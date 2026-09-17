#!/usr/bin/env bash
# deploy.sh — push config components or vendored binaries to a remote over SSH.
#
#   deploy.sh --host u@h --configs [name ...]   no name = ALL_REMOTE
#   deploy.sh --host u@h --bins    [name ...]   no name = every vendored tool (minus LOCAL_ONLY_TOOLS)
#
# The remote mirror of install.sh: same LINKS table, same targets, but files
# are copied (scp / tar over ssh) since there's no repo on the far side to
# symlink into. Needs nothing on the remote beyond sshd and a POSIX sh.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

MODE=""; HOST=""; NAMES=()
while [ $# -gt 0 ]; do
    case "$1" in
        --configs) MODE=configs ;;
        --bins)    MODE=bins ;;
        --host)    shift; HOST="${1:-}" ;;
        --host=*)  HOST="${1#--host=}" ;;
        -*)        die "Unknown option: $1" ;;
        *)         NAMES+=("$1") ;;
    esac
    shift
done
[ -n "$MODE" ] || die "usage: deploy.sh --host u@h --configs|--bins [name ...]"
[ -n "$HOST" ] || die "deploy.sh needs --host user@host"
command -v ssh >/dev/null && command -v scp >/dev/null || die "ssh and scp are required"

# ── Connect ──────────────────────────────────────────────────────────────────

info "Connecting to $HOST"
REMOTE_ARCH=$(ssh -q "$HOST" uname -m 2>/dev/null) || die "Cannot connect to $HOST"
[ -n "$REMOTE_ARCH" ] || die "Could not detect the remote architecture"
# The remote's real XDG config dir — some hosts override it per session, and
# pushing to ~/.config there fails silently (no error, app just doesn't see it).
REMOTE_CONFIG_HOME=$(ssh -q "$HOST" 'printf %s "${XDG_CONFIG_HOME:-~/.config}"' 2>/dev/null)
[ -n "$REMOTE_CONFIG_HOME" ] || REMOTE_CONFIG_HOME='~/.config'
ok "connected  (linux-$REMOTE_ARCH, config in $REMOTE_CONFIG_HOME)"
VENDOR_DIR="$DOTFILES/vendor/linux-$REMOTE_ARCH"   # override lib.sh's local-arch default

# ── Copy helpers ─────────────────────────────────────────────────────────────

# Copy a local file or directory to a remote path, creating parents.
push() {
    local src=$1 dest=$2
    if [ -d "$src" ]; then
        ssh -q "$HOST" "mkdir -p $dest" \
            && tar czf - -C "$src" "${TAR_EXCLUDES[@]}" . | ssh -q "$HOST" "tar xzf - -C $dest"
    else
        ssh -q "$HOST" "mkdir -p $(dirname "$dest")" && scp -q "$src" "$HOST:$dest"
    fi
}

# ── Configs ──────────────────────────────────────────────────────────────────

deploy_component() {
    local comp=$1 src target
    info "$comp"
    while read -r src; do
        [ -n "$src" ] || continue
        target=$(target_of "$src")
        target=${target/#\~\/.config\//$REMOTE_CONFIG_HOME/}
        push "$DOTFILES/$src" "$target" && ok "$target"
    done < <(sources_of "$comp")
    if declare -f "setup_$comp" >/dev/null; then "setup_$comp"; fi
}

setup_bash() { run_on_target "$BASH_WIRE" && ok "wired into ~/.bashrc"; }

# The repo isn't on the remote, so the shared config goes to a fixed path and
# is [include]d from there.
setup_git() {
    push "$DOTFILES/git/dot-gitconfig" '~/.gitconfig.dotfiles' && ok "~/.gitconfig.dotfiles"
    run_on_target 'p="$HOME/.gitconfig.dotfiles"' "$GIT_WIRE" && ok "included from ~/.gitconfig"
}

# ── Binaries ─────────────────────────────────────────────────────────────────

deploy_bin() {
    local tool=$1
    info "$tool"
    vendored "$tool" || { warn "not in vendor/linux-$REMOTE_ARCH/ — run 'make vendor $tool' on a linux-$REMOTE_ARCH box"; return; }
    local need="${GLIBC_MIN[$tool]:-}"
    if [ -n "$need" ]; then
        local glibc; glibc=$(ssh -q "$HOST" "ldd --version 2>&1 | awk 'NR==1{print \$NF}'" 2>/dev/null || true)
        if [ -n "$glibc" ] && awk "BEGIN{exit !($glibc < $need)}"; then
            warn "$tool needs glibc $need+ but $HOST has $glibc${tool/#nvim/ — use: make tool vim HOST=$HOST}"
            return
        fi
    fi
    # Land under a temp name and rename over: a binary that's running on the
    # remote can't be overwritten in place, but can be replaced.
    push "$VENDOR_DIR/$tool" "~/.local/bin/$tool.new" \
        && ssh -q "$HOST" "chmod +x ~/.local/bin/$tool.new && mv -f ~/.local/bin/$tool.new ~/.local/bin/$tool" \
        && ok "~/.local/bin/$tool" || { fail "~/.local/bin/$tool"; return; }
    [ "$tool" = nvim ] || return 0
    ssh -q "$HOST" "rm -rf ~/.local/share/nvim/runtime ~/.local/lib/nvim/parser"
    push "$VENDOR_DIR/nvim-runtime" "~/.local/share/nvim/runtime" && ok "~/.local/share/nvim/runtime"
    push "$VENDOR_DIR/nvim-parsers" "~/.local/lib/nvim/parser"    && ok "~/.local/lib/nvim/parser"
}

# ── Drive it ─────────────────────────────────────────────────────────────────

if [ "$MODE" = configs ]; then
    [ ${#NAMES[@]} -gt 0 ] || NAMES=("${ALL_REMOTE[@]}")
    for n in "${NAMES[@]}"; do
        is_component "$n" || die "Unknown component '$n'. Available: $COMPONENTS"
        ! in_list "$n" "${LOCAL_ONLY[@]}" || die "'$n' is local-only (see LOCAL_ONLY in scripts/lib.sh)"
    done
    for n in "${NAMES[@]}"; do deploy_component "$n"; done
else
    if [ ${#NAMES[@]} -eq 0 ]; then
        for t in "${TOOL_NAMES[@]}"; do
            in_list "$t" "${LOCAL_ONLY_TOOLS[@]}" || ! vendored "$t" || NAMES+=("$t")
        done
        [ ${#NAMES[@]} -gt 0 ] || die "nothing in vendor/linux-$REMOTE_ARCH/ — run 'make vendor' on a linux-$REMOTE_ARCH box"
    fi
    for n in "${NAMES[@]}"; do
        is_tool "$n" || die "Unknown tool '$n'. Available: ${TOOL_NAMES[*]}"
    done
    for n in "${NAMES[@]}"; do deploy_bin "$n"; done
fi

printf "\n${GREEN}Done!${NC}\n"
