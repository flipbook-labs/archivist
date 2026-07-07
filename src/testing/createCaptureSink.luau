--!strict
--[[
	A test sink that records every batch and record it receives.

	Exposes the `Sink` separately from the capture arrays so call sites can pass
	`capture.sink` where a `Sink` is expected without fighting table exactness.
]]

local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")

export type CaptureSink = {
	sink: Sink.Sink,
	-- Every batch exactly as delivered to `write`.
	batches: { { LogRecord.LogRecord } },
	-- Every record in delivery order, flattened across batches.
	records: { LogRecord.LogRecord },
}

local function createCaptureSink(): CaptureSink
	local batches: { { LogRecord.LogRecord } } = {}
	local records: { LogRecord.LogRecord } = {}

	local sink: Sink.Sink = {
		write = function(batch: { LogRecord.LogRecord })
			table.insert(batches, batch)
			for _, record in batch do
				table.insert(records, record)
			end
		end,
	}

	return {
		sink = sink,
		batches = batches,
		records = records,
	}
end

return createCaptureSink
