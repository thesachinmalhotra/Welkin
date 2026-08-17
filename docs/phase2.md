# Welkin Phase 2 — Make the Existing Architecture True, Reproducible, and Provable

We are beginning Phase 2 of Welkin.

IMPORTANT: This is NOT a redesign, greenfield implementation, feature expansion, or exploratory cleanup exercise.

Phase 1 is complete: the repository underwent a major architectural overhaul and now has a coherent composition-first foundation.

Your job now is to make that existing architecture true, deterministic, and provable end-to-end.

============================================================
NORTH STAR
============================================================

Welkin is a composition-first, cloud-native usage substrate.

Its core architectural thesis is:

    Producer
        ↓
    Canonical CloudEvent boundary
        ↓
    OpenMeter Collector
        ↓
       fan-out
      ↙       ↘
 Economic     Archive
 OpenMeter    Parquet → S3-compatible storage

The Collector is the canonical runtime boundary.

OpenMeter owns economic semantics.

The archive plane owns durable/replayable event storage.

Timoni owns composition.

Flux/OCI owns distribution and reconciliation.

Certification must prove the composed system rather than simulate or replace it.

The governing principle is:

    COMPOSE, DON'T BUILD.

Do not introduce Welkin-specific infrastructure when an upstream component, Timoni primitive, Flux primitive, CloudEvent, CUE contract, or existing architectural mechanism already provides the capability.

============================================================
CURRENT BASELINE
============================================================

Current repository is the result of the Phase 1 architectural reset.

Treat the current repository state as the baseline.

Do NOT revert the overhaul.

Do NOT resurrect removed infrastructure.

Do NOT restore the old hand-rolled OpenMeter stack.

Do NOT create another parallel implementation.

Important architectural corrections already made:

- production Collector is the real event boundary
- HTTP CloudEvent ingestion exists at /events
- canonical CloudEvent validation is part of the Collector
- Collector fans out to Economic + Archive
- OpenMeter is composed through its upstream Helm chart
- Postgres/MinIO are composed through Timoni
- certification runs against a real cluster rather than simulating production internally
- certification logic is executed in-cluster
- release/distribution is moving toward OCI → Flux
- obsolete custom manifests and duplicated infrastructure were removed
- rpk is test tooling only, NOT production runtime
- Timoni is the composition surface
- upstream-native behavior must be preferred

Read and obey:

- AGENTS.md
- production contract / architecture docs
- current certification catalog
- current certification scenarios
- current Timoni bundle/runtime/value files
- current CI/release workflows

Do not assume historical issue-register findings still apply.
Verify current HEAD before acting.

============================================================
THE ONE OBJECTIVE
============================================================

Make the current Welkin architecture:

    correct
    deterministic
    reproducible
    certifiable
    operationally honest

without expanding its architectural scope.

The end state is NOT:

"lots of features."

The end state is:

"the guarantees Welkin already claims are actually demonstrated."

============================================================
STRICT ANTI-DRIFT RULES
============================================================

These rules exist specifically because previous work drifted into reactive duct-taping.

1. NO BLIND CI RUNS.

Never trigger a 15–20 minute certification workflow merely to discover what might be wrong.

Before remote E2E:

- reproduce or statically validate locally where possible
- inspect exact failure evidence
- identify a concrete hypothesis
- make the smallest coherent change
- validate locally
- only then run CI

2. NO SPECULATIVE FIXES.

Do not modify something because it "might" be responsible.

Establish evidence first.

3. NO ARCHITECTURAL WORKAROUNDS.

If an upstream component fails, investigate its actual configuration/API/behavior.

Do not rebuild its dependencies inside Python.
Do not create fake versions of production services.
Do not bypass the production boundary just to make certification pass.

4. NO SCOPE CREEP.

Do not add:

- custom control planes
- new Welkin services
- analytics systems
- broad producer matrices
- dashboards
- custom secret systems
- custom billing/idempotency logic
- new infrastructure merely for convenience

unless the existing architecture explicitly requires them.

5. DO NOT "FIX" UPSTREAM BEHAVIOR INSIDE WELKIN.

If OpenMeter owns something, use OpenMeter.

If Collector owns something, use Collector.

If Timoni owns something, use Timoni.

If Flux owns something, use Flux.

If Kubernetes owns something, use Kubernetes.

6. PRESERVE OWNERSHIP BOUNDARIES.

Before changing anything, answer:

    Who owns this behavior?

If the answer is an upstream component, compose it.
If the answer is Welkin, implement only the smallest Welkin-specific layer required.

7. DO NOT TURN CERTIFICATION INTO A SECOND PRODUCT.

Certification should verify Welkin.

It must not become a parallel infrastructure implementation.

8. WHEN UNCERTAIN, STOP.

If a proposed change could alter architecture, ownership, or production semantics, stop and explain the ambiguity before implementing it.

============================================================
PHASE 2 ORDER
============================================================

Work through these gates IN ORDER.

Do not jump ahead merely because a later item looks interesting.

------------------------------------------------------------
GATE 1 — SINGLE CANONICAL EVENT CONTRACT
------------------------------------------------------------

Goal:

Establish one authoritative canonical CloudEvent contract.

Current concern:

There have historically been multiple representations of the CloudEvent contract.

We need:

    canonical contract
          ↓
      ┌───┴────┐
      ↓        ↓
     CI      runtime

The contract must define the canonical requirements consistently.

Build a fixture matrix covering at least:

- valid event
- missing id
- missing subject
- missing data
- wrong specversion
- empty source
- empty type
- invalid data shape
- extra fields

Determine explicitly whether extra fields are allowed or rejected by the actual contract.

For every fixture, establish:

    CUE/CI decision
    =
    runtime JSON-schema decision

Do not hand-maintain two semantically different contracts.

IMPORTANT:

Do not blindly delete schemas or move files.

First map all current consumers.

If the existing architecture intentionally generates/embeds a runtime schema from a canonical source, preserve that mechanism.

EXIT CONDITION:

There is one authoritative contract and a test matrix proving CI and runtime agree.

STATUS: COMPLETE

- One authoritative CUE contract: `spec/schema/cloudevent.cue`
- One runtime JSON Schema: `collector/schemas/cloudevent.schema.json` (identical inline in `platform/collector/collector.cue`)
- Divergence fixed: CUE now requires `data` (`data!: [string]: _`) and allows extra fields (`...`)
- Fixture matrix: 9 cases in `cert/fixtures/gate1/` — all pass CUE vet with expected outcomes
- Validation: `gate1_contract_matrix()` in `run_scenario.py` proves CUE decisions match JSON Schema for every case

------------------------------------------------------------
GATE 2 — CLEAN-ROOM CANONICAL HAPPY PATH
------------------------------------------------------------

This is the immediate runtime objective.

We need:

    fresh Kubernetes cluster
        ↓
    Welkin composition
        ↓
    Collector + OpenMeter + archive
        ↓
    canonical event
        ↓
      ┌───────┴────────┐
      ↓                ↓
   OpenMeter        Parquet/S3
      ↓                ↓
   economic          archive
   assertion         assertion

The repository already has a canonical-flow scenario.

DO NOT invent another scenario.

Make the existing one work.

CURRENT KNOWN FACT:

The recent E2E reached the Timoni bundle-apply boundary and failed.

Before triggering another expensive CI run:

1. inspect the exact failed run
2. retrieve the complete artifact/log evidence
3. identify the precise failing resource/configuration
4. reproduce locally if possible
5. inspect upstream semantics if necessary
6. make the smallest correction
7. run all available local validation
8. only then trigger CI

Do not guess.

EXIT CONDITION:

A completely fresh cluster can deploy the current Welkin composition and execute:

canonical event
→ Collector
→ OpenMeter
→ Archive

with inspectable evidence.

------------------------------------------------------------
GATE 3 — TRUTHFUL CERTIFICATION
------------------------------------------------------------

Certification status must reflect evidence, not intention.

The conceptual lifecycle is:

    planned
       ↓
    scaffolded
       ↓
    implemented
       ↓
    executed
       ↓
    evidence validated
       ↓
    verified

Do not manually promote a guarantee to "verified" merely because implementation exists.

A verified claim must be tied to:

- exact Welkin release identity
- exact OCI artifact/digest where applicable
- scenario
- execution result
- evidence bundle
- evidence validation

Investigate whether the catalog can derive verified state from evidence rather than relying on manually edited status.

Do not over-engineer this.

First make the existing certification model truthful.

EXIT CONDITION:

No guarantee is marked Verified without corresponding valid evidence.

------------------------------------------------------------
GATE 4 — ECONOMIC CORRECTNESS / IDEMPOTENCY
------------------------------------------------------------

Do not implement idempotency inside Welkin.

OpenMeter owns economic semantics.

Welkin must prove the composed system behaves correctly.

Minimum experiment:

    send event A
        ↓
    meter = X

    replay exact event A
        ↓
    meter remains X

not:

    meter = 2X

Use the same canonical event identity.

Inspect upstream OpenMeter semantics before writing any workaround.

EXIT CONDITION:

Duplicate/replayed canonical events do not create duplicate economic effect.

------------------------------------------------------------
GATE 5 — ARCHIVE CORRECTNESS
------------------------------------------------------------

Do not stop at "a Parquet file exists."

Prove:

A. Durability

    canonical event → archive object exists

B. Content fidelity

Read the produced Parquet and verify the canonical event fields correspond to the event that entered the boundary.

C. Partition correctness

Verify the declared partition dimensions:

- source
- event type
- day

D. Replayability

Establish the smallest executable proof that an archived canonical event can be replayed through the canonical boundary.

Do not build a replay service.

Use existing OpenMeter Collector / object storage / CloudEvent mechanisms.

EXIT CONDITION:

The archive is demonstrably durable, semantically correct, partitioned correctly, and recoverable/replayable to the degree required by the existing contract.

------------------------------------------------------------
GATE 6 — ECONOMIC / ARCHIVE PLANE ISOLATION
------------------------------------------------------------

The intended structure is:

                 ┌──→ Economic
canonical → broker
                 └──→ Archive
                       ↓
                   drop_on/backpressure

The archive branch may fail.

Economic delivery must continue.

Certification must prove BOTH sides:

    archive fails
        AND
    economic continues

Do not make the test pass merely because economic delivery works.

Minimum matrix:

1. archive unavailable before traffic
2. archive fails during traffic
3. archive recovers

Then, only if required by the existing production contract, extend to restart cases.

Do not assume restart tests are mandatory merely because they are interesting.

For failure injection, prefer an external test container/job or existing Kubernetes tooling.

Do not exec arbitrary diagnostic tools into the production Collector container unless that is genuinely required.

EXIT CONDITION:

Archive degradation demonstrably cannot block or corrupt economic delivery.

------------------------------------------------------------
GATE 7 — ENVIRONMENT STATE / SECRETS
------------------------------------------------------------

Platform State must not contain production credentials.

Audit:

- Postgres
- MinIO
- OpenMeter
- Collector
- any other credential-bearing configuration

Separate:

    Platform State
        =
    immutable composition

from:

    Environment State
        =
    secrets / endpoints / customer-specific values

Certification may use explicit test credentials.

Production composition must not embed them as defaults.

Test:

    missing credential → fail closed
    wrong credential   → fail
    valid credential   → deploy

Do not invent a custom Welkin secret-management system.

Use Timoni/Kubernetes/upstream mechanisms already chosen by the architecture.

EXIT CONDITION:

No production secret is embedded in Platform State and missing required credentials fail closed.

------------------------------------------------------------
GATE 8 — IMMUTABLE RELEASE → CERTIFICATION
------------------------------------------------------------

Close the distribution loop:

    source
      ↓
    Timoni artifact
      ↓
    OCI digest
      ↓
    Flux
      ↓
    Kubernetes
      ↓
    certification
      ↓
    evidence tied to same digest

Certification should ultimately certify the exact artifact that is intended for deployment.

Do not certify "whatever happens to be on main."

Audit the current release workflow and Flux OCI source.

Resolve any repository/name/digest mismatches.

Do not redesign release infrastructure if a small naming/reference correction is sufficient.

EXIT CONDITION:

The exact immutable OCI artifact consumed by deployment is the artifact certified by E2E evidence.

------------------------------------------------------------
GATE 9 — TEST/CI CONSISTENCY
------------------------------------------------------------

Make all validation tooling consistent with the repository's own pinning rules.

Audit:

- rpk
- cue
- timoni
- kubectl
- helm
- action versions
- other external tools

Do not blindly upgrade everything.

Fix only genuine violations or reproducibility problems.

Ensure:

    local validation
       ≈
    CI validation

where practical.

EXIT CONDITION:

No known floating/latest dependency remains in the certification/release path where the architecture requires deterministic pinning.

------------------------------------------------------------
GATE 10 — CUSTOMER DEPLOYMENT CONTRACT
------------------------------------------------------------

Only after the technical substrate is proven.

Document:

- prerequisites
- Kubernetes requirements
- Timoni/runtime inputs
- secrets
- external services
- namespaces
- permissions
- network requirements
- install
- upgrade
- rollback
- recovery
- uninstall
- data/export/replay expectations
- version/digest identity
- verification

Explicitly distinguish:

    Welkin reference/certification environment

from:

    customer production environment

Do not accidentally make bundled Postgres/MinIO mandatory for production if the architecture intends customer-owned infrastructure.

EXIT CONDITION:

A technically competent external operator can deploy and recover Welkin without relying on our development machine or undocumented assumptions.

============================================================
LATER — DO NOT WORK ON THESE YET
============================================================

These are valid roadmap items but are intentionally deferred until Gates 1–10 are stable:

- producer diversity
- broad producer matrix
- advanced observability
- schema evolution policy
- extensive restart/recovery matrix
- broader production dependency topology
- dashboards
- additional platform services
- feature expansion

For producer diversity, eventually prove something like:

    Kubernetes ──┐
                 ├──→ canonical event → same substrate
    HTTP/API ────┘

But do not build a zoo of producers.

============================================================
WORKING METHOD
============================================================

For every gate:

1. READ
   Inspect current implementation and relevant contract/docs.

2. MAP
   Identify ownership and current execution path.

3. VERIFY
   Check upstream behavior if the question depends on it.

4. PLAN
   State the smallest change required.

5. IMPLEMENT
   Only after the above is understood.

6. VALIDATE LOCALLY
   Run the cheapest meaningful checks first.

7. REVIEW DIFF
   Ensure no unrelated architecture changed.

8. ONLY THEN use remote CI when runtime evidence is actually required.

9. HARVEST EVIDENCE
   Record exact results.

10. CLOSE THE GATE
   Explicitly state whether its exit condition is satisfied.

Then move to the next gate.

============================================================
ANTI-PATTERN CHECK BEFORE EVERY CHANGE
============================================================

Before committing a change, ask:

1. Am I fixing a demonstrated problem?
2. Which Welkin invariant/guarantee does this serve?
3. Which component owns this behavior?
4. Am I duplicating an upstream capability?
5. Am I creating certification-only infrastructure?
6. Am I introducing another source of truth?
7. Could the same result be achieved by composition/configuration instead?
8. Is this required for the CURRENT gate?
9. Does this alter architecture or merely implement the existing architecture?
10. Can I prove the change locally before spending a remote CI run?

If the answer to #8 is "no", defer it.

============================================================
STOP CONDITIONS
============================================================

STOP and report instead of continuing if:

- a fix requires architectural redesign
- upstream behavior is ambiguous
- production ownership is unclear
- a test requires inventing infrastructure
- the current contract contradicts implementation
- a later gate becomes necessary to unblock the current gate
- a proposed change affects unrelated guarantees
- evidence is insufficient to justify a change

Do not silently choose a direction.

============================================================
DEFINITION OF DONE FOR PHASE 2
============================================================

Phase 2 is complete only when the existing Welkin architecture can demonstrate:

    canonical contract
        ↓
    real Collector boundary
        ↓
      ┌─┴───────────────┐
      ↓                 ↓
   Economic           Archive
      ↓                 ↓
 idempotent         durable/correct
 delivery           + replayable
      │                 │
      └──────┬──────────┘
             ↓
       plane isolation
             ↓
       truthful evidence
             ↓
       exact release digest

and the deployment:

- contains no production credentials in Platform State
- is reproducible from the intended release artifact
- has evidence tied to that exact artifact
- can be operated by someone other than the original developer

============================================================
MOST IMPORTANT INSTRUCTION
============================================================

DO NOT LOSE THE GOAL.

The goal is NOT:

"fix every issue you can find."

The goal is:

"make Welkin's existing architectural guarantees true and provable."

If you discover an interesting adjacent problem while working on a gate, record it and defer it unless it blocks the current gate.

Do not wander.

Do not redesign.

Do not duct-tape.

Do not run expensive CI hoping it tells us what to do.

Work gate-by-gate, evidence-first, and stop when the current gate is genuinely closed.
