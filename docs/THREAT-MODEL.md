# Threat Model — helm-utils

Local Bash CLI suite (helm-upgrade / helm-rollback / helm-publish) that drives Helm against the Noizu k8s platform. It runs **no network services** — every trust boundary is between an operator's workstation, files the tools read, shared shell libraries, and the cluster/OCI registry they act on with the operator's own credentials. Crown jewels: the k8s cluster (deploy/rollback power), OCI registry write access, and the registry/GHCR tokens in the environment. Grounding: [PROJ-ARCH.md](PROJ-ARCH.md) (components, data flow) · [PROJ-LAYOUT.md](PROJ-LAYOUT.md) (implementing directories) · [PROJ-SCHEMA.md](PROJ-SCHEMA.md) (config/state surfaces).

## Trust Boundaries & Attack Surface

Boundaries: operator shell → sourced code (`$K8_LIB_DIR/bin/*.sh`) → parsed config (`infra-config.yaml`, `Chart.yaml`) → cluster (helm/kubectl) and OCI registry (helm push). The tools assume the invoking repo's config is **trusted input**; the cluster boundary is authenticated by the operator's existing kubeconfig/registry creds, not by these tools.

```mermaid
graph LR
    OP[Operator shell] --> HU/HU2[bin/helm-upgrade | helm-rollback | helm-publish]
    LIB["$K8_LIB_DIR (~/.local/share/k8-lib) — sourced code"] -.-> HU/HU2
    CFG[(infra-config.yaml + Chart.yaml — unvalidated input)] --> HU/HU2
    ENV["K8_HELM_REGISTRY_PASSWORD / GITHUB_TOKEN / gh auth token"] --> HP[helm-publish]
    HU -->|helm upgrade/rollback, kubectl SSA| K8s[(Kubernetes cluster)]
    HP -->|helm registry login --password-stdin, helm push| OCI[(OCI registry)]
    HU --> STATE[(.helm-state/ checksums + publish log)]
```

## Vulnerability Register

| ID | Severity | STRIDE | Component | Status |
|----|----------|--------|-----------|--------|
| T-001 | High | Tampering / EoP | k8-lib sourcing | Mitigated-by-assumption: `$K8_LIB_DIR` (default `~/.local/share/k8-lib`) is trusted, user-writable code executed by all three tools; compromise of that path = arbitrary code with cluster creds. No integrity check (by design — it is the delivery mechanism). |
| T-002 | Medium | Tampering / EoP | `infra-config.yaml` / `Chart.yaml` input | Open: chart paths, aliases, namespaces, versions parsed via yq/jq and fed to helm/kubectl; a hostile repo's config drives cluster mutations. Accepted: config is authored in trusted git repos; `--config` is an explicit operator choice. |
| T-003 | High | Info disclosure | helm-publish credentials | Mitigated: registry token resolved `K8_HELM_REGISTRY_PASSWORD` → `GITHUB_TOKEN` → `gh auth token`, piped via `--password-stdin` with output suppressed; never echoed, never on argv, never written to state. |
| T-004 | Low | Tampering / Repudiation | `.helm-state/` files | Open (accepted): plain-text checksums and publish log in the target repo; no integrity protection, so skip-unchanged logic can be fooled into re-deploying or skipping (detection only — the manifest itself comes from git). Safe to delete; never contains secrets. |
| T-005 | Medium | DoS / EoP | `helm-upgrade --force-conflicts` | Mitigated-by-gate: SSA field-ownership seizure (`kubectl apply --server-side --force-conflicts --field-manager=helm`) re-applies matched resources; opt-in flag plus interactive plan confirmation precede execution. |
| T-006 | Low | Tampering | temp dirs | Mitigated: `mktemp -d` (0700) for package/parallel scratch; no secrets written. |
| T-007 | Low | Info disclosure | completions/docs | Mitigated: N/A — static text, no secrets; repo `.gitignore` keeps `.env`/`.envrc.local` out. |

## Mitigation Coverage

2 mitigated · 2 mitigated-by-gate/assumption · 2 open-accepted · 1 N/A. No open items carry a ticket — the open items (T-002, T-004) are accepted residual risks below.

## Residual Risk

Config-driven execution (T-002) is inherent to the tool's purpose; the control is *where you run it* (trusted repos only — never point `INFRA_ROOT`/`--config` at an untrusted checkout). Unprotected state files (T-004) can mislead change detection but cannot alter what is deployed. Credential handling depends on the surrounding environment (`.envrc.k8.dc`, direnv) rather than these scripts; that layer is modeled in the monorepo's `docs/secret-management.md`, not here.
