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
- **One table, no drift**: every component and tool is a row in
  `scripts/lib.sh`; install, remove, deploy and status are all derived from it.
  Files use the GNU Stow `--dotfiles` layout (`nvim/dot-config/nvim` →
  `~/.config/nvim`), linked with plain `ln` — nothing to install first.

## Quick Start

```bash
git clone https://github.com/username/dotfiles ~/dotfiles
cd ~/dotfiles

# Link the everyday set of configs locally (symlinks into this repo)
make dot core

# Or selectively — names are positional
make dot bash vim tmux
```

The interface has **two verbs on one axis**:

- **`dot`** acts on **configs**, **`tool`** acts on **portable binaries**.
- Add **`HOST=user@host`** to do it on a remote box over SSH; omit it for local.
- Give **names**, or one of three **group keywords**:
  - **`core`** — the everyday set (what a bare verb points you to)
  - **`extra`** — the opt-in-by-name items (configs `vim`/`hypr`/`aerc`/`lazyvim`, tools `cliamp`/`ffmpeg`)
  - **`all`** — `core` + `extra`
- A **bare verb does nothing** but print `core` and `extra`, so nothing bulk happens by accident.

| Command | What it does |
|---------|--------------|
| `make dot <names…\|core\|extra\|all>` | Link dotfile **configs** locally |
| `make dot … HOST=u@h` | Push those configs to a server over SSH |
| `make tool <names…\|core\|extra\|all>` | Install vendor **binaries** to `~/.local/bin` locally |
| `make tool … HOST=u@h` | Push those binaries to a server over SSH |
| `make vendor [names…\|core\|extra\|all]` | Download static binaries to `vendor/linux-<arch>/` (no arg = all; `FORCE=1` re-downloads) |
| `make clean` | Remove the downloaded binaries (the `vendor/` cache) |
| `make remove dot <names…\|core\|extra\|all> [HOST=u@h]` | Remove **configs** |
| `make remove tool <names…\|core\|extra\|all> [HOST=u@h]` | Remove **binaries** |
| `make status [HOST=u@h]` | Show what's installed, locally or on a server |

Group keywords and names can be combined (`make tool core cliamp`), and
duplicates collapse. On a remote, `core`/`all` drop the local-only items
(machine-specific configs, `grex`) — so `make tool all HOST=…` still means
"everything that belongs on a server". Unknown names are an error everywhere
(`make dot Hyperland` won't silently do nothing). Locally, `remove` only ever
deletes symlinks that point into this repo — a real file at the same path is
reported and left alone — and `status` only counts those as installed.

## Vendoring & remote deploy

This is the part most dotfiles repos don't have.

```bash
# 1. Download portable static binaries into vendor/linux-<arch>/
make vendor                            # all of them
make vendor nvim                       # just one;  FORCE=1 make vendor nvim  re-downloads

# 2. Push a tool to a remote server — binary and config are two steps
make tool nvim HOST=user@server        # the nvim binary  → ~/.local/bin
make dot  nvim HOST=user@server        # the nvim config  → ~/.config/nvim
# (or in one line)
make tool nvim HOST=u@s && make dot nvim HOST=u@s

# 3. Several at once
make tool fzf bat rg HOST=user@server

# 4. Everything — all binaries, or all configs
make tool all HOST=user@server         # every deployable binary (drops grex)
make dot  all HOST=user@server         # every deployable config

# 5. Check what's installed, locally or remotely
make status
make status HOST=user@server

# 6. Remove — same dot/tool split, add HOST for remote
make remove tool nvim                        # binary, locally
make remove dot  nvim HOST=user@server       # config, remotely
make remove tool all  HOST=user@server       # every deployable binary on the server
```

### `dot` vs `tool`, local vs remote

The two verbs are deliberately separate so each does exactly one thing:

- **`make tool …`** moves **binaries** (`~/.local/bin`). `core` is the everyday
  set; `extra` is `cliamp`/`ffmpeg`; `all` is both.
- **`make dot …`** moves **configs**. `core` locally is (`bash`, `git`, `nvim`,
  `tmux`, `inputrc`, `joshuto`, `yazi`, `lazygit`, `utils`, `fonts`); remotely
  it's what makes sense on a server (`bash`, `git`, `inputrc`, `nvim`, `tmux`,
  `joshuto`, `yazi`, `lazygit`). `extra` is `vim`, `hypr`, `aerc`, `lazyvim`
  (`make dot extra`, or by name). `hypr`
  is local-only — a Wayland compositor config has no reason to deploy to a
  headless server. `aerc` is local-only for the same kind of reason as `git`:
  its account credentials (`accounts.conf`) are deliberately excluded from
  this repo, so pushing just the styling/keybinds to a remote wouldn't give
  you a working mail client there anyway. `lazyvim` is local-only for a different reason: it's a
  live `git clone` that lazy.nvim then self-manages, so it needs network on
  whichever machine runs it — pushing it to an offline remote over SSH
  wouldn't leave a working install there anyway. It's also excluded from the
  no-name `make dot` (must be named explicitly: `make dot lazyvim`).

So a fully-equipped remote `nvim` is binary **and** config:

```bash
make tool nvim HOST=user@server && make dot nvim HOST=user@server
```

### Vendored tools

`fzf`, `fd`, `bat`, `rg` (ripgrep), `grex`, `eza`, `zoxide`, `delta`, `lazygit`,
`btop`, `yazi` (+ `ya`), `joshuto`, `7z`, `nvim`, `vim`, `tmux`, `cliamp`, `ffmpeg`.

`zoxide` is a frecency-based `cd` (`z`/`zi`); it needs the shell-init line in
`bash/dot-bashrc_ext` and is fed by joshuto navigation (`zoxide_update = true`).

`nvim` needs glibc 2.32+; the deployer detects old glibc and tells you to deploy
the static `vim` build instead. `nvim`'s runtime and treesitter parsers travel
with the binary (`make tool nvim` installs all three, `make remove tool nvim`
removes all three).

`cliamp` and `ffmpeg` are the **`extra`** tools: vendored by `make vendor`, but
not in `core`, so `make tool core` skips them — cliamp is a music player, and
`ffmpeg` is an 80 MB static build riding along only for cliamp's AAC/ALAC/Opus/
WMA playback. Install them with `make tool extra`, `make tool all`, or by name.

`grex` is in `core` locally but **local-only** for remote: `make tool all HOST=…`
skips it (regex authoring is a local task). It's still pushable by name:
`make tool grex HOST=…`.

`cliamp` (terminal music player) is the one non-static build: it needs
glibc 2.34+ and `libasound2` on the machine, plus an ALSA bridge to your sound
server (`pipewire-alsa` / `libasound2-plugins`). The deployer checks the glibc
floor per tool (`GLIBC_MIN` in `scripts/lib.sh`) before pushing.

`lazygit`'s config (`~/.config/lazygit/config.yml`) is portable and included
in both the bulk config deploy (`make dot HOST=…`) and, as of the delta-aware
config below, the bulk binary deploy too.

## What's Included

| Component   | Contents |
|-------------|----------|
| **bash/**   | `dot-bashrc_ext`, `dot-dir_colors` |
| **nvim/**   | standalone `init.lua` + plugin-based `init_plugins.lua` |
| **vim/**    | `dot-vimrc`, `dot-vim/` |
| **tmux/**   | `dot-tmux.conf` (incl. session save/restore) |
| **git/**    | `dot-gitconfig` (delta-aware), `dot-gitignore_global` |
| **hypr/**   | `dot-config/hypr` (Hyprland Lua config; `monitors.lua` is machine-local, gitignored) |
| **lazygit/**| `dot-config/lazygit/config.yml` (delta-aware pagers) |
| **aerc/**   | `dot-config/aerc/{aerc.conf,binds.conf,stylesets/}` (theme-aware styling; `accounts.conf` holds live credentials and is deliberately left out, same as `~/.gitconfig`) |
| **lazyvim** | Not linked — `make dot lazyvim` clones the LazyVim starter into `~/.config/lazyvim`, isolated via `NVIM_APPNAME`. Launch with `lvim`. Opt-in only (needs network + git; not part of the no-name `make dot`) |
| **joshuto/**| `dot-config/joshuto` (preview script + `$EDITOR` mimetypes) |
| **yazi/**   | `dot-config/yazi` (icons disabled for non-Nerd-Font terminals) |
| **utils/**  | helper scripts in `dot-local/bin/` → `~/.local/bin/` |
| **fonts/**  | bundled monospace fonts |
| **inputrc/**| readline settings |

## Compatibility

- **Bash 3.2+** (minimal), **4.0+** recommended
- **Vim 7.x+** (core), **8.0+** (persistent undo)
- **Neovim 0.10+** (plugin config uses `vim.uv`)
- The scripts need **Bash 4+** and GNU coreutils locally; a remote needs only
  `sshd` and a POSIX `sh`

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

- **Adding a component or a tool**: one row in `scripts/lib.sh` (`LINKS` or
  `TOOLS`). Install, remove, deploy, status and the `make help` lists all
  follow from it. Anything a symlink can't express (wiring a file, generating
  one) is a `setup_<name>` / `teardown_<name>` / `check_<name>` hook in the
  matching script.
- **Bash**: edit `bash/dot-bashrc_ext`; machine-local overrides go in `~/.bashrc.local`.
- **Vim**: edit `vim/dot-vimrc`.
- **Neovim**: edit `nvim/dot-config/nvim/init.lua`.
