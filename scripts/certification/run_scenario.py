#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path


GO_BIN = Path.home() / "go" / "bin"
CUE_BIN = GO_BIN / "cue"
TIMONI_BIN = GO_BIN / "timoni"


def read_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def command_log(
    command: list[str],
    return_code: int,
    stdout: str = "",
    stderr: str = "",
    elapsed: float | None = None,
    include_output: bool = True,
) -> str:
    parts = [
        "COMMAND: " + " ".join(command),
        f"EXIT_CODE: {return_code}",
    ]
    if elapsed is not None:
        parts.append(f"ELAPSED_SECONDS: {elapsed:.2f}")
    if include_output:
        parts.extend(["", "STDOUT:", stdout, "", "STDERR:", stderr])
    return "\n".join(parts)


def run_command(
    command: list[str],
    artifact_dir: Path,
    log_name: str,
    *,
    stdin_text: str | None = None,
    cwd: Path | None = None,
    allow_failure: bool = False,
    include_output: bool = True,
) -> subprocess.CompletedProcess:
    started = time.time()
    completed = subprocess.run(
        command,
        cwd=str(cwd) if cwd else None,
        input=stdin_text,
        text=True,
        capture_output=True,
    )
    elapsed = time.time() - started
    write_text(
        artifact_dir / log_name,
        command_log(
            command,
            completed.returncode,
            completed.stdout,
            completed.stderr,
            elapsed,
            include_output=include_output,
        ),
    )
    if completed.returncode != 0 and not allow_failure:
        raise RuntimeError(f"command failed: {' '.join(command)}")
    return completed


def build_overlay() -> Path:
    overlay = Path("/tmp/welkin.runtime.overlay.cue")
    overlay_content = f'''package main

runtime: {{
  namespace: "welkin-system"
  charts: {{
    fluxAioVersion:    "{os.environ.get("FLUX_AIO_VERSION", "2.5.0-0")}"
    fluxModuleVersion: "{os.environ.get("FLUX_MODULE_VERSION", "2.5.0-0")}"
    openmeterVersion:  "{os.environ.get("OPENMETER_CHART_VERSION", "1.0.0-beta.232")}"
    collectorVersion:  "{os.environ.get("COLLECTOR_CHART_VERSION", "1.0.0-beta.232")}"
  }}
  openmeter: {{
    url: "{os.environ.get("OPENMETER_URL", "http://openmeter-api")}"
  }}
  archive: {{
    endpoint:        "{os.environ.get("ARCHIVE_S3_ENDPOINT", "http://minio.welkin-system.svc.cluster.local:9000")}"
    bucket:          "{os.environ.get("ARCHIVE_S3_BUCKET", "welkin-archive")}"
    region:          "{os.environ.get("ARCHIVE_S3_REGION", "us-east-1")}"
    forcePathStyle:  true
    batchCount:      250
    batchPeriod:     "15s"
  }}
}}
'''
    write_text(overlay, overlay_content)
    return overlay


MINIO_MANIFEST = """apiVersion: v1
kind: Namespace
metadata:
  name: minio
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: minio
  labels:
    app: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
        - name: minio
          image: minio/minio:latest
          args: ["server", "/data", "--console-address", ":9001"]
          ports:
            - containerPort: 9000
              name: api
            - containerPort: 9001
              name: console
          env:
            - name: MINIO_ROOT_USER
              value: "minio"
            - name: MINIO_ROOT_PASSWORD
              value: "minio123"
          readinessProbe:
            httpGet:
              path: /minio/health/ready
              port: 9000
            initialDelaySeconds: 5
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  selector:
    app: minio
  ports:
    - name: api
      port: 9000
      targetPort: 9000
    - name: console
      port: 9001
      targetPort: 9001
"""


OPENMETER_MANIFEST = """apiVersion: v1
kind: Namespace
metadata:
  name: openmeter-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: openmeter-config
  namespace: openmeter-system
data:
  config.yaml: |
    server:
      port: 8080
    storage:
      driver: memory
    ingest:
      kafka:
        broker: redpanda.openmeter-system.svc.cluster.local:9092
    sink:
      kafka:
        brokers: redpanda.openmeter-system.svc.cluster.local:9092
    aggregation:
      clickhouse:
        address: clickhouse.openmeter-system.svc.cluster.local:9000
    meters:
      - slug: kubernetes-pod-exec-time
        eventType: kube-pod-exec-time
        valueProperty: $.duration_seconds
        aggregation: SUM
        windowSize: MINUTE
---
apiVersion: v1
kind: Service
metadata:
  name: redpanda
  namespace: openmeter-system
spec:
  selector:
    app: redpanda
  ports:
    - name: kafka
      port: 9092
      targetPort: 9092
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redpanda
  namespace: openmeter-system
  labels:
    app: redpanda
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redpanda
  template:
    metadata:
      labels:
        app: redpanda
    spec:
      containers:
        - name: redpanda
          image: docker.redpanda.com/redpandadata/redpanda:v26.1.15
          command:
            - rpk
            - redpanda
            - start
            - --mode
            - dev-container
            - --kafka-addr
            - PLAIN://0.0.0.0:9092
            - --advertise-kafka-addr
            - PLAIN://redpanda.openmeter-system.svc.cluster.local:9092
            - --overprovisioned
            - --smp
            - "1"
          ports:
            - containerPort: 9092
              name: kafka
---
apiVersion: v1
kind: Service
metadata:
  name: clickhouse
  namespace: openmeter-system
spec:
  selector:
    app: clickhouse
  ports:
    - name: http
      port: 8123
      targetPort: 8123
    - name: tcp
      port: 9000
      targetPort: 9000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: clickhouse
  namespace: openmeter-system
  labels:
    app: clickhouse
spec:
  replicas: 1
  selector:
    matchLabels:
      app: clickhouse
  template:
    metadata:
      labels:
        app: clickhouse
    spec:
      containers:
        - name: clickhouse
          image: clickhouse/clickhouse-server:24.10
          env:
            - name: CLICKHOUSE_DB
              value: default
            - name: CLICKHOUSE_USER
              value: default
            - name: CLICKHOUSE_PASSWORD
              value: ""
          ports:
            - containerPort: 9000
              name: tcp
            - containerPort: 8123
              name: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openmeter
  namespace: openmeter-system
  labels:
    app: openmeter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openmeter
  template:
    metadata:
      labels:
        app: openmeter
    spec:
      containers:
        - name: openmeter
          image: ghcr.io/openmeterio/openmeter:{OPENMETER_IMAGE_TAG}
          command: ["/entrypoint.sh", "openmeter"]
          args: ["--config", "/etc/openmeter/config.yaml"]
          ports:
            - containerPort: 8080
              name: http
          readinessProbe:
            httpGet:
              path: /api/v1/meters
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          volumeMounts:
            - name: config
              mountPath: /etc/openmeter/config.yaml
              subPath: config.yaml
      volumes:
        - name: config
          configMap:
            name: openmeter-config
---
apiVersion: v1
kind: Service
metadata:
  name: openmeter-api
  namespace: openmeter-system
spec:
  selector:
    app: openmeter
  ports:
    - name: http
      port: 8080
      targetPort: 8080
"""


def setup_minio(artifact_dir: Path) -> None:
    run_command(
        ["kubectl", "apply", "-f", "-"],
        artifact_dir,
        "minio-manifest.log",
        stdin_text=MINIO_MANIFEST,
    )
    run_command(
        [
            "kubectl",
            "wait",
            "--for=condition=available",
            "deployment/minio",
            "-n",
            "minio",
            "--timeout=120s",
        ],
        artifact_dir,
        "minio-wait.log",
    )


def create_minio_bucket(artifact_dir: Path) -> None:
    run_command(
        [
            "kubectl",
            "exec",
            "-n",
            "minio",
            "deployment/minio",
            "--",
            "mc",
            "alias",
            "set",
            "local",
            "http://localhost:9000",
            "minio",
            "minio123",
        ],
        artifact_dir,
        "minio-alias.log",
        allow_failure=True,
    )
    run_command(
        [
            "kubectl",
            "exec",
            "-n",
            "minio",
            "deployment/minio",
            "--",
            "mc",
            "mb",
            "local/welkin-archive",
            "--ignore-existing",
        ],
        artifact_dir,
        "minio-create-bucket.log",
        allow_failure=True,
    )


def capture_failure_diagnostics(artifact_dir: Path) -> None:
    """Capture cluster diagnostics on failure. All commands are best-effort."""
    diag_dir = artifact_dir / "diagnostics"
    diag_dir.mkdir(parents=True, exist_ok=True)
    diagnostics = [
        (["kubectl", "get", "deployments", "-A"], "get-deployments.log"),
        (["kubectl", "describe", "deployments", "-A"], "describe-deployments.log"),
        (["kubectl", "get", "pods", "-A"], "get-pods.log"),
        (["kubectl", "describe", "pods", "-A"], "describe-pods.log"),
        (
            ["kubectl", "get", "events", "-A", "--sort-by=.metadata.creationTimestamp"],
            "get-events.log",
        ),
        (
            [
                "kubectl",
                "logs",
                "-n",
                "openmeter-system",
                "deployment/openmeter",
                "--tail=200",
            ],
            "openmeter-logs.log",
        ),
        (
            [
                "kubectl",
                "logs",
                "-n",
                "openmeter-system",
                "deployment/openmeter",
                "--tail=200",
                "--previous",
            ],
            "openmeter-logs-previous.log",
        ),
        (
            ["kubectl", "get", "pods", "-n", "openmeter-system", "-o", "yaml"],
            "openmeter-pods-yaml.log",
        ),
    ]
    for cmd, log_name in diagnostics:
        run_command(cmd, diag_dir, log_name, allow_failure=True, include_output=True)


def openmeter_image_tag() -> str:
    chart_version = os.environ.get("OPENMETER_CHART_VERSION", "1.0.0-beta.232")
    return f"v{chart_version}" if not chart_version.startswith("v") else chart_version


def setup_openmeter(artifact_dir: Path) -> None:
    run_command(
        ["kubectl", "apply", "-f", "-"],
        artifact_dir,
        "openmeter-manifest.log",
        stdin_text=OPENMETER_MANIFEST.format(OPENMETER_IMAGE_TAG=openmeter_image_tag()),
    )
    run_command(
        [
            "kubectl",
            "wait",
            "--for=condition=available",
            "deployment/redpanda",
            "-n",
            "openmeter-system",
            "--timeout=120s",
        ],
        artifact_dir,
        "redpanda-wait.log",
    )
    run_command(
        [
            "kubectl",
            "wait",
            "--for=condition=available",
            "deployment/clickhouse",
            "-n",
            "openmeter-system",
            "--timeout=120s",
        ],
        artifact_dir,
        "clickhouse-wait.log",
    )
    run_command(
        [
            "kubectl",
            "wait",
            "--for=condition=available",
            "deployment/openmeter",
            "-n",
            "openmeter-system",
            "--timeout=120s",
        ],
        artifact_dir,
        "openmeter-wait.log",
    )


def generate_exec_event(artifact_dir: Path) -> str:
    event_id = f"sha256:certification:exec-event:{int(time.time())}"
    exec_pod = (
        "apiVersion: v1\n"
        "kind: Pod\n"
        "metadata:\n"
        "  name: welkin-certification-target\n"
        "  namespace: default\n"
        "  annotations:\n"
        f"    openmeter.io/subject: {event_id}\n"
        "    data.openmeter.io/region: ci-certification\n"
        "spec:\n"
        "  restartPolicy: Never\n"
        "  containers:\n"
        "    - name: target\n"
        "      image: registry.k8s.io/pause:3.10\n"
    )
    run_command(
        ["kubectl", "apply", "-f", "-"],
        artifact_dir,
        "exec-target-pod.log",
        stdin_text=exec_pod,
    )
    run_command(
        [
            "kubectl",
            "wait",
            "--for=condition=ready",
            "pod/welkin-certification-target",
            "-n",
            "default",
            "--timeout=60s",
        ],
        artifact_dir,
        "exec-target-wait.log",
        allow_failure=True,
    )
    run_command(
        [
            "kubectl",
            "exec",
            "-n",
            "default",
            "welkin-certification-target",
            "--",
            "echo",
            "hello",
            "from",
            "certification",
        ],
        artifact_dir,
        "exec-event.log",
        allow_failure=True,
    )
    run_command(["sleep", "10"], artifact_dir, "exec-event-settle.log")
    return event_id


def assert_openmeter_received(artifact_dir: Path, event_id: str) -> bool:
    result = run_command(
        [
            "kubectl",
            "exec",
            "-n",
            "openmeter-system",
            "deployment/openmeter",
            "--",
            "wget",
            "-q",
            "-O-",
            "http://localhost:8080/api/v1/meters/kubernetes-pod-exec-time/values",
        ],
        artifact_dir,
        "openmeter-query.log",
        allow_failure=True,
    )
    output = result.stdout + result.stderr
    write_text(
        artifact_dir / "openmeter-assertion.txt",
        f"event_id: {event_id}\nopenmeter_response: {output}\n",
    )
    return "duration_seconds" in output or event_id in output


def assert_parquet_in_minio(artifact_dir: Path) -> bool:
    run_command(["sleep", "15"], artifact_dir, "archive-settle.log")
    result = run_command(
        [
            "kubectl",
            "exec",
            "-n",
            "minio",
            "deployment/minio",
            "--",
            "find",
            "/data/welkin-archive",
            "-name",
            "*.parquet",
        ],
        artifact_dir,
        "minio-list.log",
        allow_failure=True,
    )
    output = result.stdout + result.stderr
    has_parquet = ".parquet" in output
    write_text(
        artifact_dir / "minio-assertion.txt",
        f"parquet_found: {has_parquet}\nminio_find_output: {output}\n",
    )
    if has_parquet:
        run_command(
            [
                "kubectl",
                "exec",
                "-n",
                "minio",
                "deployment/minio",
                "--",
                "ls",
                "-la",
                "/data/welkin-archive/welkin/",
            ],
            artifact_dir,
            "minio-ls.log",
            allow_failure=True,
        )
    return has_parquet


def canonical_flow(artifact_dir: Path) -> tuple[str, list[str]]:
    notes: list[str] = []
    overlay = build_overlay()

    try:
        run_command(
            [
                str(CUE_BIN),
                "vet",
                "-d",
                "#CloudEvent",
                "./engine/fixtures/canonical-event.json",
                "./contracts/schema/cloudevent.cue",
            ],
            artifact_dir,
            "cue-vet.log",
        )
        run_command(
            ["rpk", "connect", "test", "./engine/tests/archive_partition_test.yaml"],
            artifact_dir,
            "rpk-connect-test.log",
        )
        run_command(
            ["kind", "create", "cluster", "--name", "welkin-certification"],
            artifact_dir,
            "kind-create.log",
        )

        setup_minio(artifact_dir)
        create_minio_bucket(artifact_dir)
        setup_openmeter(artifact_dir)

        run_command(
            [
                str(TIMONI_BIN),
                "bundle",
                "apply",
                "-f",
                "timoni/bundles/welkin.bundle.cue",
                "-f",
                "timoni/runtime/welkin.runtime.cue",
                "-f",
                "timoni/values/collector.cue",
                "-f",
                "timoni/values/openmeter.cue",
                "-f",
                str(overlay),
                "--runtime-from-env",
                "--wait",
                "--timeout=10m",
            ],
            artifact_dir,
            "timoni-apply.log",
            include_output=False,
        )

        run_command(
            [
                "kubectl",
                "wait",
                "--for=condition=ready",
                "pod",
                "-l",
                "app.kubernetes.io/name=collector",
                "-n",
                "welkin-system",
                "--timeout=120s",
            ],
            artifact_dir,
            "collector-wait.log",
            allow_failure=True,
        )

        event_id = generate_exec_event(artifact_dir)
        notes.append(f"generated event_id: {event_id}")

        run_command(["sleep", "30"], artifact_dir, "event-settle.log")

        run_command(
            ["kubectl", "get", "all", "-A"], artifact_dir, "kubectl-get-all.log"
        )
        run_command(
            ["kubectl", "get", "events", "-A", "--sort-by=.metadata.creationTimestamp"],
            artifact_dir,
            "kubectl-events.log",
        )
        run_command(
            [
                "kubectl",
                "logs",
                "-n",
                "welkin-system",
                "-l",
                "app.kubernetes.io/name=collector",
                "--tail=200",
            ],
            artifact_dir,
            "collector.log",
            allow_failure=True,
        )

        openmeter_ok = assert_openmeter_received(artifact_dir, event_id)
        parquet_ok = assert_parquet_in_minio(artifact_dir)

        notes.append(f"openmeter_assertion: {'passed' if openmeter_ok else 'failed'}")
        notes.append(f"parquet_assertion: {'passed' if parquet_ok else 'failed'}")

        if not openmeter_ok:
            notes.append("OpenMeter did not confirm receipt of the test event")
        if not parquet_ok:
            notes.append("No parquet file found in MinIO archive bucket")

    except Exception as exc:
        notes.append(str(exc))
        capture_failure_diagnostics(artifact_dir)
        result = "failed"
    else:
        if openmeter_ok and parquet_ok:
            result = "passed"
        else:
            result = "failed"
            notes.append("end-to-end assertions did not all pass")
    finally:
        run_command(
            ["kind", "delete", "cluster", "--name", "welkin-certification"],
            artifact_dir,
            "kind-delete.log",
            allow_failure=True,
        )

    return result, notes


def malformed_boundary(artifact_dir: Path) -> tuple[str, list[str]]:
    command = [
        str(CUE_BIN),
        "vet",
        "-d",
        "#CloudEvent",
        "certification/fixtures/malformed-canonical-event.json",
        "./contracts/schema/cloudevent.cue",
    ]
    completed = subprocess.run(command, capture_output=True, text=True)
    write_text(
        artifact_dir / "cue-vet.log",
        command_log(
            command,
            completed.returncode,
            completed.stdout,
            completed.stderr,
            include_output=True,
        ),
    )

    if completed.returncode == 0:
        return "failed", ["malformed canonical input unexpectedly validated"]
    return "passed", [
        f"expected cue vet failure observed with exit code {completed.returncode}"
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description="Run a Welkin certification scenario")
    parser.add_argument("--catalog", required=True, type=Path)
    parser.add_argument("--scenario", required=True, type=Path)
    parser.add_argument("--artifact-dir", required=True, type=Path)
    args = parser.parse_args()

    args.artifact_dir.mkdir(parents=True, exist_ok=True)

    catalog = read_json(args.catalog)
    scenario = read_json(args.scenario)

    if scenario["id"] == "canonical-flow":
        result, notes = canonical_flow(args.artifact_dir)
    elif scenario["id"] == "malformed-boundary":
        result, notes = malformed_boundary(args.artifact_dir)
    else:
        result = "planned"
        notes = ["scenario is scaffolded and not yet executable"]

    context = {
        "catalog": catalog,
        "scenario": scenario,
        "result": result,
        "notes": notes,
    }
    write_text(args.artifact_dir / "context.json", json.dumps(context, indent=2) + "\n")

    subprocess.run(
        [
            sys.executable,
            str(Path("scripts/certification/render_evidence.py")),
            "--catalog",
            str(args.catalog),
            "--scenario",
            str(args.scenario),
            "--artifact-dir",
            str(args.artifact_dir),
            "--result",
            result,
        ],
        check=True,
    )

    write_text(
        args.artifact_dir / "result.txt",
        result + "\n" + "\n".join(notes) + ("\n" if notes else ""),
    )

    if result == "failed":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
