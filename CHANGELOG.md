# Changelog

All notable changes to leboof. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- The buff list checked against WoW: Forever (2026-11-08):
  - Removed Spirit of Zandalar: Zul'Gurub isn't in Forever.
  - Added warrior Shield Block, Shield Wall, Last Stand, Retaliation, Reckless Swings and Gore
    Drinker; priest Spirit Tap, Inspiration, Dark Inspiration, Divine Aegis, Prayer of Mending and
    the racials (Shadowguard, Touch of Weakness, Elune's Grace, Feedback, Dark Sacrifice); druid
    Dash, Frenzied Regeneration, Nature's Swiftness, Nature's Grace, Eclipse, Leader of the Pack,
    Moonkin Aura and Wild Growth. On by default for their class.
  - Added the world buffs Traces of Silithyst and Sayge's Dark Fortune (off by default).
  - Divine Spirit is trained by every priest in Forever, so it's in the top row for priests.
  - World buffs and racials say where they come from in their tooltips; Rallying Cry (Onyxia, from
    Dec 9) and Warchief's Blessing (Upper Blackrock Spire may not be in Forever) are marked.
- Defaults: each class sees only its own buffs (self-buffs, procs, cooldowns, shields, HoTs).
  Buffs from other classes, world buffs and weapon enchants start off (2026-11-08).
- `/leboof` opens the options window; `/leboof help` lists the commands (2026-11-08).
- `tools/install_forever.cmd` installs into the live client (`_forever_`) by default, not the
  beta (2026-11-08).

### Added

- Grow from (Layout tab): both rows grow from the center by default, staying centred on their
  place as icons come and go; Left and Right grow one way (2026-11-08).
- Animations and sounds (an Effects tab for the defaults, a ⚙ menu per tracked buff for its
  own): a pop or flash when a buff appears, a pulsing glow near its end (the game's refresh
  window) and a pulsing red copy while missing, all played by the game in combat too. Sounds out
  of combat when a buff appears, drops or runs low; a warning entering combat with a "keep up" buff
  missing; a sound before a buff you cast runs out, timed from the cast; and a check for
  Blizzard's Cooldown Manager, whose alerts are the only in-combat sounds the game allows for buffs
  being applied or removed (2026-11-08).
- The Buffs tab's "Leboof's buffs" checklist: a dropdown with a submenu per section, ticked for
  what's tracked; tick to add, untick to remove. It replaces the one-at-a-time picker (2026-11-08).
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
