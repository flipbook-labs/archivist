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
- **Sinks**: route records anywhere: console, files (Lute), or your own callback (e.g. an in-app log viewer)
- **Dev/prod deferral**: sequential `print`-like output in dev; in prod, records batch and each sink is written once per batch instead of once per record

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
logger.info("structured data:", { port = 8080, ready = true })
logger.warn("something looks off")
logger.err("something broke")

-- Children share the parent's sinks and attach fields to every record:
local child = logger.child("requests", { requestId = "abc123" })
child.debug("handling request")

-- Prod mode batches: these queue and flush to each sink as ONE write.
local batched = Archivist.createLogger("Telemetry", { mode = "prod" })
batched.info("queued 1")
batched.info("queued 2")
batched.flush() -- optional; pending batches also flush on defer and at exit

-- Show everything, regardless of LOG_LEVEL:
local verbose = Archivist.createLogger("MyModule", { level = "trace" })
```

The minimum level resolves from, in order: the `level` option, the `LOG_LEVEL`
environment variable (Lute), `_G.LOG_LEVEL` (Roblox), then defaults to `info`.

`Archivist.getLogger(name)` returns a per-name cached logger so modules can
share one configured logger without threading it through requires.

## Development

Archivist uses [Rokit](https://github.com/rojo-rbx/rokit) for toolchain management.

```sh
rokit install
lute run example   # run the demo script under Lute
lute test          # run the unit tests
lute run build     # build the Roblox model (Archivist.rbxm)
```

## License

[MIT](LICENSE)
