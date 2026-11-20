# user@host in prompt (color by hostname) + terminal title

autoload -Uz add-zsh-hook

# Стабильный цвет по короткому имени хоста (hermes, atlas, …).
_shell_config_host_color() {
  local h="${1:-${HOST:-$(hostname -s 2>/dev/null)}}"
  h="${h%%.*}"
  local -a palette=(red green yellow blue magenta cyan)
  integer sum=0 i ord=0
  for (( i = 1; i <= ${#h}; i++ )); do
    ord=$(printf '%d' "'${h[i]}")
    (( sum += ord ))
  done
  echo "${palette[$(( sum % ${#palette} + 1 ))]}"
}

_shell_config_set_prompt() {
  local c
  c="$(_shell_config_host_color)"
  # %c — хвост cwd (как robbyrussell)
  PROMPT="%F{${c}}%n@%m%f %F{blue}%B➜%b%f %c "
  RPROMPT=""
}

_shell_config_window_title() {
  print -Pn "\e]0;%n@%m: %~\a"
}

_shell_config_set_prompt
add-zsh-hook precmd _shell_config_window_title