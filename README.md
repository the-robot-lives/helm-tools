# helm-tools — Helm Upgrade, Rollback & Publish

Tiered Helm deployment orchestrator with change detection, environment overlays, manifest preview, and OCI registry publishing.

## Installation

```bash
make install    # Installs helm-upgrade, helm-rollback, helm-publish to ~/.local/bin
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

## Helm Publish (OCI Registry)

Package and push Helm charts to an OCI registry (e.g., ghcr.io).

### Configuration

Set in `config.env`:

```bash
K8_HELM_OCI_REGISTRY="oci://ghcr.io/your-org/helm-charts"
K8_HELM_REGISTRY_HOST="ghcr.io"
K8_HELM_REGISTRY_USER="your-org"
```

Set `GITHUB_TOKEN` (or `K8_HELM_REGISTRY_PASSWORD`) in your environment.

### Chart Discovery

Charts are discovered from `project.yaml` `helm.charts[]` entries:

```yaml
# Flat project
helm:
  charts:
    - name: my-chart
      path: helm/my-chart

# Composite project (incubator pattern)
projects:
  - domain: example.com
    helm:
      charts:
        - name: my-chart
          path: helm/my-chart
          registry: oci://ghcr.io/alt-org/charts  # optional override
```

### Usage

```bash
helm-publish --list                     # Show all discoverable charts
helm-publish codefresh                  # Publish specific chart (partial name ok)
helm-publish --pick                     # Interactive multi-select
helm-publish --all                      # Publish all charts
helm-publish --bump patch               # Bump version before publishing
helm-publish --dry-run                  # Package only, don't push
helm-publish --force                    # Overwrite existing version
```
