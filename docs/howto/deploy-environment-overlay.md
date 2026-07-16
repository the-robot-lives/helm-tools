## How to: deploy to a non-production environment (stage/dev)

**Goal:** deploy an overlay environment (stage/dev/prod-alt) with its own release names and values, isolated from the production release of the same chart.
**Prereqs:** a `values-<env>.yaml` file next to the chart's `values.yaml`, e.g.:
```
helm/apps/frontend/values.yaml
helm/apps/frontend/values-stage.yaml
```

1. Deploy the overlay for one chart:
   ```bash
   helm-upgrade --env stage --include frontend
   ```
   or use a shorthand for the common environments:
   ```bash
   helm-upgrade --stage --include frontend   # same as --env stage
   helm-upgrade --dev --include frontend
   helm-upgrade --prod --include frontend
   ```
2. Deploy the whole overlay-enabled set (charts without a matching `values-stage.yaml` are skipped automatically):
   ```bash
   helm-upgrade --env stage
   ```
3. Roll it back the same way:
   ```bash
   helm-rollback --env stage --include frontend
   ```

**Verify:** `helm list -n <env-namespace>` shows a release named `stage-frontend` (not `frontend`); `helm get values stage-frontend` shows `values.yaml` merged with `values-stage.yaml`.
**Gotchas:**
- `--env` restricts the plan to charts that *have* the overlay file — if a chart you expected is missing from the plan, you forgot to create `values-<env>.yaml` for it.
- MD5 change detection and rollback plans use the release name as the cache key, so `stage-frontend` and `frontend` are tracked completely independently — a `--force` on prod does not affect stage's cached checksum.
- The environment namespace is read from the overlay file when present; otherwise `namespace_overrides` / chart defaults apply.

See also: [PROJ-HOWTO.md](../PROJ-HOWTO.md)
