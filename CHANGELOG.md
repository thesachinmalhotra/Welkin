# Changelog

All notable changes to Welkin will be documented in this file.

This changelog is auto-generated from [Conventional Commits](https://www.conventionalcommits.org/).
Format: [Keep a Changelog](https://keepachangelog.com/) + [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

### Added

- **ci:** add pinning-guard workflow to prevent unpinned `latest` and wildcard patterns
- **ci:** add pin-verify workflow to validate GHCR chart+image digests
- **ci:** pin kubectl to v1.36.3 in certification-run workflow
- **ci:** trigger validate rerun; retrigger for diagnostics
- **ci(pinning):** verify chart package appVersion and image digest for OpenMeter benthos-collector
- **certification:** implement end-to-end canonical-flow assertions
- **certification:** capture deployment/pod diagnostics on failure
- **docs:** add Welkin production readiness contract
- **docs:** add production readiness diagnostic protocol
- **docs:** add implementation-is-not-architecture law to AGENTS.md
- **docs(ci):** mark rpk as test-only tooling and clarify OpenMeter Collector runtime vs rpk
- **feat:** assemble welkin v1 substrate
- **feat:** add certification pipeline
- **feat(secrets):** wire Timoni Runtime API for fail-closed secret resolution
- **feat(collector):** inline Benthos config, remove configFile dependency
- **pin(openmeter):** set OpenMeter/collector defaults to v1.0.0-beta.232
- **pin(collector):** reference benthos-collector OCI chart by digest for immutability
- **pin(flux-modules):** annotate flux-aio and flux-helm-release v2.5.0-0 with GHCR digests
- **test:** add root schemas/cloudevent.schema.json for rpk tests
- **test(rpk):** target pipeline processors so json_schema errors are handled by pipeline catch
- **test(rpk):** align malformed-event expectation with rpk output

### Fixed

- **cert:** normalize scenario refs to public ids for catalog validation
- **cert:** normalize remaining scenario refs to public ids
- **cert:** provision own postgres, disable chart-managed postgresql
- **cert:** add sslmode=disable to postgres URL in OpenMeter config
- **cert:** disable svix in OpenMeter Helm values
- **cert:** port 8888 to 80 for Helm chart, add missing malformed-boundary scenario
- **cert:** disable PostgreSQL SSL in OpenMeter Helm values
- **cert:** wire event data flow through HTTP ingestion, real meter assertion
- **cert:** capture OpenMeter logs before pod eviction
- **fix:** remove windowSize, add groupBy to openmeter meter definition
- **fix:** set HelmRelease timeout to 15m for OpenMeter chart
- **fix:** increase timoni apply timeout to 15m
- **fix:** add GOPATH/bin to PATH in certification workflow
- **certification:** create networked ClickHouse user for OpenMeter
- **certification:** make ClickHouse default user passwordless
- **certification:** provision ClickHouse for OpenMeter aggregation
- **certification:** advertise Redpanda kafka addr via service DNS
- **certification:** provision Kafka for OpenMeter in harness
- **certification:** prefix meter valueProperty with `$`
- **certification:** supply openmeter subcommand to entrypoint
- **certification:** use v-prefixed OpenMeter image tag in harness
- **collector:** convert archive forcePathStyle to string and avoid `.string()` on unions
- **collector:** use CUE if/else to render forcePathStyle as string
- **collector:** pass ARCHIVE_S3_FORCE_PATH_STYLE as bool to avoid CUE parse complexity
- **openmeter:** add missing description field to meter definition

### Changed

- **refactor:** rename cue and collector directories to contracts and engine
- **chore(pinning):** replace latest/wildcard refs with explicit pins (timoni v0.30.0, cue v0.4.0, rpk v26.2.1, ubuntu-22.04)
- **docs(plan):** record pinning progress for OpenMeter (v1.0.0-beta.232)
- **docs(plan):** record completed pin steps and next actions for iteration-1
- **ci(validate):** make rpk tests use test-friendly collector config

### Removed

- **certification:** remove unused MinIO PVC from run_scenario

## [0.1.0] - 2026-07-27

### Added

- Initial Welkin substrate assembly
- Canonical CloudEvent contract and schema
- OpenMeter + collector Helm chart composition via Timoni
- Flux AIO + HelmRelease distribution
- Certification catalog with guarantees and scenarios
- CI workflows: validate, certification-suite, certification-run, ephemeral-smoke, pinning-guard, pin-verify
