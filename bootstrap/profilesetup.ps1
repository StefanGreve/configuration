using namespace System
using namespace System.IO

param(
    [switch] $Update,

    [switch] $EnableProfileSettings
)
begin {
    $Desktop = [Environment]::GetFolderPath("Desktop")
    $ParentFolder = [Path]::Combine($Desktop, "repos", "profile")

    New-Item -Path $ParentFolder -ItemType Directory -Force | Out-Null
    $ProfileSource = [Path]::Combine($ParentFolder, "profile.ps1")
    $ProfilePath = $PROFILE.CurrentUserAllHosts
}
process {
    Write-Host "Download PowerShell Profile . . . " -NoNewline
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/StefanGreve/profile/refs/heads/master/profile.ps1" -OutFile $ProfileSource
    Write-Host "✓" -ForegroundColor Green

    # For the update process, it's enough to download the newest version of
    # the PowerShell profile from the master branch.
    if ($Update.IsPresent) { return }

    Write-Host "Install Dependencies . . . " -NoNewline
    Install-Module PowerTools -Force
    Write-Host "✓" -ForegroundColor Green

    # Create a PowerShell directory if necessary
    New-Item $(Split-Path -Parent $ProfilePath) -ItemType Directory -Force | Out-Null

    $Arguments = @{
        Path = $ProfilePath
        Value = $ProfileSource
        ItemType = "SymbolicLink"
        Force = $true
    }

    Write-Host "Create Symbolic Link . . . " -NoNewline
    New-Item @Arguments | Out-Null
    Write-Host "✓" -ForegroundColor Green

    if ($EnableProfileSettings.IsPresent) {
        Write-Host "Configure Profile Environment Variables . . . " -NoNewLine
        [environment]::SetEnvironmentVariable("PROFILE_LOAD_CUSTOM_SCRIPTS", "$HOME/Documents/Scripts", [EnvironmentVariableTarget]::User)
        Write-Host "✓" -ForegroundColor Green
    }
}
