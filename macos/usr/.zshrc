#
# Interactive shells.
#

# A non-login interactive shell reads neither /etc/zprofile nor .zprofile, so it misses both path_helper
# and brew. Rebuild them here in the same order a login shell would; the guard keeps this fork-free in the
# common case, where the environment was inherited from a login shell.
if [[ -z $HOMEBREW_PREFIX ]]; then
    eval "$(/usr/libexec/path_helper -s)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

[[ -f ~/.profile ]] && source ~/.profile

# `typeset -U path` only deduplicates on assignment to the array; .profile has to assign to the PATH scalar
# to stay POSIX, so re-assign here to collapse the entries it added twice
path=($path)

# === HISTORY ==================================================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# === OPTIONS ==================================================================
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS NO_BEEP

# === COMPLETION ===============================================================
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# -C trusts the existing dump instead of re-scanning fpath on every start
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# === KEYBINDINGS ==============================================================
bindkey -e

# up/down search history using what has already been typed
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# === ALIASES ==================================================================
alias ll='ls -lAhG'
alias ..='cd ..'
alias vim='nvim'
alias grep='grep --color=auto'
