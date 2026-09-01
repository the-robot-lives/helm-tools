# helm-utils HOWTO

Task-oriented guides for the things you'll actually do with `helm-upgrade`, `helm-rollback`, and `helm-publish`. For *what it is* see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live* see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install the tools

**Goal:** get `helm-upgrade`, `helm-rollback`, `helm-publish` on your `$PATH`.
**Prereqs:** `helm` 3.x, `kubectl`, `yq`, `jq`; shared `k8-lib` (repo-root `make install-utilities` installs both).

1. From this package's root:
   ```bash
   make install
   ```
2. Or, from the monorepo root, install everything at once:
   ```bash
   make install-utilities
   ```

**Verify:** `helm-upgrade --help` prints usage and your configured tier list.
**Gotchas:**
- If `helm-upgrade` errors sourcing `common.sh`, `k8-lib` isn't installed — run `make install-utilities` from the repo root, or set `K8_LIB_DIR` to point at it.
- Scripts read `infra-config.yaml` relative to `$INFRA_ROOT` (default `$PWD`). Run these commands from the repo root, or set `INFRA_ROOT`, or pass `--config <file>`.

## How to: deploy/upgrade charts in tier order

**Goal:** roll out chart changes to the cluster in dependency-safe order, skipping anything unchanged.
**Prereqs:** installed tools (above), a valid `infra-config.yaml` with `tiers:` defined, `kubectl` context pointed at the target cluster.

1. See what would run before touching anything:
   ```bash
   helm-upgrade --dry-run
   ```
2. Deploy everything with pending changes:
   ```bash
   helm-upgrade
   ```
3. Narrow scope as needed:
   ```bash
   helm-upgrade --include backend,frontend   # only these charts
   helm-upgrade -n apps-ns                   # only this namespace
   helm-upgrade --tiers 0,1                  # only these tiers
   ```

**Verify:** the plan table printed before confirmation lists exactly the charts you expect; `kubectl get pods -n <ns>` shows updated pods after.
**Gotchas:**
- Nothing happens on a re-run of an unchanged chart — that's MD5 change detection, not a bug. Force it with `helm-upgrade --force`.
- Tier N always completes before tier N+1 starts; a failure halts the run there. See `helm-upgrade --help` for the resolved tier list in *your* config.

## How to: preview a deploy before applying it

**Goal:** see the actual manifest diff against the live cluster, not just "would deploy."
**Prereqs:** as above; a diff viewer (`code`, `kdiff3`, `opendiff`, `meld`, or `terminal`) — default is `$K8_DIFF_VIEWER` or `code`.

1. Diff only, no dry-run gate needed:
   ```bash
   helm-upgrade --preview
   ```
2. Diff + apply in one pass (confirm before each apply):
   ```bash
   helm-upgrade --env stage --include frontend --preview
   ```
3. Pick a different viewer:
   ```bash
   helm-upgrade --preview-tool terminal
   ```

**Verify:** the diff viewer opens showing live-vs-proposed manifest; empty diff means nothing to apply.
**Gotchas:** if `$K8_DIFF_VIEWER`/`code` isn't installed, pass `--preview-tool terminal` to fall back to a plain text diff.

## How to: deploy to a non-production environment (stage/dev)

Deploy an overlay environment with its own release names and values, isolated from production.
→ *See [howto/deploy-environment-overlay.md](howto/deploy-environment-overlay.md)*

## How to: roll back a bad deploy

**Goal:** undo one or more releases, in reverse tier order, without hand-picking `helm rollback` revisions yourself.
**Prereqs:** installed tools; releases were deployed via `helm-upgrade` (or at least exist as Helm releases).

1. Let it find the problem for you:
   ```bash
   helm-rollback              # auto-detects unhealthy pods & recent deploys
   ```
2. Or target specific charts (interactive revision picker):
   ```bash
   helm-rollback --include backend,frontend
   ```
3. Or undo everything deployed in a recent window:
   ```bash
   helm-rollback --back-to 30m --dry-run   # preview first
   helm-rollback --back-to 30m             # then execute
   ```

**Verify:** `helm-rollback --dry-run` on the same args shows an empty/no-op plan afterward.
**Gotchas:**
- Rollback order is the *reverse* of deploy order (highest tier first) — app layers unwind before the infra they depend on.
- `--back-to` needs a duration like `15m`, `1h`, `2h30m` — always `--dry-run` a time-window rollback first, it can span more releases than you expect.

## How to: publish a chart to the OCI registry

**Goal:** package and push a Helm chart, optionally bumping its version.
**Prereqs:** `K8_HELM_OCI_REGISTRY` + `K8_HELM_REGISTRY_USER` set (`.envrc.k8.dc` or env); auth resolves `K8_HELM_REGISTRY_PASSWORD` → `GITHUB_TOKEN` → `gh auth token`.

1. See what's discoverable first:
   ```bash
   helm-publish --list
   ```
2. Publish the chart for your current directory, or name one:
   ```bash
   helm-publish
   helm-publish backend
   ```
3. Bump a version and dry-run the package step:
   ```bash
   helm-publish backend --bump patch --dry-run
   ```

**Verify:** `helm-publish --list` shows the new version pushed; `.helm-state/` records what's been published.
**Gotchas:**
- No registry env vars set → `die "K8_HELM_OCI_REGISTRY is not set..."`; set them in `.envrc.k8.dc`, not just your shell, so they persist.
- Re-publishing an existing version is refused unless you pass `--force`.

## How to: add a new chart to the deploy pipeline

Wire a chart into `helm-upgrade`/`helm-rollback` discovery, and place it in the right tier and namespace.
→ *See [howto/add-chart-to-pipeline.md](howto/add-chart-to-pipeline.md)*

## How to: keep a stateful chart's live values from being wiped

**Goal:** stop `helm-upgrade`'s default `--reset-values` from discarding runtime/generated values (e.g. Weaviate/Qdrant cluster keys) that only exist in the live release, not `values.yaml`.
**Prereqs:** knowing which charts carry such values.

1. Add the chart name to `helm_preserve_values` in `infra-config.yaml`:
   ```yaml
   helm_preserve_values:
     - weaviate
     - qdrant
   ```
2. Re-run the upgrade — it now uses `--reuse-values` instead of the default `--reset-values`:
   ```bash
   helm-upgrade --include weaviate
   ```

**Verify:** the upgrade log prints `preserving runtime values (--reuse-values; in helm_preserve_values)` for that chart.
**Gotchas:** this is an *opt-out* list — every chart not listed gets `--reset-values`, meaning `values.yaml` silently wins over anything set by hand with `helm upgrade --set` in the past. If a chart's live config keeps reverting to `values.yaml`, that's this default working as intended, not a bug.

## How to: resolve a server-side-apply ownership conflict

**Goal:** get past a `helm upgrade` failure caused by another controller (or a prior non-Helm `kubectl apply`) owning fields Helm now wants to manage.
**Prereqs:** `kubectl` access to the namespace in question.

1. Just re-run and accept the prompt when it appears:
   ```bash
   helm-upgrade --include <chart>
   # "field ownership conflict — attempting auto-fix" → confirm
   ```
2. Or skip the prompt entirely (useful in CI / repeat offenders):
   ```bash
   helm-upgrade --include <chart> --force-conflicts
   ```

**Verify:** log shows `Transferred ownership: <resource>` followed by a successful retry.
**Gotchas:** if it warns `Could not auto-fix ownership — no matching resources found`, the conflict isn't a field-ownership issue — inspect the underlying `helm upgrade` error directly (`kubectl describe` the resource named in the error).
