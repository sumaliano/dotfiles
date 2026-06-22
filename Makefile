# Dotfiles Makefile — thin wrapper; all logic lives in scripts/
#
# Two verbs, one axis. 'dot' = configs, 'tool' = portable binaries.
# Add HOST= to do the same thing on a remote box over SSH; omit it for local.
#
#   make dot                  link ALL configs locally
#   make dot nvim tmux        link just those configs locally
#   make dot nvim HOST=u@s    push the nvim config to a server
#   make tool                 install ALL vendored binaries locally
#   make tool fzf bat         install just those binaries locally
#   make tool nvim HOST=u@s   push the nvim binary to a server
#
# So a full remote nvim is:  make dot nvim HOST=u@s && make tool nvim HOST=u@s
# No name = everything.

DOTFILES_DIR := $(shell pwd)

BOLD := \033[1m
DIM  := \033[2m
RED  := \033[0;31m
NC   := \033[0m

# Verbs are the real targets. Any other word on the command line is a NAME
# (a config component or a tool) passed through to the underlying script.
VERBS := help dot tool remove vendor clean status
NAMES := $(filter-out $(VERBS),$(MAKECMDGOALS))

# 'remove' takes a sub-verb: 'make remove dot nvim' / 'make remove tool nvim'.
# CMD = the leading word; KIND = the dot/tool that follows 'remove'.
CMD  := $(firstword $(MAKECMDGOALS))
KIND := $(firstword $(filter dot tool,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))))

# Join "a b c" → "a,b,c" for the scripts that take a comma list.
comma := ,
empty :=
space := $(empty) $(empty)
csv    = $(subst $(space),$(comma),$(strip $(1)))

.PHONY: $(VERBS)
.DEFAULT_GOAL := help

# Names typed without a verb ('make nvim') are ambiguous — config or binary?
# Guide the user instead of silently doing nothing. When a verb IS present the
# names are its arguments, so we only intercept the verb-less case.
ifneq ($(NAMES),)
# Names collide with real files/dirs (e.g. nvim/), so force them phony — else
# Make sees the directory, says "up to date", and skips the recipe.
.PHONY: $(NAMES)
ifeq ($(filter $(VERBS),$(MAKECMDGOALS)),)
# No verb on the line — the names are orphaned. Explain and stop (Make aborts
# here, so the remaining names are never reached and need no rule).
$(firstword $(NAMES)):
	@printf "$(RED)Pick a verb:$(NC) 'make dot $(NAMES)' (configs) or 'make tool $(NAMES)' (binaries)\n" >&2; exit 2
else
# A verb is present — the names are its arguments; absorb them silently.
$(NAMES):
	@:
endif
endif

# ── Help ─────────────────────────────────────────────────────────────────────

help:
	@printf "$(BOLD)Usage: make <dot|tool> [name...] [HOST=user@host]$(NC)\n\n"
	@printf "  $(BOLD)dot$(NC)   [name...]   Link dotfile CONFIGS   (no name = all)\n"
	@printf "  $(BOLD)tool$(NC)  [name...]   Install vendor BINARIES (no name = all)\n"
	@printf "\n  Add $(BOLD)HOST=user@host$(NC) to either one to do it on a remote box over SSH.\n"
	@printf "  Omit HOST to do it locally. A full remote nvim is two steps:\n"
	@printf "    $(DIM)make dot nvim HOST=u@s && make tool nvim HOST=u@s$(NC)\n"
	@printf "\n$(BOLD)Portable binaries:$(NC)\n"
	@printf "  vendor                Download static binaries to vendor/linux-<arch>/\n"
	@printf "  clean                 Remove downloaded binaries (the vendor/ cache)\n"
	@printf "\n$(BOLD)Remove (mirror of dot/tool):$(NC)\n"
	@printf "  remove dot  [name...] [HOST=u@h]   Remove configs  (no name = all)\n"
	@printf "  remove tool [name...] [HOST=u@h]   Remove binaries (no name = all)\n"
	@printf "\n$(BOLD)Management:$(NC)\n"
	@printf "  status   [HOST=u@h]   Show what's installed, locally or on a server\n"
	@printf "\n$(DIM)Configs: bash vim nvim tmux git utils fonts inputrc joshuto yazi$(NC)\n"
	@printf "$(DIM)Tools:   fzf fd bat rg grex eza zoxide delta lazygit btop yazi ya joshuto 7z nvim vim tmux$(NC)\n"
	@printf "$(DIM)         (lazygit, grex are local-only — not pushed by 'make tool HOST=...')$(NC)\n"

# ── Configs (dot) ────────────────────────────────────────────────────────────
# When 'dot' follows 'remove' it's a sub-verb, not a command — stay inert and
# let the 'remove' recipe do the work.

dot:
ifeq ($(CMD),remove)
	@:
else ifeq ($(HOST),)
	@bash $(DOTFILES_DIR)/scripts/install.sh $(NAMES)
else
	@bash $(DOTFILES_DIR)/scripts/deploy.sh "$(HOST)" --configs --tool "$(if $(NAMES),$(call csv,$(NAMES)),all)"
endif

# ── Binaries (tool) ──────────────────────────────────────────────────────────

tool:
ifeq ($(CMD),remove)
	@:
else ifeq ($(HOST),)
	@bash $(DOTFILES_DIR)/scripts/install.sh --tool "$(if $(NAMES),$(call csv,$(NAMES)),all)"
else
	@bash $(DOTFILES_DIR)/scripts/deploy.sh "$(HOST)" --bins --tool "$(if $(NAMES),$(call csv,$(NAMES)),all)"
endif

# ── Remove (remove dot … / remove tool …) ────────────────────────────────────

remove:
ifeq ($(KIND),dot)
	@bash $(DOTFILES_DIR)/scripts/uninstall.sh --configs $(if $(HOST),--host $(HOST)) --tool "$(if $(NAMES),$(call csv,$(NAMES)),all)"
else ifeq ($(KIND),tool)
	@bash $(DOTFILES_DIR)/scripts/uninstall.sh --bins $(if $(HOST),--host $(HOST)) --tool "$(if $(NAMES),$(call csv,$(NAMES)),all)"
else
	@printf "$(RED)Usage:$(NC) make remove dot|tool [name...] [HOST=u@h]\n" >&2; exit 2
endif

# ── Vendor cache ─────────────────────────────────────────────────────────────

vendor:
	@bash $(DOTFILES_DIR)/scripts/bootstrap.sh

clean:
	@if [ -d "$(DOTFILES_DIR)/vendor" ]; then \
		rm -rf "$(DOTFILES_DIR)/vendor"; \
		printf "Removed vendor/ — run 'make vendor' to re-download.\n"; \
	else \
		printf "Nothing to clean (vendor/ does not exist).\n"; \
	fi

# ── Management ───────────────────────────────────────────────────────────────

status:
	@bash $(DOTFILES_DIR)/scripts/status.sh $(if $(HOST),--host $(HOST))
