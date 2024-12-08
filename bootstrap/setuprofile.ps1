using namespace System.IO

#region Initialization

$Desktop = [Environment]::GetFolderPath("Desktop")
$ParentFolder = Join-Path -Path $Desktop -ChildPath "repos" -AdditionalChildPath "profile"

New-Item -Path $ParentFolder -ItemType Directory -Force | Out-Null
$ProfileSource = [Path]::Combine($ParentFolder, "profile.ps1")

#endregion

Push-Location $ParentFolder

Write-Host "Download PowerShell Profile . . . " -NoNewline

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/StefanGreve/profile/refs/heads/master/profile.ps1" -Out "./profile.ps1"
$ProfileSource = $(Resolve-Path -Path "profile.ps1").Path

Write-Host "✓" -ForegroundColor Green

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
