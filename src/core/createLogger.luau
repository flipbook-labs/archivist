--[[
	Minimal logger used to prove the platform seam (Stage 1 spike).

	Dot-style, varargs API, drop-in shaped like FlipbookBatteries' createLogger:
		logger.info("message", value, ...)

	The full core (structured records, sinks, dev/prod batching) lands in Stage 2;
	for now this formats a single coloured line and routes it through the injected
	platform.
]]

local LogLevel = require("@root/core/LogLevel")
local richterm = require("@root/vendor/richterm")
local types = require("@root/platform/types")

type LogLevelT = types.LogLevel

export type Logger = {
	trace: (...any) -> (),
	debug: (...any) -> (),
	info: (...any) -> (),
	warn: (...any) -> (),
	err: (...any) -> (),
	getLevel: () -> LogLevelT,
	setLevel: (level: LogLevelT) -> (),
}

local LEVEL_COLOR: { [LogLevelT]: richterm.Formatter } = {
	trace = richterm.gray,
	debug = richterm.cyan,
	info = richterm.green,
	warn = richterm.yellow,
	err = richterm.red,
}

local function stringifyArgs(...: any): string
	local packed = table.pack(...)
	local parts = table.create(packed.n)
	for index = 1, packed.n do
		parts[index] = tostring(packed[index])
	end
	return table.concat(parts, " ")
end

local function createLogger(platform: types.Platform, name: string, level: LogLevelT?): Logger
	local currentLevel: LogLevelT = level or "info"

	local function emit(recordLevel: LogLevelT, ...: any)
		if not LogLevel.shouldLog(currentLevel, recordLevel) then
			return
		end

		local message = stringifyArgs(...)
		local line = `[{name}] [{recordLevel}] {message}`

		if platform.color then
			line = LEVEL_COLOR[recordLevel](line)
		end

		if recordLevel == "warn" or recordLevel == "err" then
			platform.warn(line)
		else
			platform.write(line)
		end
	end

	return {
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
	}
end

return createLogger
