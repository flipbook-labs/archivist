# Contributing to Archivist

## Setup

Archivist uses [Rokit](https://github.com/rojo-rbx/rokit) for toolchain management. Rokit installs the pinned `lute` version.

```sh
rokit install
lute setup         # install the Luau typedefs
lute run install   # vendor dependencies into .lpm/
```

## Commands

```sh
lute run example   # run the demo script under Lute
lute test          # run the test suite
lute run lint      # check formatting and lint rules
lute run analyze   # run Luau type analysis
lute run build     # build the Roblox model (Archivist.rbxm)
```

Tests are `*.test.luau` files next to the code they cover.

## Changelog entries

Each pull request that changes what users see adds one entry under `.changes/`, as described in [`.changes/README.md`](.changes/README.md).
