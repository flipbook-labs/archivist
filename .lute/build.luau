-- Builds the Roblox distribution.
--
-- darklua locates each file in the Roblox tree by looking its own path up in the
-- sourcemap, so the sourcemap and the processed tree must be the same (`src`).
-- We therefore transpile `src` as-is and then post-process `dist` to realise the
-- platform seam: drop the Lute-only module and point `platform/init` at the
-- Roblox implementation. darklua warns about the unresolved `@lute/*` requires in
-- `platform/lute.luau` while processing; that file is deleted immediately after,
-- so nothing broken reaches the shipped model.
--
--   src ──darklua──▶ dist ──(swap seam, drop lute)──▶ rojo ──▶ Archivist.rbxm
--
-- Run with: lute run build
local fs = require("@lute/fs")
local process = require("@lute/process")

local function run(args: { string })
	local result = process.run(args, { stdio = "inherit" })
	if not result.ok then
		error(`command failed (exit {result.exitcode}): {table.concat(args, " ")}`)
	end
end

local function writeFile(path: string, contents: string)
	local handle = fs.open(path, "w")
	fs.write(handle, contents)
	fs.close(handle)
end

-- 1. Clean previous artefacts.
run({ "rm", "-rf", "dist" })

-- 2. Sourcemap + transpile the real source tree (so `@root` and file locations
--    resolve consistently).
run({ "rojo", "sourcemap", "build.project.json", "-o", "sourcemap-darklua.json" })
run({ "darklua", "process", "src", "dist" })

-- 3. Realise the platform seam for Roblox. Post-darklua the tree uses Roblox
--    require syntax, so the swapped seam references its sibling directly.
run({ "rm", "-f", "dist/platform/lute.luau" })

-- Tests and test helpers don't ship in the Roblox package.
run({ "sh", "-c", "find dist -name '*.test.luau' -delete" })
run({ "rm", "-rf", "dist/testing" })
writeFile(
	"dist/platform/init.luau",
	"-- Roblox build: the platform seam resolves to the Roblox implementation.\nreturn require(script.roblox)\n"
)

-- 4. Package the Roblox model.
run({ "rojo", "build", "default.project.json", "-o", "Archivist.rbxm" })

print("built Archivist.rbxm")
