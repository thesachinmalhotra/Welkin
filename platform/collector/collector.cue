package main

collectorValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "benthos-collector"
    version: runtime.charts.collectorVersion
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
  }
  helmValues: {
    fullnameOverride: "openmeter-collector"

    // Upstream chart config selection, in upstream precedence order:
    //   config        (highest)  arbitrary Redpanda Connect config -> any of the 65+ connectors
    //   configFile    (mid)      mount an existing Redpanda Connect config file
    //   preset        (fallback) one of the 2 bundled presets
    // Values are ported 1:1 from the upstream benthos-collector chart.
    config:     runtime.collector.config
    configFile: runtime.collector.configFile
    preset:     runtime.collector.preset

    openmeter: {
      url:   runtime.openmeter.url
      token: string @timoni(runtime:string:OPENMETER_TOKEN)
    }

    service: enabled: runtime.collector.serviceEnabled
    storage: {
      enabled: runtime.collector.storageEnabled
      size:    runtime.collector.storageSize
    }

    env: {
      BATCH_SIZE:   runtime.collector.batchSize
      BATCH_PERIOD: runtime.collector.batchPeriod
      DEBUG:        runtime.collector.debug
      LOG_LEVEL:    runtime.collector.logLevel
      LOG_FORMAT:   runtime.collector.logFormat
    }
  }
}