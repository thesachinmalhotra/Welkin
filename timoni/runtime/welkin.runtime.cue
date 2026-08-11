package main

runtime: {
  namespace: *"welkin-system" | string

  charts: {
    fluxAioVersion:    *"2.5.0-0" | string
    fluxModuleVersion: *"2.5.0-0" | string
    openmeterVersion:  *"0.1.0" | string
    collectorVersion:  *"0.1.0" | string
  }

  openmeter: {
    url:   *"http://openmeter-api" | string
    token: *"" | string
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
    accessKeyID:    string
    secretAccessKey:string
    forcePathStyle: *true | bool
    batchCount:     *250 | int
    batchPeriod:    *"15s" | string
  }
}
