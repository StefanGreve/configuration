using namespace System.IO

#region Initialization

$Root = git rev-parse --show-toplevel
. $([Path]::Combine($Root, "scripts", "utils.ps1"))
$OperatingSystem = Get-OperatingSystem
$Config = Get-Content -Path $([Path]::Combine($Root, "settings", "config.json")) -Raw | ConvertFrom-Json
$Assets = [Path]::Combine($HOME, ".config", "assets")
$Scripts = $env:PROFILE_LOAD_CUSTOM_SCRIPTS ?? [Path]::Combine($HOME, "Documents", "Scripts")
$Total = 3

#endregion

Push-Location -Path $Root

#region Link Settings

Write-Status -Message "Symlink configuration files . . ." -Step 1 -Total $Total

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

#endregion

#region Link Custom Scripts

Write-Status -Message "Symlink custom PowerShell scripts . . ." -Step 2 -Total $Total

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

#endregion

#region Copy Assets

Write-Status -Message "Copy icons to $Assets . . ." -Step 3 -Total $Total

New-Item -ItemType Directory -Path $Assets -Force | Out-Null
Copy-Item -Path $([Path]::Combine($Root, "assets", "icons")) -Recurse -Destination $Assets -Force

#endregion

Pop-Location
