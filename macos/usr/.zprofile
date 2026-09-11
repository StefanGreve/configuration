#
# Login shells only, after /etc/zprofile has run path_helper.
#

# Sets HOMEBREW_PREFIX, MANPATH and INFOPATH besides prepending to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

[[ -f ~/.profile ]] && source ~/.profile

# collapse duplicates; see the note in .zshrc
path=($path)
