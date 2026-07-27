package main

collectorConfig: {
  logger: {
    level:  "${LOG_LEVEL:INFO}"
    format: "${LOG_FORMAT:json}"
    static_fields: {
      service: "welkin-collector"
    }
  }

  http: {
    enabled:         true
    address:         "0.0.0.0:4195"
    debug_endpoints: false
  }

  metrics: prometheus: add_process_metrics: true
  shutdown_timeout: "20s"

  pipeline: processors: [
    {
      mapping: "file://./resources/processors/canonicalize_kubernetes.blobl"
    },
    {
      resource: "welkin_validate_cloudevent"
    },
    {
      catch: [
        {
          log: {
            level:   "ERROR"
            message: "Dropping invalid canonical event due to: ${! error() }"
          }
        },
        {
          mapping: "root = deleted()"
        },
      ]
    },
  ]

  output: broker: {
    pattern: "fan_out"
    outputs: [
      {
        resource: "welkin_runtime_openmeter"
      },
      {
        drop_on: {
          back_pressure: "30s"
          output: resource: "welkin_archive_s3"
        }
      },
    ]
  }

  processor_resources: [
    {
      label: "welkin_validate_cloudevent"
      json_schema: schema_path: "file://./schemas/cloudevent.schema.json"
    },
  ]

  output_resources: [
    {
      label: "welkin_runtime_openmeter"
      openmeter: {
        url:   "${OPENMETER_URL:http://openmeter-api}"
        token: "${OPENMETER_TOKEN:}"
      }
    },
    {
      label: "welkin_archive_s3"
      aws_s3: {
        bucket: runtime.archive.bucket
        path:   "welkin/source=${! json(\"partition.source\") }/type=${! json(\"partition.eventType\") }/day=${! json(\"partition.day\") }/${! uuid_v4() }.parquet"
        endpoint:              runtime.archive.endpoint
        force_path_style_urls: runtime.archive.forcePathStyle
        region:                runtime.archive.region
        credentials: {
          id:     runtime.archive.accessKeyID
          secret: runtime.archive.secretAccessKey
        }
        processors: [
          {
            mapping: "file://./resources/processors/archive_partition.blobl"
          },
        ]
        batching: {
          count:  runtime.archive.batchCount
          period: runtime.archive.batchPeriod
          processors: [
            {
              parquet_encode: {
                schema: [
                  {
                    name: "partition"
                    fields: [
                      {name: "source", type: "UTF8"},
                      {name: "eventType", type: "UTF8"},
                      {name: "day", type: "UTF8"},
                    ]
                  },
                  {
                    name: "event"
                    fields: [
                      {name: "id", type: "UTF8"},
                      {name: "specversion", type: "UTF8"},
                      {name: "type", type: "UTF8"},
                      {name: "source", type: "UTF8"},
                      {name: "time", type: "UTF8"},
                      {name: "subject", type: "UTF8"},
                      {name: "data", type: "JSON"},
                    ]
                  },
                ]
                default_compression:    "zstd"
                default_timestamp_unit: "MICROSECOND"
              }
            },
          ]
        }
      }
    },
  ]
}

collectorValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "benthos-collector"
    version: runtime.charts.collectorVersion
  }
  sync: targetNamespace: runtime.namespace
  helmValues: {
    fullnameOverride: "openmeter-collector"
    preset:           runtime.collector.preset
    storage: enabled: true
    env: [
      {name: "OPENMETER_URL", value: runtime.openmeter.url},
      {name: "OPENMETER_TOKEN", value: runtime.openmeter.token},
      {name: "SCRAPE_NAMESPACE", value: runtime.collector.scrapeNamespace},
      {name: "SCRAPE_INTERVAL", value: runtime.collector.scrapeInterval},
      {name: "BATCH_SIZE", value: runtime.collector.batchSize},
      {name: "BATCH_PERIOD", value: runtime.collector.batchPeriod},
      {name: "DEBUG", value: runtime.collector.debug},
    ]
    config: collectorConfig
  }
}
