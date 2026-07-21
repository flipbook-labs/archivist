local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("@root/core/LogLevel")
local createFakePlatform = require("@root/testing/createFakePlatform")
local createPrettyFormatter = require("@root/formatters/createPrettyFormatter")
local nameMiddleware = require("@root/formatters/nameMiddleware")

test.suite("nameMiddleware", function(suite)
	suite:case("prepends the logger name styled by level", function()
		local fake = createFakePlatform()
		local formatter = createPrettyFormatter(fake.platform, {
			color = true,
			middleware = { nameMiddleware },
		})

		local line = formatter.format({
			timestamp = 1750000000,
			level = LogLevel.Err,
			name = "StorytellerStore",
			args = table.pack("failed"),
		})

		expect.eq(line, "<err>[StorytellerStore]</err> <err>[err]</err> failed")
	end)
end)
