package certification

#Guarantee: {
	id: string & != ""
	title: string & != ""
	claim: string & != ""
	verification: string & != ""
	status: "implemented" | "scaffolded" | "planned"
	scenarios: [...string]
	evidence: [...string]
}

#Scenario: {
	id: string & != ""
	title: string & != ""
	purpose: string & != ""
	mode: "contract" | "mock-prod" | "reproducibility"
	status: "implemented" | "scaffolded" | "planned"
	guarantees: [...string]
	verification: [...string]
	evidence: [...string]
	notes?: string
}

catalog: {
	guarantees: {
		canonical_event_boundary: #Guarantee & {
			id: "canonical-event-boundary"
			title: "One canonical CloudEvent boundary"
			claim: "Every producer becomes one canonical CloudEvent before downstream consumers see it."
			verification: "Validate the canonical CloudEvent contract and the collector's canonicalization path."
			status: "implemented"
			scenarios: ["canonical-flow"]
			evidence: ["cue-vet output", "collector fixture output", "workflow summary", "artifact bundle"]
		}

		malformed_event_rejection: #Guarantee & {
			id: "malformed-event-rejection"
			title: "Malformed events fail at the correct boundary"
			claim: "Malformed canonical candidates fail before runtime or archive fan-out."
			verification: "Exercise invalid canonical data against the canonical contract and confirm the failure is raised at the collector boundary."
			status: "implemented"
			scenarios: ["malformed-boundary"]
			evidence: ["expected failure output", "contract validation log", "scenario summary"]
		}

		economic_archive_independence: #Guarantee & {
			id: "economic-archive-independence"
			title: "Economic and archive remain independent"
			claim: "Archive degradation must not prevent economic delivery."
			verification: "Inject archive failure and prove the economic branch continues to accept canonical events."
			status: "scaffolded"
			scenarios: ["plane-independence"]
			evidence: ["archive failure injection log", "economic continuity log", "branch separation evidence"]
		}

		duplicate_billing_prevention: #Guarantee & {
			id: "duplicate-billing-prevention"
			title: "Duplicate events do not become duplicate billing"
			claim: "Replay does not produce duplicate economic effects."
			verification: "Replay the same canonical event batch and compare the billing-facing result set."
			status: "planned"
			scenarios: ["duplicate_billing"]
			evidence: ["replay log", "OpenMeter query result", "dedup comparison"]
		}

		producer_diversity_preserved: #Guarantee & {
			id: "producer-diversity-preserved"
			title: "Producer diversity only affects the edge"
			claim: "Different upstream producer families converge to the same downstream substrate."
			verification: "Run multiple producer families through the collector and diff the canonical downstream shape."
			status: "planned"
			scenarios: ["producer_diversity"]
			evidence: ["preset matrix", "canonical shape diff", "producer trace bundle"]
		}

		clean_room_reproducibility: #Guarantee & {
			id: "clean-room-reproducibility"
			title: "Deployment stays reproducible from a clean environment"
			claim: "A fresh cluster can be brought to the Welkin substrate without manual laptop setup."
			verification: "Provision a clean environment and apply the release through the same composition path."
			status: "implemented"
			scenarios: ["canonical-flow"]
			evidence: ["cluster bootstrap log", "Timoni render", "Flux reconciliation log", "artifact bundle"]
		}
	}

	scenarios: {
		canonical_flow: #Scenario & {
			id: "canonical-flow"
			title: "Canonical flow from clean environment"
			purpose: "Certify the baseline happy path and clean-room deployment behavior."
			mode: "mock-prod"
			status: "implemented"
			guarantees: ["canonical-event-boundary", "clean-room-reproducibility"]
			verification: ["provision a fresh kind cluster", "apply the Welkin bundle", "inject one annotated Kubernetes workload", "capture cluster state and collector logs"]
			evidence: ["kind cluster state", "Timoni rendered bundle", "kubectl resource snapshot", "collector logs", "workflow summary"]
		}

		malformed_boundary: #Scenario & {
			id: "malformed-boundary"
			title: "Malformed canonical input fails early"
			purpose: "Certify that bad canonical candidates are rejected before they can contaminate the runtime or archive planes."
			mode: "contract"
			status: "implemented"
			guarantees: ["malformed-event-rejection"]
			verification: ["run the malformed fixture through the canonical schema", "assert the validation failure is preserved as evidence", "confirm the scenario does not reach deployment steps"]
			evidence: ["cue vet failure output", "scenario summary", "catalog validation log"]
		}

		plane_independence: #Scenario & {
			id: "plane-independence"
			title: "Runtime survives archive failure"
			purpose: "Prove the runtime branch continues when archive delivery is degraded."
			mode: "mock-prod"
			status: "scaffolded"
			guarantees: ["economic-archive-independence"]
			verification: ["inject archive-side failure", "observe economic continuity", "compare branch-specific logs"]
			evidence: ["archive failure log", "economic continuity log", "branch independence summary"]
			notes: "This is scaffolded because the repo does not yet include a dedicated failure-injection harness for the archive plane."
		}

		duplicate_billing: #Scenario & {
			id: "duplicate-billing"
			title: "Replay does not duplicate billing"
			purpose: "Certify idempotency against duplicate inputs."
			mode: "reproducibility"
			status: "planned"
			guarantees: ["duplicate-billing-prevention"]
			verification: ["replay the same canonical batch", "query the billing-facing result set", "diff the counts"]
			evidence: ["OpenMeter query result", "dedup diff", "replay log"]
		}

		producer_diversity: #Scenario & {
			id: "producer-diversity"
			title: "Different producers produce the same downstream shape"
			purpose: "Certify that collector presets can vary while the canonical downstream path stays unchanged."
			mode: "mock-prod"
			status: "planned"
			guarantees: ["producer-diversity-preserved"]
			verification: ["run multiple upstream producer families", "capture canonical output from each", "diff the downstream shape"]
			evidence: ["preset matrix", "canonical shape diff", "producer trace bundle"]
		}
	}
}
