local expect = require("@std/test/assert")
local test = require("@std/test")

local CallbackSink = require("@root/sinks/CallbackSink")
local LogRecord = require("@root/core/LogRecord")

local function record(message: string): LogRecord.LogRecord
	return {
		timestamp = 0,
		level = "info",
		name = "test",
		args = table.pack(message),
	}
end

test.suite("CallbackSink", function(suite)
	suite:case("invokes the callback once per record, even for batches", function()
		local received: { string } = {}
		local sink = CallbackSink(function(r)
			table.insert(received, r.args[1])
		end)

		sink.write({ record("one"), record("two"), record("three") })

		expect.eq(#received, 3)
		expect.eq(received[1], "one")
		expect.eq(received[3], "three")
	end)

	suite:case("hands over the raw record, not a formatted string", function()
		local captured: LogRecord.LogRecord? = nil
		local sink = CallbackSink(function(r)
			captured = r
		end)

		sink.write({ record("raw") })

		assert(captured ~= nil, "callback should have captured a record")
		expect.eq(captured.level, "info")
		expect.eq(captured.name, "test")
		expect.eq(captured.args.n, 1)
	end)
end)
