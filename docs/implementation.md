# Welkin Implementation Notes

## Repository responsibilities

- `contracts/` holds the canonical CloudEvent and archive contracts.
- `engine/` holds the OpenMeter Collector substrate: canonical validation, fan-out resources, archive handling, source presets, fixtures, and tests.
- `timoni/` holds the deployment bundle and runtime contract.
- `flux/` holds the GitOps-facing handoff once Welkin release artifacts are published.
- `.github/workflows/` holds remote validation and smoke deployment automation.

## Current first-class path

The first implemented path is source-agnostic at the Canonical CloudEvent boundary.

Key pieces:

- `engine/resources/processors/validate_cloudevent.yaml`
- `engine/resources/processors/archive_partition.blobl`
- `engine/tests/archive_partition_test.yaml`

Collector config is inlined in `timoni/values/collector.cue` (the sole deployment source).

The Canonical CloudEvent contract is validated with CUE against fixtures in `engine/fixtures/` and `contracts/`.

Kubernetes support is kept under `engine/presets/kubernetes/` as an OpenMeter Collector preset example, not as Welkin's core event model.

## Delivery posture

The repo is assembled so you can author locally without running a full platform stack, then validate later in CI or an ephemeral Kubernetes environment.

This is why the install surface is centered on Timoni and Flux rather than on laptop-resident services.

## Assumptions

- Flux is installed by the Timoni bundle before chart-backed releases reconcile.
- Archive storage is supplied as an S3-compatible endpoint through runtime values.
- OpenMeter remains the runtime authority; Welkin does not add custom runtime services.
- The Flux OCI handoff is intended for published release artifacts and uses placeholder OCI coordinates until a release registry location is chosen.
