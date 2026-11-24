return {
	package = {
		name = "Archivist",
		version = "0.3.1",
		-- What a consumer gets when installing Archivist. `/src/**` skips
		-- dotfiles, so `src/.config.luau` has to be named to ship. Specs
		-- (`*.test.luau`) and the helpers in `src/testing` are only for this
		-- repo's tests, so they stay out.
		files = {
			"/init.luau",
			"/src/**",
			"/src/.config.luau",
			"/README.md",
			"/LICENSE",
			"!/src/**/*.test.luau",
			"!/src/testing/**",
		},
		dependencies = {
			batteries = {
				rev = "v1.0.1-nightly.20261115",
				sourceKind = "github",
				source = "https://github.com/luau-lang/lute",
				target = "batteries",
			},
		},
		dev_dependencies = {
			["agent-skills"] = {
				rev = "v0.9.0",
				sourceKind = "github",
				source = "https://github.com/flipbook-labs/agent-skills",
			},
		},
	},
}
