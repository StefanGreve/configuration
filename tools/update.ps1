function Update-System {
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "Option")]
        [switch] $Help,

        [Parameter(ParameterSetName = "Option")]
        [switch] $Applications,

        [Parameter(ParameterSetName = "All")]
        [switch] $All
    )

    process {
        if ($Help.IsPresent -or $All.IsPresent) {
            Update-Help -UICulture "en-US" -ErrorAction SilentlyContinue -ErrorVariable UpdateErrors -Force
        }

        if ($Applications.IsPresent -or $All.IsPresent) {
            switch ($global:OperatingSystem) {
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
}
