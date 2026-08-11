function Update-System {
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "Option")]
        [switch] $Help,

        [Parameter(ParameterSetName = "Option")]
        [switch] $WinGet,

        [Parameter(ParameterSetName = "Option")]
        [switch] $Brew,

        [Parameter(ParameterSetName = "Option")]
        [switch] $Pipx,

        [Parameter(ParameterSetName = "Option")]
        [switch] $Cargo,

        [Parameter(ParameterSetName = "Option")]
        [switch] $DotnetTools,

        [Parameter(ParameterSetName = "Option")]
        [switch] $Npm,

        [Parameter(ParameterSetName = "All")]
        [switch] $All
    )

    process {
        $HasInternetConnection = Test-Connection -TargetName "www.google.com" -Count 3 -Quiet

        if (!$HasInternetConnection) {
            Write-Error "Failed to connect to the internet. Please check your network settings and try again." -ErrorAction Stop -Category ConnectionError
        }

        if ($Help.IsPresent -or $All.IsPresent) {
            Update-Help -UICulture "en-US" -ErrorAction SilentlyContinue -ErrorVariable UpdateErrors -Force
        }

        if ($WinGet.IsPresent -or $All.IsPresent) {
            if ($IsWindows) {
                # Some programs may require some user interaction for GUI installer wizards (e.g. Jet Brains products)
                winget upgrade --all `
                    --silent `
                    --accept-package-agreements `
                    --accept-source-agreements `
                    --include-unknown `
                    --disable-interactivity
            } elseif ($WinGet.IsPresent) {
                Write-Error "winget is only available on Windows." -Category InvalidOperation
            }
        }

        if ($Brew.IsPresent -or $All.IsPresent) {
            if ($IsMacOS) {
                # 1. Update homebrew itself, to ensure that the latest version information is available.
                brew update

                # 2. Upgrade all installed packages
                brew upgrade

                # 3. Check for any remaining outdated packages after the upgrade procedure.
                brew outdated

                # 4. After upgrading packages, older versions may still remain on the system. This command
                # cleans up unused versions to free up disk space.
                brew cleanup
            } elseif ($Brew.IsPresent) {
                Write-Error "Homebrew is only available on macOS." -Category InvalidOperation
            }
        }

        if ($Pipx.IsPresent -or $All.IsPresent) {
            if (Test-Command pipx) {
                pipx upgrade-all
            } elseif ($Pipx.IsPresent) {
                Write-Error "pipx is not installed." -Category NotInstalled
            }
        }

        if ($Cargo.IsPresent -or $All.IsPresent) {
            if (Test-Command cargo) {
                if ($null -eq $(cargo install --list | Select-String "cargo-install-update" -SimpleMatch)) {
                    Write-Error "cargo-update is not installed. Run `"cargo install cargo-update`" to install this crate." `
                        -Category NotInstalled `
                        -ErrorAction Stop
                }

                # Update rust
                rustc --version
                rustup update

                # Then update all crates that were installed in global scope
                cargo install-update -a
            } elseif ($Cargo.IsPresent) {
                Write-Error "cargo is not installed." -Category NotInstalled
            }
        }

        if ($DotnetTools.IsPresent -or $All.IsPresent) {
            if (Test-Command dotnet) {
                dotnet tool update --global --all
            } elseif ($DotnetTools.IsPresent) {
                Write-Error "The .NET SDK is not installed." -Category NotInstalled
            }
        }

        if ($Npm.IsPresent -or $All.IsPresent) {
            if (Test-Command npm) {
                # Update npm itself first
                npm install --global npm@latest

                # Then update every npm package installed in global scope.
                npm update --global
            } elseif ($Npm.IsPresent) {
                Write-Error "npm is not installed." -Category NotInstalled
            }
        }
    }
}
