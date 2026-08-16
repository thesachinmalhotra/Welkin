# Welkin Production Readiness Contract

This document defines the objective bar for Welkin v1 production readiness. It states
what must be demonstrably true before Welkin can be called production-ready. This
contract is durable: implementation may change freely when necessary, but this bar
does not. It is not an implementation plan, a current-state audit, an issue register,
or an architecture rewrite.

---

## 1. Purpose

Welkin production readiness is a property of the platform, not of a particular
deployment, commit, or tooling set. This document captures the invariant conditions
that must hold for any deployment claiming to be a production-ready Welkin v1.
It separates the **goal** — what must be true — from the **roads** — how an
implementation chooses to get there. The goal is fixed; the roads may change.

---

## 2. Definition of Production Ready

Welkin is production-ready when the platform satisfies each of the following across
both operational planes:

- **Functional correctness.** Every event reaching the canonical boundary is
  canonicalized before any downstream processing. Malformed canonical candidates are
  rejected at the collector boundary before any downstream fan-out. After
  canonicalization, downstream behavior is identical regardless of producer type.

- **Economic correctness.** The Economic Plane receives canonical events and delivers
  them to OpenMeter for real-time metering, aggregation, and billing-semantic
  processing without loss, duplication, or misattribution of usage.

- **Archive durability and replayability.** The Archive Plane durably persists
  canonical events as Parquet to S3-compatible object storage. Archive records are
  append-oriented, recoverable, and replayable from object storage.

- **Economic/Archive failure isolation.** Archive degradation or failure does not
  block, delay, or corrupt Economic Plane delivery. The two planes operate
  independently; archive processing must never become a dependency of economic
  processing.

- **Reproducible deployment.** Equivalent release artifacts and equivalent Platform
  State inputs produce equivalent Platform State, irrespective of who deploys or the
  target Kubernetes environment. The release artifact is the sole source of Platform
  State; Environment State supplies only per-deployment variation.

- **Security and fail-closed secrets.** Credentials and secrets are supplied
  exclusively as Environment State. Their absence prevents deployment from proceeding
  in an insecure state rather than silently degrading to unsafe defaults.

- **Customer deployability.** A customer can deploy Welkin into their Kubernetes
  environment using only the published release artifact and their own Environment
  State. No Welkin-operated control-plane service, controller, or custom runtime is
  required. The resulting deployment is customer-owned.

- **Truthful certification.** Every claimed guarantee is backed by executable
  evidence produced through the certification system. No guarantee is marked as
  proven without inspectable, reproducible evidence appropriate to the claim.

---

## 3. Architectural Invariants

The following invariants are non-negotiable for production readiness. They hold
regardless of implementation choices:

1. Canonical CloudEvents are the platform contract.
2. Producer diversity ends at canonicalization.
3. Economic and Archive planes are independent.
4. Archive processing must never block Economic Plane processing.
5. OpenMeter Collector is the production collector — the integration engine for
   event ingestion.
6. Test tooling is distinct from the production collector runtime and must never
   be treated as a replacement for it.
7. Platform State, Environment State, and Observed Runtime State remain separate.
8. Timoni → OCI → Flux is the platform distribution model.
9. The Welkin platform (not individual upstream components) is the compatibility
   boundary.
10. **Compose, don't build.** Prefer upstream-native components, open standards,
    and clean composition over custom infrastructure.
11. Prefer open standards and upstream-native capabilities.
12. Do not introduce infrastructure merely because building it is convenient.
13. Do not redesign established architecture to solve a local implementation
    inconvenience.
14. Do not silently expand scope.

Additional production-readiness constraints derived from the above:

- The resulting deployment is customer-owned; Welkin contributes configuration,
  not a managed service.
- No custom runtime or control-plane service is introduced.
- The archive plane is for preservation, durability, and replay — not analytics.

---

## 4. V1 Required Guarantees

Welkin v1 production readiness requires demonstrating the following guarantees
through the certification system:

1. **Canonical event flow.** Producer events are canonicalized to the Canonical
   CloudEvent and routed identically to both planes.

2. **Economic delivery.** Canonical events reach OpenMeter and are reflected in
   the economic record.

3. **Archive delivery.** Canonical events are durably written to S3-compatible
   object storage as Parquet in the archive partition layout.

4. **Economic/Archive independence.** Archive failure does not prevent economic
   delivery.

5. **Idempotency and uniqueness.** Replay of canonical events does not produce
   duplicate economic effects; idempotency and uniqueness are responsibilities of the
   Economic Plane / OpenMeter, not of Welkin's substrate.

6. **Reproducible deployment.** A fresh environment can be brought to the Welkin
   substrate through the standard composition path without manual intervention.

7. **Clean-room certification.** Guarantees are demonstrated in a clean / ephemeral
   cluster provisioned from the published release artifact, not a pre-warmed
   developer environment.

8. **Bootstrap and deployability.** The full platform boot — Flux, OpenMeter, and
   the collector — completes and becomes ready from a clean starting state using
   only the release artifact and Environment State.

---

## 5. Evidence Standard

A claim is not a guarantee until it is evidenced. The certification system
recognizes four evidence statuses, each with a distinct meaning:

- **Implemented.** The implementation and an executable verification mechanism
  exist; the guarantee is structurally ready for verification.

- **Verified.** The verification has actually executed successfully against a
  specific release artifact and produced valid evidence showing the guarantee
  holds. Verification is the act that promotes a claim from implemented to
  verified.

- **Scaffolded.** The verification structure exists but the guarantee has not yet
  been demonstrated end-to-end. A path to validation is defined and in progress.

- **Planned.** The guarantee is recognized as necessary but not yet structurally
  scaffolded.

The certification lifecycle is: Planned → Scaffolded → Implemented → Verified.

A guarantee is **not** considered production-ready merely because its status is
implemented. Only Verified guarantees count toward the production-readiness gate.
Structure or configuration alone is not proof.

---

## 6. Severity / Readiness Gates

Issues are classified by their impact on this production readiness contract.
Classification is evidence-oriented: each P0 condition has a concrete, observable
failure mode.

- **P0 — Production blocking.** A condition that violates a required guarantee or
  invariant: data loss, correctness violation, security failure, or any actual
  failure causing economic loss, corruption, blocking, or violation of the
  Economic/Archive isolation guarantee. The platform cannot ship with any P0 open.

- **P1 — Important gap.** A condition that materially impairs reliability,
  operational manageability, or deployment reproducibility. Examples include failure
  to reproduce a clean-room deployment, secrets leaking into Platform State,
  weaknesses in the Economic/Archive isolation mechanism that have not produced a
  correctness failure, or inability to produce required certification evidence.
  Must be resolved before production readiness is claimed, but may carry an explicit,
  documented, time-bounded mitigation.

- **P2 — Hardening or maintainability.** A condition that weakens long-term
  operability or clarity without immediate runtime impact: missing observability
  signals, weak error diagnostics, configuration drift risk, or insufficient test
  coverage for edge cases. Must be tracked and addressed in the near term.

- **P3 — Future improvement.** A condition that would enhance the platform but does
  not affect the current readiness bar: polish, additional presets, expanded
  analytics on the archive, or speculative reliability features.

P0 conditions are never waivable for v1. P1 conditions block readiness by default
and may only be accepted through an explicit documented decision with mitigation.
P2 and P3 conditions do not block readiness, though P2 items must appear on a
tracked backlog.

---

## 7. Explicit V1 Non-Goals

The following are explicitly out of scope for Welkin v1 production readiness.
Treating them as v1 requirements would violate the established architecture:

- **No monolithic billing platform.** Welkin routes canonical events to OpenMeter;
  it does not own billing business logic, pricing rules, or invoice generation.

- **No monolithic data or analytics platform.** The archive is for preservation,
  durability, and replay. Analytics infrastructure built on the archive is a future
  extension, not a v1 requirement.

- **No archive committer service.** The archive path is append-oriented Parquet
  writes to object storage. No additional archive committer, query engine, or
  lakehouse service is introduced.

- **No custom runtime or control-plane service.** Welkin deploys and composes
  upstream-native components; it does not ship a custom controller, operator, or
  business-logic microservice.

- **No redefinition of the canonical event boundary or plane semantics.** The
  Canonical CloudEvent contract, plane separation, and producer-diversity boundary
  are fixed.

- **No dependency on a specific cloud provider.** Welkin is cloud-native and
  composable but provider-agnostic at the platform level.

- **No weakening of the test/production boundary.** Test tooling remains test
  tooling; it does not become the runtime.

---

## 8. Certification Gate

Before the certification catalog may truthfully mark a scenario or guarantee as
**implemented**, the following minimum evidence must exist and be reproducible:

1. A defined **claim** that maps to a specific architectural guarantee.

2. A defined **verification** procedure that is executable — not merely
   descriptive.

3. **Evidence artifacts** produced by running the verification, including:
   - Execution output showing the procedure ran to completion.
   - Observable assertions proving the claim holds (e.g., receipt
     confirmation, durability confirmation, isolation confirmation).
   - An artifact bundle identifying the release artifact and Environment State
     used.

4. A **human-readable report** and a **machine-readable summary** (structured
   evidence) that can be inspected without ambiguity.

5. Evidence that the verification ran against a **clean environment** provisioned
   from the published release artifact — not a pre-warmed developer cluster.

Evidence that is absent, stale, or not tied to a specific release artifact does
not satisfy the gate. "Implemented" must mean "demonstrably proven, not assumed."

---

## 9. Change Rule

Implementation may change freely when necessary — files may be reorganized,
formats may evolve, and mechanisms may be replaced — but the following may not:

- The production-readiness contracts, guarantees, and invariants defined in this
  document.
- Any architectural invariant from the established architecture.
- The production-readiness bar for v1.

Changes to architectural invariants, production guarantees, or the readiness bar
require an explicit architectural decision, documented and reviewed, before they
take effect. This contract changes only through that mechanism.
