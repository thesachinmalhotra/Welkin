package main

postgresValues: {
  repository: url: "oci://registry-1.docker.io/bitnamicharts"
  chart: {
    name:    "postgresql"
    version: "16.7.13"
  }
  sync: {
    targetNamespace: runtime.namespace
    timeout:         15
  }
  helmValues: {
    fullnameOverride: "postgres"
    auth: {
      username:             "application"
      password:             "application"
      postgresPassword:     "application"
      database:             "application"
      enablePostgresUser:   false
    }
    primary: persistence: enabled: false
  }
}
