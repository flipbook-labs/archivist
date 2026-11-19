--[[
	Hands every `LogRecord` to a user function: the escape hatch for anything
	the built-in sinks don't cover, e.g. feeding an in-app log viewer:

		Archivist.createCallbackSink(function(record)
			LogsStore.get().addLine(record)
		end)

	The callback receives records one at a time even in prod mode (batching
	exists to amortise expensive I/O; a plain function call is not that). Use
	createTransportSink when the destination genuinely wants batches.
]]

local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")

local function createCallbackSink(callback: (record: LogRecord.LogRecord) -> ()): Sink.Sink
	return {
		write = function(records)
			for _, record in records do
				callback(record)
			end
		end,
	}
end

return createCallbackSink
