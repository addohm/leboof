# Roadmap

What's done for leboof, and what's next. Update it in the same commit as the
change.

## Done

- Standard docs (2026-11-07).
- 0.1.0, first build (2026-11-07): keep row with the missing look, up row, weapon enchants,
  class defaults for warrior, priest and druid, `/leboof` commands, the Windows install script.

## Next

1. First in-game run (TESTING.md): do the containers accept the player's buffs in combat, does the
   missing look work, and do the defaults suit each of your characters?
2. Decide the open design points: which buffs belong in each row, the layout (one row each, or
   groups placed separately), and whether in-combat sounds matter (that would mean checking
   whether Forever turns on the Cooldown Manager and its alerts).
3. An options window instead of slash commands.

## Ideas

- Out-of-combat reminders, where aura data can be read: "Fortitude ends in under 5 minutes" before
  a pull.
- Consumables (flasks, elixirs, food) and more world buffs.
- The other classes.
