package main

openmeterValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "openmeter"
    version: runtime.charts.openmeterVersion
  }
  sync: targetNamespace: runtime.namespace
  helmValues: {}
}
