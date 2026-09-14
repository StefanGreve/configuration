#Requires -Version 7.4

#
# Session-level overrides; bootstrap/configure.ps1 -AddUserSettings writes these to User scope.
# Only variables read by child processes belong here: anything the shell reads about itself at
# startup must go to User scope, since this file is dot-sourced after that point.
#

# dotnet
$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"
$env:DOTNET_CLI_UI_LANGUAGE = "en-US"
$env:DOTNET_NOLOGO = "1"
