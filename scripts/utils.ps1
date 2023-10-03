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

function Write-Status {
    param(
        [int] $Step,

        [int] $Total,

        [string] $Message
    )

    process {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Message
    }
}
