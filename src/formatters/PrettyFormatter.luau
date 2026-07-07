--!strict
--[[
	Human-readable, optionally colored, single-line-per-record formatter:

		12:30:45 [StorytellerStore] [info] loaded storybook Sample.storybook

	Table arguments and attached fields are pretty-printed with the vendored
	`pp` battery so structured data stays legible on a terminal.
]]

local Formatter = require("@root/core/Formatter")
local LogRecord = require("@root/core/LogRecord")
local pp = require("@root/vendor/pp")
local richterm = require("@root/vendor/richterm")
local types = require("@root/platform/types")

export type PrettyFormatterOptions = {
	-- Wrap output in ANSI colors. Callers should gate this on `platform.color`.
	color: boolean?,
	-- Prefix records with a HH:MM:SS wall-clock timestamp. Defaults to true.
	timestamp: boolean?,
}

local LEVEL_COLOR: { [types.LogLevel]: richterm.Formatter } = {
	trace = richterm.gray,
	debug = richterm.cyan,
	info = richterm.green,
	warn = richterm.yellow,
	err = richterm.red,
}

-- Pads the level so message columns line up across records ("err  " vs "trace").
local LEVEL_LABEL: { [types.LogLevel]: string } = {
	trace = "trace",
	debug = "debug",
	info = "info ",
	warn = "warn ",
	err = "err  ",
}

local function stringify(value: any): string
	if type(value) == "table" then
		return pp(value)
	end
	return tostring(value)
end

local function createPrettyFormatter(options: PrettyFormatterOptions?): Formatter.Formatter
	local color = if options and options.color ~= nil then options.color else false
	local withTimestamp = if options and options.timestamp ~= nil then options.timestamp else true

	local function format(record: LogRecord.LogRecord): string
		local parts = {}

		if withTimestamp then
			local clock = os.date("%H:%M:%S", record.timestamp) :: string
			table.insert(parts, if color then richterm.dim(clock) else clock)
		end

		local prefix = `[{record.name}] [{LEVEL_LABEL[record.level]}]`
		table.insert(parts, if color then LEVEL_COLOR[record.level](prefix) else prefix)

		for index = 1, record.args.n do
			table.insert(parts, stringify(record.args[index]))
		end

		if record.fields then
			local rendered = pp(record.fields)
			table.insert(parts, if color then richterm.dim(rendered) else rendered)
		end

		return table.concat(parts, " ")
	end

	return {
		format = format,
	}
end

return createPrettyFormatter
