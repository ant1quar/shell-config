#!/usr/bin/env bash
# shell-config installer — macOS and Linux
set -euo pipefail

REPO_DIR_DEFAULT="${HOME}/.local/share/shell-config"
CONFIG_MARKER_DIR="${HOME}/.config/shell-config"
GPAKOSZ_URL="https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf"
OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"

DRY_RUN=0
NO_NVIM=0
SKIP_TMUX=0
SKIP_OMZ=0
DO_CHSH=0
REPO_DIR=""

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --dry-run       Print actions, do not change anything
  --no-nvim       Skip nvim headless Lazy sync
  --skip-tmux     Do not fetch gpakosz .tmux.conf
  --skip-omz      Skip Oh My Zsh install
  --chsh          Run chsh -s $(command -v zsh) when possible
  --repo-dir DIR  Dotfiles repo root (default: script directory or ~/.local/share/shell-config)
  -h, --help      This help
EOF
}

log() { printf '==> %s\n' "$*"; }
run() {
  if (( DRY_RUN )); then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

resolve_repo_dir() {
  if [[ -n "$REPO_DIR" ]]; then
  :
  elif [[ -n "${SHELL_CONFIG_DIR:-}" ]]; then
    REPO_DIR="$SHELL_CONFIG_DIR"
  else
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$script_dir/install.sh" && -d "$script_dir/git" ]]; then
      REPO_DIR="$script_dir"
    else
      REPO_DIR="$REPO_DIR_DEFAULT"
    fi
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

backup_target() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  local ts dest
  ts="$(date +%Y%m%d%H%M%S)"
  dest="${target}.pre-shell-config-${ts}"
  log "Backup $target -> $dest"
  run mv "$target" "$dest"
}

link_path() {
  local src="$1" dst="$2"
  local dst_parent
  dst_parent="$(dirname "$dst")"
  run mkdir -p "$dst_parent"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    log "Already linked: $dst"
    return 0
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup_target "$dst"
  fi
  log "Link $dst -> $src"
  run ln -sfn "$src" "$dst"
}

install_omz() {
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  if [[ -d "$zsh_dir" ]]; then
    log "Oh My Zsh already present at $zsh_dir"
    return 0
  fi
  need_cmd git
  log "Installing Oh My Zsh (non-interactive)"
  if (( DRY_RUN )); then
    printf '[dry-run] RUNZSH=no CHSH=no git clone --depth=1 %s %s\n' "$OMZ_REPO" "$zsh_dir"
    return 0
  fi
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    git clone --depth=1 "$OMZ_REPO" "$zsh_dir"
}

fetch_tmux_conf() {
  need_cmd curl
  log "Fetching gpakosz .tmux.conf"
  if [[ -f "$HOME/.tmux.conf" ]]; then
    backup_target "$HOME/.tmux.conf"
  fi
  if (( DRY_RUN )); then
    printf '[dry-run] curl -fsSL %s -o %s/.tmux.conf\n' "$GPAKOSZ_URL" "$HOME"
    return 0
  fi
  curl -fsSL "$GPAKOSZ_URL" -o "$HOME/.tmux.conf"
}

seed_gitconfig_local() {
  local dst="$HOME/.gitconfig.local"
  local example="$REPO_DIR/git/gitconfig.local.example"
  if [[ -f "$dst" ]]; then
    log "Keep existing $dst"
    return 0
  fi
  if [[ ! -f "$example" ]]; then
    echo "warning: missing $example" >&2
    return 0
  fi
  log "Create $dst from example"
  if (( DRY_RUN )); then
    printf '[dry-run] cp %s %s\n' "$example" "$dst"
    return 0
  fi
  cp "$example" "$dst"
  if command -v git >/dev/null 2>&1; then
    local name email
    name="$(git config --global user.name 2>/dev/null || true)"
    email="$(git config --global user.email 2>/dev/null || true)"
    if [[ -n "$name" && -n "$email" && "$name" != "Your Name" ]]; then
      # portable in-place replace (macOS + GNU sed)
      if sed --version >/dev/null 2>&1; then
        sed -i "s/^	name = .*/	name = $name/" "$dst"
        sed -i "s/^	email = .*/	email = $email/" "$dst"
      else
        sed -i '' "s/^	name = .*/	name = $name/" "$dst"
        sed -i '' "s/^	email = .*/	email = $email/" "$dst"
      fi
      log "Prefilled user.name / user.email from existing global git config"
    fi
  fi
}

sync_nvim() {
  if (( NO_NVIM )); then
    log "Skipping nvim Lazy sync (--no-nvim)"
    return 0
  fi
  if ! command -v nvim >/dev/null 2>&1; then
    log "nvim not found, skip plugin sync"
    return 0
  fi
  log "nvim: Lazy.nvim sync (may take a few minutes)"
  if (( DRY_RUN )); then
    printf '[dry-run] nvim --headless "+Lazy! sync" +qa\n'
    return 0
  fi
  nvim --headless "+Lazy! sync" +qa
}

maybe_chsh() {
  (( DO_CHSH )) || return 0
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"
  [[ -n "$zsh_bin" ]] || { echo "error: zsh not in PATH" >&2; exit 1; }
  if [[ "${SHELL:-}" == "$zsh_bin" ]]; then
    log "Login shell already zsh"
    return 0
  fi
  log "chsh -s $zsh_bin (may prompt for password)"
  run chsh -s "$zsh_bin"
}

write_marker() {
  run mkdir -p "$CONFIG_MARKER_DIR"
  if (( DRY_RUN )); then
    printf '[dry-run] write %s/path = %s\n' "$CONFIG_MARKER_DIR" "$REPO_DIR"
    return 0
  fi
  printf '%s\n' "$REPO_DIR" >"$CONFIG_MARKER_DIR/path"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --no-nvim) NO_NVIM=1 ;;
      --skip-tmux) SKIP_TMUX=1 ;;
      --skip-omz) SKIP_OMZ=1 ;;
      --chsh) DO_CHSH=1 ;;
      --repo-dir)
        shift
        REPO_DIR="${1:?--repo-dir needs a path}"
        ;;
      -h|--help) usage; exit 0 ;;
      *) echo "unknown option: $1" >&2; usage; exit 2 ;;
    esac
    shift
  done

  resolve_repo_dir
  [[ -d "$REPO_DIR/git" ]] || {
    echo "error: repo not found or invalid: $REPO_DIR" >&2
    exit 1
  }

  need_cmd ln
  need_cmd mkdir

  log "Repo: $REPO_DIR"

  (( SKIP_OMZ )) || install_omz

  link_path "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_path "$REPO_DIR/git/gitconfig" "$HOME/.gitconfig"
  link_path "$REPO_DIR/git/gitignore_global" "$HOME/.gitignore_global"
  link_path "$REPO_DIR/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
  link_path "$REPO_DIR/nvim" "$HOME/.config/nvim"

  write_marker
  seed_gitconfig_local
  (( SKIP_TMUX )) || fetch_tmux_conf
  sync_nvim
  maybe_chsh

  log "Done. Open a new zsh session or: exec zsh"
  log "Edit ~/.gitconfig.local and ~/.zshrc.local for machine-specific settings"
}

main "$@"