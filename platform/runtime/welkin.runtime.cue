package main

runtime: {
  namespace: "welkin-system"

  charts: {
    fluxAioVersion:    "2.5.0-0" // stefanprodan/flux-aio v2.5.0-0 (chart/module digest: sha256:d2318d87b177e6ae9406a61194f6ce7e4aab17f49369e8d2c18ecc22b671d7d9)
    fluxModuleVersion: "2.5.0-0" // stefanprodan/flux-helm-release v2.5.0-0 (module digest: sha256:cbefa11842b80cb4d6871ff361ce133c64dc232e93864462066e01b269a15970)
    openmeterVersion:  "1.0.0-beta.232" // pinned to OpenMeter release v1.0.0-beta.232 (chart digest: sha256:084f4eb0947daf948583ea07945241583d5ef40a5ae1da8d9f9caedf62878dc3)
    collectorVersion:  "1.0.0-beta.232" // chart appVersion v1.0.0-beta.232 -> image ghcr.io/openmeterio/benthos-collector:v1.0.0-beta.232 (amd64 digest: sha256:4a816108919b77d35209ad9053dca417897bfc463cd6c13ff71262ad35103119)
  }

  openmeter: {
    url: "http://openmeter-api"
  }

  collector: {
    preset:          "kubernetes-pod-exec-time"
    scrapeNamespace: ""
    scrapeInterval:  "15s"
    batchSize:       "100"
    batchPeriod:     "1s"
    debug:           "false"

    serviceEnabled: false
    storageEnabled: true
    storageSize:    "1Gi"
    bufferPath:     "/data/buffer.db"

    logLevel:       "INFO"
    logFormat:      "json"
    shutdownDelay:  "5s"
    shutdownTimeout:"20s"
  }

  archive: {
    endpoint:       "http://minio.welkin-system.svc.cluster.local:9000"
    bucket:         string @timoni(runtime:string:ARCHIVE_S3_BUCKET)
    region:         "us-east-1"
    forcePathStyle: true
    batchCount:     250
    batchPeriod:    "15s"
  }
}
