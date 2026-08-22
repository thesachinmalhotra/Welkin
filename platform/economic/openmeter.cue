package main

openmeterValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "openmeter"
    version: product.charts.openmeterVersion
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
    redis: {
      enabled: false
    }
    // ponytail: scale off-path workers to zero for kind/CI footprint; raise
    // when running real workloads (balance/billing/notification are off the
    // ingestion path — certification only needs api+kafka+sink+clickhouse+pg)
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
        url: "postgres://\(runtime.postgres.username):\(runtime.postgres.password)@\(runtime.postgres.host):5432/\(runtime.postgres.database)?sslmode=disable"
      }
      meters: meterCatalog
    }
  }
}