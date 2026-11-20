#!/usr/bin/env bash
# shell-config installer — macOS and Linux
set -euo pipefail

REPO_DIR_DEFAULT="${HOME}/.local/share/shell-config"
CONFIG_MARKER_DIR="${HOME}/.config/shell-config"
GPAKOSZ_URL="https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf"
OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"

DRY_RUN=0
NO_NVIM=0
SKIP_TMUX=0
SKIP_OMZ=0
SKIP_DEPS=0
DO_CHSH=0
REPO_DIR=""

OS=""
PKG_MGR=""

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --dry-run       Print actions, do not change anything
  --no-nvim       Skip nvim headless Lazy sync
  --skip-deps     Do not install system packages / nvm / node
  --skip-tmux     Do not fetch gpakosz .tmux.conf
  --skip-omz      Skip Oh My Zsh install
  --chsh          Run chsh -s $(command -v zsh) when possible
  --repo-dir DIR  Dotfiles repo root (default: script directory or ~/.local/share/shell-config)
  -h, --help      This help

By default installs missing: git, curl, zsh, tmux, neovim, ripgrep, fzf, clipboard
helpers (Linux), Homebrew (macOS if missing), nvm, Node.js LTS.
EOF
}

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

run() {
  if (( DRY_RUN )); then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

run_root() {
  if (( DRY_RUN )); then
    printf '[dry-run] (root) %s\n' "$*"
    return 0
  fi
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  else
    warn "need root for: $* — install manually or re-run with sudo"
    return 1
  fi
}

detect_platform() {
  case "$(uname -s)" in
    Darwin) OS=darwin ;;
    Linux) OS=linux ;;
    *) OS=other ;;
  esac

  if [[ "$OS" == darwin ]]; then
    if has_cmd brew; then
      PKG_MGR=brew
    else
      PKG_MGR=brew-install
    fi
    return 0
  fi

  if [[ "$OS" != linux ]]; then
    PKG_MGR=none
    return 0
  fi

  if has_cmd apt-get; then
    PKG_MGR=apt
  elif has_cmd dnf; then
    PKG_MGR=dnf
  elif has_cmd yum; then
    PKG_MGR=yum
  elif has_cmd pacman; then
    PKG_MGR=pacman
  elif has_cmd zypper; then
    PKG_MGR=zypper
  elif has_cmd apk; then
    PKG_MGR=apk
  else
    PKG_MGR=none
  fi
}

ensure_homebrew() {
  [[ "$PKG_MGR" == brew || "$PKG_MGR" == brew-install ]] || return 0
  if has_cmd brew; then
    PKG_MGR=brew
    return 0
  fi
  log "Installing Homebrew (non-interactive)"
  if (( DRY_RUN )); then
    printf '[dry-run] install Homebrew\n'
    PKG_MGR=brew
    return 0
  fi
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellcheck disable=SC1091
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  PKG_MGR=brew
}

brew_install() {
  local pkg
  for pkg in "$@"; do
    if brew list "$pkg" &>/dev/null; then
      continue
    fi
    log "brew install $pkg"
    if (( DRY_RUN )); then
      printf '[dry-run] brew install %s\n' "$pkg"
    else
      brew install "$pkg"
    fi
  done
}

apt_install() {
  log "apt: update & install $*"
  if (( DRY_RUN )); then
    printf '[dry-run] apt-get install -y %s\n' "$*"
    return 0
  fi
  run_root apt-get update -qq || true
  run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

dnf_install() {
  log "dnf install $*"
  if (( DRY_RUN )); then
    printf '[dry-run] dnf install -y %s\n' "$*"
    return 0
  fi
  run_root dnf install -y "$@"
}

yum_install() {
  log "yum install $*"
  if (( DRY_RUN )); then
    printf '[dry-run] yum install -y %s\n' "$*"
    return 0
  fi
  run_root yum install -y "$@"
}

pacman_install() {
  log "pacman -S $*"
  if (( DRY_RUN )); then
    printf '[dry-run] pacman -S --noconfirm %s\n' "$*"
    return 0
  fi
  run_root pacman -S --noconfirm --needed "$@"
}

zypper_install() {
  log "zypper install $*"
  if (( DRY_RUN )); then
    printf '[dry-run] zypper install -y %s\n' "$*"
    return 0
  fi
  run_root zypper install -y "$@"
}

apk_install() {
  log "apk add $*"
  if (( DRY_RUN )); then
    printf '[dry-run] apk add %s\n' "$*"
    return 0
  fi
  run_root apk add "$@"
}

pkg_install_many() {
  [[ $# -gt 0 ]] || return 0
  case "$PKG_MGR" in
    brew) brew_install "$@" ;;
    apt) apt_install "$@" ;;
    dnf) dnf_install "$@" ;;
    yum) yum_install "$@" ;;
    pacman) pacman_install "$@" ;;
    zypper) zypper_install "$@" ;;
    apk) apk_install "$@" ;;
    brew-install)
      ensure_homebrew
      brew_install "$@"
      ;;
    none)
      warn "no supported package manager — install manually: $*"
      ;;
  esac
}

# Install only packages needed for missing commands (map: cmd -> pkg name per mgr)
install_missing_tools() {
  detect_platform
  [[ "$PKG_MGR" == brew-install ]] && ensure_homebrew

  local -a to_install=()

  if [[ "$OS" == darwin ]]; then
    has_cmd git || to_install+=(git)
    has_cmd curl || to_install+=(curl)
    has_cmd zsh || to_install+=(zsh)
    has_cmd tmux || to_install+=(tmux)
    has_cmd nvim || to_install+=(neovim)
    has_cmd rg || to_install+=(ripgrep)
    has_cmd fzf || to_install+=(fzf)
    pkg_install_many "${to_install[@]}"
    return 0
  fi

  if [[ "$OS" != linux ]]; then
    warn "unsupported OS for auto deps: $(uname -s)"
    return 0
  fi

  case "$PKG_MGR" in
    apt)
      has_cmd git || to_install+=(git)
      has_cmd curl || to_install+=(curl)
      has_cmd zsh || to_install+=(zsh)
      has_cmd tmux || to_install+=(tmux)
      has_cmd nvim || to_install+=(neovim)
      has_cmd rg || to_install+=(ripgrep)
      has_cmd fzf || to_install+=(fzf)
      has_cmd xclip || to_install+=(xclip)
      has_cmd xsel || [[ " ${to_install[*]} " == *" xclip "* ]] || to_install+=(xsel)
      pkg_install_many "${to_install[@]}"
      ;;
    dnf|yum)
      has_cmd git || to_install+=(git)
      has_cmd curl || to_install+=(curl)
      has_cmd zsh || to_install+=(zsh)
      has_cmd tmux || to_install+=(tmux)
      has_cmd nvim || to_install+=(neovim)
      has_cmd rg || to_install+=(ripgrep)
      has_cmd fzf || to_install+=(fzf)
      has_cmd xclip || to_install+=(xclip)
      pkg_install_many "${to_install[@]}"
      ;;
    pacman)
      has_cmd git || to_install+=(git)
      has_cmd curl || to_install+=(curl)
      has_cmd zsh || to_install+=(zsh)
      has_cmd tmux || to_install+=(tmux)
      has_cmd nvim || to_install+=(neovim)
      has_cmd rg || to_install+=(ripgrep)
      has_cmd fzf || to_install+=(fzf)
      has_cmd wl-copy || to_install+=(wl-clipboard)
      has_cmd xclip || to_install+=(xclip)
      pkg_install_many "${to_install[@]}"
      ;;
    zypper)
      has_cmd git || to_install+=(git)
      has_cmd curl || to_install+=(curl)
      has_cmd zsh || to_install+=(zsh)
      has_cmd tmux || to_install+=(tmux)
      has_cmd nvim || to_install+=(neovim)
      has_cmd rg || to_install+=(ripgrep)
      has_cmd fzf || to_install+=(fzf)
      has_cmd xclip || to_install+=(xclip)
      pkg_install_many "${to_install[@]}"
      ;;
    apk)
      has_cmd git || to_install+=(git)
      has_cmd curl || to_install+=(curl)
      has_cmd zsh || to_install+=(zsh)
      has_cmd tmux || to_install+=(tmux)
      has_cmd nvim || to_install+=(neovim)
      has_cmd rg || to_install+=(ripgrep)
      has_cmd fzf || to_install+=(fzf)
      has_cmd xclip || to_install+=(xclip)
      pkg_install_many "${to_install[@]}"
      ;;
    none)
      warn "install git curl zsh tmux neovim ripgrep yourself"
      ;;
  esac
}

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
}

install_nvm_and_node() {
  load_nvm
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    need_cmd curl
    log "Installing nvm"
    if (( DRY_RUN )); then
      printf '[dry-run] curl %s | bash\n' "$NVM_INSTALL_URL"
    else
      curl -fsSL "$NVM_INSTALL_URL" | bash
      load_nvm
    fi
  else
    log "nvm already installed at $NVM_DIR"
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] nvm install --lts\n'
    return 0
  fi

  load_nvm
  if ! has_cmd nvm; then
    warn "nvm not loaded — open a new shell after install"
    return 0
  fi

  if ! has_cmd node; then
    log "nvm: install Node.js LTS"
    nvm install --lts
    nvm alias default 'lts/*'
  else
    log "node already present: $(node -v 2>/dev/null || true)"
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

gitconfig_local_needs_identity() {
  local dst="$1"
  [[ -f "$dst" ]] || return 0
  local name email
  name="$(git config --file "$dst" user.name 2>/dev/null || true)"
  email="$(git config --file "$dst" user.email 2>/dev/null || true)"
  [[ -z "$name" || -z "$email" || "$name" == "Your Name" || "$email" == "you@example.com" ]]
}

prompt_git_identity() {
  local dst="$1"
  local default_name default_email name email

  default_name="${SHELL_CONFIG_GIT_NAME:-}"
  default_email="${SHELL_CONFIG_GIT_EMAIL:-}"
  if [[ -z "$default_name" ]]; then
    default_name="$(git config --file "$dst" user.name 2>/dev/null || true)"
  fi
  if [[ -z "$default_email" ]]; then
    default_email="$(git config --file "$dst" user.email 2>/dev/null || true)"
  fi
  if [[ -z "$default_name" || "$default_name" == "Your Name" ]]; then
    default_name="$(git config --global user.name 2>/dev/null || true)"
  fi
  if [[ -z "$default_email" || "$default_email" == "you@example.com" ]]; then
    default_email="$(git config --global user.email 2>/dev/null || true)"
  fi

  if [[ -t 0 ]]; then
    printf '\n'
    log "Git identity for ~/.gitconfig.local"
    read -r -p "  user.name [${default_name:-none}]: " name
    name="${name:-$default_name}"
    read -r -p "  user.email [${default_email:-none}]: " email
    email="${email:-$default_email}"
  else
    name="$default_name"
    email="$default_email"
    if [[ -z "$name" || -z "$email" ]]; then
      warn "non-interactive shell: set SHELL_CONFIG_GIT_NAME and SHELL_CONFIG_GIT_EMAIL"
      return 1
    fi
    log "Using git identity from environment (non-interactive)"
  fi

  if [[ -z "$name" || -z "$email" ]]; then
    warn "git user.name and user.email are required"
    return 1
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] git config --file %s user.name %q\n' "$dst" "$name"
    printf '[dry-run] git config --file %s user.email %q\n' "$dst" "$email"
    return 0
  fi

  git config --file "$dst" user.name "$name"
  git config --file "$dst" user.email "$email"
  log "Wrote git user.name / user.email to $dst"
}

agent_target_file() {
  printf '%s/agent-target' "$CONFIG_MARKER_DIR"
}

agent_target_needs_setup() {
  local f
  f="$(agent_target_file)"
  [[ ! -f "$f" ]] && return 0
  local line
  line="$(head -n1 "$f" 2>/dev/null | tr -d '\r' || true)"
  [[ -z "$line" || "$line" == "CHANGE_ME" ]]
}

prompt_nvim_agent() {
  local dst target default line wrapper_src wrapper_dst

  dst="$(agent_target_file)"
  default="${SHELL_CONFIG_AGENT_CMD:-}"
  if [[ -z "$default" && -f "$dst" ]]; then
    default="$(head -n1 "$dst" | tr -d '\r' || true)"
    [[ "$default" == "CHANGE_ME" ]] && default=""
  fi
  if [[ -z "$default" ]] && has_cmd fcc-pi; then
    default="fcc-pi"
  fi

  if [[ -t 0 ]]; then
    printf '\n'
    log "Neovim sidekick agent (wrapper: nvim-agent)"
    printf '  One line: shell command to run (e.g. fcc-pi, "cursor agent").\n'
    read -r -p "  agent command [${default:-none}]: " line
    target="${line:-$default}"
  else
    target="$default"
    if [[ -z "$target" ]]; then
      warn "non-interactive: set SHELL_CONFIG_AGENT_CMD"
      return 1
    fi
    log "Using agent command from environment (non-interactive)"
  fi

  if [[ -z "$target" ]]; then
    warn "agent command is required for ~/.local/bin/nvim-agent"
    return 1
  fi

  wrapper_src="$REPO_DIR/scripts/nvim-agent"
  wrapper_dst="$HOME/.local/bin/nvim-agent"
  if [[ ! -f "$wrapper_src" ]]; then
    warn "missing $wrapper_src"
    return 1
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] write %s: %q\n' "$dst" "$target"
    printf '[dry-run] install %s -> %s\n' "$wrapper_src" "$wrapper_dst"
    return 0
  fi

  run mkdir -p "$CONFIG_MARKER_DIR" "$HOME/.local/bin"
  printf '%s\n' "$target" >"$dst"
  cp "$wrapper_src" "$wrapper_dst"
  chmod +x "$wrapper_dst"
  log "nvim-agent -> ($target) via $wrapper_dst"
}

setup_nvim_agent() {
  if agent_target_needs_setup; then
    prompt_nvim_agent || warn "nvim-agent not configured — re-run install or edit $(agent_target_file)"
  else
    local wrapper_dst="$HOME/.local/bin/nvim-agent"
    if [[ ! -x "$wrapper_dst" ]] && [[ -f "$REPO_DIR/scripts/nvim-agent" ]]; then
      log "Installing nvim-agent wrapper (keeping existing agent-target)"
      run mkdir -p "$HOME/.local/bin"
      cp "$REPO_DIR/scripts/nvim-agent" "$wrapper_dst"
      chmod +x "$wrapper_dst"
    else
      log "Keep existing nvim-agent ($wrapper_dst)"
    fi
  fi
}

seed_gitconfig_local() {
  local dst="$HOME/.gitconfig.local"
  local example="$REPO_DIR/git/gitconfig.local.example"

  if [[ ! -f "$example" ]]; then
    warn "missing $example"
    return 0
  fi

  if [[ -f "$dst" ]]; then
    if gitconfig_local_needs_identity "$dst"; then
      log "Completing git identity in existing $dst"
      prompt_git_identity "$dst" || return 0
    else
      log "Keep existing $dst (git identity already set)"
    fi
    return 0
  fi

  log "Create $dst from example"
  if (( DRY_RUN )); then
    printf '[dry-run] cp %s %s\n' "$example" "$dst"
    printf '[dry-run] prompt for git user.name / user.email\n'
    return 0
  fi

  cp "$example" "$dst"
  prompt_git_identity "$dst" || true
}

sync_nvim() {
  if (( NO_NVIM )); then
    log "Skipping nvim Lazy sync (--no-nvim)"
    return 0
  fi
  if ! has_cmd nvim; then
    warn "nvim not found, skip plugin sync"
    return 0
  fi
  load_nvm
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
      --skip-deps) SKIP_DEPS=1 ;;
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

  if (( ! SKIP_DEPS )); then
    install_missing_tools
    install_nvm_and_node
  fi

  (( SKIP_OMZ )) || install_omz

  link_path "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_path "$REPO_DIR/git/gitconfig" "$HOME/.gitconfig"
  link_path "$REPO_DIR/git/gitignore_global" "$HOME/.gitignore_global"
  link_path "$REPO_DIR/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
  link_path "$REPO_DIR/nvim" "$HOME/.config/nvim"

  write_marker
  seed_gitconfig_local
  setup_nvim_agent
  (( SKIP_TMUX )) || fetch_tmux_conf
  sync_nvim
  maybe_chsh

  log "Done. Open a new zsh session or: exec zsh"
  log "Edit ~/.gitconfig.local and ~/.zshrc.local for machine-specific settings"
}

main "$@"