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
| `--skip-tmux` | Do not download gpakosz `~/.tmux.conf` |
| `--skip-omz` | Skip Oh My Zsh install |
| `--chsh` | Set login shell to `zsh` |
| `--repo-dir PATH` | Repo root (default: directory containing this script) |

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

## Dependencies

Install before or after `install.sh` (soft requirements):

- **Required:** `git`, `zsh`, `curl`
- **Recommended:** `tmux`, `neovim` (0.9+), `ripgrep` (Telescope)

macOS (Homebrew): `brew install zsh tmux neovim ripgrep`

Debian/Ubuntu: `sudo apt install zsh tmux neovim ripgrep git curl`

## Git aliases

Common shortcuts (`p`, `pf`, `st`, `ll`, `rbi`, `rbc`, …). Interactive rebase:

```bash
git rbi origin/main
git rbi HEAD~3
```

## Neovim

First run installs plugins via lazy.nvim. `install.sh` runs headless sync unless `--no-nvim`.

Sidekick agent defaults to `fcc-pi` — override on servers without it or add the binary to `PATH`.

## tmux

Upstream config: [gpakosz/.tmux](https://github.com/gpakosz/.tmux). Custom keys/theme in `tmux/tmux.conf.local`.

Reload: `tmux source ~/.tmux.conf` or prefix `r` (per local bindings).