# shell-config

Dotfiles: zsh + Oh My Zsh, git, tmux (gpakosz + local overrides), Neovim (lazy.nvim).

## Quick start (new machine)

```bash
git clone git@github.com:ant1quar/shell-config.git ~/.local/share/shell-config
~/.local/share/shell-config/install.sh
```

From an existing clone:

```bash
./install.sh
```

### Options

| Flag | Meaning |
|------|---------|
| `--dry-run` | Show what would happen |
| `--no-nvim` | Skip `nvim` Lazy plugin sync |
| `--skip-deps` | Skip auto-install of system packages, nvm, Node |
| `--skip-tmux` | Do not download gpakosz `~/.tmux.conf` |
| `--skip-omz` | Skip Oh My Zsh install |
| `--chsh` | Set login shell to `zsh` |
| `--repo-dir PATH` | Repo root (default: directory containing this script) |

### What `install.sh` installs (by default)

Only **missing** tools are installed:

| Layer | Tools |
|-------|--------|
| **macOS** | Homebrew (if absent), then `git`, `curl`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fzf` |
| **Linux** | via `apt` / `dnf` / `pacman` / … — same set + `xclip` (or `wl-clipboard` on Arch) |
| **User** | [nvm](https://github.com/nvm-sh/nvm) + Node.js LTS, Oh My Zsh, gpakosz tmux, dotfile symlinks, Lazy.nvim sync |

Linux installs use `sudo` when available. Use `--skip-deps` if the host is locked down (only symlinks + OMZ).

On first run (or when `~/.gitconfig.local` still has placeholders), the script **asks** for `user.name` and `user.email`.  
Non-interactive: `SHELL_CONFIG_GIT_NAME=... SHELL_CONFIG_GIT_EMAIL=... ./install.sh`

It also asks for the **real CLI agent command** (e.g. `fcc-pi`), writes it to `~/.config/shell-config/agent-target`, and installs `~/.local/bin/nvim-agent` (used by sidekick in `ai.lua`).  
Non-interactive: `SHELL_CONFIG_AGENT_CMD=fcc-pi ./install.sh`

## Layout

```
git/           → ~/.gitconfig, ~/.gitignore_global
gitconfig.local.example → copy to ~/.gitconfig.local (user + project includes)
tmux/          → ~/.tmux.conf.local (base ~/.tmux.conf from gpakosz on install)
nvim/          → ~/.config/nvim
zsh/           → ~/.zshrc (symlink) + sourced fragments
local/         → examples for ~/.zshrc.local
```

Machine-specific settings stay in **gitignored** files:

- `~/.gitconfig.local` — `[user]`, `includeIf` for work repos
- `~/.zshrc.local` — PATH, app aliases (see `local/zshrc.local.example`)

Repo path is stored in `~/.config/shell-config/path` for zsh bootstrap.

## Git aliases

Common shortcuts (`p`, `pf`, `st`, `ll`, `rbi`, `rbc`, …). Interactive rebase:

```bash
git rbi origin/main
git rbi HEAD~3
```

## Neovim

First run installs plugins via lazy.nvim. `install.sh` runs headless sync unless `--no-nvim`.

Sidekick calls `~/.local/bin/nvim-agent`; target command is configured at install (see `agent-target`).

## tmux

Upstream config: [gpakosz/.tmux](https://github.com/gpakosz/.tmux). Custom keys/theme in `tmux/tmux.conf.local`.

Reload: `tmux source ~/.tmux.conf` or prefix `r` (per local bindings).