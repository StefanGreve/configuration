using namespace System.IO

#region Initialization

$Root = git rev-parse --show-toplevel
. $([Path]::Combine($Root, "scripts", "utils.ps1"))
$OperatingSystem = Get-OperatingSystem
$Apps = Get-Content -Path $([Path]::Combine($Root, "settings", "apps.json")) -Raw | ConvertFrom-Json

#endregion

Push-Location -Path $Root

#region Install Programs

$PackageManagers = $Apps | Select-Object -ExpandProperty $OperatingSystem

switch ($OperatingSystem) {
    "Windows" {
        $WingetPackages = $PackageManagers.Winget
        winget install --id $WingetPackages --accept-package-agreements --accept-source-agreements --disable-interactivity
     }
    "Linux" {
        throw [NotImplementedException]::new("TODO")
    }
    "MacOS" {
        throw [NotImplementedException]::new("TODO")
    }
}

#endregion

Pop-Location
