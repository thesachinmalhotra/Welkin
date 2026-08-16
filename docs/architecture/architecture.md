# Welkin Architecture

## System idea

Welkin is a canonicalization and routing substrate.

It accepts heterogeneous producer events, transforms them once into canonical CloudEvents, and then routes the same canonical message into two independent planes:

- Economic Plane for metering, billing, and economic logic
- Archive Plane for preservation, replay, and historical durability

## Boundary model

### Producer edge

The producer edge is intentionally diverse. Welkin does not force uniformity before ingestion. Instead, it relies on the OpenMeter Collector ecosystem to absorb upstream variation.

### Canonicalization Engine

OpenMeter Collector is the heart of Welkin. It is responsible for:

- receiving producer events through the existing OpenMeter Collector and Redpanda Connect ecosystem
- applying source presets, connectors, and Bloblang mappings where needed
- validating the Canonical CloudEvent envelope at Welkin's substrate boundary
- dropping malformed canonical candidates
- fanning out canonical events to economic and archive outputs

Producer-specific logic belongs to the collector ecosystem before the Canonical CloudEvent boundary.

### Canonical event boundary

Once an event reaches the canonical CloudEvent contract, downstream behavior must remain identical for every producer type.

That contract is the point of architectural discipline in Welkin.

### Economic plane

OpenMeter owns economic truth:

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
