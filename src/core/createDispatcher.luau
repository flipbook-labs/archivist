--[[
	Routes records from loggers to sinks, implementing the dev/prod deferral
	behavior:

	- dev: each record is written to its sinks synchronously, like `print`.
	- prod: records queue, and one `platform.defer` callback drains the whole
	  queue, so each sink receives every record queued since the last flush in a
	  single `write` call, so expensive outputs (print, file writes) happen once
	  per batch instead of once per record.

	A single dispatcher is shared by every logger so batched records flush in
	global call order. While a batch is pending the dispatcher holds the process
	open via `platform.holdForFlush` (so an interrupt or shutdown flushes the
	queue first) and releases the hold as soon as the queue drains. On Lute
	that release is what lets the process exit naturally.
]]

local LogMode = require("@root/core/LogMode")
local LogRecord = require("@root/core/LogRecord")
local Sink = require("@root/core/Sink")
local types = require("@root/platform/types")

type LogModeT = LogMode.LogMode
type LogRecordT = LogRecord.LogRecord
type SinkT = Sink.Sink

-- Safety valve: a runaway loop logging in prod mode flushes early rather than
-- growing the queue unboundedly.
local MAX_QUEUED_RECORDS = 512

export type Dispatcher = {
	dispatch: (sinks: { SinkT }, record: LogRecordT, mode: LogModeT) -> (),
	flush: () -> (),
}

type QueueEntry = {
	sinks: { SinkT },
	record: LogRecordT,
}

local function createDispatcher(platform: types.Platform): Dispatcher
	local queue: { QueueEntry } = {}
	local flushScheduled = false
	local releaseHold: (() -> ())? = nil

	local function flush()
		flushScheduled = false

		if #queue > 0 then
			local draining = queue
			queue = {}

			-- Group the drained records per sink, preserving call order, so each
			-- sink gets exactly one `write` for the whole batch.
			local sinkBatches: { [SinkT]: { LogRecordT } } = {}
			local sinkOrder: { SinkT } = {}

			for _, entry in draining do
				for _, sink in entry.sinks do
					local batch = sinkBatches[sink]
					if not batch then
						batch = {}
						sinkBatches[sink] = batch
						table.insert(sinkOrder, sink)
					end
					table.insert(batch, entry.record)
				end
			end

			for _, sink in sinkOrder do
				sink.write(sinkBatches[sink])
			end
		end

		-- Release the hold only after every sink has been written. On Lute the
		-- hold is the live SIGINT/SIGTERM handles, so keeping them open across the
		-- write phase means an interrupt mid-flush still drains the batch instead
		-- of dropping it.
		if releaseHold then
			local release = releaseHold
			releaseHold = nil
			release()
		end
	end

	local function dispatch(sinks: { SinkT }, record: LogRecordT, mode: LogModeT)
		if mode == LogMode.Dev then
			for _, sink in sinks do
				sink.write({ record })
			end
			return
		end

		-- Snapshot the sink list: dev mode iterates it now, so prod must capture
		-- it now too. Otherwise an addSink/removeSink before the deferred flush
		-- would reroute records already queued against the old set.
		table.insert(queue, { sinks = table.clone(sinks), record = record })

		if not releaseHold then
			releaseHold = platform.holdForFlush(flush)
		end

		if #queue >= MAX_QUEUED_RECORDS then
			flush()
		elseif not flushScheduled then
			flushScheduled = true
			platform.defer(flush)
		end
	end

	return {
		dispatch = dispatch,
		flush = flush,
	}
end

return createDispatcher
