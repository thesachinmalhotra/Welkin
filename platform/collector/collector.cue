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
    image: runtime.collector.image

    openmeter: {
      url:   runtime.openmeter.url
      token: runtime.openmeter.token
    }

    config: {
      output: {
        switch: {
          cases: [
            {
              check: ""
              continue: true
              output: {
                openmeter: {
                  url:   runtime.openmeter.url
                  token: runtime.openmeter.token
                  batching: {
                    count: 100
                    period: "1s"
                  }
                }
              }
            },
            {
              check: ""
              continue: true
              output: {
                drop_on: {
                  error: true
                  back_pressure: "10s"
                  output: {
                    aws_s3: {
                      bucket: runtime.archive.bucket
                      path: "events/${!timestamp_unix()}-${!uuid_v4()}.parquet"
                      endpoint: runtime.archive.endpoint
                      force_path_style_urls: true
                      region: runtime.archive.region
                      credentials: {
                        id: runtime.archive.accessKeyId
                        secret: runtime.archive.secretAccessKey
                      }
                      max_in_flight: 1
                      batching: {
                        count: runtime.archive.batchCount
                        period: runtime.archive.batchPeriod
                        processors: [
                          {
                            parquet_encode: {
                              schema: [
                                {name: "id", type: "UTF8"}
                                {name: "specversion", type: "UTF8"}
                                {name: "type", type: "UTF8"}
                                {name: "source", type: "UTF8"}
                                {name: "time", type: "TIMESTAMP"}
                                {name: "subject", type: "UTF8"}
                                {name: "data", type: "BYTE_ARRAY"}
                              ]
                              default_compression: "zstd"
                              default_timestamp_unit: "MICROSECOND"
                            }
                          }
                        ]
                      }
                    }
                  }
                }
              }
            },
            {
              check: '"${DEBUG:false}" == "true"'
              output: {
                stdout: { codec: "lines" }
              }
            }
          ]
        }
      }
    }
  }
}