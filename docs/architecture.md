# Welkin Architecture

## System idea

Welkin is a canonicalization and routing substrate.

It accepts heterogeneous producer events, transforms them once into canonical CloudEvents, and then routes the same canonical message into two independent planes:

- Runtime Plane for metering, billing, and economic logic
- Archive Plane for preservation, replay, and historical durability

## Boundary model

### Producer edge

The producer edge is intentionally diverse. Welkin does not force uniformity before ingestion. Instead, it relies on the OpenMeter Collector ecosystem to absorb upstream variation.

### Collector core

The collector is the heart of Welkin. It is responsible for:

- receiving producer events
- reshaping them with Bloblang
- validating the canonical CloudEvent envelope
- dropping malformed or non-billable events
- fanning out canonical events to runtime and archive outputs

Producer-specific logic must stop here.

### Canonical event boundary

Once an event reaches the canonical CloudEvent contract, downstream behavior must remain identical for every producer type.

That contract is the point of architectural discipline in Welkin.

### Runtime plane

OpenMeter owns runtime truth:

- ingestion of canonical events
- usage metering
- billing-adjacent semantics
- downstream Stripe integration where applicable

Welkin does not reimplement runtime business logic.

### Archive plane

The archive plane owns historical truth:

- canonical event preservation
- Parquet encoding
- durable object storage writes
- replayable event history

It is not an analytics platform in v1.

## Deployment shape

Welkin is delivered as declarative infrastructure:

- CUE for contracts and runtime input structure
- Timoni for bundle packaging
- Flux for release reconciliation
- Helm chart interoperability for OpenMeter and the collector

This keeps each component in its native ecosystem rather than wrapping it in custom control-plane code.
