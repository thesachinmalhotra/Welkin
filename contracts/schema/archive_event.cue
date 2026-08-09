package schema

#ArchiveEvent: {
	event: #CloudEvent
	partition: {
		source:    string & != ""
		eventType: string & != ""
		day:       string & != ""
	}
}
