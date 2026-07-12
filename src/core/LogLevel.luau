--[[
	Log levels and their severity ordering.

	Ordering (ascending severity): trace < debug < info < warn < err.
	A record is emitted when its severity is >= the logger's minimum level.
]]

local types = require("@root/platform/types")

export type LogLevel = types.LogLevel

local LogLevel = {
	Trace = "trace" :: "trace",
	Debug = "debug" :: "debug",
	Info = "info" :: "info",
	Warn = "warn" :: "warn",
	Err = "err" :: "err",
}

local ORDER: { [LogLevel]: number } = {
	[LogLevel.Trace] = 1,
	[LogLevel.Debug] = 2,
	[LogLevel.Info] = 3,
	[LogLevel.Warn] = 4,
	[LogLevel.Err] = 5,
}

LogLevel.ORDER = ORDER

-- Returns true when `level` should be emitted under the given `minimum`.
function LogLevel.shouldLog(minimum: LogLevel, level: LogLevel): boolean
	return ORDER[level] >= ORDER[minimum]
end

-- Coerces an arbitrary string (e.g. from LOG_LEVEL) to a LogLevel, or nil.
function LogLevel.coerce(raw: string?): LogLevel?
	if not raw then
		return nil
	end
	local lowered = string.lower(raw)
	if ORDER[lowered :: LogLevel] then
		return lowered :: LogLevel
	end
	-- Accept a couple of common aliases.
	if lowered == "error" then
		return LogLevel.Err
	elseif lowered == "warning" then
		return LogLevel.Warn
	end
	return nil
end

return LogLevel
