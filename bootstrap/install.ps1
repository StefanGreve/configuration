using namespace System.IO
using namespace System.Management.Automation

[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(ParameterSetName = "Custom")]
    [switch] $Applications,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $Cargo,

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
    . $([Path]::Combine($Root, "bootstrap", "utils.ps1"))
    $OperatingSystem = Get-OperatingSystem
    $Apps = Get-Content -Path $([Path]::Combine($Root, "settings", "apps.json")) -Raw | ConvertFrom-Json
    $PackageManagers = $Apps | Select-Object -ExpandProperty "PackageManagers"
    Push-Location -Path $Root
}
process {
    if ($Applications.IsPresent -or $All.IsPresent) {
        switch ($OperatingSystem) {
            "Windows" {
                $PackageManagers.Winget | Install-WingetPackage
             }
            "Linux" {
                throw [NotImplementedException]::new("TODO")
            }
            "MacOS" {
                throw [NotImplementedException]::new("TODO")
            }
        }
    }

    if ($Cargo.IsPresent -or $All.IsPresent) {
        if (Test-Command "cargo") {
            # update rustc and cargo because some crates won't install easily
            # if we continue with an outdated version
            rustup update
        }
        else {
            switch ($OperatingSystem) {
                "Windows" {
                    Install-WingetPackage -Id "rustlang.rustup"
                }
                "Linux" {
                    throw [NotImplementedException]::new("TODO")
                }
                "MacOS" {
                    thow [NotImplementedException]::new("TODO")
                }
            }
        }

        $PackageManagers.Cargo | ForEach-Object {
            cargo install $_
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

        # install vs code extensions
        $Extensions.Code | ForEach-Object -ThrottleLimit 5 -Parallel {
            code --install-extension $_ --force
        }

        # prerequisites for coc
        corepack enable
        npm install --global corepack
        npm install --global npm@latest

        # first install a vim plugin manager
        Write-Host "Installing vim-plug..."
        $VimPlug = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        Invoke-WebRequest -UseBasicParsing $VimPlug | New-Item "$env:LOCALAPPDATA/nvim/autoload/plug.vim" -Force
        # install all CoC depedencies from init.vim
        nvim +'call coc#util#install()' +qa
        # finally install all plugins
        nvim +'PlugInstall --sync' +qa
    }
}
clean {
    Pop-Location
}
