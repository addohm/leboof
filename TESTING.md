# Testing in game

What to check after installing a build (`tools\install_forever.cmd`, then `/reload`). Note the
build `/leboof` shows. Results go in Confirmed or Problems below.

## To check (0.1.0)

0. After installing this build, fully restart the game (the `.toc` changed). The AddOns list and
   the addon compartment show Leboof's icon: gold chevrons on dark teal.
1. No Lua errors on login. `/leboof help` prints the commands with a build number.
1a. `/leboof` opens the options window (and closes it again); so do the minimap button and the
    addon menu by the minimap. Escape closes it; it can be dragged and resized, and comes back in
    the same place.
1b. Buffs tab: the tracked buffs with icons under their headings; the arrows (or clicking the
    box) switch Keep up / While up, the icons change at once, and changed ones say "(changed)".
    Hover shows the default. Defaults puts them all back (and removes added buffs).
1c. Layout tab: icon size and spacing change the icons; Unlock shows the blue box, Lock hides it.
1d. General tab: untick the minimap button and it goes; tick it and it's back.
1e. Profiles tab: it says this character's profile ("Name - Realm"). Make a new one: settings go
    back to defaults; switch back and yours return. On a second character, pick the first one's
    profile: its buffs and layout follow, and the first character's tab says "Also used by".
    Copy, rename, delete (asks first) and reset work. Settings from an earlier build are kept.
1f. Minimap button: right-click unlocks and locks the icons; drag moves it around the minimap,
    clear of Nothing Wasted's and Ticky's buttons.
1g. Adding and removing: Remove a tracked buff, and it leaves the icons and shows up under "Add
    from Leboof's list". Out of combat, with a buff on you that isn't tracked (a food or elixir
    buff, say), it's listed under "Add from the buffs on you now"; Add puts it in Tracked and on
    screen, and it shows in combat too, inside a dungeon as well. In combat the list says it
    can't read your buffs. Debuffs never appear in that list.
2. The icons appear a little below the middle of the screen. `/leboof unlock` shows a blue box to
   drag; `/leboof lock` hides it; the place is kept after `/reload`.
3. Keep row: with the class buff missing (e.g. Battle Shout, Inner Fire), a dimmed red copy shows.
   Cast it: the real icon covers the copy, with time left.
4. The same in combat, out in the world: the icon appears on cast and the red copy comes back when
   the buff ends or is cancelled.
5. The same in combat inside a dungeon (where addons get no aura data at all).
5a. Defaults on a fresh profile: only your class's buffs are tracked (Buffs tab); Fortitude from
    another priest, Kings, world buffs and weapon enchants aren't, until you add them.
6. Up row: procs (Flurry, Enrage, Clearcasting) and buffs you've added appear while up, and the row
   closes its gaps.
7. Time left turns red near the end.
8. Weapon enchant: apply a sharpening stone or oil; it shows at the end of the keep row.
9. `/leboof fort keep` gives Fortitude a place; `/leboof list` shows it with a `*`. Try a change
   in combat: it should say it applies when combat ends, and do so.
10. `/leboof size 40`: icons grow, nothing overlaps.

## Confirmed

Nothing yet.

## Problems

None reported yet.
