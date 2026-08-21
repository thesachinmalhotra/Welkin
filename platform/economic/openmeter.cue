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
    config: {
      postgres: {
        url: "postgres://\(runtime.postgres.username):\(runtime.postgres.password)@\(runtime.postgres.host):5432/\(runtime.postgres.database)?sslmode=disable"
      }
      meters: meterCatalog
    }
  }
}