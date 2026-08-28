# Dynatrace AI Skills

Reusable [Agent Skills](https://agentskills.io) for working with Dynatrace across Claude Code, GitHub Copilot, Cursor, Gemini CLI, and other compatible agents — including `dtctl`, the Dynatrace MCP server, and common observability workflows.

## Installation

### 1. Skills Package (Recommended)

```bash
npx skills add pushpendrasinghbaghel-ai/dynatrace-ai-skills
```

Installs every skill in this repo. To install one specific skill instead:

```bash
npx skills add pushpendrasinghbaghel-ai/dynatrace-ai-skills --skill dt-tenant-setup
```

Target Claude Code explicitly with `-a claude-code` if you have multiple agents configured:

```bash
npx skills add pushpendrasinghbaghel-ai/dynatrace-ai-skills --skill dt-tenant-setup -a claude-code
```

### 2. Manual Installation

Copy a skill folder directly into your agent's skills path (`.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, etc. — project-local or the user-global equivalent):

```bash
git clone https://github.com/pushpendrasinghbaghel-ai/dynatrace-ai-skills.git
cp -r dynatrace-ai-skills/skills/<skill-name> ~/.claude/skills/
```

Claude Code picks up skills automatically — no restart needed for the skill itself (MCP server changes do require a session reload).

## Public publishing model

Recommended long-term split:

### Repo A - skills repo

Keep the current public skills repo focused on portable reusable building blocks:

- [skills/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills)
- [harness/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness)
- root documentation such as this [README.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/README.md)

This repo is the best public/community surface because users can install one skill or many without adopting your full SE operating model.

Keep this repo as the source of truth for `skills/` and the harness.

### What should not go public

Do not publish:

- real tenant IDs unless they are already intentionally public demo tenants
- API tokens, client secrets, or auth headers
- customer-specific payloads, dashboards, notebooks, or decks
- internal-only branding assets
- copied internal customer content

For a fuller recommendation, see [publication-model.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-se-poc-orchestrator/references/publication-model.md).

## Skills

| Skill | What it does |
|---|---|
| [`dt-tenant-setup`](skills/dt-tenant-setup/SKILL.md) | Onboards a new Dynatrace tenant end-to-end: creates a working `dtctl` context and optionally registers the tenant as an MCP server in `.mcp.json`. |
| [`dtctl-tenant-admin`](skills/dtctl-tenant-admin/SKILL.md) | Deep tenant-control dtctl playbook for inventory, export/import, drift checks, bulk config changes, and rollback-safe tenant admin work. |
| [`dtctl-dynatrace-operations`](skills/dtctl-dynatrace-operations/SKILL.md) | Local `dtctl` playbook for tenant context management, DQL execution, settings apply workflows, verification, and common troubleshooting. |
| [`dt-bizevents-http-capture`](skills/dt-bizevents-http-capture/SKILL.md) | End-to-end workflow for capturing business events from HTTP APIs monitored by OneAgent — discovery, capture rule YAML, field extraction pitfalls, `dtctl` deployment, OpenPipeline path enrichment, and verification DQL. |
| [`dt-settings-as-code-factory`](skills/dt-settings-as-code-factory/SKILL.md) | Turns Dynatrace settings changes into versioned YAML with `dtctl apply -f`, object ID tracking, verification, and rollback guidance for repeatable POCs. |
| [`dt-alert-lifecycle`](skills/dt-alert-lifecycle/SKILL.md) | Runs alerting as a lifecycle: choose detector model, manage alert settings as code, route notifications/workflows, verify signal quality, and tune or roll back safely. |
| [`dt-openpipeline-lifecycle`](skills/dt-openpipeline-lifecycle/SKILL.md) | Designs and validates OpenPipeline parsing/enrichment end-to-end: transformation contract, ingest-time vs query-time choice, processor rollout, and field-fill troubleshooting. |
| [`dt-poc-data-readiness`](skills/dt-poc-data-readiness/SKILL.md) | Assesses whether a tenant is actually ready for a POC by mapping success criteria to logs, traces, metrics, and business-event evidence. |
| [`dt-custom-log-ingest`](skills/dt-custom-log-ingest/SKILL.md) | Handles customer log-ingest variants where logs live on custom paths or must be collected via OneAgent configuration or OpenTelemetry Collector fallback. |
| [`dt-otel-poc-readiness`](skills/dt-otel-poc-readiness/SKILL.md) | Adapts POCs to OpenTelemetry-first environments, verifying traces/logs/metrics correlation without assuming OneAgent coverage everywhere. |
| [`dt-app-dev-ai-setup`](skills/dt-app-dev-ai-setup/SKILL.md) | Sets up AI-assisted Dynatrace app development: configures the `dt-app-mcp` MCP server and `CLAUDE.md`/`AGENTS.md` instructions file, links official Strato Design System/AppEngine docs, and captures build/runtime, scope, and Strato-compliance lessons distilled from real shipped Dynatrace apps. |
| [`dt-se-poc-orchestrator`](skills/dt-se-poc-orchestrator/SKILL.md) | Orchestrates repeatable SE POCs end-to-end (tenant setup, settings-as-code, dashboards, bizevents, OpenPipeline, validation, and handover) with token-efficient multi-agent execution patterns across Claude/Copilot/Gemini. |

## Related Projects

| Project | Description |
|---|---|
| [dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl) | The `dtctl` CLI these skills drive for tenant config, queries, and settings deployment. |
| [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) | Dynatrace's official AI tooling and integrations. |
| [Dynatrace MCP server docs](https://docs.dynatrace.com/docs/dynatrace-intelligence/dynatrace-mcp) | Official documentation for the Dynatrace MCP server referenced by the `dt-tenant-setup` skill. |

## Contributing

These skills came out of real onboarding/troubleshooting sessions — the goal is to capture gotchas so they don't have to be rediscovered each time. PRs adding new Dynatrace skills or fixing inaccuracies are welcome. Please keep skill content generic (no tenant IDs, customer names, or real API tokens).

## Testing the skills (harness)

This repo includes a local harness in [harness/README.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/README.md) to test:

- static skill quality (frontmatter + structure),
- prompt-to-skill routing accuracy,
- outcome capability markers per skill.
- end-to-end POC depth coverage against realistic customer scenarios.
- grounding discipline through explicit `Authoritative references` and `Grounding notes` sections in each skill.

Run all suites:

```powershell
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-all.ps1
```

To specifically answer "how deep can this agent go for a customer POC?", run:

```powershell
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-poc-depth-tests.ps1
```

## License

MIT
