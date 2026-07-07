-- Type-checks both flavors of the library with luau-lsp:
--
-- 1. Lute flavor: `src` and `.lute` against Lute's typedefs, skipping the
--    Roblox-only platform implementation.
-- 2. Roblox flavor: the built `dist` tree against Roblox global types, with a
--    rojo sourcemap for require resolution. Requires `lute run build` first.
--
-- Run with: lute run analyze
local fs = require("@std/fs")
local path = require("@std/path")
local system = require("@std/system")

local run = require("./lib/run")

local project = require("@repo/project")

local globalDefsPath = tostring(path.join(system.tmpdir(), "globalTypes.d.luau"))

-- Keep the ref in sync with the luau-lsp version pinned in rokit.toml.
local LUAU_LSP_VERSION = "1.68.1"

run({
	"curl",
	"-sSf",
	"-o",
	globalDefsPath,
	`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{LUAU_LSP_VERSION}/scripts/globalTypes.d.lua`,
})

-- Lute flavor: everything except the Roblox platform implementation. The
-- vendored batteries are upstream code and analyzed upstream.
run({
	"luau-lsp",
	"analyze",
	"--platform=standard",
	"--flag:LuauSolverV2=true",
	"--settings=./.vscode/settings.json",
	"--ignore",
	"**/platform/roblox.luau",
	"--ignore",
	"**/vendor/**",
	project.SOURCE_PATH,
	project.SCRIPTS_PATH,
})

-- Roblox flavor: the built tree (which has the Roblox platform swapped in and
-- the Lute one removed).
if not fs.exists(project.BUILD_PATH) then
	print(`[err] {project.BUILD_PATH} does not exist; run 'lute run build' first`)
	fs.remove(globalDefsPath)
	error("missing build")
end

run({ "rojo", "sourcemap", "default.project.json", "-o", project.SOURCEMAP_PATH })

run({
	"luau-lsp",
	"analyze",
	`--defs={globalDefsPath}`,
	`--sourcemap={project.SOURCEMAP_PATH}`,
	"--flag:LuauSolverV2=true",
	"--settings=./.vscode/settings.json",
	"--ignore",
	"**/vendor/**",
	project.BUILD_PATH,
})

print("analysis passed for both flavors")
