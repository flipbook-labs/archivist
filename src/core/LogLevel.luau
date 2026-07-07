--[[
	Log levels and their severity ordering.

	Ordering (ascending severity): trace < debug < info < warn < err.
	A record is emitted when its severity is >= the logger's minimum level.
]]

local types = require("@root/platform/types")

export type LogLevel = types.LogLevel

local ORDER: { [types.LogLevel]: number } = {
	trace = 1,
	debug = 2,
	info = 3,
	warn = 4,
	err = 5,
}

local LogLevel = {}

LogLevel.ORDER = ORDER

-- Returns true when `level` should be emitted under the given `minimum`.
function LogLevel.shouldLog(minimum: types.LogLevel, level: types.LogLevel): boolean
	return ORDER[level] >= ORDER[minimum]
end

-- Coerces an arbitrary string (e.g. from LOG_LEVEL) to a LogLevel, or nil.
function LogLevel.coerce(raw: string?): types.LogLevel?
	if not raw then
		return nil
	end
	local lowered = string.lower(raw)
	if ORDER[lowered :: types.LogLevel] then
		return lowered :: types.LogLevel
	end
	-- Accept a couple of common aliases.
	if lowered == "error" then
		return "err"
	elseif lowered == "warning" then
		return "warn"
	end
	return nil
end

return LogLevel
