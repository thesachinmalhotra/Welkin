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
      // Bundled Postgres via the chart's own subchart; the chart computes and
      // overwrites config.postgres.url itself.
      values: openmeterValues & {helmValues: postgresql: {enabled: true}}
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
