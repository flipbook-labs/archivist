-- Lints and format-checks the repo.
-- Run with: lute run lint
local fs = require("@std/fs")
local process = require("@std/process")

local run = require("./lib/run")

local project = require("@repo/project")

run({ "selene", table.unpack(project.FOLDERS_TO_LINT) })

run({ "stylua", "--check", table.unpack(project.FOLDERS_TO_LINT) })

-- Everything must use the .luau extension.
local luaFiles = {}
for _, folder in project.FOLDERS_TO_LINT do
	for path in fs.walk(folder, { recursive = true }) do
		if tostring(path):match("%.lua$") then
			table.insert(luaFiles, tostring(path))
		end
	end
end

if #luaFiles > 0 then
	print("[err] the following file(s) are using the '.lua' extension. Please change to '.luau' and try again")
	print(table.concat(luaFiles, "\n"))
	process.exit(1)
end
