local LogRecord = require("../core/LogRecord")
local types = require("../platform/types")

export type FormatContext = {
	record: LogRecord.LogRecord,
	platform: types.Platform,
	color: boolean,
	style: (types.Styler) -> types.Styler,
}

export type Middleware = (string, FormatContext) -> string

return {}
