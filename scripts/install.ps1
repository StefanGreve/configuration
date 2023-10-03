using namespace System.IO
using namespace System.Management.Automation

[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(ParameterSetName = "Custom")]
    [switch] $Applications,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $Plugins,

    [Parameter(ParameterSetName = "All", Mandatory)]
    [switch] $All
)
dynamicparam {
    if ([OperatingSystem]::IsWindows()) {
        $ParamDictionary = New-Object -Type RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[Attribute]

        $RegistryParameter = New-Object -Type RuntimeDefinedParameter("Registry", [switch], $AttributeCollection)

        $RegistryAttribute = New-Object ParameterAttribute
        $RegistryAttribute.ParameterSetName = "Custom"

        $AttributeCollection.Add($RegistryAttribute)
        $ParamDictionary.Add("Registry", $RegistryParameter)
        return $ParamDictionary
    }
}

begin {
    $Root = git rev-parse --show-toplevel
    . $([Path]::Combine($Root, "scripts", "utils.ps1"))
    $OperatingSystem = Get-OperatingSystem
    $Apps = Get-Content -Path $([Path]::Combine($Root, "settings", "apps.json")) -Raw | ConvertFrom-Json
    Push-Location -Path $Root
}
process {
    if ($Applications.IsPresent -or $All.IsPresent) {
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
    }

    if ($PSBoundParameters.Registry -or ([OperatingSystem]::IsWindows() -and $All.IsPresent)) {
        $RegistryFiles = Get-ChildItem -Path $([Path]::Combine($Root, "settings")) -Filter *.reg
        $RegistryFiles | ForEach-Object {
            Write-Verbose $_.FullName
            reg import $_.FullName
        }
    }

    if ($Plugins.IsPresent -or $All.IsPresent) {
        $Extensions = $Apps | Select-Object -ExpandProperty Extensions

        $Extensions.Code | ForEach-Object -ThrottleLimit 5 -Parallel {
            # force parameter updates to the latest version, if already installed
            code --install-extension $_ --force
        }
    }
}
clean {
    Pop-Location
}
