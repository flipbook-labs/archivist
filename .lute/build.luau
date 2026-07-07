-- Builds the Roblox distribution.
--
-- darklua locates each file in the Roblox tree by looking its own path up in the
-- sourcemap, so the sourcemap and the processed tree must be the same (`src`).
-- We therefore transpile `src` as-is and then post-process `dist` to realise the
-- platform seam: drop the Lute-only module and point `platform/init` at the
-- Roblox implementation. darklua warns about the unresolved `@std/*` requires in
-- `platform/lute.luau` while processing; that file is deleted immediately after,
-- so nothing broken reaches the shipped model.
--
--   src ──darklua──▶ dist ──(swap seam, drop lute, drop tests)──▶ rojo ──▶ Archivist.rbxm
--
-- Run with: lute run build
local fs = require("@std/fs")

local run = require("./lib/run")

local project = require("@repo/project")

-- 1. Clean previous artefacts.
if fs.exists(project.BUILD_PATH) then
	fs.removeDirectory(project.BUILD_PATH, { recursive = true })
end

-- 2. Sourcemap + transpile the real source tree (so `@root` and file locations
--    resolve consistently).
run({ "rojo", "sourcemap", project.ROJO_BUILD_PROJECT, "-o", project.DARKLUA_SOURCEMAP_PATH })
run({ "darklua", "process", project.SOURCE_PATH, project.BUILD_PATH })

-- 3. Realise the platform seam for Roblox. Post-darklua the tree uses Roblox
--    require syntax, so the swapped seam references its sibling directly.
fs.remove(`{project.BUILD_PATH}/platform/lute.luau`)
fs.writeStringToFile(
	`{project.BUILD_PATH}/platform/init.luau`,
	"-- Roblox build: the platform seam resolves to the Roblox implementation.\nreturn require(script.roblox)\n"
)

-- 4. Tests and test helpers don't ship in the Roblox package.
for path in fs.walk(project.BUILD_PATH, { recursive = true }) do
	if tostring(path):match("%.test%.luau$") then
		fs.remove(path)
	end
end
fs.removeDirectory(`{project.BUILD_PATH}/testing`, { recursive = true })

-- 5. Package the Roblox model.
run({ "rojo", "build", "default.project.json", "-o", project.MODEL_FILENAME })

print(`built {project.MODEL_FILENAME}`)
