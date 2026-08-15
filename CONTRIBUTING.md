# Contributing to Welkin

This guide is for humans and AI agents alike. Follow it when working on Welkin.

## First principles

Read `AGENTS.md` before anything else. It defines the architecture, invariants, and philosophy. When in doubt, `AGENTS.md` is the authority.

**Compose, don't build.** Prefer upstream-native components, open standards, and clean composition over custom infrastructure.

## Commit messages

Welkin uses [Conventional Commits](https://www.conventionalcommits.org/). Every commit message must match:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Scopes:** `cert`, `openmeter`, `collector`, `flux`, `timoni`, `ci`, `certification`, `contracts`

**Examples:**
```
fix(cert): wire event data flow through collector boundary
feat(collector): add http_server input for canonical CloudEvent ingestion
docs: update operator-runbook with collector health checks
chore(ci): pin commitizen version in pre-commit config
```

**Rules:**
- Subject line max 72 characters, no period, imperative mood
- Type is always lowercase
- Body wraps at 120 characters
- Reference issues with `Closes #123` or `Refs SAC-7`

## Branch naming

```
<type>/<short-description>
```

Examples: `fix/collector-http-input`, `feat/minio-lego`, `docs/certification-runbook`

## Pull requests

Use the PR template (`.github/PULL_REQUEST_TEMPLATE.md`). Every PR must:

1. **State what** it does (one sentence)
2. **State why** it's needed (link to issue or explain)
3. **State how** it works (approach, tradeoffs)
4. **Identify the architectural boundary** it touches
5. **Show verification** (commands run, results)

## Local validation

Before pushing, run the checks that apply to your changes:

| Change type | Run this |
|---|---|
| CUE files | `cue vet` on the relevant schemas |
| Benthos config | `rpk connect test engine/tests/*.yaml` |
| Timoni bundle | `timoni bundle vet -f timoni/bundles/welkin.bundle.cue -f timoni/runtime/welkin.runtime.cue -f timoni/values/collector.cue -f timoni/values/openmeter.cue --runtime-from-env` |
| Python scripts | `python3 -m py_compile scripts/certification/*.py` |
| Commit messages | `pre-commit run commitizen --hook-stage commit-msg` |

**No CI run until local checks are green.**

## File organization

| Path | What lives here |
|---|---|
| `AGENTS.md` | Architecture, invariants, agent instructions |
| `contracts/schema/` | Canonical CloudEvent and archive schemas |
| `timoni/bundles/` | Platform composition (Timoni bundles) |
| `timoni/runtime/` | Runtime contracts (Platform State) |
| `timoni/values/` | Per-component Helm values (collector, openmeter) |
| `engine/` | Collector test fixtures, Bloblang presets, rpk tests |
| `certification/` | Certification catalog and evidence model |
| `scripts/certification/` | Certification harness scripts |
| `.github/workflows/` | CI workflows |

## What NOT to do

- Do not add custom services, controllers, or SDKs
- Do not embed infrastructure manifests in Python scripts
- Do not hardcode credentials in Platform State (`.cue` files)
- Do not use `@latest` or unpinned versions
- Do not bypass the collector boundary (always POST to `:4195/events`)
- `engine/config/base.yaml` was deleted in Phase 1 — collector config lives only in `timoni/values/collector.cue`
- Do not commit secrets, tokens, or keys

## AI agents

If you are an AI agent working on Welkin:

1. Read `AGENTS.md` first — it overrides everything
2. Use the Plan mode before non-trivial changes
3. Run local validation before claiming work is done
4. Follow conventional commits
5. Respect architectural invariants — never silently expand scope
6. When evidence conflicts with an assumption, surface the conflict

## Release process

Welkin uses semantic versioning. Changelog is auto-generated from conventional commits.

```bash
# Install commitizen (one-time)
pip install commitizen

# Bump version and generate changelog
cz bump --changelog

# Push with tags
git push --follow-tags
```
