--!strict
--[[
	Machine-readable, one-JSON-object-per-line formatter for file sinks and
	transports:

		{"level":"info","message":"loaded 3 stories","name":"MyModule","timestamp":1750000000}

	`message` is the log call's arguments stringified and joined (the way a
	human would read them); `args` additionally carries any non-string
	arguments structurally when present, so transports don't lose data to
	stringification. `fields` carries the logger's structured context.
]]

local Formatter = require("@root/core/Formatter")
local LogRecord = require("@root/core/LogRecord")
local encodeJson = require("@root/formatters/encodeJson")

export type JsonFormatterOptions = {
	-- Include the raw args array alongside the joined message when any
	-- argument is not a plain string. Defaults to true.
	structuredArgs: boolean?,
}

local function createJsonFormatter(options: JsonFormatterOptions?): Formatter.Formatter
	local structuredArgs = if options and options.structuredArgs ~= nil then options.structuredArgs else true

	local function format(record: LogRecord.LogRecord): string
		local messageParts = table.create(record.args.n)
		local hasNonString = false
		for index = 1, record.args.n do
			local arg = record.args[index]
			if type(arg) ~= "string" then
				hasNonString = true
			end
			messageParts[index] = tostring(arg)
		end

		local payload: { [string]: any } = {
			timestamp = record.timestamp,
			level = record.level,
			name = record.name,
			message = table.concat(messageParts, " "),
		}

		if structuredArgs and hasNonString then
			-- table.pack tables carry `n`; strip it so args encode as a JSON array.
			local args = table.create(record.args.n)
			for index = 1, record.args.n do
				args[index] = record.args[index]
			end
			payload.args = args
		end

		if record.fields then
			payload.fields = record.fields
		end

		return encodeJson(payload)
	end

	return {
		format = format,
	}
end

return createJsonFormatter
