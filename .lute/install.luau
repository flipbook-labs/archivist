-- Installs everything a fresh checkout needs, so contributors and agents run one
-- command instead of remembering the toolchain's three separate install steps:
--
--   1. `lute pkg install` -- Loom (Lute) dependencies from loom.config.luau into
--      ~/.loom/store, including the AgentSkills library agents route to.
--   2. `wally install`     -- Roblox dependencies from wally.toml into Packages.
--      A no-op while wally.toml declares none, but kept so adding a dependency
--      later needs no change here.
--   3. `lute setup`        -- regenerate the Lute type definitions luau-lsp reads
--      (the paths .luaurc aliases as @lute/* and @std/*).
--
-- Run with: lute run install
local process = require("@lute/process")

local function run(args: { string })
	local result = process.run(args, { stdio = "inherit" })
	if not result.ok then
		error(`command failed (exit {result.exitcode}): {table.concat(args, " ")}`)
	end
end

print("installing Loom dependencies (lute pkg install)...")
run({ "lute", "pkg", "install" })

print("installing Wally dependencies (wally install)...")
run({ "wally", "install" })

print("generating Lute type definitions (lute setup)...")
run({ "lute", "setup" })

print("install complete")
