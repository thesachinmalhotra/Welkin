# Flux OCI Distribution

How a Welkin release flows from Timoni to a running cluster via Flux.

## Architecture

```
platform/  (canonical composition CUE)
        │
        ▼
timoni artifact push oci://ghcr.io/<org>/welkin:v1.0.0 -f platform
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

The release artifact is the `platform/` directory itself — the canonical
composition CUE, pushed as-is. There is no staging copy or symlink farm:

```
platform/
  bundles/    dev + prod Timoni bundles
  runtime/    runtime injection points (Environment State)
  collector/  collector component values
  economic/   OpenMeter + Postgres component values
  archive/    MinIO component values
```

The `release.yaml` workflow pushes this directory as an OCI artifact on every
`v*` tag via `timoni artifact push -f platform`.

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

Flux resolves semver to a specific digest on each reconciliation loop.

## Promotion

Staging and production promote the **same signed digest** — recorded in
`environments/<env>/artifact.txt` and promoted via PR. See
`environments/README.md`. Production always resolves to a digest, never a
mutable tag.
