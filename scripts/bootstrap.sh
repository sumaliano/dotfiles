#!/usr/bin/env bash
# bootstrap.sh — Download static/portable binaries to vendor/linux-<arch>/
#
# Run once on any internet-connected machine.
# Then use: make tool <name> HOST=user@server
#
# Override GITHUB_TOKEN env var to avoid API rate limits.
# Use FORCE=true to re-download already-present binaries.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH=$(uname -m)   # x86_64 | aarch64
VENDOR_DIR="$REPO_DIR/vendor/linux-$ARCH"
FORCE="${FORCE:-false}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

info() { printf "${BOLD}==> %s${NC}\n" "$*"; }
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
skip() { printf "  ${YELLOW}[skip]${NC} %s\n" "$*"; }
fail() { printf "  ${RED}[fail]${NC} %s\n" "$*"; }

mkdir -p "$VENDOR_DIR"

# Fetch the download URL for the latest GitHub release matching a filename pattern.
gh_latest() {
    local repo="$1" pattern="$2"
    local auth_flag=()
    [ -n "${GITHUB_TOKEN:-}" ] && auth_flag=(-H "Authorization: token $GITHUB_TOKEN")

    # Try /releases/latest first; fall back to /releases (catches pre-releases)
    local url
    url=$(curl -fsSL "${auth_flag[@]}" \
            "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
        | grep '"browser_download_url"' \
        | grep -o 'https://[^"]*' \
        | grep -F "$pattern" \
        | head -1)

    if [ -z "$url" ]; then
        url=$(curl -fsSL "${auth_flag[@]}" \
                "https://api.github.com/repos/$repo/releases?per_page=10" 2>/dev/null \
            | grep '"browser_download_url"' \
            | grep -o 'https://[^"]*' \
            | grep -F "$pattern" \
            | head -1)
    fi

    printf '%s\n' "$url"
}

# Download a .tar.gz, find a named binary inside it, install to VENDOR_DIR.
# Usage: install_tar <dest-name> <repo> <pattern> [<binary-name-in-archive>]
install_tar() {
    local dest="$1" repo="$2" pattern="$3" bin="${4:-$1}"

    if [ -f "$VENDOR_DIR/$dest" ] && [ "$FORCE" != "true" ]; then
        skip "$dest (exists — FORCE=true to refresh)"
        return
    fi
    local url; url=$(gh_latest "$repo" "$pattern")
    if [ -z "$url" ]; then
        fail "$dest: no release URL found (pattern mismatch or GitHub rate limit)"
        return
    fi

    printf "  Fetching %-10s ...\r" "$dest"
    local tmp; tmp=$(mktemp -d)

    if curl -fsSL -o "$tmp/archive" "$url" && tar -xf "$tmp/archive" -C "$tmp" 2>/dev/null; then
        local found; found=$(find "$tmp" -type f -name "$bin" | head -1)
        if [ -n "$found" ]; then
            cp "$found" "$VENDOR_DIR/$dest"
            chmod +x "$VENDOR_DIR/$dest"
            printf "\r\033[K"; ok "$dest"
        else
            printf "\r\033[K"; fail "$dest: binary '$bin' not found in archive"
        fi
    else
        printf "\r\033[K"; fail "$dest: download or extract failed — check URL: $url"
    fi

    rm -rf "$tmp"
}

# Download a .zip, find a named binary inside it, install to VENDOR_DIR.
# Usage: install_zip <dest-name> <repo> <pattern> [<binary-name-in-archive>]
install_zip() {
    local dest="$1" repo="$2" pattern="$3" bin="${4:-$1}"

    if [ -f "$VENDOR_DIR/$dest" ] && [ "$FORCE" != "true" ]; then
        skip "$dest (exists — FORCE=true to refresh)"
        return
    fi
    local url; url=$(gh_latest "$repo" "$pattern")
    if [ -z "$url" ]; then
        fail "$dest: no release URL found (pattern mismatch or GitHub rate limit)"
        return
    fi

    printf "  Fetching %-10s ...\r" "$dest"
    local tmp; tmp=$(mktemp -d)

    if curl -fsSL "$url" -o "$tmp/archive.zip" && unzip -q "$tmp/archive.zip" -d "$tmp/out" 2>/dev/null; then
        local found; found=$(find "$tmp/out" -type f -name "$bin" | head -1)
        if [ -n "$found" ]; then
            cp "$found" "$VENDOR_DIR/$dest"
            chmod +x "$VENDOR_DIR/$dest"
            printf "\r\033[K"; ok "$dest"
        else
            printf "\r\033[K"; fail "$dest: binary '$bin' not found in archive"
        fi
    else
        printf "\r\033[K"; fail "$dest: download or extract failed — check URL: $url"
    fi

    rm -rf "$tmp"
}

# Download a single-file binary (e.g. AppImage) directly.
# Usage: install_file <dest-name> <repo> <pattern>
install_file() {
    local dest="$1" repo="$2" pattern="$3"

    if [ -f "$VENDOR_DIR/$dest" ] && [ "$FORCE" != "true" ]; then
        skip "$dest (exists — FORCE=true to refresh)"
        return
    fi
    local url; url=$(gh_latest "$repo" "$pattern")
    if [ -z "$url" ]; then
        fail "$dest: no release URL found"
        return
    fi

    printf "  Fetching %-10s ...\r" "$dest"
    if curl -fsSL -o "$VENDOR_DIR/$dest" "$url"; then
        chmod +x "$VENDOR_DIR/$dest"
        printf "\r\033[K"; ok "$dest"
    else
        printf "\r\033[K"; fail "$dest: download failed"
        rm -f "$VENDOR_DIR/$dest"
    fi
}

# ---------------------------------------------------------------------------

info "Fetching portable binaries → vendor/linux-$ARCH/"
printf "\n"

# Naming conventions differ across projects:
#   fzf uses "amd64" / "arm64"
#   musl Rust builds use "x86_64" / "aarch64"
#   nvim/vim/tmux/yazi use "x86_64" / "arm64"
FZF_ARCH="amd64";     [ "$ARCH" = "aarch64" ] && FZF_ARCH="arm64"
NVIM_ARCH="$ARCH";    [ "$ARCH" = "aarch64" ] && NVIM_ARCH="arm64"
VIM_ARCH="$ARCH";     [ "$ARCH" = "aarch64" ] && VIM_ARCH="arm64"
TMUX_ARCH="$ARCH";    [ "$ARCH" = "aarch64" ] && TMUX_ARCH="arm64"
SEVENZ_ARCH="x64";    [ "$ARCH" = "aarch64" ] && SEVENZ_ARCH="arm64"
LG_ARCH="x86_64";     [ "$ARCH" = "aarch64" ] && LG_ARCH="arm64"
MUSL="${ARCH}-unknown-linux-musl"

# fzf — Go static binary (junegunn/fzf)
install_tar fzf   junegunn/fzf              "linux_${FZF_ARCH}.tar.gz"

# fd — fast find replacement, Rust musl (sharkdp/fd)
install_tar fd    sharkdp/fd               "${MUSL}.tar.gz"

# bat — cat with syntax highlighting, Rust musl (sharkdp/bat)
install_tar bat   sharkdp/bat              "${MUSL}.tar.gz"

# rg (ripgrep) — fast grep, Rust musl (BurntSushi/ripgrep)
# Note: archive binary is named 'rg', not 'ripgrep'
install_tar rg    BurntSushi/ripgrep       "${MUSL}.tar.gz"    rg

# eza — modern ls replacement, Rust musl (eza-community/eza)
install_tar eza   eza-community/eza        "eza_${MUSL}.tar.gz"

# zoxide — frecency-based 'cd' (z / zi), Rust musl (ajeetdsouza/zoxide)
# Needs a shell-init line to hook cd — see bash/dot-bashrc_ext.
install_tar zoxide ajeetdsouza/zoxide      "${MUSL}.tar.gz"

# delta — git diff pager, Rust musl (dandavison/delta)
install_tar delta dandavison/delta         "${MUSL}.tar.gz"

# lazygit — git TUI, static Go binary (jesseduffield/lazygit)
# Local-only: vendored and installed locally, but excluded from the remote
# "all" deploy (see deploy.sh). Keep your git fundamentals sharp for bare boxes.
install_tar lazygit jesseduffield/lazygit  "linux_${LG_ARCH}.tar.gz"

# btop — interactive system monitor, C++ musl static (aristocratos/btop)
install_tar btop  aristocratos/btop        "btop-${MUSL}.tar.gz"  btop

# yazi — terminal file manager, musl static (sxyazi/yazi)
# ya is the companion CLI (shell integration, flavours, package manager)
install_zip yazi  sxyazi/yazi              "${MUSL}.zip"
install_zip ya    sxyazi/yazi              "${MUSL}.zip"

# joshuto — ranger-like file manager with tabs, Rust musl (kamiyaa/joshuto)
install_tar joshuto kamiyaa/joshuto        "${MUSL}.tar.gz"

# 7z — official static build (ip7z/7zip); archive contains 7zzs (static) and 7zz (dynamic)
install_tar 7z      ip7z/7zip             "linux-${SEVENZ_ARCH}.tar.xz"  7zzs

# nvim — official tarball (requires glibc 2.32+ — won't run on RHEL 7/old systems)
# For old systems, deploy vim instead: make tool vim HOST=server
install_tar nvim  neovim/neovim            "nvim-linux-${NVIM_ARCH}.tar.gz"

# vim — static-pie single binary, no runtime needed, x86_64 + arm64 (heywoodlh/vim-builds)
# Zero glibc dependency. Use when nvim fails on old glibc servers.
install_file vim  heywoodlh/vim-builds     "vim-${VIM_ARCH}"

# tmux — official static builds (tmux/tmux-builds)
install_tar tmux  tmux/tmux-builds         "linux-${TMUX_ARCH}.tar.gz"

# ---------------------------------------------------------------------------

printf "\n"
info "Vendor directory contents:"
ls -lh "$VENDOR_DIR" 2>/dev/null || printf "  (empty)\n"
printf "\n${GREEN}Done.${NC} Run ${BOLD}make tool <name> HOST=user@server${NC} to push to a remote machine.\n"
