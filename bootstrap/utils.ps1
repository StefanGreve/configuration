#Requires -Version 7.4

using namespace System.Collections.Generic

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
            brew install --yes $p
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

function Install-DotnetTool {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Name
    )

    process {
        foreach ($n in $Name) {
            dotnet tool install $n --global
        }
    }
}

function Install-Npm {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Package
    )

    process {
        foreach ($p in $Package) {
            npm install --global $p
        }
    }
}

function Install-PSModule {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Name
    )

    process {
        foreach ($n in $Name) {
            Install-Module -Name $n -Scope CurrentUser -Repository PSGallery -Force -AcceptLicense
        }
    }
}

function Install-UvTool {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Package
    )

    process {
        foreach ($p in $Package) {
            uv tool install --force $p
        }
    }
}

function Install-VsCodeExtension {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $ExtensionId
    )

    process {
        foreach ($e in $ExtensionId) {
            code --install-extension $e --force
        }
    }
}

function Install-WinGet {
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]] $Id
    )

    begin {
        $i = 1
        $Packages = [List[string]]::new()
    }
    process {
        # It's not possible to know how many items are piped into this function
        # unless we collect these items one by one, and do the actual processing
        # at the end. The verbose switch implementation is needed because the
        # output from winget doesn't give away the name of the package that it is
        # trying to install
        foreach ($PackageId in $Id) {
            $Packages.Add($PackageId)
        }
    }
    end {
        foreach ($PackageId in $Packages) {
            if ($PSBoundParameters.ContainsKey("Verbose")) {
                Write-Host ("[{0,3}/{1,3}] " -f $i, $Packages.Count) -NoNewline -ForegroundColor DarkGray
                Write-Host "Installing " -NoNewline
                Write-Host $PackageId -ForegroundColor Cyan -NoNewline
                Write-Host " . . ."
                $i += 1
            }

            winget install --id $PackageId `
                --accept-package-agreements `
                --accept-source-agreements `
                --disable-interactivity
        }
    }
}

function Register-McpServer {
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string] $Name,

        [Parameter(Position = 1, Mandatory)]
        [psobject] $Definition
    )

    process {
        # User scope keeps the server available in every project. add-json refuses to
        # overwrite an existing registration, so the entry is dropped beforehand to keep
        # repeated bootstrap runs idempotent; removing an absent server is not an error.
        claude mcp remove $Name --scope user *> $null

        claude mcp add-json $Name ($Definition | ConvertTo-Json -Compress) --scope user
    }
}
