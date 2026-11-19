local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local LogRecord = require("@root/core/LogRecord")
local createTransportSink = require("@root/sinks/createTransportSink")

local function record(message: any): LogRecord.LogRecord
	return {
		timestamp = 0,
		level = LogLevel.Info,
		name = "test",
		args = table.pack(message),
	}
end

test.suite("TransportSink", function(suite)
	suite:case("buffers below batchSize without sending", function()
		local sends = {}
		local sink = createTransportSink({
			batchSize = 3,
			send = function(records)
				table.insert(sends, records)
			end,
		})

		sink.write({ record(1) })
		sink.write({ record(2) })

		expect.eq(#sends, 0)
	end)

	suite:case("sends the whole buffer when batchSize is reached", function()
		local sends = {}
		local sink = createTransportSink({
			batchSize = 3,
			send = function(records)
				table.insert(sends, records)
			end,
		})

		sink.write({ record(1) })
		sink.write({ record(2), record(3) })

		expect.eq(#sends, 1)
		expect.eq(#sends[1], 3)
		expect.eq(sends[1][1].args[1], 1)
		expect.eq(sends[1][3].args[1], 3)
	end)

	suite:case("flush sends a partial buffer and empties it", function()
		local sends = {}
		local sink = createTransportSink({
			batchSize = 100,
			send = function(records)
				table.insert(sends, records)
			end,
		})

		sink.write({ record("pending") })
		assert(sink.flush, "TransportSink should expose flush")
		sink.flush()

		expect.eq(#sends, 1)
		expect.eq(#sends[1], 1)

		-- Nothing left: a second flush is a no-op.
		sink.flush()
		expect.eq(#sends, 1)
	end)

	suite:case("accumulates again after a send", function()
		local sends = {}
		local sink = createTransportSink({
			batchSize = 2,
			send = function(records)
				table.insert(sends, records)
			end,
		})

		sink.write({ record(1), record(2) })
		sink.write({ record(3), record(4) })

		expect.eq(#sends, 2)
		expect.eq(sends[2][1].args[1], 3)
	end)
end)
