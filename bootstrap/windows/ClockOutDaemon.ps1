#Requires -Version 7.0

<#
.SYNOPSIS
    Registers a scheduled task that reminds you to clock out on weekday evenings.

.DESCRIPTION
    Creates (or overwrites) a Windows scheduled task named "ClockOutDaemon" that runs
    scripts/windows/Stop-Work.ps1 via pwsh.exe at the configured clock-out time (17:30 by default)
    every weekday (Monday through Friday). The task starts when available, so a run missed while the
    machine is off is caught up on next wake. It also runs on battery and is capped at a five minute
    execution time limit. Re-running this script re-registers the task in place because -Force is set.

.PARAMETER ClockOutTime
    Time of day, as a TimeSpan, at which the reminder fires. Accepts values from 00:00 up to (but not
    including) 24:00. Defaults to 17:30.

.EXAMPLE
    .\ClockOutDaemon.ps1
    Registers or refreshes the task using the default 17:30 reminder time.

.EXAMPLE
    .\ClockOutDaemon.ps1 -ClockOutTime "18:00"
    Registers the task to remind you at 18:00 instead.

.NOTES
    Run from an elevated (Administrator) PowerShell session. Registering a task in the Task Scheduler
    root library requires administrator rights.

.LINK
    https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask
#>

[CmdletBinding()]
param (
    [ValidateScript({ $_ -ge [TimeSpan]::Zero -and $_ -lt [TimeSpan]::FromDays(1) },
        ErrorMessage = "ClockOutTime must be a time of day between 00:00 and 23:59.")]
    [TimeSpan] $ClockOutTime = "17:30"
)

# ==============================================================================

$Author = "Stefan Greve"
$TaskName = "ClockOutDaemon"
$Description = "Reminds you to clock out at $($ClockOutTime.ToString('hh\:mm')) on weekdays."

# ==============================================================================

$StopWork = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\scripts\windows\Stop-Work.ps1"))
$ActionArgs = @{
    Execute  = "pwsh.exe"
    Argument = "-NoProfile -ExecutionPolicy Bypass -File `"$StopWork`""
}
$Action = New-ScheduledTaskAction @ActionArgs

$TriggerArgs = @{
    Weekly     = $true
    DaysOfWeek = [DayOfWeek]::Monday..[DayOfWeek]::Friday
    At         = [DateTime]::Today.Add($ClockOutTime)
}
$Trigger = New-ScheduledTaskTrigger @TriggerArgs

$SettingsArgs = @{
    ExecutionTimeLimit         = [TimeSpan]::FromMinutes(5)
    AllowStartIfOnBatteries    = $true
    DontStopIfGoingOnBatteries = $true
    StartWhenAvailable         = $true
}
$Settings = New-ScheduledTaskSettingsSet @SettingsArgs

$TaskArgs = @{
    Action      = $Action
    Trigger     = $Trigger
    Settings    = $Settings
    Description = $Description
}
$Task = New-ScheduledTask @TaskArgs
$Task.Author = $Author
$Task.Date = [DateTime]::Now.ToString("s")
$Task.Source = $MyInvocation.MyCommand.Name

$RegisterArgs = @{
    TaskName    = $TaskName
    InputObject = $Task
    Force       = $true
}
Register-ScheduledTask @RegisterArgs
