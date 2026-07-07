local expect = require("@std/test/assert")
local json = require("@std/json")
local test = require("@std/test")

local encodeJson = require("@root/formatters/encodeJson")

test.suite("encodeJson primitives", function(suite)
	suite:case("encodes scalars", function()
		expect.eq(encodeJson(nil), "null")
		expect.eq(encodeJson(true), "true")
		expect.eq(encodeJson(false), "false")
		expect.eq(encodeJson(42), "42")
		expect.eq(encodeJson(-1.5), "-1.5")
		expect.eq(encodeJson("hello"), '"hello"')
	end)

	suite:case("escapes strings", function()
		expect.eq(encodeJson('say "hi"'), '"say \\"hi\\""')
		expect.eq(encodeJson("back\\slash"), '"back\\\\slash"')
		expect.eq(encodeJson("line\nbreak\ttab"), '"line\\nbreak\\ttab"')
		expect.eq(encodeJson("bell\7"), '"bell\\u0007"')
	end)

	suite:case("encodes non-finite numbers as null", function()
		expect.eq(encodeJson(0 / 0), "null")
		expect.eq(encodeJson(math.huge), "null")
		expect.eq(encodeJson(-math.huge), "null")
	end)

	suite:case("represents unencodable values as strings", function()
		local encoded = encodeJson(print)
		expect.strContains(encoded, "function")
	end)
end)

test.suite("encodeJson tables", function(suite)
	suite:case("encodes contiguous integer-keyed tables as arrays", function()
		expect.eq(encodeJson({ 1, 2, 3 }), "[1,2,3]")
		expect.eq(encodeJson({ "a", "b" }), '["a","b"]')
		expect.eq(encodeJson({}), "{}")
	end)

	suite:case("encodes keyed tables as objects with sorted keys", function()
		expect.eq(encodeJson({ b = 2, a = 1 }), '{"a":1,"b":2}')
	end)

	suite:case("stringifies non-string keys", function()
		expect.eq(encodeJson({ [1] = "x", name = "y" }), '{"1":"x","name":"y"}')
	end)

	suite:case("encodes nested structures", function()
		local encoded = encodeJson({ user = { id = 7, tags = { "a", "b" } } })
		expect.eq(encoded, '{"user":{"id":7,"tags":["a","b"]}}')
	end)

	suite:case("replaces cycles instead of hanging", function()
		local t: { [string]: any } = { name = "loop" }
		t.self = t

		expect.eq(encodeJson(t), '{"name":"loop","self":"<cycle>"}')
	end)

	suite:case("allows the same table twice when not cyclic", function()
		local shared = { x = 1 }
		local encoded = encodeJson({ a = shared, b = shared })

		expect.eq(encoded, '{"a":{"x":1},"b":{"x":1}}')
	end)

	suite:case("round-trips through a real JSON parser", function()
		local original = {
			message = 'quo"ted\n',
			count = 3,
			flags = { true, false },
			nested = { deep = { -1.25 } },
		}

		local decoded = json.deserialize(encodeJson(original)) :: any

		expect.eq(decoded.message, 'quo"ted\n')
		expect.eq(decoded.count, 3)
		expect.eq(decoded.flags[1], true)
		expect.eq(decoded.flags[2], false)
		expect.eq(decoded.nested.deep[1], -1.25)
	end)
end)
