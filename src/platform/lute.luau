--[[
	Lute implementation of the `Platform` seam.

	This module requires Lute's `@std/*` libraries and therefore MUST NOT be
	reachable from the Roblox build (see `.lute/build.luau`, which excludes it
	and swaps `platform/init.luau` for the Roblox implementation).
]]

local io = require("@std/io")
local json = require("@std/json")
local pp = require("@batteries/pp")
local process = require("@std/process")
local richterm = require("@batteries/richterm")
local task = require("@std/task")

local types = require("@root/platform/types")

-- richterm formatters take an extra optional `nocolor` argument, so they don't
-- match `Styler` exactly under strict analysis; adapt them.
local function toStyler(format: richterm.Formatter): types.Styler
	return function(text)
		return format(text)
	end
end

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
	styles = {
		levels = {
			trace = toStyler(richterm.gray),
			debug = toStyler(richterm.cyan),
			info = toStyler(richterm.green),
			warn = toStyler(richterm.yellow),
			err = toStyler(richterm.red),
		},
		dim = toStyler(richterm.dim),
	},
	inspect = function(value)
		if type(value) == "table" then
			return pp(value)
		end
		return tostring(value)
	end,
	jsonEncode = function(value)
		return json.serialize(value)
	end,
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
