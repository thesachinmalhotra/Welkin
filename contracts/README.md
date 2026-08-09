# Welkin Contracts

This directory holds the canonical contracts for Welkin v1.

- `schema/cloudevent.cue` defines the Canonical CloudEvent envelope that every producer must reach before runtime and archive fan-out.
- `schema/archive_event.cue` defines the Archive Event record shape derived from the canonical event.

These contracts are validated in CI and reused by Timoni runtime values and deployment packaging.
