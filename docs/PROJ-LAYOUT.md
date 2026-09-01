# Project Layout

Terminal utility package: Helm deployment tooling (upgrade, rollback, OCI publish) for the Noizu k8s platform. Installed to `~/.local/bin` via `make install`. All three scripts source the shared shell library from `$K8_LIB_DIR` (default `~/.local/share/k8-lib`) and read the merged `infra-config.yaml`.

```
helm-utils/
├── bin/                        # Executable bash utilities (installed to ~/.local/bin)
│   ├── helm-upgrade            #   Dependency-ordered (tiered) helm upgrade with MD5 change detection; namespace/include/exclude filters, interactive toggle UI
│   ├── helm-rollback           #   Dependency-aware rollback in reverse tier order; by target, revision, unhealthy pods, or time window (--back-to)
│   └── helm-publish            #   Package + push Helm charts to an OCI registry; auto-detect, --pick, --all, --bump, --dry-run
├── completions/                # Shell completions (installed by `make install-completions`)
│   ├── helm-*.bash             #   bash-completion scripts (one per tool)
│   └── _helm-*                 #   zsh completion functions
├── docs/                       # Documentation
│   ├── PROJ-ARCH.md            #   Architecture reference
│   ├── PROJ-ARCH.summary.md    #   Architecture quick-reference companion
│   ├── PROJ-LAYOUT.md          #   This file
│   ├── PROJ-LAYOUT.summary.md  #   Layout quick-reference companion
│   ├── PROJ-HOWTO.md           #   Task-oriented how-to index (+ .summary.md companion)
│   ├── PROJ-FAQ.md             #   Frequently asked questions (+ .summary.md companion)
│   └── howto/                  #   Step-by-step task guides
│       ├── add-chart-to-pipeline.md      # Wire a new chart into upgrade/publish
│       └── deploy-environment-overlay.md # Non-prod env deploys via values-<env>.yaml
├── .gitignore                  # Ignores editor swap files, .DS_Store, .env, .envrc.local
├── CHANGELOG.md                # Release history
├── Makefile                    # `make install` → bin/* to $INSTALL_DIR (default ~/.local/bin) + completions; compile/test are no-ops
├── README.md                   # Start here — install, prerequisites (helm 3.x, kubectl, yq, jq), config sources, usage
└── merge-notes.md              # Working notes from a prior merge (historical, not user-facing)
```

Runtime state (not in repo): tools write chart checksums and publish markers to `.helm-state/` in the invoking repo's working directory — safe to delete; recreated on next deploy/publish.

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `~/.local/share/k8-lib` | Shared shell library must be installed (repo-root `make install-utilities`); override location with `K8_LIB_DIR` |
| `.envrc.k8.dc` (repo root) | Registry credentials for `helm-publish` (or via environment variables) |
| `infra-config.yaml` | Merged config read by all three tools for chart discovery, tiers, and namespaces |
