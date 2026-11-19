--[[
	A `Formatter` renders a `LogRecord` into a string for text-oriented sinks
	(console, files). Sinks that consume records directly (e.g. CallbackSink)
	don't use one.
]]

local LogRecord = require("./LogRecord")

export type Formatter = {
	format: (record: LogRecord.LogRecord) -> string,
}

return {}
