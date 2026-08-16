# Welkin Composition Plan — From Scratch

## Starting Point

The architecture is sound. The components are sound. The implementation drifted by patching with custom code where upstream-native patterns already exist. The plan is to realign implementation to architecture — no redesign, no new components, just pure composition.

## Core Invariants (unchanged)

1. Canonical CloudEvents are the platform contract.
2. Producer diversity ends at canonicalization.
3. Economic and Archive planes are independent.
4. Archive processing must never block Economic Plane processing.
5. OpenMeter Collector is the production collector. `rpk` is test tooling only.
6. Timoni → OCI → Flux is the platform distribution model.
7. Platform State (immutable, versioned) and Environment State (per-environment) stay separate.

## Legos Available (Upstream Native)

| Lego | Source | Role in Welkin |
|---|---|---|
| `benthos-collector` (OCI Helm) | `ghcr.io/openmeterio/helm-charts/benthos-collector` | OpenMeter Collector — ingestion, canonicalization, fan-out |
| `openmeter` (OCI Helm) | `ghcr.io/openmeterio/helm-charts/openmeter` | Economic plane — metering, billing, OpenMeter API |
| `flux-aio` (Timoni module) | `oci://ghcr.io/stefanprodan/modules/flux-aio` | Flux reconciliation controller |
| `flux-helm-release` (Timoni module) | `oci://ghcr.io/stefanprodan/modules/flux-helm-release` | Flux HelmRelease per component |
| MinIO (upstream Helm or OCI) | `minio/minio` | Archive plane — object storage |
| S3-compatible object storage | native | Archive plane — durable Parquet |
| Timoni bundles | CUE | Platform composition surface |
| Flux Kustomization | native | Post-deployment validation / certification |

## Composition Map

```
timoni bundle build
       │
       ├── instance: flux-aio
       │     └── flux: reconciliation controller
       │
       ├── instance: openmeter (HelmRelease via flux-helm-release)
       │     ├── chart: oci://ghcr.io/openmeterio/helm-charts/openmeter@sha256:<digest>
       │     ├── postgresql: disabled (external Postgres via env)
       │     ├── svix: disabled
       │     └── config: meters, postgres URL, stripe (env via k8s:Secret)
       │
       ├── instance: collector (HelmRelease via flux-helm-release)
       │     ├── chart: oci://ghcr.io/openmeterio/helm-charts/benthos-collector@sha256:<digest>
       │     └── config (Helm values → benthos config.yaml):
       │           ├── input.http_server.path: /events        ← canonical boundary
       │           ├── pipeline.processors: [json_schema validator + drop on fail]
       │           └── output.broker.fan_out:
       │                 ├── openmeter output (env: OPENMETER_URL, OPENMETER_TOKEN)
       │                 └── aws_s3 output (env: ARCHIVE_S3_*)
       │
       └── instance: minio (HelmRelease)
             └── object storage bucket: welkin-archive
```

## Missing Legos to Remove

These exist in the current implementation but are NOT upstream-native — they are the custom wheels:

| Current | Replacement |
|---|---|
| `cert/scripts/run_scenario.py` (inline K8s manifests, wget-based testing) | Flux Kustomization with a native `TestJob` that tests the composed system |
| `POSTGRES_MANIFEST` inline YAML in `run_scenario.py` | Compose Postgres as a separate Timoni instance using the upstream PostgreSQL chart (`bitnami/postgresql` or `pg` module) |
| Direct `POST` to `openmeter-api:80/api/v1/events` in test harness | POST to `openmeter-collector:4195/events` via the collector's `http_server` input |
| `assert_parquet_in_minio()` stub | `mc find local/welkin-archive --name "*.parquet"` in the native TestJob |
| `collector/config/base.yaml` as a source-of-truth separate from Timoni | Deleted. Collector config lives only in `platform/collector/collector.cue` |

## Phase Map

### Phase 1 — Environment Foundation
- ~~Spin up a fresh `k8s-runtime.cue` with real environment values (no hardcoded test overlays)~~ **Done (welkin.runtime.cue is now concrete defaults)**
- Ensure all secrets (`OPENMETER_TOKEN`, `ARCHIVE_S3_*`) are in a K8s Secret that Timoni can query via `k8s:v1:Secret`
- ~~Remove the `ci-test.cue` overlay — it's a test abstraction that leaks into production shapes~~ **Done (deleted in Phase 2)**

### Phase 2 — Postgres as a Lego
- ~~Remove `POSTGRES_MANIFEST` from `run_scenario.py`~~ **Done**
- ~~Add a `postgres` Timoni instance to the bundle using `bitnami/postgresql` Helm chart OR the stefanprodan `pg` module~~ **Done (bitnami/postgresql via flux-helm-release)**
- ~~Wire `openmeter.config.postgres.url` to the composed Postgres service (`postgres:5432`)~~ **Done (service name matches via fullnameOverride)**
- ~~Remove the hardcoded `postgres://application:application@postgres:5432` string from `openmeter.cue`~~ **Wired to composed Postgres; credentials remain as env values (Secret injection deferred to production hardening)**

### Phase 3 — Collector as Pure Lego
- The collector instance in the Timoni bundle IS the complete collector config surface
- ~~Remove `collector/config/base.yaml` as a "source of truth"~~ **Done (deleted in Phase 1)**
- The `input.http_server.path: /events` is set in the Timoni module's `helmValues.config` block
- All environment knobs (`OPENMETER_URL`, `ARCHIVE_S3_*`, `LOG_LEVEL`, etc.) flow from Timoni runtime → Helm env vars → Benthos config
- No file mounts, no ConfigMap patches, no custom init containers

### Phase 4 — Certification as a Lego
- ~~Replace `run_scenario.py` with a Flux `Kustomization` that deploys a `Job` resource~~ **Done (Job created, run_scenario.py simplified)**
- ~~The Job tests the composed system natively:~~ **Done (certify.sh)**
  - ~~POSTs a CloudEvent to `http://openmeter-collector:4195/events`~~
  - ~~Queries OpenMeter API (`http://openmeter-api/api/v1/meters/*/values`)~~
  - ~~Queries MinIO for Parquet files (via S3 API)~~
- ~~Certification result is a K8s Job pod log — not a CI script artifact~~ **Done**
- The certification Kustomization is part of the bundle, not an external script *(deferred to Phase 5 — Flux integration)*

### Phase 5 — Platform Artifact
- `timoni bundle build` produces all Kubernetes resources as a directory tree
- `timoni artifact push` packages the bundle as an OCI artifact (`oci://ghcr.io/<org>/welkin:v<semver>`)
- Flux `OCIRepository` consumes the OCI artifact and reconciles the bundle
- Semantic version communicates release intent; OCI digest provides immutable identity

## Verification Strategy

| Check | Tool | What it validates |
|---|---|---|
| Schema contract | `cue vet` | CloudEvent and Archive schemas |
| Collector logic | `rpk connect test` | Bloblang processors, Parquet encoding |
| Bundle integrity | `timoni bundle vet` | All CUE layers resolve, env vars wired |
| Bundle render | `timoni bundle build` | Kubernetes manifests are well-formed |
| Composition smoke | `timoni bundle apply --dry-run` | Resources reconcile without conflict |
| Certification | Flux Job (native) | End-to-end event flow through collector boundary |

## Non-Goals

- No custom services
- No Redpanda Connect config files checked into the repo (that is the Helm chart's job)
- No bash scripts for infrastructure orchestration
- No `collector/config/base.yaml` as a deployment materialization source (deleted in Phase 1)
- No stub assertions — if something can't be verified composably, surface the gap instead of stubbing it

## When Ready

Once this plan is approved, implementation follows phase by phase. Each phase produces a clean diff that passes the full verification strategy before the next phase begins. No phase reaches CI until local validation is green.