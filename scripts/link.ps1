using namespace System.IO

#region Initialization

$Root = git rev-parse --show-toplevel
$Config = Get-Content -Path $([Path]::Combine($Root, "settings", "config.json")) -Raw | ConvertFrom-Json
$OperatingSystem = if ([OperatingSystem]::IsWindows()) {
    "Windows"
} elseif ([OperatingSystem]::IsLinux()) {
    "Linux"
} elseif ([OperatingSystem]::IsMacOS()) {
    "MacOS"
} else {
    Write-Error "Unsupported Operating System" -ErrorAction Stop -Category DeviceError
}

#endregion

Push-Location -Path $Root

#region Create Symbolic Links

$Links = $Config | Select-Object -ExpandProperty $OperatingSystem
$Links.PsObject.Properties.Value | Foreach-Object -ThrottleLimit 5 -Parallel {
    foreach ($File in $_) {
        $Arguments = @{
            Path = $ExecutionContext.InvokeCommand.ExpandString($File.Target)
            # see also: https://github.com/PowerShell/PowerShell/issues/12804
            Value = [Sysytem.IO.Path]::Combine($using:Root, $File.Path)
            ItemType = "SymbolicLink"
            Force = $true
        }

        New-Item @Arguments
    }
}

#endregion

Pop-Location
