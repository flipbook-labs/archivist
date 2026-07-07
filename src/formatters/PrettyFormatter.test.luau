local expect = require("@std/test/assert")
local test = require("@std/test")

local LogRecord = require("@root/core/LogRecord")
local PrettyFormatter = require("@root/formatters/PrettyFormatter")

local function record(overrides: {
	level: ("trace" | "debug" | "info" | "warn" | "err")?,
	args: LogRecord.PackedArgs?,
	fields: { [string]: any }?,
}): LogRecord.LogRecord
	return {
		timestamp = 1750000000,
		level = overrides.level or "info",
		name = "test",
		args = overrides.args or table.pack("hello"),
		fields = overrides.fields,
	}
end

test.suite("PrettyFormatter", function(suite)
	suite:case("renders name, level, and message", function()
		local formatter = PrettyFormatter({ timestamp = false })

		expect.eq(formatter.format(record({})), "[test] [info ] hello")
	end)

	suite:case("prefixes a HH:MM:SS timestamp by default", function()
		local formatter = PrettyFormatter()

		local line = formatter.format(record({}))

		expect.that(string.find(line, "^%d%d:%d%d:%d%d %[test%]") ~= nil, line)
	end)

	suite:case("joins varargs with spaces, including non-strings", function()
		local formatter = PrettyFormatter({ timestamp = false })

		local line = formatter.format(record({ args = table.pack("loaded", 3, true) }))

		expect.eq(line, "[test] [info ] loaded 3 true")
	end)

	suite:case("renders nil arguments explicitly", function()
		local formatter = PrettyFormatter({ timestamp = false })

		local line = formatter.format(record({ args = table.pack("value:", nil) }))

		expect.eq(line, "[test] [info ] value: nil")
	end)

	suite:case("pretty-prints table arguments", function()
		local formatter = PrettyFormatter({ timestamp = false })

		local line = formatter.format(record({ args = table.pack({ port = 8080 }) }))

		expect.strContains(line, "port = 8080")
	end)

	suite:case("appends fields after the message", function()
		local formatter = PrettyFormatter({ timestamp = false })

		local line = formatter.format(record({ fields = { requestId = "abc" } }))

		expect.strContains(line, 'requestId = "abc"')
	end)

	suite:case("emits ANSI codes only when color is on", function()
		local plain = PrettyFormatter({ timestamp = false })
		local colored = PrettyFormatter({ timestamp = false, color = true })

		-- selene: allow(bad_string_escape) -- \x is valid Luau; selene lags here (same as vendor/richterm)
		expect.never.strContains(plain.format(record({})), "\x1b[")
		-- selene: allow(bad_string_escape)
		expect.strContains(colored.format(record({ level = "err" })), "\x1b[31m")
	end)
end)
