package main

openmeterValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "openmeter"
    version: runtime.charts.openmeterVersion
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
    timeout:         15
  }
  helmValues: {
    postgresql: {
      enabled: false
    }
    svix: {
      enabled: false
    }
    config: {
      postgres: {
        // References the composed Postgres instance (platform/economic/postgres.cue)
        // Service name is set via helmValues.fullnameOverride: "postgres"
        url: "postgres://\(runtime.postgres.username):\(runtime.postgres.password)@postgres:5432/\(runtime.postgres.database)?sslmode=disable"
      }
      meters: [
      {
        slug:          "kubernetes-pod-exec-time"
        description:   "Kubernetes pod exec time"
        eventType:     "kube-pod-exec-time"
        valueProperty: "$.duration_seconds"
        aggregation:   "SUM"
        groupBy: {
          pod_name:      "$.pod_name"
          pod_namespace: "$.pod_namespace"
        }
      },
    ]
    }
  }
}
