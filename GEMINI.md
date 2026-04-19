# Project Overview: Dotfiles

A collection of minimal, portable, and high-performance configuration files for **Bash**, **Vim**, **Neovim**, and **Tmux**. This project is designed for "graceful degradation," meaning it works on older systems while automatically enabling advanced features (like LSP or FZF) when modern tools are detected.

## Core Philosophies
- **Portability**: Works across different Linux distributions and versions.
- **Minimal Bloat**: Prefers native features and small scripts over heavy plugin managers.
- **Extensibility**: Uses a "link-and-extend" approach (e.g., appending to `~/.bashrc` rather than replacing it).

---

## 🚀 Getting Started

### Installation
Use the provided `install.sh` script to set up your environment.
```bash
# Install everything
./install.sh

# Selective installation
./install.sh bash vim neovim tmux git utils
```
*Note: The installer creates symlinks for most configurations but appends a source line to your existing `~/.bashrc` to maintain local settings.*

### Key Commands & Shortcuts
- **Bash**: 
  - `reload`: Refresh your bash configuration.
  - `mark <name>` / `jump <name>`: Simple directory bookmarking.
  - `fcd`: Fuzzy-find and `cd` into a directory (requires `fzf`).
  - `extract <file>`: Universal archive extractor.
- **Vim/Neovim**:
  - `<leader>` is set to `Space`.
  - `jk`: Quick escape to Normal mode.
  - `<leader>w`: Save file.
  - `<leader>e`: Toggle file explorer (Netrw/Lexplore).
  - `<leader>ff`: Find files (native implementation).
  - `<leader>?`: Show a custom help menu with all shortcuts.
- **Git (Shell Aliases)**:
  - `gs`: Status | `ga`: Add | `gc`: Commit | `gp`: Push | `gl`: Visual graph log.

---

## 🛠️ Components

### 🐚 Bash (`_bashrc`)
- **Smart Prompt**: Displays current Git branch, status (staged, modified, untracked), active Virtualenv, and background jobs.
- **History Management**: Shared history across all open terminals; ignores common short commands.
- **Integrations**: Auto-detects and configures `fzf`, `bat`, `eza`, and `dircolors`.
- **Local Overrides**: Automatically loads `~/.bashrc.local` for machine-specific settings.

### 📝 Neovim (`_config/nvim/`)
- **init.lua**: A complete, modern Lua configuration in a single file.
- **Native LSP**: Pre-configured for Python, Bash, Rust, C/C++, and Java.
- **Built-in Git**: 
  - Gutter signs for staged/unstaged changes (with distinct colors).
  - `<leader>gd`: Side-by-side diff view (supports 3-way merge conflicts).
  - `<leader>ha`/`hu`: Stage/Unstage individual hunks.
- **Custom UI**: Uses `vim.ui.select` for fuzzy-finding recent files, buffers, and grep results.

### 📜 Vim (`_vimrc`)
- **Plugin-free**: Implements "Commentary" logic and whitespace stripping in pure Vimscript.
- **Modern Defaults**: Persistent undo, hybrid line numbers, and smart searching.

### 📂 Utilities (`_bin/`)
Custom scripts linked to `~/.bin/`:
- `sysinfo`: Comprehensive system status overview.
- `gitstatus`: Summary of all git repositories in a directory.
- `onchange`: Run a command whenever a file changes.
- `yt2mp3` / `yt2m4a`: Quick YouTube media conversion.

---

## 🔧 Development & Customization

- **Adding Scripts**: Place new scripts in `_bin/` and rerun `./install.sh utils` to link them.
- **Local Bash**: Use `~/.bashrc.local` for private environment variables or PATH exports.
- **Colorschemes**: Found in `_config/nvim/colors/`. Neovim defaults to `retrobox` or `badwolf`.
