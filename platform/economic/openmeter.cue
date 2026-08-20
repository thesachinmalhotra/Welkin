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
    // Redis is optional in OpenMeter (used only for svix webhooks and
    // distributed dedup/query progress; svix is disabled and dedup defaults
    // to in-process memory). Disabling it removes the master + replica pods
    // from the kind node.
    redis: {
      enabled: false
    }
    // Lean CI footprint: the canonical-flow certification asserts the meter
    // value, which only requires API + Kafka + sink worker + ClickHouse +
    // Postgres. Balance/Billing/Notification are off the ingestion path, so
    // scale them to zero here (Environment State) to keep the kind node from
    // starving on a 2-core GitHub runner.
    balanceWorker: {
      replicaCount: 0
    }
    billingWorker: {
      replicaCount: 0
    }
    notificationService: {
      replicaCount: 0
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
