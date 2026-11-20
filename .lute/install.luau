local process = require("@std/process")

-- Lute copies each GitHub dependency in `pkg.luau`, dev dependencies included,
-- into a gitignored `.lpm` folder, one folder per dependency named `<key>@<rev>`. The `lpm` alias in
-- `.config.luau` points at `.lpm`, so code requires a dependency through its
-- folder, such as `@lpm/batteries@v1.0.1-nightly.20261115/pp`. Bumping a rev
-- changes the folder name, so those requires change with it.
local result = process.run({ "lute", "pkg", "install", "--vendor" }, { stdio = "inherit" })
assert(result.ok, "lute pkg install --vendor failed")
