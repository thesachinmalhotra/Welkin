# Welkin

Welkin is a composition-first usage substrate built around OpenMeter Collector, OpenMeter, and an archive plane.

Welkin v1 has one governing rule: producer diversity is allowed only before canonicalization. Once an event becomes a canonical CloudEvent, runtime metering and archive handling stay identical regardless of producer type.

## What this repo gives you

- `cue/` for canonical event and archive contract definitions
- `collector/` for OpenMeter Collector / Redpanda Connect mappings, resources, and tests
- `timoni/` for the primary install surface and runtime contract
- `flux/` for OCI-based GitOps handoff after publishing release artifacts
- `.github/workflows/` for remote validation and ephemeral deployment smoke checks
- `docs/` for architecture, deployment, and operator guidance

## Core architecture

Welkin v1 is two planes only:

- Runtime Plane: canonical CloudEvents flow into OpenMeter.
- Archive Plane: the same canonical CloudEvents are encoded as Parquet and written to S3-compatible storage.

The collector is the soul of Welkin. It absorbs producer diversity, normalizes events once, validates the canonical shape, and fans out one fixed stream to both planes.

## Golden path

The first built path in this repo is Kubernetes-oriented and follows the ecosystem-native route:

`Kubernetes preset -> Bloblang normalization -> canonical CloudEvent -> broker fan_out -> OpenMeter + Parquet-on-S3`

That keeps Welkin aligned with the OpenMeter Collector and Redpanda Connect happy path instead of inventing custom services or adapters.

## How to use this later

You do not need to run the full stack on your laptop to use this repo.

1. Review and adapt runtime values in `timoni/runtime/welkin.runtime.cue`.
2. Supply environment- or file-based secrets for OpenMeter and archive credentials.
3. Apply the Timoni bundle into an ephemeral or real Kubernetes environment.
4. Let Flux reconcile OpenMeter and the collector.
5. Use the workflow in `docs/deployment.md` and `docs/operator-runbook.md` to validate readiness.

The primary install surface is the Timoni bundle, not a large bootstrap manifest.
