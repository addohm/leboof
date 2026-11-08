# Changelog

All notable changes to leboof. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- The listing banner (`art/leboof-banner.png`), a 400 px avatar icon and `LISTING.md`, the
  CurseForge and Wago page text (2026-11-08).

## [1.0.0] - 2026-11-08

The first release, for WoW: Forever.

### Added

- Your buffs in combat, where the game hides aura data from addons: Leboof tells Blizzard's aura
  containers which buffs to show, and the game fills the icons itself. The icons never read aura
  data.
- Two rows, growing from the centre (or from the left or right):
  - **Keep up:** a fixed place per buff, with a dimmed red copy while it's missing. Weapon
    enchants (oils, sharpening stones) at the end.
  - **While up:** procs, cooldowns and other buffs, only while they're on you; gaps close.
- Defaults per class (warrior, priest, druid): your own class's buffs on, everything else off. The
  buff list is checked against Forever: its new and changed class buffs and talents, the priest
  racials, and the world buffs it has, with notes on where they come from.
- **Leboof's buffs** checklist (a submenu per section) to add and remove built-in buffs, and
  **Add from the buffs on you now** for your own: only buffs on you can be tracked, so nothing is
  typed in. Added buffs learn their other ranks by name out of combat.
- Glows that work in combat: a **warning glow** near the end of a buff (the game's refresh
  window) and an **expired glow** round a missing buff's red copy, as big as the warning glow and
  gone the moment the buff is back. Styles: Pulse, Pixel glow, Action button glow, Auto-cast
  shine, GCD, Modern WoW glow, Classic WoW glow; eleven colours or your class colour. Icons
  themselves just appear and disappear.
- Sounds: **running out** at the warning time (out of combat from the buff's timer, in combat
  timed from your own cast, never twice for one cast); a buff appearing or dropping (out of
  combat); and a warning on entering combat with a keep-up buff missing. The **warning time** is
  yours to set (each buff's own by default, or 3 s to 10 min), and turns the timer red at the same
  moment. A pointer to Blizzard's Cooldown Manager, whose alerts are the only in-combat sounds the
  game allows for buffs being applied or removed.
- An options window in Nothing Wasted's style (Buffs, Layout, Effects, General, Profiles), a
  per-buff gear menu for its own glows, sounds and warning time, a minimap button and the addon
  compartment entry.
- Profiles: every setting in a profile, one per character by default ("First Last"), shareable
  between characters, with copy, rename, delete and reset.
- `/leboof soundlog`: logs every sound any addon plays and which addon played it, ready to copy.
- `tools\install_forever.cmd` (Windows): pull, install into the client with a build stamp, and
  pack the zip on the desktop; `tools/make_release.py` builds the release zip.
