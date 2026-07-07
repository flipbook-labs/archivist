local expect = require("@std/test/assert")
local test = require("@std/test")

local LogRecord = require("@root/core/LogRecord")
local Logger = require("@root/core/Logger")
local createDispatcher = require("@root/core/createDispatcher")
local createFakePlatform = require("@root/testing/createFakePlatform")

type CaptureSink = {
	write: (records: { LogRecord.LogRecord }) -> (),
	batches: { { LogRecord.LogRecord } },
	records: { LogRecord.LogRecord },
}

local function createCaptureSink(): CaptureSink
	local batches = {}
	local records = {}
	return {
		write = function(batch)
			table.insert(batches, batch)
			for _, record in batch do
				table.insert(records, record)
			end
		end,
		batches = batches,
		records = records,
	}
end

local function createTestLogger(config: {
	level: ("trace" | "debug" | "info" | "warn" | "err")?,
	mode: ("dev" | "prod")?,
	fields: { [string]: any }?,
})
	local fake = createFakePlatform()
	local dispatcher = createDispatcher(fake.platform)
	local sink = createCaptureSink()
	local logger = Logger(fake.platform, dispatcher, "test", {
		level = config.level or "info",
		mode = config.mode or "dev",
		sinks = { sink },
		fields = config.fields,
	})
	return logger, sink, fake
end

test.suite("Logger levels", function(suite)
	suite:case("filters records below the minimum level", function()
		local logger, sink = createTestLogger({ level = "info" })

		logger.trace("hidden")
		logger.debug("hidden")
		logger.info("shown")
		logger.warn("shown")
		logger.err("shown")

		expect.eq(#sink.records, 3)
		expect.eq(sink.records[1].level, "info")
		expect.eq(sink.records[2].level, "warn")
		expect.eq(sink.records[3].level, "err")
	end)

	suite:case("setLevel takes effect for subsequent calls", function()
		local logger, sink = createTestLogger({ level = "err" })

		logger.info("hidden")
		logger.setLevel("trace")
		logger.trace("shown")

		expect.eq(#sink.records, 1)
		expect.eq(sink.records[1].level, "trace")
	end)
end)

test.suite("Logger records", function(suite)
	suite:case("captures name, timestamp, and packed varargs", function()
		local logger, sink, fake = createTestLogger({})
		fake.setNow(1234567890)

		logger.info("loaded", 3, true, nil)

		local record = sink.records[1]
		expect.eq(record.name, "test")
		expect.eq(record.timestamp, 1234567890)
		expect.eq(record.args.n, 4)
		expect.eq(record.args[1], "loaded")
		expect.eq(record.args[2], 3)
		expect.eq(record.args[3], true)
		expect.eq(record.args[4], nil)
	end)

	suite:case("attaches configured fields to every record", function()
		local logger, sink = createTestLogger({ fields = { requestId = "abc" } })

		logger.info("hello")

		expect.eq(sink.records[1].fields :: any, { requestId = "abc" })
	end)
end)

test.suite("Logger children", function(suite)
	suite:case("joins names with a slash", function()
		local logger, sink = createTestLogger({})

		logger.child("settings").info("hello")

		expect.eq(sink.records[1].name, "test/settings")
	end)

	suite:case("merges fields over the parent's", function()
		local logger, sink = createTestLogger({ fields = { a = 1, b = 1 } })

		logger.child(nil, { b = 2, c = 3 }).info("hello")

		expect.eq(sink.records[1].fields :: any, { a = 1, b = 2, c = 3 })
	end)

	suite:case("does not leak sinks added to the child back to the parent", function()
		local logger, sink = createTestLogger({})
		local childSink = createCaptureSink()

		local child = logger.child("child")
		child.addSink(childSink)
		logger.info("parent only")

		expect.eq(#sink.records, 1)
		expect.eq(#childSink.records, 0)
	end)
end)
