## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues for `KeithMatic/nvim`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default triage roles, each label string equal to its role name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Tests

Every feature has a `tests/<area>_spec.lua`; check a change with `tests/run.sh tests/<area>_spec.lua`. It boots the config in the `.tests/` sandbox with its own plugins, so the real install stays as it is. See README.md › Tests.
