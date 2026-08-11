package main

// Collector behavior is defined by a single source of truth:
// `engine/config/base.yaml`.
//
// Timoni/Helm supplies Environment State via env vars and chart values.

// NOTE: We use `configFile` rather than inline `config` to keep a single
// authoritative collector config in `engine/config/base.yaml`.
collectorValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "benthos-collector"
    version: runtime.charts.collectorVersion
  }
  sync: targetNamespace: runtime.namespace
  helmValues: {
    fullnameOverride: "openmeter-collector"
    // With configFile set, the chart ignores preset.
    // Keep this value for documentation/discoverability.
    preset:           runtime.collector.preset

  // Pin the container image tag to the chart appVersion (collectorVersion)
  // Chart digest (immutable): sha256:bf2afa50f4ccf43ae05a689d65330d3181af75054658163b33e25b862a4a7841
  // Image digests (immutable): amd64 sha256:4a816108919b77d35209ad9053dca417897bfc463cd6c13ff71262ad35103119
  //                                    arm64 sha256:d2d0f2d54ae51e129bf1add6be78aa0e0e2114b39980979db95c815eca059d5e
  // Recommended Platform State pin: use chart OCI digest + trust the packaged chart templates to select the correct image tag.

  image: {
    repository: "ghcr.io/openmeterio/benthos-collector"
    tag: runtime.charts.collectorVersion
  }

    service: enabled: runtime.collector.serviceEnabled
    storage: {
      enabled: runtime.collector.storageEnabled
      size:    runtime.collector.storageSize
    }

    env: [
      // OpenMeter destination.
      {name: "OPENMETER_URL", value: runtime.openmeter.url},
      {name: "OPENMETER_TOKEN", value: runtime.openmeter.token},

      // Kubernetes preset knobs (still used by our mapping and/or underlying input).
      {name: "SCRAPE_NAMESPACE", value: runtime.collector.scrapeNamespace},
      {name: "SCRAPE_INTERVAL", value: runtime.collector.scrapeInterval},

      // Batching knobs.
      {name: "BATCH_SIZE", value: runtime.collector.batchSize},
      {name: "BATCH_PERIOD", value: runtime.collector.batchPeriod},

      // Debug.
      {name: "DEBUG", value: runtime.collector.debug},

      // Buffering and lifecycle.
      {name: "BUFFER_PATH", value: runtime.collector.bufferPath},
      {name: "SHUTDOWN_DELAY", value: runtime.collector.shutdownDelay},
      {name: "SHUTDOWN_TIMEOUT", value: runtime.collector.shutdownTimeout},

      // Logging.
      {name: "LOG_LEVEL", value: runtime.collector.logLevel},
      {name: "LOG_FORMAT", value: runtime.collector.logFormat},

      // Identity fields used in structured logs.
      {name: "K8S_APP_INSTANCE", value: "openmeter-collector"},
      {name: "K8S_APP_VERSION", value: runtime.charts.collectorVersion},

      // Archive output.
      {name: "ARCHIVE_S3_BUCKET", value: runtime.archive.bucket},
      {name: "ARCHIVE_S3_ENDPOINT", value: runtime.archive.endpoint},
      {name: "ARCHIVE_S3_FORCE_PATH_STYLE", value: (runtime.archive.forcePathStyle == true) ? "true" : "false"},
      {name: "ARCHIVE_S3_REGION", value: runtime.archive.region},
      {name: "ARCHIVE_S3_ACCESS_KEY_ID", value: runtime.archive.accessKeyID},
      {name: "ARCHIVE_S3_SECRET_ACCESS_KEY", value: runtime.archive.secretAccessKey},
      {name: "ARCHIVE_BATCH_COUNT", value: runtime.archive.batchCount},
      {name: "ARCHIVE_BATCH_PERIOD", value: runtime.archive.batchPeriod},
    ]
    configFile: "welkin/config/base.yaml"
  }
}
