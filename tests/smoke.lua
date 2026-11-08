-- Scenarios run by tests/run_tests.py. WM is the mock (wowmock.lua), ns the addon namespace.
local function Check(cond, msg) if not cond then error(msg, 2) end end
local function Printed(pattern)
	for _, line in ipairs(WM.printed) do if line:find(pattern) then return true end end
	return false
end
local function Keep() return WM.containers[1] end
local function Up() return WM.containers[2] end

-- A warrior who knows Battle Shout logs in.
WM.known[6673] = true
WM.Fire("ADDON_LOADED", "Leboof")
WM.Fire("PLAYER_LOGIN")
Check(ns.built, "display not built: " .. table.concat(WM.printed, " | "))
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))
Check(Keep().slots.battleshout and Keep().slots.battleshout.enabled, "Battle Shout should be in the keep row")
Check(Keep().slots.battleshout.filters.includeSpellIDs[25289], "Battle Shout should include its top rank")
Check(not Keep().slots.innerfire, "a warrior has no Inner Fire place")
local groups = 0
for _, g in pairs(Up().groups) do if g.enabled then groups = groups + 1 end end
Check(groups > 0, "the up row should have groups")
Check(Up().groups.warn3 and Up().groups.warn3.filters.includeSpellIDs[12966], "Flurry should be in the 3s group")

-- Moving Fort to keep adds a place; turning it off disables it again.
WM.Slash("fort keep")
Check(Keep().slots.fort and Keep().slots.fort.enabled, "fort keep didn't add a place")
WM.Slash("fort off")
Check(not Keep().slots.fort.enabled, "fort off didn't disable the place")
Check(ns.db.modes.fort == "off", "fort off wasn't saved")
WM.Slash("fort default")
Check(ns.db.modes.fort == nil, "fort default should clear the saved mode")

-- Changes in combat wait for it to end.
WM.combat = true
WM.Slash("battleshout up")
Check(Keep().slots.battleshout.enabled, "changed in combat")
Check(Printed("when combat ends"), "no combat message")
WM.combat = false
WM.Fire("PLAYER_REGEN_ENABLED")
Check(not Keep().slots.battleshout.enabled, "not applied after combat")

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
Check(not Keep().slots.battleshout.enabled, "the change didn't reach the icons")
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
Check(ns.acct.minimap.hide and not LeboofMinimapButton.shown, "/leboof minimap didn't hide the button")
WM.Slash("minimap")
Check(not ns.acct.minimap.hide and LeboofMinimapButton.shown, "/leboof minimap didn't show the button")
Check(not Printed("couldn't"), "layout error: " .. table.concat(WM.printed, " | "))
