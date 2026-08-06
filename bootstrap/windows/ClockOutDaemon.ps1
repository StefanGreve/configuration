# ==============================================================================

$Author = "Stefan Greve"
$TaskName = "ClockOutDaemon"
$Description = "Reminds you to clock out at 17:30 on weekdays."

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
    At         = "5:30PM"
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
$Task.Date = [DateTime]::Today.ToString("s")
$Task.Source = $MyInvocation.MyCommand.Name

$RegisterArgs = @{
    TaskName    = $TaskName
    InputObject = $Task
    Force       = $true
}
Register-ScheduledTask @RegisterArgs
