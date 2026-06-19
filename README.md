# Dotfiles

Portable shell and editor configuration **plus a vendoring system that pushes
static binaries and configs to remote servers over plain SSH** — no root, no
package manager, nothing pre-installed on the remote required.

## Features

- **Portable toolchain**: `make vendor` downloads static (musl) builds of
  modern CLI tools into `vendor/linux-<arch>/`; `make install HOST=…` ships them
  to any Linux box over SSH/SCP.
- **Bash**: fast git-aware prompt (single `git status` call), WSL-aware
  clipboard/`open`, fzf helpers, SSH/tmux/bookmark utilities.
- **Neovim**: two-tier config — a standalone plugin-free `init.lua` (great for
  remote servers) and a full `init_plugins.lua` with LSP via lazy.nvim.
- **Graceful degradation**: configs detect available tools (delta, eza, bat,
  fzf…) and fall back cleanly when they're absent.
- **Stow-compatible**: `dot-` naming convention works with GNU Stow
  (`--dotfiles`) or the provided Makefile fallback (plain `ln`).

## Quick Start

```bash
git clone https://github.com/username/dotfiles ~/dotfiles
cd ~/dotfiles

# Install all dotfile components locally (uses stow if present, else ln)
make install

# Or install selectively
make bash vim tmux
```

## Vendoring & remote deploy

This is the part most dotfiles repos don't have.

```bash
# 1. Download portable static binaries into vendor/linux-<arch>/
make vendor

# 2. Push a single tool (binary + its config) to a remote server
make install HOST=user@server TOOL=nvim

# 3. Push every vendored binary (and the configs of vendor tools)
make install HOST=user@server TOOL=all

# 4. Check what's installed, locally or remotely
make status
make status HOST=user@server

# 5. Remove a tool (or everything) locally or remotely
make clean TOOL=nvim
make clean HOST=user@server TOOL=all
```

### What `TOOL=all` deploys (and what it doesn't)

`TOOL=all` deploys **only the vendored binaries and the configs that belong to
those binaries** (e.g. `nvim` → `~/.config/nvim`, `tmux` → `~/.tmux.conf`).

Config-only components that don't correspond to a vendor binary — **`bash`,
`git`, `inputrc`** — are **never** included in `all`. Deploy them explicitly:

```bash
make install HOST=user@server TOOL=bash      # ships ~/.bashrc_ext + wires ~/.bashrc
make install HOST=user@server TOOL=git       # ships ~/.gitignore_global
```

### Vendored tools

`fzf`, `fd`, `bat`, `rg` (ripgrep), `eza`, `delta`, `btop`, `yazi` (+ `ya`),
`joshuto`, `nvim`, `vim`, `tmux`.

`nvim` needs glibc 2.32+; the deployer detects old glibc and tells you to deploy
the static `vim` build instead.

## What's Included

| Component   | Contents |
|-------------|----------|
| **bash/**   | `dot-bashrc_ext`, `dot-dir_colors` |
| **nvim/**   | standalone `init.lua` + plugin-based `init_plugins.lua` |
| **vim/**    | `dot-vimrc`, `dot-vim/` |
| **tmux/**   | `dot-tmux.conf` (incl. session save/restore) |
| **git/**    | `dot-gitconfig` (delta-aware), `dot-gitignore_global` |
| **joshuto/**| `dot-config/joshuto` |
| **utils/**  | helper scripts in `dot-bin/` |
| **fonts/**  | bundled monospace fonts |
| **inputrc/**| readline settings |

## Compatibility

- **Bash 3.2+** (minimal), **4.0+** recommended
- **Vim 7.x+** (core), **8.0+** (persistent undo)
- **Neovim 0.10+** (plugin config uses `vim.uv`)
- Works on any system with `make` or `stow`

## Git + delta

`dot-gitconfig` uses [delta](https://github.com/dandavison/delta) as the diff
pager **only when it's on `PATH`**, falling back to `less` otherwise — so the
same config works whether or not delta is installed. `delta` is one of the
vendored tools, so `make vendor` provides it.

## LSP Setup (Neovim, plugin config)

Auto-detects installed servers. To enable:

```bash
pip install pyright                      # Python
npm install -g bash-language-server      # Bash
rustup component add rust-analyzer       # Rust
sudo apt install clangd                  # C/C++
```

## Customization

- **Bash**: edit `bash/dot-bashrc_ext`; machine-local overrides go in `~/.bashrc.local`.
- **Vim**: edit `vim/dot-vimrc`.
- **Neovim**: edit `nvim/dot-config/nvim/init.lua`.
