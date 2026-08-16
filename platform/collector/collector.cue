package main

// Collector behavior is defined inline here as a CUE map.
// The chart renders `config` as a Secret at /etc/benthos/config.yaml.
// Schema and Bloblang resources are inlined (no file:// dependencies).
// Environment State is supplied via env vars and @timoni runtime attributes.

collectorValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    // Use an OCI chart reference with digest for immutability. Flux/HelmRelease accepts OCI chart references
    // of the form: oci://ghcr.io/openmeterio/helm-charts/benthos-collector@sha256:<digest>
    // Chart digest (immutable) for v1.0.0-beta.232:
    // sha256:bf2afa50f4ccf43ae05a689d65330d3181af75054658163b33e25b862a4a7841
    name:    "oci://ghcr.io/openmeterio/helm-charts/benthos-collector@sha256:bf2afa50f4ccf43ae05a689d65330d3181af75054658163b33e25b862a4a7841"
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
      {name: "OPENMETER_TOKEN", value: string @timoni(runtime:string:OPENMETER_TOKEN)},

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
      {name: "ARCHIVE_S3_FORCE_PATH_STYLE", value: runtime.archive.forcePathStyle },
      {name: "ARCHIVE_S3_REGION", value: runtime.archive.region},
      {name: "ARCHIVE_S3_ACCESS_KEY_ID", value: string @timoni(runtime:string:ARCHIVE_S3_ACCESS_KEY_ID)},
      {name: "ARCHIVE_S3_SECRET_ACCESS_KEY", value: string @timoni(runtime:string:ARCHIVE_S3_SECRET_ACCESS_KEY)},
      {name: "ARCHIVE_BATCH_COUNT", value: runtime.archive.batchCount},
      {name: "ARCHIVE_BATCH_PERIOD", value: runtime.archive.batchPeriod},
    ]
    config: {
      logger: {
        level:           "${LOG_LEVEL:INFO}"
        format:          "${LOG_FORMAT:json}"
        static_fields: {
          service:  "welkin-collector"
          instance: "${K8S_APP_INSTANCE:}"
          version:  "${K8S_APP_VERSION:}"
        }
      }
      http: {
        enabled:         true
        address:         "0.0.0.0:4195"
        debug_endpoints: false
      }
      input: {
        http_server: {
          path: "/events"
        }
      }
      metrics: {
        prometheus: {
          add_process_metrics: true
        }
      }
      shutdown_delay:   "${SHUTDOWN_DELAY:5s}"
      shutdown_timeout: "${SHUTDOWN_TIMEOUT:20s}"
      pipeline: {
        processors: [
          {resource: "welkin_validate_cloudevent"},
          {catch: [
            {log: {level: "ERROR", message: "Dropping invalid canonical event due to: ${! error() }"}},
            {mapping: "root = deleted()"},
          ]},
        ]
      }
      output: {
        broker: {
          pattern: "fan_out"
          outputs: [
            {resource: "welkin_economic_openmeter"},
            {drop_on: {back_pressure: "30s", output: {resource: "welkin_archive_s3"}}},
          ]
        }
      }
      processor_resources: [
        {label: "welkin_validate_cloudevent", json_schema: {schema: """
          {
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "$id": "https://welkin.dev/schema/cloudevent.json",
            "title": "WelkinCanonicalCloudEvent",
            "type": "object",
            "required": ["id", "specversion", "type", "source", "time", "subject", "data"],
            "properties": {
              "id": { "type": "string", "minLength": 1 },
              "specversion": { "const": "1.0" },
              "type": { "type": "string", "minLength": 1 },
              "source": { "type": "string", "minLength": 1 },
              "time": { "type": "string", "minLength": 1 },
              "subject": { "type": "string", "minLength": 1 },
              "data": { "type": "object" }
            },
            "additionalProperties": true
          }
          """}},
      ]
      output_resources: [
        {label: "welkin_economic_openmeter", openmeter: {url: "${OPENMETER_URL:http://openmeter-api}", token: "${OPENMETER_TOKEN:}"}},
        {label: "welkin_archive_s3", aws_s3: {
          bucket:                "${ARCHIVE_S3_BUCKET:welkin-archive}"
          path:                  "welkin/source=${! json(\"partition.source\") }/type=${! json(\"partition.eventType\") }/day=${! json(\"partition.day\") }/${! uuid_v4() }.parquet"
          endpoint:              "${ARCHIVE_S3_ENDPOINT:http://minio.minio.svc.cluster.local:9000}"
          force_path_style_urls: "${ARCHIVE_S3_FORCE_PATH_STYLE:true}"
          region:                "${ARCHIVE_S3_REGION:us-east-1}"
          credentials:           {id: "${ARCHIVE_S3_ACCESS_KEY_ID:}", secret: "${ARCHIVE_S3_SECRET_ACCESS_KEY:}"}
          processors: [{mapping: """
            root = {
              "partition": {
                "source": this.source,
                "eventType": this.type,
                "day": this.time.string().slice(0, 10)
              },
              "event": this
            }
            """}]
          batching: {
            count:  "${ARCHIVE_BATCH_COUNT:250}"
            period: "${ARCHIVE_BATCH_PERIOD:15s}"
            processors: [{parquet_encode: {
              schema: [
                {name: "partition", fields: [
                  {name: "source", type: "UTF8"},
                  {name: "eventType", type: "UTF8"},
                  {name: "day", type: "UTF8"},
                ]},
                {name: "event", fields: [
                  {name: "id", type: "UTF8"},
                  {name: "specversion", type: "UTF8"},
                  {name: "type", type: "UTF8"},
                  {name: "source", type: "UTF8"},
                  {name: "time", type: "UTF8"},
                  {name: "subject", type: "UTF8"},
                  {name: "data", type: "JSON"},
                ]},
              ]
              default_compression:    "zstd"
              default_timestamp_unit: "MICROSECOND"
            }}]
          }
        }},
      ]
    }
  }
}
