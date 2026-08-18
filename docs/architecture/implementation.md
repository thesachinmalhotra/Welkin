# Welkin Implementation Notes

## Repository responsibilities

- `spec/` holds the canonical CloudEvent and archive contracts.
- `platform/` holds the deployment bundle and runtime contract (plane-based: economic, archive, collector).
- `dist/` holds the GitOps-facing handoff once Welkin release artifacts are published.
- `.github/workflows/` holds remote validation and smoke deployment automation.

## Current first-class path

Welkin composes the **OpenMeter Collector** (the upstream Redpanda Connect distribution) as the sole production collector. Welkin does not add custom Benthos/Bloblang resources, processor_resources, or output_resources.

The collector uses the upstream `benthos-collector` Helm chart with its native `openmeter` output. Welkin configures the chart via `platform/collector/collector.cue`:

- `preset` selects an upstream preset (e.g. `kubernetes-pod-exec-time`, `http-server`).
- `openmeter.url` and `openmeter.token` configure the native output.
- Env vars configure preset behavior.

The Canonical CloudEvent contract is defined by CUE in `spec/schema/cloudevent.cue` and validated via `cue vet`.

## Delivery posture

The repo is assembled so you can author locally without running a full platform stack, then validate later in CI or an ephemeral Kubernetes environment.

This is why the install surface is centered on Timoni and Flux rather than on laptop-resident services.

## Assumptions

- Flux is installed by the Timoni bundle before chart-backed releases reconcile.
- Archive storage is supplied as an S3-compatible endpoint through runtime values.
- OpenMeter remains the runtime authority; Welkin does not add custom runtime services.
- The Flux OCI handoff is intended for published release artifacts and uses placeholder OCI coordinates until a release registry location is chosen.
