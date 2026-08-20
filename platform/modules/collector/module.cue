module: {
  name: "collector"
  version: "1.0.0"
  description: "OpenMeter Collector substrate module"
  schema: {
    openmeterUrl: string
    openmeterToken: string
  }
}

params: {
  openmeterUrl: string
  openmeterToken: string
}

instances: {
  collector: {
    module: "ghcr.io/openmeterio/helm-charts/benthos-collector:1.0.0-beta.232"
    values: {
      openmeter: {
        url: params.openmeterUrl
        token: params.openmeterToken
      }
    }
  }
}