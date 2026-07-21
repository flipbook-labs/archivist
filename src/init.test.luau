local expect = require("@std/test/assert")
local test = require("@std/test")

local Archivist = require("@root")

test.suite("Archivist", function(suite)
	suite:case("applies middleware to the default console sink", function()
		local calls = 0
		local logger = Archivist.createLogger("test", {
			middleware = {
				function(line, context)
					calls += 1
					expect.strContains(line, "[info]")
					expect.strContains(line, "hello")
					expect.eq(context.record.name, "test")
					return line
				end,
			},
		})

		logger.info("hello")

		expect.eq(calls, 1)
	end)
end)
