# Welkin Implementation Notes

## Repository responsibilities

- `spec/` holds the canonical CloudEvent and archive contracts.
- `collector/` holds the OpenMeter Collector substrate: canonical validation, fan-out resources, archive handling, source presets, fixtures, and tests.
- `platform/` holds the deployment bundle and runtime contract (plane-based: economic, archive, collector).
- `dist/` holds the GitOps-facing handoff once Welkin release artifacts are published.
- `.github/workflows/` holds remote validation and smoke deployment automation.

## Current first-class path

The first implemented path is source-agnostic at the Canonical CloudEvent boundary.

Key pieces:

- `collector/resources/processors/validate_cloudevent.yaml`
- `collector/resources/processors/archive_partition.blobl`
- `collector/tests/archive_partition_test.yaml`

Collector config is inlined in `platform/collector/collector.cue` (the sole deployment source).

The Canonical CloudEvent contract is validated with CUE against fixtures in `collector/fixtures/` and `spec/`.

Kubernetes support is kept under `collector/presets/kubernetes/` as an OpenMeter Collector preset example, not as Welkin's core event model.

## Delivery posture

The repo is assembled so you can author locally without running a full platform stack, then validate later in CI or an ephemeral Kubernetes environment.

This is why the install surface is centered on Timoni and Flux rather than on laptop-resident services.

## Assumptions

- Flux is installed by the Timoni bundle before chart-backed releases reconcile.
- Archive storage is supplied as an S3-compatible endpoint through runtime values.
- OpenMeter remains the runtime authority; Welkin does not add custom runtime services.
- The Flux OCI handoff is intended for published release artifacts and uses placeholder OCI coordinates until a release registry location is chosen.
