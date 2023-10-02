function Get-OperatingSystem {
    if ([OperatingSystem]::IsWindows()) {
        "Windows"
    } elseif ([OperatingSystem]::IsLinux()) {
        "Linux"
    } elseif ([OperatingSystem]::IsMacOS()) {
        "MacOS"
    } else {
        Write-Error "Unsupported Operating System" -ErrorAction Stop -Category DeviceError
    }
}
