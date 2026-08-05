# Dynatrace AI Skills

Reusable [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) for working with Dynatrace — `dtctl`, the Dynatrace MCP server, and common observability workflows.

## Installation

Copy a skill folder into your `.claude/skills/` directory (project-local or `~/.claude/skills/` for global use):

```bash
git clone https://github.com/<your-username>/dynatrace-ai-skills.git
cp -r dynatrace-ai-skills/skills/<skill-name> ~/.claude/skills/
```

Claude Code picks up skills automatically — no restart needed for the skill itself (MCP server changes do require a session reload).

## Skills

| Skill | What it does |
|---|---|
| [`dt-tenant-setup`](skills/dt-tenant-setup/SKILL.md) | Onboards a new Dynatrace tenant end-to-end: creates a working `dtctl` context and optionally registers the tenant as an MCP server in `.mcp.json`. |
| [`dt-app-dashboards`](skills/dt-app-dashboards/SKILL.md) | Create, modify, query, and analyze Dynatrace dashboards — tiles, layouts, DQL queries, variables, and visualizations, deployed via `dtctl`. |
| [`dt-bizevents-http-capture`](skills/dt-bizevents-http-capture/SKILL.md) | End-to-end workflow for capturing business events from HTTP APIs monitored by OneAgent — discovery, capture rule YAML, field extraction pitfalls, `dtctl` deployment, OpenPipeline path enrichment, and verification DQL. |

## Related Projects

| Project | Description |
|---|---|
| [dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl) | The `dtctl` CLI these skills drive for tenant config, queries, and settings deployment. |
| [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) | Dynatrace's official AI tooling and integrations. |
| [Dynatrace MCP server docs](https://docs.dynatrace.com/docs/dynatrace-intelligence/dynatrace-mcp) | Official documentation for the Dynatrace MCP server referenced by the `dt-tenant-setup` skill. |

## Contributing

These skills came out of real onboarding/troubleshooting sessions — the goal is to capture gotchas so they don't have to be rediscovered each time. PRs adding new Dynatrace skills or fixing inaccuracies are welcome. Please keep skill content generic (no tenant IDs, customer names, or real API tokens).

## License

MIT
