package main

runtime: {
  namespace: *"welkin-system" | string

  charts: {
    fluxAioVersion:    *"2.5.0-0" | string // stefanprodan/flux-aio v2.5.0-0 (chart/module digest: sha256:d2318d87b177e6ae9406a61194f6ce7e4aab17f49369e8d2c18ecc22b671d7d9)
    fluxModuleVersion: *"2.5.0-0" | string // stefanprodan/flux-helm-release v2.5.0-0 (module digest: sha256:cbefa11842b80cb4d6871ff361ce133c64dc232e93864462066e01b269a15970)
    openmeterVersion:  *"1.0.0-beta.232" | string // pinned to OpenMeter release v1.0.0-beta.232 (chart digest: sha256:084f4eb0947daf948583ea07945241583d5ef40a5ae1da8d9f9caedf62878dc3)
    collectorVersion:  *"1.0.0-beta.232" | string // chart appVersion v1.0.0-beta.232 -> image ghcr.io/openmeterio/benthos-collector:v1.0.0-beta.232 (amd64 digest: sha256:4a816108919b77d35209ad9053dca417897bfc463cd6c13ff71262ad35103119)
  }

  openmeter: {
    url:   *"http://openmeter-api" | string
  }

  collector: {
    preset:          *"kubernetes-pod-exec-time" | string
    scrapeNamespace: *"" | string
    scrapeInterval:  *"15s" | string
    batchSize:       *"100" | string
    batchPeriod:     *"1s" | string
    debug:           *"false" | string

    serviceEnabled: *false | bool
    storageEnabled: *true | bool
    storageSize:    *"1Gi" | string
    bufferPath:     *"/data/buffer.db" | string

    logLevel:       *"INFO" | string
    logFormat:      *"json" | string
    shutdownDelay:  *"5s" | string
    shutdownTimeout:*"20s" | string
  }

  archive: {
    endpoint:       string
    bucket:         string
    region:         *"us-east-1" | string
    forcePathStyle: *true | bool
    batchCount:     *250 | int
    batchPeriod:    *"15s" | string
  }
}
