# CLAUDE.md

Orientation for Claude working on leboof. Read this first.

## What this is

A new project, so far only the standard docs (first commit 2026-11-07). The
remote is `addohm/leboof` on GitHub (`origin`, branch `main`).

TODO: what does leboof do, and what are its main parts?

## Layout

- `README.md`, `CHANGELOG.md`, `DEPLOY.md`, `SECURITY.md`, `ROADMAP.md`: the
  standard docs (see Workflow)
- `CLAUDE.md`: this file

No code yet. Add each folder here as it's created.

## Workflow

1. Start from the latest: pull before changing anything.
2. Make the change with tests.
3. **Update the docs in the same commit.** Every change updates the docs it
   affects:
   - README.md: setup and usage
   - CHANGELOG.md: an entry under *Unreleased*
   - DEPLOY.md: when deploying or running it live changes
   - SECURITY.md: when secrets, access or permissions change
   - ROADMAP.md: when something on it is done, or new plans are made
   - this file: when the layout, workflow or conventions change
4. Run the checks (none yet; TODO: the lint and test commands once there's code), then commit.

## Conventions

TODO: what language and stack? Coding style, naming, anything a newcomer would
get wrong.

## Don't

- Commit secrets (`.env`, keys, tokens).
