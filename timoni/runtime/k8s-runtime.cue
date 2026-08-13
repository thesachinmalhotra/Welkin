package main

runtime: {
  apiVersion: "v1alpha1"
  name:       "welkin"
  values: [
    {
      query: "k8s:v1:Secret:welkin-system:welkin-collector-secrets"
      for: {
        "OPENMETER_TOKEN":              "obj.data.OPENMETER_TOKEN"
        "ARCHIVE_S3_ACCESS_KEY_ID":     "obj.data.ARCHIVE_S3_ACCESS_KEY_ID"
        "ARCHIVE_S3_SECRET_ACCESS_KEY": "obj.data.ARCHIVE_S3_SECRET_ACCESS_KEY"
      }
    },
  ]
}
