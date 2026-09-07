# helm-utils

**Repo:** https://github.com/the-robot-lives/helm-tools

Helm deployment, rollback, and chart publishing tools driven by the shared `infra-config.yaml`.

## What

Three commands installed to `~/.local/bin`:

| Command | Purpose |
|---------|---------|
| `helm-upgrade` | Deploy charts in tier order with change detection (skips unchanged charts) |
| `helm-rollback` | Roll back by explicit target, revision, unhealthy pods, or recent deploy window |
| `helm-publish` | Package and push configured charts to an OCI registry |

## Why

Manually orchestrating dozens of Helm charts across namespaces and environments is error-prone. helm-utils provides tiered ordering (tier N completes before N+1), checksum-based change detection, environment overlays, and declarative chart discovery — all from one merged config, so deploys are reproducible and reviewable.

## Getting Started

Prerequisites: `helm` 3.x, `kubectl`, `yq`, `jq`.

```bash
make install    # → ~/.local/bin (make install-completions for shell completions)
```

```bash
helm-upgrade --list | --dry-run | --interactive | --preview
helm-upgrade --include easy-peasy | --exclude ... | --tier 0 | --tiers 0,1
helm-upgrade --env stage | --force

helm-rollback --include easy-peasy
helm-rollback --env stage --include easy-peasy
helm-rollback --back-to 30m

helm-publish --list | --all | --pick | --dry-run | --force
helm-publish easy-peasy
helm-publish --bump patch
```

## How It Works

- **Config**: everything reads the merged `infra-config.yaml`; registry creds come from `.envrc.k8.dc` or env (`K8_HELM_REGISTRY_USER`/`_PASSWORD`, or `GITHUB_TOKEN`/`gh auth token` for GHCR).
- **Chart discovery** (upgrade/rollback): `paths.helm_dir`, `helm_scan_dirs`, and `chart_path_overrides` (keys act as friendly aliases).
- **Publish discovery**: `project.helm.charts[]` or composite `project.projects[].helm.charts[]` under `paths.projects_dir`; default registry from `helm.oci_registry` / `registry_host`, per-chart `registry:` override.
- **Tiers**: `tiers[].charts` with `namespace_overrides` (beats values.yaml detection) and `timeout_overrides`; charts outside tiers are still directly includable.
- **Env overlays**: `--env stage` uses release name `stage-<chart>`, layers `values-stage.yaml` over `values.yaml`, includes only charts that have the overlay, and reads namespace from it.
- **State**: checksums in `.helm-state/{chart}.md5` after successful deploys; publish state also lives under `.helm-state/` so re-pushes are detected. `--force` bypasses.

Full config examples and schema: `docs/` (PROJ-ARCH, PROJ-SCHEMA, PROJ-HOWTO).

## Repo Layout

- `bin/` — the three command entrypoints
- `completions/` — shell completions
- `docs/` — architecture, schema, howto docs
