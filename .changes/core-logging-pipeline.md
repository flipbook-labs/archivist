---
bump: minor
category: Features
---

Core logging pipeline: structured `LogRecord`s, dot-style leveled loggers (`trace`/`debug`/`info`/`warn`/`err`) with `LOG_LEVEL` / `_G.LOG_LEVEL` resolution, child loggers with attached fields, dev/prod batching dispatch, a console sink, and a colored pretty formatter — running on both Lute and Roblox behind a build-time platform seam.
