local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local LogRecord = require("@root/core/LogRecord")
local createFakePlatform = require("@root/testing/createFakePlatform")
local createPrettyFormatter = require("@root/formatters/createPrettyFormatter")

local function record(overrides: {
	level: LogLevel.LogLevel?,
	args: LogRecord.PackedArgs?,
	fields: { [string]: any }?,
}): LogRecord.LogRecord
	return {
		timestamp = 1750000000,
		level = overrides.level or LogLevel.Info,
		name = "test",
		args = overrides.args or table.pack("hello"),
		fields = overrides.fields,
	}
end

test.suite("PrettyFormatter", function(suite)
	suite:case("renders name, level, and message", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, { timestamp = false })

		expect.eq(formatter.format(record({})), "[test] [info] hello")
	end)

	suite:case("prefixes a HH:MM:SS timestamp by default", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform)

		local line = formatter.format(record({}))

		expect.that(string.find(line, "^%d%d:%d%d:%d%d %[test%]") ~= nil, line)
	end)

	suite:case("joins varargs with spaces, including non-strings", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, { timestamp = false })

		local line = formatter.format(record({ args = table.pack("loaded", 3, true) }))

		expect.eq(line, "[test] [info] loaded 3 true")
	end)

	suite:case("renders nil arguments explicitly", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, { timestamp = false })

		local line = formatter.format(record({ args = table.pack("value:", nil) }))

		expect.eq(line, "[test] [info] value: nil")
	end)

	suite:case("pretty-prints table arguments via the platform", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, { timestamp = false })

		local line = formatter.format(record({ args = table.pack({ port = 8080 }) }))

		expect.strContains(line, "port = 8080")
	end)

	suite:case("appends fields after the message", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, { timestamp = false })

		local line = formatter.format(record({ fields = { requestId = "abc" } }))

		expect.strContains(line, 'requestId = "abc"')
	end)

	suite:case("styles by level only when color is on", function()
		local fake = createFakePlatform()
		local plain = createPrettyFormatter(fake.platform, { timestamp = false })
		local colored = createPrettyFormatter(fake.platform, { timestamp = false, color = true })

		-- The fake platform's color is false, so styling defaults off.
		expect.never.strContains(plain.format(record({})), "<info>")
		expect.strContains(colored.format(record({ level = LogLevel.Err })), "<err>[test] [err]</err>")
	end)

	suite:case("dims the timestamp and fields when color is on", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, { color = true })

		local line = formatter.format(record({ fields = { a = 1 } }))

		expect.that(string.find(line, "^<dim>%d%d:%d%d:%d%d</dim>") ~= nil, line)
		expect.strContains(line, "<dim>{")
	end)
end)
