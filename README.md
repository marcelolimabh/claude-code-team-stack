# claude-code-team-stack

**A small, opinionated starter kit to standardize Claude Code across a dev team:**
vetted plugins, security guardrails and setup scripts for Java/Spring Boot and
Node/TypeScript/React/Next.js projects.

🇧🇷 [Leia em português](README.pt-BR.md)

> Unofficial community project, not affiliated with or endorsed by Anthropic.
> Plugin names and behavior change often: this kit was put together in November 2026.
> Check [CHANGELOG.md](CHANGELOG.md) for what changed since.

## Why

When a team adopts Claude Code, everyone tends to configure it their own way: one dev
installs ten plugins, another none, a third grabs a skill from a random repo. This kit
gives the team one setup, committed to each repository and changed only through PRs.

Principles:

- **Less is more.** Every active plugin takes context in every conversation. Only what we can justify.
- **Official first.** Almost everything comes from Anthropic's official marketplace (`claude-plugins-official`).
- **Local first.** Tools that run on the developer's machine come before services that send code elsewhere.
- **Everything versioned.** The config lives in `.claude/settings.json`; changing the stack is a PR.

## What's inside

```
templates/
  java-spring/.claude/settings.json       # Java / Spring Boot projects
  node-react-next/.claude/settings.json   # Node / TypeScript / React / Next.js projects
scripts/
  setup-claude-stack.sh                   # macOS, Linux, WSL2
  setup-claude-stack-windows.ps1          # Windows (WSL2 or native without LSP)
```

### Plugins (all free)

| Plugin | Why | Java | Node/Front |
|---|---|:-:|:-:|
| `jdtls-lsp` | Claude sees Java compile errors right after each edit | ✅ | |
| `typescript-lsp` | Same for TS/JS | | ✅ |
| `superpowers` | Disciplined workflow: brainstorm → plan → TDD → review → verify | ✅ | ✅ |
| `code-review`, `pr-review-toolkit` | Code and PR reviews with parallel subagents | ✅ | ✅ |
| `security-guidance` | Claude reviews its own changes for vulnerabilities while it writes | ✅ | ✅ |
| `commit-commands` | Commit / push / PR in one command | ✅ | ✅ |
| `github` | Issue and PR context | ✅ | ✅ |
| `context7` | Up-to-date library docs (free plan, account required) | ✅ | ✅ |
| `frontend-design`, `playwright` | Better UI and browser testing | | ✅ |

### Guardrails (`permissions` in settings.json)

- **deny:** reading `.env`, keys, keystores (`*.pem`, `*.key`, `*.jks`, `*.p12`), `secrets/`,
  production configs (`application-prod*`, `.env.production`); `git push --force`; `rm -rf`.
- **ask:** `git push`, `git reset`, `gh pr merge`, installing npm packages.
- **allow:** build, test and lint commands (`mvnw`, `gradlew`, `npm test`, `eslint`...) and read-only git.

## Adopting it in a repository (tech lead, once)

1. Copy the matching template to the repo root as `.claude/settings.json`.
   Monorepo with both stacks? Merge the `enabledPlugins` and `permissions` of both templates.
2. Adjust `permissions` to your project's commands (yarn, pnpm, make...).
3. Commit `.claude/settings.json`. Never commit `.claude/settings.local.json` (personal overrides).

## Setting up each machine (every developer, once)

### macOS / Linux
```bash
cd ~/dev/<repo>
bash /path/to/claude-code-team-stack/scripts/setup-claude-stack.sh
```
Prerequisites: Claude Code, git, Python 3.9+, Node LTS (TS projects). For Java projects, macOS uses
Homebrew to install jdtls and falls back to a direct download (needs JDK 21+) when Homebrew is missing or
fails, as on Intel Macs; Linux needs JDK 21+ (jdtls requires it to run, your project can target 17).

### Windows
**Recommended: run Claude Code inside WSL2.** On native Windows the LSP plugins currently fail to
start the language server (see [Known issues](#known-issues)); everything else works.
```powershell
.\scripts\setup-claude-stack-windows.ps1          # checks/installs WSL2 and prints next steps
.\scripts\setup-claude-stack-windows.ps1 -Native  # native Windows, without LSP plugins
```
In WSL, clone repos under `~/dev` (not `/mnt/c`) and run `setup-claude-stack.sh`.

### Check
Open Claude Code in the repo, trust the folder and run `/plugin`. The project's plugins should be enabled.

## Team rules we recommend

- **New plugins only through a PR** to your copy of this kit, after someone reads the plugin's
  `SKILL.md`, hooks and code. Third-party skills run with your privileges.
- **Don't remove the `deny` rules for secrets.**
- **Sensitive code / regulated industries:** don't connect external services (code review SaaS,
  cloud SCA, private-repo docs indexing) without your security/compliance team's approval.
- Want to turn a plugin off just for you? Use `.claude/settings.local.json`:
  ```json
  { "enabledPlugins": { "superpowers@claude-plugins-official": false } }
  ```
- Keep Claude Code updated (`claude update`).

## Paid add-ons (optional)

You can go far for free. If you want to invest, a sensible order is:

1. **SonarQube** plugin (official marketplace): quality gates, duplication, complexity, SAST and
   secrets on Claude-generated code too.
2. **Snyk** (dependency vulnerabilities) or **Semgrep** paid tiers.
3. **CodeRabbit** or **Claude Code Review** (Team/Enterprise) for PR review. Pick one, not both.

Items 2 and 3 send code to external services: get approval first if your code is sensitive.

## Known issues

- **LSP plugins on native Windows** fail to spawn the language server
  ([#37897](https://claudeissues.com/issue/37897-lsp-plugins-fail-on-windows-spawn-enoent-for-npm-global-shim-scripts),
  [#78188](https://claudeissues.com/issue/78188-bug-jdtls-lsp-plugin-lsp-tool-fails-with-command-jdtls-not-found-or-is-in-an-uns)).
  Workaround: WSL2.
- **Project `enabledPlugins` may not prompt teammates to install** plugins from the official marketplace
  ([#41669](https://claudeissues.com/issue/41669-project-level-enabledplugins-should-auto-install-or-prompt-to-install-plugins-fr)).
  Workaround: the setup scripts install whatever `settings.json` lists.
- **`claude plugin install --scope project` may rewrite `.claude/settings.json`** with the keys in a
  different order. The content is the same; discard the change with `git checkout .claude/settings.json`.

## References

- [Claude Code docs: plugins for organizations](https://code.claude.com/docs/en/plugins/org)
- [Claude Code docs: code intelligence (LSP) plugins](https://code.claude.com/docs/en/plugins/code-intelligence)
- [Claude Code docs: security guidance](https://code.claude.com/docs/en/security-guidance)
- [Cloud Security Alliance: Agent Context Poisoning (SKILL.md)](https://labs.cloudsecurityalliance.org/research/briefing-csa-research-note-skill-md-agent-context-poisoning/)

## Contributing

Issues and PRs are welcome, especially test reports from Windows/WSL and Linux and templates for
other stacks. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
