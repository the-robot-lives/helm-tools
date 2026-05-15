# helm-tools — Helm Upgrade & Rollback

Tiered Helm deployment orchestrator with change detection, environment overlays, and manifest preview.

## Installation

```bash
make install    # Installs helm-upgrade, helm-rollback to ~/.local/bin
```

## Prerequisites

- `helm` 3.x
- `kubectl` with cluster access
- `yq` for YAML parsing
- `jq` for JSON parsing

## Configuration

### Required (at project root)

**tiers.yaml** — Deployment ordering. Tier N completes before tier N+1 starts:

```yaml
tiers:
  - name: "Infrastructure"
    charts:
      - infisical-core
  - name: "Applications"
    charts:
      - apps-infra
```

### Optional (at project root)

**namespaces.conf** — Chart-to-namespace overrides:

```
apps-infra=apps-ns
```

**timeout-overrides.conf** — Per-chart timeout (default: 5m):

```
apps-infra=10m
```

**.helm-state/upgrade-policy.yaml** — Confirmation rules for risky changes (auto-created on first use).

### project.yaml Integration

Charts are discovered from `project.yaml` `helm.*` fields:

```yaml
helm:
  release: apps-infra
  namespace: apps-ns
  tier: 3
  timeout: "10m"
  path: apps-infra/
```

## Usage

```bash
helm-upgrade --list                     # Show discovered charts with tier/namespace
helm-upgrade --dry-run                  # Preview full upgrade
helm-upgrade --include apps-infra       # Upgrade single chart
helm-upgrade --tier 0                   # Deploy only tier 0
helm-upgrade --interactive              # Prompt before each chart
helm-upgrade --preview                  # Diff live vs proposed manifests
helm-upgrade --env stage                # Use staging environment overlay
helm-upgrade --force                    # Skip change detection, upgrade all

helm-rollback apps-infra                # Rollback to previous revision
helm-rollback apps-infra 3              # Rollback to specific revision
```

## Change Detection

After each successful upgrade, an MD5 checksum of the chart is stored in `.helm-state/{chart}.md5`. Subsequent runs skip unchanged charts unless `--force` is used.

## Environment Overlays

With `--env stage`, the orchestrator:
1. Prefixes release names: `stage-apps-infra`
2. Loads `values-stage.yaml` alongside `values.yaml`
3. Resolves namespace from the overlay's `global.namespace`
