# helm-utils FAQ — Summary

Question headings only, grouped by category. Companion to [PROJ-FAQ.md](PROJ-FAQ.md) — cheap relevance check before opening the full file.

## Motivation
- Why would I use `helm-upgrade` instead of just calling `helm upgrade --install` myself?
- Why does `helm-upgrade` default to `--reset-values` instead of Helm's own `--reuse-values` behavior?
- Why is `helm-publish`'s chart discovery separate from `helm-upgrade`/`helm-rollback`'s?
- Why does `--env` create a whole separate release (`stage-frontend`) instead of just pointing the same release at a different namespace?

## Fit
- When is this the wrong tool for a deploy?
- When should I skip the tier config entirely and just target one chart?
- When should I use `helm_scan_dirs` vs. `chart_path_overrides` to make a chart discoverable?

## Comparison
- How does `helm-rollback` differ from plain `helm rollback <release> <revision>`?
- How does this differ from just scripting `helm push` for `helm-publish`?
- How does `helm-upgrade --preview` differ from `--dry-run`?

## Capability
- Can I deploy a chart that lives outside the standard `helm/` tree?
- Does `helm-publish` also own the chart source (Chart.yaml, templates)?

## Caveats
- What happens if I re-run `helm-upgrade` and nothing deploys?
- If one chart fails mid-tier, do the other charts already running in that same tier get cut off?
- What's the risk in `--force-conflicts` on a server-side-apply ownership error?

## Trust
- Where do `helm-publish`'s registry credentials come from, and are they ever logged?
