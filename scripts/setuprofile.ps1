using namespace System.IO

#region Initialization

$Desktop = [Environment]::GetFolderPath("Desktop")
$ParentFolder = Join-Path -Path $Desktop -ChildPath "repos" -AdditionalChildPath "profile"

New-Item -Path $ParentFolder -ItemType Directory -Force | Out-Null
$ProfileSource = [Path]::Combine($ParentFolder, "profile.ps1")

#endregion

Push-Location $ParentFolder

Write-Host "Download repository . . . " -NoNewline

if (!(Test-Path $ProfileSource)) {
    git clone "git@github.com:StefanGreve/profile.git" . --quiet
} else {
    git pull --quiet
}

Write-Host "✓" -ForegroundColor Green

$Arguments = @{
    # current user, all hosts
    Path = [OperatingSystem]::IsWindows() ? "$HOME\Documents\PowerShell\Profile.ps1" : "~/.config/powershell/profile.ps1"
    Value = $ProfileSource
    ItemType = "SymbolicLink"
    Force = $true
}

Write-Host "Create Symbolic Link . . . " -NoNewline
New-Item @Arguments | Out-Null
Write-Host "✓" -ForegroundColor Green

Write-Host "Configure Profile Environment Variables . . . " -NoNewLine
[Environment]::SetEnvironmentVariable("PROFILE_ENABLE_DAILY_TRANSCRIPTS", "1", [EnvironmentVariableTarget]::User)
[environment]::SetEnvironmentVariable("PROFILE_LOAD_CUSTOM_SCRIPTS", "$HOME/Documents/Scripts", [EnvironmentVariableTarget]::User)
Write-Host "✓" -ForegroundColor Green

Pop-Location
