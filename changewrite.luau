return {
	categories = { "Features", "Changes", "Fixes", "Dependencies", "Internal" },
	collapsed = { "Dependencies", "Internal" },
	version = {
		current = "0.3.2",
		mirror = {
			{ file = "wally.toml" },
			{ file = "pkg.luau" },
			{ file = "README.md", pattern = "flipbook%-labs/archivist@([%d%.]+)" },
			{ file = "README.md", pattern = 'rev = "v([%d%.]+)"' },
			{ file = "README.md", pattern = "@lpm/archivist@v([%d%.]+)" },
		},
	},
	kind = {
		release = { text = "Release", color = "#94606f" },
		build = { text = "Build", color = "#5a7396" },
		ci = { text = "CI", color = "#75659a" },
		contributing = { text = "Contributing", color = "#5f7f55" },
		docs = { text = "Docs", color = "#8a5a2b" },
		formatters = { text = "Formatters", color = "#bf3989" },
		logging = { text = "Logging", color = "#5b5bd6" },
		packages = { text = "Packages", color = "#7a7444" },
		sinks = { text = "Sinks", color = "#0e7490" },
		tooling = { text = "Tooling", color = "#4e8079" },
	},
}
