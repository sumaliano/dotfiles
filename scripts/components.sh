# components.sh — single source of truth for dotfile config component names.
# Sourced by install.sh, deploy.sh, and uninstall.sh so adding a component
# means editing this file once. Previously each script kept its own copy of
# "every component" and they drifted: uninstall.sh silently never learned
# about hypr, lazygit, or aerc, and deploy.sh never learned about aerc.

# Every config component 'make dot' installs locally when given no name.
ALL_CONFIGS=(bash nvim tmux git utils fonts inputrc joshuto yazi lazygit)

# Subset deploy.sh / uninstall.sh's remote (--host) path supports. hypr
# (host-specific WM config), utils (local scripts), and fonts (large binary
# asset) are deliberately local-only. lazyvim is opt-in-only everywhere (see
# install_lazyvim) and self-managing, so it's excluded from every "all" list.
ALL_CONFIGS_REMOTE=(bash git inputrc nvim tmux joshuto yazi lazygit)
