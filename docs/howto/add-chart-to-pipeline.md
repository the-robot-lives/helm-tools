## How to: add a new chart to the deploy pipeline

**Goal:** make `helm-upgrade` and `helm-rollback` discover a chart, and deploy it in the right order relative to everything else.
**Prereqs:** the chart directory exists (with a `Chart.yaml`), either under `paths.helm_dir` or somewhere else in the repo.

1. **Standard location** — if the chart lives under the configured `helm_dir` (default `helm/`), it's already discoverable; skip to step 3.

2. **Non-standard location** — add it via `chart_path_overrides` (this also lets you give it a friendly alias):
   ```yaml
   chart_path_overrides:
     easy-peasy: random/testing/random/not-helm-dir/easy-pasy
   ```
   Or add a whole extra directory to the scan list:
   ```yaml
   helm_scan_dirs:
     - helm/platform
     - helm/apps
   ```

3. Assign it to a tier so it deploys in the correct dependency order:
   ```yaml
   tiers:
     - name: Applications
       tier: 3
       charts:
         - easy-peasy
   ```

4. (Optional) override namespace or timeout if the chart's own `values.yaml` doesn't already say the right thing:
   ```yaml
   namespace_overrides:
     easy-peasy: apps-ns
   timeout_overrides:
     easy-peasy: 15m
   ```

**Verify:**
```bash
helm-upgrade --include easy-peasy --dry-run
```
The chart shows up in the plan table with the expected namespace and tier.
**Gotchas:**
- A chart absent from `tiers:` can still be targeted directly with `--include`, but it won't be part of the default (no-flag) run — add it to a tier if it should deploy automatically.
- `chart_path_overrides` keys are the name you use everywhere else (`--include`, `tiers:`, `namespace_overrides`) — pick the alias once and keep it consistent.
- If `helm-rollback --include easy-peasy` says "Unknown argument," the chart isn't in any tier *and* its path isn't under `helm/` — it needs a `chart_path_overrides` entry or to be added to a tier.

See also: [PROJ-HOWTO.md](../PROJ-HOWTO.md)
