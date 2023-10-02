using namespace System.IO

#region Initialization

$Root = git rev-parse --show-toplevel
. $([Path]::Combine($Root, "scripts", "utils.ps1"))
$OperatingSystem = Get-OperatingSystem
$Config = Get-Content -Path $([Path]::Combine($Root, "settings", "config.json")) -Raw | ConvertFrom-Json

#endregion

Push-Location -Path $Root

#region Create Symbolic Links

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

        New-Item @Arguments
    }
}

#endregion

Pop-Location
