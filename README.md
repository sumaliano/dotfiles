# Dotfiles

Minimal, portable shell and editor configurations for **Bash**, **Vim**, and **Neovim**.

## Features

- **Bash**: Enhanced prompt with git integration
- **Neovim**: Plugin-free config with LSP, Git integration, fzf navigation
- **Portability**: Graceful degradation on minimal systems, auto-detect modern tools
- **No bloat**: Single files, no plugins (except nvim LSP)
- **Stow-Compatible**: Organized folders for use with GNU Stow (`--dotfiles`) or the provided Makefile.

## Quick Start

```bash
git clone https://github.com/username/dotfiles ~/dotfiles
cd ~/dotfiles

# Install to home directory (uses GNU Stow if available, otherwise falls back to ln)
make install

# Or install selectively
make vim bash tmux
```

## What's Included

The repository is organized into components compatible with **GNU Stow** using the `--dotfiles` naming convention (this keeps the repository free of hidden files):

- **bash/**: `dot-bashrc_ext`, `dot-dir_colors`
- **nvim/**: Neovim configuration (`dot-config/nvim`)
- **vim/**: Vim configuration (`dot-vimrc`, `dot-vim/`)
- **tmux/**: `dot-tmux.conf`
- **git/**: `dot-gitconfig`, `dot-gitignore_global`
- **utils/**: Custom scripts in `dot-bin/`
- **fonts/**: System fonts
- **inputrc/**: Readline settings

## Compatibility

- **Bash 3.2+** (minimal systems), **4.0+** recommended
- **Vim 7.x+** (core), **8.0+** (persistent undo)
- **Neovim 0.8+** (LSP requires 0.9+)
- **Graceful degradation**: Works on any system with `make` or `stow`.

## LSP Setup (Neovim)

Auto-detects installed servers. To enable:

```bash
# Python
pip install pyright

# Bash
npm install -g bash-language-server

# Rust
rustup component add rust-analyzer

# C/C++
sudo apt install clangd  # or your package manager
```

Check status with `:lua print(vim.lsp.get_log_path())` or press `<leader>li`.

## Customization

### Bash
Edit `bash/dot-bashrc_ext`. Local overrides go in `~/.bashrc.local`.

### Vim
Edit `vim/dot-vimrc`.

### Neovim
Edit `nvim/dot-config/nvim/init.lua`.
