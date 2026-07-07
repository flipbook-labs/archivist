--!strict
--[[
	The structured object every log call produces.

	Sinks and formatters consume records; nothing in the pipeline works on bare
	strings until a formatter renders one.
]]

local types = require("@root/platform/types")

-- The result of `table.pack(...)`: the log call's arguments plus their count
-- (`n` matters because the varargs may contain nils).
export type PackedArgs = { n: number, [number]: any }

export type LogRecord = {
	-- Wall-clock seconds since the Unix epoch, captured at the call site.
	timestamp: number,
	level: types.LogLevel,
	-- The logger's name, e.g. "StorytellerStore". Child loggers join names with
	-- "/", e.g. "flipbook/settings".
	name: string,
	-- The arguments passed to the log call, un-stringified.
	args: PackedArgs,
	-- Structured context attached via `logger.child`; nil when none.
	fields: { [string]: any }?,
}

return {}
