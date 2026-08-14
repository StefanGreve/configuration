#Requires -Version 7.4

# dotnet
$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"
$env:DOTNET_NOLOGO = "1"

# powershell
$env:POWERSHELL_TELEMETRY_OPTOUT = "1"
$env:POWERSHELL_UPDATECHECK = "LTS"

# powershell profile settings
$env:PROFILE_ENABLE_BRANCH_USERNAME = "1"
$env:PROFILE_LOAD_CUSTOM_SCRIPTS = "~/Documents/Scripts"
