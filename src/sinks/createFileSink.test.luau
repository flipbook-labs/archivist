local expect = require("@std/test/assert")
local fs = require("@std/fs")
local path = require("@std/path")
local system = require("@std/system")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local LogRecord = require("@root/core/LogRecord")
local createFakePlatform = require("@root/testing/createFakePlatform")
local createFileSink = require("@root/sinks/createFileSink")
local lutePlatform = require("@root/platform/lute")

local function record(message: string): LogRecord.LogRecord
	return {
		timestamp = 1750000000,
		level = LogLevel.Info,
		name = "test",
		args = table.pack(message),
	}
end

test.suite("FileSink", function(suite)
	suite:case("appends one line per record with a single write per batch", function()
		local fake = createFakePlatform()
		local sink = createFileSink(fake.platform, { path = "app.log" })

		sink.write({ record("one"), record("two") })

		local chunks = fake.files["app.log"]
		expect.eq(#chunks, 1)
		local _, lineBreaks = chunks[1]:gsub("\n", "")
		expect.eq(lineBreaks, 2)
	end)

	suite:case("uses the JsonFormatter by default", function()
		local fake = createFakePlatform()
		local sink = createFileSink(fake.platform, { path = "app.log" })

		sink.write({ record("hello") })

		expect.strContains(fake.files["app.log"][1], '"message":"hello"')
	end)

	suite:case("keeps the file open across batches and closes on close", function()
		local fake = createFakePlatform()
		local sink = createFileSink(fake.platform, { path = "app.log" })

		sink.write({ record("one") })
		sink.write({ record("two") })

		expect.eq(fake.closedFiles["app.log"], nil)
		assert(sink.close, "FileSink should expose close")
		sink.close()
		expect.eq(fake.closedFiles["app.log"], true)
	end)

	suite:case("errors on runtimes without a filesystem", function()
		local fake = createFakePlatform()
		fake.platform.openAppendable = nil

		expect.throws(function()
			createFileSink(fake.platform, { path = "app.log" })
		end)
	end)

	suite:case("writes a real file on Lute", function()
		local logPath = tostring(path.join(system.tmpdir(), `archivist-filesink-test-{os.clock()}.log`))
		local sink = createFileSink(lutePlatform, { path = logPath })

		sink.write({ record("first"), record("second") })
		sink.write({ record("third") })
		assert(sink.close, "FileSink should expose close")
		sink.close()

		local contents = fs.readFileToString(logPath)
		fs.remove(logPath)

		local lines = contents:split("\n")
		expect.eq(lines[1] ~= "", true)
		expect.strContains(lines[1], '"message":"first"')
		expect.strContains(lines[2], '"message":"second"')
		expect.strContains(lines[3], '"message":"third"')
	end)
end)
