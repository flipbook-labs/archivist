-- All paths are relative to the root of the repo

return {
	SOURCE_PATH = "src",
	BUILD_SOURCE_PATH = "build-tmp",
	BUILD_PATH = "dist",
	PACKAGES_PATH = "Packages",
	SCRIPTS_PATH = ".lute",

	MODEL_FILENAME = "Archivist.rbxm",

	SOURCEMAP_PATH = "sourcemap.json",
	DARKLUA_SOURCEMAP_PATH = "sourcemap-darklua.json",

	ROJO_BUILD_PROJECT = "build.project.json",

	FOLDERS_TO_LINT = {
		"src",
		".lute",
	},
}
