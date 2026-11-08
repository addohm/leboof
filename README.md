# leboof

Leboof is a World of Warcraft addon for **WoW: Forever** (Interface 16001) that shows your own
buffs in combat, where the game hides aura data from addons. It doesn't read any aura data:
Blizzard's aura containers fill the icons themselves. Leboof only says which buffs to show and
where to put them.

The source lives at `github.com/addohm/leboof`. Status: first build (0.1.0), not yet tried in
game.

## What it shows

Two rows of icons, a little below the middle of the screen by default:

- **Keep up** (top row): a fixed place for each buff you should always have, such as Battle Shout,
  Inner Fire, Fortitude, Mark of the Wild or Omen of Clarity. When the buff is up you see its icon
  and time left. When it's missing you see a dimmed red copy instead. Weapon enchants (oils,
  sharpening stones) sit at the end of this row.
- **While up** (second row): procs, cooldowns, buffs from others and world buffs, shown only
  while they're on you. The row closes its gaps.

The time left turns red near the end (each buff has its own warning time). Procs get a swipe.
Hovering an icon shows the game's tooltip.

The defaults depend on your class (warrior, priest and druid so far). A class buff only
gets a "keep" place if you know the spell. Everything works by spell name, so all ranks count,
and group versions like Prayer of Fortitude count as Fortitude.

## Getting started

Copy the `Leboof` folder into `<WoW>\_forever_\Interface\AddOns\` and start the game. To install
straight from this repo on Windows, see [DEPLOY.md](DEPLOY.md) (`tools\install_forever.cmd`).

## Usage

**The options window** opens with `/leboof` (or `/lbf`), the minimap button, or the game's addon
menu by the minimap. It has three tabs:

- **Buffs:** every buff Leboof knows, under headings (class and group buffs, procs and cooldowns,
  world buffs, weapon enchants), each with its icon and a picker: Keep up, While up or Off.
  Changed ones are marked; hover one for its default and warning time.
- **Layout:** icon size, the space between icons, Unlock/Lock to drag the icons, and back to the
  default place.
- **General:** show or hide the minimap button, the version, and how Leboof works.

Each tab has a Defaults button. The window can be moved and resized, and Escape closes it.

**The minimap button:** click for the window, right-click to unlock or lock the icons, drag to
move it around the minimap.

**Chat commands** (`/leboof help` lists them):

- `/leboof`: open or close the options window
- `/leboof list`: every buff and its mode
- `/leboof <buff> keep|up|off|default`: e.g. `/leboof fort keep` gives Fortitude a fixed place
- `/leboof unlock`, then drag the blue box; `/leboof lock` when done
- `/leboof size 16-64`, `/leboof gap 0-20`
- `/leboof minimap`: show or hide the minimap button
- `/leboof reset`: default modes, size and position

The icons' settings are saved per character; the window's place and the minimap button are
account-wide. Changes made in combat apply when combat ends: the game won't
let addons touch the icons while auras are secret.

## What it can't do

The game decides what's visible in combat, and the addon never learns it. So nothing can react to
a buff: no sounds, glows or "missing" logic beyond the visual layering above.

## Development

```bash
python3 -m venv .venv && .venv/bin/pip install lupa   # once
.venv/bin/python tests/run_tests.py                   # syntax, TOC, globals, scenarios
python3 tools/gen_data.py                             # after changing names in Buffs.lua
python3 art/make_logo.py                              # redraw the icon (needs Pillow)
```

## Docs

- [CHANGELOG.md](CHANGELOG.md): what changed in each version
- [DEPLOY.md](DEPLOY.md): installing builds and releasing
- [SECURITY.md](SECURITY.md): secrets, access, reporting problems
- [ROADMAP.md](ROADMAP.md): what's done and what's next
- [TESTING.md](TESTING.md): what to check in game
- [CLAUDE.md](CLAUDE.md): notes for Claude working on it
