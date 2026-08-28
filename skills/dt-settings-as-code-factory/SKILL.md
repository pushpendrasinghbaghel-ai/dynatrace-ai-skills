---
name: dt-settings-as-code-factory
description: "Create and maintain Dynatrace settings as code for repeatable POCs and rollouts. Use when: generating settings YAML, updating existing settings objects, tracking object IDs, promoting settings across tenants, validating settings deployment with dtctl, or preparing rollback-safe configuration changes."
argument-hint: "Setting goal, target schema or feature, and scope, e.g. 'workflow notification settings for environment scope' or 'log ingest rule for host group X'"
---

# Dynatrace Settings-as-Code Factory

Turn configuration changes into versioned, reviewable artifacts instead of one-off UI clicks.

## Authoritative references

- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — supported API concepts, auth, and service boundaries.
- [Dynatrace data and storage guide](https://developer.dynatrace.com/develop/guides/data/) — where settings-backed persistence and platform-managed configuration fit.
- [dtctl repository](https://github.com/dynatrace-oss/dtctl) — CLI apply/update behavior used operationally in this skill.

## Grounding notes

The supported platform concepts are doc-grounded. The file layout, inventory tracking, and rollback discipline are repeatable delivery conventions added for SE POCs.

## When to Use

- A POC needs repeatable settings changes across prospects or customer tenants.
- You need `dtctl apply -f` workflows instead of manual configuration drift.
- You must update an existing settings object without losing its `objectId`.
- You want a validation and rollback trail for every change.

## Inputs needed

- Business goal and success criteria.
- Target tenant/context.
- Known schema or feature area, if the user has it.
- Intended scope (`environment`, host group, management zone, app scope, and so on).
- Whether this is a new object or an update to an existing one.

If the schema is unknown, discover it first from docs, existing tenant objects, or a known-good export. Do not guess a settings payload shape from memory if the schema is unclear.

## Recommended artifact layout

Store settings under the POC workspace:

```text
02-settings/
  <feature-name>.yaml
  inventory.md
  rollback.md
```

`inventory.md` should track:

- schema
- object purpose
- scope
- objectId
- last verification time

## Phase 1 - Discover the current state

1. Confirm the right tenant/context is active.
2. Identify whether a matching object already exists.
3. Export, capture, or copy the current payload before editing.
4. Decide whether the action is:
   - create new object
   - update existing object in place
   - clone to another tenant with scoped changes

For updates, preserve the original `objectId`. That is what makes `dtctl apply -f` update in place instead of creating accidental duplicates.

## Phase 2 - Author the YAML

Baseline structure:

```yaml
schemaId: <schema-id>
scope: environment
objectId: "<existing-object-id>"   # omit for first create
value:
  enabled: true
  # schema-specific payload here
```

Authoring rules:

- Keep one logical object per file unless the repo already groups them differently.
- Use clear filenames tied to the feature, not random exports.
- Add comments only where the setting meaning is not obvious.
- If a tenant-specific value changes per customer, mark it clearly in the file or alongside it in `inventory.md`.

## Phase 3 - Deploy safely

Preferred pattern:

```bash
dtctl apply -f 02-settings\feature-name.yaml
```

After deploy:

1. Capture returned identifiers or confirmation output.
2. If this was a create, write the new `objectId` back into the file for future updates.
3. Record the deployed tenant and timestamp in `inventory.md`.

Avoid broad rewrites of many unrelated settings objects unless the user explicitly asked for a bulk rollout.

## Phase 4 - Verify the change

Verification should be feature-specific, but the workflow is always:

1. Re-read the settings object from the tenant.
2. Confirm the value matches the file.
3. Run one observable smoke test tied to the success criteria.

Examples:

- A log-ingest rule: confirm the rule exists and matching logs arrive.
- A workflow setting: confirm the workflow configuration is present and a test event routes correctly.
- A data-processing change: confirm the derived field appears in query results.

## Phase 5 - Rollback plan

Every settings change should have a nearby rollback instruction:

```text
Rollback options:
1. Re-apply the previously exported YAML.
2. Disable the object and re-verify.
3. Delete only if the user explicitly wants full removal and the object is known to be disposable.
```

Do not rely on memory for rollback. Keep either the old export or a clearly documented previous state.

## Checklist

- [ ] Target context is correct
- [ ] Schema and scope are confirmed
- [ ] YAML is checked into the expected folder
- [ ] `objectId` handling is correct for create vs update
- [ ] `dtctl apply -f` completed successfully
- [ ] Post-deploy verification is recorded
- [ ] Rollback instructions exist
