# Change entries

This folder holds the unreleased changes for the next release. Each file describes one change: how big a version bump it warrants and what to say about it in the changelog. At release time [Changewrite](https://github.com/flipbook-labs/changewrite) combines every entry here into `CHANGELOG.md`, bumps the version, and deletes the entries it consumed.

## Adding an entry

Create a Markdown file in this folder, named after the change, such as `fix-release-permissions.md`:

```markdown
---
bump: minor
category: Features
kind: sinks
---

Add support for Foo values so Bar can be Bazzed.
```

- **`bump`** (required) — how much to move the version: `major`, `minor`, or `patch`.
- **`category`** (required) — the heading this entry appears under in the changelog: `Features`, `Changes`, `Fixes`, `Dependencies`, or `Internal`. The changelog lists the headings in that order, as set by `categories` in [`changewrite.toml`](../changewrite.toml). Dependencies and Internal start collapsed in GitHub release notes.
- **`kind`** (required) — the part of Archivist the change landed in, shown as a chip beside the entry. Pick one of the kinds under `[kind]` in [`changewrite.toml`](../changewrite.toml): `logging`, `sinks`, `formatters`, `docs`, `build`, `tooling`, `packages`, `ci`, `release`, or `contributing`. A refactor takes the kind of whatever it touches.
- **`highlight`** (optional) — a short title for a change worth a headline. The entry's full body appears under Highlights at the top of the release notes.
- **Body** — everything below the frontmatter is the changelog text. Aim for one short sentence.

An optional `release.md` in this folder opens the next release's notes with a one- or two-sentence summary of what it brings. Changewrite consumes it with the entries.

After changing the kinds in `changewrite.toml`, run `changewrite generate` and commit the chip images it writes to `assets/`.

## How the version is chosen

The next version is the largest bump across all pending entries: a single `major` entry makes the release a major, otherwise a single `minor` makes it a minor, otherwise it is a `patch`.

`README.md` is ignored, so it is safe to keep here.
