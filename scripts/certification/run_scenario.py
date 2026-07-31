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


def command_log(command: list[str], return_code: int, stdout: str = "", stderr: str = "", elapsed: float | None = None, include_output: bool = True) -> str:
    parts = [
        "COMMAND: " + " ".join(command),
        f"EXIT_CODE: {return_code}",
    ]
    if elapsed is not None:
        parts.append(f"ELAPSED_SECONDS: {elapsed:.2f}")
    if include_output:
        parts.extend(["", "STDOUT:", stdout, "", "STDERR:", stderr])
    return "\n".join(parts)


def run_command(command: list[str], artifact_dir: Path, log_name: str, *, stdin_text: str | None = None, cwd: Path | None = None, allow_failure: bool = False, include_output: bool = True) -> int:
    started = time.time()
    completed = subprocess.run(
        command,
        cwd=str(cwd) if cwd else None,
        input=stdin_text,
        text=True,
        capture_output=True,
    )
    elapsed = time.time() - started
    write_text(artifact_dir / log_name, command_log(command, completed.returncode, completed.stdout, completed.stderr, elapsed, include_output=include_output))
    if completed.returncode != 0 and not allow_failure:
        raise RuntimeError(f"command failed: {' '.join(command)}")
    return completed.returncode


def build_overlay() -> Path:
    overlay = Path("/tmp/welkin.runtime.overlay.cue")
    overlay_content = f'''package main

runtime: {{
  namespace: "welkin-system"
  openmeter: {{
    token: "{os.environ.get('OPENMETER_TOKEN', '')}"
  }}
  archive: {{
    endpoint:        "{os.environ.get('ARCHIVE_S3_ENDPOINT', 'http://minio.minio.svc.cluster.local:9000')}"
    bucket:          "{os.environ.get('ARCHIVE_S3_BUCKET', 'welkin-archive')}"
    region:          "{os.environ.get('ARCHIVE_S3_REGION', 'us-east-1')}"
    accessKeyID:     "{os.environ.get('ARCHIVE_S3_ACCESS_KEY_ID', 'welkin')}"
    secretAccessKey: "{os.environ.get('ARCHIVE_S3_SECRET_ACCESS_KEY', 'welkin-secret')}"
  }}
}}
'''
    write_text(overlay, overlay_content)
    return overlay


def canonical_flow(artifact_dir: Path) -> tuple[str, list[str]]:
    notes: list[str] = []
    overlay = build_overlay()

    try:
        run_command([str(CUE_BIN), "vet", "./collector/fixtures/canonical-event.json", "./cue/schema/cloudevent.cue"], artifact_dir, "cue-vet.log")
        run_command(["rpk", "connect", "test", "./collector/tests/kubernetes_runtime_archive_benthos_test.yaml"], artifact_dir, "rpk-connect-test.log")
        run_command(["kind", "create", "cluster", "--name", "welkin-certification"], artifact_dir, "kind-create.log")
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
                str(overlay),
                "--wait",
                "--timeout=10m",
            ],
            artifact_dir,
            "timoni-apply.log",
            include_output=False,
        )
        run_command(["kubectl", "create", "namespace", "smoke"], artifact_dir, "kubectl-create-namespace.log", allow_failure=True)
        run_command(
            ["kubectl", "apply", "-f", "-"],
            artifact_dir,
            "kubectl-apply-smoke-pod.log",
            stdin_text=(
                "apiVersion: v1\n"
                "kind: Pod\n"
                "metadata:\n"
                "  name: welkin-certification-smoke\n"
                "  namespace: smoke\n"
                "  annotations:\n"
                "    openmeter.io/subject: tenant-smoke\n"
                "    data.openmeter.io/region: ci\n"
                "spec:\n"
                "  restartPolicy: Never\n"
                "  containers:\n"
                "    - name: pause\n"
                "      image: registry.k8s.io/pause:3.10\n"
            ),
        )
        run_command(["sleep", "45"], artifact_dir, "sleep.log")
        run_command(["kubectl", "get", "all", "-A"], artifact_dir, "kubectl-get-all.log")
        run_command(["kubectl", "get", "events", "-A", "--sort-by=.metadata.creationTimestamp"], artifact_dir, "kubectl-events.log")
        run_command(["kubectl", "logs", "-n", "welkin-system", "deployment/openmeter-collector", "--tail=200"], artifact_dir, "collector.log", allow_failure=True)
    except Exception as exc:
        notes.append(str(exc))
        result = "failed"
    else:
        result = "passed"
    finally:
        if Path("/usr/local/bin/kind").exists() or Path("/bin/kind").exists() or Path("/usr/bin/kind").exists() or Path("kind").exists():
            run_command(["kind", "delete", "cluster", "--name", "welkin-certification"], artifact_dir, "kind-delete.log", allow_failure=True)

    return result, notes


def malformed_boundary(artifact_dir: Path) -> tuple[str, list[str]]:
    command = [str(CUE_BIN), "vet", "certification/fixtures/malformed-canonical-event.json", "./cue/schema/cloudevent.cue"]
    completed = subprocess.run(command, capture_output=True, text=True)
    write_text(artifact_dir / "cue-vet.log", command_log(command, completed.returncode, completed.stdout, completed.stderr, include_output=True))

    if completed.returncode == 0:
        return "failed", ["malformed canonical input unexpectedly validated"]
    return "passed", [f"expected cue vet failure observed with exit code {completed.returncode}"]


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

    write_text(args.artifact_dir / "result.txt", result + "\n" + "\n".join(notes) + ("\n" if notes else ""))

    if result == "failed":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
