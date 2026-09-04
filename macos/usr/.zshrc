if (( $+commands[dotnet] )); then
  eval "$(dotnet completions script zsh)"
fi

if (( $+commands[bat] )); then
  eval "$(bat completion zsh)"
fi

if (( $+commands[gh] )); then
  eval "$(gh completion --shell zsh)"
fi
