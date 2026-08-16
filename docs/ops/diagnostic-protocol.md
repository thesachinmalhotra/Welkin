# Welkin Production-Readiness Diagnostic Procedure

This document is the canonical procedure for auditing Welkin against
`WELKIN_PRODUCTION_READINESS.md`. It is durable: it survives implementation
changes and does not embed the repository's state at any point in time.

The diagnostic agent reads nothing more than this procedure, the readiness
contract, and the live repository. It produces evidence and findings only — no
fixes, refactors, deletions, or commits.

---

## 1. Start From the Contract

Before touching the repository, read in this order:

1. `AGENTS.md` (root) — architectural invariants, distribution model, engineering
   principles.
2. `docs/ops/production-readiness.md` — the production-readiness
   contract (this document's target).
3. `docs/architecture/architecture.md`, `docs/ops/deployment.md`, `docs/ops/runbook.md`,
   `docs/architecture/implementation.md` — current architecture, deployment, and operator guidance.
4. `cert/catalog.cue` and `docs/certification/overview.md` — guarantees, scenarios,
   and evidence model.

Treat the production-readiness contract as the **GO/NO-GO target**. Nothing in the
repository overrides it. The contract's Definition of Production Ready
(contract §2) and V1 Required Guarantees (contract §4) are the audit targets.

Record the exact text of each guarantee and invariant you are assessing. Do not
paraphrase claims from memory; quote the contract.

---

## 2. Treat the Repository As Reality

Do not assume that previous agent reports, plans, TODO comments, or
documentation reflect the actual state of the system. Verify every important
claim against:

- The actual repository source, configuration, and fixtures.
- Rendered deployment artifacts (e.g., Timoni bundle output, HelmRelease
  values, rendered manifests).
- Executable behavior (running the validator, collector tests, bundle build).
- CI workflow definitions and their actual step sequence.
- Upstream documentation and source for the components Welkin composes
  (OpenMeter Collector, Timoni, Flux, OpenMeter, Kubernetes).

A claim is not evidenced until the repository itself — or a faithful rendering
of it — demonstrates it.

---

## 3. Do Not Confuse Roads With Goals

The contract defines the goal; the repository may contain one or more roads to
that goal. Do not preserve or dismiss an implementation merely because it
already exists.

For each mechanism you evaluate:

- Identify the invariant or guarantee it is intended to satisfy.
- Ask: does an upstream-native primitive (Timoni runtime, Flux, Kubernetes,
  OpenMeter Collector, Redpanda Connect, Helm, CUE, or an open standard) satisfy
  this invariant with less bespoke machinery?
- If the current implementation appears to make an invariant harder to satisfy,
  investigate simpler or upstream-native alternatives — do not weaken the
  invariant to accommodate the implementation.

If a mechanism cannot be mapped to an invariant, treat its necessity as
unproven.

---

## 4. Investigate by Guarantee

For **every** V1 Required Guarantee (contract §4):

1. State the exact claim as written in the contract.
2. Identify the mechanism currently intended to provide it (in the repository or
   its rendered artifacts).
3. Determine what would **falsify** the claim.
4. Test the falsification path where practical (see §5 — Evidence Hierarchy and
   §6 — Negative Cases).
5. Collect concrete evidence (output, artifacts, logs, rendered values).
6. Classify the result as: **Verified**, **Implemented (unverified)**,
   **Scaffolded**, **Planned**, or **Evidence gap**.

Record findings as: *guarantee → mechanism → falsification test → result →
evidence artifact*.

---

## 5. Evidence Hierarchy

When judging whether a claim is proven, prefer evidence in this order:

1. **Executable test or result** — a test suite run, a rendered output that
   matches expectations, or a bundle build / apply that succeeds.
2. **Rendered deployment artifact** — a concrete HelmRelease, Timoni bundle
   output, or manifest produced from the release artifact + Environment State.
3. **Source/configuration behavior** — behavior observable from reading and
   executing the actual configuration against fixtures.
4. **CI workflow behavior** — what the defined CI steps actually do and produce.
5. **Upstream documentation or source** — how the composed upstream component
   actually behaves.
6. **Repository documentation** — prose descriptions, treated as the weakest
   form.
7. **Agent or user assertion** — never sufficient on its own.

Never mark something verified at a level higher than the highest evidence tier
that actually demonstrates it. Documentation that says something works is never
sufficient ground for "verified."

---

## 6. Search for Negative Cases

Explicitly test or reason through the failure modes that are applicable to
Welkin's established architecture. For each, attempt to falsify a contract
guarantee and collect the outcome:

- Malformed canonical events — do they reach the Economic or Archive Plane?
- Duplicate / replayed events — does replay produce duplicate economic effects?
- Economic destination failure — does it affect archive delivery, and vice versa?
- Archive destination failure — does it block or delay economic delivery?
- Backpressure — does economic processing stall when archive backpressures?
- Restart / reconciliation — does state survive a collector restart or Flux
  reconciliation without duplication or loss?
- Missing secrets — does the deployment fail closed rather than degrading to an
  insecure default?
- Invalid configuration — does the system fail clearly, or deploy a broken state?
- Clean-environment deployment — does a fresh cluster accept the release artifact
  and Environment State alone?
- Artifact / version drift — does the same release artifact produce consistent
  Platform State?
- Producer diversity before canonicalization — do different producers converge to
  the same canonical downstream shape?
- Security boundary violations — does Environment State (secrets) leak into
  Platform State or artifact manifests?

Only test cases that are actually applicable to Welkin's architecture count. Do
not invent failures for components or behaviors the architecture explicitly
excludes.

---

## 7. Distinguish Findings from Hypotheses

Every record has two possible forms:

- **Finding (confirmed):** an issue supported by concrete evidence — output
  showing a failure, a rendered artifact that contradicts the claim, or an
  executable test that fails. State what falsifies the claim and how it was
  observed.

- **Unverified hypothesis / evidence gap:** a suspicion with insufficient
  evidence. State what is missing and what evidence would resolve it.

Never write "X is broken" without evidence. If tests could not be run (no
cluster, no tooling, no artifact), record the gap — do not speculate past it.

---

## 8. Issue Severity

Classify every finding or gap using the P0–P3 definitions from the contract
(contract §6):

- **P0 — Production blocking.** A condition that violates a required guarantee
  or invariant: data loss, correctness violation, security failure, or an actual
  failure causing economic loss, corruption, blocking, or violation of the
  Economic/Archive isolation guarantee. Never waivable for v1.
- **P1 — Important gap.** A condition that materially impairs reliability,
  operational manageability, or deployment reproducibility. Blocks readiness by
  default; only accepted through an explicit documented decision with
  mitigation.
- **P2 — Hardening or maintainability.** A condition that weakens long-term
  operability or clarity without immediate runtime impact.
- **P3 — Future improvement.** A condition that would enhance the platform but
  does not affect the current readiness bar.

Severity must be justified by impact and evidence, not by implementation
difficulty. A P0 with no evidence is not a P0 — it is an unverified hypothesis.

---

## 9. Upstream-Native Review

When an implementation appears to require bespoke machinery:

1. Identify the invariant or guarantee it is trying to satisfy.
2. Investigate whether Timoni, Flux, Kubernetes, OpenMeter Collector / Redpanda
   Connect, or another already-approved upstream primitive can satisfy it
   natively.
3. Only consider custom machinery after upstream-native alternatives have been
   reasonably exhausted.
4. Do not assume the current implementation is the intended architecture — the
   agent follows AGENTS.md, "Implementation Is Not Architecture" ("protect the
   DNA, not the machinery") and the Architectural Invariants.

Document the upstream investigation and its conclusion for each bespoke
mechanism flagged.

---

## 10. No Implementation During Diagnosis

The diagnostic agent must **not**:

- Fix, refactor, delete, or modify any repository file.
- Commit, stage, or branch.
- "Clean up" stale configuration, dead code, or outdated documentation as part
  of the diagnostic.
- Change AGENTS.md, the readiness contract, or any other source file.

The output is **evidence and findings only**. Any implementation changes happen
in a separate, subsequent step.

---

## 11. Output

The diagnostic run must produce a single report containing:

1. **Executive readiness summary.** One paragraph: is the platform production-ready
   per the contract? State how many V1 guarantees are Verified, and whether any
   P0 or unmitigated P1 conditions remain.
2. **Guarantees assessed.** A table: each contract §4 guarantee → status
   (Verified / Implemented-unverified / Scaffolded / Planned / Evidence gap) →
   key evidence.
3. **Evidence collected.** Where it lives (artifact paths, command outputs,
   rendered manifests, test results).
4. **Confirmed issues.** Each with: severity, affected invariant/garantee,
   evidence, and required outcome (the outcome needed to promote the status —
   e.g., "must produce evidence of X in a clean environment").
5. **Unverified hypotheses / evidence gaps.** Each with the missing evidence and
   what would resolve it.
6. **What was NOT tested.** Every area skipped and the reason (no cluster
   available, tooling absent, upstream behavior not consulted, etc.).

---

## 12. Stop Condition

Stop when the production-readiness contract (contract §2, §4, §5, §8) has been
systematically assessed — that is, when every V1 Required Guarantee has been
investigated by the procedure above and classified with evidence.

Do not expand scope into unrelated improvements, future features, aesthetics,
speculative redesigns, or implementation cleanup. If an invariant is already
satisfied, do not invent work for it. If an area is out of scope per the
contract (contract §7 — Non-Goals), explicitly note it and move on.

---

## Quick-Reference Checklist

- [ ] Read contract (§2, §3, §4, §5, §6, §7, §8) and AGENTS.md invariants before touching the repo.
- [ ] For each of the 8 V1 guarantees: claim → mechanism → falsification → evidence → classification.
- [ ] Prefer executable evidence over documentation (§5 hierarchy).
- [ ] Test applicable negative cases from §6.
- [ ] Separate findings from hypotheses (§7).
- [ ] Classify by P0–P3 using contract §6; justify impact, not difficulty.
- [ ] Flag bespoke machinery; investigate upstream-native alternatives (§9).
- [ ] Do not modify, commit, or fix anything (§10).
- [ ] Produce report with: summary, guarantees table, evidence, issues, gaps, what-was-not-tested (§11).
- [ ] Stop when all 8 guarantees are assessed (§12).
