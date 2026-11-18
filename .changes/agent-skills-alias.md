---
bump: patch
category: Internal
kind: tooling
---

`lute run install` writes an alias into `.config.luau` for every Loom dependency, named after its kebab-case key in `pkg.luau`, so agents find the shared skills library through `agent-skills` instead of parsing the lockfile.
