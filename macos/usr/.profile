#
# PATH additions, kept POSIX-compatible so bash and sh sessions can reuse it.
#
# Sourced from both .zprofile and .zshrc so that login and non-login shells agree; `typeset -U path` in
# .zshenv makes the repeated sourcing a no-op.
#

# === PATH =====================================================================

# rust (rustup)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# python packages (pipx)
PATH="$HOME/.local/bin:$PATH"

# dotnet global tools; the SDK itself arrives via /etc/paths.d/dotnet
PATH="$HOME/.dotnet/tools:$PATH"

export PATH
