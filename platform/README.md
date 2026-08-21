# Welkin Timoni Packaging

Timoni is the primary install surface for Welkin.

The packaging is split along the platform/environment boundary:

- **Platform State** (immutable, versioned) — `bundles/welkin-dev.bundle.cue` declares the
  chart-backed Welkin releases (Flux, Postgres, MinIO, OpenMeter, Collector). Plane
  values live in `collector/`, `economic/`, and `archive/`.
- **Environment State** (mutable, per-deployment) — `runtime/welkin.runtime.cue` declares
  the environment contract and surfaces every knob as a Timoni runtime attribute
  (`@timoni(...)`), so a deployment is configured by environment variables — never by
  editing platform state.

This lets Welkin be authored locally as declarative config and applied later into
ephemeral or long-lived Kubernetes environments.

## Quick start

The repo ships a `Makefile` that wraps Timoni so you never hand-assemble the file list:

```sh
# export the environment contract (secrets first)
export OPENMETER_TOKEN=...
export ARCHIVE_S3_BUCKET=welkin-archive
export ARCHIVE_S3_ACCESS_KEY_ID=...
export ARCHIVE_S3_SECRET_ACCESS_KEY=...

make vet          # validate the bundle against the runtime (no cluster)
make print-value  # print the computed runtime-injected values
make diff         # preview cluster-state changes before applying
make build        # render the bundle to multi-doc YAML without applying
make apply        # deploy/upgrade the bundle on the current cluster
make status       # show applied instances, module URL and digest
```

Running `timoni bundle vet`/`apply` by hand requires every file in
`bundles/welkin-dev.bundle.cue`, `runtime/welkin.runtime.cue`, `spec/meters/meters.cue`,
and the three plane directories — the Makefile sets that up for you.

## Environment parameters

Environment values are injected at apply time. Parameters without a `*default`
are **required** (apply fails if unset); the rest are optional overrides:

| Variable | Default | Purpose |
|---|---|---|
| `OPENMETER_TOKEN` | — | OpenMeter API token (collector native output) |
| `OPENMETER_URL` | `http://openmeter-api` | OpenMeter endpoint |
| `ARCHIVE_S3_ENDPOINT` | `http://minio.welkin-system.svc.cluster.local:9000` | S3-compatible archive endpoint |
| `ARCHIVE_S3_BUCKET` | — | Archive bucket (also MinIO `defaultBuckets`) |
| `ARCHIVE_S3_ACCESS_KEY_ID` | `minio` | MinIO root user / S3 access key |
| `ARCHIVE_S3_SECRET_ACCESS_KEY` | `minio123` | MinIO root password / S3 secret key |
| `POSTGRES_USERNAME` | `application` | App DB user |
| `POSTGRES_PASSWORD` | `application` | App DB password |
| `POSTGRES_DATABASE` | `application` | App DB name |
| `POSTGRES_ADMIN_PASSWORD` | `application` | Postgres superuser password |

Runtime parameters come from environment variables (`--runtime-from-env`) and/or a
runtime overlay file (`--runtime runtime.cue`); the runtime overlay takes precedence.