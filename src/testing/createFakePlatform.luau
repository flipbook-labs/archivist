--!strict
--[[
	A deterministic, fully-inspectable `Platform` for tests.

	- `write`/`warn` capture into `written`/`warned` arrays
	- `defer` captures callbacks; tests pump them explicitly via `runDeferred`
	- `now` returns a fixed, settable time
	- `env` is a plain table backing `getEnv`
]]

local types = require("@root/platform/types")

export type FakePlatform = {
	platform: types.Platform,
	written: { string },
	warned: { string },
	env: { [string]: string },
	-- Flush callbacks captured from `holdForFlush`, in registration order.
	holds: { () -> () },
	-- How many holds have been released so far.
	releasedCount: () -> number,
	-- Runs and clears every captured defer callback; returns how many ran.
	runDeferred: () -> number,
	setNow: (timestamp: number) -> (),
}

local function createFakePlatform(): FakePlatform
	local written: { string } = {}
	local warned: { string } = {}
	local env: { [string]: string } = {}
	local holds: { () -> () } = {}
	local released = 0
	local deferred: { () -> () } = {}
	local now = 1750000000

	local platform: types.Platform = {
		write = function(line)
			table.insert(written, line)
		end,
		warn = function(line)
			table.insert(warned, line)
		end,
		now = function()
			return now
		end,
		getEnv = function(key): string?
			return env[key]
		end,
		color = false,
		defer = function(callback)
			table.insert(deferred, callback)
		end,
		holdForFlush = function(flush)
			table.insert(holds, flush)
			return function()
				released += 1
			end
		end,
	}

	local fake: FakePlatform = {
		platform = platform,
		written = written,
		warned = warned,
		env = env,
		holds = holds,
		releasedCount = function(): number
			return released
		end,
		runDeferred = function(): number
			local toRun = deferred
			deferred = {}
			for _, callback in toRun do
				callback()
			end
			return #toRun
		end,
		setNow = function(timestamp: number)
			now = timestamp
		end,
	}

	return fake
end

return createFakePlatform
