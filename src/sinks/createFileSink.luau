--[[
	Appends formatted records to a log file, one per line. Lute only: the
	constructor errors on runtimes without a filesystem (Roblox), which is a
	deliberate fail-fast. A silently dropped log file is worse than a loud one.

	The file opens lazily on the first write and stays open; a whole batch is
	appended with a single filesystem write. Defaults to the JsonFormatter so
	log files are machine-consumable.
]]

local Formatter = require("@root/core/Formatter")
local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")
local createJsonFormatter = require("@root/formatters/createJsonFormatter")
local types = require("@root/platform/types")

export type FileSinkOptions = {
	path: string,
	-- Defaults to a JsonFormatter.
	formatter: Formatter.Formatter?,
}

local function createFileSink(platform: types.Platform, options: FileSinkOptions): Sink.Sink
	local openAppendable = platform.openAppendable
	assert(openAppendable ~= nil, "FileSink is not supported on this runtime: it has no filesystem")

	local formatter = if options.formatter then options.formatter else createJsonFormatter(platform)
	local handle: types.AppendHandle? = nil

	local function write(records: { LogRecord.LogRecord })
		local openHandle: types.AppendHandle = if handle then handle else openAppendable(options.path)
		handle = openHandle

		local lines = table.create(#records + 1)
		for index, record in records do
			lines[index] = formatter.format(record)
		end
		-- Trailing "" so concat ends the last record's line.
		table.insert(lines, "")

		openHandle.append(table.concat(lines, "\n"))
	end

	local function close()
		if handle then
			handle.close()
			handle = nil
		end
	end

	return {
		write = write,
		close = close,
	}
end

return createFileSink
