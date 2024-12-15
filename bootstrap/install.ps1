using namespace System.Collections.ObjectModel
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
    [switch] $NeoVim,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $VsCode,

    [Parameter(ParameterSetName = "All", Mandatory)]
    [switch] $All
)
dynamicparam {
    $ParamDictionary = [RuntimeDefinedParameterDictionary]::new()

    if ($IsWindows) {
        $RegistryAttribute = [ParameterAttribute]::new()
        $RegistryAttribute.ParameterSetName = "Custom"

        $AttributeCollection = [Collection[Attribute]]::new()
        $AttributeCollection.Add($RegistryAttribute)

        $RegistryParameter = [RuntimeDefinedParameter]::new("Registry", [switch], $AttributeCollection)

        $ParamDictionary.Add("Registry", $RegistryParameter)
    }

    return $ParamDictionary
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

    #region Packages
    if ($Applications.IsPresent -or $All.IsPresent) {
        if ($IsWindows) {
            $PackageManagers.WinGet | Install-WinGet
        } elseif ($IsMacOS) {
            foreach ($Package in $PackageManagers.Brew) {
                brew install $Package
            }
        } else {
            Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
        }
    }
    #endregion

    #region Cargo
    if ($Cargo.IsPresent -or $All.IsPresent) {
        if (Test-Command "cargo") {
            # update rustc and cargo because some crates won't install easily
            # if we continue with an outdated version
            rustup update
        }
        else {
            if ($IsWindows) {
                Install-WinGet -Id "rustlang.rustup"
            } else {
                Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
            }
        }

        $PackageManagers.Cargo | ForEach-Object {
            cargo install $_
        }
    }
    #endregion

    #region Windows Registry
    if ($PSBoundParameters.Registry -or ($IsWindows -and $All.IsPresent)) {
        $RegistryFiles = Get-ChildItem -Path $([Path]::Combine($Root, "settings")) -Filter *.reg
        $RegistryFiles | ForEach-Object {
            Write-Verbose $_.FullName
            reg import $_.FullName
        }
    }
    #endregion

    #region VS Code
    if ($VsCode.IsPresent -or $All.IsPresent) {
        $Extensions = $Apps | Select-Object -ExpandProperty Extensions

        # install vs code extensions
        $Extensions.Code | ForEach-Object -ThrottleLimit 5 -Parallel {
            code --install-extension $_ --force
        }
    }

    #endregion

    #region NeoVim
    if ($NeoVim.IsPresent -or $All.IsPresent) {
        # prerequisites for coc
        corepack enable
        npm install --global corepack
        npm install --global npm@latest

        # first install a vim plugin manager
        Write-Host "Installing vim-plug..."
        $VimPlug = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

        if ($IsWindows) {
            Invoke-WebRequest -UseBasicParsing $VimPlug | New-Item "${env:LOCALAPPDATA}/nvim/autoload/plug.vim" -Force
        } else {
            sh -c "curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs ${VimPlug}"
        }

        # install all CoC depedencies from init.vim
        nvim +"call coc#util#install()" +qa
        # finally install all plugins
        nvim +"PlugInstall --sync" +qa
    }
    #endregion
}
clean {
    Pop-Location
}
