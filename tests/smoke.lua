-- Scenarios run by tests/run_tests.py. WM is the mock (wowmock.lua), ns the addon namespace.
local function Check(cond, msg) if not cond then error(msg, 2) end end
local function Printed(pattern)
	for _, line in ipairs(WM.printed) do if line:find(pattern) then return true end end
	return false
end
local function Keep() return WM.containers[1] end
local function Up() return WM.containers[2] end
-- A buff's keep-row slot ("<key>/<animations>"): the enabled one, else any.
local function KeepSlot(key)
	local found
	for k, slot in pairs(Keep().slots) do
		if k:sub(1, #key + 1) == key .. "/" then
			if slot.enabled then return slot end
			found = slot
		end
	end
	return found
end
-- The enabled up-row group for a warn time ("warn<w>/<animations>").
local function UpGroup(w)
	for k, g in pairs(Up().groups) do
		if g.enabled and k:sub(1, #("warn" .. w) + 1) == "warn" .. w .. "/" then return g end
	end
end

-- A warrior who knows Battle Shout logs in, with settings saved by 0.1.0 (per character, the
-- window and minimap button account-wide): they move into a profile named after the character.
LeboofCharDB = { point = "CENTER", x = 0, y = -180, size = 32, gap = 4, locked = true, modes = { thorns = "off" } }
LeboofDB = { window = { tab = "layout" }, minimap = { angle = 10, hide = false } }
WM.known[6673] = true
WM.Fire("ADDON_LOADED", "Leboof")
WM.Fire("PLAYER_LOGIN")
Check(ns.Profiles.Current() == "Tester - Realm", "the character's profile isn't in use")
Check(ns.db == LeboofDB.profiles["Tester - Realm"], "ns.db isn't the profile")
Check(ns.db.modes.thorns == "off" and ns.db.minimap.angle == 10 and ns.db.window.tab == "layout", "old settings weren't moved")
Check(LeboofCharDB == nil, "the old per-character settings weren't cleared")
Check(ns.built, "display not built: " .. table.concat(WM.printed, " | "))
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))
Check(KeepSlot("battleshout") and KeepSlot("battleshout").enabled, "Battle Shout should be in the keep row")
Check(KeepSlot("battleshout").filters.includeSpellIDs[25289], "Battle Shout should include its top rank")
Check(not KeepSlot("innerfire"), "a warrior has no Inner Fire place")
local groups = 0
for _, g in pairs(Up().groups) do if g.enabled then groups = groups + 1 end end
Check(groups > 0, "the up row should have groups")
Check(UpGroup(3) and UpGroup(3).filters.includeSpellIDs[12966], "Flurry should be in the 3s group")

-- Defaults: the class's own buffs on, everything else off.
local function M(key) return ns.DefaultMode(ns.byKey[key]) end
Check(M("battleshout") == "keep" and M("flurry") == "up" and M("deathwish") == "up" and M("shieldwall") == "up", "a warrior's own buffs should be on")
Check(ns.byKey.zandalar == nil and ns.byKey.silithyst and ns.byKey.sayge and #ns.byKey.sayge.idList >= 8, "the world buffs list")
Check(ns.byKey.rallyingcry.note and ns.byKey.warchief.note:find("unconfirmed"), "world buffs should say where they come from")
for _, key in ipairs({ "fort", "motw", "kings", "might", "intellect", "rallyingcry", "mainhand", "offhand", "innerfire", "renew" }) do
	Check(M(key) == "off", key .. " should be off for a warrior")
end
WM.class = "PRIEST"
WM.known[10938] = true
Check(M("fort") == "keep" and M("innerfire") == "up" and M("renew") == "up" and M("shield") == "up", "a priest's own buffs should be on (keep needs the spell known)")
Check(M("battleshout") == "off" and M("motw") == "off" and M("kings") == "off", "other classes' buffs should be off for a priest")
WM.class = "DRUID"
Check(M("motw") == "up" and M("thorns") == "up" and M("clearcasting") == "up" and M("fort") == "off", "a druid's defaults")
WM.class = "WARRIOR"
WM.known[10938] = nil

-- Moving Fort to keep adds a place; turning it off disables it again.
WM.Slash("fort keep")
Check(KeepSlot("fort") and KeepSlot("fort").enabled, "fort keep didn't add a place")
WM.Slash("fort off")
Check(not KeepSlot("fort").enabled, "fort off didn't disable the place")
Check(ns.Mode(ns.byKey.fort) == "off" and ns.db.modes.fort == nil, "off is a warrior's default for fort, so nothing is saved")
WM.Slash("battleshout off")
Check(ns.db.modes.battleshout == "off", "a change from the default wasn't saved")
WM.Slash("battleshout default")
WM.Slash("fort default")
Check(ns.db.modes.fort == nil, "fort default should clear the saved mode")

-- Changes in combat wait for it to end.
WM.combat = true
WM.Slash("battleshout up")
Check(KeepSlot("battleshout").enabled, "changed in combat")
Check(Printed("when combat ends"), "no combat message")
WM.combat = false
WM.Fire("PLAYER_REGEN_ENABLED")
Check(not KeepSlot("battleshout").enabled, "not applied after combat")

-- Size, unlock, list, reset, help, a bad command: no errors.
WM.Slash("size 40")
Check(ns.db.size == 40, "size not saved")
WM.Slash("size 400")
Check(ns.db.size == 40, "size out of range was accepted")
WM.Slash("unlock")
WM.Slash("lock")
WM.Slash("list")
WM.Slash("help")
WM.Slash("nonsense")
WM.Slash("reset")
Check(ns.db.size == 32 and next(ns.db.modes) == nil, "reset didn't reset")
WM.Fire("PLAYER_EQUIPMENT_CHANGED")
WM.Fire("SPELLS_CHANGED")
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))

-- Every buff resolves to spell IDs.
for _, e in ipairs(ns.Catalogue) do
	Check(e.enchant or (e.idList and #e.idList > 0), e.key .. " has no spell IDs")
end

-- The options window: /leboof opens it on the Buffs tab; the arrows change a buff's mode.
WM.combat = false
WM.Slash("")
Check(ns.Window.IsShown(), "/leboof didn't open the window")
ns.Window.Select("buffs")
local panel = ns.Window.CurrentPanel()
Check(panel and panel.stack, "no Buffs page")
local shout
for _, row in ipairs(panel.stack.rows) do
	if row.label and row.label.text and row.label.text:find("Battle Shout", 1, true) then shout = row end
end
Check(shout, "no Battle Shout row")
shout.next.scripts.OnClick()
Check(ns.db.modes.battleshout == "up", "the arrow didn't change Battle Shout to While up")
Check(shout.label.text:find("(changed)", 1, true), "a changed mode isn't marked")
Check(not KeepSlot("battleshout").enabled, "the change didn't reach the icons")
shout.prev.scripts.OnClick()
Check(ns.db.modes.battleshout == nil, "back to the default should clear the saved mode")
for _, id in ipairs({ "layout", "general", "buffs" }) do
	ns.Window.Select(id)
	Check(ns.Window.CurrentPanel().stack, id .. " page didn't build")
end
WM.Slash("")
Check(not ns.Window.IsShown(), "/leboof didn't close the window")

-- Minimap button and the addon compartment.
Check(LeboofMinimapButton and LeboofMinimapButton.shown, "no minimap button")
Leboof_OnAddonCompartmentClick(nil, "RightButton")
Check(ns.db.locked == false, "right-click didn't unlock the icons")
Leboof_OnAddonCompartmentClick(nil, "RightButton")
Check(ns.db.locked == true, "right-click didn't lock the icons")
Leboof_OnAddonCompartmentClick(nil, "LeftButton")
Check(ns.Window.IsShown(), "left-click didn't open the window")
WM.Slash("minimap")
Check(ns.db.minimap.hide and not LeboofMinimapButton.shown, "/leboof minimap didn't hide the button")
WM.Slash("minimap")
Check(not ns.db.minimap.hide and LeboofMinimapButton.shown, "/leboof minimap didn't show the button")
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))

-- Profiles: new, separate, copy, rename, delete, reset, and a deleted profile at login.
local P = ns.Profiles
WM.Slash("reset")
Check(P.New("Shared"), "New failed")
Check(P.Current() == "Shared" and ns.db.size == 32, "the new profile isn't in use with defaults")
Check(not P.New("Shared") and not P.New("   "), "a duplicate or empty name was accepted")
ns.SetMode(ns.byKey.fort, "keep")
Check(KeepSlot("fort").enabled, "fort keep in Shared didn't reach the icons")
Check(P.Switch("Tester - Realm"), "Switch failed")
Check(not KeepSlot("fort").enabled and ns.db.modes.fort == nil, "profiles aren't separate")
Check(P.CopyFrom("Shared") and ns.db.modes.fort == "keep" and KeepSlot("fort").enabled, "CopyFrom didn't copy")
Check(not P.CopyFrom("Tester - Realm"), "copied a profile onto itself")
Check(not P.Delete("Tester - Realm"), "deleted the profile in use")
Check(P.Rename("Main") and P.Current() == "Main", "Rename failed")
Check(LeboofDB.profiles.Main == ns.db and LeboofDB.profiles["Tester - Realm"] == nil, "Rename left the old name")
LeboofDB.chars["Alt - Realm"] = "Shared"
Check(P.UsedBy("Shared")[1] == "Alt - Realm", "UsedBy")

-- The Profiles tab: the picker switches, Delete asks first.
ns.Window.Show()
ns.Window.Select("profiles")
local inUse, delete
for _, row in ipairs(ns.Window.CurrentPanel().stack.rows) do
	if row.label and row.label.text == "Profile in use" then inUse = row end
	if row.button and row.button.text == "Delete it" then delete = row end
end
Check(inUse and delete, "the Profiles tab is missing rows")
inUse.next.scripts.OnClick()
Check(P.Current() == "Shared", "the picker didn't switch profiles")
inUse.prev.scripts.OnClick()
Check(P.Current() == "Main", "the picker didn't switch back")
delete.button.scripts.OnClick()
Check(LeboofDB.profiles.Shared, "Delete didn't ask first")
WM.Accept()
Check(LeboofDB.profiles.Shared == nil and LeboofDB.chars["Alt - Realm"] == nil, "Delete didn't delete")

Check(P.Reset() and next(ns.db.modes) == nil and ns.db.minimap.angle == 250, "Reset didn't reset")

-- A character whose profile was deleted elsewhere gets its own at the next login.
LeboofDB.chars["Tester - Realm"] = "Gone"
P.Init()
Check(P.Current() == "Tester - Realm" and ns.db == LeboofDB.profiles["Tester - Realm"], "no fallback profile")
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))

-- Adding and removing buffs.
local function BuffsRows()
	ns.Window.Show()
	ns.Window.Select("buffs")
	return ns.Window.CurrentPanel().stack.rows
end
local function CurrentRowFor(spellId)
	for _, row in ipairs(BuffsRows()) do
		if row.ref and row.ref.buff and row.ref.buff.spellId == spellId then return row end
	end
end
local function TrackedRowFor(key)
	for _, row in ipairs(BuffsRows()) do
		if row.ref and row.ref.entry and row.ref.entry.key == key then return row end
	end
end

WM.combat = false
WM.buffs = {
	{ spellId = 999001, name = "Juju Power", icon = 5555, duration = 1800 },
	{ spellId = 10938, name = "Power Word: Fortitude", icon = 135987, duration = 1800 },
}
ns.SetMode(ns.byKey.fort, "up")
Check(TrackedRowFor("fort") and not CurrentRowFor(10938), "a tracked buff shouldn't be offered again")
TrackedRowFor("fort").remove.scripts.OnClick()
Check(ns.Mode(ns.byKey.fort) == "off" and CurrentRowFor(10938), "Remove didn't turn Fortitude off")
CurrentRowFor(10938).button.scripts.OnClick()
Check(ns.Mode(ns.byKey.fort) == "up" and ns.db.custom.c10938 == nil, "Adding Fortitude should switch the built-in on")

CurrentRowFor(999001).button.scripts.OnClick()
local juju = ns.db.custom.c999001
Check(juju and juju.name == "Juju Power" and juju.warn == 120, "Juju Power wasn't added")
Check(UpGroup(120).filters.includeSpellIDs[999001], "the added buff isn't in the up row")
Check(not CurrentRowFor(999001) and TrackedRowFor("c999001"), "the added buff should move to Tracked")
Check(not ns.AddBuff({ spellId = 999001, name = "Juju Power" }), "added the same buff twice")

-- Another rank seen out of combat is learned; not in combat.
table.insert(WM.buffs, { spellId = 999002, name = "Juju Power", icon = 5555, duration = 1800 })
WM.combat = true
WM.Fire("UNIT_AURA", "player")
Check(not juju.ids[999002], "learned in combat")
WM.combat = false
WM.Fire("UNIT_AURA", "player")
Check(juju.ids[999002] and UpGroup(120).filters.includeSpellIDs[999002], "the new rank wasn't learned")

ns.SetMode(ns.Entry("c999001"), "keep")
Check(KeepSlot("c999001") and KeepSlot("c999001").enabled and KeepSlot("c999001").filters.includeSpellIDs[999002], "keep for an added buff")
TrackedRowFor("c999001").remove.scripts.OnClick()
Check(ns.db.custom.c999001 == nil and ns.db.modes.c999001 == nil and not KeepSlot("c999001").enabled, "Remove didn't delete the added buff")

-- Leboof's buffs: a checklist dropdown, a submenu per section; ticking tracks, unticking removes.
local checklist
for _, row in ipairs(BuffsRows()) do
	if row.dropdown then checklist = row end
end
Check(checklist, "no Leboof's buffs dropdown")
local menu = WM.Menu(checklist.dropdown)
Check(#menu.buttons == 4 and menu.buttons[4].text == "Weapon enchants", "the menu should have a submenu per section")
local total = 0
for _, sub in ipairs(menu.buttons) do total = total + #sub.items end
Check(total == #ns.Catalogue, "every built-in buff should be in the checklist")
local mh = menu.buttons[4].items[1]
Check(mh.text:find("Main hand enchant", 1, true) and not mh.isSelected(), "the main hand enchant should start unticked")
local world = menu.buttons[3]
Check(world.text == "World buffs" and world.items[1].tooltip, "world buffs in the checklist should have a tooltip")
mh.setSelected()
Check(mh.isSelected() and ns.Mode(ns.byKey.mainhand) == "up", "ticking didn't track it")
Check(TrackedRowFor("mainhand"), "a ticked buff should be in Tracked")
Check(checklist.dropdown.text and checklist.dropdown.text:find("tracked"), "the dropdown should count the tracked buffs")
mh.setSelected()
Check(not mh.isSelected() and ns.Mode(ns.byKey.mainhand) == "off" and not TrackedRowFor("mainhand"), "unticking didn't remove it")
Check(checklist.shown, "the dropdown row was hidden by a refresh (its menu would close)")

-- In combat the buffs can't be read: the tab says so instead of failing.
WM.combat = true
BuffsRows()
Check(ns.ReadBuffs() == nil, "read buffs in combat")
WM.combat = false

-- Added buffs belong to the profile.
ns.AddBuff({ spellId = 999003, name = "Winterfall Firewater", icon = 1, duration = 1200 })
Check(ns.Profiles.New("Clean") and next(ns.db.custom) == nil, "a new profile has the other profile's buffs")
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))

-- Glows: the buttons get the chosen warning glow and nothing else; changing it switches buttons.
WM.combat = false
local bs = KeepSlot("battleshout")
Check(bs and bs.enabled and #bs.button.shownAnims == 0 and #bs.button.pandemicAnims == 1 and #bs.button.pandemicRegions == 8,
	"Battle Shout's button should have only the pixel glow, near the end")
ns.Fx.Set(ns.byKey.battleshout, "expiring", "none")
local bs2 = KeepSlot("battleshout")
Check(bs2 ~= bs and bs2.enabled and not bs.enabled, "changing the glow should switch buttons")
Check(#bs2.button.pandemicAnims == 0 and #bs2.button.pandemicRegions == 0, "no glow")
ns.Fx.Set(ns.byKey.battleshout, "expiring", nil)
Check(bs.enabled and not bs2.enabled and ns.db.fx.battleshout == nil, "back to the defaults")
Check(UpGroup(3) and #UpGroup(3).frames[1].shownAnims == 0 and #UpGroup(3).frames[1].pandemicAnims == 1, "up-row buttons: the glow only")

-- Sounds out of combat: gained (none for keep), running out, drops; entering combat without it.
WM.sounds = {}
WM.buffs = { { spellId = 25289, name = "Battle Shout", icon = 1, duration = 120, expirationTime = WM.now + 120 } }
WM.Fire("UNIT_AURA", "player")
Check(#WM.sounds == 0, "a keep-up buff appearing is quiet by default")
WM.Advance(100)
Check(#WM.sounds == 0, "running-out sound too early")
WM.Advance(8)
Check(WM.Played("MAP_PING"), "no running-out sound under the warning time")
WM.Advance(3)
Check(#WM.sounds == 1, "the running-out sound should play once")
WM.buffs = {}
WM.Fire("UNIT_AURA", "player")
Check(WM.Played("RAID_WARNING"), "no sound when it dropped")
WM.sounds = {}
WM.printed = {}
WM.combat = true
WM.Fire("PLAYER_REGEN_DISABLED")
Check(WM.Played("RAID_WARNING") and Printed("missing: Battle Shout"), "no warning entering combat without Battle Shout")

-- In combat: a sound before your own cast runs out (duration from the earlier look: 120 s).
ns.db.effects.cast = "ALARM_CLOCK_WARNING_3"
WM.sounds = {}
WM.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 25289)
WM.Advance(110)
Check(#WM.sounds == 0, "the cast sound came too early")
WM.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 25289) -- recast: starts again
WM.Advance(110)
Check(#WM.sounds == 0, "a recast didn't restart the timer")
WM.Advance(6)
Check(WM.Played("ALARM_CLOCK_WARNING_3"), "no sound before the cast ran out")
WM.sounds = {}
WM.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 12345) -- not a tracked buff
WM.Advance(200)
Check(#WM.sounds == 0, "a sound for a spell that isn't tracked")

-- After combat: what changed during the fight isn't announced.
WM.sounds = {}
WM.buffs = { { spellId = 25289, name = "Battle Shout", icon = 1, duration = 120, expirationTime = WM.now + 120 } }
WM.combat = false
WM.Fire("PLAYER_REGEN_ENABLED")
Check(#WM.sounds == 0, "a change during combat was announced afterwards")
ns.db.effects.cast = "none"

-- A buff's own choices: the gear menu.
local fortRow
ns.SetMode(ns.byKey.fort, "keep")
for _, row in ipairs(BuffsRows()) do
	if row.ref and row.ref.entry and row.ref.entry.key == "fort" then fortRow = row end
end
Check(fortRow and fortRow.gear, "no gear button on a tracked buff")
fortRow.gear.scripts.OnClick(fortRow.gear)
local fxMenu = WM.RunMenu(function(root) WM.contextMenu.generator(fortRow.gear, root) end)
Check(fxMenu.title == "Power Word: Fortitude" and #fxMenu.buttons == 9, "the gear menu should have a submenu per setting")
local lost
for _, b in ipairs(fxMenu.buttons) do if b.text:find("drops") then lost = b end end
Check(lost.text:find("drops") and lost.items[1].text:find("Default (Raid warning)", 1, true) and lost.items[1].isSelected(), "Default first, selected")
lost.items[#lost.items].setSelected()
Check(ns.Fx.Get(ns.byKey.fort, "sLost") == "MAP_PING" and WM.Played("MAP_PING"), "picking a sound should set and play it")
Check(fortRow.label.text:find("(changed)", 1, true), "a buff with its own effects should be marked")
lost.items[1].setSelected()
Check(ns.db.fx.fort == nil, "Default should clear the buff's own choice")

-- The Effects tab builds; a sound picker sets and plays its sound.
ns.Window.Select("effects")
local dropsRow
for _, row in ipairs(ns.Window.CurrentPanel().stack.rows) do
	if row.test and row.label.text == "When one drops" and not dropsRow then dropsRow = row end
end
Check(dropsRow, "no sound picker on the Effects tab")
WM.sounds = {}
dropsRow.next.scripts.OnClick()
Check(ns.db.effects.keepLost == "READY_CHECK" and WM.Played("READY_CHECK"), "the picker didn't set and play the next sound")
dropsRow.test.scripts.OnClick()
Check(#WM.sounds == 2, "Test didn't play it")
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))

-- Growing: centred by default, else from the left or the right.
WM.combat = false
local function FirstX(slot) return slot.button.points[1][4] end
ns.ResetModes()
ns.Refresh()
local keepCount = 0
for _, e in ipairs(ns.Entries()) do if ns.Mode(e) == "keep" then keepCount = keepCount + 1 end end
Check(ns.db.grow == "center", "rows should grow from the centre by default")
local width = keepCount * (ns.db.size + ns.db.gap) - ns.db.gap
Check(FirstX(KeepSlot("battleshout")) == -width / 2, "the keep row isn't centred")
Check(Up().points[1][1] == "TOP", "the up row isn't centred")
ns.db.grow = "left"
ns.Refresh()
Check(FirstX(KeepSlot("battleshout")) == 0 and Up().points[1][1] == "TOPLEFT", "grow from the left")
ns.db.grow = "right"
ns.Refresh()
Check(FirstX(KeepSlot("battleshout")) == -width and Up().points[1][1] == "TOPRIGHT", "grow from the right")
ns.db.grow = "center"
ns.Refresh()

-- Glow styles: each builds; the warning glow goes to the game's button, the expired glow inside
-- the red copy (so the button covers it while the buff is up); old on/off settings still work.
for _, v in ipairs(ns.Glow.STYLES) do
	local owner = CreateFrame("Frame")
	owner:SetSize(32, 32)
	local built = ns.Glow.Build(owner, v[1], "class", 32)
	Check(v[1] == "none" or (#built.regions > 0 and #built.groups > 0), v[1] .. " built nothing")
end
for _, v in ipairs(ns.Glow.STYLES) do
	ns.db.effects.expiring = v[1]
	ns.db.effects.missing = v[1]
	ns.Refresh()
	Check(not Printed("couldn't"), v[1] .. ": " .. table.concat(WM.printed, " | "))
end
ns.db.effects.expiring = "modern"
ns.db.effects.expiringColor = "blue"
ns.Refresh()
Check(#KeepSlot("battleshout").button.pandemicRegions == 1, "the modern glow is one flipbook texture")
ns.db.fx.battleshout = { expiring = "on", missing = "off" }
Check(ns.Fx.Get(ns.byKey.battleshout, "expiring") == "pulse" and ns.Fx.Get(ns.byKey.battleshout, "missing") == "none", "old on/off values")
ns.db.fx.battleshout = nil
ns.db.effects.expiring, ns.db.effects.expiringColor = "pixel", "gold"
ns.db.effects.missing = "classic"
ns.Refresh()
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))
