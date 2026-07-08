--[[
	Buffered base for shipping records to external destinations (logging
	platforms, HTTP ingest endpoints, analytics).

	Buffers records across writes and hands the accumulated array to `send`
	when the buffer reaches `batchSize` or on `flush`, so a destination like
	an HTTP API receives one request per batch, never one per record. Archivist
	deliberately doesn't do the HTTP itself: `send` gets plain records and the
	caller brings their own client (Lute `@lute/net`, Roblox HttpService).

		local transport = Archivist.TransportSink({
			batchSize = 50,
			send = function(records)
				someHttpClient.post(INGEST_URL, records)
			end,
		})

	`send` failures are the caller's to handle (retry, drop, dead-letter);
	Archivist assumes a `send` that returns.
]]

local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")

local DEFAULT_BATCH_SIZE = 50

export type TransportSinkOptions = {
	send: (records: { LogRecord.LogRecord }) -> (),
	-- Buffer size that triggers a send. Defaults to 50.
	batchSize: number?,
}

local function createTransportSink(options: TransportSinkOptions): Sink.Sink
	local batchSize = options.batchSize or DEFAULT_BATCH_SIZE
	local buffer: { LogRecord.LogRecord } = {}

	local function sendBuffer()
		if #buffer == 0 then
			return
		end
		local sending = buffer
		buffer = {}
		options.send(sending)
	end

	return {
		write = function(records)
			for _, record in records do
				table.insert(buffer, record)
			end
			if #buffer >= batchSize then
				sendBuffer()
			end
		end,
		flush = sendBuffer,
	}
end

return createTransportSink
