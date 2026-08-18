package main

minioValues: {
  repository: url: "oci://registry-1.docker.io/bitnamicharts"
  chart: {
    name:    "minio"
    version: "14.7.0"
  }
  sync: {
    targetNamespace: runtime.namespace
    createNamespace: true
    timeout:         15
  }
  helmValues: {
    fullnameOverride: "minio"
    image: {
      registry:   "docker.io"
      repository: "bitnamilegacy/minio"
      tag:        "2025.7.23-debian-12-r3"
    }
    clientImage: {
      registry:   "docker.io"
      repository: "bitnamilegacy/minio-client"
      tag:        "2025.7.21-debian-12-r2"
    }
    auth: {
      rootUser:     runtime.archive.accessKeyId
      rootPassword: runtime.archive.secretAccessKey
    }
    defaultBuckets: runtime.archive.bucket
    mode:           "standalone"
  }
}
