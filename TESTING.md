# Testing in game

What to check after installing a build (`tools\install_forever.cmd`, then `/reload`). Note the
build `/leboof` shows. Results go in Confirmed or Problems below.

## To check (0.1.0)

1. `/leboof` prints the help with a build number, and no Lua errors on login.
2. The icons appear a little below the middle of the screen. `/leboof unlock` shows a blue box to
   drag; `/leboof lock` hides it; the place is kept after `/reload`.
3. Keep row: with the class buff missing (e.g. Battle Shout, Inner Fire), a dimmed red copy shows.
   Cast it: the real icon covers the copy, with time left.
4. The same in combat, out in the world: the icon appears on cast and the red copy comes back when
   the buff ends or is cancelled.
5. The same in combat inside a dungeon (where addons get no aura data at all).
6. Up row: procs (Flurry, Enrage, Clearcasting) and buffs from others appear while up, and the row
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
