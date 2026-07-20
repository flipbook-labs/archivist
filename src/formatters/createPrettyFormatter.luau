--[[
	Human-readable, optionally styled, single-line-per-record formatter:

		[info] loaded storybook Sample.storybook

	Styling and value rendering come from the platform: richterm ANSI and the
	pp pretty-printer on Lute, identity styling and JSON rendering on Roblox.
]]

local Formatter = require("@root/core/Formatter")
local LogRecord = require("@root/core/LogRecord")
local Middleware = require("@root/formatters/Middleware")
local types = require("@root/platform/types")

export type PrettyFormatterOptions = {
	-- Apply the platform's console styling. Defaults to `platform.color`; turn
	-- off explicitly when pretty output is headed somewhere ANSI-hostile
	-- (e.g. a file).
	color: boolean?,
	middleware: { Middleware.Middleware }?,
}

local function identity(text: string): string
	return text
end

local function createPrettyFormatter(platform: types.Platform, options: PrettyFormatterOptions?): Formatter.Formatter
	local color = if options and options.color ~= nil then options.color else platform.color
	local middleware = if options and options.middleware then options.middleware else {}

	local function style(styler: types.Styler): types.Styler
		return if color then styler else identity
	end

	local function format(record: LogRecord.LogRecord): string
		local parts = {}
		table.insert(parts, style(platform.styles.levels[record.level])(`[{record.level:lower()}]`))

		for index = 1, record.args.n do
			table.insert(parts, platform.inspect(record.args[index]))
		end

		if record.fields then
			table.insert(parts, style(platform.styles.dim)(platform.inspect(record.fields)))
		end

		local line = table.concat(parts, " ")
		local context: Middleware.FormatContext = {
			record = record,
			platform = platform,
			color = color,
			style = style,
		}
		for _, applyMiddleware in middleware do
			line = applyMiddleware(line, context)
		end

		return line
	end

	return {
		format = format,
	}
end

return createPrettyFormatter
