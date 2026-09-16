#!/usr/bin/env bash
# install.sh — Link dotfile components (stow when available, manual fallback otherwise)
# Usage: ./scripts/install.sh [component ...]   (no args = all)

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW=$(command -v stow 2>/dev/null || true)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "\n${BOLD}==> %s${NC}\n" "$*"; }
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
warn() { printf "  ${YELLOW}[warn]${NC} %s\n" "$*"; }

# Create a symlink, backing up any pre-existing file/dir at the destination
link_file() {
    local src="$1" dest="$2"
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ]; then
        local bak; bak="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up $(basename "$dest") → $bak"
        mv "$dest" "$bak"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    ok "$(basename "$dest")"
}

# Use stow if available; otherwise call the link_<pkg> fallback for that package
stow_pkg() {
    local pkg="$1"
    if [ -n "$STOW" ]; then
        stow --dotfiles -t "$HOME" -d "$DOTFILES" "$pkg"
        ok "stow $pkg"
    else
        "link_$pkg"
    fi
}

# ── Manual link fallbacks (used only when stow is absent) ──────────────────
# Each function replicates what stow --dotfiles would do for that package.

link_bash()    { link_file "$DOTFILES/bash/dot-dir_colors"             "$HOME/.dir_colors"; }
link_vim()     {
    link_file "$DOTFILES/vim/dot-vimrc" "$HOME/.vimrc"
    link_file "$DOTFILES/vim/dot-vim"   "$HOME/.vim"
}
link_nvim()    { link_file "$DOTFILES/nvim/dot-config/nvim"            "$HOME/.config/nvim"; }
link_hypr()    { link_file "$DOTFILES/hypr/dot-config/hypr"            "$HOME/.config/hypr"; }
link_tmux()    { link_file "$DOTFILES/tmux/dot-tmux.conf"              "$HOME/.tmux.conf"; }
link_git()     { link_file "$DOTFILES/git/dot-gitignore_global"        "$HOME/.gitignore_global"; }
link_utils() {
    local dest_dir="$HOME/.local/bin"
    mkdir -p "$dest_dir"
    for src in "$DOTFILES/utils/dot-bin"/*; do
        [ -f "$src" ] || continue
        link_file "$src" "$dest_dir/$(basename "$src")"
    done
}
link_fonts()   { link_file "$DOTFILES/fonts/dot-local/share/fonts"     "$HOME/.local/share/fonts"; }
link_inputrc() { link_file "$DOTFILES/inputrc/dot-inputrc"             "$HOME/.inputrc"; }
link_joshuto() { link_file "$DOTFILES/joshuto/dot-config/joshuto"      "$HOME/.config/joshuto"; }
link_yazi()    { link_file "$DOTFILES/yazi/dot-config/yazi"            "$HOME/.config/yazi"; }
link_lazygit() { link_file "$DOTFILES/lazygit/dot-config/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"; }
link_aerc() {
    link_file "$DOTFILES/aerc/dot-config/aerc/aerc.conf"   "$HOME/.config/aerc/aerc.conf"
    link_file "$DOTFILES/aerc/dot-config/aerc/binds.conf"  "$HOME/.config/aerc/binds.conf"
    link_file "$DOTFILES/aerc/dot-config/aerc/stylesets"   "$HOME/.config/aerc/stylesets"
}

# ── Component installers ────────────────────────────────────────────────────

install_bash() {
    info "Bash"
    stow_pkg bash
    if ! grep -q "# BEGIN DOTFILES" "$HOME/.bashrc" 2>/dev/null; then
        printf '\n# BEGIN DOTFILES\n[ -f "%s/bash/dot-bashrc_ext" ] && source "%s/bash/dot-bashrc_ext"\n# END DOTFILES\n' \
            "$DOTFILES" "$DOTFILES" >> "$HOME/.bashrc"
        ok "Wired into ~/.bashrc"
    else
        ok "~/.bashrc already configured"
    fi
    if [ ! -f "$HOME/.bashrc.local" ]; then
        printf '# Local machine-specific overrides\n# This file is ignored by git\n' > "$HOME/.bashrc.local"
        ok "Created ~/.bashrc.local"
    fi
}

install_vim() {
    info "Vim"
    mkdir -p "$DOTFILES/vim/dot-vim/undo" "$DOTFILES/vim/dot-vim/backup" "$DOTFILES/vim/dot-vim/swap"
    stow_pkg vim
}

install_neovim() {
    info "Neovim"
    stow_pkg nvim
}

install_hypr() {
    info "Hyprland"
    stow_pkg hypr
}

# LazyVim is not a stowed dotfile — it's an upstream starter template that
# lazy.nvim then self-manages (its own lockfile, its own plugin updates).
# NVIM_APPNAME isolates it in ~/.config/lazyvim, entirely separate from the
# nvim/ component above, so the two configs can't collide. Opt-in only (not
# in ALL): it needs network + git on first run, and re-running this must NOT
# clobber your subsequent in-editor plugin changes, so an existing install is
# left untouched.
install_lazyvim() {
    info "LazyVim"
    if [ -d "$HOME/.config/lazyvim" ]; then
        ok "~/.config/lazyvim already present — leaving your install untouched"
        return 0
    fi
    command -v git &>/dev/null || { warn "git not found — cannot clone the LazyVim starter"; return 0; }
    git clone --depth=1 https://github.com/LazyVim/starter "$HOME/.config/lazyvim" \
        && rm -rf "$HOME/.config/lazyvim/.git" \
        && ok "Cloned LazyVim starter → ~/.config/lazyvim  (launch with: lvim)"
}

install_tmux() {
    info "Tmux"
    stow_pkg tmux
}

install_git() {
    info "Git"
    # Link only the global ignore file. We deliberately do NOT stow the whole
    # git package — that would symlink ~/.gitconfig into the repo. Instead we
    # layer our shared config in via [include], preserving the user's own
    # ~/.gitconfig (identity, credentials, machine-specific settings).
    link_git

    # Safety: if a previous install symlinked ~/.gitconfig into this repo,
    # de-link it so `git config` below doesn't write through into the repo file.
    if [ -L "$HOME/.gitconfig" ] && readlink "$HOME/.gitconfig" | grep -q "$DOTFILES"; then
        rm "$HOME/.gitconfig"
    fi

    local target="$DOTFILES/git/dot-gitconfig"
    if git config --global --get-all include.path 2>/dev/null | grep -qxF "$target"; then
        ok "~/.gitconfig already includes dotfiles config"
    else
        git config --global --add include.path "$target"
        ok "Wired dotfiles config into ~/.gitconfig (via [include])"
    fi
}

install_utils() {
    info "Utils"
    chmod +x "$DOTFILES/utils/dot-bin/"* 2>/dev/null || true
    link_utils
}

# Under WSL the terminal drawing your text is a WINDOWS application, and it can
# only use fonts installed on the WINDOWS side — it cannot see the Linux
# ~/.local/share/fonts this package just linked. That is why glyphs render as
# tofu even with the font "installed". Registering a font from WSL means writing
# to the Windows registry, so we stage the files where Explorer can reach them
# and print the two steps that must happen over there. No-op outside WSL.
stage_fonts_windows() {
    grep -qi microsoft /proc/version 2>/dev/null || return 0

    local win_user dest
    win_user=$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')
    if [ -z "$win_user" ] || [ ! -d "/mnt/c/Users/$win_user" ]; then
        warn "WSL detected, but could not resolve the Windows user — install the"
        warn "Nerd Font manually from fonts/dot-local/share/fonts/UbuntuMono/"
        return 0
    fi

    dest="/mnt/c/Users/$win_user/Downloads/nerd-fonts"
    if ! mkdir -p "$dest" 2>/dev/null; then
        warn "Cannot write to $dest — skipping the Windows-side staging"
        return 0
    fi

    cp "$DOTFILES"/fonts/dot-local/share/fonts/UbuntuMono/UbuntuMonoNerdFontMono-*.ttf "$dest"/ 2>/dev/null
    ok "Staged Nerd Font → $dest"
    printf "  ${BOLD}Two steps left, on the Windows side (once per machine):${NC}\n"
    printf "    1. Open that folder, select the .ttf files, right-click → Install\n"
    printf "    2. Terminal → Settings → your profile → Appearance → Font face:\n"
    printf "       ${BOLD}UbuntuMono Nerd Font Mono${NC}\n"
}

install_fonts() {
    info "Fonts"
    stow_pkg fonts
    if command -v fc-cache &>/dev/null; then
        fc-cache -f
        ok "Font cache refreshed"
    fi
    stage_fonts_windows
}

install_inputrc() {
    info "Inputrc"
    stow_pkg inputrc
}

# joshuto reads [display] mode once at startup and has no runtime toggle, so the
# dual-pane layout needs a config dir of its own. Only joshuto.toml differs, and
# it is GENERATED from the real one with the mode line swapped — so the two can
# never drift — while the other three files are symlinked back to the originals
# (joshuto replaces each config file wholesale, it never merges with defaults).
# Launched by the `jjs` wrapper in bash/dot-bashrc_ext.
link_joshuto_hsplit() {
    local src="$DOTFILES/joshuto/dot-config/joshuto"
    local dest="$HOME/.config/joshuto-hsplit"
    mkdir -p "$dest"
    {
        printf '# GENERATED by scripts/install.sh — edit joshuto/dot-config/joshuto/joshuto.toml.\n'
        sed 's/^mode = "default"$/mode = "hsplit"/' "$src/joshuto.toml"
    } > "$dest/joshuto.toml"
    if grep -q '^mode = "hsplit"$' "$dest/joshuto.toml"; then
        ok "joshuto-hsplit/joshuto.toml"
    else
        warn "no 'mode = \"default\"' line in joshuto.toml — jjs will not be dual-pane"
    fi
    local f
    for f in keymap.toml mimetype.toml preview_file.sh; do
        link_file "$src/$f" "$dest/$f"
    done
}

install_joshuto() {
    info "Joshuto"
    stow_pkg joshuto
    link_joshuto_hsplit
}

install_yazi() {
    info "Yazi"
    stow_pkg yazi
}

install_lazygit() {
    info "Lazygit"
    # lazygit auto-creates an empty ~/.config/lazygit/config.yml on first run, so
    # we back-up-and-link the single file rather than stow the package (stow would
    # conflict with that auto-created file). Same direct-link pattern as git.
    link_lazygit
}

install_aerc() {
    info "Aerc"
    # accounts.conf holds live IMAP/SMTP credentials, so - same reasoning as
    # git's ~/.gitconfig - we deliberately do NOT stow the whole package.
    # Only the portable files (styling, keybinds, general config) are linked;
    # accounts.conf stays a real, untracked file in ~/.config/aerc.
    link_aerc
    if [ ! -f "$HOME/.config/aerc/accounts.conf" ]; then
        warn "No ~/.config/aerc/accounts.conf — aerc won't have any accounts until you add one"
    fi
}

# ── Vendor tool install ──────────────────────────────────────────────────────
# Maps tool name → dotfile component (runs install_<component> for config).
# CONFIG_ONLY tools have no vendor binary — system binary is assumed present.

declare -A TOOL_COMPONENT=(
    [nvim]="neovim"
    [vim]="vim"
    [tmux]="tmux"
    [joshuto]="joshuto"
    [yazi]="yazi"
    [lazygit]="lazygit"
)

install_tool() {
    local tool="$1"
    local arch; arch=$(uname -m)
    local src="$DOTFILES/vendor/linux-$arch/$tool"

    info "Tool: $tool"

    # Binary
    if [ -f "$src" ]; then
        mkdir -p "$HOME/.local/bin"
        cp "$src" "$HOME/.local/bin/$tool"
        chmod +x "$HOME/.local/bin/$tool"
        ok "$tool  →  ~/.local/bin/$tool"
        warn "Run 'hash -r' (or open a new terminal) to refresh the shell's command cache"
    else
        warn "Binary not found in vendor/linux-$arch/ — run 'make vendor' first"
    fi

    # nvim needs three pieces from the tarball, all resolved relative to the
    # binary prefix (~/.local/ when binary is in ~/.local/bin/):
    #   share/nvim/runtime/   → VIMRUNTIME  (Lua/VimScript stdlib)
    #   lib/nvim/parser/*.so  → treesitter grammars (must match bundled queries)
    # Copied (not symlinked) so that 'make clean' can wipe vendor/ without
    # breaking the installed nvim — same principle as the binary itself.
    if [ "$tool" = "nvim" ]; then
        local rt_src="$DOTFILES/vendor/linux-$arch/nvim-runtime"
        local pr_src="$DOTFILES/vendor/linux-$arch/nvim-parsers"
        if [ -d "$rt_src" ]; then
            mkdir -p "$HOME/.local/share/nvim"
            rm -rf "$HOME/.local/share/nvim/runtime"
            cp -r "$rt_src" "$HOME/.local/share/nvim/runtime"
            ok "nvim runtime  →  ~/.local/share/nvim/runtime"
        else
            warn "nvim runtime not in vendor/ — run 'make vendor' first, then re-run 'make tool nvim'"
        fi
        if [ -d "$pr_src" ]; then
            mkdir -p "$HOME/.local/lib/nvim"
            rm -rf "$HOME/.local/lib/nvim/parser"
            cp -r "$pr_src" "$HOME/.local/lib/nvim/parser"
            ok "nvim parsers  →  ~/.local/lib/nvim/parser"
        else
            warn "nvim parsers not in vendor/ — run 'make vendor' first, then re-run 'make tool nvim'"
        fi
    fi

    # Config — reuse the existing component installer when one exists
    local component="${TOOL_COMPONENT[$tool]:-}"
    if [ -n "$component" ] && declare -f "install_$component" &>/dev/null; then
        "install_$component"
    fi
}

# ── Entry point ─────────────────────────────────────────────────────────────

ALL=(bash vim neovim tmux git hypr utils fonts inputrc joshuto yazi lazygit aerc)

# --tool <name>[,name] installs vendor binaries + their configs locally
if [ "${1:-}" = "--tool" ]; then
    shift
    [ $# -gt 0 ] || { printf "${RED}Error:${NC} --tool requires a name (e.g. --tool nvim)\n" >&2; exit 1; }
    arg="$1"

    # Expand 'all' to every binary present in the local vendor directory
    if [ "$arg" = "all" ]; then
        vendor_dir="$DOTFILES/vendor/linux-$(uname -m)"
        [ -d "$vendor_dir" ] || { printf "${RED}Error:${NC} vendor/linux-$(uname -m)/ not found — run 'make vendor'\n" >&2; exit 1; }
        arg=$(ls "$vendor_dir" | tr '\n' ',' | sed 's/,$//')
        [ -n "$arg" ] || { printf "${RED}Error:${NC} vendor/linux-$(uname -m)/ is empty — run 'make vendor'\n" >&2; exit 1; }
    fi

    IFS=',' read -ra tools <<< "$arg"
    for t in "${tools[@]}"; do
        install_tool "${t// /}"
    done
    printf "\n${GREEN}Done!${NC}\n"
    exit 0
fi

# No args — or the explicit keyword 'all' — means every config component.
if [ $# -eq 0 ] || { [ $# -eq 1 ] && [ "$1" = "all" ]; }; then
    targets=("${ALL[@]}")
else
    targets=("$@")
fi

for t in "${targets[@]}"; do
    # User-facing name → internal component function (e.g. nvim → neovim)
    comp="$t"; [ "$t" = "nvim" ] && comp="neovim"
    if declare -f "install_$comp" &>/dev/null; then
        "install_$comp"
    else
        printf "${RED}Error:${NC} Unknown component '%s'\n" "$t" >&2
        printf "Available: bash vim nvim tmux git hypr utils fonts inputrc joshuto yazi lazygit aerc lazyvim\n" >&2
        exit 1
    fi
done

printf "\n${GREEN}Done!${NC}\n"
