#!/bin/zsh
#
# Writes zsh completion functions for the tools that ship a generator instead of a ready-made function,
# mirroring the RegisterNativeCompletions list of the PowerShell profile. Formulae that install their own
# function into $HOMEBREW_PREFIX/share/zsh/site-functions (brew, gh, git, op, pipx) are not repeated here.
#
# Re-run after upgrading a toolchain.
#

COMPLETIONS=${1:-$HOME/.local/share/zsh/site-functions}

mkdir -p "$COMPLETIONS" || exit 1

generated=0

generate() {
    local name=$1 file=$COMPLETIONS/_$1
    shift

    local binary=$(command -v "$1" 2> /dev/null)

    if [[ -z $binary ]]; then
        printf 'skip %s: %s is not installed\n' "$name" "$1"
        return
    fi

    if [[ -f $file && $file -nt $binary ]]; then
        printf 'keep %s\n' "$name"
        return
    fi

    # compinit only reads a file whose first line carries a tag, and pip prefixes its script with a banner
    local tag='/^#(compdef|autoload)/ { found = 1 } found'

    if ! "$@" 2> /dev/null | awk "$tag" > "$file.tmp" || [[ ! -s $file.tmp ]]; then
        rm -f "$file.tmp"
        printf 'fail %s\n' "$name"
        return
    fi

    mv "$file.tmp" "$file"
    printf 'make %s\n' "$name"
    generated=1
}

generate dotnet dotnet completions script zsh
generate bat    bat --completion zsh
generate uv     uv generate-shell-completion zsh
generate pip    pip3 completion --zsh
generate delta  delta --generate-completion zsh
generate rustup rustup completions zsh
generate cargo  rustup completions zsh cargo
generate deno   deno completions zsh

# macos/usr/.zshrc runs `compinit -C`, which reuses an existing dump rather than scanning fpath, so a new
# function stays invisible until the dump is gone
if [[ $generated -eq 1 ]]; then
    rm -f ${ZDOTDIR:-$HOME}/.zcompdump*(N)
    printf '\nRestart your shell to rebuild the completion dump.\n'
fi
