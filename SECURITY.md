# Security policy

## Reporting a vulnerability

If you find a problem in this kit that could expose secrets or let an agent run unintended
commands (for example, a `permissions` rule that can be bypassed, or a script that downloads
something unsafely), please **do not open a public issue**. Use GitHub's
"Report a vulnerability" (private security advisory) on this repository instead.

Vulnerabilities in Claude Code itself or in a third-party plugin should be reported to their
maintainers (for Claude Code: Anthropic's disclosure process).

## Scope and limits of this kit

- The `permissions` rules in the templates **reduce** risk; they are not a sandbox. Review them
  for your own project and keep secrets out of the repository regardless.
- Plugins listed here were chosen in November 2026. A plugin's content can change after an update:
  re-review plugins when you bump versions.
- Third-party skills and plugins run with the developer's privileges. Treat them like any other
  dependency: read the source before adding one, and add them only through a reviewed PR.
