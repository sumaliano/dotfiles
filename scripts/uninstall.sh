#!/usr/bin/env bash
# uninstall.sh — remove config components or binaries, locally or on a remote.
#
#   uninstall.sh --configs [--host u@h] name ...   'all' = everything of ours (remote: ALL_REMOTE)
#   uninstall.sh --bins    [--host u@h] name ...   'all' = every installed tool (remote: every tool)
#
# Locally only our own symlinks are touched — a real file or directory at a
# target path is reported and left alone. Remote configs are copies (deploy.sh
# can't symlink into a repo that isn't there), so those are removed by path.

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
[ -n "$MODE" ] || die "usage: uninstall.sh --configs|--bins [--host u@h] [name ...]"
[ -z "$HOST" ] || command -v ssh >/dev/null || die "ssh is required"

# ── Configs ──────────────────────────────────────────────────────────────────

remove_component() {
    local comp=$1 src target dest n=0
    info "$comp${HOST:+ (on $HOST)}"
    if [ -n "$HOST" ]; then
        local paths=""
        while read -r src; do
            [ -n "$src" ] || continue
            target=$(target_of "$src")
            paths+=" ${target/#\~\/.config\//$REMOTE_CONFIG_HOME/}"
        done < <(sources_of "$comp")
        [ -z "$paths" ] || { ssh -q "$HOST" "rm -rf $paths" && ok "removed:$paths"; }
    else
        while read -r src; do
            [ -n "$src" ] || continue
            target=$(target_of "$src"); dest=$(local_path "$target")
            if ours "$dest"; then
                rm "$dest"; ok "$target"; n=$((n + 1))
            elif [ -e "$dest" ] || [ -L "$dest" ]; then
                warn "$target is not a dotfiles link — left alone"
            fi
        done < <(sources_of "$comp")
    fi
    if declare -f "teardown_$comp" >/dev/null; then "teardown_$comp" && n=$((n + 1)); fi
    [ -n "$HOST" ] || [ $n -gt 0 ] || skip "nothing to remove"
}

teardown_bash() { run_on_target "$BASH_UNWIRE" && ok "unwired ~/.bashrc"; }

teardown_git() {
    if [ -n "$HOST" ]; then
        run_on_target 'p="$HOME/.gitconfig.dotfiles"' "$GIT_UNWIRE" 'rm -f "$p"'
    else
        run_on_target "p=\"$DOTFILES/git/dot-gitconfig\"" "$GIT_UNWIRE"
    fi && ok "dropped the [include] from ~/.gitconfig"
}

# The generated dual-pane dir (see setup_joshuto in install.sh) is ours outright.
# Hooks return non-zero when there was nothing to do.
teardown_joshuto() {
    [ -z "$HOST" ] && [ -d "$CONFIG_HOME/joshuto-hsplit" ] || return 1
    rm -rf "$CONFIG_HOME/joshuto-hsplit" && ok "~/.config/joshuto-hsplit"
}

# lazyvim is a clone plus lazy.nvim's own plugin/state/cache dirs, keyed by
# NVIM_APPNAME=lazyvim; removing it means removing all four.
teardown_lazyvim() {
    local d n=0
    for d in "$CONFIG_HOME/lazyvim" "$HOME/.local/share/lazyvim" "$HOME/.local/state/lazyvim" "$HOME/.cache/lazyvim"; do
        [ -e "$d" ] || continue
        rm -rf "$d" && ok "${d/#$HOME/\~}" && n=$((n + 1))
    done
    [ $n -gt 0 ]
}

# ── Binaries ─────────────────────────────────────────────────────────────────

remove_bin() {
    local tool=$1
    info "$tool${HOST:+ (on $HOST)}"
    local extras=""
    [ "$tool" != nvim ] || extras="~/.local/share/nvim/runtime ~/.local/lib/nvim/parser"
    if [ -n "$HOST" ]; then
        ssh -q "$HOST" "rm -rf ~/.local/bin/$tool $extras" && ok "removed: ~/.local/bin/$tool $extras"
    elif [ -e "$HOME/.local/bin/$tool" ]; then
        rm -f "$HOME/.local/bin/$tool"; ok "~/.local/bin/$tool"
        for d in $extras; do rm -rf "${d/#\~/$HOME}" && ok "$d"; done
    else
        skip "not in ~/.local/bin/"
    fi
}

# ── Drive it ─────────────────────────────────────────────────────────────────

if [ -n "$HOST" ]; then
    REMOTE_CONFIG_HOME=$(ssh -q "$HOST" 'printf %s "${XDG_CONFIG_HOME:-~/.config}"' 2>/dev/null) \
        || die "Cannot connect to $HOST"
fi

scope=local; [ -z "$HOST" ] || scope=remote
if [ "$MODE" = configs ]; then
    resolve_names "make remove dot" configs "$scope"
    for n in "${NAMES[@]}"; do
        is_component "$n" || die "Unknown component '$n'. Available: $COMPONENTS"
        [ -z "$HOST" ] || ! in_list "$n" "${LOCAL_ONLY[@]}" || die "'$n' is local-only — it is never on a remote"
    done
    for n in "${NAMES[@]}"; do remove_component "$n"; done
else
    resolve_names "make remove tool" tools "$scope"
    for n in "${NAMES[@]}"; do
        is_tool "$n" || die "Unknown tool '$n'. Available: ${TOOL_NAMES[*]}"
    done
    for n in "${NAMES[@]}"; do remove_bin "$n"; done
fi

printf "\n${GREEN}Done!${NC}\n"
