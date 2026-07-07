--!strict
--[[
	Shared runtime-abstraction types.

	The `Platform` is the seam between the portable core and a concrete runtime
	(Lute or Roblox). Only platform implementations and a few sinks touch runtime
	APIs; everything else in the library depends on this interface, never on
	`@lute/*` or Roblox globals directly.
]]

export type LogLevel = "trace" | "debug" | "info" | "warn" | "err"

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
}

return {}
