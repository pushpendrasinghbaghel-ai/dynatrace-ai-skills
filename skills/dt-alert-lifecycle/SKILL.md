---
name: dt-alert-lifecycle
description: "Plan, create, validate, and evolve Dynatrace alerting for POCs using settings-as-code and workflow-aware verification. Use when: choosing alert model types, creating detector-related settings, routing notifications, validating signal quality, or making rollback-safe alert changes for customer scenarios."
argument-hint: "Alert objective and target signal, e.g. 'alert on checkout failure rate spike to Slack' or 'seasonal CPU anomaly notification for prod hosts'"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Dynatrace Alert Lifecycle

Use this skill to treat alerts as an end-to-end lifecycle, not just a one-time detector click in the UI.

## Authoritative references

- [Dynatrace Workflows guide](https://developer.dynatrace.com/develop/guides/workflows/) — workflow model and notification/action context.
- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — platform-service context for configuration and verification flows.
- Upstream reference skill: [dt-alerting](https://github.com/Dynatrace/dynatrace-for-ai/tree/main/skills/dt-alerting) — official Dynatrace agent-skill baseline for alerting concepts and workflow routing.

## Grounding notes

The workflow concepts and alerting context are grounded in official Dynatrace docs and the upstream Dynatrace skill. The exact lifecycle sequencing, rollout gates, and rollback discipline here are local SE operating guidance.

## When to Use

- A POC needs one or more alerts tied to a business or technical success criterion.
- You must choose between static threshold, adaptive baseline, or seasonal behavior.
- You need notification routing to Slack, email, webhook, or downstream automation.
- You want settings-as-code plus verification, not ad hoc UI-only alert setup.

## Phase 1 - Define the alert contract

Before creating anything, write down:

- signal to alert on
- entity or scope
- triggering condition
- who should be notified
- acceptable noise level
- how success will be verified

If the alert objective is vague, tighten it into one measurable condition first.

## Phase 2 - Choose the right alert model

- **Static threshold**: use when the expected boundary is clear and stable.
- **Adaptive baseline**: use when normal behavior varies but still has a learnable baseline.
- **Seasonal model**: use when workload has day/week cyclic patterns and static thresholds will be noisy.

If the signal quality is unknown, validate the signal first before promising a production-like alert.

## Phase 3 - Represent the configuration as code

Prefer versioned settings artifacts under:

```text
02-settings/
  alerts/
    <alert-name>.yaml
  workflows/
    <route-name>.yaml
```

Deployment pattern:

```bash
dtctl apply -f 02-settings\alerts\<alert-name>.yaml
```

If the detector or route already exists, preserve `objectId` so updates happen in place.

## Phase 4 - Route the notification

Decide whether the alert should:

- notify only,
- open or enrich an operational workflow,
- trigger a human-confirmed remediation flow.

For workflows with side effects, keep a confirmation step unless the user explicitly asks for fully automated action and understands the risk.

## Phase 5 - Verify the lifecycle

Verification should include:

1. the detector configuration exists as expected,
2. the routing target is correct,
3. the signal can actually trigger meaningfully,
4. test evidence is recorded.

Examples of verification evidence:

- settings object present
- workflow route present
- recent alert/problem data shows the expected grouping behavior
- notification test or simulated trigger reaches the destination

## Phase 6 - Rollback and tuning

Have a clear rollback path:

- re-apply previous YAML,
- disable the detector,
- remove or detach the workflow route,
- narrow scope or thresholds if noise is too high.

During POCs, tuning is normal. Hide neither noise nor gaps; document them explicitly.

## Common pitfalls

- alert created before signal quality is validated
- threshold choice mismatched to seasonal behavior
- notification path configured, but never test-triggered
- update creates duplicate object because `objectId` was dropped
- irreversible workflow side effects enabled too early

## Checklist

- [ ] alert objective mapped to success criteria
- [ ] model choice is explicit
- [ ] settings files are versioned
- [ ] `dtctl apply -f` deployment path is defined
- [ ] routing target is configured and testable
- [ ] rollback path exists
