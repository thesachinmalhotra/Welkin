# Welkin

Welkin is a composition-first usage substrate built around OpenMeter Collector, OpenMeter, and an archive plane.

Welkin v1 has one governing rule: producer diversity is allowed only before canonicalization. Once an event becomes a canonical CloudEvent, runtime metering and archive handling stay identical regardless of producer type.

## What this repo gives you

- `contracts/` for canonical event and archive contract definitions
- `engine/` for the OpenMeter Collector substrate: canonical validation, fan-out resources, archive handling, tests, and optional source presets
- `timoni/` for the primary install surface and runtime contract
- `flux/` for OCI-based GitOps handoff after publishing release artifacts
- `.github/workflows/` for validation and certification workflows
- `certification/` for the architectural guarantees, scenario catalog, and evidence model
- `docs/` for architecture, deployment, certification, and operator guidance

## Core architecture

Welkin v1 is two planes only:

- Economic Plane: canonical CloudEvents flow into OpenMeter.
- Archive Plane: the same canonical CloudEvents are encoded as Parquet and written to S3-compatible storage.

OpenMeter Collector is the soul of Welkin. Producer diversity belongs to the OpenMeter Collector and Redpanda Connect ecosystem. Welkin validates the Canonical CloudEvent boundary and fans out one fixed canonical stream to both planes.

## Collector substrate

Welkin is source-agnostic at the substrate boundary:

`OpenMeter Collector source or preset -> Canonical CloudEvent -> validation -> broker fan_out -> OpenMeter + Parquet-on-S3`

Kubernetes support lives as an optional OpenMeter Collector preset example, not as Welkin's core event model. The goal is to compose and exploit the existing collector ecosystem rather than replace it.

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
