local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local LogRecord = require("@root/core/LogRecord")
local createCallbackSink = require("@root/sinks/createCallbackSink")

local function record(message: string): LogRecord.LogRecord
	return {
		timestamp = 0,
		level = LogLevel.Info,
		name = "test",
		args = table.pack(message),
	}
end

test.suite("CallbackSink", function(suite)
	suite:case("invokes the callback once per record, even for batches", function()
		local received: { string } = {}
		local sink = createCallbackSink(function(r)
			table.insert(received, r.args[1])
		end)

		sink.write({ record("one"), record("two"), record("three") })

		expect.eq(#received, 3)
		expect.eq(received[1], "one")
		expect.eq(received[3], "three")
	end)

	suite:case("hands over the raw record, not a formatted string", function()
		local captured: LogRecord.LogRecord? = nil
		local sink = createCallbackSink(function(r)
			captured = r
		end)

		sink.write({ record("raw") })

		assert(captured ~= nil, "callback should have captured a record")
		expect.eq(captured.level, LogLevel.Info)
		expect.eq(captured.name, "test")
		expect.eq(captured.args.n, 1)
	end)
end)
