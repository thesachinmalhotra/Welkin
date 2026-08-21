package main

// Welkin Runtime — the environment API.
// Answers exactly one question: "how does this Welkin release run HERE?"
// Only genuinely environment-specific values: namespace, external endpoints,
// credentials, storage locations, capacity. Product definition lives in
// platform/product.cue.

runtime: {
  namespace: *"welkin-system" | string @timoni(runtime:string:WELKIN_NAMESPACE)

  openmeter: {
    url:   *"http://openmeter-api" | string @timoni(runtime:string:OPENMETER_URL)
    token: *"changeme" | string @timoni(runtime:string:OPENMETER_TOKEN)
  }

  postgres: {
    host:             *"postgres" | string @timoni(runtime:string:POSTGRES_HOST)
    username:         *"application" | string @timoni(runtime:string:POSTGRES_USERNAME)
    password:         *"application" | string @timoni(runtime:string:POSTGRES_PASSWORD)
    database:         *"application" | string @timoni(runtime:string:POSTGRES_DATABASE)
    postgresPassword: *"application" | string @timoni(runtime:string:POSTGRES_ADMIN_PASSWORD)
  }

  archive: {
    endpoint:        *"http://minio.welkin-system.svc.cluster.local:9000" | string @timoni(runtime:string:ARCHIVE_S3_ENDPOINT)
    bucket:          *"welkin-archive" | string @timoni(runtime:string:ARCHIVE_S3_BUCKET)
    region:          *"us-east-1" | string @timoni(runtime:string:ARCHIVE_S3_REGION)
    forcePathStyle:  *true | bool @timoni(runtime:string:ARCHIVE_S3_FORCE_PATH_STYLE)
    accessKeyId:     *"minio" | string @timoni(runtime:string:ARCHIVE_S3_ACCESS_KEY_ID)
    secretAccessKey: *"minio123" | string @timoni(runtime:string:ARCHIVE_S3_SECRET_ACCESS_KEY)
  }
}
