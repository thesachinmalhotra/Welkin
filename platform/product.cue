package main

// Welkin Product — the immutable definition of what a Welkin release IS.
// Component versions, product semantics and defaults live here. Nothing in
// this file is environment-specific or runtime-injectable.
//
// Environment configuration lives in platform/runtime/welkin.runtime.cue.

product: {
  charts: {
    fluxAioVersion:    "2.9.4-0"
    fluxModuleVersion: "2.9.4-0"
    openmeterVersion:  "1.0.0-beta.232"
    collectorVersion:  "1.0.0-beta.232"
  }

  // Derived from the collector chart version — single source, no drift.
  collectorImage: {
    repository: "ghcr.io/openmeterio/benthos-collector"
    tag:        "v\(charts.collectorVersion)"
  }

  // Archive plane semantics (product defaults, not environment knobs).
  archive: {
    batchCount:  250
    batchPeriod: "15s"
  }
}
