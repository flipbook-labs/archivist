-- Loom package entry point: consumers require the repo root
-- (e.g. `require("@pkg/Archivist@v0.1.0")`), which forwards to the library.
return require("@self/src")
