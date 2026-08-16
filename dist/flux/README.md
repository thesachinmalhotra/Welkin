# Flux Entry Points

Welkin's primary install surface is Timoni, but this directory carries the Flux-facing handoff for teams that want OCI-based GitOps reconciliation after publishing release artifacts.

- `release-source.yaml` defines an `OCIRepository` for a published Welkin release artifact.
- `release-kustomization.yaml` defines the matching Flux `Kustomization`.

Replace the placeholder OCI URL and tag before use.
