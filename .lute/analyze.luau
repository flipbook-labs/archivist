-- Type-checks both flavors of the library with luau-lsp:
--
-- 1. Lute flavor: `src` and `.lute` against Lute's typedefs. Skips
--    `platform/roblox.luau`, which uses Roblox globals that only exist in the
--    other flavor.
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

run({
	"curl",
	"-sSf",
	"-o",
	globalDefsPath,
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua",
})

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
