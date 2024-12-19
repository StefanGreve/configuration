#
# User-defined environment variables
#

# === KEYS =====================================================================
export GPG_TTY=$(tty)
export DOTNET_ROOT="~/.dotnet"

# powershell profile settings
export PROFILE_ENABLE_BRANCH_USERNAME=1
export PROFILE_LOAD_CUSTOM_SCRIPTS="~/Documents/Scripts"

# === PATH =====================================================================
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
export PATH="$PATH:~/.cargo/bin"
