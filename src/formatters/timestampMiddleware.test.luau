local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local createFakePlatform = require("@root/testing/createFakePlatform")
local createPrettyFormatter = require("@root/formatters/createPrettyFormatter")
local timestampMiddleware = require("@root/formatters/timestampMiddleware")

test.suite("timestampMiddleware", function(suite)
	suite:case("prepends a dimmed wall-clock timestamp", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, {
			color = true,
			middleware = { timestampMiddleware },
		})

		local line = formatter.format({
			timestamp = 1750000000,
			level = LogLevel.Info,
			name = "test",
			args = table.pack("hello"),
		})

		expect.that(line:find("^<dim>%d%d:%d%d:%d%d</dim> <info>%[info%]</info> hello$") ~= nil, line)
	end)
end)
