# Archivist

A structured logging library for Luau that runs on both [Lute](https://github.com/luau-lang/lute) and Roblox.

> [!NOTE]
> Archivist is pre-release and under active development. The API may change before v1.

## Features

- **Dual runtime**: one library, first-class support for Lute (CLI) and Roblox
- **Log levels**: `trace`, `debug`, `info`, `warn`, `err`, filtered by a minimum level
- **`LOG_LEVEL`**: level resolution from the environment on Lute, `_G.LOG_LEVEL` on Roblox
- **Colorful output**: ANSI-colored console output on Lute; plain `print`/`warn` on Roblox
- **Structured records**: every entry is a `LogRecord` object (timestamp, level, name, args) that sinks can consume
- **Sinks**: route records anywhere — console, files (Lute), or your own callback (e.g. an in-app log viewer)
- **Dev/prod deferral** *(planned)*: sequential `print`-like output in dev, batched non-blocking writes in prod

## Installation

### Lute (Loom)

Add to your `loom.config.luau` dependencies:

```luau
Archivist = {
	rev = "v0.1.0",
	sourceKind = "github",
	source = "https://github.com/flipbook-labs/archivist",
},
```

Then run `lute pkg install`.

### Roblox (Wally)

```toml
[dependencies]
Archivist = "flipbook-labs/archivist@0.1.0"
```

## Usage

```luau
local Archivist = require("@pkg/Archivist")

local logger = Archivist.createLogger("MyModule")

logger.info("loaded", 3, "stories")
logger.warn("something looks off")
logger.err("something broke")

-- Show everything, regardless of LOG_LEVEL:
local verbose = Archivist.createLogger("MyModule", { level = "trace" })
```

The minimum level resolves from, in order: the `level` option, the `LOG_LEVEL`
environment variable (Lute), `_G.LOG_LEVEL` (Roblox), then defaults to `info`.

## Development

Archivist uses [Rokit](https://github.com/rojo-rbx/rokit) for toolchain management.

```sh
rokit install
lute run install   # install Loom + Wally dependencies and Lute type defs
lute run example   # run the demo script under Lute
lute run build     # build the Roblox model (Archivist.rbxm)
```

`lute run install` wraps `lute pkg install`, `wally install`, and `lute setup` so a
fresh checkout is one command. It also fetches the shared
[agent-skills](https://github.com/flipbook-labs/agent-skills) library that
[`AGENTS.md`](AGENTS.md) routes agents to.

## License

[MIT](LICENSE)
