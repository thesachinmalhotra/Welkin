package main

minioValues: {
  repository: url: "oci://registry-1.docker.io/bitnamicharts"
  chart: {
    name:    "minio"
    version: "14.9.2"
  }
  sync: {
    targetNamespace: runtime.namespace
    timeout:         15
  }
  helmValues: {
    fullnameOverride: "minio"
    auth: {
      rootUser:     "minio"
      rootPassword: "minio123"
    }
    defaultBuckets: "welkin-archive"
    mode:           "standalone"
  }
}
