# Testing in game

What to check after installing a build (`tools\install_forever.cmd`, then `/reload`). Note the
build `/leboof` shows. Results go in Confirmed or Problems below.

## To check (1.1.0)

0. After installing this build, fully restart the game (the `.toc` changed). The AddOns list and
   the addon compartment show Leboof's icon: gold chevrons on dark teal.
1. No Lua errors on login. `/leboof help` prints the commands with a build number.
1a. `/leboof` opens the options window (and closes it again); so do the minimap button and the
    addon menu by the minimap. Escape closes it; it can be dragged and resized, and comes back in
    the same place.
1b. Buffs tab: the tracked buffs with icons under their headings; the arrows (or clicking the
    box) switch Keep up / While up, the icons change at once, and changed ones say "(changed)".
    Hover shows the default. Defaults puts them all back (and removes added buffs).
1c. Layout tab: icon size and spacing change the icons; both rows are centred on their place, and
    stay centred as second-row icons come and go (Grow from: Center); Left and Right grow one way; Unlock shows the blue box, Lock hides it.
1d. General tab: untick the minimap button and it goes; tick it and it's back.
1e. Profiles tab: it says this character's profile, by first and last name (no realm); a profile
    from an earlier build named "Name - Realm" has been renamed that way. Make a new one: settings go
    back to defaults; switch back and yours return. On a second character, pick the first one's
    profile: its buffs and layout follow, and the first character's tab says "Also used by".
    Copy, rename, delete (asks first) and reset work. Settings from an earlier build are kept.
1f. Minimap button: right-click unlocks and locks the icons; drag moves it around the minimap,
    clear of Nothing Wasted's and Ticky's buttons.
1g. Adding and removing: "Leboof's buffs" opens a menu with four sections; each opens a checklist
    with icons, ticked for what's tracked. Tick a few without the menu closing: each one appears in
    Tracked and on screen, and the button's count goes up. Untick, or Remove in Tracked, and it
    goes. Out of combat, with a buff on you that isn't tracked (a food or elixir
    buff, say), it's listed under "Add from the buffs on you now"; Add puts it in Tracked and on
    screen, and it shows in combat too, inside a dungeon as well. In combat the list says it
    can't read your buffs. Debuffs never appear in that list.
1h. Effects: icons just appear and disappear (no growing, shrinking or fading). Top row: after
    seeing Battle Shout once out of combat, recast it and fight: the warning glow appears at the
    warning time (15 s, or what you set), in combat, and only then. Second row: near the end of a
    proc or HoT the glow shows if Forever gives it a refresh window; say which ones glow. A missing top-row buff's red copy has a red
    glow, and the copy itself stays still. Out of
    combat: let Battle Shout run low (map ping at 15 s), then drop (raid warning). Pull with it
    missing: a raid warning and "missing: Battle Shout" in chat. Recast Battle Shout in combat
    (after seeing it once out of combat): the running-out sound comes 15 s before it ends, once,
    and not again if combat ends before it runs out. Set Warning time to 30 s on the Effects tab:
    the sound and the red text both move to 30 s. The ⚙ menu on a tracked buff changes just that buff. The Effects tab says
    whether Blizzard's Cooldown Manager is available; note what it says.
1i. Glows: on the Effects tab, step through each warning glow style and colour; the sample icon
    shows it. Then check each style on a real buff near its end (Renew or Battle Shout): Pixel,
    Action button, Auto-cast, GCD, Modern, Classic. Expired glows: a missing top-row buff shows
    the chosen glow around its red copy, as big as the warning glow, and the glow vanishes the
    moment the buff is
    back. Note any style that looks wrong or doesn't animate (the Classic ants and Modern loop
    use the game's own art, so they need checking most).
1j. Only when missing: set Battle Shout to it. With Battle Shout up its place is empty (no icon,
    no glow); when it drops, the red copy and the expired glow appear, in combat too, and vanish
    when you recast. Opacity and grey: on the Effects tab set 50% and Grey; icons that are up
    fade and turn grey with no red tint showing through, their warning glow stays bright, and the red copies don't change.
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

- At reduced opacity, icons that are up show no red tint; the red copy still appears when the
  buff drops (9dff371, 2026-11-14).
- The expired glow shows round a missing top-row buff's red copy in combat (2026-11-08).
- The top row's warning glow comes up at the warning time in combat (Battle Shout; f681d69,
  2026-11-08).
- Sounds out of combat at the right moments: running out at 15 s and dropped at 0 for Battle
  Shout; `/leboof soundlog` names the addon behind each sound (13e60b4, 2026-11-08).

## Problems

None reported yet.
