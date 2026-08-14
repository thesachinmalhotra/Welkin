package main

openmeterValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "openmeter"
    version: runtime.charts.openmeterVersion
  }
  sync: {
    targetNamespace: runtime.namespace
    timeout:         15
  }
  helmValues: {
    config: meters: [
      {
        slug:          "kubernetes-pod-exec-time"
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
