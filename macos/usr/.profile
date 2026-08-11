#
# User-defined environment variables
#

# === VARS =====================================================================
export GPG_TTY=$(tty)

# dotnet
export DOTNET_ROOT="~/.dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# powershell
export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK="LTS"

# brew
export HOMEBREW_NO_ANALYTICS=1

# powershell profile settings
export PROFILE_ENABLE_BRANCH_USERNAME=1
export PROFILE_LOAD_CUSTOM_SCRIPTS="~/Documents/Scripts"

# === PATH =====================================================================
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# python packages (pipx)
export PATH="$PATH:~/.local/bin"

# brew packages
export PATH="$PATH:/opt/homebrew/bin"

# dotnet tools
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"

# rust tools
export PATH="$PATH:~/.cargo/bin"

# === MISC =====================================================================
