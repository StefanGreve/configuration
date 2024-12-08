function Get-OperatingSystem {
    if ([OperatingSystem]::IsWindows()) {
        "Windows"
    } elseif ([OperatingSystem]::IsLinux()) {
        "Linux"
    } elseif ([OperatingSystem]::IsMacOS()) {
        "MacOS"
    } else {
        Write-Error "Unsupported Operating System" -Category DeviceError -ErrorAction Stop
    }
}

function Install-WinGet {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Id
    )

    process {
        foreach ($i in $Id) {
            winget install --id $i --accept-package-agreements --accept-source-agreements --disable-interactivity
        }
    }
}
