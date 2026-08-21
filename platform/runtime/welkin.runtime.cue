package main

runtime: {
  namespace: *"welkin-system" | string @timoni(runtime:string:WELKIN_NAMESPACE)

  charts: {
    fluxAioVersion:    "2.9.4-0"
    fluxModuleVersion: "2.9.4-0"
    openmeterVersion:  "1.0.0-beta.232"
    collectorVersion:  "1.0.0-beta.232"
    postgresVersion:   "16.7.13"
  }

  openmeter: {
    url:    *"http://openmeter-api" | string @timoni(runtime:string:OPENMETER_URL)
    token:  *"changeme" | string @timoni(runtime:string:OPENMETER_TOKEN)
    meters: "" @timoni(runtime:string:OPENMETER_METERS_CONFIG)
  }

  postgres: {
    username:         *"application" | string @timoni(runtime:string:POSTGRES_USERNAME)
    password:         *"application" | string @timoni(runtime:string:POSTGRES_PASSWORD)
    database:         *"application" | string @timoni(runtime:string:POSTGRES_DATABASE)
    postgresPassword: *"application" | string @timoni(runtime:string:POSTGRES_ADMIN_PASSWORD)
  }

  collector: {
    image: *"ghcr.io/openmeterio/benthos-collector:v1.0.0-beta.232" | string
  }

  archive: {
    endpoint:         *"http://minio.welkin-system.svc.cluster.local:9000" | string
    bucket:           *"welkin-archive" | string @timoni(runtime:string:ARCHIVE_S3_BUCKET)
    region:           *"us-east-1" | string
    forcePathStyle:   *true | bool
    accessKeyId:      *"minio" | string @timoni(runtime:string:ARCHIVE_S3_ACCESS_KEY_ID)
    secretAccessKey:  *"minio123" | string @timoni(runtime:string:ARCHIVE_S3_SECRET_ACCESS_KEY)
    batchCount:       *250 | int
    batchPeriod:      *"15s" | string
  }
}