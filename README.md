# Dynatrace AI Skills

Reusable Agent Skills for working with Dynatrace across Claude Code, GitHub Copilot, Cursor, Gemini CLI, and other compatible agents.

This repo is the **skills repo**:

- reusable `SKILL.md` packages
- skill-specific references and assets
- shared harness logic
- generic prompt templates

For the packaged SE POC persona/wrapper, see the separate [dynatrace-se-poc-agent](https://github.com/pushpendrasinghbaghel-ai/dynatrace-se-poc-agent) repo.

## Installation

### Skills package (Claude Code, Copilot, Cursor, Gemini CLI — coding surfaces)

```bash
npx skills add pushpendrasinghbaghel-ai/dynatrace-ai-skills
```

Install one skill if you only need a specific workflow:

```bash
npx skills add pushpendrasinghbaghel-ai/dynatrace-ai-skills --skill dt-tenant-setup
```

### Claude plugin (Claude chat, Cowork, and Claude Code)

This repo is also a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`), so it
installs as a single plugin and its skills become available not just in Claude Code, but also in
the **Cowork** tab and regular Claude chat — this is what surfaces non-code skills like
[dynatrace-deck](skills/dynatrace-deck/SKILL.md) outside a coding context:

```shell
/plugin marketplace add pushpendrasinghbaghel-ai/dynatrace-ai-skills
/plugin install dynatrace-ai-skills@dynatrace-ai-skills
```

Then run `/reload-plugins` if prompted. Skills load namespaced, e.g.
`/dynatrace-ai-skills:dynatrace-deck`, and are also auto-invoked by Claude when relevant to your
request (no slash command needed) once the plugin is installed.

### Manual install

Copy a skill folder into your agent's skills path:

```bash
git clone https://github.com/pushpendrasinghbaghel-ai/dynatrace-ai-skills.git
cp -r dynatrace-ai-skills/skills/<skill-name> ~/.claude/skills/
```

## What this repo covers

### Local SE / POC overlay

- tenant onboarding and CLI context setup
- settings lifecycle and bulk config changes
- OpenPipeline lifecycle
- HTTP business-event capture
- telemetry readiness and custom log / OTel variants
- alert lifecycle and routing
- POC orchestration and handover structure

### Official upstream Dynatrace skills to include for completeness

Treat these as part of the capability pack; do not duplicate them here:

- `dt-dql-essentials`
- `dt-obs-services`
- `dt-obs-frontends`
- `dt-obs-tracing`
- `dt-obs-hosts`
- `dt-obs-kubernetes`
- `dt-obs-aws`
- `dt-obs-azure`
- `dt-obs-gcp`
- `dt-obs-logs`
- `dt-obs-problems`
- `dt-obs-predictive-analytics`
- `dt-alerting`
- `dt-obs-analytics`
- `dt-obs-ext-monitors`
- `dt-obs-genai`
- `dt-obs-log-semantic-mapping`
- `dt-sec-insights`
- `dt-sec-contextualization`
- `dt-sec-ioc-hunting`
- `dt-sec-semantic-mapping`
- `dt-obs-android`
- `dt-obs-flutter`
- `dt-obs-ios`
- `dt-obs-react-native`
- `dt-app-dashboards`
- `dt-app-notebooks`
- `dt-js-runtime`
- `dt-platform-costs`
- `dt-migration`

## Completeness boundary

With the official Dynatrace skills installed, this repo can cover the **majority** of non-UI Dynatrace POC work.

The main remaining gaps are complementary execution workflows, not duplicate analysis skills:

- skill-pack setup / preflight
- observability onboarding
- native synthetic lifecycle
- SLO / release validation
- Business Flow POC
- workflow-as-code
- governance / database / extensions if required by scope

See [dynatrace-coverage-gap-analysis.md](skills/dt-se-poc-orchestrator/references/dynatrace-coverage-gap-analysis.md) for the current boundary.

## Skills

### POC / tenant / control-plane

| Skill | Description |
|---|---|
| [dt-tenant-setup](skills/dt-tenant-setup/SKILL.md) | Onboards a tenant end-to-end: creates `dtctl` context and optionally registers MCP. |
| [dtctl-tenant-admin](skills/dtctl-tenant-admin/SKILL.md) | Deep tenant-control playbook for inventory, export/import, drift checks, bulk config changes, and rollback-safe admin work. |
| [dtctl-dynatrace-operations](skills/dtctl-dynatrace-operations/SKILL.md) | Quick `dtctl` playbook for tenant context management, DQL execution, settings apply workflows, and troubleshooting. |
| [dt-settings-as-code-factory](skills/dt-settings-as-code-factory/SKILL.md) | Turns settings changes into versioned YAML with apply/verification/rollback. |
| [dt-alert-lifecycle](skills/dt-alert-lifecycle/SKILL.md) | Runs alerting as a lifecycle: detector choice, notification routing, and signal-quality validation. |
| [dt-openpipeline-lifecycle](skills/dt-openpipeline-lifecycle/SKILL.md) | Designs and validates OpenPipeline parsing and enrichment end-to-end. |
| [dt-bizevents-http-capture](skills/dt-bizevents-http-capture/SKILL.md) | Captures business events from HTTP APIs and verifies field extraction and correlation. |
| [dt-custom-log-ingest](skills/dt-custom-log-ingest/SKILL.md) | Handles custom-path log ingest and OTel fallback scenarios. |
| [dt-otel-poc-readiness](skills/dt-otel-poc-readiness/SKILL.md) | Adapts POCs to OpenTelemetry-first environments. |
| [dt-poc-data-readiness](skills/dt-poc-data-readiness/SKILL.md) | Checks whether telemetry is ready for the requested POC success criteria. |
| [dt-se-poc-orchestrator](skills/dt-se-poc-orchestrator/SKILL.md) | Orchestrates repeatable SE POCs end-to-end with token-efficient execution patterns. |
| [enable-session-replay](skills/enable-session-replay/SKILL.md) | Diagnoses and enables Session Replay / RUM on Grail for the new Gen3 apps (replays visible in classic but not the new Sessions app); ships an idempotent diagnose/enable/verify harness (PowerShell + bash). |

### Other local skills

| Skill | Description |
|---|---|
| [dt-app-dev-ai-setup](skills/dt-app-dev-ai-setup/SKILL.md) | Sets up AI-assisted Dynatrace app development. |
| [dynatrace-deck](skills/dynatrace-deck/SKILL.md) | Packages POC results into a customer-ready deck. |

### Skill categories (`metadata.category` / `metadata.code-specific`)

Every `SKILL.md` in this repo carries a `metadata.category` and `metadata.code-specific`
field in its frontmatter (per the [agentskills.io spec's optional `metadata` field](https://agentskills.io/specification)),
so any host surface can filter or list skills without opening a coding context:

| `code-specific` | Meaning | Skills |
|---|---|---|
| `true` | Executes against a tenant/repo (`dtctl`, settings YAML, OpenPipeline, etc.) — expects a coding/CLI-capable surface. | `dt-tenant-setup`, `dtctl-tenant-admin`, `dtctl-dynatrace-operations`, `dt-settings-as-code-factory`, `dt-alert-lifecycle`, `dt-openpipeline-lifecycle`, `dt-bizevents-http-capture`, `dt-custom-log-ingest`, `dt-otel-poc-readiness`, `dt-app-dev-ai-setup`, `enable-session-replay` |
| `false` | Advisory, planning, or content-authoring — no tenant mutation, just reasoning/output (a deck, a plan, a readiness assessment). Should be installed as the Claude plugin (above) so it's available in Claude's **Cowork** tab and chat, not only Claude Code/IDE surfaces; on other platforms, list it on their equivalent non-coding chat/collaboration surface. | `dynatrace-deck`, `dt-poc-data-readiness`, `dt-se-poc-orchestrator` |

If your platform's skill picker only shows skills to coding contexts by default, filter on
`metadata.code-specific == "false"` to also surface `dynatrace-deck` and the other
advisory skills in non-coding chat/collaboration surfaces. On Claude specifically, install the
[Claude plugin](#claude-plugin-claude-chat-cowork-and-claude-code) so the whole pack — including
`dynatrace-deck` — is available in **Cowork** and chat, not just Claude Code.

## Harness

Run the local skill harness:

```powershell
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-all.ps1
```

It checks:

- static skill quality
- routing accuracy
- outcome capability markers
- POC depth coverage

For the current completeness boundary, see the analysis linked above.

## Security posture

Skill marketplaces (e.g. [skills.sh](https://skills.sh)) run automated scanners against every
skill before install, since no one should install a skill blind. This repo is written to score
clean on those checks:

- No skill pipes a remote script into a shell (`curl ... | sh`, `irm ... | iex`). `dt-tenant-setup`
  points to versioned, checksum-verifiable installer releases instead.
- No skill maps a credential-bearing HTTP header (`Authorization`, `Cookie`, `X-Api-Key`) into a
  captured bizevent field — `dt-bizevents-http-capture` only demonstrates non-sensitive
  correlation headers and explicitly warns against capturing auth headers.
- `dt-tenant-setup` treats API tokens as ephemeral: never echoed back in chat, never written
  anywhere except the single `.mcp.json` entry or `dtctl`'s own credential store, and never
  logged.
- `--token <TOKEN>`-style CLI arguments (`dtctl config set-credentials`) carry a warning in
  `dt-tenant-setup` and `dtctl-dynatrace-operations` to prefer an interactive prompt or
  environment variable over a literal command-line value, since CLI args land in shell history
  and the process list.
- Placeholder secrets in examples use `TOKEN`/`YOUR_TOKEN`/`******` style syntax, never a
  realistic-looking key that could be mistaken for a real credential or trigger a false-positive
  secret scan.

If you add a new skill, keep to these constraints and avoid introducing install-time remote
code execution or secret-handling shortcuts — they are the patterns skill-marketplace risk
scanners flag hardest.

## Contributing

These skills came out of real onboarding and troubleshooting sessions. Please keep skill content generic and avoid tenant IDs, customer names, or real API tokens.

## License

MIT
