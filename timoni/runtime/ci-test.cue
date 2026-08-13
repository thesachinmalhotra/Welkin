package main

runtime: {
  namespace: "welkin-system"
  charts: {
    fluxAioVersion:    "2.5.0-0"
    fluxModuleVersion: "2.5.0-0"
    openmeterVersion:  "1.0.0-beta.232"
    collectorVersion:  "1.0.0-beta.232"
  }
  openmeter: url: "http://openmeter-api"
  archive: {
    endpoint:       "http://minio.minio.svc.cluster.local:9000"
    bucket:         "welkin-archive"
    region:         "us-east-1"
    forcePathStyle: true
    batchCount:     250
    batchPeriod:    "15s"
  }
}
