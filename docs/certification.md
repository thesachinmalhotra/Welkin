# Welkin Certification

Welkin certification exists to prove architectural guarantees with executable evidence.

## Guarantees

| Guarantee | Status | How it is verified | Evidence produced |
| --- | --- | --- | --- |
| One canonical CloudEvent boundary | Implemented | Validate the canonical CloudEvent contract and the collector canonicalization path. | `cue vet` output, collector fixture output, workflow summary, artifact bundle |
| Malformed events fail at the correct boundary | Implemented | Run invalid canonical input through the canonical contract and assert validation fails before deployment steps. | Expected-failure output, contract validation log, scenario summary |
| Runtime and archive remain independent | Scaffolded | Inject archive-side failure and prove the runtime branch continues. | Archive failure log, runtime continuity log, branch independence evidence |
| Duplicate events do not become duplicate billing | Planned | Replay the same canonical batch and compare billing-facing results. | OpenMeter query result, dedup diff, replay log |
| Producer diversity only affects the edge | Planned | Exercise multiple collector presets and compare the canonical downstream shape. | Preset matrix, canonical shape diff, producer trace bundle |
| Deployment stays reproducible from a clean environment | Implemented | Create a fresh cluster and apply the release through the same composition path. | Kind bootstrap log, Timoni render, Flux reconciliation log, artifact bundle |

## Evidence model

Every certification run should leave behind a durable artifact bundle containing:

- the scenario definition that ran
- the exported certification catalog
- command output for the verification steps
- cluster state or validation failure output, depending on scenario type
- a machine-readable summary and a human-readable report

## Current gaps

Some invariants are intentionally scaffolded rather than forced into weak checks:

- Plane independence needs a real archive failure-injection path.
- Duplicate billing needs OpenMeter meter/query assertions wired into the repository's runtime contract.
- Producer diversity needs additional preset-backed upstream families beyond the Kubernetes-first path.

Those are marked as scaffolded or planned in `certification/catalog.cue` so the repository stays honest about what is proven today.
