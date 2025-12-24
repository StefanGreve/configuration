using namespace System.IO

<#
    .SYNOPSIS
    Installs Windows Package Manager (WinGet) and its required dependencies.

    .DESCRIPTION
    Downloads and installs the Windows Package Manager (WinGet) MSIX bundle and
    any required dependency packages.

    If dependent AppX/MSIX packages are currently in use, the installation may fail
    with HRESULT 0x80073D02.

    .PARAMETER SkipCleanup
    If specified, downloaded installation artifacts (MSIX bundle and dependency
    packages) are preserved on disk after a successful installation. By default,
    all temporary artifacts are removed when installation completes successfully.

    .EXAMPLE
    Install-WinGet

    Installs WinGet and removes all temporary download artifacts upon success.

    .NOTES
    Requires administrative privileges.
    Uses Add-AppxPackage and may require a clean user session (no running Store apps).
#>
function Install-WinGet {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $SkipCleanup
    )

    begin {
        if (!$IsWindows) {
            Write-Error "This Cmdlet only works on the Windows Operating System" `
                -Category DeviceError `
                -ErrorAction Stop
        }

        $Architecture = $(Get-CimInstance Win32_OperatingSystem -Verbose:$false).OSArchitecture -eq "64-bit" ? "x64" : "x86"

        Push-Location -Path $([Path]::Combine($HOME, "Downloads"))
    }
    process {
        $WinGetAssets = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -Verbose:$false `
            | Select-Object -ExpandProperty "assets"

        Write-Verbose "Download WinGet installer dependencies"
        $WingetDependenciesZip = "WingetDependencies.zip"
        $DesktopAppInstallerDependencies = $WinGetAssets `
            | Where-Object { $_.name -eq "DesktopAppInstaller_Dependencies.zip" } `
            | Select-Object -ExpandProperty browser_download_url

        Invoke-WebRequest -Uri $DesktopAppInstallerDependencies `
            -OutFile $WingetDependenciesZip `
            -Verbose:$false
        Write-Verbose "Unzip ${WingetDependenciesZip}"
        Expand-Archive -Path $WingetDependenciesZip -Force

        $DependenciesPath = Join-Path -Path $([Path]::ChangeExtension($WingetDependenciesZip, $null)) `
            -ChildPath $Architecture
        $Dependencies = Get-ChildItem -Path $DependenciesPath -Filter "*.appx*" `
            | Select-Object -ExpandProperty FullName

        Write-Verbose "Download WinGet"
        $WinGet = "winget.msixbundle"
        $DesktopAppInstallerMsixBundle = $WinGetAssets `
            | Where-Object { $_.name -like "Microsoft.DesktopAppInstaller_*.msixbundle" } `
            | Select-Object -ExpandProperty browser_download_url

        Invoke-WebRequest -Uri $DesktopAppInstallerMsixBundle `
            -OutFile $WinGet `
            -Verbose:$false

        # NOTE: Deployment may fail (HRESULT: 0x80073D02) if one or more running AppX/MSIX
        # packages are currently using shared frameworks or resources required by this
        # installation (e.g., Microsoft Store, DesktopAppInstaller, Widgets, or other
        # UWP apps). Ensure all dependent Store apps are closed, or perform the install
        # after a reboot and before launching any user apps.
        Write-Verbose "Install WinGet"
        Add-AppxPackage -Path $WinGet `
            -DependencyPath $Dependencies `
            -Confirm:$false `
            -Verbose:$false
        $InstallSucceeded = $?
    }
    clean {
        if ($InstallSucceeded -and !$SkipCleanup.IsPresent) {
            $OriginalEAP = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            Remove-Item -Path $WingetDependenciesZip -Force
            Remove-Item -Path $DependenciesPath -Recurse -Force
            Remove-Item -Path $DesktopAppInstallerMsixBundle -Force
            $ErrorActionPreference = $OriginalEAP
        }

        Pop-Location
    }
}
