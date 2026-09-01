# helm-utils HOWTO — Summary

Task list for [PROJ-HOWTO.md](PROJ-HOWTO.md). One line each: what you'd be walked through.

- **Install the tools** — get `helm-upgrade`, `helm-rollback`, `helm-publish` on your `$PATH`.
- **Deploy/upgrade charts in tier order** — roll out chart changes in dependency-safe order, skipping anything unchanged.
- **Preview a deploy before applying it** — see the actual manifest diff against the live cluster, not just "would deploy."
- **Deploy to a non-production environment (stage/dev)** — deploy an overlay environment with its own release names and values, isolated from production. *(howto/deploy-environment-overlay.md)*
- **Roll back a bad deploy** — undo one or more releases, in reverse tier order, without hand-picking `helm rollback` revisions yourself.
- **Publish a chart to the OCI registry** — package and push a Helm chart, optionally bumping its version.
- **Add a new chart to the deploy pipeline** — wire a chart into discovery, tiers, namespace, and timeout config. *(howto/add-chart-to-pipeline.md)*
- **Keep a stateful chart's live values from being wiped** — stop the default `--reset-values` from discarding runtime-only values on charts like Weaviate/Qdrant.
- **Resolve a server-side-apply ownership conflict** — get past a `helm upgrade` failure caused by another controller owning fields Helm now wants to manage.
