# helm-utils Architecture Summary

Terminal utility package for Helm chart lifecycle on the Noizu k8s platform: tiered upgrades, reverse-tier rollbacks, OCI publishing. Standalone Bash scripts installed to `~/.local/bin`; all source shared k8-lib from `$K8_LIB_DIR` (default `~/.local/share/k8-lib`) and read the merged `infra-config.yaml` (overridable via `--config`, pre-parsed before library load).

## Components

- **bin/helm-upgrade** — tier-ordered upgrade with MD5 change detection, env overlays, interactive selection, manifest preview, SSA conflict auto-fix.
- **bin/helm-rollback** — reverse-tier rollback via explicit include, unhealthy-pod auto-detect, or time-window `--back-to`.
- **bin/helm-publish** — package + push charts to OCI registries; flat or composite publish targets; auth from `.envrc.k8.dc`/env/`gh auth token`.
- **$K8_LIB_DIR/bin** — shared k8-lib (common.sh, helm-common.sh, helm-publish-config.sh, assist.sh).
- **.helm-state/** — per-release checksums and publish state under `$INFRA_ROOT`.

## Configuration

Deploy tools discover charts from `paths.helm_dir` / `helm_scan_dirs` / `chart_path_overrides` and plan from `tiers[]` with namespace/timeout overrides; helm-publish discovers targets from `project(.projects[]).helm.charts[]`. `--env <name>` layers `values-<env>.yaml` and prefixes release names.

## Key Decisions

- Per-release MD5 checksums avoid redundant releases; env releases track independently.
- Tier ordering: infra first on upgrade, reversed on rollback.
- k8-lib resolved via `$K8_LIB_DIR`, not relative paths — scripts run from anywhere.
- Dependencies limited to Bash, helm 3.x, kubectl, jq, yq.

## Ecosystem

One of the Noizu monorepo `utilities/`; consumed by `deploy-service` / `docker-push --release` flows against the repo-root `.infra-config.yaml`; charts live in the upstream noizu-infra repo.
