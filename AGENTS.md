# Archivist agent guide

Archivist is a structured logging library for Luau that runs on both Lute and
Roblox. This file is the entry point for any agent working in the repo. It routes
you to the shared skills library and the repo's own setup.

## First: install dependencies

Before doing anything else in a fresh checkout, run:

```sh
lute run install
```

That one script installs the Loom (Lute) dependencies, installs the Wally (Roblox)
dependencies, and regenerates the Lute type definitions luau-lsp reads. Without it
the shared skills below are not on disk and analysis will not resolve.

## Shared skills: flipbook-labs/agent-skills

Cross-cutting doctrine (test discipline, code comments, changelog entries, writing
style) does not live in this repo. It lives in the org's shared, versioned
[AgentSkills](https://github.com/flipbook-labs/agent-skills) library, pinned in
[`loom.config.luau`](loom.config.luau) and installed by `lute run install` into:

```
~/.loom/store/AgentSkills@v0.2.0/
```

The version in that path tracks the `rev` pinned for `AgentSkills` in
`loom.config.luau`. When you bump the pin, the folder name changes to match.

Routing is manual and on demand, the same as the library's own convention:

1. Read the library's routing index at
   `~/.loom/store/AgentSkills@v0.2.0/AGENTS.md`. Its **Project Skills** section
   lists every skill with a trigger-rich one-liner.
2. When a task matches a trigger, read that skill's
   `~/.loom/store/AgentSkills@v0.2.0/src/<scope>/<name>/SKILL.md` before you start
   the work it covers.

Skills are living documents. If your work in this repo contradicts a skill (a
renamed symbol, a changed value, a fixed bug it still calls known), fix it in the
agent-skills repo and add a `.changes/` entry there in the same PR. The fix reaches
this repo on its next `rev` bump.

## Repo specifics

- Toolchain is managed with [Rokit](https://github.com/rojo-rbx/rokit); run
  `rokit install` once to get `lute`, `rojo`, `wally`, and the linters on PATH.
- `lute run --list` shows the available scripts. Common ones: `install` (set up
  dependencies), `example` (run the demo under Lute), `build` (produce the Roblox
  `Archivist.rbxm`).
- The platform seam lives in [`src/platform/`](src/platform); read
  [`.lute/build.luau`](.lute/build.luau) for how the Lute and Roblox targets diverge
  before you touch it.
