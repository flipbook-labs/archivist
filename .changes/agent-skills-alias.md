---
bump: patch
category: Internal
kind: packages
---

`lute run install` vendors the Lute package dependencies into a gitignored `.lpm/` folder, and code requires them through a single `@lpm` alias, such as `@lpm/batteries@v1.0.1-nightly.20261115/pp`. Projects using Archivist need Lute `1.0.1-nightly.20261117` or newer, `lute pkg install --vendor`, and `lpm = "./.lpm"` in their `.config.luau`. The published package ships only its source, README and license, plus `src/.config.luau` so a vendored copy keeps its own `@root` alias.
