# Leboof: CurseForge and Wago listing

Copy-paste material for the project pages. Placeholders are in [brackets]. Keep the feature list
in step with README.md.

---

## Basics

| Field | Value |
| --- | --- |
| Name | Leboof |
| Slug | `leboof` |
| Game version | WoW: Forever (Interface 16001) |
| Author | addohm |
| License | [choose: All Rights Reserved, MIT, ...] |
| Source | [https://github.com/addohm/leboof, if the repo is public] |
| Issues | [https://github.com/addohm/leboof/issues, if public] |

**Images**
- Avatar: `art/leboof-icon-400.png`
- Banner / header: `art/leboof-banner.png` (1600x500)

**Categories**
- CurseForge: Buffs & Debuffs (main), Combat, Audio & Video
- Wago: Buffs & Debuffs (main), Combat

**Summary** (the one-liner under the name; 123 characters)

> Your buffs in combat on WoW: Forever. See what's up, what's running out, and a glowing red copy
> of anything you're missing.

**Short tagline** (for images or a Discord post)

> Your buffs in combat, and what's missing.

---

## Description

*(Paste as Markdown. Both sites accept it.)*

### Leboof

**Your buffs in combat, built for WoW: Forever.**

In Forever, the game hides buff data from addons once combat starts. Leboof works with that
instead of around it: it hands your buffs to Blizzard's own aura containers, and the game shows
them itself. So the icons, timers and glows keep working in every fight.

#### Two rows, nothing else

- **Keep up:** a fixed place for each buff you should always have: Battle Shout, Inner Fire,
  Fortitude, Mark of the Wild, Omen of Clarity, your weapon oil or stone. When one is missing, a
  dimmed red copy of its icon sits in its place, so you see the gap at a glance.
- **While up:** procs, cooldowns and other buffs, shown only while they're on you. The row closes
  its gaps.
- Both rows grow from the centre (or from the left or right). Icons just appear and disappear: no
  bouncing, fading or growing.

#### Glows that work in combat

- **Warning glow** from your warning time on (for the keep-up row; the second row uses the
  game's refresh window).
- **Expired glow** around a missing buff's red copy, the same size as the warning glow, and gone
  the moment the buff is back.
- Seven styles: Pulse, Pixel glow, Action button glow, Auto-cast shine, GCD, Modern WoW glow and
  Classic WoW glow, in eleven colours or your class colour. Sample icons show your choice as you
  pick.

#### Sounds

- **Running out:** a sound when a buff's time left goes under your warning time (each buff's own,
  or anything from 3 seconds to 10 minutes). In combat it's timed from your own cast.
- **Dropped** and **appeared** sounds out of combat, and a warning when you pull with a buff
  missing, with the missing ones listed in chat.
- Every sound picker has a Test button.
- `/leboof soundlog` tells you which addon played any sound you hear, Leboof or not.

#### Your buffs, your list

- Sensible defaults for warriors, priests and druids: your own class's buffs on, the rest off.
- Tick buffs on and off from a checklist: class and group buffs, procs and cooldowns, world buffs
  and weapon enchants. The list is checked against Forever's own changes: its new talents, the
  priest racials, and the world buffs it has (each says where it comes from).
- Add any buff of your own by picking it while it's on you. Only buffs on you can be tracked this
  way, so you can't add one that would never light up.
- A per-buff menu for its own glows, sounds and warning time.

#### Profiles

- Every setting is in a profile, one per character by default ("First Last").
- Share one between characters, say two warriors, or copy, rename, delete and reset.

#### Commands

| Command | |
| --- | --- |
| `/leboof` | Open or close the options window |
| `/leboof unlock`, `/leboof lock` | Move the icons |
| `/leboof list` | Every buff and how it's shown |
| `/leboof profile` | The profile in use |
| `/leboof soundlog` | Log every sound and the addon that played it |
| `/leboof help` | All commands |

The minimap button opens the options (right-click to unlock the icons), and so does the game's
addon menu by the minimap.

#### Good to know

- **Does it read buff data in combat?** No. The game doesn't allow it, and Leboof doesn't try.
  Blizzard's containers do the showing; Leboof only says which buffs and where. Out of combat it
  reads your buffs for the "add from the buffs on you" list and its sounds.
- **In combat, sounds can't know about buffs someone else cast on you** (Fortitude from another
  priest, say), because the game hides them. Those warn out of combat.
- **Blizzard's Cooldown Manager** can play its own sounds in combat when a buff is applied or
  removed. Leboof's Effects tab tells you whether it's available and opens it.
- No libraries, no automation: display and sound only.

---

## Screenshots to take

1. Both rows in combat, with one top-row buff missing (its red copy and expired glow showing) and
   another near its end with the warning glow.
2. The Effects tab: the two sample icons and the glow and sound pickers.
3. The Buffs tab with the Leboof's buffs checklist open on a section.
4. A tracked buff's gear menu.
5. The Profiles tab.
6. The icons unlocked (the blue box) being moved.

---

## Release notes

### 1.0.0

The first release. Your buffs in combat through Blizzard's aura containers: a keep-up row with a
red copy for anything missing, a while-up row for procs and cooldowns, warning and expired glows
in seven styles and eleven colours, sounds for running out (in combat too, for your own casts),
dropping and pulling without a buff, a checklist of Forever's buffs plus any of your own,
profiles per character, and `/leboof soundlog`.
