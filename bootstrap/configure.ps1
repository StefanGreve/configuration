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
    $Assets = [Path]::Combine($HOME, ".config", "assets")
    $ScriptsFolder = $env:PROFILE_LOAD_CUSTOM_SCRIPTS ?? [Path]::Combine($HOME, "Documents", "Scripts")

    $Total = $All.IsPresent ? 4 : $PSBoundParameters.Count
    $Step = 1

    if ($Total -eq 0) {
        Write-Error "Insufficient number of parameters supplied to this Cmdlet" -Category NotSpecified -ErrorAction Stop
    }

    Push-Location -Path $Root
}
process {
    #region Symlink Config Files
    if ($LinkConfiguration.IsPresent -or $All.IsPresent) {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Symlink configuration files . . ."

        $Links = $Config | Select-Object -ExpandProperty $OperatingSystem
        $Links.PsObject.Properties.Value | Foreach-Object {
            foreach ($File in $_) {
                $Arguments = @{
                    Path = $ExecutionContext.InvokeCommand.ExpandString($File.Target)
                    Value = [Path]::Combine($Root, $File.Path)
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
    #endregion

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
                [Environment]::SetEnvironmentVariable("GIT_SSH", "C:/Windows/System32/OpenSSH/ssh.exe", [EnvironmentVariableTarget]::User)
            }
        } elseif ($IsMacOS) {
            if ($null -eq $env:GIT_SSH) {
                ssh-add ~/.ssh/ed_25519
            }

            # Update permissions for GNUPG
            $GNUPG =  New-Item ~/.gnupg -ItemType Directory -Force
            chmod 700 $GNUPG.FullName

            # Restart GPG agent
            gpgconf --kill gpg-agent
            gpgconf --launch gpg-agent
        } else {
            Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
        }

        $Step++
    }

    #region Symlink Scripts
    if ($LinkScripts.IsPresent -or $All.IsPresent) {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Symlink custom PowerShell scripts . . ."

        $Scripts = Get-ChildItem -Path $([Path]::Combine($Root, "scripts")) -Filter *.ps1
        $Scripts | ForEach-Object {
            $Arguments = @{
                Path = [Path]::Combine($ScriptsFolder, $_.Name)
                Value = $_.FullName
                ItemType = "SymbolicLink"
                Force = $true
            }

            Write-Host "[ LINK ] " -ForegroundColor Green -NoNewline
            Write-Host $Arguments.Value -ForegroundColor Cyan -NoNewline
            Write-Host " -> $($Arguments.Path)"
            New-Item @Arguments | Out-Null
        }

        $Step++
    }
    #endregion

    #region Copy Assets
    if ($CopyAssets.IsPresent -or $All.IsPresent) {
        Write-Host "[$Step/$Total] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Copy Assets to $Assets . . ."
        New-Item -ItemType Directory -Path $Assets -Force | Out-Null
        Copy-Item -Path $([Path]::Combine($Root, "assets", "icons")) -Recurse -Destination $Assets -Force
        $Step++
    }
    #endregion
}
clean {
    Pop-Location
}
