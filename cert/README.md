# Certification Catalog

This directory defines Welkin's architectural verification model.

## What lives here

- `catalog.cue` is the source of truth for the guarantees Welkin claims, how each guarantee is verified, and what evidence each scenario should produce.
- `fixtures/` holds negative or certification-oriented inputs that are meant to fail at the correct boundary.

## Current status

Implemented scenarios:
- `canonical_flow`
- `malformed_boundary`

Scaffolded or planned scenarios:
- `plane_independence`
- `duplicate_billing`
- `producer_diversity`

## Principle

A certification scenario is only valuable if it proves an architectural claim. If an invariant cannot yet be exercised automatically, the catalog marks it as scaffolded or planned instead of disguising it as a weak test.
