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
    if ($IsWindows) {
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

    $Apps = Get-Content -Path $([Path]::Combine($Root, "settings", "apps.json")) -Raw | ConvertFrom-Json
    $PackageManagers = $Apps | Select-Object -ExpandProperty "PackageManagers"
    Push-Location -Path $Root
}
process {
    if (!(Get-Module PowerTools)) {
        Install-Module PowerTools -Force
    }

    Import-Module PowerTools

    if ($Applications.IsPresent -or $All.IsPresent) {
        if ($IsWindows) {
            $PackageManagers.Winget | Install-WinGet
        } else {
            Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
        }
    }

    if ($Cargo.IsPresent -or $All.IsPresent) {
        if (Test-Command "cargo") {
            # update rustc and cargo because some crates won't install easily
            # if we continue with an outdated version
            rustup update
        }
        else {
            if ($isWindows) {
                Install-WinGet -Id "rustlang.rustup"
            } else {
                Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
            }
        }

        $PackageManagers.Cargo | ForEach-Object {
            cargo install $_
        }
    }

    if ($PSBoundParameters.Registry -or ($isWindows -and $All.IsPresent)) {
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

        if ($IsWindows) {
            Invoke-WebRequest -UseBasicParsing $VimPlug | New-Item "$env:LOCALAPPDATA/nvim/autoload/plug.vim" -Force
        } else {
            sh -c "curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs $VimPlug"
        }

        # install all CoC depedencies from init.vim
        nvim +'call coc#util#install()' +qa
        # finally install all plugins
        nvim +'PlugInstall --sync' +qa
    }
}
clean {
    Pop-Location
}
