---
bump: patch
category: Internal
kind: tooling
---

`lute run install` also writes an `agent-skills` alias into `.config.luau`, so agents find the shared skills library without parsing the lockfile, and Lute's dependency key in `pkg.luau` is now `Batteries`.
