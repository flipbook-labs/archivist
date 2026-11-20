-- Archivist's own aliases. This file ships with the package (see `files` in
-- `pkg.luau`), so a vendored copy of Archivist still finds its own modules
-- through `@root`. Dependencies come through `@lpm`, which the project using
-- Archivist defines, so it isn't here.
return {
	luau = {
		aliases = {
			root = "./",
		},
	},
}
