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

-- A Lute-only require that leaks into the shipped Roblox tree errors the
-- moment Roblox loads the module, and test files bloat every consumer's
-- install. These checks need a build to inspect, so CI builds before linting.
if fs.exists(project.BUILD_PATH) then
	local problems = {}

	for path in fs.walk(project.BUILD_PATH, { recursive = true }) do
		local pathString = tostring(path)

		if pathString:match("%.test%.luau$") then
			table.insert(problems, `test file leaked into {project.BUILD_PATH}: {pathString}`)
		elseif fs.type(path) == "file" and pathString:match("%.luau$") then
			local contents = fs.readFileToString(path)
			if contents:match('require%("@lute') or contents:match('require%("@std') then
				table.insert(problems, `Lute-only require leaked into {project.BUILD_PATH}: {pathString}`)
			end
		end
	end

	if fs.exists(`{project.BUILD_PATH}/testing`) then
		table.insert(problems, `test helpers leaked into {project.BUILD_PATH}: {project.BUILD_PATH}/testing`)
	end

	if #problems > 0 then
		print(`[err] {table.concat(problems, "\n[err] ")}`)
		process.exit(1)
	end
else
	print(`skipping dist hygiene checks: {project.BUILD_PATH} does not exist (run 'lute run build' first)`)
end
