# Deploying leboof

Leboof is a World of Warcraft addon. It runs inside the game client (WoW: Forever, Interface
16001), and there's no server.

## First-time setup

On the Windows test PC:

1. Clone the repo anywhere: `git clone https://github.com/addohm/leboof.git` (it needs your
   GitHub login if the repo is private).
2. Open `tools\install_forever.cmd` and check `WOW` at the top: it's the client folder, by default
   `C:\Program Files (x86)\World of Warcraft\_forever_`, the live game. Change it to
   `_classic_beta_` for the beta client.
3. Run `tools\install_forever.cmd` from a terminal, then start the game. Check that Leboof is
   enabled under AddOns on the character-select screen.

To install by hand instead, copy the `Leboof` folder (not the repo root) into
`<WoW>\_forever_\Interface\AddOns\`.

## Shipping a change

1. Run the tests: `.venv/bin/python tests/run_tests.py`.
2. Commit and push.
3. On Windows, run `tools\install_forever.cmd`, then `/reload` (or restart the game if it says so).
4. For a release: bump `## Version` in `Leboof/Leboof.toc`, move the CHANGELOG's Unreleased
   entries under the new version, commit, tag (`git tag v0.1.0`) and push. The install script's
   desktop zip is the release package.

## The install script

`tools\install_forever.cmd` does, in order:

- `git pull --ff-only` (it only gets what's pushed, so push first). The pull can update the
  script itself, so it runs from a copy in `%TEMP%`.
- Mirrors `Leboof\` into `<WOW>\Interface\AddOns\Leboof` (`robocopy /MIR`), creating the folder
  on the first run. If `WOW` itself doesn't exist it stops, since the path is probably wrong.
- Writes the commit into the installed `Build.lua`, so `/leboof` shows `v<version> build <commit>`.
  "-dirty" means the copy included uncommitted changes.
- Packs `Leboof-<version>.zip` on the desktop: `git archive` of the committed `Leboof\` folder,
  without the build stamp.
- Says whether `/reload` is enough. WoW reads the addon's file list only when the game starts, so
  when the `.toc` changed you must restart the game.

If creating or copying fails, the WoW folder may need the script to run as administrator.

## Rolling back

Install an older version: `git checkout <tag> -- Leboof` in the clone, copy it over the installed
folder, then `git checkout main -- Leboof` to return.

## Configuration

There are no secrets or environment settings. In-game settings are saved per character in
`WTF/Account/<account>/<realm>/<character>/SavedVariables/Leboof.lua`.

## Troubleshooting

- **Nothing on `/leboof`:** the addon isn't loaded. Check the AddOns list; if it says out of date,
  the client's Interface number isn't 16001.
- **"the game's aura containers aren't available":** `Blizzard_AuraContainer` didn't load or
  doesn't accept addon containers on this client. Report the message text.
- **Lua errors:** `/console scriptErrors 1` shows them; report them with the `/leboof` build.

TODO: where should public releases go (CurseForge, Wago, GitHub Releases, or nowhere yet)?
