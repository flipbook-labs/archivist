--[[
	Roblox implementation of the `Platform` seam.

	Uses only Roblox globals (`print`, `warn`, `task`, `os.time`). The Roblox
	build swaps this in for `platform/init.luau`; see `.lute/build.luau`.

	selene lints against the plain Luau std and cannot see Roblox globals, hence
	the targeted allows below.
]]

local types = require("@root/platform/types")

-- `holdForFlush` is called once per batch window but `game:BindToClose` has no
-- unbind, so bind each distinct flush function only once for the session.
local boundFlushes: { [() -> ()]: boolean } = {}

-- The Roblox Output window strips ANSI codes, so styles are identity. If
-- terminal-rendered output ever matters here (e.g. Open Cloud runs), these can
-- delegate to a chalk-style Wally package instead — Jest-Lua uses
-- jsdotlua/chalk for exactly that.
local function identity(text: string): string
	return text
end

local function jsonEncode(value: any): string
	-- selene: allow(undefined_variable)
	return game:GetService("HttpService"):JSONEncode(value)
end

local platform: types.Platform = {
	write = function(line)
		print(line)
	end,
	warn = function(line)
		-- selene: allow(undefined_variable)
		warn(line)
	end,
	-- os.time takes an optional DateTypeArg, so its type is (DateTypeArg?) -> number
	-- and does not satisfy Platform.now's () -> number under strict analysis;
	-- wrapping drops the optional parameter.
	now = function()
		return os.time()
	end,
	getEnv = function(_key)
		return nil
	end,
	color = false,
	styles = {
		levels = {
			trace = identity,
			debug = identity,
			info = identity,
			warn = identity,
			err = identity,
		},
		dim = identity,
	},
	inspect = function(value)
		if type(value) == "table" then
			local success, encoded = pcall(jsonEncode, value)
			if success then
				return encoded
			end
		end
		return tostring(value)
	end,
	jsonEncode = jsonEncode,
	defer = function(callback)
		-- selene: allow(undefined_variable)
		task.defer(callback)
	end,
	holdForFlush = function(flush)
		-- Roblox has no process to hold open and nothing to unregister, so this
		-- is best-effort: bind `flush` to DataModel close where available
		-- (`game:BindToClose` is server-only; plugins and clients skip it).
		-- Batches on Roblox flush every defer cycle regardless, so little is
		-- ever pending at shutdown.
		-- selene: allow(undefined_variable)
		if not boundFlushes[flush] and typeof(game) == "Instance" then
			boundFlushes[flush] = true
			pcall(function()
				-- selene: allow(undefined_variable, incorrect_standard_library_use)
				game:BindToClose(flush)
			end)
		end

		return function() end
	end,
}

return platform
