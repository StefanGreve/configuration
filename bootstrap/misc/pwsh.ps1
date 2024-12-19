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
    Push-Location $ParentFolder
}
process {
    #region PowerShell Profile

    Write-Host "Download PowerShell Profile . . . " -NoNewline
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/StefanGreve/profile/refs/heads/master/profile.ps1" -Out "./profile.ps1"
    Write-Host "✓" -ForegroundColor Green

    if ($Update.IsPresent) {
        # For the update process, it's enough to download the newest version of
        # the PowerShell profile from the master branch.
        return
    }

    Write-Host "Install Dependencies . . . " -NoNewline
    Install-Module PowerTools -Force
    Write-Host "✓" -ForegroundColor Green

    $Definition = $PROFILE
      | Get-Member -Type NoteProperty
      | Where-Object Name -eq CurrentUserAllHosts
      | Select-Object -ExpandProperty Definition

    $ProfilePath = $Definition.Split("=")[1]

    # Create a PowerShell directory if necessary
    New-Item $(Split-Path -Parent $ProfilePath) -ItemType Directory -ErrorAction SilentlyContinue

    $Arguments = @{
        Path = $ProfilePath
        Value = $(Resolve-Path -Path "profile.ps1").Path
        ItemType = "SymbolicLink"
        Force = $true
    }

    Write-Host "Create Symbolic Link . . . " -NoNewline
    New-Item @Arguments | Out-Null
    Write-Host "✓" -ForegroundColor Green

    #endregion

    if ($EnableProfileSettings.IsPresent) {
        Write-Host "Configure Profile Environment Variables . . . " -NoNewLine
        [Environment]::SetEnvironmentVariable("PROFILE_ENABLE_DAILY_TRANSCRIPTS", "1", [EnvironmentVariableTarget]::User)
        [environment]::SetEnvironmentVariable("PROFILE_LOAD_CUSTOM_SCRIPTS", "$HOME/Documents/Scripts", [EnvironmentVariableTarget]::User)
        Write-Host "✓" -ForegroundColor Green
    }
}
clean {
    Pop-Location
}
