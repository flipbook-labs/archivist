--[[
	Caches loggers by name so `getLogger("X")` returns the same instance across
	modules — the cheap way for a codebase to share one configured logger
	without threading it through requires.
]]

local Logger = require("@root/core/Logger")

export type Registry = {
	get: (name: string, create: () -> Logger.Logger) -> Logger.Logger,
}

local function createRegistry(): Registry
	local loggers: { [string]: Logger.Logger } = {}

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
