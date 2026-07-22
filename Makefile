INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: compile test install install-completions

compile:
	@true

test:
	@true

install:
	@mkdir -p $(INSTALL_DIR)
	@for f in bin/helm-upgrade bin/helm-rollback bin/helm-publish; do \
		install -m 755 "$$f" "$(INSTALL_DIR)/$$(basename $$f)"; \
		echo "✓ Installed $$(basename $$f)"; \
	done
	@$(MAKE) install-completions

install-completions:
	@DATA_DIR="$${XDG_DATA_HOME:-$$HOME/.local/share}"; \
	BASH_DIR="$$DATA_DIR/bash-completion/completions"; \
	ZSH_DIR="$$DATA_DIR/zsh/site-functions"; \
	if ! mkdir -p "$$BASH_DIR" "$$ZSH_DIR" 2>/dev/null; then \
		echo "helm-utils: cannot write completion dirs; skipping."; \
		exit 0; \
	fi; \
	cp completions/helm-upgrade.bash "$$BASH_DIR/helm-upgrade"; \
	cp completions/helm-rollback.bash "$$BASH_DIR/helm-rollback"; \
	cp completions/helm-publish.bash "$$BASH_DIR/helm-publish"; \
	cp completions/_helm-upgrade "$$ZSH_DIR/_helm-upgrade"; \
	cp completions/_helm-rollback "$$ZSH_DIR/_helm-rollback"; \
	cp completions/_helm-publish "$$ZSH_DIR/_helm-publish"; \
	echo "helm-utils: completions installed (bash-completion + zsh)"; \
	if ! grep -qs "zsh/site-functions" "$$HOME/.zshrc" 2>/dev/null; then \
		echo "helm-utils: zsh users — add to .zshrc before compinit:"; \
		echo "  fpath=($$ZSH_DIR \$$fpath)"; \
	fi
