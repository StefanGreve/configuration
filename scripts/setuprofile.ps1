using namespace System.IO

#region Initialization

$Desktop = [Environment]::GetFolderPath("Desktop")
$ParentFolder = Join-Path -Path $Desktop -ChildPath "repos" -AdditionalChildPath "profile"
$Repository = New-Item -Path $ParentFolder -ItemType Directory -Force
$Profile = [Path]::Combine($ParentFolder, "profile.ps1")

#endregion

Push-Location $ParentFolder

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

Pop-Location
