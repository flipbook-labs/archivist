--[[
	A `Sink` is an output target for log records.

	`write` always receives a batch: a one-record batch in dev mode, or every
	record queued since the last flush in prod mode. This keeps the contract
	uniform and lets sinks amortise expensive operations (one `print` / one file
	write / one HTTP request per batch rather than per record).
]]

local LogRecord = require("@root/core/LogRecord")

export type Sink = {
	write: (records: { LogRecord.LogRecord }) -> (),
	-- Called when pending output should be persisted (shutdown, manual flush).
	flush: (() -> ())?,
	-- Called when the sink is discarded; release handles here.
	close: (() -> ())?,
}

return {}
