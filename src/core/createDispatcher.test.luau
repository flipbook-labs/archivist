local expect = require("@std/test/assert")
local test = require("@std/test")

local LogRecord = require("@root/core/LogRecord")
local createDispatcher = require("@root/core/createDispatcher")
local createFakePlatform = require("@root/testing/createFakePlatform")

local function record(level, message): LogRecord.LogRecord
	return {
		timestamp = 0,
		level = level,
		name = "test",
		args = table.pack(message),
	}
end

local function createCaptureSink()
	local batches = {}
	return {
		write = function(batch)
			table.insert(batches, batch)
		end,
		batches = batches,
	}
end

test.suite("Dispatcher dev mode", function(suite)
	suite:case("writes each record synchronously as its own batch", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		dispatcher.dispatch({ sink }, record("info", "one"), "dev")
		dispatcher.dispatch({ sink }, record("info", "two"), "dev")

		expect.eq(#sink.batches, 2)
		expect.eq(#sink.batches[1], 1)
		expect.eq(fake.runDeferred(), 0)
	end)
end)

test.suite("Dispatcher prod mode", function(suite)
	suite:case("queues records and delivers one batch per sink on flush", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		dispatcher.dispatch({ sink }, record("info", "one"), "prod")
		dispatcher.dispatch({ sink }, record("info", "two"), "prod")
		dispatcher.dispatch({ sink }, record("info", "three"), "prod")

		-- Nothing written until the deferred flush runs.
		expect.eq(#sink.batches, 0)

		fake.runDeferred()

		expect.eq(#sink.batches, 1)
		expect.eq(#sink.batches[1], 3)
		expect.eq(sink.batches[1][1].args[1], "one")
		expect.eq(sink.batches[1][3].args[1], "three")
	end)

	suite:case("schedules only one deferred flush per batch window", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		for index = 1, 10 do
			dispatcher.dispatch({ sink }, record("info", index), "prod")
		end

		expect.eq(fake.runDeferred(), 1)
	end)

	suite:case("routes multi-sink batches to every sink in call order", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sinkA = createCaptureSink()
		local sinkB = createCaptureSink()

		dispatcher.dispatch({ sinkA }, record("info", "a-only"), "prod")
		dispatcher.dispatch({ sinkA, sinkB }, record("info", "both"), "prod")

		fake.runDeferred()

		expect.eq(#sinkA.batches[1], 2)
		expect.eq(#sinkB.batches[1], 1)
		expect.eq(sinkB.batches[1][1].args[1], "both")
	end)

	suite:case("manual flush drains the queue immediately", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		dispatcher.dispatch({ sink }, record("info", "one"), "prod")
		dispatcher.flush()

		expect.eq(#sink.batches, 1)

		-- The already-scheduled deferred flush finds an empty queue and is a no-op.
		fake.runDeferred()
		expect.eq(#sink.batches, 1)
	end)

	suite:case("holds the process open while a batch is pending", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		dispatcher.dispatch({ sink }, record("info", "pending"), "prod")

		-- Held but not yet released: an interrupt here must flush.
		expect.eq(#fake.holds, 1)
		expect.eq(fake.releasedCount(), 0)

		fake.holds[1]()
		expect.eq(#sink.batches, 1)
	end)

	suite:case("releases the hold once the queue drains", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		dispatcher.dispatch({ sink }, record("info", "one"), "prod")
		fake.runDeferred()

		expect.eq(fake.releasedCount(), 1)

		-- The next batch takes (and later releases) a fresh hold.
		dispatcher.dispatch({ sink }, record("info", "two"), "prod")
		expect.eq(#fake.holds, 2)
		fake.runDeferred()
		expect.eq(fake.releasedCount(), 2)
	end)

	suite:case("flushes early when the queue hits the safety cap", function()
		local fake = createFakePlatform()
		local dispatcher = createDispatcher(fake.platform)
		local sink = createCaptureSink()

		for index = 1, 512 do
			dispatcher.dispatch({ sink }, record("info", index), "prod")
		end

		-- The 512th dispatch tripped the cap and flushed synchronously.
		expect.eq(#sink.batches, 1)
		expect.eq(#sink.batches[1], 512)
	end)
end)
