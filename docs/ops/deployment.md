# Deployment Guide

## Primary install surface

Welkin is installed through the Timoni bundle at `platform/bundles/welkin.bundle.cue`.

The bundle:

1. installs Flux AIO into `flux-system`
2. declares OpenMeter as a Flux-managed Helm release
3. declares OpenMeter Collector as a Flux-managed Helm release

## Runtime inputs

The deployment contract lives in `platform/runtime/welkin.runtime.cue`.

You need to provide values for:

- archive endpoint
- archive bucket
- archive region
- archive access key
- archive secret key
- optional OpenMeter token
- optional namespace and version pins

Example overlay file:

```cue
package main

runtime: {
  namespace: "welkin-system"
  openmeter: token: ""
  archive: {
    endpoint:        "https://s3.example.internal"
    bucket:          "welkin-archive"
    region:          "us-east-1"
    accessKeyID:     "example"
    secretAccessKey: "example-secret"
  }
}
```

## Ephemeral deployment flow

Use this flow when you want to validate Welkin in a disposable environment instead of on your laptop:

1. create an ephemeral Kubernetes cluster
2. prepare a runtime overlay file or environment-backed values
3. apply the Timoni bundle
4. wait for Flux, OpenMeter, and the collector to become ready
5. create an annotated test workload
6. inspect collector logs, cluster state, and archive destination
7. destroy the cluster when finished

## Apply command

```bash
timoni bundle apply \
  -f platform/bundles/welkin.bundle.cue \
  -f platform/runtime/welkin.runtime.cue \
  -f /path/to/your.runtime.cue \
  --wait --timeout=10m
```

## CI and remote validation

Use `.github/workflows/validate.yaml` for static validation and `.github/workflows/ephemeral-smoke.yaml` for remote cluster deployment checks.

This is the intended path when you do not want to run the stack locally.
