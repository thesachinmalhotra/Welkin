FILE_OPTS = -f platform/bundles/welkin.bundle.cue
FILE_OPTS += -f platform/runtime/welkin.runtime.cue
FILE_OPTS += -f platform/collector/collector.cue
FILE_OPTS += -f platform/economic/openmeter.cue
FILE_OPTS += -f platform/economic/postgres.cue
FILE_OPTS += -f platform/archive/minio.cue
BUNDLE = platform/bundles/welkin.bundle.cue

.PHONY: vet diff print-value build apply status ci-test ci-diff

## vet: validate the Timoni bundle against its runtime (no cluster)
vet:
	timoni bundle vet $(FILE_OPTS) --runtime-from-env

## diff: preview cluster-state changes before applying
diff:
	timoni bundle apply $(FILE_OPTS) --runtime-from-env --diff

## print-value: print the computed runtime-injected values
print-value:
	timoni bundle vet $(FILE_OPTS) --runtime-from-env --print-value

## build: render the bundle to multi-doc YAML without applying
build:
	timoni bundle build $(FILE_OPTS) --runtime-from-env

## apply: deploy/upgrade the bundle across the current cluster
apply:
	timoni bundle apply $(FILE_OPTS) --runtime-from-env

## status: show applied instances, module URL and digest
status:
	timoni bundle status -f $(BUNDLE)

## ci-test: Run CI validation + behavioral test locally
ci-test: vet build
	@echo "Running behavioral test via rpk connect test..."
	@make build > /tmp/bundle.yaml
	@yq eval '.[] | select(.kind=="HelmRelease" and .metadata.name=="collector") | .spec.values.config' /tmp/bundle.yaml > /tmp/collector-config.yaml
	@docker run --rm \
		-v /tmp/collector-config.yaml:/config.yaml \
		-v "$(CURDIR)/platform/collector/collector_benthos_test.yaml":/test.yaml \
		ghcr.io/openmeterio/benthos-collector:v1.0.0-beta.232 \
		rpk connect test /config.yaml -t /test.yaml

## ci-diff: Diff artifact against latest on GHCR
ci-diff: build
	@make build > /tmp/bundle.yaml
	@flux diff artifact oci://ghcr.io/thesachinmalhotra/Welkin/welkin:latest \
		--path /tmp/bundle.yaml || echo "Changes detected"