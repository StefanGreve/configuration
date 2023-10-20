[OutputType([void])]
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = "Option")]
    [switch] $Help,

    [Parameter(ParameterSetName = "Option")]
    [switch] $Applications,

    [Parameter(ParameterSetName = "Option")]
    [switch] $Modules,

    [Parameter(ParameterSetName = "All")]
    [switch] $All
)

begin {
    $Root = git rev-parse --show-toplevel
    . $([Path]::Combine($Root, "scripts", "utils.ps1"))
    $OperatingSystem = Get-OperatingSystem
}
process {
    if ($Help.IsPresent -or $All.IsPresent) {
        Update-Help -UICulture "en-US" -ErrorAction SilentlyContinue -ErrorVariable UpdateErrors -Force
    }

    if ($Applications.IsPresent -or $All.IsPresent) {
        switch ($OperatingSystem) {
            ([OS]::Windows) {
                winget upgrade --all --silent
            }
            ([OS]::Linux) {
                [NotImplementedException]::new("TODO")
            }
            ([OS]::MacOS) {
                [NotImplementedException]::new("TODO")
            }
        }
    }
}
