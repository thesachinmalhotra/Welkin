# Environment Promotion

Welkin separates **what a release is** (immutable product artifact) from
**where it runs** (environment configuration).

## The rule

Staging and production run the **exact same OCI digest**. Promotion is moving
a digest reference between environment files — never rebuilding.

## Artifact identity

Every `v*` tag triggers `release.yaml`, which:

1. Vets the composition (`make vet-prod`)
2. Pushes `platform/` as an OCI artifact to
   `ghcr.io/<owner>/welkin:<version>`
3. Signs it with cosign (keyless, GitHub OIDC)
4. Verifies the signature

The immutable identity is the digest (e.g. `sha256:abc...`), printed in the
release logs. Tags are conveniences; the digest is the contract.

## Promoting

After a release, record the digest per environment:

```
environments/staging/artifact.txt     → sha256:<staging digest>
environments/production/artifact.txt  → sha256:<production digest>
```

Promotion flow:

1. Tag the release (`git tag v1.x.y && git push --tags`) — CI builds, signs,
   verifies once.
2. Copy the digest into `environments/staging/artifact.txt` and deploy staging
   with that digest plus staging's runtime configuration.
3. Promote to production by opening a PR that changes
   `environments/production/artifact.txt` from the staging digest to the new
   one. Same bytes, human gate, full audit trail in git history.

A production deploy must always resolve to a digest — never a mutable tag.

## Environment configuration

Runtime configuration (namespace, endpoints, credentials, storage locations)
is supplied at apply time via Timoni runtime attributes — see
`platform/runtime/welkin.runtime.cue`. It is never baked into the artifact.
