# Dotfiles Makefile — a thin front end. The work is in scripts/, and what the
# repo contains (components, tools, where they go) is one table: scripts/lib.sh.
#
# Two verbs, one axis. 'dot' = configs, 'tool' = portable binaries.
# Add HOST=user@host to do the same thing on a remote box over SSH.
#
#   make dot                  link the default configs locally
#   make dot nvim tmux        link just those
#   make dot nvim HOST=u@s    push the nvim config to a server
#   make tool                 install every vendored binary locally
#   make tool fzf bat         install just those
#   make tool nvim HOST=u@s   push the nvim binary to a server
#
# A full remote nvim is:  make tool nvim HOST=u@s && make dot nvim HOST=u@s

SCRIPTS := $(CURDIR)/scripts

# Some site logins export HOST=<this machine's own hostname> by default (seen
# on the X2Go session hosts this repo runs on). Without this guard a bare
# 'make dot' would SSH-deploy to itself instead of installing locally. A HOST
# naming this machine means "local".
LOCAL_HOSTNAMES := $(shell hostname 2>/dev/null) $(shell hostname -s 2>/dev/null)
ifneq ($(filter $(lastword $(subst @, ,$(HOST))),$(LOCAL_HOSTNAMES)),)
override HOST :=
endif
AT_HOST := $(if $(HOST),--host $(HOST))

BOLD := \033[1m
DIM  := \033[2m
RED  := \033[0;31m
NC   := \033[0m

# Verbs are the real targets. Any other word on the command line is a NAME
# (a component or a tool) handed to the script.
VERBS := help dot tool remove vendor clean status
NAMES := $(filter-out $(VERBS),$(MAKECMDGOALS))
CMD   := $(firstword $(MAKECMDGOALS))
# 'remove' takes a sub-verb: 'make remove dot nvim' / 'make remove tool nvim'.
KIND  := $(firstword $(filter dot tool,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))))

.PHONY: $(VERBS)
.DEFAULT_GOAL := help

ifneq ($(NAMES),)
# Names collide with real dirs (nvim/), so force them phony — else Make sees
# the directory, says "up to date", and skips the recipe.
.PHONY: $(NAMES)
ifeq ($(filter $(VERBS),$(MAKECMDGOALS)),)
# 'make nvim' — config or binary? Say so and stop (Make aborts on the first
# name, so the rest need no rule).
$(firstword $(NAMES)):
	@printf "$(RED)Pick a verb:$(NC) 'make dot $(NAMES)' (configs) or 'make tool $(NAMES)' (binaries)\n" >&2; exit 2
else
# A verb is present — the names are its arguments; absorb them silently.
$(NAMES):
	@:
endif
endif

help:
	@printf "$(BOLD)Usage: make <dot|tool> [name...] [HOST=user@host]$(NC)\n\n"
	@printf "  $(BOLD)dot$(NC)   [name...]   Link dotfile CONFIGS    (no name = the default set)\n"
	@printf "  $(BOLD)tool$(NC)  [name...]   Install vendor BINARIES (no name = every vendored one)\n"
	@printf "\n  Add $(BOLD)HOST=user@host$(NC) to do it on a remote box over SSH. A full remote nvim:\n"
	@printf "    $(DIM)make tool nvim HOST=u@s && make dot nvim HOST=u@s$(NC)\n"
	@printf "\n$(BOLD)Portable binaries:$(NC)\n"
	@printf "  vendor [name...]      Download static binaries to vendor/linux-<arch>/  (FORCE=1 refreshes)\n"
	@printf "  clean                 Remove the vendor/ cache\n"
	@printf "\n$(BOLD)Remove (mirror of dot/tool):$(NC)\n"
	@printf "  remove dot  [name...] [HOST=u@h]   Remove configs  (no name = all of ours)\n"
	@printf "  remove tool [name...] [HOST=u@h]   Remove binaries (no name = all)\n"
	@printf "\n$(BOLD)Management:$(NC)\n"
	@printf "  status   [HOST=u@h]   Show what's installed, locally or on a server\n\n"
	@printf "$(DIM)"; bash $(SCRIPTS)/lib.sh; printf "(hypr, vim, aerc, lazyvim are opt-in by name; grex stays local)$(NC)\n"

# When 'dot'/'tool' follows 'remove' it's a sub-verb, not a command: stay inert.
dot:
ifeq ($(CMD),remove)
	@:
else
	@bash $(SCRIPTS)/$(if $(HOST),deploy,install).sh $(AT_HOST) --configs $(NAMES)
endif

tool:
ifeq ($(CMD),remove)
	@:
else
	@bash $(SCRIPTS)/$(if $(HOST),deploy,install).sh $(AT_HOST) --bins $(NAMES)
endif

remove:
ifeq ($(KIND),dot)
	@bash $(SCRIPTS)/uninstall.sh $(AT_HOST) --configs $(NAMES)
else ifeq ($(KIND),tool)
	@bash $(SCRIPTS)/uninstall.sh $(AT_HOST) --bins $(NAMES)
else
	@printf "$(RED)Usage:$(NC) make remove dot|tool [name...] [HOST=u@h]\n" >&2; exit 2
endif

vendor:
	@bash $(SCRIPTS)/bootstrap.sh $(NAMES)

clean:
	@if [ -d "$(CURDIR)/vendor" ]; then rm -rf "$(CURDIR)/vendor" && printf "Removed vendor/ — 'make vendor' re-downloads.\n"; \
	else printf "Nothing to clean (no vendor/).\n"; fi

status:
	@bash $(SCRIPTS)/status.sh $(AT_HOST)
