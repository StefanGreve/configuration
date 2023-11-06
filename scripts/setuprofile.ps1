using namespace System.IO

#region Initialization

$Desktop = [Environment]::GetFolderPath("Desktop")
$ParentFolder = Join-Path -Path $Desktop -ChildPath "repos" -AdditionalChildPath "profile"
$Repository = New-Item -Path $ParentFolder -ItemType Directory -Force
$Profile = [Path]::Combine($ParentFolder, "profile.ps1")

#endregion

Push-Location $ParentFolder

Write-Host "Download repository . . ."

if (!(Test-Path $Profile)) {
    git clone "git@github.com:StefanGreve/profile.git" .
} else {
    git pull
}

$Arguments = @{
    # current user, all hosts
    Path = [OperatingSystem]::IsWindows() ? "$HOME\Documents\PowerShell\Profile.ps1" : "~/.config/powershell/profile.ps1"
    Value = $Profile
    ItemType = "SymbolicLink"
    Force = $true
}

Write-Host "$($Arguments.Value) -> $($Arguments.Path)" -ForegroundColor Yellow
New-Item @Arguments | Out-Null

Write-Host "Configure Profile Environment Variables . . . " -NoNewLine
[Environment]::SetEnvironmentVariable("PROFILE_ENABLE_DAILY_TRANSCRIPTS", "1", [EnvironmentVariableTarget]::User)
[environment]::SetEnvironmentVariable("PROFILE_LOAD_CUSTOM_SCRIPTS", "$HOME/Documents/Scripts", [EnvironmentVariableTarget]::User)
Write-Host "✓" -ForegroundColor Green

Pop-Location
