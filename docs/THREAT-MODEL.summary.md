# Threat Model — Summary

Local Bash CLIs (helm-upgrade / helm-rollback / helm-publish); no network services. Boundaries: operator shell → sourced k8-lib (`$K8_LIB_DIR`, trusted) → unvalidated `infra-config.yaml`/`Chart.yaml` input → k8s cluster + OCI registry using operator credentials. Jewels: cluster deploy/rollback power, OCI registry write, registry/GHCR tokens. Full detail: [THREAT-MODEL.md](THREAT-MODEL.md).

Register: T-001 k8-lib path = trusted code (high, by assumption) · T-002 hostile config drives cluster ops (medium, open-accepted: run only in trusted repos) · T-003 registry credentials via `--password-stdin`, never echoed/argv/state (high, mitigated) · T-004 `.helm-state/` unprotected, detection-only impact (low, open-accepted) · T-005 SSA `--force-conflicts` ownership seizure gated by opt-in flag + confirm (medium, mitigated-by-gate) · T-006 temp dirs `mktemp -d` 0700 (low, mitigated) · T-007 static completions/docs (low, N/A).

Coverage: 2 mitigated · 2 gated/assumed · 2 open-accepted · 1 N/A. Residual risk: config-driven execution inherent to purpose (control = where you run it); secrets layer modeled in monorepo `docs/secret-management.md`, not here.
