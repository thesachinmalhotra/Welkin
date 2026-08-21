package main

bundle: {
  apiVersion: "v1alpha1"
  name:       "welkin"
  instances: {
    flux: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-aio"
        version: product.charts.fluxAioVersion
      }
      namespace: "flux-system"
      values: {
        controllers: {
          helm:         enabled: true
          kustomize:    enabled: true
          notification: enabled: true
        }
        hostNetwork:     false
        securityProfile: "privileged"
      }
    }

    postgres: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
        version: product.charts.fluxModuleVersion
      }
      namespace: "flux-system"
      values: postgresValues
    }

    minio: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
        version: product.charts.fluxModuleVersion
      }
      namespace: "flux-system"
      values: minioValues
    }

    openmeter: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
        version: product.charts.fluxModuleVersion
      }
      namespace: "flux-system"
      values: openmeterValues
    }

    collector: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
        version: product.charts.fluxModuleVersion
      }
      namespace: "flux-system"
      values: collectorValues
    }
  }
}
