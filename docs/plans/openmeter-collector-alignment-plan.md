> **SUPERSEDED** — This plan's goal (make `engine/config/base.yaml` the canonical collector source) has been superseded by the Composition Restoration program (Phase 1). The file `engine/config/base.yaml` has been deleted. Collector config now lives only in `timoni/values/collector.cue`.

# Welkin OpenMeter Collector Alignment Plan

## Intent

Make Welkin feel native to OpenMeter Collector operational patterns by using existing OpenMeter Collector capabilities and chart conventions.

This is an implementation alignment effort, not an architecture redesign.

## Principles

- Prefer OpenMeter Collector documented patterns over ad-hoc Redpanda Connect layout decisions.
- Keep one canonical collector config source per behavior.
- Keep Timoni as the materialization surface, but model collector runtime knobs exactly where OpenMeter expects them.
- Strengthen reliability and certification evidence using built-in buffering, retries, deduplication, metrics, and logs.

## Current gaps (repo-specific)

1. Collector config is duplicated (`engine/config/base.yaml` and `timoni/values/collector.cue` inline config).
2. Resource files under `engine/resources/` exist but are not truly the source of truth for deployment materialization.
3. Buffering controls are not modeled explicitly as runtime contract fields (only hardcoded storage enablement).
4. Collector observability is enabled but not fully harvested as certification evidence.
5. Deduplication and duplicate-billing assurance are still planned but not implemented in collector pipeline.

## Phased implementation plan

### Phase 1 — Chart-surface parity and runtime contract hardening

Goal: Expose OpenMeter Collector chart/runtime controls directly and explicitly.

Changes:
- Add runtime collector fields for:
  - `serviceEnabled`
  - `storageEnabled`
  - `storageSize`
  - `bufferPath`
  - `logLevel`
  - `logFormat`
  - `shutdownDelay`
  - `shutdownTimeout`
- Wire these fields into `timoni/values/collector.cue` helm values and collector config.
- Add collector identity static fields in logs (`service`, `instance`, `version`) using env interpolation.

Outcome:
- Welkin runtime contract mirrors OpenMeter Collector operational knobs.
- No behavior redesign; only explicit and tunable deployment settings.

### Phase 2 — Single-source collector config

Goal: Remove drift risk by collapsing config duplication.

Changes:
- Make `engine/config/base.yaml` the canonical collector config source.
- Use the Helm chart's `configFile` feature to mount and load `engine/config/base.yaml`.
- Supply Environment State strictly via env vars and chart values.
- Keep `engine/resources/` as modular components referenced by canonical config (Bloblang + schemas).

Outcome:
- Collector behavior changes happen in one place.
- Easier producer expansion without divergence.

### Phase 3 — OpenMeter-native reliability guarantees

Goal: Implement built-in reliability and idempotency features.

Changes:
- Ensure persistent buffering is first-class (storage + buffer path + shutdown controls).
- Add explicit retry/backoff tuning in collector config where appropriate.
- Implement collector-side deduplication (cache/resource-backed) using canonical CloudEvent identifiers.

Outcome:
- Stronger protection for Economic Plane and Archive Plane.
- Direct path to move duplicate-billing certification from planned to implemented/scaffolded.

### Phase 4 — Bloblang and preset composability for producer expansion

Goal: Use the OpenMeter Collector and Redpanda Connect ecosystem without turning Welkin into a producer-specific event model.

Changes:
- Keep the base engine config source-agnostic at the Canonical CloudEvent boundary.
- Keep source-specific mappings and examples under `engine/presets/`.
- Use reusable Bloblang map libraries (`map ...` + `.apply()`) only where they help compose ecosystem presets cleanly.
- Expand preset tests without making any one preset the core Welkin path.

Outcome:
- Producer diversity remains in the collector ecosystem.
- Welkin remains a substrate over Canonical CloudEvents, Economic Plane, and Archive Plane.

### Phase 5 — Certification-grade observability evidence

Goal: Turn existing collector metrics/logs into formal evidence artifacts.

Changes:
- Capture collector `/metrics` snapshots in certification scenarios.
- Include batch/buffer metrics and processor/output failure counters in evidence bundle.
- Add runbook sections that map key metrics to invariant health.

Outcome:
- Certification reflects measurable operational truth, not only command logs.

## Execution order recommendation

1. Phase 1 (low-risk, immediate value)
2. Phase 2 (eliminate drift)
3. Phase 3 (reliability and dedup)
4. Phase 4 (ecosystem preset maintainability)
5. Phase 5 (evidence hardening)

## Validation strategy

For each phase:

- `cue vet` on canonical contracts and fixtures.
- `rpk connect test` on all collector tests.
- `timoni bundle vet` on bundle/runtime values.
- Certification scenario runs for changed guarantees where applicable.

## Non-goals

- No custom services.
- No architecture changes.
- No changes to OpenMeter semantics.
- No changes to Timoni or Flux role in lifecycle.
