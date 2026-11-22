# Archivist

Archivist is a structured logging library for Luau that runs on both [Lute](https://github.com/luau-lang/lute) and Roblox. Each log call produces a record that sinks send to the console, a file, or your own callback. Archivist is pre-release, and its API may change before v1.

## Install

For Roblox, with Wally:

```toml
[dependencies]
Archivist = "flipbook-labs/archivist@0.3.1"
```

For Lute, add this to the `dependencies` table in `pkg.luau`, then run `lute pkg install --vendor`:

```luau
["archivist"] = {
	rev = "v0.3.1",
	sourceKind = "github",
	source = "https://github.com/flipbook-labs/archivist",
},
```

Lute projects also need Lute `1.0.1-nightly.20261117` or newer, and `lpm = "./.lpm"` in the `aliases` table of `.config.luau`. Archivist requires its dependencies through that alias.

## Use

```luau
local Archivist = require("@pkg/Archivist")

local logger = Archivist.createLogger("MyModule")
logger.info("loaded", 3, "stories")
```

On Lute, the console prints `[info] loaded 3 stories`, and you require the vendored copy as `@lpm/archivist@v0.3.1` instead of `@pkg/Archivist`.

`Archivist.getLogger(name)` returns the same logger for a given name, so modules can share one configured logger. Later calls with that name ignore their options.

## Levels

The levels, in ascending order, are `trace`, `debug`, `info`, `warn`, and `err`. A logger drops records below its minimum level. The minimum comes from the first of these that is set: the `level` option, the `LOG_LEVEL` environment variable on Lute, `_G.LOG_LEVEL` on Roblox, and then `info`.

The `level` option takes the capitalized name, as in `"Trace"`:

```luau
local verbose = Archivist.createLogger("MyModule", { level = "Trace" })
```

## Child loggers

`logger.child(name, fields)` returns a logger that copies its parent's sinks, level, and mode. Its name joins the parent's name with `/`, and its fields go on every record:

```luau
local request = logger.child("requests", { requestId = "abc123" })
request.info("handling request")
```

## Sinks

Without a `sinks` option, a logger writes to one console sink. Pass `sinks` to choose the destinations:

```luau
local logger = Archivist.createLogger("App", {
	sinks = {
		Archivist.createConsoleSink(),
		Archivist.createCallbackSink(function(record)
			print(record.level, record.name)
		end),
	},
})
```

- `createCallbackSink(callback)` calls `callback` with each record, one at a time, even in prod mode.
- `createFileSink({ path })` appends one JSON object per line to a file. It is Lute only, and it errors on Roblox.
- `createTransportSink({ batchSize, send })` buffers records and calls `send` with each batch. `batchSize` defaults to 50. `send` uses your own HTTP client.

## Formatters

The console sink formats each record as `[level] message`. The built-in middleware adds logger names or timestamps to that line:

```luau
local logger = Archivist.createLogger("MyModule", {
	middleware = {
		Archivist.middleware.name,
		Archivist.middleware.timestamp,
	},
})
```

Middleware runs in the order listed. Each function receives the formatted line and a context table, and returns the line to print. The `middleware` option applies only when Archivist creates the console sink. With your own `sinks`, put middleware on a formatter instead:

```luau
local formatter = Archivist.createPrettyFormatter({
	middleware = { Archivist.middleware.name },
})
local logger = Archivist.createLogger("MyModule", {
	sinks = { Archivist.createConsoleSink({ formatter = formatter }) },
})
```

`createJsonFormatter()` writes one JSON object per line. File sinks use it by default.

## Prod mode

Loggers default to dev mode, where each call writes right away, like `print`. Set `mode = "Prod"` to queue records and write each sink once per batch. Call `logger.flush()` before a short-lived program exits, so queued records reach the sinks.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT.
