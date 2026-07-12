local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local LogMode = require("@root/core/LogMode")
local createCaptureSink = require("@root/testing/createCaptureSink")
local createDispatcher = require("@root/core/createDispatcher")
local createFakePlatform = require("@root/testing/createFakePlatform")
local createLogger = require("@root/core/createLogger")

local function createTestLogger(config: {
	level: LogLevel.LogLevel?,
	mode: LogMode.LogMode?,
	fields: { [string]: any }?,
})
	local fake = createFakePlatform()
	local dispatcher = createDispatcher(fake.platform)
	local capture = createCaptureSink()
	local logger = createLogger(fake.platform, dispatcher, "test", {
		level = config.level or LogLevel.Info,
		mode = config.mode or LogMode.Dev,
		sinks = { capture.sink },
		fields = config.fields,
	})
	return logger, capture, fake
end

test.suite("Logger levels", function(suite)
	suite:case("filters records below the minimum level", function()
		local logger, capture = createTestLogger({ level = LogLevel.Info })

		logger.trace("hidden")
		logger.debug("hidden")
		logger.info("shown")
		logger.warn("shown")
		logger.err("shown")

		expect.eq(#capture.records, 3)
		expect.eq(capture.records[1].level, LogLevel.Info)
		expect.eq(capture.records[2].level, LogLevel.Warn)
		expect.eq(capture.records[3].level, LogLevel.Err)
	end)

	suite:case("setLevel takes effect for subsequent calls", function()
		local logger, capture = createTestLogger({ level = LogLevel.Err })

		logger.info("hidden")
		logger.setLevel(LogLevel.Trace)
		logger.trace("shown")

		expect.eq(#capture.records, 1)
		expect.eq(capture.records[1].level, LogLevel.Trace)
	end)
end)

test.suite("Logger records", function(suite)
	suite:case("captures name, timestamp, and packed varargs", function()
		local logger, capture, fake = createTestLogger({})
		fake.setNow(1234567890)

		logger.info("loaded", 3, true, nil)

		local record = capture.records[1]
		expect.eq(record.name, "test")
		expect.eq(record.timestamp, 1234567890)
		expect.eq(record.args.n, 4)
		expect.eq(record.args[1], "loaded")
		expect.eq(record.args[2], 3)
		expect.eq(record.args[3], true)
		expect.eq(record.args[4], nil)
	end)

	suite:case("attaches configured fields to every record", function()
		local logger, capture = createTestLogger({ fields = { requestId = "abc" } })

		logger.info("hello")

		expect.eq(capture.records[1].fields :: any, { requestId = "abc" })
	end)
end)

test.suite("Logger children", function(suite)
	suite:case("joins names with a slash", function()
		local logger, capture = createTestLogger({})

		logger.child("settings").info("hello")

		expect.eq(capture.records[1].name, "test/settings")
	end)

	suite:case("merges fields over the parent's", function()
		local logger, capture = createTestLogger({ fields = { a = 1, b = 1 } })

		logger.child(nil, { b = 2, c = 3 }).info("hello")

		expect.eq(capture.records[1].fields :: any, { a = 1, b = 2, c = 3 })
	end)

	suite:case("does not leak sinks added to the child back to the parent", function()
		local logger, capture = createTestLogger({})
		local childCapture = createCaptureSink()

		local child = logger.child("child")
		child.addSink(childCapture.sink)
		logger.info("parent only")

		expect.eq(#capture.records, 1)
		expect.eq(#childCapture.records, 0)
	end)
end)
