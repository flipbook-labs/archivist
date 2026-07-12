--[[
	Archivist: a structured logging library for Luau that runs on both Lute
	and Roblox.

	`require` resolves the platform seam (`@root/platform`) to the Lute or
	Roblox implementation depending on which build this is; everything else is
	portable and receives the platform by injection.

		local Archivist = require("@pkg/Archivist")
		local logger = Archivist.createLogger("MyModule")
		logger.info("loaded", count, "stories")
]]

local Formatter = require("@root/core/Formatter")
local LogLevel = require("@root/core/LogLevel")
local LogMode = require("@root/core/LogMode")
local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")
local createCallbackSink = require("@root/sinks/createCallbackSink")
local createConsoleSink = require("@root/sinks/createConsoleSink")
local createDispatcher = require("@root/core/createDispatcher")
local createFileSink = require("@root/sinks/createFileSink")
local createJsonFormatter = require("@root/formatters/createJsonFormatter")
local createLogger = require("@root/core/createLogger")
local createPrettyFormatter = require("@root/formatters/createPrettyFormatter")
local createRegistry = require("@root/core/createRegistry")
local createTransportSink = require("@root/sinks/createTransportSink")
local platform = require("@root/platform")

export type LogLevel = LogLevel.LogLevel
export type LogMode = LogMode.LogMode
export type LogRecord = LogRecord.LogRecord
export type Logger = createLogger.Logger
export type Sink = Sink.Sink
export type Formatter = Formatter.Formatter

-- One dispatcher for the whole program so prod-mode batches flush in global
-- call order, and one registry backing `getLogger`.
local dispatcher = createDispatcher(platform)
local registry = createRegistry()

export type CreateLoggerOptions = {
	-- Minimum level to emit. When omitted, resolves from LOG_LEVEL (Lute) /
	-- _G.LOG_LEVEL (Roblox), falling back to "info".
	level: LogLevel?,
	-- "Dev" writes records synchronously like `print`. "Prod" batches them and
	-- writes each sink once per batch. Defaults to "Dev".
	mode: LogMode?,
	-- Output targets. Defaults to a single console sink.
	sinks: { Sink }?,
	-- Structured context attached to every record from this logger.
	fields: { [string]: unknown }?,
}

-- Resolves the starting level: explicit option, then LOG_LEVEL, then
-- _G.LOG_LEVEL, then "info".
local function resolveLevel(options: CreateLoggerOptions?): LogLevel
	if options and options.level then
		return options.level
	end

	local fromEnv = LogLevel.coerce(platform.getEnv("LOG_LEVEL"))
	if fromEnv then
		return fromEnv
	end

	-- Flipbook configures its plugin build via `_G.LOG_LEVEL`; honoring it keeps
	-- Archivist a drop-in there. Roblox has no process environment to read instead.
	-- selene: allow(global_usage)
	local globalLevel = (_G :: any).LOG_LEVEL
	if type(globalLevel) == "string" then
		local coerced = LogLevel.coerce(globalLevel)
		if coerced then
			return coerced
		end
	end

	return LogLevel.Info
end

-- Fills in the defaults an un-configured logger needs: a console sink, dev mode,
-- and a resolved level.
local function resolveConfig(options: CreateLoggerOptions?): createLogger.LoggerConfig
	return {
		level = resolveLevel(options),
		mode = if options and options.mode then options.mode else LogMode.Dev,
		sinks = if options and options.sinks then options.sinks else { createConsoleSink(platform) },
		fields = if options then options.fields else nil,
	}
end

return {
	-- Creates a new, un-cached logger.
	createLogger = function(name: string, options: CreateLoggerOptions?): Logger
		return createLogger(platform, dispatcher, name, resolveConfig(options))
	end,

	-- Returns the cached logger for `name`, creating it (with `options`) on first
	-- use. Later calls ignore `options`.
	getLogger = function(name: string, options: CreateLoggerOptions?): Logger
		return registry.get(name, function()
			return createLogger(platform, dispatcher, name, resolveConfig(options))
		end)
	end,

	createConsoleSink = function(options: createConsoleSink.ConsoleSinkOptions?): Sink
		return createConsoleSink(platform, options)
	end,
	createCallbackSink = function(callback: (LogRecord) -> ()): Sink
		return createCallbackSink(callback)
	end,
	createFileSink = function(options: createFileSink.FileSinkOptions): Sink
		return createFileSink(platform, options)
	end,
	createTransportSink = function(options: createTransportSink.TransportSinkOptions): Sink
		return createTransportSink(options)
	end,
	createPrettyFormatter = function(options: createPrettyFormatter.PrettyFormatterOptions?): Formatter
		return createPrettyFormatter(platform, options)
	end,
	createJsonFormatter = function(options: createJsonFormatter.JsonFormatterOptions?): Formatter
		return createJsonFormatter(platform, options)
	end,
}
