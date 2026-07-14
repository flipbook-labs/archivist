# Changelog

All notable changes to this project will be documented in this file.


## v0.1.0

### Changes

- Upgrade the Changewrite release action to `v0.7.0` and adopt its `publish-lock` check.

- Set up CI (lint, tests, build with dist-hygiene checks, dual-flavor Luau analysis) and changewrite-driven releases (version mirroring into `wally.toml`/`loom.config.luau`, release PRs that tag, attach the model, and publish to Wally).

### Dependencies

- Add AgentSkills `v0.4.0` as a dev dependency so agents can bootstrap the shared skills library.

### Features

- Add the core logging pipeline: structured records, leveled child loggers, and dev/prod batched dispatch to a console sink, on both Lute and Roblox.

- Add the `createCallbackSink`, `createFileSink` (Lute), and `createTransportSink` sinks, plus a `createJsonFormatter`.
