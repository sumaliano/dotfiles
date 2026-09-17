#!/usr/bin/env bash
# lib.sh — the one place that knows what this repo contains.
#
# Sourced by every script in scripts/. Holds the two tables (config components
# and vendored tools), the rule that maps a repo file to its ~ target, the
# wiring snippets that aren't symlinks, and the output helpers. Adding a
# component or a tool means editing a table here and nothing else.
#
# Run directly, it prints the name lists (the Makefile help does that).

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH=$(uname -m)                              # x86_64 | aarch64
VENDOR_DIR="$DOTFILES/vendor/linux-$ARCH"
# An overridden $XDG_CONFIG_HOME means the apps actually read from there, not
# ~/.config (per-session sandboxing on some hosts), so every ~/.config target
# is redirected through it — see local_path.
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "\n${BOLD}==> %s${NC}\n" "$*"; }
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
warn() { printf "  ${YELLOW}[warn]${NC} %s\n" "$*"; }
skip() { printf "  ${YELLOW}[skip]${NC} %s\n" "$*"; }
fail() { printf "  ${RED}[fail]${NC} %s\n" "$*"; }
die()  { printf "${RED}Error:${NC} %s\n" "$*" >&2; exit 1; }

in_list() { local x=$1; shift; [[ " $* " == *" $x "* ]]; }

# ── Configs ──────────────────────────────────────────────────────────────────
# Component → the repo files it links, relative to the repo root (globs expand).
# Each lands where GNU stow --dotfiles would put it: drop the package directory,
# turn a leading "dot-" on every path segment into ".", root it at ~:
#   nvim/dot-config/nvim         → ~/.config/nvim
#   fonts/dot-local/share/fonts  → ~/.local/share/fonts
# Anything that isn't a symlink (wiring ~/.bashrc, git's [include], joshuto's
# generated hsplit dir, …) is a setup_/teardown_/check_ hook in the scripts.
declare -A LINKS=(
    [bash]="bash/dot-bashrc_ext bash/dot-dir_colors"
    [git]="git/dot-gitignore_global"   # dot-gitconfig is [include]d from ~/.gitconfig, never linked
    [vim]="vim/dot-vimrc vim/dot-vim"
    [nvim]="nvim/dot-config/nvim"
    [tmux]="tmux/dot-tmux.conf"
    [inputrc]="inputrc/dot-inputrc"
    [joshuto]="joshuto/dot-config/joshuto"
    [yazi]="yazi/dot-config/yazi"
    [lazygit]="lazygit/dot-config/lazygit/config.yml"   # one file: lazygit owns the dir
    [aerc]="aerc/dot-config/aerc/aerc.conf aerc/dot-config/aerc/binds.conf aerc/dot-config/aerc/stylesets"  # accounts.conf holds credentials, stays local
    [hypr]="hypr/dot-config/hypr"
    [fonts]="fonts/dot-local/share/fonts"
    [utils]="utils/dot-local/bin/*"
    [lazyvim]=""                       # nothing linked: it's a git clone, see install.sh
)

# What a bare 'make dot' means, locally and remotely; the rest is opt-in by
# name. Remote skips what's machine-specific (hypr, fonts, utils) and lazyvim
# (a live clone that needs network on the machine running it).
ALL_LOCAL=(bash git nvim tmux inputrc joshuto yazi lazygit utils fonts)
ALL_REMOTE=(bash git inputrc nvim tmux joshuto yazi lazygit)
LOCAL_ONLY=(hypr fonts utils lazyvim)

COMPONENTS=$(printf '%s\n' "${!LINKS[@]}" | sort | tr '\n' ' ')
is_component() { [ -n "${LINKS[$1]+x}" ]; }

# Repo-relative sources of a component, one per line, globs expanded.
sources_of() { [ -n "${LINKS[$1]}" ] && ( cd "$DOTFILES" && printf '%s\n' ${LINKS[$1]} ); return 0; }

# ~-relative target of a repo-relative source (the stow --dotfiles rule).
target_of() {
    local out="" seg s
    IFS=/ read -ra seg <<< "${1#*/}"
    for s in "${seg[@]}"; do out+="/${s/#dot-/.}"; done
    printf '~%s' "$out"
}

# Absolute local path of a ~ target, honoring $XDG_CONFIG_HOME.
local_path() {
    case "$1" in
        "~/.config/"*) printf '%s/%s' "$CONFIG_HOME" "${1#\~/.config/}" ;;
        *)             printf '%s/%s' "$HOME" "${1#\~/}" ;;
    esac
}

# Is this a symlink of ours (pointing into the repo)? readlink -m resolves
# without needing the target to exist, so a link left dangling by a repo
# move still counts as ours and gets cleaned up.
ours() { [ -L "$1" ] && [[ $(readlink -m "$1") == "$DOTFILES"/* ]]; }

# ── Wiring that isn't a symlink ──────────────────────────────────────────────
# Shell snippets run on the machine being configured — locally through
# 'bash -c', remotely through ssh — so local and remote can't drift. They are
# POSIX sh except GNU 'sed -i'. The bash block is rewritten every time so an
# older wiring line gets replaced, not duplicated.
BASH_WIRE='sed -i "/# BEGIN DOTFILES/,/# END DOTFILES/d" ~/.bashrc 2>/dev/null; printf "\n# BEGIN DOTFILES\n[ -f ~/.bashrc_ext ] && . ~/.bashrc_ext\n# END DOTFILES\n" >> ~/.bashrc'
BASH_UNWIRE='sed -i "/# BEGIN DOTFILES/,/# END DOTFILES/d" ~/.bashrc 2>/dev/null; true'
BASH_CHECK='grep -q "# BEGIN DOTFILES" ~/.bashrc 2>/dev/null'

# git: the shared config is layered in through [include], leaving the user's
# own ~/.gitconfig (identity, credentials) untouched. Each takes the include
# path as $p — locally the repo file, remotely the pushed ~/.gitconfig.dotfiles.
GIT_WIRE='git config --global --get-all include.path 2>/dev/null | grep -qxF "$p" || git config --global --add include.path "$p"'
GIT_UNWIRE='re="^$(printf "%s" "$p" | sed "s/[.[*^\$\\\\]/\\\\&/g")\$"; git config --global --unset-all include.path "$re" 2>/dev/null; true'
GIT_CHECK='git config --global --get-all include.path 2>/dev/null | grep -qxF "$p"'

# Run a snippet here, or on $HOST when it's set. Extra args are prepended as
# assignments, e.g.  run_on_target 'p="$HOME/x"' "$GIT_WIRE"
run_on_target() {
    local snippet; snippet=$(printf '%s; ' "$@")
    if [ -n "${HOST:-}" ]; then ssh -q "$HOST" "$snippet"; else bash -c "$snippet"; fi
}

# Local-only junk that tar (unlike git) would otherwise ship to a remote:
# editor droppings anywhere, and vim's undo/backup/swap dirs at the top level
# of its package only (--anchored, so a nested backup/ elsewhere is kept).
TAR_EXCLUDES=(--anchored --exclude='*.sw[op]' --exclude='*/.git' --exclude='*/.netrwhist' --exclude='*/lazy-lock.json'
              --exclude=./.claude --exclude=./.idea --exclude=./.qodo --exclude=./undo --exclude=./backup --exclude=./swap)

# ── Tools ────────────────────────────────────────────────────────────────────
# name  github-repo  release-asset pattern  [binary name inside the archive]
# The pattern's suffix picks the unpacker (.zip, .tar*, anything else is a bare
# binary). Projects disagree on how to spell the architecture:
case "$ARCH" in
    aarch64) GO_ARCH=arm64; X_ARCH=arm64;  Z_ARCH=arm64 ;;
    *)       GO_ARCH=amd64; X_ARCH=x86_64; Z_ARCH=x64 ;;
esac
MUSL="$ARCH-unknown-linux-musl"
TOOLS=(
    "fzf      junegunn/fzf           linux_${GO_ARCH}.tar.gz"
    "fd       sharkdp/fd             ${MUSL}.tar.gz"
    "bat      sharkdp/bat            ${MUSL}.tar.gz"
    "rg       BurntSushi/ripgrep     ${MUSL}.tar.gz"
    "grex     pemistahl/grex         ${MUSL}.tar.gz"
    "eza      eza-community/eza      eza_${MUSL}.tar.gz"
    "zoxide   ajeetdsouza/zoxide     ${MUSL}.tar.gz"
    "delta    dandavison/delta       ${MUSL}.tar.gz"
    "lazygit  jesseduffield/lazygit  linux_${X_ARCH}.tar.gz"
    "btop     aristocratos/btop      btop-${MUSL}.tar.gz"
    "yazi     sxyazi/yazi            ${MUSL}.zip"
    "ya       sxyazi/yazi            ${MUSL}.zip"
    "joshuto  kamiyaa/joshuto        ${MUSL}.tar.gz"
    "7z       ip7z/7zip              linux-${Z_ARCH}.tar.xz   7zzs"   # 7zzs = the static build
    "nvim     neovim/neovim          nvim-linux-${X_ARCH}.tar.gz"     # needs glibc 2.32+; + runtime & parsers
    "vim      heywoodlh/vim-builds   vim-${X_ARCH}"                   # static, zero glibc: for old boxes
    "tmux     tmux/tmux-builds       linux-${X_ARCH}.tar.gz"
)
TOOL_NAMES=(); for t in "${TOOLS[@]}"; do TOOL_NAMES+=("${t%% *}"); done
# Vendored and installed locally, but left out of a bare 'make tool HOST=…':
# regex authoring is a local task.
LOCAL_ONLY_TOOLS=(grex)

is_tool() { in_list "$1" "${TOOL_NAMES[@]}"; }

# nvim's binary is useless without the runtime (VIMRUNTIME) and the treesitter
# parsers from the same tarball; they travel with it everywhere as two dirs.
vendored() {
    [ -f "$VENDOR_DIR/$1" ] || return 1
    [ "$1" != nvim ] || { [ -d "$VENDOR_DIR/nvim-runtime" ] && [ -d "$VENDOR_DIR/nvim-parsers" ]; }
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    printf 'Configs: %s\n' "$COMPONENTS"
    printf 'Tools:   %s\n' "${TOOL_NAMES[*]}"
fi
