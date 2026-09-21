#Requires -Version 7.4

<#
.SYNOPSIS
    Registers a scheduled task that opens the Claude Code usage window three times a day.

.DESCRIPTION
    Creates (or overwrites) a Windows scheduled task named "ClaudeWindowDaemon" that sends a throwaway
    prompt to Claude Code through pwsh.exe every day, at StartTime and again five and ten hours later.

    Claude Code meters usage in five hour windows that begin with the first message of the window, so the
    reset times drift later whenever the first message of the day does. Priming each window on a fixed
    schedule pins them to the clock instead: a 07:00 start resets at 12:00, 17:00 and 22:00.

    A single action serves all three triggers, so the greeting is selected from the hour the task fires. A
    run that Task Scheduler catches up outside those hours falls back to a plain greeting rather than
    invoking claude with no prompt at all.

    The task starts when available, so a run missed while the machine is off is caught up on next wake. It
    also runs on battery and is capped at a five minute execution time limit. Re-running this script
    re-registers the task in place because -Force is set.

.PARAMETER StartTime
    Time of day, as a TimeSpan, at which the first window opens. The other two runs are derived as
    StartTime plus five and ten hours, so values from 00:00 up to (but not including) 14:00 are accepted;
    anything later would push the third run past midnight. Defaults to 07:00.

.EXAMPLE
    .\ClaudeWindowDaemon.ps1
    Registers or refreshes the task with windows opening at 07:00, 12:00 and 17:00.

.EXAMPLE
    .\ClaudeWindowDaemon.ps1 -StartTime "06:30"
    Shifts the whole chain half an hour earlier, so the windows open at 06:30, 11:30 and 16:30.

.NOTES
    Run from an elevated (Administrator) PowerShell session. Registering a task in the Task Scheduler
    root library requires administrator rights.

    The task runs under your interactive account and therefore authenticates as the signed-in Claude Code
    user. Nothing is logged: when the login expires or claude fails for any other reason, the non-zero exit
    code surfaces in the Last Run Result column of Task Scheduler.

.LINK
    https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask

.LINK
    https://code.claude.com/docs/en/cli-reference
#>

[CmdletBinding()]
param (
    [ValidateScript({ $_ -ge [TimeSpan]::Zero -and $_ -lt [TimeSpan]::FromHours(14) },
        ErrorMessage = "StartTime must be between 00:00 and 13:59 so the last of the three runs stays before midnight.")]
    [TimeSpan] $StartTime = "07:00"
)

# ==============================================================================

$Author = "Stefan Greve"
$TaskName = "ClaudeWindowDaemon"
$ClaudeWindow = 5

$Greetings = [ordered]@{
    $StartTime                                               = "Good morning"
    $StartTime.Add([TimeSpan]::FromHours($ClaudeWindow))     = "Good afternoon"
    $StartTime.Add([TimeSpan]::FromHours($ClaudeWindow * 2)) = "Good evening"
}

$Schedule = ($Greetings.Keys | ForEach-Object { $_.ToString("hh\:mm") }) -join ", "
$Description = "Opens the Claude Code usage window at $Schedule every day."

# ==============================================================================

if (!(Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "claude is not on PATH; the task registers but every run will fail until Claude Code is installed."
}

# Task Scheduler pairs one action with every trigger, so the prompt has to resolve at run time. The lookup
# is keyed by hour rather than by trigger, and ?? covers a catch-up run that lands outside the three hours.
$Lookup = ($Greetings.GetEnumerator() | ForEach-Object { "$($_.Key.Hours)='$($_.Value)'" }) -join ";"
$Prompt = "`$(@{$Lookup}[(Get-Date).Hour] ?? 'Hello')"
$Command = "claude --effort low --model haiku --no-session-persistence --print --safe-mode $Prompt"

$ActionArgs = @{
    Execute          = "pwsh.exe"
    Argument         = "-NoProfile -NonInteractive -Command `"$Command`""
    WorkingDirectory = $HOME
}
$Action = New-ScheduledTaskAction @ActionArgs

$Triggers = $Greetings.Keys | ForEach-Object {
    $TriggerArgs = @{
        Daily = $true
        At    = [DateTime]::Today.Add($_)
    }
    New-ScheduledTaskTrigger @TriggerArgs
}

$SettingsArgs = @{
    ExecutionTimeLimit         = [TimeSpan]::FromMinutes(5)
    AllowStartIfOnBatteries    = $true
    DontStopIfGoingOnBatteries = $true
    StartWhenAvailable         = $true
}
$Settings = New-ScheduledTaskSettingsSet @SettingsArgs

$TaskArgs = @{
    Action      = $Action
    Trigger     = $Triggers
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
