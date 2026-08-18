package main

postgresValues: {
  repository: url: "oci://registry-1.docker.io/bitnamicharts"
  chart: {
    name:    "postgresql"
    version: "16.7.13"
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
    timeout:         15
  }
  helmValues: {
    fullnameOverride: "postgres"
    image: {
      registry:   "docker.io"
      repository: "bitnamilegacy/postgresql"
      tag:        "17.5.0-debian-12-r12"
    }
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
