# Changelog

All notable changes to leboof. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Defaults: each class sees only its own buffs (self-buffs, procs, cooldowns, shields, HoTs).
  Buffs from other classes, world buffs and weapon enchants start off (2026-11-08).
- `/leboof` opens the options window; `/leboof help` lists the commands (2026-11-08).
- `tools/install_forever.cmd` installs into the live client (`_forever_`) by default, not the
  beta (2026-11-08).

### Added

- Adding and removing buffs: the Buffs tab lists what's tracked, each with Remove, and adds from
  Leboof's list or from the buffs on you now (out of combat). Only buffs on you can be added,
  since those are the only ones the game's containers can show; nothing is typed in. An added
  buff learns its other ranks by name when Leboof sees them out of combat (2026-11-08).
- Profiles: every setting is in a profile, and each character starts with its own. The new
  Profiles tab switches profiles (to share one between characters), makes a new one, copies from
  another, renames, deletes and resets; `/leboof profile` shows the one in use. Settings saved by
  0.1.0 move into the character's profile (2026-11-08).
- An options window like Nothing Wasted's (`/leboof`, the minimap button or the addon menu): a
  Buffs tab with a Keep up / While up / Off picker for every buff, a Layout tab (size, spacing,
  moving the icons) and a General tab, each with Defaults (2026-11-08).
- A minimap button with the Leboof icon: click for the window, right-click to unlock or lock the
  icons, drag to move it; `/leboof minimap` shows or hides it (2026-11-08).
- An icon for the AddOns list and the addon compartment: two gold chevrons on dark teal with a
  red "missing" pip, drawn by `art/make_logo.py` (2026-11-08).
- Leboof 0.1.0, the first build: your buffs in combat through Blizzard's aura containers, with no
  aura data read. A keep row (a fixed place per buff, a dimmed red copy when it's missing, weapon
  enchants at the end) and an up row (procs and other buffs while they're up), class defaults for
  warrior, priest and druid, and `/leboof` commands (2026-11-07).
- `tools/install_forever.cmd`: pulls, installs into the Windows client with a build stamp, and
  packs the zip on the desktop, like Nothing Wasted's (2026-11-07).
- `tools/gen_data.py` (spell IDs from wago.tools) and headless tests (2026-11-07).
- Standard docs: README, CLAUDE, CHANGELOG, DEPLOY, SECURITY and ROADMAP (2026-11-07).
- Filled the docs with what's known so far; open questions are marked TODO
  (2026-11-07).
