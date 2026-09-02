#Requires -Version 7.4

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
    [switch] $DotnetTool,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $PipX,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $PSModule,

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
    if ($Applications.IsPresent -or $All.IsPresent) {
        if ($IsWindows) {
            # Prefer the winget community source over msstore (default priority 0); higher wins.
            # Needs the "sourcePriority" experimental feature and winget 1.29.280+.
            winget source edit --name winget --priority 100

            $PackageManagers.WinGet | Install-WinGet -Verbose
        } elseif ($IsMacOS) {
            $PackageManagers.Brew | Install-Brew
        } else {
            Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
        }
    }

    if ($Cargo.IsPresent -or $All.IsPresent) {
        if (Get-Command cargo -ErrorAction SilentlyContinue) {
            # Update rustc and cargo because some crates won't install easily
            # if we continue with an outdated version
            rustup update
        }
        else {
            if ($IsWindows) {
                Install-WinGet -Id "rustlang.rustup"
            } else {
                Write-Error "TODO: install cargo" -Category NotImplemented -ErrorAction Stop
            }
        }

        $PackageManagers.Cargo | Install-Cargo
    }

    if ($DotnetTool.IsPresent -or $All.IsPresent) {
        if (Get-Command dotnet -ErrorAction SilentlyContinue) {
            $PackageManagers.DotnetTool | Install-DotnetTool
        } else {
            Write-Error "TODO: install dotnet" -Category NotImplemented -ErrorAction Stop
        }
    }

    if ($Pipx.IsPresent -or $All.IsPresent) {
        if (!(Get-Command pipx -ErrorAction SilentlyContinue)) {
            & ($IsWindows ? "py" : "python3") -m pip config set global.require-virtualenv False

            if ($IsMacOS) {
                brew install pipx
            } elseif ($IsWindows) {
                py -m pip install --user pipx

                # Append the pipx executable directory and the user-scope app directory to PATH,
                # skipping any entry that is already present so repeated runs do not create duplicates.
                $UserScripts = py -c "import sysconfig; print(sysconfig.get_path('scripts', 'nt_user'))"

                foreach ($Directory in @($UserScripts, [Path]::Combine($HOME, ".local", "bin"))) {
                    $UserPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
                    if (($UserPath -split ";") -notcontains $Directory) {
                        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$Directory", [EnvironmentVariableTarget]::User)
                    }
                }
            } else {
                Write-Error "TODO: install pipx" -Category NotImplemented -ErrorAction Stop
            }

            & ($IsWindows ? "py" : "python3") -m pip config set global.require-virtualenv True
        }

        $PackageManagers.PipX | Install-PipX
    }

    if ($PSModule.IsPresent -or $All.IsPresent) {
        $PackageManagers.PSModule | Install-PSModule
    }

    if ($PSBoundParameters.Registry -or ($IsWindows -and $All.IsPresent)) {
        $RegistryFiles = Get-ChildItem -Path $([Path]::Combine($Root, "settings")) -Filter "*.reg"

        # Windows10.reg is the shared baseline; Windows11.reg is Windows 11-only (build 22000+).
        if ([Environment]::OSVersion.Version.Build -lt 22000) {
            $RegistryFiles = $RegistryFiles | Where-Object { $_.Name -ne "Windows11.reg" }
        }

        $IsElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)

        if ($IsElevated) {
            $RegistryFiles | ForEach-Object {
                Write-Verbose $_.FullName
                reg import $_.FullName
            }
        } else {
            # Some .reg files write HKLM policy keys, which require elevation. Re-run every
            # import in a single elevated child process so only one UAC prompt is shown. HKCU
            # keys land in the invoking user's hive, so this assumes same-user elevation.
            Write-Warning "Registry import requires administrator rights; requesting elevation..."
            $Commands = ($RegistryFiles | ForEach-Object { "reg import `"$($_.FullName)`"" }) -join "`n"
            $Encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Commands))
            Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -Wait -ArgumentList @(
                "-NoProfile", "-EncodedCommand", $Encoded
            )
        }
    }

    if ($VsCode.IsPresent -or $All.IsPresent) {
        $Extensions = $Apps | Select-Object -ExpandProperty Extensions
        $Extensions.Code | Install-VsCodeExtension
    }

    if ($NeoVim.IsPresent -or $All.IsPresent) {
        if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
            Write-Error "npm is not installed, but it is required to proceed. Please install npm and try again." -Category NotInstalled -ErrorAction Stop
        }

        # First install a vim plugin manager
        Write-Host "Installing vim-plug..."
        $VimPlug = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

        if ($IsWindows) {
            Invoke-WebRequest -UseBasicParsing $VimPlug | New-Item "${env:LOCALAPPDATA}/nvim/autoload/plug.vim" -Force
        } else {
            sh -c "curl -fLo '${XDG_DATA_HOME:-$HOME/.local/share}'/nvim/site/autoload/plug.vim --create-dirs ${VimPlug}"
        }

        # Prerequisites for CoC
        corepack enable
        npm install --global corepack
        npm install --global npm@latest

        # Install dependencies for CoC
        npm install --prefix $($IsWindows ? "$env:LOCALAPPDATA\nvim-data\plugged\coc.nvim" : "~/.local/share/nvim/plugged/coc.nvim")

        # Install all CoC dependencies from init.vim
        nvim +"call coc#util#install()" +qa

        # Finally install all plugins
        nvim +"PlugInstall --sync" +qa
    }
}
clean {
    Pop-Location
}
