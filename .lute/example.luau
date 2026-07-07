-- Stage 1 spike runner: proves the library builds a logger and writes through
-- the Lute platform. Run with: lute run example
local Log = require("@repo/src")

local logger = Log.createLogger("spike")

logger.trace("trace is hidden at the default info level")
logger.debug("debug is hidden at the default info level")
logger.info("hello from", "lute", { batched = false })
logger.warn("careful now")
logger.err("something broke")

local verbose = Log.createLogger("verbose", { level = "trace" })
verbose.trace("...but trace shows when the level is lowered")
