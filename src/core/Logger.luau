--!strict
--[[
	The logger: builds a `LogRecord` per call, filters it by level, and hands it
	to the dispatcher.

	Dot-style, varargs API, consistent with FlipbookBatteries' createLogger:

		logger.info("loaded", count, "stories")

	Loggers are plain tables of closures (no metatables), so methods can be
	destructured freely: `local info = logger.info`.
]]

local LogLevel = require("@root/core/LogLevel")
local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")
local createDispatcher = require("@root/core/createDispatcher")
local types = require("@root/platform/types")

type LogLevelT = types.LogLevel
type SinkT = Sink.Sink

export type Mode = "dev" | "prod"

export type Logger = {
	trace: (...any) -> (),
	debug: (...any) -> (),
	info: (...any) -> (),
	warn: (...any) -> (),
	err: (...any) -> (),

	getLevel: () -> LogLevelT,
	setLevel: (level: LogLevelT) -> (),
	getMode: () -> Mode,
	setMode: (mode: Mode) -> (),
	addSink: (sink: SinkT) -> (),
	removeSink: (sink: SinkT) -> (),

	-- Derives a logger that shares this logger's sinks, level, and mode at
	-- creation time. `name` is appended as "parent/name"; `fields` are merged
	-- over the parent's fields and attached to every record.
	child: (name: string?, fields: { [string]: any }?) -> Logger,

	-- Forces any batched records (prod mode) out to sinks immediately.
	flush: () -> (),
}

export type LoggerConfig = {
	level: LogLevelT,
	mode: Mode,
	sinks: { SinkT },
	fields: { [string]: any }?,
}

local function createLogger(
	platform: types.Platform,
	dispatcher: createDispatcher.Dispatcher,
	name: string,
	config: LoggerConfig
): Logger
	local currentLevel = config.level
	local currentMode = config.mode
	-- Copied so `addSink`/`removeSink` never mutate a caller's (or parent's) table.
	local sinks = table.clone(config.sinks)
	local fields = config.fields

	local function emit(recordLevel: LogLevelT, ...: any)
		if not LogLevel.shouldLog(currentLevel, recordLevel) then
			return
		end

		local record: LogRecord.LogRecord = {
			timestamp = platform.now(),
			level = recordLevel,
			name = name,
			args = table.pack(...),
			fields = fields,
		}

		dispatcher.dispatch(sinks, record, currentMode)
	end

	local logger: Logger = {
		trace = function(...)
			emit("trace", ...)
		end,
		debug = function(...)
			emit("debug", ...)
		end,
		info = function(...)
			emit("info", ...)
		end,
		warn = function(...)
			emit("warn", ...)
		end,
		err = function(...)
			emit("err", ...)
		end,

		getLevel = function()
			return currentLevel
		end,
		setLevel = function(newLevel)
			currentLevel = newLevel
		end,
		getMode = function()
			return currentMode
		end,
		setMode = function(newMode)
			currentMode = newMode
		end,
		addSink = function(sink)
			table.insert(sinks, sink)
		end,
		removeSink = function(sink)
			local index = table.find(sinks, sink)
			if index then
				table.remove(sinks, index)
			end
		end,

		child = function(childName, childFields)
			local mergedFields = fields
			if childFields then
				mergedFields = if fields then table.clone(fields) else {}
				for key, value in childFields do
					mergedFields[key] = value
				end
			end

			return createLogger(platform, dispatcher, if childName then `{name}/{childName}` else name, {
				level = currentLevel,
				mode = currentMode,
				sinks = sinks,
				fields = mergedFields,
			})
		end,

		flush = function()
			dispatcher.flush()
		end,
	}

	return logger
end

return createLogger
