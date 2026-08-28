# Publication model for public Dynatrace SE assets

Use this model when deciding how to publish reusable Dynatrace skills and the packaged SE POC agent.

## Recommendation

### Publish skills in one public repo

This repo should be the **skills repo**.

Keep here:

- reusable `SKILL.md` packages
- skill-specific references and assets
- shared harness logic
- generic prompt templates that help evaluate or invoke skills

Why:

- easier community adoption
- easier selective installation
- clearer upstream contribution story
- easier to complement `Dynatrace/dynatrace-for-ai` without bundling your full workflow opinion

### Publish the agent in a second public repo

Create a separate **agent repo** for the SE POC persona.

Keep there:

- `AGENTS.md`
- `CLAUDE.md`
- `copilot-instructions.md`
- agent prompt templates
- sample POC intake payloads
- sample `pocs/<account>-<usecase>/` folder skeletons
- release notes around end-to-end agent behavior

Why:

- the agent is an opinionated composition of many skills
- it will likely change faster than stable skills
- different users may want the skills without the full POC agent
- you can later publish multiple agents backed by the same skill repo

## Short-term exception

If you want faster initial momentum, it is acceptable to keep skills and agent in one repo temporarily while the agent wrapper stabilizes.

Once usage grows, split them.

## Suggested future repo names

- `dynatrace-ai-skills`
- `dynatrace-se-poc-agent`

## Dependency model

The agent repo should:

1. reference the skills repo in its README,
2. instruct users to install the skills repo first,
3. add only persona/orchestration files locally,
4. avoid copying the skills unless absolutely necessary for offline packaging.

## Install behavior

By default, installing the **agent repo** should not be assumed to automatically install the external **skills repo**. Treat them as two install steps unless you deliberately build a bundling or bootstrap flow.

Recommended default flow:

1. install skills from the skills repo,
2. install the agent wrapper repo,
3. start a new session so the wrapper and skills are available together.

If you want a one-command experience, add a bootstrap script in the agent repo that installs the skills repo first and then enables the wrapper files.

## Reference, do not duplicate

Preferred default:

- the **skills repo** owns reusable skill content,
- the **agent repo** owns wrapper behavior and orchestration.

Avoid maintaining the same `skills/` tree in both repos.

Why:

- prevents drift between copies
- avoids version confusion
- makes contribution ownership obvious
- lets the agent evolve independently from the skills

## Exception policy

Duplicate or vendor skills only when one of these is true:

1. the target platform cannot reference external skills cleanly,
2. you need a frozen bundled release for reproducibility,
3. you need an offline/internal package for a controlled environment.

If you vendor skills:

- mark the folder clearly as vendored,
- cite the original repo,
- pin a version or commit,
- do not edit the vendored copy casually; update from source deliberately.

## Public-readiness checklist

- remove any customer names that should not be public
- remove tenant IDs and auth material
- remove private screenshots and decks
- confirm local references do not embed sensitive paths or data
- keep examples generic or synthetic
