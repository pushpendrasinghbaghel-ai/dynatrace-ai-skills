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

## SE POC agent wrapper

This repo now includes a reusable cross-platform **Dynatrace SE POC agent** wrapper:

- [AGENTS.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/AGENTS.md)
- [CLAUDE.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/CLAUDE.md)
- [copilot-instructions.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/copilot-instructions.md)
- [dynatrace-se-poc-agent.prompt.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/prompts/dynatrace-se-poc-agent.prompt.md)
- [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json)

Use these to package the skills in this repo into a real named agent/persona for Claude, GitHub Copilot, and Gemini-style prompt flows.

For deeper tenant-control work, use [dtctl-tenant-admin](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-tenant-admin/SKILL.md); for quick CLI work, use [dtctl-dynatrace-operations](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-dynatrace-operations/SKILL.md).

Before each POC, the wrapper should read [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json) to confirm the relevant local and upstream skills are available and not stale for the requested work.

As the repo evolves, update the manifest and harness whenever a new skill is added or an existing skill materially changes. The maintenance rule is captured in [skill-maintenance.instructions.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/.github/instructions/skill-maintenance.instructions.md).

### Install the agent wrapper

For a fresh workspace, install the skills repo first, then layer the agent wrapper files on top.

1. Clone or pull this repo so the skills and wrapper files are available locally.
2. Install the skills pack:
   ```bash
   npx skills add pushpendrasinghbaghel-ai/dynatrace-ai-skills
   ```
3. For **Claude Code**, make sure [AGENTS.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/AGENTS.md) and [CLAUDE.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/CLAUDE.md) are present in the workspace root.
4. For **GitHub Copilot**, make sure [copilot-instructions.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/copilot-instructions.md) is present in the workspace root.
5. Open a new Claude or Copilot session in that workspace so the wrapper instructions are picked up.

## Public publishing model

Recommended long-term split:

### Repo A - skills repo

Keep the current public skills repo focused on portable reusable building blocks:

- [skills/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills)
- [harness/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness)
- generic [prompts/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/prompts)
- root documentation such as this [README.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/README.md)

This repo is the best public/community surface because users can install one skill or many without adopting your full SE operating model.

### Repo B - agent repo

Create a separate public agent repo for the packaged SE POC persona:

- [AGENTS.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/AGENTS.md)
- [CLAUDE.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/CLAUDE.md)
- [copilot-instructions.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/copilot-instructions.md)
- the reusable agent prompt [dynatrace-se-poc-agent.prompt.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/prompts/dynatrace-se-poc-agent.prompt.md)
- optional sample `pocs/` skeletons and onboarding examples

This repo should reference the skills repo as its dependency/base knowledge pack rather than duplicating the skills.

### Reference, do not duplicate

Recommended default:

- **skills repo** = source of truth for `skills/`
- **agent repo** = source of truth for persona/orchestration files

The agent repo should instruct users to install or copy skills from the skills repo first, then layer only the agent wrapper files on top.

Do **not** duplicate the same skills into both repos unless you intentionally need a bundled or pinned distribution model. Duplication creates drift, extra maintenance, and confusion about which repo owns the authoritative version.

### Exception: vendored/bundled release

If a platform cannot easily reference the external skills repo, a bundled copy is acceptable only if it is explicit:

- vendor the skills under a clearly named folder
- record the upstream source repo
- record the pinned version or commit
- treat the skills repo as the canonical source of truth

### Install behavior

Installing the **agent repo alone** should be assumed to install only the wrapper/persona files unless you explicitly build a bundled installer.

Default model:

1. install the **skills repo**
2. install or copy the **agent wrapper repo**
3. run them in the same agent session/tool environment

So yes, the agent can use those skills in the same process/session **after both are installed**, but no, the wrapper should not be assumed to auto-fetch the skills cross-repo unless you intentionally add that behavior.

If you want one-step setup later, create a small installer script in the agent repo that:

1. installs the skills package from the skills repo,
2. copies or enables the wrapper files,
3. prints a verification checklist.

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
