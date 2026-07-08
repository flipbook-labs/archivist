local expect = require("@std/test/assert")
local json = require("@std/json")
local test = require("@std/test")

local JsonFormatter = require("@root/formatters/JsonFormatter")
local LogRecord = require("@root/core/LogRecord")
local createFakePlatform = require("@root/testing/createFakePlatform")

local function record(overrides: {
	args: LogRecord.PackedArgs?,
	fields: { [string]: any }?,
}): LogRecord.LogRecord
	return {
		timestamp = 1750000000,
		level = "info",
		name = "test",
		args = overrides.args or table.pack("hello"),
		fields = overrides.fields,
	}
end

test.suite("JsonFormatter", function(suite)
	suite:case("emits one parseable JSON object with the record's core fields", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform)

		local decoded = json.deserialize(formatter.format(record({}))) :: any

		expect.eq(decoded.timestamp, 1750000000)
		expect.eq(decoded.level, "info")
		expect.eq(decoded.name, "test")
		expect.eq(decoded.message, "hello")
	end)

	suite:case("joins varargs into the message", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform)

		local decoded = json.deserialize(formatter.format(record({
			args = table.pack("loaded", 3, "stories"),
		}))) :: any

		expect.eq(decoded.message, "loaded 3 stories")
	end)

	suite:case("carries structured args when any argument is not a string", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform)

		local decoded = json.deserialize(formatter.format(record({
			args = table.pack("status:", { code = 500 }),
		}))) :: any

		expect.eq(decoded.args[1], "status:")
		expect.eq(decoded.args[2].code, 500)
	end)

	suite:case("omits args when every argument is a plain string", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform)

		local decoded = json.deserialize(formatter.format(record({
			args = table.pack("all", "strings"),
		}))) :: any

		expect.eq(decoded.args, nil)
	end)

	suite:case("omits args when structuredArgs is off", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform, { structuredArgs = false })

		local decoded = json.deserialize(formatter.format(record({
			args = table.pack("n:", 42),
		}))) :: any

		expect.eq(decoded.args, nil)
		expect.eq(decoded.message, "n: 42")
	end)

	suite:case("carries fields", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform)

		local decoded = json.deserialize(formatter.format(record({
			fields = { requestId = "abc" },
		}))) :: any

		expect.eq(decoded.fields.requestId, "abc")
	end)

	suite:case("falls back to a stringified payload when encoding fails", function()
		local fake = createFakePlatform()
		local formatter = JsonFormatter(fake.platform)

		-- Functions aren't JSON-encodable, so the first encode attempt throws.
		local decoded = json.deserialize(formatter.format(record({
			args = table.pack("callback:", print),
		}))) :: any

		expect.eq(decoded.encodeError, true)
		expect.eq(decoded.level, "info")
		expect.strContains(decoded.message, "callback:")
	end)
end)
