# Changelog

All notable changes to leboof. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

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
