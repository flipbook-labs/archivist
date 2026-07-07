--!strict
--[[
	Lute implementation of the `Platform` seam.

	This module requires `@lute/*` builtins and therefore MUST NOT be reachable
	from the Roblox build (see `.lute/build.luau`, which excludes it and swaps
	`platform/init.luau` for the Roblox implementation).
]]

local io = require("@lute/io")
local process = require("@lute/process")
local task = require("@lute/task")

local types = require("@root/platform/types")

local platform: types.Platform = {
	write = function(line)
		io.write(line .. "\n")
	end,
	warn = function(line)
		io.write(line .. "\n")
	end,
	now = os.time,
	getEnv = function(key)
		local value = process.env[key]
		if value == "" then
			return nil
		end
		return value
	end,
	color = true,
	defer = function(callback)
		task.defer(callback)
	end,
	holdForFlush = function(flush)
		-- `process.onSignal` suppresses the default terminate behavior, so exit
		-- manually after flushing. 130/143 are the conventional exit codes for
		-- SIGINT/SIGTERM. The live handles also keep the event loop open, which
		-- is exactly the hold semantics we want — and why they must be closed
		-- once the batch drains.
		local sigint = process.onSignal("SIGINT", function()
			flush()
			process.exit(130)
		end)
		local sigterm = process.onSignal("SIGTERM", function()
			flush()
			process.exit(143)
		end)

		return function()
			sigint:close()
			sigterm:close()
		end
	end,
}

return platform
