#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Enforces Windows privacy settings that cannot be expressed as registry values.

    .DESCRIPTION
    Complements the registry files in settings\ with privacy settings that must be applied
    through commands. Each step runs only when its switch is specified; -All runs every step.
    Candidates for further steps are tracked in privacy.md at the repository root.

    .PARAMETER DisableDeliveryOptimizationPeering
    Sets the Delivery Optimization download mode to CdnOnly (HTTP only, no peering) and deletes
    the local cache, including pinned files, so that no content listed by
    Get-DeliveryOptimizationStatus remains available for upload to other peers.

    .PARAMETER DisableTelemetryServices
    Stops and disables services that collect usage data: Microsoft Usage and Quality Insights
    (wuqisvc) and the HP analytics services. Services that do not exist on the device are
    skipped.

    .PARAMETER DisableTelemetryTasks
    Disables the scheduled tasks that collect diagnostic and usage data, such as the
    Compatibility Appraiser, Device Census, and the Customer Experience Improvement Program.
    Tasks that do not exist on the running Windows build are skipped.

    .PARAMETER EnableMacRandomization
    Enables random hardware (MAC) addresses on every physical Wi-Fi adapter, so that the device
    cannot be tracked by its MAC address across Wi-Fi networks.

    .PARAMETER All
    Runs every step.

    .INPUTS
    None. You cannot pipe objects to this script.

    .OUTPUTS
    None. This script does not produce any output.

    .NOTES
    Requires administrative privileges.
    Delivery Optimization rejects local changes to a download mode configured through Group
    Policy or MDM. In that case, the script leaves the mode unchanged and writes a warning if
    the effective mode still permits peering.
    netsh refuses MAC randomization if the adapter does not support it or an administrator
    blocked it. In that case, the script writes a warning and continues.

    .EXAMPLE
    PS> .\privacy.ps1 -All -WhatIf -Verbose

    Lists the changes every step would make without applying them.

    .EXAMPLE
    PS> .\privacy.ps1 -DisableTelemetryTasks -EnableMacRandomization

    Disables the telemetry tasks and enables MAC randomization, but leaves Delivery Optimization
    unchanged.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Custom")]
[OutputType([void])]
param(
    [Parameter(ParameterSetName = "Custom")]
    [switch] $DisableDeliveryOptimizationPeering,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $DisableTelemetryServices,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $DisableTelemetryTasks,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $EnableMacRandomization,

    [Parameter(ParameterSetName = "All", Mandatory)]
    [switch] $All
)

begin {
    if (!$IsWindows) {
        Write-Error "This script only works on the Windows Operating System" `
            -Category DeviceError `
            -ErrorAction Stop
    }

    $Steps = @(
        $DisableDeliveryOptimizationPeering
        $DisableTelemetryServices
        $DisableTelemetryTasks
        $EnableMacRandomization
    )

    if (!$All.IsPresent -and $Steps.IsPresent -notcontains $true) {
        Write-Error "Specify -All or at least one step to run" -Category InvalidArgument -ErrorAction Stop
    }
}
process {
    if ($DisableDeliveryOptimizationPeering.IsPresent -or $All.IsPresent) {
        $Config = Get-DOConfig -Verbose:$false

        if ($Config.DownloadModeProvider -in "RegistryProvider", "MdmProvider") {
            Write-Verbose "Skip setting the download mode because policy sets it ($($Config.DownloadModeProvider))"
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
    }

    if ($DisableTelemetryServices.IsPresent -or $All.IsPresent) {
        $TelemetryServices = @(
            "HPAudioAnalytics"
            "HpTouchpointAnalyticsService"
            "wuqisvc"
        )

        foreach ($ServiceName in $TelemetryServices) {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

            if ($null -eq $Service) {
                Write-Verbose "Skip missing service ${ServiceName}"
            }
            elseif ($Service.StartType -eq "Disabled" -and $Service.Status -eq "Stopped") {
                Write-Verbose "Skip disabled service ${ServiceName}"
            }
            elseif ($PSCmdlet.ShouldProcess("$($Service.DisplayName) (${ServiceName})", "Disable and stop service")) {
                Set-Service -InputObject $Service -StartupType Disabled
                Stop-Service -InputObject $Service
            }
        }
    }

    if ($DisableTelemetryTasks.IsPresent -or $All.IsPresent) {
        $TelemetryTasks = @(
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp"
            "\Microsoft\Windows\Application Experience\MareBackup"
            "\Microsoft\Windows\Autochk\Proxy"
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
            "\Microsoft\Windows\Device Information\Device"
            "\Microsoft\Windows\Device Information\Device User"
            "\Microsoft\Windows\Feedback\Siuf\DmClient"
            "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
            "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting"
            "\Microsoft\Windows\PI\Sqm-Tasks"
            "\Microsoft\Windows\Sustainability\SustainabilityTelemetry"
            "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
        )

        foreach ($TelemetryTask in $TelemetryTasks) {
            $TaskPath = "$(Split-Path -Path $TelemetryTask -Parent)\"
            $TaskName = Split-Path -Path $TelemetryTask -Leaf
            $Task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue

            if ($null -eq $Task) {
                Write-Verbose "Skip missing task ${TelemetryTask}"
            }
            elseif ($Task.State -eq "Disabled") {
                Write-Verbose "Skip disabled task ${TelemetryTask}"
            }
            elseif ($PSCmdlet.ShouldProcess($TelemetryTask, "Disable scheduled task")) {
                Disable-ScheduledTask -InputObject $Task | Out-Null
            }
        }
    }

    if ($EnableMacRandomization.IsPresent -or $All.IsPresent) {
        $Adapters = Get-NetAdapter -Physical | Where-Object NdisPhysicalMedium -eq 9

        if (!$Adapters) {
            Write-Verbose "Skip MAC randomization because no Wi-Fi adapter is present"
        }

        foreach ($Adapter in $Adapters) {
            if ($PSCmdlet.ShouldProcess($Adapter.Name, "Enable MAC randomization")) {
                $Output = netsh wlan set randomization enabled=yes interface="$($Adapter.Name)"

                if ($LASTEXITCODE -ne 0) {
                    $Reason = ($Output | Where-Object { $_ }) -join " "
                    Write-Warning "Could not enable MAC randomization on $($Adapter.Name): ${Reason}"
                }
                else {
                    Write-Verbose "MAC randomization is enabled on $($Adapter.Name)"
                }
            }
        }
    }
}
