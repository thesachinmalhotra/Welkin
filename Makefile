FILE_OPTS_DEV = -f platform/bundles/welkin-dev.bundle.cue
FILE_OPTS_DEV += -f platform/runtime/welkin.runtime.cue
FILE_OPTS_DEV += -f spec/meters/meters.cue
FILE_OPTS_DEV += -f platform/collector/collector.cue
FILE_OPTS_DEV += -f platform/economic/openmeter.cue
FILE_OPTS_DEV += -f platform/economic/postgres.cue
FILE_OPTS_DEV += -f platform/archive/minio.cue

FILE_OPTS_PROD = -f platform/bundles/welkin-prod.bundle.cue
FILE_OPTS_PROD += -f platform/runtime/welkin.runtime.cue
FILE_OPTS_PROD += -f spec/meters/meters.cue
FILE_OPTS_PROD += -f platform/collector/collector.cue
FILE_OPTS_PROD += -f platform/economic/openmeter.cue
BUNDLE = platform/bundles/welkin-dev.bundle.cue

.PHONY: vet diff print-value build apply status vet-dev build-dev vet-prod build-prod

## vet: validate the Timoni bundle against its runtime (no cluster)
vet:
	timoni bundle vet $(FILE_OPTS_DEV) --runtime-from-env

## diff: preview cluster-state changes before applying
diff:
	timoni bundle apply $(FILE_OPTS_DEV) --runtime-from-env --diff

## print-value: print the computed runtime-injected values
print-value:
	timoni bundle vet $(FILE_OPTS_DEV) --runtime-from-env --print-value

## vet-dev: validate the dev bundle
vet-dev:
	timoni bundle vet $(FILE_OPTS_DEV) --runtime-from-env

## build-dev: build the dev bundle
build-dev:
	timoni bundle build $(FILE_OPTS_DEV) --runtime-from-env

## vet-prod: validate the prod bundle
vet-prod:
	timoni bundle vet $(FILE_OPTS_PROD) --runtime-from-env

## build-prod: build the prod bundle
build-prod:
	timoni bundle build $(FILE_OPTS_PROD) --runtime-from-env

## build: render the bundle to multi-doc YAML without applying
build:
	timoni bundle build $(FILE_OPTS_DEV) --runtime-from-env

## apply: deploy/upgrade the bundle across the current cluster
apply:
	timoni bundle apply $(FILE_OPTS_DEV) --runtime-from-env

## status: show applied instances, module URL and digest
status:
	timoni bundle status -f $(BUNDLE)
