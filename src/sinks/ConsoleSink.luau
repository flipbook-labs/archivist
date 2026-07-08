--[[
	Writes records to the runtime's console: stdout on Lute, the Output window
	on Roblox. `trace`/`debug`/`info` go through `platform.write` (print);
	`warn`/`err` go through `platform.warn`.

	Batches are written with one platform call per contiguous run of records on
	the same stream, so a 100-record batch costs a handful of `print`s rather
	than 100 — `print`/`warn` are expensive, which is the whole point of prod
	mode.
]]

local Formatter = require("@root/core/Formatter")
local LogRecord = require("@root/core/LogRecord")
local PrettyFormatter = require("@root/formatters/PrettyFormatter")
local Sink = require("@root/core/Sink")
local types = require("@root/platform/types")

export type ConsoleSinkOptions = {
	-- Defaults to a PrettyFormatter colored per the platform's capability.
	formatter: Formatter.Formatter?,
}

local function isWarnStream(record: LogRecord.LogRecord): boolean
	return record.level == "warn" or record.level == "err"
end

local function createConsoleSink(platform: types.Platform, options: ConsoleSinkOptions?): Sink.Sink
	local formatter = if options and options.formatter then options.formatter else PrettyFormatter(platform)

	local function write(records: { LogRecord.LogRecord })
		local runLines: { string } = {}
		local runIsWarn: boolean? = nil

		local function flushRun()
			if #runLines == 0 then
				return
			end
			local text = table.concat(runLines, "\n")
			if runIsWarn then
				platform.warn(text)
			else
				platform.write(text)
			end
			table.clear(runLines)
		end

		for _, record in records do
			local wantsWarn = isWarnStream(record)
			if runIsWarn ~= nil and wantsWarn ~= runIsWarn then
				flushRun()
			end
			runIsWarn = wantsWarn
			table.insert(runLines, formatter.format(record))
		end

		flushRun()
	end

	return {
		write = write,
	}
end

return createConsoleSink
