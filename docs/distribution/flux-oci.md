# Flux OCI Distribution

How a Welkin release flows from Timoni to a running cluster via Flux.

## Architecture

```
timoni artifact build -f release -t v1.0.0
        │
        ▼
timoni artifact push oci://ghcr.io/<org>/welkin:v1.0.0
        │
        ▼
  OCI artifact in registry (immutable digest)
        │
        ▼
Flux OCIRepository watches oci://ghcr.io/<org>/welkin
        │
        ▼
Flux Kustomization applies the rendered manifests
```

## Release artifact

The release directory (`dist/oci/`) contains symlinks to the canonical CUE files:

```
dist/oci/
  welkin.bundle.cue    → platform/bundles/welkin.bundle.cue
  welkin.runtime.cue   → platform/runtime/welkin.runtime.cue
  collector.cue        → platform/collector/collector.cue
  openmeter.cue        → platform/economic/openmeter.cue
  postgres.cue         → platform/economic/postgres.cue
  minio.cue            → platform/archive/minio.cue
```

The `release.yaml` workflow builds and pushes this directory as an OCI artifact on every `v*` tag.

## Consuming from Flux

### OCIRepository

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: welkin
  namespace: flux-system
spec:
  interval: 1m
  url: oci://ghcr.io/<org>/welkin
  ref:
    semver: ">=1.0.0"
  provider: generic
  secretRef:
    name: ghcr-credentials
```

### Kustomization

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: welkin
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: OCIRepository
    name: welkin
  path: ./
  prune: true
  wait: true
  timeout: 5m
```

### Runtime overlay

Environment-specific values are supplied via a runtime overlay CUE file deployed as a ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: welkin-runtime
  namespace: flux-system
data:
  welkin.runtime.cue: |
    package main
    runtime: {
      namespace: "welkin-system"
      archive: {
        endpoint: "http://minio.welkin-system.svc.cluster.local:9000"
        bucket: "welkin-archive"
      }
    }
```

## Versioning

- **Semver tag** (e.g., `v1.2.0`): communicates human-readable release intent
- **OCI digest** (e.g., `sha256:abc...`): provides immutable artifact identity
- **`latest` tag**: always points to the most recent release

Flux resolves semver to a specific digest on each reconciliation loop.

## CI verification

The `release.yaml` workflow verifies the artifact after push:
1. Pulls the artifact back from the registry
2. Runs `timoni bundle vet` against the extracted files
3. Reports the digest in the GitHub Actions step summary
