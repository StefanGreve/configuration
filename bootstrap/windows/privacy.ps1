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

    .PARAMETER RemoveConsumerApps
    Removes the specified consumer app packages for all users and deprovisions them, so that new
    user profiles do not receive them either. If dism.exe cannot remove a provisioning entry, for
    example because its files are missing, the script marks the package family as deprovisioned
    instead. Accepts All or any of BingNews, BingSearch, BingWeather, ClientWebExperience
    (Widgets), Copilot, Cortana, CrossDevice, Getstarted (Tips), WindowsFeedbackHub, and
    YourPhone (Phone Link). Removed apps can be reinstalled from the Microsoft Store.

    .PARAMETER All
    Runs every step, including -RemoveConsumerApps All.

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

    .EXAMPLE
    PS> .\privacy.ps1 -RemoveConsumerApps WindowsFeedbackHub, ClientWebExperience

    Removes Feedback Hub and Widgets for all users.
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

    [Parameter(ParameterSetName = "Custom")]
    [ValidateSet(
        "All", "BingNews", "BingSearch", "BingWeather", "ClientWebExperience", "Copilot", "Cortana", "CrossDevice",
        "Getstarted", "WindowsFeedbackHub", "YourPhone"
    )]
    [string[]] $RemoveConsumerApps,

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
        $DisableDeliveryOptimizationPeering.IsPresent
        $DisableTelemetryServices.IsPresent
        $DisableTelemetryTasks.IsPresent
        $EnableMacRandomization.IsPresent
        $RemoveConsumerApps.Count -gt 0
    )

    if (!$All.IsPresent -and $Steps -notcontains $true) {
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

    if ($RemoveConsumerApps.Count -gt 0 -or $All.IsPresent) {
        $ConsumerApps = [ordered]@{
            BingNews            = "Microsoft.BingNews_8wekyb3d8bbwe"
            BingSearch          = "Microsoft.BingSearch_8wekyb3d8bbwe"
            BingWeather         = "Microsoft.BingWeather_8wekyb3d8bbwe"
            ClientWebExperience = "MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy"
            Copilot             = "Microsoft.Copilot_8wekyb3d8bbwe"
            Cortana             = "Microsoft.549981C3F5F10_8wekyb3d8bbwe"
            CrossDevice         = "MicrosoftWindows.CrossDevice_cw5n1h2txyewy"
            Getstarted          = "Microsoft.Getstarted_8wekyb3d8bbwe"
            WindowsFeedbackHub  = "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe"
            YourPhone           = "Microsoft.YourPhone_8wekyb3d8bbwe"
        }
        $DeprovisionedKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned"

        $RemoveAll = $All.IsPresent -or "All" -in $RemoveConsumerApps
        $Selection = $ConsumerApps.GetEnumerator() | Where-Object { $RemoveAll -or $_.Key -in $RemoveConsumerApps }

        $InstalledPackages = Get-AppxPackage -AllUsers
        # Store-installed pwsh is packaged: the Dism cmdlets fail and all-user removals are denied
        $DismOutput = dism.exe /Online /Get-ProvisionedAppxPackages /English

        if ($LASTEXITCODE -ne 0) {
            Write-Error "dism.exe could not list provisioned packages (exit code ${LASTEXITCODE})" -Category ReadError
        }

        $ProvisionedPackages = $DismOutput |
            Select-String -Pattern '^PackageName : (.+)$' |
            ForEach-Object { $_.Matches[0].Groups[1].Value }

        foreach ($App in $Selection) {
            $Name, $Publisher = $App.Value.Split("_")
            $Marker = "${DeprovisionedKey}\$($App.Value)"
            $Deprovisioned = Test-Path -Path $Marker
            $Installed = @($InstalledPackages | Where-Object PackageFamilyName -eq $App.Value)
            $Provisioned = @($ProvisionedPackages |
                Where-Object { !$Deprovisioned -and $_ -like "${Name}_*_${Publisher}" })

            if ($Installed.Count -eq 0 -and $Provisioned.Count -eq 0) {
                Write-Verbose "Skip absent app package ${Name}"
            }
            elseif ($PSCmdlet.ShouldProcess($Name, "Remove for all users and deprovision")) {
                foreach ($PackageName in $Provisioned) {
                    dism.exe /Online /Remove-ProvisionedAppxPackage /PackageName:$PackageName /English | Out-Null

                    if ($LASTEXITCODE -ne 0) {
                        New-Item -Path $Marker -Force | Out-Null
                        Write-Warning "Marked ${Name} as deprovisioned; dism.exe failed (exit code ${LASTEXITCODE})"
                    }
                }

                foreach ($Package in Get-AppxPackage -AllUsers -Name $Name) {
                    $Command = "Remove-AppxPackage -Package '$($Package.PackageFullName)' -AllUsers"
                    $Output = powershell.exe -NoProfile -NonInteractive -Command $Command 2>&1

                    if ($LASTEXITCODE -ne 0) {
                        $Reason = $Output | Select-Object -First 1
                        Write-Error "Could not remove $($Package.PackageFullName): ${Reason}" -Category WriteError
                    }
                }
            }
        }
    }
}
