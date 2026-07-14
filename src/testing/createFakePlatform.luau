--[[
	A deterministic, fully-inspectable `Platform` for tests.

	- `write`/`warn` capture into `written`/`warned` arrays
	- `defer` captures callbacks; tests pump them explicitly via `runDeferred`
	- `now` returns a fixed, settable time
	- `env` is a plain table backing `getEnv`
	- `openAppendable` is an in-memory filesystem: `files` holds appended chunks
	  per path, `closedFiles` records which handles were closed
	- `styles` wrap text in `<style>...</style>` markers so assertions can
	  check that (and which) styling was applied without ANSI escapes
	- `inspect`/`jsonEncode` use the real Lute implementations (this helper
	  only ever runs under `lute test`; it never ships to Roblox)
]]

local json = require("@std/json")
local pp = require("@batteries/pp")

local types = require("@root/platform/types")

local function marker(name: string): types.Styler
	return function(text)
		return `<{name}>{text}</{name}>`
	end
end

export type FakePlatform = {
	platform: types.Platform,
	written: { string },
	warned: { string },
	env: { [string]: string },
	-- In-memory filesystem backing `openAppendable`: path -> appended chunks.
	files: { [string]: { string } },
	-- Paths whose append handles have been closed.
	closedFiles: { [string]: boolean },
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
	local files: { [string]: { string } } = {}
	local closedFiles: { [string]: boolean } = {}
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
		styles = {
			levels = {
				Trace = marker("trace"),
				Debug = marker("debug"),
				Info = marker("info"),
				Warn = marker("warn"),
				Err = marker("err"),
			},
			dim = marker("dim"),
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
			table.insert(deferred, callback)
		end,
		holdForFlush = function(flush)
			table.insert(holds, flush)
			return function()
				released += 1
			end
		end,
		openAppendable = function(path)
			local chunks = files[path] or {}
			files[path] = chunks
			return {
				append = function(text)
					table.insert(chunks, text)
				end,
				close = function()
					closedFiles[path] = true
				end,
			}
		end,
	}

	local fake: FakePlatform = {
		platform = platform,
		written = written,
		warned = warned,
		env = env,
		files = files,
		closedFiles = closedFiles,
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
