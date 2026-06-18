#!/usr/bin/env bash
# bootstrap.sh — Download static/portable binaries to vendor/linux-<arch>/
#
# Run once on any internet-connected machine.
# Then use: make deploy HOST=user@server
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
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} "$api_url" 2>/dev/null \
        | grep '"browser_download_url"' \
        | grep -o 'https://[^"]*' \
        | grep -F "$pattern" \
        | head -1
}

# Download a .tar.gz, find a named binary inside it, install to VENDOR_DIR.
# Usage: install_tar <dest-name> <url> [<binary-name-in-archive>]
install_tar() {
    local dest="$1" url="$2" bin="${3:-$1}"

    if [ -z "$url" ]; then
        fail "$dest: no release URL found (pattern mismatch or GitHub rate limit)"
        return
    fi
    if [ -f "$VENDOR_DIR/$dest" ] && [ "$FORCE" != "true" ]; then
        skip "$dest (exists — FORCE=true to refresh)"
        return
    fi

    printf "  Fetching %-10s ...\r" "$dest"
    local tmp; tmp=$(mktemp -d)

    if curl -fsSL "$url" | tar -xz -C "$tmp" 2>/dev/null; then
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
# Usage: install_zip <dest-name> <url> [<binary-name-in-archive>]
install_zip() {
    local dest="$1" url="$2" bin="${3:-$1}"

    if [ -z "$url" ]; then
        fail "$dest: no release URL found (pattern mismatch or GitHub rate limit)"
        return
    fi
    if [ -f "$VENDOR_DIR/$dest" ] && [ "$FORCE" != "true" ]; then
        skip "$dest (exists — FORCE=true to refresh)"
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
# Usage: install_file <dest-name> <url>
install_file() {
    local dest="$1" url="$2"

    if [ -z "$url" ]; then
        fail "$dest: no release URL found"
        return
    fi
    if [ -f "$VENDOR_DIR/$dest" ] && [ "$FORCE" != "true" ]; then
        skip "$dest (exists — FORCE=true to refresh)"
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
#   fzf/lf use "amd64" / "arm64"
#   musl Rust builds use "x86_64" / "aarch64"
#   nvim/vim/tmux/yazi use "x86_64" / "arm64"
FZF_ARCH="amd64";  [ "$ARCH" = "aarch64" ] && FZF_ARCH="arm64"
LF_ARCH="amd64";   [ "$ARCH" = "aarch64" ] && LF_ARCH="arm64"
NVIM_ARCH="$ARCH"; [ "$ARCH" = "aarch64" ] && NVIM_ARCH="arm64"
VIM_ARCH="$ARCH";  [ "$ARCH" = "aarch64" ] && VIM_ARCH="arm64"
TMUX_ARCH="$ARCH"; [ "$ARCH" = "aarch64" ] && TMUX_ARCH="arm64"
MUSL="${ARCH}-unknown-linux-musl"

# fzf — Go static binary (junegunn/fzf)
install_tar fzf \
    "$(gh_latest junegunn/fzf "linux_${FZF_ARCH}.tar.gz")"

# fd — fast find replacement, Rust musl (sharkdp/fd)
install_tar fd \
    "$(gh_latest sharkdp/fd "${MUSL}.tar.gz")"

# bat — cat with syntax highlighting, Rust musl (sharkdp/bat)
install_tar bat \
    "$(gh_latest sharkdp/bat "${MUSL}.tar.gz")"

# rg (ripgrep) — fast grep, Rust musl (BurntSushi/ripgrep)
# Note: archive binary is named 'rg', not 'ripgrep'
install_tar rg \
    "$(gh_latest BurntSushi/ripgrep "${MUSL}.tar.gz")" rg

# eza — modern ls replacement, Rust musl (eza-community/eza)
install_tar eza \
    "$(gh_latest eza-community/eza "eza_${MUSL}.tar.gz")"

# delta — git diff pager, Rust musl (dandavison/delta)
install_tar delta \
    "$(gh_latest dandavison/delta "${MUSL}.tar.gz")"

# yazi — terminal file manager, glibc build (sxyazi/yazi)
# musl build has a /dev/tty ENXIO crash on WSL2; gnu build avoids it
# ya is the companion CLI (shell integration, flavours, package manager)
_yazi_url="$(gh_latest sxyazi/yazi "${ARCH}-unknown-linux-gnu.zip")"
install_zip yazi "$_yazi_url"
install_zip ya   "$_yazi_url"
unset _yazi_url

# lf — terminal file manager, Go static binary (gokcehan/lf)
# Fully static, no glibc dependency, x86_64 + arm64
install_tar lf \
    "$(gh_latest gokcehan/lf "lf-linux-${LF_ARCH}.tar.gz")"

# nnn — terminal file manager, C musl static (jarun/nnn)
# Smallest of the three (204KB); x86_64 only for prebuilt static
if [ "$ARCH" = "x86_64" ]; then
    install_tar nnn \
        "$(gh_latest jarun/nnn "nnn-musl-static-")" nnn-musl-static
else
    skip "nnn: no static build for $ARCH"
fi

# nvim — official tarball (requires glibc 2.32+ — won't run on RHEL 7/old systems)
# For old systems, deploy vim instead: make install HOST=server TOOL=vim
install_tar nvim \
    "$(gh_latest neovim/neovim "nvim-linux-${NVIM_ARCH}.tar.gz")"

# vim — static-pie single binary, no runtime needed, x86_64 + arm64 (heywoodlh/vim-builds)
# Zero glibc dependency. Use when nvim fails on old glibc servers.
install_file vim \
    "$(gh_latest heywoodlh/vim-builds "vim-${VIM_ARCH}")"

# tmux — official static builds (tmux/tmux-builds)
install_tar tmux \
    "$(gh_latest tmux/tmux-builds "linux-${TMUX_ARCH}.tar.gz")"

# ---------------------------------------------------------------------------

printf "\n"
info "Vendor directory contents:"
ls -lh "$VENDOR_DIR" 2>/dev/null || printf "  (empty)\n"
printf "\n${GREEN}Done.${NC} Run ${BOLD}make install HOST=user@server TOOL=<name>${NC} to push to a remote machine.\n"
