# Welkin

Welkin is a composition-first usage substrate built around OpenMeter Collector, OpenMeter, and an archive plane.

Welkin v1 has one governing rule: producer diversity is allowed only before canonicalization. Once an event becomes a canonical CloudEvent, runtime metering and archive handling stay identical regardless of producer type.

## What this repo gives you

- `cue/` for canonical event and archive contract definitions
- `collector/` for OpenMeter Collector / Redpanda Connect mappings, resources, and tests
- `timoni/` for the primary install surface and runtime contract
- `flux/` for OCI-based GitOps handoff after publishing release artifacts
- `.github/workflows/` for validation and certification workflows
- `certification/` for the architectural guarantees, scenario catalog, and evidence model
- `docs/` for architecture, deployment, certification, and operator guidance

## Core architecture

Welkin v1 is two planes only:

- Runtime Plane: canonical CloudEvents flow into OpenMeter.
- Archive Plane: the same canonical CloudEvents are encoded as Parquet and written to S3-compatible storage.

The collector is the soul of Welkin. It absorbs producer diversity, normalizes events once, validates the canonical shape, and fans out one fixed stream to both planes.

## Golden path

The first built path in this repo is Kubernetes-oriented and follows the ecosystem-native route:

`Kubernetes preset -> Bloblang normalization -> canonical CloudEvent -> broker fan_out -> OpenMeter + Parquet-on-S3`

That keeps Welkin aligned with the OpenMeter Collector and Redpanda Connect happy path instead of inventing custom services or adapters.

## Certification

Welkin now includes a certification system that treats verification as architectural evidence rather than just test coverage.

Current implemented certifications:
- canonical event boundary
- malformed event rejection
- clean-room reproducibility through the canonical deployment path

Planned certifications remain cataloged explicitly instead of being disguised as weak assertions.

## How to use this later

You do not need to run the full stack on your laptop to use this repo.

1. Review and adapt runtime values in `timoni/runtime/welkin.runtime.cue`.
2. Supply environment- or file-based secrets for OpenMeter and archive credentials.
3. Apply the Timoni bundle into an ephemeral or real Kubernetes environment.
4. Let Flux reconcile OpenMeter and the collector.
5. Use the certification workflows to produce evidence for each architectural guarantee.

The primary install surface is the Timoni bundle, not a large bootstrap manifest.
