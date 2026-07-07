--[[
	Lute implementation of the `Platform` seam.

	This module requires `@lute/*` builtins and therefore MUST NOT be reachable
	from the Roblox build (see `.lute/build.luau`, which excludes it and swaps
	`platform/init.luau` for the Roblox implementation).
]]

local io = require("@lute/io")
local process = require("@lute/process")

local types = require("@root/platform/types")

local platform: types.Platform = {
	write = function(line)
		io.write(line .. "\n")
	end,
	warn = function(line)
		io.write(line .. "\n")
	end,
	-- os.time takes an optional DateTypeArg, so its type is (DateTypeArg?) -> number
	-- and does not satisfy Platform.now's () -> number under strict analysis;
	-- wrapping drops the optional parameter.
	now = function()
		return os.time()
	end,
	getEnv = function(key)
		local value = process.env[key]
		if value == "" then
			return nil
		end
		return value
	end,
	color = true,
}

return platform
