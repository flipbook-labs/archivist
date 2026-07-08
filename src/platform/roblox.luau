--[[
	Roblox implementation of the `Platform` seam.

	Uses only Roblox globals (`print`, `warn`, `os.time`). The Roblox build swaps
	this in for `platform/init.luau`; see `.lute/build.luau`.
]]

local types = require("@root/platform/types")

local platform: types.Platform = {
	write = function(line)
		print(line)
	end,
	warn = function(line)
		-- This module only ever runs on Roblox, where `warn` is a global; selene
		-- lints against the plain Luau std and cannot see it.
		-- selene: allow(undefined_variable)
		warn(line)
	end,
	now = function()
		return os.time()
	end,
	getEnv = function(_key)
		return nil
	end,
	color = false,
}

return platform
