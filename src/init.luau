--[[
	Public entry point.

	`require` resolves the platform seam (`./platform`) to the Lute or Roblox
	implementation depending on which build this is, then hands it to the
	portable core.
]]

local LogLevel = require("@root/core/LogLevel")
local createLoggerImpl = require("@root/core/createLogger")
local platform = require("@root/platform")
local types = require("@root/platform/types")

export type LogLevel = types.LogLevel
export type Logger = createLoggerImpl.Logger

export type CreateLoggerOptions = {
	-- Minimum level to emit. When omitted, resolves from LOG_LEVEL / _G.LOG_LEVEL,
	-- falling back to "info".
	level: LogLevel?,
}

-- Resolves the starting level: explicit option, then LOG_LEVEL, then _G.LOG_LEVEL,
-- then "info".
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

local function createLogger(name: string, options: CreateLoggerOptions?): Logger
	return createLoggerImpl(platform, name, resolveLevel(options))
end

return {
	createLogger = createLogger,
}
