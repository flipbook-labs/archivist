# Changelog

All notable changes to this project will be documented in this file.


## v0.3.0

Changes 1 · Internal 2

### Changes

1. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-packages-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-packages-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-packages-light.png" alt="Packages" height="18" align="texttop"></picture> Ship the manifest as `pkg.luau` and depend on Lute `1.0.1-nightly.20261115`, so Loom consumers need a Lute nightly newer than `1.0.1-nightly.20261031` to install. ([#15](https://github.com/flipbook-labs/archivist/pull/15))

<details>
<summary>Internal (2)</summary>

1. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-release-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-release-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-release-light.png" alt="Release" height="18" align="texttop"></picture> Release automation reads the public Flipbook Backend App Client ID from an organization variable. ([#11](https://github.com/flipbook-labs/archivist/pull/11))
2. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-release-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-release-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/archivist/main/.changes/assets/kind-release-light.png" alt="Release" height="18" align="texttop"></picture> Release notes mark each entry with a chip naming the part of Archivist it changed, and the Dependencies and Internal sections start collapsed. ([#14](https://github.com/flipbook-labs/archivist/pull/14))

</details>


## v0.2.0

### Changes

- Render pretty logs as `[level] message` by default and add opt-in name and timestamp middleware.


## v0.1.0

### Changes

- Upgrade the Changewrite release action to `v0.7.0` and adopt its `publish-lock` check.

- Set up CI (lint, tests, build with dist-hygiene checks, dual-flavor Luau analysis) and changewrite-driven releases (version mirroring into `wally.toml`/`loom.config.luau`, release PRs that tag, attach the model, and publish to Wally).

### Dependencies

- Add AgentSkills `v0.4.0` as a dev dependency so agents can bootstrap the shared skills library.

### Features

- Add the core logging pipeline: structured records, leveled child loggers, and dev/prod batched dispatch to a console sink, on both Lute and Roblox.

- Add the `createCallbackSink`, `createFileSink` (Lute), and `createTransportSink` sinks, plus a `createJsonFormatter`.
