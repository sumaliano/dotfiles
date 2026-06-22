#!/usr/bin/env bash
# deploy.sh — Push configs and/or vendor binaries to a remote server
#
# Usage:
#   ./scripts/deploy.sh user@host --configs --tool nvim     # configs only
#   ./scripts/deploy.sh user@host --bins    --tool nvim     # binaries only
#   ./scripts/deploy.sh user@host           --tool nvim     # both
#   ./scripts/deploy.sh user@host --bins    --tool nvim,fzf,bat

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "\n${BOLD}==> %s${NC}\n" "$*"; }
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
warn() { printf "  ${YELLOW}[warn]${NC} %s\n" "$*"; }
die()  { printf "${RED}Error:${NC} %s\n" "$*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────

REMOTE="${1:-}"
shift || true

TOOLS=""
MODE="both"   # both | configs | bins

while [ $# -gt 0 ]; do
    case "$1" in
        --configs) MODE="configs" ;;
        --bins)    MODE="bins" ;;
        --tool)
            shift; [ $# -gt 0 ] || die "--tool requires a value (e.g. --tool nvim)"
            TOOLS="$1" ;;
        --tool=*) TOOLS="${1#*=}" ;;
        *) printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
    esac
    shift
done

[ -z "$REMOTE" ] && die "Usage: $(basename "$0") [user@]host --tool name[,name]"
[ -z "$TOOLS"  ] && die "Specify at least one tool: --tool nvim  or  --tool nvim,fzf,bat"
command -v ssh &>/dev/null || die "ssh is required"
command -v scp &>/dev/null || die "scp is required"

# ── Config map: tool → "source|remote_dest" pairs ────────────────────────────

declare -A TOOL_CONFIG=(
    [nvim]="nvim/dot-config/nvim|~/.config/nvim"
    [vim]="vim/dot-vimrc|~/.vimrc vim/dot-vim|~/.vim"
    [tmux]="tmux/dot-tmux.conf|~/.tmux.conf"
    [joshuto]="joshuto/dot-config/joshuto|~/.config/joshuto"
    [yazi]="yazi/dot-config/yazi|~/.config/yazi"
    [inputrc]="inputrc/dot-inputrc|~/.inputrc"
)

# Config-only tools have no vendor binary (skip the "missing binary" warning).
# These are NOT included in 'all' — they must be named explicitly, e.g. --tool bash.
CONFIG_ONLY="bash git inputrc"

# ── Connect ───────────────────────────────────────────────────────────────────

info "Connecting to $REMOTE..."
REMOTE_ARCH=$(ssh -q "$REMOTE" uname -m 2>/dev/null) || die "Cannot connect to $REMOTE"
[ -z "$REMOTE_ARCH" ] && die "Could not detect remote architecture"
ok "Connected  (arch: linux-$REMOTE_ARCH)"

VENDOR_DIR="$DOTFILES/vendor/linux-$REMOTE_ARCH"
ssh -q "$REMOTE" 'mkdir -p ~/.local/bin'

# ── Deploy each tool ──────────────────────────────────────────────────────────

# Expand 'all'. What "everything" means depends on the mode:
#   configs → every config component the deployer knows how to push remotely
#   bins/both → every binary present in vendor/linux-<arch>/
if [ "$TOOLS" = "all" ]; then
    if [ "$MODE" = "configs" ]; then
        TOOLS="bash,git,inputrc,nvim,vim,tmux,joshuto,yazi"
    else
        [ -d "$VENDOR_DIR" ] || die "vendor/linux-$REMOTE_ARCH/ not found — run 'make vendor' first"
        TOOLS=$(ls "$VENDOR_DIR" | tr '\n' ',' | sed 's/,$//')
        [ -n "$TOOLS" ] || die "vendor/linux-$REMOTE_ARCH/ is empty — run 'make vendor' first"
    fi
fi

IFS=',' read -ra tool_list <<< "$TOOLS"
for tool in "${tool_list[@]}"; do
    tool="${tool// /}"
    info "Deploying: $tool"

    # ── Binary (skipped in --configs mode) ────────────────────────────────────
    if [ "$MODE" != "configs" ]; then
    # scp needs no remote binary, it's handled by sshd
    src="$VENDOR_DIR/$tool"
    if [ -f "$src" ]; then
        # nvim requires glibc 2.32+; warn early on old systems rather than fail at runtime
        if [ "$tool" = "nvim" ]; then
            remote_glibc=$(ssh -q "$REMOTE" "ldd --version 2>&1 | awk 'NR==1{print \$NF}'" 2>/dev/null || true)
            if [ -n "$remote_glibc" ] && awk "BEGIN{exit !($remote_glibc < 2.32)}"; then
                warn "nvim requires glibc 2.32+ but remote has $remote_glibc — try: make tool vim HOST=..."
                continue
            fi
        fi
        scp -q "$src" "$REMOTE:~/.local/bin/$tool"
        ssh -q "$REMOTE" "chmod +x ~/.local/bin/$tool"
        ok "$tool  →  ~/.local/bin/$tool"
    elif [ "$tool" = "vim" ]; then
        ok "vim  →  using system binary (no vendor build for $REMOTE_ARCH)"
    elif [[ " $CONFIG_ONLY " == *" $tool "* ]]; then
        : # config-only tool — no binary expected
    else
        warn "Binary not in vendor/linux-$REMOTE_ARCH/ — run 'make vendor' first"
    fi
    fi

    # ── Configs (skipped in --bins mode) ──────────────────────────────────────
    if [ "$MODE" = "bins" ]; then
        continue
    fi

    # Bash is special: copy the extension + dir_colors, then wire it into the
    # remote ~/.bashrc the same way the local installer does.
    if [ "$tool" = "bash" ]; then
        scp -q "$DOTFILES/bash/dot-bashrc_ext" "$REMOTE:.bashrc_ext"
        scp -q "$DOTFILES/bash/dot-dir_colors" "$REMOTE:.dir_colors"
        ssh -q "$REMOTE" bash <<'WIRE'
if ! grep -q "# BEGIN DOTFILES" ~/.bashrc 2>/dev/null; then
    printf '\n# BEGIN DOTFILES\n[ -f ~/.bashrc_ext ] && source ~/.bashrc_ext\n# END DOTFILES\n' >> ~/.bashrc
fi
WIRE
        ok "config  →  ~/.bashrc_ext (wired into ~/.bashrc)"
        continue
    fi

    # Git is special: the repo path doesn't exist on the remote, so copy the
    # shared config to ~/.gitconfig.dotfiles and layer it in via [include],
    # leaving the remote user's own ~/.gitconfig (identity/credentials) intact.
    if [ "$tool" = "git" ]; then
        scp -q "$DOTFILES/git/dot-gitconfig"        "$REMOTE:.gitconfig.dotfiles"
        scp -q "$DOTFILES/git/dot-gitignore_global" "$REMOTE:.gitignore_global"
        ssh -q "$REMOTE" bash <<'WIRE'
inc="$HOME/.gitconfig.dotfiles"
git config --global --get-all include.path 2>/dev/null | grep -qxF "$inc" \
    || git config --global --add include.path "$inc"
WIRE
        ok "config  →  ~/.gitconfig.dotfiles (included from ~/.gitconfig)"
        continue
    fi

    # Config — files via scp, directories via tar-over-ssh
    mapping="${TOOL_CONFIG[$tool]:-}"
    for pair in $mapping; do
        local_src="$DOTFILES/${pair%%|*}"
        remote_dest="${pair##*|}"
        if [ -e "$local_src" ]; then
            if [ -d "$local_src" ]; then
                ssh -q "$REMOTE" "mkdir -p $remote_dest"
                # Exclude local-only junk that tar (unlike git) would otherwise ship
                tar czf - -C "$local_src" \
                    --exclude='.claude' --exclude='.git' --exclude='.netrwhist' \
                    --exclude='lazy-lock.json' --exclude='*.sw[op]' \
                    . | ssh -q "$REMOTE" "tar xzf - -C $remote_dest"
            else
                ssh -q "$REMOTE" "mkdir -p $(dirname "$remote_dest")"
                scp -q "$local_src" "$REMOTE:$remote_dest"
            fi
            ok "config  →  $remote_dest"
        fi
    done
done

printf "\n${GREEN}${BOLD}Done!${NC}\n\n"
