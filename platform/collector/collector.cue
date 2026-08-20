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
    // Image
    image: runtime.collector.image

    // Replicas
    replicaCount: runtime.collector.replicaCount

    // OpenMeter (native output)
    openmeter: {
      url:   runtime.openmeter.url
      token: string @timoni(runtime:string:OPENMETER_TOKEN)
    }

    // Config selection (upstream precedence: config > configFile > preset)
    config: {
      output: {
        switch: {
          cases: [
            // Case 1: Economic path (OpenMeter)
            {
              check: ""
              continue: true
              output: {
                openmeter: {
                  url:   runtime.openmeter.url
                  token: string @timoni(runtime:string:OPENMETER_TOKEN)
                  batching: {
                    count: 100
                    period: "1s"
                  }
                }
              }
            }
            // Case 2: Archive path — best-effort, non-blocking
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
            }
            // Case 3: Debug (preserved from preset)
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
    configFile: runtime.collector.configFile
    preset:     runtime.collector.preset

    // Service
    service: runtime.collector.service

    // Auth / identity
    imagePullSecrets: runtime.collector.imagePullSecrets
    nameOverride:     runtime.collector.nameOverride
    fullnameOverride: runtime.collector.fullnameOverride

    // ServiceAccount / RBAC / LeaderElection
    serviceAccount: runtime.collector.serviceAccount
    rbac:           runtime.collector.rbac
    leaderElection: runtime.collector.leaderElection

    // Pod / container metadata & security
    podAnnotations:  runtime.collector.podAnnotations
    podLabels:       runtime.collector.podLabels
    podSecurityContext:  runtime.collector.podSecurityContext
    securityContext:     runtime.collector.securityContext

    // Resources / scheduling
    resources:      runtime.collector.resources
    nodeSelector:   runtime.collector.nodeSelector
    tolerations:    runtime.collector.tolerations
    affinity:       runtime.collector.affinity

    // Storage (PVC)
    storage: runtime.collector.storage

    // Volumes / volumeMounts (enables configFile)
    volumes:      runtime.collector.volumes
    volumeMounts: runtime.collector.volumeMounts

    // Env / envFrom
    env:      runtime.collector.env
    envFrom:  runtime.collector.envFrom

    // CA certs
    caRootCertificates: runtime.collector.caRootCertificates
  }
}