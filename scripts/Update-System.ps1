#Requires -Version 7.4

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

        [Parameter(ParameterSetName = "Option")]
        [switch] $CleanUp,

        [Parameter(ParameterSetName = "All")]
        [switch] $All
    )

    begin {
        $HasInternetConnection = Test-Connection -TargetName "www.google.com" -Count 3 -Quiet

        if (!$HasInternetConnection) {
            Write-Error "Failed to connect to the internet. Please check your network settings and try again." -ErrorAction Stop -Category ConnectionError
        }
    }
    process {
        if ($Help.IsPresent -or $All.IsPresent) {
            Update-Help -UICulture "en-US" -ErrorAction SilentlyContinue -ErrorVariable UpdateErrors -Force
        }

        if ($WinGet.IsPresent -or $All.IsPresent) {
            if ($IsWindows -and (Get-Command winget -ErrorAction SilentlyContinue)) {
                # Package Ids of winget packages to pin so "upgrade --all" skips them.
                $WinGetBlacklist = @()

                # winget has no exclude flag, so pin each blacklisted package (plain pins are skipped by --all).
                foreach ($Id in $WinGetBlacklist) {
                    winget pin add --id $Id --exact --accept-source-agreements --disable-interactivity
                }

                winget upgrade --all `
                    --source winget `
                    --silent `
                    --accept-package-agreements `
                    --accept-source-agreements `
                    --include-unknown `
                    --disable-interactivity `
                    --force
            } elseif ($IsWindows) {
                Write-Error "winget is not installed." -Category NotInstalled
            } elseif ($WinGet.IsPresent) {
                Write-Error "winget is only available on Windows." -Category InvalidOperation
            }
        }

        if ($Brew.IsPresent -or $All.IsPresent) {
            if ($IsMacOS) {
                # Names of Homebrew formulae/casks to exclude from the update.
                $BrewBlacklist = @()

                # Update homebrew itself, to ensure that the latest version information is available.
                brew update

                if ($BrewBlacklist.Count -eq 0) {
                    brew upgrade
                } else {
                    # "brew upgrade" cannot skip individual packages, so enumerate the outdated ones and
                    # upgrade only those that are not blacklisted.
                    $Outdated = brew outdated --quiet | Where-Object { $_ -and $_ -notin $BrewBlacklist }

                    if ($Outdated) {
                        brew upgrade $Outdated
                    }
                }

                # After upgrading packages, older versions may still remain on the system. This command
                # cleans up unused versions to free up disk space.
                brew cleanup
            } elseif ($Brew.IsPresent) {
                Write-Error "Homebrew is only available on macOS." -Category InvalidOperation
            }
        }

        if ($Pipx.IsPresent -or $All.IsPresent) {
            if (Get-Command pipx -ErrorAction SilentlyContinue) {
                # Names of global pipx packages to exclude from the update.
                $PipxBlacklist = @()

                if ($PipxBlacklist.Count -eq 0) {
                    pipx upgrade-all
                } else {
                    pipx upgrade-all --skip $PipxBlacklist
                }
            } elseif ($Pipx.IsPresent) {
                Write-Error "pipx is not installed." -Category NotInstalled
            }
        }

        if ($Cargo.IsPresent -or $All.IsPresent) {
            if (Get-Command cargo -ErrorAction SilentlyContinue) {
                # Names of global cargo crates to exclude from the update.
                $CargoBlacklist = @()

                if ($null -eq $(cargo install --list | Select-String "cargo-install-update" -SimpleMatch)) {
                    Write-Error "cargo-update is not installed. Run `"cargo install cargo-update`" to install this crate." `
                        -Category NotInstalled `
                        -ErrorAction Stop
                }

                # Update rust
                rustc --version
                rustup update

                # Then update all crates that were installed in global scope
                if ($CargoBlacklist.Count -eq 0) {
                    cargo install-update -a
                } else {
                    # cargo-update has no exclude flag, but its name filter can be negated ("!name=<crate>").
                    # Multiple filters are combined with logical AND, so each blacklisted crate is skipped.
                    $ExcludeFilters = $CargoBlacklist | ForEach-Object { "--filter", "!name=$_" }
                    cargo install-update -a $ExcludeFilters
                }
            } elseif ($Cargo.IsPresent) {
                Write-Error "cargo is not installed." -Category NotInstalled
            }
        }

        if ($DotnetTools.IsPresent -or $All.IsPresent) {
            if (Get-Command dotnet -ErrorAction SilentlyContinue) {
                # Package Ids of global .NET tools to exclude from the update.
                $DotnetToolsBlacklist = @(
                    "dependencyvisualizertool"  # corporate tool for dependency-track
                    "nexus.claude.analysis"     # corporate tracking tool
                )

                if ($DotnetToolsBlacklist.Count -eq 0) {
                    dotnet tool update --global --all
                } else {
                    $InstalledTools = (dotnet tool list --global --format json | ConvertFrom-Json).data.packageId

                    foreach ($Tool in $InstalledTools) {
                        if ($Tool -in $DotnetToolsBlacklist) { continue }
                        dotnet tool update --global $Tool
                    }
                }
            } elseif ($DotnetTools.IsPresent) {
                Write-Error "The .NET SDK is not installed." -Category NotInstalled
            }
        }

        if ($Npm.IsPresent -or $All.IsPresent) {
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                # Names of global npm packages to exclude from the update.
                $NpmBlacklist = @()

                # Update npm itself first
                npm install --global npm@latest

                if ($NpmBlacklist.Count -eq 0) {
                    npm update --global
                } else {
                    $Installed = npm ls --global --depth=0 --json | ConvertFrom-Json
                    $GlobalPackages = $Installed.dependencies.PSObject.Properties.Name

                    foreach ($Package in $GlobalPackages) {
                        if ($Package -eq "npm" -or $Package -in $NpmBlacklist) { continue }
                        npm update --global $Package
                    }
                }
            } elseif ($Npm.IsPresent) {
                Write-Error "npm is not installed." -Category NotInstalled
            }
        }

        if ($CleanUp.IsPresent) {
            if ($IsMacOS) {
                if (Get-Command xcrun -ErrorAction SilentlyContinue) {
                    # Delete every simulator marked as "unavailable" (e.g. left behind by removed runtimes)
                    xcrun simctl delete unavailable

                    # Clean up unused versions to free up disk space.
                    brew cleanup
                } else {
                    Write-Error "xcrun is not available. Install the Xcode command line tools with `"xcode-select --install`"." -Category NotInstalled
                }
            } elseif ($IsWindows) {
                # Purge temporary files, thumbnail caches and Windows Update leftovers (without any user interaction).
                cleanmgr /verylowdisk
            } else {
                Write-Error "Clean-up is not implemented for this platform." -Category NotImplemented
            }
        }
    }
}
