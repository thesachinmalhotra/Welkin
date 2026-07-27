# Welkin Implementation Notes

## Repository responsibilities

- `cue/` holds the canonical CloudEvent and archive contracts.
- `collector/` holds the ingestion core: fixtures, schemas, Bloblang mappings, outputs, and unit tests.
- `timoni/` holds the deployment bundle and runtime contract.
- `flux/` holds the GitOps-facing handoff once Welkin release artifacts are published.
- `.github/workflows/` holds remote validation and smoke deployment automation.

## Current first-class path

The first implemented path is the Kubernetes-oriented collector route.

Key pieces:

- `collector/resources/processors/canonicalize_kubernetes.blobl`
- `collector/resources/outputs/runtime_openmeter.yaml`
- `collector/resources/outputs/archive_s3.yaml`
- `collector/config/base.yaml`
- `collector/tests/kubernetes_runtime_archive_benthos_test.yaml`

## Delivery posture

The repo is assembled so you can author locally without running a full platform stack, then validate later in CI or an ephemeral Kubernetes environment.

This is why the install surface is centered on Timoni and Flux rather than on laptop-resident services.

## Assumptions

- Flux is installed by the Timoni bundle before chart-backed releases reconcile.
- Archive storage is supplied as an S3-compatible endpoint through runtime values.
- OpenMeter remains the runtime authority; Welkin does not add custom runtime services.
- The Flux OCI handoff is intended for published release artifacts and uses placeholder OCI coordinates until a release registry location is chosen.
