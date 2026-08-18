package main

collectorValues: {
  repository: url: "oci://ghcr.io/openmeterio/helm-charts"
  chart: {
    name:    "benthos-collector"
    version: runtime.charts.collectorVersion
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
  }
  helmValues: {
    // Image
    image: runtime.collector.image

    // Replicas
    replicaCount: runtime.collector.replicaCount

    // OpenMeter (native output)
    openmeter: {
      url:   runtime.openmeter.url
      token: string @timoni(runtime:string:OPENMETER_TOKEN)
    }

    // Config selection (upstream precedence: config > configFile > preset)
    config:     runtime.collector.config
    configFile: runtime.collector.configFile
    preset:     runtime.collector.preset

    // Service
    service: runtime.collector.service

    // Auth / identity
    imagePullSecrets: runtime.collector.imagePullSecrets
    nameOverride:     runtime.collector.nameOverride
    fullnameOverride: runtime.collector.fullnameOverride

    // ServiceAccount / RBAC / LeaderElection
    serviceAccount: runtime.collector.serviceAccount
    rbac:           runtime.collector.rbac
    leaderElection: runtime.collector.leaderElection

    // Pod / container metadata & security
    podAnnotations:  runtime.collector.podAnnotations
    podLabels:       runtime.collector.podLabels
    podSecurityContext:  runtime.collector.podSecurityContext
    securityContext:     runtime.collector.securityContext

    // Resources / scheduling
    resources:      runtime.collector.resources
    nodeSelector:   runtime.collector.nodeSelector
    tolerations:    runtime.collector.tolerations
    affinity:       runtime.collector.affinity

    // Storage (PVC)
    storage: runtime.collector.storage

    // Volumes / volumeMounts (enables configFile)
    volumes:      runtime.collector.volumes
    volumeMounts: runtime.collector.volumeMounts

    // Env / envFrom
    env:      runtime.collector.env
    envFrom:  runtime.collector.envFrom

    // CA certs
    caRootCertificates: runtime.collector.caRootCertificates
  }
}