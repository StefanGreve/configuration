function Get-OperatingSystem {
    if ($IsWindows) {
        "Windows"
    } elseif ($IsLinux) {
        "Linux"
    } elseif ($IsMacOS) {
        "MacOS"
    } else {
        Write-Error "Unsupported Operating System" -Category DeviceError -ErrorAction Stop
    }
}

function Install-Brew {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Package
    )

    process {
        foreach ($p in $Package) {
            brew install $p
        }
    }
}

function Install-Cargo {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Crate
    )

    process {
        foreach ($c in $Crate) {
            cargo install --force $c
        }
    }
}

function Install-PipX {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Package
    )

    process {
        foreach ($p in $Package) {
            pipx install --force $p
        }
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
