function Update-System {
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "Option")]
        [switch] $Help,

        [Parameter(ParameterSetName = "Option")]
        [switch] $Applications,

        [Parameter(ParameterSetName = "All")]
        [switch] $All
    )

    process {
        if ($Help.IsPresent -or $All.IsPresent) {
            Update-Help -UICulture "en-US" -ErrorAction SilentlyContinue -ErrorVariable UpdateErrors -Force
        }

        if ($Applications.IsPresent -or $All.IsPresent) {
            if ($IsWindows) {
                # Some programs may require some user interaction for GUI installer wizards (e.g. Jet Brains products)
                winget upgrade --all `
                    --silent `
                    --accept-package-agreements `
                    --accept-source-agreements `
                    --include-unknown `
                    --disable-interactivity
            } elseif ($IsMacOS) {
                # 1. Update homebrew itself, to ensure that the latest version information is available.
                brew update

                # 2. Upgrade all installed packages
                brew upgrade

                # 3. Check for any remaining outdated packages after the upgrade procedure.
                brew outdated

                # 4. After upgrading packages, older versions may still remain on the system. This command
                # cleans up unused versions to free up disk space.
                brew cleanup
            } else {
                Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
            }
        }
    }
}
