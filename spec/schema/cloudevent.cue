package schema

#CloudEvent: {
	id:          string & != ""
	specversion: "1.0"
	type:        string & != ""
	source:      string & != ""
	time:        string & != ""
	subject:     string & != ""
	data!:       [string]: _
	...
}
