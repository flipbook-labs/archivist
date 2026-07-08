-- Runs an external tool, inheriting stdio, and exits the script with the
-- tool's exit code on failure.
local process = require("@std/process")

local function run(args: { string })
	local result = process.run(args, { stdio = "inherit" })
	if not result.ok then
		print(`command failed (exit {result.exitcode}): {table.concat(args, " ")}`)
		process.exit(if result.exitcode ~= 0 then result.exitcode else 1)
	end
end

return run
