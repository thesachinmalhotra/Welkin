package main

postgresValues: {
  repository: url: "oci://registry-1.docker.io/bitnamicharts"
  chart: {
    name:    "postgresql"
    version: "16.4.12"
  }
  sync: {
    targetNamespace: runtime.namespace
    timeout:         15
    disableWait:     true
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
    primary: {
      persistence: enabled: false
      containerSecurityContext: enabled: false
      livenessProbe: enabled: false
      readinessProbe: enabled: false
    }
    volumePermissions: enabled: false
    metrics: disabled: true
    networkPolicy: enabled: false
    resourcesPreset: "none"
  }
}
