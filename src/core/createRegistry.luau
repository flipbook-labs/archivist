--[[
	Caches loggers by name so `getLogger("X")` returns the same instance across
	modules. This is the cheap way for a codebase to share one configured logger
	without threading it through requires.
]]

local createLogger = require("@root/core/createLogger")

export type Registry = {
	get: (name: string, create: () -> createLogger.Logger) -> createLogger.Logger,
}

local function createRegistry(): Registry
	local loggers: { [string]: createLogger.Logger } = {}

	return {
		get = function(name, create)
			local existing = loggers[name]
			if existing then
				return existing
			end
			local logger = create()
			loggers[name] = logger
			return logger
		end,
	}
end

return createRegistry
