# Welkin v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deployment-ready Welkin v1 substrate that canonicalizes producer events once, routes them to OpenMeter and an archive plane, and ships as declarative CUE, Timoni, Flux, and collector artifacts.

**Architecture:** Welkin centers the OpenMeter Collector as the ingestion core. Producer-specific inputs and Bloblang normalization terminate at a canonical CloudEvent contract, after which one fixed dual-plane route sends the same event to OpenMeter for runtime metering and to Parquet-on-S3-compatible storage for archival. Delivery is handled as Timoni bundles and runtime values that Flux can reconcile in ephemeral Kubernetes environments.

**Tech Stack:** CUE, Timoni, Flux, OpenMeter, OpenMeter Collector (Redpanda Connect), Bloblang, GitHub Actions

## Global Constraints

### Progress (2026-08-11)
- [x] Pin OpenMeter release defaults in timoni/runtime to v1.0.0-beta.232 (chart digest: sha256:bf2afa50f4...; image amd64: sha256:4a816108...)
- [x] Pin benthos-collector chart by OCI digest in Timoni values (timoni/values/collector.cue)
- [x] Override collector image.tag to collectorVersion and add CI digest verification
- [x] Add CI workflow .github/workflows/pin-verify.yaml to assert chart+image digests on GHCR
- [x] Pin flux release source URL to ghcr.io/thesachinmalhotra/welkin-release (flux/release-source.yaml)
- [x] Annotate flux-aio and flux-helm-release v2.5.0-0 with GHCR module digests in timoni/runtime/welkin.runtime.cue
- [ ] Continue: pin flux/timoni module references to OCI digests (optional stronger immutability)
- [ ] Continue: run full CI (validate + certification-suite) and fix any emergent issues
- [ ] Continue: update docs and add PR protection requiring pin-verify


## Global Constraints

- Welkin v1 is only two planes: Runtime (OpenMeter -> Stripe) and Archive (Parquet on object storage).
- Do not add Iceberg, Polaris, DataFusion, Arrow Flight, or any archive committer service.
- Do not add microservices, controllers, or custom business-logic services.
- OpenMeter Collector is the deploy target for ingestion, not vanilla Redpanda Connect.
- Producer-specific logic is allowed only in Bloblang before canonicalization.
- After canonical CloudEvents, every producer path must remain identical.
- Prefer official collector presets before custom Bloblang-only inputs.
- Package chart-backed components through Timoni `flux-helm-release`, not handwritten chart wrappers.
- Treat the archive plane as preservation and replay only, not analytics.

---

### Task 1: Establish repo skeleton and canonical contract

**Files:**
- Create: `README.md`
- Create: `docs/architecture.md`
- Create: `docs/implementation.md`
- Create: `cue/README.md`
- Create: `cue/schema/cloudevent.cue`
- Create: `cue/schema/archive_event.cue`
- Create: `collector/fixtures/kubernetes-pod.json`
- Create: `collector/fixtures/canonical-event.json`
- Create: `collector/fixtures/non-billable-pod.json`

**Interfaces:**
- Consumes: none
- Produces:
  - canonical CloudEvent schema in `cue/schema/cloudevent.cue`
  - archive record schema in `cue/schema/archive_event.cue`
  - Kubernetes preset sample input fixture in `collector/fixtures/kubernetes-pod.json`
  - canonical output fixture in `collector/fixtures/canonical-event.json`

- [ ] **Step 1: Write the failing test fixtures contract**

Document these expected canonical fields in `collector/fixtures/canonical-event.json` and `cue/schema/cloudevent.cue`:

```json
{
  "id": "sha256:kubernetes-api:pod-demo:2026-07-27T00:00:15Z",
  "specversion": "1.0",
  "type": "kube-pod-exec-time",
  "source": "kubernetes-api",
  "time": "2026-07-27T00:00:15Z",
  "subject": "tenant-acme",
  "data": {
    "pod_name": "demo-pod",
    "pod_namespace": "acme",
    "duration_seconds": 15
  }
}
```

- [ ] **Step 2: Run schema validation command to verify repo is still missing the contract**

Run: `cue vet ./collector/fixtures/canonical-event.json ./cue/schema/cloudevent.cue`

Expected: FAIL because `cue/schema/cloudevent.cue` does not exist yet.

- [ ] **Step 3: Write the minimal canonical schemas and docs**

Add a minimal CUE schema with these constraints:

```cue
package schema

#CloudEvent: {
  id:          string
  specversion: "1.0"
  type:        string
  source:      string
  time:        string
  subject:     string
  data:        {...}
}
```

Add an archive record schema that keeps the CloudEvent envelope plus archive partition hints:

```cue
package schema

#ArchiveEvent: {
  event:       #CloudEvent
  partition: {
    source:    string
    eventType: string
    day:       string
  }
}
```

- [ ] **Step 4: Run schema validation to verify the contract passes**

Run: `cue vet ./collector/fixtures/canonical-event.json ./cue/schema/cloudevent.cue`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md docs/architecture.md docs/implementation.md cue/schema collector/fixtures
git commit -m "feat: add canonical welkin event contract"
```

### Task 2: Build the collector golden path and tests

**Files:**
- Create: `collector/config/base.yaml`
- Create: `collector/resources/processors/canonicalize_kubernetes.blobl`
- Create: `collector/resources/processors/archive_partition.blobl`
- Create: `collector/resources/processors/validate_cloudevent.yaml`
- Create: `collector/resources/outputs/runtime_openmeter.yaml`
- Create: `collector/resources/outputs/archive_s3.yaml`
- Create: `collector/resources/pipelines/kubernetes_runtime_archive.yaml`
- Create: `collector/tests/kubernetes_runtime_archive_benthos_test.yaml`

**Interfaces:**
- Consumes:
  - `collector/fixtures/kubernetes-pod.json`
  - `collector/fixtures/canonical-event.json`
  - `cue/schema/cloudevent.cue` as contract source for field expectations
- Produces:
  - Bloblang mapping `canonicalize_kubernetes.blobl`
  - collector pipeline `collector/resources/pipelines/kubernetes_runtime_archive.yaml`
  - resource labels `welkin_runtime_openmeter`, `welkin_archive_s3`, `welkin_validate_cloudevent`

- [ ] **Step 1: Write the failing collector unit tests**

Create `collector/tests/kubernetes_runtime_archive_benthos_test.yaml` with tests for:

```yaml
tests:
  - name: canonicalizes kubernetes pod into cloudevent
    target_mapping: ../resources/processors/canonicalize_kubernetes.blobl
    input_batch:
      - content: |
          {"metadata":{"name":"demo-pod","namespace":"acme","annotations":{"openmeter.io/subject":"tenant-acme","data.openmeter.io/region":"us-east-1"}},"spec":{"containers":[{"resources":{"limits":{"memory":"4Gi","cpu":"500m"},"requests":{"memory":"2Gi","cpu":"250m"}}}]}}
        metadata:
          schedule_time: "2026-07-27T00:00:15Z"
          schedule_interval: "15s"
    output_batches:
      - - json_equals:
            subject: tenant-acme
            source: kubernetes-api
            type: kube-pod-exec-time

  - name: drops non billable kubernetes pod
    target_mapping: ../resources/processors/canonicalize_kubernetes.blobl
    input_batch:
      - content: |
          {"metadata":{"name":"ignored","namespace":"acme","annotations":{"openmeter.io/billable":"false"}},"spec":{"containers":[{"resources":{"limits":{},"requests":{}}}]}}
        metadata:
          schedule_time: "2026-07-27T00:00:15Z"
          schedule_interval: "15s"
    output_batches: []
```

- [ ] **Step 2: Run collector tests to verify they fail**

Run: `rpk connect test ./collector/tests/kubernetes_runtime_archive_benthos_test.yaml`

Expected: FAIL because the target mapping file does not exist yet.

- [ ] **Step 3: Write minimal collector resources and mapping**

Implement the core mapping with these behaviors:

```bloblang
let subject = this.metadata.annotations."openmeter.io/subject".or(this.metadata.name)
let billable = this.metadata.annotations."openmeter.io/billable".or("true")
root = if $billable != "true" { deleted() } else {
  "id": "sha256:kubernetes-api:%s:%s".format(this.metadata.name, meta("schedule_time")).hash("sha256"),
  "specversion": "1.0",
  "type": "kube-pod-exec-time",
  "source": "kubernetes-api",
  "time": meta("schedule_time"),
  "subject": $subject,
  "data": this.metadata.annotations.filter(item -> item.key.has_prefix("data.openmeter.io/")).map_each_key(key -> key.trim_prefix("data.openmeter.io/")).assign({
    "pod_name": this.metadata.name,
    "pod_namespace": this.metadata.namespace,
    "duration_seconds": (meta("schedule_interval").parse_duration() / 1000 / 1000 / 1000).round().int64()
  })
}
root = if !this.exists("subject") || this.subject == "" { throw("missing subject") } else { this }
```

Build the pipeline around:

```yaml
pipeline:
  processors:
    - mapping: file://./resources/processors/canonicalize_kubernetes.blobl
    - resource: welkin_validate_cloudevent

output:
  broker:
    pattern: fan_out
    outputs:
      - resource: welkin_runtime_openmeter
      - drop_on:
          output:
            resource: welkin_archive_s3
```

- [ ] **Step 4: Run collector tests to verify they pass**

Run: `rpk connect test ./collector/tests/kubernetes_runtime_archive_benthos_test.yaml`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add collector/config collector/resources collector/tests
git commit -m "feat: add collector golden path for kubernetes runtime and archive"
```

### Task 3: Package OpenMeter, collector, and archive contract with Timoni

**Files:**
- Create: `timoni/README.md`
- Create: `timoni/runtime/welkin.runtime.cue`
- Create: `timoni/bundles/welkin.bundle.cue`
- Create: `timoni/values/openmeter.cue`
- Create: `timoni/values/collector.cue`
- Create: `timoni/values/archive.cue`

**Interfaces:**
- Consumes:
  - collector files under `collector/`
  - runtime values from `timoni/runtime/welkin.runtime.cue`
- Produces:
  - Timoni bundle `timoni/bundles/welkin.bundle.cue`
  - runtime contract fields for OpenMeter token, S3 endpoint, bucket, region, access key, secret key

- [ ] **Step 1: Write the failing bundle contract**

Define these required runtime fields in `timoni/runtime/welkin.runtime.cue`:

```cue
runtime: {
  namespace:        string | *"welkin-system"
  openmeterToken:   string
  s3: {
    endpoint:       string
    bucket:         string
    region:         string | *"us-east-1"
    accessKeyID:    string
    secretAccessKey:string
    pathStyle:      bool | *true
  }
}
```

- [ ] **Step 2: Run Timoni vet to verify the bundle is missing**

Run: `timoni bundle vet -f timoni/bundles/welkin.bundle.cue -f timoni/runtime/welkin.runtime.cue`

Expected: FAIL because the bundle file does not exist yet.

- [ ] **Step 3: Write the minimal bundle and values**

Model the bundle as chart-backed instances using `flux-helm-release`:

```cue
bundle: {
  apiVersion: "v1alpha1"
  name:       "welkin"
  instances: {
    openmeter: {
      module: url: "oci://ghcr.io/stefanprodan/modules/flux-helm-release"
      namespace: runtime.namespace
      values: {
        chart: {
          repoURL: "oci://ghcr.io/openmeterio/helm-charts"
          name:    "openmeter"
        }
      }
    }
  }
}
```

Add a second `flux-helm-release` instance for `benthos-collector` and supply a values block that:
- sets `preset` to `kubernetes-pod-exec-time`
- injects custom config from `collector/config/base.yaml`
- sets `storage.enabled` where buffering is desired
- sets `metrics.prometheus.add_process_metrics` to true

- [ ] **Step 4: Run Timoni vet to verify the bundle is well-formed**

Run: `timoni bundle vet -f timoni/bundles/welkin.bundle.cue -f timoni/runtime/welkin.runtime.cue`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add timoni
git commit -m "feat: add timoni bundle for welkin substrate"
```

### Task 4: Add Flux-facing install surface and CI validation

**Files:**
- Create: `flux/README.md`
- Create: `flux/release-source.yaml`
- Create: `flux/release-kustomization.yaml`
- Create: `.github/workflows/validate.yaml`
- Create: `.github/workflows/ephemeral-smoke.yaml`

**Interfaces:**
- Consumes:
  - `timoni/bundles/welkin.bundle.cue`
  - `timoni/runtime/welkin.runtime.cue`
- Produces:
  - Flux source and reconciliation manifests
  - CI jobs for schema, collector, Timoni, and smoke validation

- [ ] **Step 1: Write the failing CI contract**

Define validation jobs that must eventually run:

```yaml
- cue vet ./collector/fixtures/canonical-event.json ./cue/schema/cloudevent.cue
- rpk connect test ./collector/tests/...
- timoni bundle vet -f timoni/bundles/welkin.bundle.cue -f timoni/runtime/welkin.runtime.cue
```

And a smoke workflow contract:

```yaml
- create ephemeral cluster
- install Flux
- deploy Welkin release source
- wait for OpenMeter and collector readiness
- inject one sample event
- assert OpenMeter and archive visibility
```

- [ ] **Step 2: Run workflow lint command to verify workflows do not exist yet**

Run: `test -f .github/workflows/validate.yaml`

Expected: FAIL because the workflow file does not exist yet.

- [ ] **Step 3: Write minimal workflows and Flux manifests**

Create Flux manifests that point at Welkin release artifacts and a validation workflow that:
- installs `cue`, `rpk`, and `timoni`
- runs schema checks
- runs collector unit tests
- runs bundle vet

Create an ephemeral smoke workflow that:
- provisions a temporary Kubernetes environment
- installs Flux
- renders or applies the Welkin release
- runs a simple end-to-end assertion path

- [ ] **Step 4: Run workflow existence checks**

Run: `test -f .github/workflows/validate.yaml && test -f .github/workflows/ephemeral-smoke.yaml`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add flux .github/workflows
git commit -m "feat: add flux install surface and ci validation"
```

### Task 5: Final operator docs and deployment handoff

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/implementation.md`
- Create: `docs/deployment.md`
- Create: `docs/operator-runbook.md`

**Interfaces:**
- Consumes:
  - all repo artifacts from Tasks 1-4
- Produces:
  - operator-facing deployment flow
  - explanation of runtime values and test-environment deployment

- [ ] **Step 1: Write the failing documentation checklist**

Document that the repo must explain:

```text
1. What Welkin owns vs what OpenMeter owns
2. How the collector canonicalizes Kubernetes events
3. How to provide runtime values without local full-stack execution
4. How to deploy into an ephemeral Kubernetes environment
5. How to validate runtime and archive success conditions
```

- [ ] **Step 2: Verify docs are still empty**

Run: `test ! -s README.md && test ! -s docs/architecture.md && test ! -s docs/implementation.md`

Expected: PASS because the files are empty before documentation is written.

- [ ] **Step 3: Write the final docs**

Document:
- the substrate model and plane boundaries
- file/folder responsibilities
- runtime values expected by Timoni
- Flux and CI workflow usage
- ephemeral deployment flow without local long-running services

- [ ] **Step 4: Verify the docs contain the deployment and validation flow**

Run: `rg -n "ephemeral|runtime values|OpenMeter|archive" README.md docs/*.md`

Expected: PASS with hits across the new docs.

- [ ] **Step 5: Commit**

```bash
git add README.md docs
git commit -m "docs: add deployment and operator handoff"
```
