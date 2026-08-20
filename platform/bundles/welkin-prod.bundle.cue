// Production bundle: requires managed Postgres and managed S3. See docs/architecture.md.
//
// The archive plane (S3) is controlled via ARCHIVE_S3_ENDPOINT runtime injection
// in collector.cue. The collector writes directly to the S3 endpoint; MinIO is
// not required in prod.

package main

bundle: {
  apiVersion: "v1alpha1"
  name:       "welkin"
  instances: {
    flux: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-aio"
        version: runtime.charts.fluxAioVersion
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

    openmeter: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
        version: runtime.charts.fluxModuleVersion
      }
      namespace: "flux-system"
      values: openmeterValues
    }

    collector: {
      module: {
        url:     "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
        version: runtime.charts.fluxModuleVersion
      }
      namespace: "flux-system"
      values: collectorValues
    }
  }
}
