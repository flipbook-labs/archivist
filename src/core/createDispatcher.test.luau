local expect = require("@std/test/assert")
local test = require("@std/test")

local LogRecord = require("@root/core/LogRecord")
local createCaptureSink = require("@root/testing/createCaptureSink")
local createDispatcher = require("@root/core/createDispatcher")
local createFakePlatform = require("@root/testing/createFakePlatform")

local function record(level: "trace" | "debug" | "info" | "warn" | "err", message: any): LogRecord.LogRecord
	return {
		timestamp = 0,
		level = level,
		name = "test",
		args = table.pack(message),
	}
end

test.suite("Dispatcher dev mode", function(suite)
	suite:case("writes each record synchronously as its own batch", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		dispatcher.dispatch({ capture.sink }, record("info", "one"), "dev")
		dispatcher.dispatch({ capture.sink }, record("info", "two"), "dev")

		expect.eq(#capture.batches, 2)
		expect.eq(#capture.batches[1], 1)
		expect.eq(fake.runDeferred(), 0)
	end)
end)

test.suite("Dispatcher prod mode", function(suite)
	suite:case("queues records and delivers one batch per sink on flush", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		dispatcher.dispatch({ capture.sink }, record("info", "one"), "prod")
		dispatcher.dispatch({ capture.sink }, record("info", "two"), "prod")
		dispatcher.dispatch({ capture.sink }, record("info", "three"), "prod")

		-- Nothing written until the deferred flush runs.
		expect.eq(#capture.batches, 0)

		fake.runDeferred()

		expect.eq(#capture.batches, 1)
		expect.eq(#capture.batches[1], 3)
		expect.eq(capture.batches[1][1].args[1], "one")
		expect.eq(capture.batches[1][3].args[1], "three")
	end)

	suite:case("schedules only one deferred flush per batch window", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		for index = 1, 10 do
			dispatcher.dispatch({ capture.sink }, record("info", index), "prod")
		end

		expect.eq(fake.runDeferred(), 1)
	end)

	suite:case("routes multi-sink batches to every sink in call order", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local captureA = createCaptureSink()
		local captureB = createCaptureSink()

		dispatcher.dispatch({ captureA.sink }, record("info", "a-only"), "prod")
		dispatcher.dispatch({ captureA.sink, captureB.sink }, record("info", "both"), "prod")

		fake.runDeferred()

		expect.eq(#captureA.batches[1], 2)
		expect.eq(#captureB.batches[1], 1)
		expect.eq(captureB.batches[1][1].args[1], "both")
	end)

	suite:case("snapshots the sink list at dispatch time, not flush time", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local captureA = createCaptureSink()
		local captureB = createCaptureSink()

		local sinks = { captureA.sink }
		dispatcher.dispatch(sinks, record("info", "queued for A"), "prod")

		-- Mutating the sink list (as addSink/removeSink do) before the deferred
		-- flush must not reroute the already-queued record away from A to B.
		table.remove(sinks, 1)
		table.insert(sinks, captureB.sink)

		fake.runDeferred()

		expect.eq(#captureA.batches, 1)
		expect.eq(captureA.batches[1][1].args[1], "queued for A")
		expect.eq(#captureB.batches, 0)
	end)

	suite:case("manual flush drains the queue immediately", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		dispatcher.dispatch({ capture.sink }, record("info", "one"), "prod")
		dispatcher.flush()

		expect.eq(#capture.batches, 1)

		-- The already-scheduled deferred flush finds an empty queue and is a no-op.
		fake.runDeferred()
		expect.eq(#capture.batches, 1)
	end)

	suite:case("holds the process open while a batch is pending", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		dispatcher.dispatch({ capture.sink }, record("info", "pending"), "prod")

		-- Held but not yet released: an interrupt here must flush.
		expect.eq(#fake.holds, 1)
		expect.eq(fake.releasedCount(), 0)

		fake.holds[1]()
		expect.eq(#capture.batches, 1)
	end)

	suite:case("releases the hold once the queue drains", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		dispatcher.dispatch({ capture.sink }, record("info", "one"), "prod")
		fake.runDeferred()

		expect.eq(fake.releasedCount(), 1)

		-- The next batch takes (and later releases) a fresh hold.
		dispatcher.dispatch({ capture.sink }, record("info", "two"), "prod")
		expect.eq(#fake.holds, 2)
		fake.runDeferred()
		expect.eq(fake.releasedCount(), 2)
	end)

	suite:case("flushes early when the queue hits the safety cap", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local capture = createCaptureSink()

		for index = 1, 512 do
			dispatcher.dispatch({ capture.sink }, record("info", index), "prod")
		end

		-- The 512th dispatch tripped the cap and flushed synchronously.
		expect.eq(#capture.batches, 1)
		expect.eq(#capture.batches[1], 512)
	end)
end)
