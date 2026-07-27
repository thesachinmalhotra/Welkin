# Operator Runbook

## What success looks like

A healthy Welkin deployment has:

- Flux controllers ready in `flux-system`
- OpenMeter workloads ready in the target namespace
- collector workloads ready in the target namespace
- archive credentials resolved correctly
- collector `/metrics` exposed for scraping

## Recommended validation sequence

### 1. Check control plane readiness

```bash
kubectl get pods -n flux-system
kubectl get pods -n welkin-system
```

### 2. Check collector health and metrics

```bash
kubectl logs -n welkin-system deployment/openmeter-collector --tail=200
kubectl port-forward -n welkin-system deployment/openmeter-collector 4195:4195
curl http://127.0.0.1:4195/metrics
```

### 3. Create a sample annotated workload

Use a pod with:

- `openmeter.io/subject`
- optional `data.openmeter.io/*` annotations

This follows the documented Kubernetes collector mapping model.

### 4. Confirm event movement

At minimum, validate:

- collector remains healthy after observing the workload
- collector emits no schema-validation failures for the sample path
- archive target receives data according to your S3-compatible backend checks

### 5. Troubleshoot by boundary

- If producer data is wrong: inspect the Bloblang mapping path first.
- If runtime ingestion is wrong: inspect canonical event shape and OpenMeter endpoint settings.
- If archive writes are wrong: inspect S3 endpoint, credentials, and archive batching/parquet settings.
- If one branch stalls the other: inspect `drop_on` and broker fan-out behavior.

## Notes

The current repo delivers a deployment-ready substrate and remote-validation posture. Final business-level runtime assertions, such as meter query expectations, depend on the specific OpenMeter meter definitions you configure for your environment.
