# Welkin CUE Contracts

This directory holds the canonical contracts for Welkin v1.

- `schema/cloudevent.cue` defines the canonical CloudEvent envelope that every producer must reach before runtime and archive fan-out.
- `schema/archive_event.cue` defines the archive-oriented record shape derived from the canonical event.

These contracts are intended to be validated in CI and reused by Timoni runtime values and deployment packaging.
