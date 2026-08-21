# Welkin Certification

Welkin certification exists to prove architectural guarantees with executable evidence. It is exercised by the `certification-e2e.yml` workflow, which:

1. Builds and pushes the release OCI artifact exactly once, capturing its immutable digest.
2. Creates an ephemeral kind cluster and applies the Timoni bundle (`timoni bundle apply`) — the same composition path as production.
3. Applies the certification Job (`dist/flux/certification/certification-job.yaml`), which POSTs a canonical CloudEvent to the collector boundary at `:8080/api/v1/events` and asserts the planes.
4. Collects evidence into one deterministic directory, uploads it as an artifact, and destroys the cluster unconditionally.

## Guarantees

| Guarantee | Status | How it is verified |
| --- | --- | --- |
| One canonical CloudEvent boundary | Implemented | Certification Job POSTs a canonical CloudEvent to the collector and asserts acceptance. |
| Malformed events fail at the correct boundary | Implemented | Contract validation via `cue vet` on the canonical schema. |
| Economic and archive remain independent | Scaffolded | Archive plane is asserted but a real archive failure-injection path is not yet in the workflow. |
| Duplicate events do not become duplicate billing | Planned | Not yet wired into the certification run. |
| Producer diversity only affects the edge | Planned | Requires additional preset-backed producer families. |
| Deployment stays reproducible from a clean environment | Implemented | Fresh kind cluster + `timoni bundle apply` through the same composition path. |

## Evidence model

Every workflow run leaves behind a durable artifact bundle (`/tmp/welkin-evidence/`) containing:

- the scenario id and OCI digest
- the certification result and Job logs
- cluster resources, HelmReleases, and events
- a machine-readable evidence file

## Current gaps

Plane independence, duplicate-billing, and producer-diversity assertions are intentionally not forced into weak checks. They remain scaffolded or planned rather than disguised as passing tests.