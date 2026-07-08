--[[
	Archivist — a structured logging library for Luau that runs on both Lute
	and Roblox.

	`require` resolves the platform seam (`@root/platform`) to the Lute or
	Roblox implementation depending on which build this is; everything else is
	portable and receives the platform by injection.

		local Archivist = require("@pkg/Archivist")
		local logger = Archivist.createLogger("MyModule")
		logger.info("loaded", count, "stories")
]]

local ConsoleSink = require("@root/sinks/ConsoleSink")
local Formatter = require("@root/core/Formatter")
local LogLevel = require("@root/core/LogLevel")
local LogRecord = require("@root/core/LogRecord")
local Logger = require("@root/core/Logger")
local PrettyFormatter = require("@root/formatters/PrettyFormatter")
local Sink = require("@root/core/Sink")
local createDispatcher = require("@root/core/createDispatcher")
local createRegistry = require("@root/core/createRegistry")
local platform = require("@root/platform")

export type LogLevel = LogLevel.LogLevel
export type LogRecord = LogRecord.LogRecord
export type Logger = Logger.Logger
export type Mode = Logger.Mode
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
	-- "dev" writes records synchronously like `print`; "prod" batches them and
	-- writes each sink once per batch. Defaults to "dev".
	mode: Mode?,
	-- Output targets. Defaults to a single console sink.
	sinks: { Sink }?,
	-- Structured context attached to every record from this logger.
	fields: { [string]: any }?,
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

	return "info"
end

local function newConsoleSink(options: ConsoleSink.ConsoleSinkOptions?): Sink
	return ConsoleSink(platform, options)
end

local function newPrettyFormatter(options: PrettyFormatter.PrettyFormatterOptions?): Formatter
	return PrettyFormatter(platform, options)
end

-- Creates a new, un-cached logger.
local function createLogger(name: string, options: CreateLoggerOptions?): Logger
	return Logger(platform, dispatcher, name, {
		level = resolveLevel(options),
		mode = if options and options.mode then options.mode else "dev",
		sinks = if options and options.sinks then options.sinks else { newConsoleSink() },
		fields = if options then options.fields else nil,
	})
end

-- Returns the cached logger for `name`, creating it (with `options`) on first
-- use. Later calls ignore `options`.
local function getLogger(name: string, options: CreateLoggerOptions?): Logger
	return registry.get(name, function()
		return createLogger(name, options)
	end)
end

return {
	createLogger = createLogger,
	getLogger = getLogger,

	ConsoleSink = newConsoleSink,
	PrettyFormatter = newPrettyFormatter,
}
