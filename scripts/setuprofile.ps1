using namespace System.IO

#region Initialization

$Desktop = [Environment]::GetFolderPath("Desktop")
$ParentFolder = Join-Path -Path $Desktop -ChildPath "repos" -AdditionalChildPath "profile"
$Repository = New-Item -Path $ParentFolder -ItemType Directory -Force

#endregion

Push-Location $Repository.Directory.FullName

if (!(Test-Path $Repository)) {
    git clone "git@github.com:StefanGreve/profile.git"
}

$Arguments = @{
    # current user, all hosts
    Path = [OperatingSystem]::IsWindows() ? "$HOME\Documents\PowerShell\Profile.ps1" : "~/.config/powershell/profile.ps1"
    Value = [Path]::Combine($Repository.FullName, "profile.ps1")
    ItemType = "SymbolicLink"
    Force = $true
}

Write-Host "$($Arguments.Value) -> $($Arguments.Path)" -ForegroundColor Yellow
New-Item @Arguments | Out-Null

Pop-Location
