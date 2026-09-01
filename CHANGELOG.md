# Changelog — utilities/k8/helm-utils

## [Unreleased]
- No changes since the last milestone.

## [m4-npl-docs] — 2026-07-16 — tag: `utilities-k8-helm-utils/m4-npl-docs`
Milestone summary: brought the package's `docs/` in line with the monorepo's NPL doc conventions, refreshing PROJ-ARCH and adding PROJ-LAYOUT.

### Changed
- Rewrote `docs/PROJ-ARCH.md` and `PROJ-ARCH.summary.md` for accuracy
### Added
- `docs/PROJ-LAYOUT.md` and `PROJ-LAYOUT.summary.md`

## [m3-reset-values-default] — 2026-06-25 — tag: `utilities-k8-helm-utils/m3-reset-values-default`
Milestone summary: fixed a recurring deploy footgun where bumped image tags in `values.yaml` were silently ignored because `helm upgrade` reuses prior release values.

### Changed
- `helm-upgrade` now passes `--reset-values` by default, making `values.yaml` the source of truth
### Added
- `helm_preserve_values` opt-out list (`.infra-config.yaml`) for stateful charts (e.g. weaviate, qdrant) whose live values include runtime/generated data not present in `values.yaml`; those charts get `--reuse-values` instead

## [m2-config-and-cleanup] — 2026-06-14 — tag: `utilities-k8-helm-utils/m2-config-and-cleanup`
Milestone summary: post-import housekeeping — ignore rules, doc touch-ups, and a substantial `helm-upgrade` refactor.

### Changed
- Added `.gitignore`; minor `docs/PROJ-ARCH.md` corrections
- Reworked `bin/helm-upgrade` internals (34 insertions / 18 deletions across flag handling and upgrade flow)

## [m1-subtree-import] — 2026-06-13 — tag: `utilities-k8-helm-utils/m1-subtree-import`
Milestone summary: initial import of the helm-utils package into the monorepo as a git subtree, establishing the full toolset in one commit.

### Added
- `bin/helm-upgrade` — chart upgrade/deploy driver (tier, namespace, dry-run, diff-preview support)
- `bin/helm-publish` — chart packaging/publish workflow
- `bin/helm-rollback` — release rollback workflow
- `Makefile`, `README.md`, `docs/PROJ-ARCH.md`, `docs/PROJ-ARCH.summary.md`
