#
# Sourced by every zsh: login, interactive, and scripts. Keep it minimal.
#
# PATH is deliberately not set here. /etc/zprofile runs path_helper afterwards, which would demote any
# entry added at this stage below the system directories.
#

# Keep both arrays unique-valued. Note that this only takes effect on assignment to the array itself, not
# to the tied PATH scalar, which is why .zprofile and .zshrc re-assign `path` after sourcing .profile.
typeset -U path fpath

# === VARS =====================================================================

# dotnet: bootstrap/macos/dotnet.sh installs the SDK system-wide
export DOTNET_ROOT="/usr/local/share/dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# powershell
export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK="LTS"

# brew
export HOMEBREW_NO_ANALYTICS=1

# programs
export EDITOR="nvim"

# guarded: .zshenv also runs without a terminal, where tty(1) yields "not a tty"
[[ -t 0 ]] && export GPG_TTY=${TTY:-$(tty)}
