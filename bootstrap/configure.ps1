#Requires -Version 7.4

using namespace System
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
    . $([Path]::Combine($Root, "bootstrap", "utils.ps1"))

    $OperatingSystem = Get-OperatingSystem

    $Config = Get-Content -Path $([Path]::Combine($Root, "settings", "config.json")) -Raw | ConvertFrom-Json
    $ProfileSettings = Get-Content -Path $([Path]::Combine($Root, "appSettings", "profile", "settings.json")) -Raw | ConvertFrom-Json
    $ScriptsFolder = $ProfileSettings.DotSourceDirectory.Replace("~", $HOME)

    $Total = $All.IsPresent ? 4 : $PSBoundParameters.Count
    $Step = 1

    if ($Total -eq 0) {
        Write-Error "Insufficient number of parameters supplied to this Cmdlet" -Category NotSpecified -ErrorAction Stop
    }

    Push-Location -Path $Root
}
process {
    if ($LinkConfiguration.IsPresent -or $All.IsPresent) {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Symlink configuration files . . ."

        $Links = $Config | Select-Object -ExpandProperty $OperatingSystem
        $Links.PsObject.Properties.Value | Foreach-Object {
            foreach ($Key in $_) {
                if (!$IsWindows -and $Key.Path.StartsWith("./windows")) { continue }
                if (!$IsMacOS -and $Key.Path.StartsWith("./macos")) { continue }
                if (!$IsLinux -and $Key.Path.StartsWith("./linux")) { continue }

                $Arguments = @{
                    Path = $ExecutionContext.InvokeCommand.ExpandString($Key.Target)
                    Value = [Path]::Combine($Root, $Key.Path)
                    ItemType = "SymbolicLink"
                    Force = $true
                }

                Write-Host "[ LINK ] " -ForegroundColor Green -NoNewline
                Write-Host $Arguments.Value -ForegroundColor Cyan -NoNewline
                Write-Host " -> $($Arguments.Path)"
                New-Item @Arguments | Out-Null
            }
        }

        $Step++
    }

    if ($AddUserSettings.IsPresent -or $All.IsPresent) {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Apply platform-specific settings . . ."

        if ($IsWindows) {
            # NOTE: ssh-add will ask for a passphrase (if enabled), which
            # disrupts the automatic flow of execution. A future workaround
            # might use the SSH_ASKPASS environment variable which defines
            # the prompt program to hardcode the passphrase in a custom script,
            # though this would have to be set prior to this line
            if ($null -eq $env:GIT_SSH) {
                ssh-add $HOME/.ssh/id_rsa
                Set-Service ssh-agent -StartupType Automatic
                Start-Service ssh-agent
                [Environment]::SetEnvironmentVariable("GIT_SSH", "C:/Windows/System32/OpenSSH/ssh.exe", [EnvironmentVariableTarget]::User)
            }
        } elseif ($IsMacOS) {
            if ($null -eq $env:GIT_SSH) {
                # Started to use a new key generation algorithm for MacOS
                ssh-add ~/.ssh/ed_25519
            }

            # Update permissions for GNUPG
            $GNUPG =  New-Item ~/.gnupg -ItemType Directory -Force
            chmod 700 $GNUPG.FullName

            # Restart the GPG agent so it picks up the refreshed permissions.
            gpgconf --kill gpg-agent
            gpgconf --launch gpg-agent
        } else {
            Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
        }

        $Step++
    }

    if ($LinkScripts.IsPresent -or $All.IsPresent) {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Symlink custom PowerShell scripts . . ."

        $Scripts = Get-ChildItem -Path $([Path]::Combine($Root, "scripts")) -Filter "*.ps1" -Recurse
        $Scripts | ForEach-Object {
            $Arguments = @{
                Path = [Path]::Combine($ScriptsFolder, $_.Name)
                Value = $_.FullName
                ItemType = "SymbolicLink"
                Force = $true
            }

            if (!$IsWindows -and $Arguments.Value.Contains("windows")) { return }
            if (!$IsMacOS -and $Arguments.Value.Contains("macos")) { return }
            if (!$IsLinux -and $Arguments.Value.Contains("linux")) { return }

            Write-Host "[ LINK ] " -ForegroundColor Green -NoNewline
            Write-Host $Arguments.Value -ForegroundColor Cyan -NoNewline
            Write-Host " -> $($Arguments.Path)"
            New-Item @Arguments | Out-Null
        }

        $Step++
    }

    if ($CopyAssets.IsPresent -or $All.IsPresent) {
        $Assets = [Path]::Combine([Environment]::GetFolderPath("MyPictures"), ".configuration", "assets")
        New-Item -Path $Assets -ItemType Directory -Force | Out-Null

        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Copy assets to $Assets . . ."

        Get-ChildItem -Path $([Path]::Combine($Root, "assets")) -Directory | ForEach-Object {
            $Destination = New-Item -Path $([Path]::Combine($Assets, $_.Name)) -ItemType Directory -Force
            Copy-Item -Path $([Path]::Combine($_.FullName, "*")) -Recurse -Destination $Destination -Force
        }
        $Step++
    }
}
clean {
    Pop-Location
}
