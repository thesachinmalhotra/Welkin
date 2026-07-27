package main

runtime: {
  namespace: *"welkin-system" | string

  charts: {
    fluxAioVersion:    *"2.5.0-0" | string
    fluxModuleVersion: *"latest" | string
    openmeterVersion:  *"*" | string
    collectorVersion:  *"*" | string
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
