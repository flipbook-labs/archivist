--[[
	Human-readable, optionally styled, single-line-per-record formatter:

		12:30:45 [StorytellerStore] [info] loaded storybook Sample.storybook

	Styling and value rendering come from the platform: richterm ANSI and the
	pp pretty-printer on Lute, identity styling and JSON rendering on Roblox.
]]

local Formatter = require("@root/core/Formatter")
local LogRecord = require("@root/core/LogRecord")
local types = require("@root/platform/types")

export type PrettyFormatterOptions = {
	-- Apply the platform's console styling. Defaults to `platform.color`; turn
	-- off explicitly when pretty output is headed somewhere ANSI-hostile
	-- (e.g. a file).
	color: boolean?,
	-- Prefix records with a HH:MM:SS wall-clock timestamp. Defaults to true.
	timestamp: boolean?,
}

local function identity(text: string): string
	return text
end

local function createPrettyFormatter(platform: types.Platform, options: PrettyFormatterOptions?): Formatter.Formatter
	local color = if options and options.color ~= nil then options.color else platform.color
	local withTimestamp = if options and options.timestamp ~= nil then options.timestamp else true

	local function style(styler: types.Styler): types.Styler
		return if color then styler else identity
	end

	local function format(record: LogRecord.LogRecord): string
		local parts = {}

		if withTimestamp then
			local clock = os.date("%H:%M:%S", record.timestamp) :: string
			table.insert(parts, style(platform.styles.dim)(clock))
		end

		local prefix = `[{record.name}] [{record.level:lower()}]`
		table.insert(parts, style(platform.styles.levels[record.level])(prefix))

		for index = 1, record.args.n do
			table.insert(parts, platform.inspect(record.args[index]))
		end

		if record.fields then
			table.insert(parts, style(platform.styles.dim)(platform.inspect(record.fields)))
		end

		return table.concat(parts, " ")
	end

	return {
		format = format,
	}
end

return createPrettyFormatter
