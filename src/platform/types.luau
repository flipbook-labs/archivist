--[[
	Shared runtime-abstraction types.

	The `Platform` is the seam between the portable core and a concrete runtime
	(Lute or Roblox). Only platform implementations and a few sinks touch runtime
	APIs; everything else in the library depends on this interface, never on
	`@lute/*` or Roblox globals directly.
]]

export type LogLevel = "trace" | "debug" | "info" | "warn" | "err"

-- A handle to a file opened for appending; see `Platform.openAppendable`.
export type AppendHandle = {
	append: (text: string) -> (),
	close: () -> (),
}

export type Platform = {
	-- Writes a line to standard output (Lute `io.write` / Roblox `print`).
	write: (line: string) -> (),
	-- Writes a line to the warning stream (Lute stderr-ish / Roblox `warn`).
	warn: (line: string) -> (),
	-- Wall-clock time in whole seconds since the Unix epoch.
	now: () -> number,
	-- Reads an environment variable; always `nil` on Roblox.
	getEnv: (key: string) -> string?,
	-- Whether ANSI colour codes are meaningful on this runtime's output.
	color: boolean,
	-- Schedules `callback` to run soon, after the current execution finishes
	-- (Lute/Roblox `task.defer`). Used to coalesce batched log writes.
	defer: (callback: () -> ()) -> (),
	-- Called while batched records are pending: `flush` must run if the process
	-- is about to terminate (interrupt, shutdown). Returns a release function
	-- the caller invokes once the pending batch has drained. On Lute the
	-- registered signal handles hold the event loop open, so releasing promptly
	-- is what lets the process exit naturally.
	holdForFlush: (flush: () -> ()) -> () -> (),
	-- Opens `path` for appending (creating it if absent). Absent on runtimes
	-- with no filesystem (Roblox) — capability-probe before use.
	openAppendable: ((path: string) -> AppendHandle)?,
}

return {}
