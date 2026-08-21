# Deployment Guide

## Primary install surface

Welkin is installed through the Timoni bundle at `platform/bundles/welkin-dev.bundle.cue`.

The bundle:

1. installs Flux AIO into `flux-system`
2. declares OpenMeter as a Flux-managed Helm release
3. declares OpenMeter Collector as a Flux-managed Helm release
4. declares Postgres (economic plane) and MinIO (archive plane) releases

## Runtime inputs

The deployment contract lives in `platform/runtime/welkin.runtime.cue`. Every mutable
value is a Timoni runtime attribute (`@timoni(...)`), injected at apply time from
environment variables (`--runtime-from-env`) and/or a runtime overlay.

Required (apply fails if unset):

- `OPENMETER_TOKEN` — OpenMeter API token (collector native output)

Optional overrides (sensible `*` defaults in the runtime):

- `OPENMETER_URL` — OpenMeter endpoint (default `http://openmeter-api`)
- `ARCHIVE_S3_ENDPOINT` — S3-compatible archive endpoint (default in-cluster MinIO)
- `ARCHIVE_S3_BUCKET` — archive bucket (also MinIO `defaultBuckets`)
- `ARCHIVE_S3_ACCESS_KEY_ID` / `ARCHIVE_S3_SECRET_ACCESS_KEY` — MinIO/S3 credentials
- `POSTGRES_USERNAME` / `POSTGRES_PASSWORD` / `POSTGRES_DATABASE` / `POSTGRES_ADMIN_PASSWORD`
- archive endpoint, region, batch, and force-path-style knobs

The full contract and table is in `platform/README.md`.

### Environment-var injection

```bash
export OPENMETER_TOKEN="..."
export ARCHIVE_S3_BUCKET="welkin-archive"
export ARCHIVE_S3_ACCESS_KEY_ID="example"
export ARCHIVE_S3_SECRET_ACCESS_KEY="example-secret"
timoni bundle apply <all CUE files> --runtime-from-env
```

### Runtime overlay file

When values live in the cluster or a file rather than the shell, use a runtime overlay:

```cue
package main

runtime: {
  openmeter: { url: "http://openmeter-api" }
  archive: {
    endpoint:      "https://s3.example.internal"
    bucket:        "welkin-archive"
    region:        "us-east-1"
    accessKeyId:     "example"
    secretAccessKey: "example-secret"
  }
}
```

Pass it with `--runtime /path/to/your.runtime.cue`. Runtime file values take
precedence over environment variables.

> Note the runtime field names are camelCase (`accessKeyId`, `secretAccessKey`),
> matching `platform/runtime/welkin.runtime.cue`.

## Quick start (Makefile)

The repo's `Makefile` wraps the Timoni bundle targets so you do not assemble the
CUE file list by hand:

```sh
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

## Ephemeral deployment flow

Use this flow when you want to validate Welkin in a disposable environment instead of on your laptop:

1. create an ephemeral Kubernetes cluster
2. prepare environment-backed values or a runtime overlay
3. `make apply` (or `timoni bundle apply` with the full file set)
4. wait for Flux, OpenMeter, and the collector to become ready
5. create an annotated test workload
6. inspect collector logs, cluster state, and archive destination
7. destroy the cluster when finished

## CI and remote validation

Use `.github/workflows/validate.yaml` for static validation and `.github/workflows/certification-e2e.yml` for full end-to-end deployment checks in an ephemeral cluster.

This is the intended path when you do not want to run the stack locally.