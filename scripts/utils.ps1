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

function Test-Command {
    [OutputType([bool])]
    param(
        [string] $Name
    )

    $PrevPreference = $ErrorActionPreference

    try {
        $ErrorActionPreference = "stop"
        $_ = Get-Command $Name
        return $true
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $PrevPreference
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

function Install-WingetPackage {
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
