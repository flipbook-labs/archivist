---
bump: patch
category: Internal
kind: packages
---

`lute run install` writes an alias into `.config.luau` for every Loom dependency, named after its kebab-case key in `pkg.luau`, so agents find the shared skills library through `agent-skills`. The published package now ships only its source, README and license, plus `src/.config.luau` so a vendored copy keeps its own `@root` alias.
