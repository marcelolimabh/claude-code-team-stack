# Contributing

Thanks for helping! Contributions in English or Portuguese are welcome.
(Contribuições em português também são bem-vindas.)

## Most useful contributions

- **Test reports** from Windows (WSL2 and native), Linux distros and macOS versions.
  Use the "Setup report / bug" issue template and include OS, Claude Code version (`claude --version`)
  and the script output.
- **Templates for other stacks** (Python/FastAPI, Go, Kotlin, .NET...) following the same principles.
- **Fixes** when a plugin is renamed, removed or a known issue gets fixed upstream.

## Rules for proposing a plugin

A plugin enters a template only if the PR explains:

1. **What problem it solves** that the current stack doesn't.
2. **Where it comes from.** Official marketplace first. Third-party plugins need a link to the source,
   and the reviewer must read its `SKILL.md`, hooks and scripts before approving.
3. **Cost.** Free, free tier with limits, or paid. Paid tools go to the "Paid add-ons" section, not
   into the templates.
4. **Data flow.** Does it send code or data to an external service? If so, say so explicitly.

Prefer fewer plugins: every active plugin uses context in every conversation.

## Pull request checklist

- [ ] JSON templates are valid (`jq empty templates/*/.claude/settings.json`)
- [ ] `shellcheck scripts/*.sh` passes
- [ ] README.md **and** README.pt-BR.md updated when behavior changes
- [ ] CHANGELOG.md entry under "Unreleased"

The CI workflow runs the JSON, shell and PowerShell checks on every PR.
