-- Demo script: exercises the public API under Lute.
-- Run with: lute run example
-- Try: LOG_LEVEL=trace lute run example
local Archivist = require("@repo/src")

local logger = Archivist.createLogger("example")

logger.trace("trace is hidden at the default info level")
logger.debug("debug is hidden at the default info level")
logger.info("hello from lute")
logger.info("structured data:", { port = 8080, ready = true })
logger.warn("careful now")
logger.err("something broke")

local child = logger.child("child", { requestId = "abc123" })
child.info("children inherit sinks and carry fields")

-- Prod mode: these three records queue and flush as ONE batched write after
-- the script yields (or at exit), instead of three separate prints.
local batched = Archivist.createLogger("batched", { mode = "Prod" })
batched.info("queued 1")
batched.info("queued 2")
batched.info("queued 3")

local verbose = Archivist.createLogger("verbose", { level = "Trace" })
verbose.trace("...but trace shows when the level is lowered")
