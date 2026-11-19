local expect = require("@std/test/assert")
local test = require("@std/test")

local LogLevel = require("../core/LogLevel")
local createFakePlatform = require("../testing/createFakePlatform")
local createPrettyFormatter = require("./createPrettyFormatter")
local nameMiddleware = require("./nameMiddleware")

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
