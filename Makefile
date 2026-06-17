# Dotfiles Makefile — all logic lives in scripts/

DOTFILES_DIR := $(shell pwd)

BOLD := \033[1m
RED  := \033[0;31m
NC   := \033[0m

.PHONY: all help install clean uninstall status update vendor
.PHONY: bash vim neovim tmux git utils fonts inputrc

all: help

help:
	@printf "$(BOLD)Usage: make [target] [HOST=user@host] [TOOL=name]$(NC)\n\n"
	@printf "Install:\n"
	@printf "  install                        Install all dotfile components locally\n"
	@printf "  install TOOL=nvim              Install vendor tool locally (binary + config)\n"
	@printf "  install TOOL=all               Install all vendor tools locally\n"
	@printf "  install HOST=u@h TOOL=nvim     Deploy vendor tool to remote server\n"
	@printf "  install HOST=u@h TOOL=all      Deploy all vendor tools to remote server\n"
	@printf "  bash vim neovim ...            Install a single dotfile component locally\n"
	@printf "\nManagement:\n"
	@printf "  status                         Show local installation + vendor status\n"
	@printf "  status HOST=u@h                Show status on remote server\n"
	@printf "  update                         Pull latest and reinstall\n"
	@printf "  clean                          Remove all dotfile symlinks locally\n"
	@printf "  clean TOOL=nvim                Remove vendor tool locally\n"
	@printf "  clean TOOL=all                 Remove all vendor tools locally\n"
	@printf "  clean HOST=u@h TOOL=nvim       Remove vendor tool from remote server\n"
	@printf "  clean HOST=u@h TOOL=all        Remove all vendor tools from remote server\n"
	@printf "\nVendor:\n"
	@printf "  vendor                         Download static binaries to vendor/linux-<arch>/\n"
	@printf "\nAll scripts are also runnable directly from scripts/\n"

# ── Install / Deploy ─────────────────────────────────────────────────────────

install:
	@if [ -n "$(HOST)" ]; then \
		[ -n "$(TOOL)" ] || { printf "$(RED)[err]$(NC) Remote install requires TOOL=name\n"; exit 1; }; \
		bash $(DOTFILES_DIR)/scripts/deploy.sh "$(HOST)" --tool "$(TOOL)"; \
	else \
		bash $(DOTFILES_DIR)/scripts/install.sh $(if $(TOOL),--tool $(TOOL)); \
	fi

bash vim neovim tmux git utils fonts inputrc:
	@bash $(DOTFILES_DIR)/scripts/install.sh $@

# ── Management ───────────────────────────────────────────────────────────────

status:
	@bash $(DOTFILES_DIR)/scripts/status.sh $(if $(HOST),--host $(HOST))

update:
	@git pull
	@$(MAKE) install

clean: uninstall
uninstall:
	@bash $(DOTFILES_DIR)/scripts/uninstall.sh \
		$(if $(HOST),--host $(HOST)) \
		$(if $(TOOL),--tool $(TOOL))

# ── Vendor ───────────────────────────────────────────────────────────────────

vendor:
	@bash $(DOTFILES_DIR)/scripts/bootstrap.sh
