#Requires -Version 7.0

<#
.SYNOPSIS
    Starts a background job that keeps the session "active" by sending F15 while you are idle.

.DESCRIPTION
    Launches a PowerShell background job (via Start-Job) that polls the system idle time and, once
    it exceeds a threshold, synthesizes a single F15 key press. F15 is used because virtually
    nothing binds it, so it registers as input activity. This resets the idle timer and prevents
    the screen from locking without disrupting whatever has focus.

.PARAMETER IdleThresholdSeconds
    Send F15 only after this many seconds without real user input. Keep it below your lock timeout.

.PARAMETER PollIntervalSeconds
    How often the job checks idle time. Should be smaller than IdleThresholdSeconds.

.EXAMPLE
    # starts the job, returns the job object
    .\LazyJob.ps1

.EXAMPLE
    .\LazyJob.ps1 -IdleThresholdSeconds 120 -PollIntervalSeconds 15
#>

[CmdletBinding()]
param (
    [ValidateRange(1, 86400)]
    [int] $IdleThresholdSeconds = 240,

    [ValidateRange(1, 3600)]
    [int] $PollIntervalSeconds = 30
)

# ==============================================================================

$JobName = "LazyJob"

if ($PollIntervalSeconds -ge $IdleThresholdSeconds) {
    Write-Warning ("PollIntervalSeconds ($PollIntervalSeconds) is not smaller than " +
        "IdleThresholdSeconds ($IdleThresholdSeconds); idle nudges may lag behind the threshold.")
}

if (Get-Job -Name $JobName -ErrorAction SilentlyContinue) {
    Write-Error "A job named '$JobName' already exists. Stop and remove it first" `
        -Category ResourceExists `
        -ErrorAction Stop
}

# ==============================================================================

$LazyJobScript = {
    param (
        [int] $IdleThresholdSeconds,
        [int] $PollIntervalSeconds
    )

    Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class LazyJobIdle
{
    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO
    {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static TimeSpan GetIdleTime()
    {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(lii);

        if (!GetLastInputInfo(ref lii))
        {
            return TimeSpan.Zero;
        }

        // Unsigned subtraction handles the 32-bit GetTickCount wraparound (~49.7 days uptime).
        uint idleMs = (uint)Environment.TickCount - lii.dwTime;
        return TimeSpan.FromMilliseconds(idleMs);
    }
}
"@

    $WShell = New-Object -ComObject WScript.Shell

    while ($true) {
        $Idle = [LazyJobIdle]::GetIdleTime()

        if ($Idle.TotalSeconds -ge $IdleThresholdSeconds) {
            $null = $WShell.SendKeys("{F15}")
            Write-Output ("[{0:HH:mm:ss}] Idle {1:n0}s: sent {{F15}}." -f [DateTime]::Now, $Idle.TotalSeconds)
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }
}

# ==============================================================================

Start-Job -Name $JobName `
    -ScriptBlock $LazyJobScript `
    -ArgumentList $IdleThresholdSeconds, $PollIntervalSeconds
