# leboof

Leboof is a World of Warcraft addon for **WoW: Forever** (Interface 16001) that shows your own
buffs in combat, where the game hides aura data from addons. The icons don't read any aura data:
Blizzard's aura containers fill them themselves. Leboof only says which buffs to show and where to
put them. (Out of combat it reads your buffs for one thing: the list you add buffs from.)

The source lives at `github.com/addohm/leboof`. Status: first build (0.1.0), not yet tried in
game.

## What it shows

Two rows of icons, a little below the middle of the screen by default:

- **Keep up** (top row): a fixed place for each buff you should always have, such as Battle Shout,
  Inner Fire, Fortitude, Mark of the Wild or Omen of Clarity. When the buff is up you see its icon
  and time left. When it's missing you see a dimmed red copy instead. Weapon enchants (oils,
  sharpening stones) sit at the end of this row.
- **While up** (second row): procs, cooldowns and any other buffs you add, shown only
  while they're on you. The row closes its gaps.

The time left turns red near the end (each buff has its own warning time). Procs get a swipe.
Hovering an icon shows the game's tooltip.

By default you see **your own class's buffs and nothing else** (warrior, priest and druid so
far): the long self-buffs in the top row (Battle Shout; Inner Fire and Fortitude; Mark of the Wild
and Omen of Clarity), and your procs, cooldowns, shields and HoTs in the second row. Buffs from
other classes, world buffs and weapon enchants start off; tick them in the Buffs tab's checklist. A self-buff
only gets a top-row place if you know the spell (otherwise it's in the second row). Built-in
buffs work by spell name, so all ranks count, and group versions like Prayer of Fortitude count as
Fortitude.

## Getting started

Copy the `Leboof` folder into `<WoW>\_forever_\Interface\AddOns\` and start the game. To install
straight from this repo on Windows, see [DEPLOY.md](DEPLOY.md) (`tools\install_forever.cmd`).

## Usage

**The options window** opens with `/leboof` (or `/lbf`), the minimap button, or the game's addon
menu by the minimap. It has five tabs:

- **Buffs:** add and remove what's tracked.
  - **Leboof's buffs ▾:** a checklist of the built-in buffs, with a submenu per section (class and
    group buffs, procs and cooldowns, world buffs, weapon enchants). Tick to track, untick to
    remove; the menu stays open so you can tick several. They're known to work, with every rank
    and group version.
  - **Tracked:** the buffs shown, under their headings, each with Keep up / While up and
    **Remove**. Changed ones are marked; hover one for its default and warning time.
  - **Add from the buffs on you now:** your current buffs (out of combat), each with **Add**. This
    is the only way to add a buff of your own, and it's what keeps it to buffs that can work (see
    below). Added buffs go in the profile.
- **Layout:** icon size, the space between icons, Unlock/Lock to drag the icons, and back to the
  default place.
- **Effects:** the default animations and sounds (see below). Each tracked buff's ⚙ button on
  the Buffs tab sets its own.
- **General:** show or hide the minimap button, the version, and how Leboof works.
- **Profiles:** which profile this character uses, a new profile, copy settings from another
  profile, rename, delete, or reset every setting to the defaults.

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
- `/leboof profile`: the profile in use, and the others
- `/leboof reset`: default modes, size and position

**Profiles:** every setting (buff modes, size, spacing, where the icons and the window are, the
minimap button) is in a profile. Each character starts with its own, named after it ("Name -
Realm"). Pick another character's profile to share it, say between two warriors: a change on one
then shows on both. `/leboof profile` shows the one in use.

Changes made in combat apply when combat ends: the game won't
let addons touch the icons while auras are secret.

## What it can track

Blizzard's containers only match a spell ID for **buffs on you**, and only the buff's own ID. So
Leboof can't show debuffs, buffs on other players or your target, abilities that leave no buff,
or hidden passive talents. That's why you add your own buffs by picking them while they're on you:
anything on that list is a buff the game shows on you, with the exact ID the container will see.
Names and IDs can't be typed in, since Leboof couldn't check them.

A buff you add starts with the one spell ID it was seen with. When Leboof later sees a buff with
the same name out of combat (another rank, a group version), it adds that ID too. Its warning time
is a tenth of its duration, from 3 seconds to 2 minutes.

## Animations and sounds

**Animations** play in combat too, because the game plays them itself on its own buttons:

- **When a buff appears:** a pop (the icon grows in) or a white flash.
- **Glow near the end:** a pulsing gold edge in the game's refresh window, the last part of a buff
  where recasting keeps some of the time left. Buffs without one don't glow.
- **Pulse while missing:** the red copy in the top row pulses.

**Sounds** need to know when something happened, and in combat the game hides that. So:

- **Out of combat**, Leboof reads your buffs: a sound when a buff appears, drops, or runs low
  (under its warning time), with separate defaults for the two rows.
- **Entering combat** with a "keep up" buff missing: a warning sound, and the missing ones listed
  in chat, from what Leboof saw just before the fight.
- **In combat**, a sound a few seconds before a buff *you cast* should run out, timed from your
  cast with the duration last seen out of combat. It's a guess: it still plays if the buff was
  dispelled, its charges used, or it went on someone else. Off by default.
- **Blizzard's Cooldown Manager** is the only way the game plays a sound in combat when a buff is
  applied or removed. The Effects tab says whether Forever has it on and opens it; the alerts are
  set there, not in Leboof.

Every sound picker has a Test button, and picking a sound plays it.

## What it can't do

The game decides what's visible in combat, and the addon never learns it. So nothing in Leboof
can react to a buff changing in combat: no logic, and no sounds except the cast timer and
Blizzard's Cooldown Manager above. The animations and the "missing" look are the game's own
display, layered.

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
