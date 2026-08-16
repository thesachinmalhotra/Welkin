# Welkin Timoni Packaging

Timoni is the primary install surface for Welkin.

- `bundles/welkin.bundle.cue` installs Flux and declares the chart-backed Welkin releases.
- `runtime/welkin.runtime.cue` declares the environment-specific contract.
- `values/*.cue` keep chart values and deployment config in one place.

This lets Welkin be authored locally as declarative config and applied later into ephemeral or long-lived Kubernetes environments.
