# helm-utils FAQ

Anticipated why/when/compared-to-what questions. For *how* see [PROJ-HOWTO.md](PROJ-HOWTO.md); for *what it is* see [PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use `helm-upgrade` instead of just calling `helm upgrade --install` myself?

Because a hand-rolled loop over charts gives you none of tier ordering, change detection, or namespace/timeout resolution for free, and you will eventually deploy tier 3 before tier 0 finishes or re-push an unchanged chart by habit. `helm-upgrade` reads `infra-config.yaml` once and gives you: dependency-safe tier execution (halts the whole run on a tier failure instead of racing ahead), MD5-based skip-unchanged so re-running is cheap, and per-chart namespace/timeout overrides so you stop passing `-n` and `--timeout` by memory. The honest trade-off: for a single chart in a directory with no tiers/namespace concerns, plain `helm upgrade --install` is fewer moving parts and easier to explain to someone unfamiliar with this repo's config.
→ *See [PROJ-HOWTO.md#how-to-deployupgrade-charts-in-tier-order](PROJ-HOWTO.md#how-to-deployupgrade-charts-in-tier-order).*

### Why does `helm-upgrade` default to `--reset-values` instead of Helm's own `--reuse-values` behavior?

Because Helm's default (`--reuse-values`) silently keeps whatever was set with a one-off `--set` months ago, so a bumped image tag in `values.yaml` gets ignored on the next upgrade — a real recurring deploy footgun here (see the `m3-reset-values-default` changelog entry). Making `values.yaml` the enforced source of truth means what's committed is what's live. The catch: charts that carry live-only state not present in `values.yaml` (Weaviate/Qdrant cluster keys, generated secrets) get that state wiped unless you opt them out.
→ *See [PROJ-HOWTO.md#how-to-keep-a-stateful-charts-live-values-from-being-wiped](PROJ-HOWTO.md#how-to-keep-a-stateful-charts-live-values-from-being-wiped).*

### Why is `helm-publish`'s chart discovery separate from `helm-upgrade`/`helm-rollback`'s?

Because "what's deployable" and "what's publishable" are different questions answered from different config sections on purpose — `paths.helm_dir`/`helm_scan_dirs`/`chart_path_overrides` for deploy targets vs. `project.helm.charts[]` for publish targets. A chart can be deployed from a local checkout without ever being published (internal-only), or published without being part of this cluster's deploy plan (a chart for another team/repo). Collapsing the two into one discovery path would force every deployable chart to also declare a registry, which isn't true here.

### Why does `--env` create a whole separate release (`stage-frontend`) instead of just pointing the same release at a different namespace?

Because a same-named release deployed twice (prod namespace vs stage namespace) would collide in Helm's own release history and in this tool's MD5/rollback checksum cache, which is keyed by release name — a `--force` or rollback aimed at prod would risk touching stage's cached state too. Prefixing the release name (`{ENV}-{chart}`) gives stage and prod fully independent Helm history, checksums, and rollback plans, at the cost of the release name no longer matching the chart name 1:1 (tooling and `helm list` output need to account for the prefix).
→ *See [PROJ-HOWTO.md#how-to-deploy-to-a-non-production-environment-stagedev](PROJ-HOWTO.md#how-to-deploy-to-a-non-production-environment-stagedev).*

## Fit

### When should I use `helm_scan_dirs` vs. `chart_path_overrides` to make a chart discoverable?

Use `helm_scan_dirs` when the chart's directory name already matches (or should become) its chart name and it just lives outside the default `helm_dir` tree — it's a zero-config "also look here" scan. Use `chart_path_overrides` when you need an alias that differs from the directory name, or the chart lives somewhere genuinely irregular (a path outside any scanned tree, e.g. `random/testing/...`) — it's an explicit one-to-one mapping, not a scan. If a chart is discoverable both ways, `chart_path_overrides` wins as the more specific declaration.
→ *See [howto/add-chart-to-pipeline.md](howto/add-chart-to-pipeline.md).*

### When is this the wrong tool for a deploy?

When you need GitOps-style continuous reconciliation (ArgoCD/Flux watching a repo and self-healing drift) rather than an operator-triggered push. `helm-upgrade` runs when a human or `deploy-service` invokes it — nothing re-applies your chart if someone hand-edits a Deployment afterward. If you need drift detection/auto-heal as a first-class property, these scripts are not that; they're a scripted, tier-aware wrapper over imperative `helm upgrade`.

### When should I skip the tier config entirely and just target one chart?

When you're iterating on a single chart in dev and don't care about dependency ordering — `helm-upgrade --include <chart>` works even for charts not listed in any `tiers:` entry, as long as they're discoverable via `paths.helm_dir`/`helm_scan_dirs`/`chart_path_overrides`. Tiers matter for full-environment rollouts where order-of-operations is load-bearing (secrets before consumers, infra before apps); they're overhead for a one-chart dev loop.

## Comparison

### How does `helm-rollback` differ from plain `helm rollback <release> <revision>`?

`helm rollback` needs you to already know the release name and target revision; `helm-rollback` finds both for you — auto-detecting unhealthy pods and recent deploys, or accepting a time window (`--back-to 30m`) — and, critically, executes in *reverse* tier order so app layers unwind before the infrastructure layers they depend on. Plain `helm rollback` has no concept of tiers at all: rolling back an infra chart out of order can break every app layer above it that this tool would have sequenced correctly.
→ *See [PROJ-HOWTO.md#how-to-roll-back-a-bad-deploy](PROJ-HOWTO.md#how-to-roll-back-a-bad-deploy).*

### How does this differ from just scripting `helm push` for `helm-publish`?

`helm-publish` adds target discovery (config-driven or CWD auto-detect/`--pick`/`--all`), version bumping (`--bump patch|minor|major`), duplicate-publish protection (refuses to re-publish an existing version without `--force`), and credential fallback (`K8_HELM_REGISTRY_PASSWORD` → `GITHUB_TOKEN` → `gh auth token`) so you're not hand-maintaining auth per environment. A raw `helm push` script does the OCI push and nothing else — you own version bumping, duplicate checks, and auth resolution yourself.

### How does `helm-upgrade --preview` differ from `--dry-run`?

`--dry-run` tells you *which charts* would be touched (the plan table) without applying anything — no cluster round-trip beyond change detection. `--preview` actually renders the chart and diffs it against the live cluster's manifest, so you see the *field-level* changes, not just "chart X is due for an upgrade." They compose: `--dry-run --preview` shows the diff only, while `--preview` alone shows the diff and then proceeds to apply after confirmation. If you only need to know what's stale, `--dry-run` is cheaper; if you need to know exactly what will change on the wire, use `--preview`.
→ *See [PROJ-HOWTO.md#how-to-preview-a-deploy-before-applying-it](PROJ-HOWTO.md#how-to-preview-a-deploy-before-applying-it).*

## Capability

### Can I deploy a chart that lives outside the standard `helm/` tree?

Yes — `chart_path_overrides` maps a chart name to any path, including outside `paths.helm_dir` entirely, and the alias becomes usable directly (`helm-upgrade --include <alias>`). This is by design for one-off or non-standard chart locations; it does not require the chart to also be in `helm_scan_dirs`.

### Does `helm-publish` also own the chart source (Chart.yaml, templates)?

No. These three scripts orchestrate charts that live in the upstream `noizu-infra` repo (`kubernetes/helm/`) — this package builds, deploys, rolls back, and packages them, but the chart definitions themselves are edited elsewhere. If you're looking to author or modify a chart's templates, that's a different repo.

## Caveats

### What happens if I re-run `helm-upgrade` and nothing deploys?

That's the MD5 change-detection working as intended, not a stall or a bug — an unchanged chart is skipped by design so repeated runs are cheap. If you need to force a redeploy with no config changes (e.g. to pick up a mutable image tag), pass `--force`.

### If one chart fails mid-tier, do the other charts already running in that same tier get cut off?

No — charts within a tier are launched in parallel and all of them are allowed to finish (success or failure) before the tier gate is evaluated; only *subsequent* tiers are skipped once any chart in the current tier failed. So a tier with three charts where one fails still lets the other two complete normally — you just won't get tier N+1 afterward, and the skipped tier's charts are reported as "skipped — upstream tier failed" rather than silently omitted.
→ *See [PROJ-HOWTO.md#how-to-deployupgrade-charts-in-tier-order](PROJ-HOWTO.md#how-to-deployupgrade-charts-in-tier-order).*

### What's the risk in `--force-conflicts` on a server-side-apply ownership error?

It transfers field ownership away from whatever controller (or prior `kubectl apply`) currently holds those fields, without asking per-field — appropriate when you know Helm should own them going forward, risky if another controller is actively reconciling the same fields and will fight Helm for them afterward. Prefer the interactive per-conflict prompt (the default) unless you're scripting this for CI.
→ *See [PROJ-HOWTO.md#how-to-resolve-a-server-side-apply-ownership-conflict](PROJ-HOWTO.md#how-to-resolve-a-server-side-apply-ownership-conflict).*

## Trust

### Where do `helm-publish`'s registry credentials come from, and are they ever logged?

From `.envrc.k8.dc` or environment variables, resolved in order `K8_HELM_REGISTRY_PASSWORD` → `GITHUB_TOKEN` → `gh auth token` — never hardcoded in the scripts or `infra-config.yaml`. Set them in `.envrc.k8.dc` (not just an ad hoc shell export) so they persist across sessions; the scripts don't echo resolved secret values to stdout during normal operation.
