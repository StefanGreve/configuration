if (!(Get-Module( PowerTools))) {
    Install-Module PowerTools -Force
}

Import-Module PowerTools

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
