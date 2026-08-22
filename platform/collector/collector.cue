package main

collectorValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "benthos-collector"
    version: product.charts.collectorVersion
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
  }
  helmValues: {
    // Match upstream quickstart naming so the Service DNS name is
    // openmeter-collector.<namespace>.svc.
    fullnameOverride: "openmeter-collector"

    image: product.collectorImage

    // Expose the event input (container port "http" = 8080) as a Service.
    service: {
      enabled: true
      port:    8080
    }

    // Persistent volume for the sqlite buffer (/data).
    storage: enabled: true

    openmeter: {
      url:   runtime.openmeter.url
      token: runtime.openmeter.token
    }

    // The chart treats `config` as all-or-nothing (config > configFile >
    // preset), so input, validation, buffer and outputs are composed here,
    // following upstream's documented manual configuration shape.
    //
    // SYNC POLICY: This config mirrors the pinned upstream preset
    // `http-server` from benthos-collector chart v1.0.0-beta.232.
    // Check upstream release notes on every chart version bump.
    config: {
      http: {
        enabled:         true
        address:         "0.0.0.0:4195"
        debug_endpoints: false
      }

      input: {
        http_server: {
          address:       "0.0.0.0:8080"
          path:          "/api/v1/events"
          allowed_verbs: ["POST"]
          timeout:       "10s"
          sync_response: {
            status: "${! meta(\"http_status_code\").or(\"204\") }"
            headers: {
              "Content-Type": "${! meta(\"content_type\").or(\"application/json\") }"
            }
          }
          processors: [
            {
              metric: {
                type:  "counter"
                name:  "openmeter_event_received"
                value: "1"
              }
            },
            {
              label: "validation"
              json_schema: {
                schema_path: "file:///etc/benthos/cloudevents.spec.json"
              }
            },
            {
              catch: [{
                log: {
                  level:          "ERROR"
                  message:        "schema validation failed due to: ${!error()}"
                  fields_mapping: "root = this"
                }
              }, {
                mapping: """
                  meta http_status_code = "400"
                  meta content_type = "application/problem+json"

                  root = {
                    "type": "about:blank",
                    "title": "Bad Request",
                    "status": 400,
                    "detail": "invalid event: %s".format(error()),
                  }
                  """
              }, {
                sync_response: {}
              }, {
                mapping: "root = deleted()"
              }]
            },
            {
              mapping: """
                meta http_status_code = "204"
                """
            },
            {
              sync_response: {}
            },
          ]
        }
      }

      buffer: {
        sqlite: {
          path: "/data/buffer.db"
          post_processors: [{
            split: {size: 100}
          }]
        }
      }

      output: {
        switch: {
          cases: [
            {
              check:    ""
              continue: true
              output: {
                label: "openmeter"
                drop_on: {
                  error:          false
                  error_patterns: ["Bad Request"]
                  output: {
                    http_client: {
                      url:  "\(runtime.openmeter.url)/api/v1/events"
                      verb: "POST"
                      headers: {
                        Authorization: "Bearer \(runtime.openmeter.token)"
                        "Content-Type": "application/json"
                      }
                      timeout:            "30s"
                      retry_period:       "15s"
                      retries:            3
                      max_retry_backoff:  "1m"
                      max_in_flight:      64
                      batch_as_multipart: false
                      drop_on: [400]
                      batching: {
                        count:  100
                        period: "1s"
                        processors: [{
                          metric: {
                            type:  "counter"
                            name:  "openmeter_events_sent"
                            value: "1"
                          }
                        }, {
                          archive: {format: "json_array"}
                        }]
                      }
                    }
                  }
                }
              }
            },
            {
              check:    ""
              continue: true
              output: {
                drop_on: {
                  error:        true
                  back_pressure: "10s"
                  output: {
                    aws_s3: {
                      bucket:               runtime.archive.bucket
                      path:                 "events/${!timestamp_unix()}-${!uuid_v4()}.parquet"
                      endpoint:             runtime.archive.endpoint
                      force_path_style_urls: runtime.archive.forcePathStyle
                      region:               runtime.archive.region
                      credentials: {
                        id:     runtime.archive.accessKeyId
                        secret: runtime.archive.secretAccessKey
                      }
                      max_in_flight: 1
                      batching: {
                        count:  product.archive.batchCount
                        period: product.archive.batchPeriod
                        // Archive subset of CloudEvent — 7 fields, not full spec.
                        processors: [{
                          parquet_encode: {
                            schema: [
                              {name: "id",          type: "UTF8"},
                              {name: "specversion", type: "UTF8"},
                              {name: "type",        type: "UTF8"},
                              {name: "source",      type: "UTF8"},
                              {name: "time",        type: "TIMESTAMP"},
                              {name: "subject",     type: "UTF8"},
                              {name: "data",        type: "BYTE_ARRAY"},
                            ]
                            default_compression:   "zstd"
                            default_timestamp_unit: "MICROSECOND"
                          }
                        }]
                      }
                    }
                  }
                }
              }
            },
            {
              check:  "\"${DEBUG:false}\" == \"true\""
              output: {stdout: {codec: "lines"}}
            },
          ]
        }
      }

      metrics: {
        prometheus: {
          add_process_metrics: true
        }
      }
    }
  }
}
