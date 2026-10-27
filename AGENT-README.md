# AGENT-README

> Orientation for AI coding agents working in this repo. Human docs: README.md.

## Type

scripts+cli-tool

## Purpose

Helm deployment, rollback, and chart publishing driven by the shared `infra-config.yaml`: `helm-upgrade` (tier-ordered deploys with change detection), `helm-rollback`, `helm-publish` (package + push to OCI registry).

## Stack

Bash CLIs (`bin/`); prerequisites helm 3.x, kubectl, yq, jq; config from merged `infra-config.yaml` (tiers, env overlays, chart discovery, registries).

## Dev mode

```bash
make install    # three tools -> ~/.local/bin (make install-completions for shell completions)
helm-upgrade --list
helm-upgrade --include easy-peasy --dry-run
helm-rollback --env stage --include easy-peasy
helm-publish --list
```

## Ports / URLs

- none (library/CLI)

## Tests

```bash
make test   # no-op placeholder
```

## Gotchas

- Inventory/debug only — releases are git-driven (CI bumps chart tags, ArgoCD syncs); never hand-edit chart tags to ship.
- Deploy state is checksums in `.helm-state/{chart}.md5` after successful deploys (publish state too); `--force` bypasses change detection.
- `--env stage` uses release name `stage-<chart>`, layers `values-stage.yaml` over `values.yaml`, and includes only charts that have the overlay.
- Registry creds come from `.envrc.k8.dc` or env (`K8_HELM_REGISTRY_USER`/`_PASSWORD`, or `GITHUB_TOKEN`/`gh auth token` for GHCR).
- Tier order matters: tier N completes before N+1; charts outside tiers are still directly includable via `--include`.
