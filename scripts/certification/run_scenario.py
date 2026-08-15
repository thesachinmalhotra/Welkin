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


CERTIFICATION_JOB = """apiVersion: batch/v1
kind: Job
metadata:
  name: welkin-certification
  namespace: welkin-system
  labels:
    app.kubernetes.io/name: welkin-certification
    app.kubernetes.io/part-of: welkin
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    metadata:
      labels:
        app.kubernetes.io/name: welkin-certification
    spec:
      restartPolicy: Never
      containers:
        - name: certify
          image: curlimages/curl:8.5.0
          command: ["/bin/sh", "/scripts/certify.sh"]
          volumeMounts:
            - name: scripts
              mountPath: /scripts
              readOnly: true
      volumes:
        - name: scripts
          configMap:
            name: welkin-certify-script
            defaultMode: 0755
"""


def run_certification_job(artifact_dir: Path) -> tuple[bool, str]:
    """Create the certification Job, wait for completion, capture logs."""
    script_path = Path("scripts/certification/certify.sh")
    render = subprocess.run(
        [
            "kubectl",
            "create",
            "configmap",
            "welkin-certify-script",
            "--from-file=certify.sh=" + str(script_path),
            "-n",
            "welkin-system",
            "--dry-run=client",
            "-o=yaml",
        ],
        capture_output=True,
        text=True,
    )
    run_command(
        ["kubectl", "apply", "-f", "-"],
        artifact_dir,
        "configmap-apply.log",
        stdin_text=render.stdout,
    )
    run_command(
        ["kubectl", "apply", "-f", "-"],
        artifact_dir,
        "certification-job-create.log",
        stdin_text=CERTIFICATION_JOB,
    )

    deadline = time.time() + 10 * 60
    while time.time() < deadline:
        result = subprocess.run(
            [
                "kubectl",
                "get",
                "job",
                "welkin-certification",
                "-n",
                "welkin-system",
                "-o",
                "jsonpath={.status.conditions[?(@.type=='Complete')].status}",
            ],
            capture_output=True,
            text=True,
        )
        if result.stdout.strip() == "True":
            break
        fail = subprocess.run(
            [
                "kubectl",
                "get",
                "job",
                "welkin-certification",
                "-n",
                "welkin-system",
                "-o",
                "jsonpath={.status.conditions[?(@.type=='Failed')].status}",
            ],
            capture_output=True,
            text=True,
        )
        if fail.stdout.strip() == "True":
            break
        time.sleep(5)
    else:
        write_text(
            artifact_dir / "certification-timeout.log",
            "Job did not complete within 10 minutes\n",
        )
        return False, "certification job timed out"

    logs = subprocess.run(
        ["kubectl", "logs", "-n", "welkin-system", "job/welkin-certification"],
        capture_output=True,
        text=True,
    )
    write_text(
        artifact_dir / "certification-job.log",
        command_log(
            ["kubectl", "logs", "job/welkin-certification"],
            logs.returncode,
            logs.stdout,
            logs.stderr,
        ),
    )

    status = subprocess.run(
        [
            "kubectl",
            "get",
            "job",
            "welkin-certification",
            "-n",
            "welkin-system",
            "-o",
            "json",
        ],
        capture_output=True,
        text=True,
    )
    write_text(artifact_dir / "certification-job-status.json", status.stdout)

    succeeded = (
        "passed" in logs.stdout.lower() or '"succeeded":1' in status.stdout.lower()
    )
    return succeeded, logs.stdout


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
                "timoni/values/postgres.cue",
                "-f",
                "timoni/values/minio.cue",
                "-f",
                str(overlay),
                "--runtime-from-env",
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
                "app.kubernetes.io/name=openmeter-api",
                "-n",
                "welkin-system",
                "--timeout=300s",
            ],
            artifact_dir,
            "wait-openmeter.log",
            allow_failure=True,
        )
        run_command(
            [
                "kubectl",
                "wait",
                "--for=condition=ready",
                "pod",
                "-l",
                "app.kubernetes.io/name=benthos-collector",
                "-n",
                "welkin-system",
                "--timeout=300s",
            ],
            artifact_dir,
            "wait-collector.log",
            allow_failure=True,
        )

        job_ok, job_output = run_certification_job(artifact_dir)
        notes.append(f"certification_job: {'passed' if job_ok else 'failed'}")
        notes.append(job_output[:500])

        run_command(
            ["kubectl", "get", "all", "-A"], artifact_dir, "kubectl-get-all.log"
        )

    except Exception as exc:
        notes.append(str(exc))
        capture_failure_diagnostics(artifact_dir)
        result = "failed"
    else:
        result = "passed" if job_ok else "failed"
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


def capture_failure_diagnostics(artifact_dir: Path) -> None:
    diag_dir = artifact_dir / "diagnostics"
    diag_dir.mkdir(parents=True, exist_ok=True)
    for cmd, name in [
        (["kubectl", "get", "deployments", "-A"], "get-deployments.log"),
        (["kubectl", "get", "pods", "-A"], "get-pods.log"),
        (
            ["kubectl", "get", "events", "-A", "--sort-by=.metadata.creationTimestamp"],
            "get-events.log",
        ),
        (
            ["kubectl", "logs", "-n", "welkin-system", "job/welkin-certification"],
            "certification-job.log",
        ),
    ]:
        run_command(cmd, diag_dir, name, allow_failure=True, include_output=True)


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
