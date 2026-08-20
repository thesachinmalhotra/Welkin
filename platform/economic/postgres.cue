package main

postgresValues: {
  repository: url: "oci://registry-1.docker.io/bitnamicharts"
  chart: {
    name:    "postgresql"
    version: runtime.charts.postgresVersion
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
    timeout:         15
  }
  helmValues: {
    fullnameOverride: "postgres"
    auth: {
      username:             runtime.postgres.username
      password:             runtime.postgres.password
      postgresPassword:     runtime.postgres.postgresPassword
      database:             runtime.postgres.database
      enablePostgresUser:   false
    }
    primary: persistence: enabled: false
  }
}
