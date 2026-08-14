#Requires -Version 7.4

<#
    .SYNOPSIS
    Installs the PowerShell profile and links it to the current user's profile path.

    .DESCRIPTION
    Downloads the latest profile.ps1 from the StefanGreve/profile repository into
    ~/Desktop/repos/profile, installs the PowerTools module, and creates a symbolic
    link from the CurrentUserAllHosts profile path to the downloaded file. Works on
    any platform with pwsh installed, including macOS and Linux.

    .PARAMETER Update
    If specified, only the latest profile.ps1 is downloaded from the master branch;
    dependency installation, the symbolic link, and environment variable setup are
    skipped.

    .PARAMETER EnableProfileSettings
    If specified, sets the user-scoped PROFILE_LOAD_CUSTOM_SCRIPTS environment
    variable to $HOME/Documents/Scripts.

    .INPUTS
    None. You cannot pipe objects to this script.

    .OUTPUTS
    None. This script does not produce any output.

    .NOTES
    Creating the symbolic link may require elevated privileges or Developer Mode on
    Windows prior to the Windows 10 Creators Update.
#>

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
        [Environment]::SetEnvironmentVariable("PROFILE_LOAD_CUSTOM_SCRIPTS", "$HOME/Documents/Scripts", [EnvironmentVariableTarget]::User)
        Write-Host "✓" -ForegroundColor Green
    }
}
