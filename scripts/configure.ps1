using namespace System.IO

[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(ParameterSetName = "Custom")]
    [switch] $LinkConfiguration,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $AddUserSettings,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $LinkScripts,

    [Parameter(ParameterSetName = "Custom")]
    [switch] $CopyAssets,

    [Parameter(ParameterSetName = "All", Mandatory)]
    [switch] $All
)

begin {
    $Root = git rev-parse --show-toplevel
    . $([Path]::Combine($Root, "scripts", "utils.ps1"))

    $OperatingSystem = Get-OperatingSystem
    $Config = Get-Content -Path $([Path]::Combine($Root, "settings", "config.json")) -Raw | ConvertFrom-Json
    $Assets = [Path]::Combine($HOME, ".config", "assets")
    $Scripts = $env:PROFILE_LOAD_CUSTOM_SCRIPTS ?? [Path]::Combine($HOME, "Documents", "Scripts")

    $Total = $All.IsPresent ? 4 : $PSBoundParameters.Count
    $Step = 1

    if ($Total -eq 0) {
        Write-Error "Insufficient number of parameters supplied to this Cmdlet" -ErrorAction Stop
    }

    Push-Location -Path $Root
}
process {
    if ($LinkConfiguration.IsPresent -or $All.IsPresent) {
        Write-Status -Message "Symlink configuration files . . ." -Step $Step -Total $Total

        $Links = $Config | Select-Object -ExpandProperty $OperatingSystem
        $Links.PsObject.Properties.Value | Foreach-Object -ThrottleLimit 5 -Parallel {
            foreach ($File in $_) {
                $Arguments = @{
                    Path = $ExecutionContext.InvokeCommand.ExpandString($File.Target)
                    # see also: https://github.com/PowerShell/PowerShell/issues/12804
                    Value = [System.IO.Path]::Combine($using:Root, $File.Path)
                    ItemType = "SymbolicLink"
                    Force = $true
                }

                New-Item @Arguments | Out-Null
            }
        }

        $Step++
    }

    if ($AddUserSettings.IsPresent -or $All.IsPresent) {
        Write-Status -Message "Apply platform-specific settings . . ." -Step $Step -Total $Total

        switch ($OperatingSystem) {
            "Windows" {
                # NOTE: ssh-add will ask for a passphrase (if enabled), which
                # disrupts the automatic flow of execution. A future workaround
                # might use the SSH_ASKPASS environment variable which defines
                # the prompt program to hardcode the passphrase in a custom script,
                # though this would have to be set prior to this line
                if ($null -eq $env:GIT_SSH) {
                    ssh-add $home/.ssh/id_rsa
                    Set-Service ssh-agent -StartupType Automatic
                    [Environment]::SetEnvironmentVariable("GIT_SSH", "C:/Windows/System32/OpenSSH/ssh.exe", [EnvironmentVariableTarget]::User)
                }
            }
            "Linux" {
                [NotImplementedException]::new("TODO")
            }
            "MacOS" {
                [NotImplementedException]::new("TODO")
            }
        }

        $Step++
    }

    if ($LinkScripts.IsPresent -or $All.IsPresent) {
        Write-Status -Message "Symlink custom PowerShell scripts . . ." -Step $Step -Total $Total

        $Tools = Get-ChildItem -Path $([Path]::Combine($Root, "tools")) -Filter *.ps1
        $Tools | ForEach-Object -ThrottleLimit 5 -Parallel {
            $Arguments = @{
                Path = [System.IO.Path]::Combine($using:Scripts, $_.Name)
                Value = $_.FullName
                ItemType = "SymbolicLink"
                Force = $true
            }

            New-Item @Arguments | Out-Null
        }

        $Step++
    }

    if ($CopyAssets.IsPresent -or $All.IsPresent) {
        Write-Status -Message "Copy Assets to $Assets . . ." -Step $Step -Total $Total
        New-Item -ItemType Directory -Path $Assets -Force | Out-Null
        Copy-Item -Path $([Path]::Combine($Root, "assets", "icons")) -Recurse -Destination $Assets -Force
        $Step++
    }
}
clean {
    Pop-Location
}
