#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Enforces Windows privacy settings that cannot be expressed as registry values.

    .DESCRIPTION
    Complements the registry files in settings\ with privacy settings that must be applied
    through commands. The script performs the following steps:

    - Delivery Optimization: sets the download mode to CdnOnly (HTTP only, no peering) and
      deletes the local cache, including pinned files, so that no content listed by
      Get-DeliveryOptimizationStatus remains available for upload to other peers.

    .INPUTS
    None. You cannot pipe objects to this script.

    .OUTPUTS
    None. This script does not produce any output.

    .NOTES
    Requires administrative privileges.
    Delivery Optimization rejects local changes to a download mode configured through Group
    Policy or MDM. In that case, the script leaves the mode unchanged and writes a warning if
    the effective mode still permits peering.

    .EXAMPLE
    PS> .\privacy.ps1 -WhatIf -Verbose

    Lists the changes the script would make without applying them.
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([void])]
param()

begin {
    if (!$IsWindows) {
        Write-Error "This script only works on the Windows Operating System" `
            -Category DeviceError `
            -ErrorAction Stop
    }
}
process {
    #region Delivery Optimization
    $Config = Get-DOConfig -Verbose:$false

    if ($Config.DownloadModeProvider -in "RegistryProvider", "MdmProvider") {
        Write-Verbose "Skip setting the download mode because it is set by policy ($($Config.DownloadModeProvider))"
    }
    elseif ($PSCmdlet.ShouldProcess("Delivery Optimization", "Set download mode to CdnOnly")) {
        Set-DODownloadMode -DownloadMode CdnOnly
        $Config = Get-DOConfig -Verbose:$false
    }

    if ($PSCmdlet.ShouldProcess("Delivery Optimization cache", "Delete all files including pinned files")) {
        Delete-DeliveryOptimizationCache -IncludePinnedFiles -Force 6>$null
    }

    $Summary = "mode '$($Config.DownloadMode)' (provider: $($Config.DownloadModeProvider))"

    if ($Config.DownloadMode -notin "CdnOnly", "Simple", "Bypass") {
        Write-Warning "Delivery Optimization still permits peering: ${Summary}"
    }
    else {
        Write-Verbose "Delivery Optimization peering is disabled: ${Summary}"
    }
    #endregion
}
