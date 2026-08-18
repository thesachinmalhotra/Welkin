package main

runtime: {
  namespace: "welkin-system"

  charts: {
    fluxAioVersion:    "2.9.4-0" // stefanprodan/flux-aio v2.9.4-0 (Flux v2.9.4, Timoni v0.30.0)
    fluxModuleVersion: "2.9.4-0" // stefanprodan/flux-helm-release v2.9.4-0 (sync.createNamespace support)
    openmeterVersion:  "1.0.0-beta.232" // pinned to OpenMeter release v1.0.0-beta.232 (chart digest: sha256:084f4eb0947daf948583ea07945241583d5ef40a5ae1da8d9f9caedf62878dc3)
    collectorVersion:  "1.0.0-beta.232" // chart appVersion v1.0.0-beta.232 -> image ghcr.io/openmeterio/benthos-collector:v1.0.0-beta.232 (amd64 digest: sha256:4a816108919b77d35209ad9053dca417897bfc463cd6c13ff71262ad35103119)
  }

  openmeter: {
    url: "http://openmeter-api"
  }

  collector: {
    // Image
    image: {
      repository: "ghcr.io/openmeterio/benthos-collector"
      pullPolicy: "IfNotPresent"
      tag:        ""
    }

    // Replicas
    replicaCount: 1

    // Config selection (upstream precedence: config > configFile > preset)
    // config: arbitrary Redpanda Connect config to use any of the 65+ connectors, e.g.
    //   config: { input: { kafka: { addresses: ["..."] } } }
    config:     {}
    configFile: ""
    preset:     "kubernetes-pod-exec-time"

    // OpenMeter (native output)
    // openmeter.url and openmeter.token are set at top-level runtime.openmeter

    // Service
    service: {
      enabled:    false
      type:       "ClusterIP"
      port:       80
      annotations: {}
    }

    // Auth / identity
    imagePullSecrets: []
    nameOverride:     ""
    fullnameOverride: "openmeter-collector"

    // ServiceAccount
    serviceAccount: {
      create:      true
      automount:   true
      annotations: {}
      name:        ""
    }

    // RBAC
    rbac: {
      create: true
    }

    // LeaderElection
    leaderElection: {
      enabled: false
      lease: {
        duration:     "10s"
        renewDeadline: "5s"
        retryPeriod:   "2s"
      }
    }

    // Pod metadata
    podAnnotations: {}
    podLabels:      {}

    // Security
    podSecurityContext: {}
    securityContext:    {}

    // Resources
    resources: {}

    // Scheduling
    nodeSelector: {}
    tolerations:  []
    affinity:     {}

    // Storage (PVC)
    storage: {
      enabled:      false
      annotations:  {}
      labels:       {}
      selector:     {}
      accessModes:  ["ReadWriteOnce"]
      size:         "1Gi"
      mountPath:    "/data"
      storageClass: ""
    }

    // Volumes / volumeMounts (enables configFile)
    volumes:      []
    volumeMounts: []

    // Env / envFrom
    env:      {}
    envFrom:  []

    // CA certs
    caRootCertificates: {}

    // Legacy env passthrough (preserved for backward compat with old collector env vars)
    scrapeNamespace: ""
    scrapeInterval:  "15s"
    batchSize:       "100"
    batchPeriod:     "1s"
    debug:           "false"
    serviceEnabled:  false
    storageEnabled:  true
    storageSize:     "1Gi"
    bufferPath:      "/data/buffer.db"
    logLevel:        "INFO"
    logFormat:       "json"
    shutdownDelay:   "5s"
    shutdownTimeout: "20s"
  }

  archive: {
    endpoint:       *     "http://minio.welkin-system.svc.cluster.local:9000" | string
    bucket:         string @timoni(runtime:string:ARCHIVE_S3_BUCKET)
    region:         "us-east-1"
    forcePathStyle: true
    batchCount:     250
    batchPeriod:    "15s"
  }
}