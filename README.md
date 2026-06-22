# Dotfiles

Portable shell and editor configuration **plus a vendoring system that pushes
static binaries and configs to remote servers over plain SSH** — no root, no
package manager, nothing pre-installed on the remote required.

## Features

- **Portable toolchain**: `make vendor` downloads static (musl) builds of
  modern CLI tools into `vendor/linux-<arch>/`; `make tool <name> HOST=…` ships
  them to any Linux box over SSH/SCP.
- **Bash**: fast git-aware prompt (single `git status` call), WSL-aware
  clipboard/`open`, fzf helpers, SSH/tmux/bookmark utilities.
- **Terminal theme**: gruvbox-dark palette applied via portable OSC escape
  sequences at shell startup — works in any xterm-compatible terminal and over
  SSH, no emulator config. Disable with `export DOTFILES_TERM_THEME=0`; restore
  the terminal's own colors with `term-reset`.
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

# Link all dotfile configs locally (uses stow if present, else ln)
make dot

# Or selectively — names are positional
make dot bash vim tmux
```

The interface has **two verbs on one axis**:

- **`dot`** acts on **configs**, **`tool`** acts on **portable binaries**.
- Add **`HOST=user@host`** to do it on a remote box over SSH; omit it for local.
- No name means **everything**.

| Command | What it does |
|---------|--------------|
| `make dot [name…]` | Link dotfile **configs** locally (no name = all) |
| `make dot [name…] HOST=u@h` | Push those configs to a server over SSH |
| `make tool [name…]` | Install vendor **binaries** to `~/.local/bin` locally |
| `make tool [name…] HOST=u@h` | Push those binaries to a server over SSH |
| `make vendor` | Download static binaries to `vendor/linux-<arch>/` |
| `make clean` | Remove the downloaded binaries (the `vendor/` cache) |
| `make remove dot [name…] [HOST=u@h]` | Remove **configs** (no name = all) |
| `make remove tool [name…] [HOST=u@h]` | Remove **binaries** (no name = all) |
| `make status [HOST=u@h]` | Show what's installed, locally or on a server |

## Vendoring & remote deploy

This is the part most dotfiles repos don't have.

```bash
# 1. Download portable static binaries into vendor/linux-<arch>/
make vendor

# 2. Push a tool to a remote server — binary and config are two steps
make tool nvim HOST=user@server        # the nvim binary  → ~/.local/bin
make dot  nvim HOST=user@server        # the nvim config  → ~/.config/nvim
# (or in one line)
make tool nvim HOST=u@s && make dot nvim HOST=u@s

# 3. Several at once
make tool fzf bat rg HOST=user@server

# 4. Everything — all binaries, or all configs
make tool HOST=user@server             # every vendored binary
make dot  HOST=user@server             # every config the deployer knows

# 5. Check what's installed, locally or remotely
make status
make status HOST=user@server

# 6. Remove — same dot/tool split, add HOST for remote
make remove tool nvim                        # binary, locally
make remove dot  nvim HOST=user@server       # config, remotely
make remove tool HOST=user@server            # every binary on the server
```

### `dot` vs `tool`, local vs remote

The two verbs are deliberately separate so each does exactly one thing:

- **`make tool …`** moves **binaries** (`~/.local/bin`). With no name it means
  every binary present in `vendor/linux-<arch>/`.
- **`make dot …`** moves **configs**. Locally that's all dotfile components
  (`bash`, `git`, `nvim`, `vim`, `tmux`, `joshuto`, `yazi`, `utils`, `fonts`, `inputrc`);
  remotely it's the ones the deployer knows how to wire up over SSH (`bash`,
  `git`, `inputrc`, `nvim`, `vim`, `tmux`, `joshuto`, `yazi`).

So a fully-equipped remote `nvim` is binary **and** config:

```bash
make tool nvim HOST=user@server && make dot nvim HOST=user@server
```

### Vendored tools

`fzf`, `fd`, `bat`, `rg` (ripgrep), `grex`, `eza`, `zoxide`, `delta`, `lazygit`,
`btop`, `yazi` (+ `ya`), `joshuto`, `7z`, `nvim`, `vim`, `tmux`.

`zoxide` is a frecency-based `cd` (`z`/`zi`); it needs the shell-init line in
`bash/dot-bashrc_ext` and is fed by joshuto navigation (`zoxide_update = true`).

`nvim` needs glibc 2.32+; the deployer detects old glibc and tells you to deploy
the static `vim` build instead.

`lazygit` and `grex` are **local-only**: vendored and installed locally, but
excluded from the bulk remote deploy (`make tool HOST=…`) — `lazygit` to keep
your raw git skills sharp on bare servers, `grex` because regex authoring is a
local task. You can still push either explicitly, e.g. `make tool grex HOST=…`.

## What's Included

| Component   | Contents |
|-------------|----------|
| **bash/**   | `dot-bashrc_ext`, `dot-dir_colors` |
| **nvim/**   | standalone `init.lua` + plugin-based `init_plugins.lua` |
| **vim/**    | `dot-vimrc`, `dot-vim/` |
| **tmux/**   | `dot-tmux.conf` (incl. session save/restore) |
| **git/**    | `dot-gitconfig` (delta-aware), `dot-gitignore_global` |
| **joshuto/**| `dot-config/joshuto` (preview script + `$EDITOR` mimetypes) |
| **yazi/**   | `dot-config/yazi` (icons disabled for non-Nerd-Font terminals) |
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
