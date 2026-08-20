# Collector Configuration

Welkin uses the [OpenMeter Collector](https://github.com/openmeterio/openmeter-collector) via a Timoni module. Configure it by setting these environment variables:

- `OPENMETER_URL`: URL of the OpenMeter API.
- `OPENMETER_TOKEN`: Authentication token for OpenMeter.

## Presets
Use upstream presets (e.g., Kubernetes) instead of custom Benthos configs. See the [Collector presets documentation](https://github.com/openmeterio/openmeter-collector/tree/main/presets).