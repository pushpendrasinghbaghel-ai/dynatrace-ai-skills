---
description: Keep the Dynatrace SE POC agent current as new skills are added or existing skills evolve.
---

When creating a new skill or making a meaningful update to an existing skill, update the agent ecosystem in the same change so the packaged agent stays current.

Required follow-up for every new or materially changed skill:

1. Update [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json) so the agent knows the skill exists and which lane it belongs to.
2. Update [README.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/README.md) if the public skill catalog or agent behavior changes.
3. Update harness cases under [harness/cases/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/cases):
   - routing coverage if the skill should be discoverable from prompts
   - outcome coverage if the skill has key capability markers
   - POC depth coverage if the skill expands end-to-end execution
4. Re-run [run-all.ps1](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/runners/run-all.ps1).

Do not add a new skill without wiring it into the manifest and harness unless the user explicitly wants a draft-only placeholder.
