-- Leboof: the options window's tabs: Buffs (what's tracked, adding and removing), Layout (size,
-- spacing, moving the icons), General (minimap button, about) and Profiles.
local _, ns = ...
local UI = ns.UI

local MODE_NAMES = { keep = "Keep up", up = "While up", off = "Off" }

local SIZES = {}
for _, n in ipairs({ 20, 24, 28, 32, 36, 40, 44, 48, 56, 64 }) do SIZES[#SIZES + 1] = { n, n .. " px" } end
local GROWS = { { "center", "Center" }, { "left", "Left" }, { "right", "Right" } }
local GAPS = {}
for _, n in ipairs({ 0, 1, 2, 3, 4, 6, 8, 10, 12 }) do GAPS[#GAPS + 1] = { n, n .. " px" } end

local ENCHANT_ICONS = {
	MainHand = "Interface\\Paperdoll\\UI-PaperDoll-Slot-MainHand",
	OffHand = "Interface\\Paperdoll\\UI-PaperDoll-Slot-SecondaryHand",
}

local function Icon(e)
	local texture = e.icon or (e.enchant and ENCHANT_ICONS[e.enchant])
		or (e.idList and e.idList[1] and C_Spell.GetSpellTexture(e.idList[1]))
	return "|T" .. tostring(texture or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":20:20:0:0:64:64:5:59:5:59|t  "
end

-- Prints a failure's reason, and shows the change.
local function Report(ok, err)
	if not ok and err then ns.Print(err) end
	ns.Window.Refresh()
	return ok
end

-- The value picked in a picker whose choices change: kept while it's still a choice.
local function Picker(choices)
	local picked
	local function get()
		local list = choices()
		for _, v in ipairs(list) do
			if v[1] == picked then return picked end
		end
		picked = list[1] and list[1][1]
		return picked
	end
	return get, function(v) picked = v end
end

-- def: { id, label, note, fill(stack, panel), refresh(panel) (default: sync the rows), defaults }
local function Page(def)
	ns.Window.AddPage({
		id = def.id,
		label = def.label,
		build = function(panel)
			local top = 0
			if def.note then
				local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				note:SetPoint("TOPLEFT", 4, -2)
				note:SetPoint("TOPRIGHT", -28, -2)
				note:SetJustifyH("LEFT")
				note:SetText(def.note)
				top = -36
			end
			local holder = CreateFrame("Frame", nil, panel)
			holder:SetPoint("TOPLEFT", 0, top)
			holder:SetPoint("BOTTOMRIGHT")
			panel.stack = UI.Stack(holder)
			def.fill(panel.stack, panel)
		end,
		refresh = def.refresh or function(panel) panel.stack:Sync() end,
		defaults = def.defaults,
	})
end

-- Buffs: what's tracked (with Keep up / While up and Remove), then two ways to add one: from
-- Leboof's own list, or from the buffs on you now (see Custom.lua for why only those). The list
-- is rebuilt on each refresh from pooled rows.
local TRACK_CHOICES = { { "keep", "Keep up" }, { "up", "While up" } }
local TRACK_X, TRACK_BOX = 250, 100

local function Tracked(e) return ns.Mode(e) ~= "off" end

local function EntryTooltip(e)
	local lines = { e.label }
	if e.custom then
		lines[#lines + 1] = "Added by you. Spell IDs seen: " .. #e.idList .. " (more ranks are added when Leboof sees them out of combat)."
	elseif e.names and #e.names > 1 then
		lines[#lines + 1] = "Counts: " .. table.concat(e.names, ", ")
	end
	if e.note then lines[#lines + 1] = e.note end
	lines[#lines + 1] = "Default for you: " .. MODE_NAMES[ns.DefaultMode(e)]
	if e.warn and e.warn > 0 then lines[#lines + 1] = "Time left turns red under " .. e.warn .. " s" end
	return lines
end

local function TrackedRow(parent)
	local ref = {}
	local row = UI.OptionSelect(parent, "", TRACK_CHOICES,
		function() return ns.Mode(ref.entry) end,
		function(mode) ns.SetMode(ref.entry, mode) end,
		{
			font = "GameFontHighlight", controlX = TRACK_X, boxWidth = TRACK_BOX,
			tooltip = function() return EntryTooltip(ref.entry) end,
			sync = function(r)
				local key = ref.entry.key
				local changed = (ns.db.modes[key] or ns.db.fx[key]) and "  |cff999999(changed)|r" or ""
				r.label:SetText(Icon(ref.entry) .. ref.entry.label .. changed)
			end,
		})
	local remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	remove:SetSize(76, 22)
	remove:SetPoint("LEFT", row.right + 6, 0)
	remove:SetText("Remove")
	remove:SetScript("OnClick", function()
		ns.RemoveBuff(ref.entry)
		ns.Window.Refresh()
	end)
	-- The buff's own animations and sounds, in a menu.
	local gear = CreateFrame("Button", nil, row)
	gear:SetSize(20, 20)
	gear:SetPoint("LEFT", remove, "RIGHT", 6, 0)
	gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
	gear:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	gear:SetScript("OnClick", function(self)
		MenuUtil.CreateContextMenu(self, function(_, root) ns.BuildFxMenu(ref.entry, root) end)
	end)
	gear:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Animations and sounds for " .. ref.entry.label)
		GameTooltip:Show()
	end)
	gear:SetScript("OnLeave", GameTooltip_Hide)
	row.remove, row.gear, row.ref = remove, gear, ref
	return row
end

-- A buff's own animation and sound choices: a submenu per setting, "Default (...)" first.
function ns.BuildFxMenu(e, root)
	local Fx = ns.Fx
	local keep = ns.Mode(e) == "keep"
	root:CreateTitle(e.label)
	local function Choice(text, field, list)
		local sub = root:CreateButton(text)
		sub:CreateRadio("Default (" .. Fx.Label(list, Fx.Default(e, field)) .. ")",
			function() return not (ns.db.fx[e.key] and ns.db.fx[e.key][field] ~= nil) end,
			function() Fx.Set(e, field, nil) end)
		for _, v in ipairs(list) do
			sub:CreateRadio(v[2],
				function() return ns.db.fx[e.key] ~= nil and ns.db.fx[e.key][field] == v[1] end,
				function()
					Fx.Set(e, field, v[1])
					if list == Fx.SOUNDS then Fx.Play(v[1]) end
				end)
		end
	end
	Choice("Warning glow (near the end)", "expiring", ns.Glow.STYLES)
	Choice("Warning glow colour", "expiringColor", ns.Glow.COLORS)
	if keep then
		Choice("Expired glow (while missing)", "missing", ns.Glow.STYLES)
		Choice("Expired glow colour", "missingColor", ns.Glow.COLORS)
	end
	Choice("Sound when it appears (out of combat)", "sGained", Fx.SOUNDS)
	Choice("Sound when it drops (out of combat)", "sLost", Fx.SOUNDS)
	Choice("Sound when it's running out (out of combat)", "sExpiring", Fx.SOUNDS)
	if keep then Choice("Sound entering combat without it", "sCombat", Fx.SOUNDS) end
	if not e.enchant then Choice("Sound before your cast runs out (in combat)", "sCast", Fx.SOUNDS) end
end

local function CurrentRow(parent)
	local ref = {}
	local row = UI.OptionButton(parent, "", "Add", function()
		Report(ns.AddBuff(ref.buff))
	end, function()
		local b = ref.buff
		local lines = { b.name }
		local e = ns.EntryForSpell(b.spellId)
		if e then
			lines[#lines + 1] = "One of Leboof's buffs: Add switches it on, with every rank."
		else
			lines[#lines + 1] = "Adds it as your own buff (spell ID " .. b.spellId .. ")."
		end
		return lines
	end)
	row.label:SetFontObject("GameFontHighlight")
	row.ref = ref
	return row
end

local function Duration(seconds)
	if not seconds or seconds <= 0 then return "no time limit" end
	if seconds >= 3600 then return math.floor(seconds / 3600 + 0.5) .. " h" end
	if seconds >= 60 then return math.floor(seconds / 60 + 0.5) .. " min" end
	return math.floor(seconds + 0.5) .. " s"
end

-- Leboof's own buffs as a checklist: a dropdown (Blizzard's menu system) with a submenu per
-- section; ticking tracks a buff, unticking removes it, and the menu stays open between ticks.
local function SetTracked(e, on)
	if on then
		local mode = ns.DefaultMode(e)
		ns.SetMode(e, mode ~= "off" and mode or "up")
	else
		ns.RemoveBuff(e)
	end
	ns.Window.Refresh()
end

local function MenuText(e)
	return Icon(e):gsub(":20:20:", ":16:16:") .. e.label
end

function ns.BuildBuffMenu(_, root)
	local order, sections = {}, {}
	for _, e in ipairs(ns.Catalogue) do
		if not sections[e.section] then
			sections[e.section] = {}
			order[#order + 1] = e.section
		end
		table.insert(sections[e.section], e)
	end
	for _, name in ipairs(order) do
		local sub = root:CreateButton(name)
		for _, e in ipairs(sections[name]) do
			local item = sub:CreateCheckbox(MenuText(e), function() return Tracked(e) end, function() SetTracked(e, not Tracked(e)) end)
			if e.note then
				item:SetTooltip(function(tooltip)
					GameTooltip_SetTitle(tooltip, e.label)
					GameTooltip_AddNormalLine(tooltip, e.note)
				end)
			end
		end
	end
end

local function ChecklistRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(36)
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.label:SetPoint("LEFT", 16, 0)
	row.label:SetText("Leboof's buffs")
	local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1FilterDropdownTemplate")
	dropdown:SetPoint("LEFT", 330, 0)
	dropdown:SetupMenu(ns.BuildBuffMenu)
	row.dropdown = dropdown
	row.Sync = function()
		local n = 0
		for _, e in ipairs(ns.Catalogue) do
			if Tracked(e) then n = n + 1 end
		end
		dropdown:SetText(n .. " of " .. #ns.Catalogue .. " tracked")
	end
	return row
end

Page({
	id = "buffs",
	label = "Buffs",
	note = "Keep up: a fixed place in the top row, a dimmed red copy while it's missing. While up: the second row, only while it's on you. Changes made in combat apply when combat ends.",
	fill = function(stack, panel)
		local p = { tracked = {}, sections = {}, current = {} }
		panel.parts = p
		p.checklist = ChecklistRow(stack.inner)
		p.headTracked = UI.OptionHeading(stack.inner, "Tracked")
		p.noneTracked = UI.OptionText(stack.inner, "Nothing is tracked. Tick buffs in Leboof's buffs above, or add one below.", 24)

		p.headCurrent = UI.OptionHeading(stack.inner, "Add from the buffs on you now")
		p.currentNote = UI.OptionText(stack.inner, function() return p.noteText end, 44)
	end,
	refresh = function(panel)
		local stack, p = panel.stack, panel.parts
		stack:Reset()

		stack:Add(p.checklist)
		stack:Add(p.headTracked)
		local n, section = 0, nil
		for _, e in ipairs(ns.Entries()) do
			if Tracked(e) then
				if e.section ~= section then
					section = e.section
					p.sections[section] = p.sections[section] or UI.OptionText(stack.inner, "|cffffd100" .. section .. "|r", 22)
					stack:Add(p.sections[section])
				end
				n = n + 1
				p.tracked[n] = p.tracked[n] or TrackedRow(stack.inner)
				p.tracked[n].ref.entry = e
				stack:Add(p.tracked[n])
			end
		end
		if n == 0 then stack:Add(p.noneTracked) end

		stack:Add(p.headCurrent)
		local buffs, why = ns.ReadBuffs()
		local shown, seen = 0, {}
		for _, b in ipairs(buffs or {}) do
			local e = ns.EntryForSpell(b.spellId)
			if not seen[b.spellId] and not (e and Tracked(e)) then
				seen[b.spellId] = true
				shown = shown + 1
				local row = p.current[shown] or CurrentRow(stack.inner)
				p.current[shown] = row
				row.ref.buff = b
				row.label:SetText("|T" .. tostring(b.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
					.. ":20:20:0:0:64:64:5:59:5:59|t  " .. b.name .. "  |cff999999" .. Duration(b.duration) .. "|r")
				stack:Add(row)
			end
		end
		if not buffs then
			p.noteText = why
		elseif shown == 0 then
			p.noteText = "Nothing new on you right now. Get the buff (cast it, or ask for it), then come back to this tab."
		else
			p.noteText = "Only buffs on you can be tracked, so they're picked from here: debuffs, buffs on others and abilities that leave no buff can't be shown this way."
		end
		stack:Add(p.currentNote)
		stack:Sync()
		stack:Done()
	end,
	defaults = function()
		ns.ResetModes()
		wipe(ns.db.custom)
	end,
})

Page({
	id = "layout",
	label = "Layout",
	fill = function(stack)
		stack:Add(UI.OptionHeading(stack.inner, "Icons"))
		stack:Add(UI.OptionSelect(stack.inner, "Icon size", SIZES,
			function() return ns.db.size end,
			function(v) ns.db.size = v; ns.Refresh() end))
		stack:Add(UI.OptionSelect(stack.inner, "Space between icons and rows", GAPS,
			function() return ns.db.gap end,
			function(v) ns.db.gap = v; ns.Refresh() end))
		stack:Add(UI.OptionSelect(stack.inner, "Grow from", GROWS,
			function() return ns.db.grow end,
			function(v) ns.db.grow = v; ns.Refresh() end,
			{ tooltip = { "Grow from", "Center: the rows stay centred on their place and grow both ways. Left: they start at the left and grow to the right. Right: the other way." } }))
		stack:Add(UI.OptionHeading(stack.inner, "Position"))
		stack:Add(UI.OptionButton(stack.inner, "Move the icons",
			function() return ns.db.locked and "Unlock" or "Lock" end,
			function() ns.SetLocked(not ns.db.locked) end,
			{ "Move the icons", "Unlocked, a blue box covers both rows: drag it, then lock." }))
		stack:Add(UI.OptionButton(stack.inner, "Back to the default place", "Reset position", function()
			ns.db.point, ns.db.x, ns.db.y = "CENTER", 0, -180
			ns.Refresh()
		end))
	end,
	defaults = function() ns.ResetLayout() end,
})

-- Effects: the default animations and sounds (a buff's own choices are in its ⚙ menu).
local function EffectGet(field)
	return function() return ns.db.effects[field] end
end

local function EffectSet(field)
	return function(v)
		ns.db.effects[field] = v
		ns.Refresh()
	end
end

-- Both, for the last argument of a call.
local function EffectSetting(field)
	return EffectGet(field), EffectSet(field)
end

Page({
	id = "effects",
	label = "Effects",
	note = "Defaults for every buff; the gear next to a tracked buff sets its own. In combat the game hides when buffs change, so sounds there only come from your own casts or Blizzard's Cooldown Manager.",
	fill = function(stack)
		local Fx = ns.Fx
		stack:Add(UI.OptionHeading(stack.inner, "Glows (in combat too)"))
		stack:Add(UI.GlowPreview(stack.inner))
		stack:Add(UI.OptionSelect(stack.inner, "Warning glow (near the end)", ns.Glow.STYLES, EffectGet("expiring"), EffectSet("expiring"),
			{ tooltip = { "Warning glow", "Shown in the game's refresh window: the last part of a buff, where recasting it keeps some of the time left. The game shows it, so it works in combat. Buffs without a refresh window don't get it." } }))
		stack:Add(UI.OptionSelect(stack.inner, "Warning glow colour", ns.Glow.COLORS, EffectSetting("expiringColor")))
		stack:Add(UI.OptionSelect(stack.inner, "Expired glow (top row, while missing)", ns.Glow.STYLES, EffectGet("missing"), EffectSet("missing"),
			{ tooltip = { "Expired glow", "Around the red copy of a missing top-row buff, within 3 px of it: the top row's 3 px icon border covers that while the buff is up. Bigger styles are trimmed there." } }))
		stack:Add(UI.OptionSelect(stack.inner, "Expired glow colour", ns.Glow.COLORS, EffectSetting("missingColor")))

		stack:Add(UI.OptionHeading(stack.inner, "Sounds out of combat: buffs to keep up"))
		stack:Add(UI.OptionSound(stack.inner, "When one drops", EffectSetting("keepLost")))
		stack:Add(UI.OptionSound(stack.inner, "When one is running out", EffectGet("keepExpiring"), EffectSet("keepExpiring"),
			{ "When one is running out", "When its time left goes under its warning time (the time left turns red then)." }))
		stack:Add(UI.OptionSound(stack.inner, "Entering combat without one", EffectGet("combatMissing"), EffectSet("combatMissing"),
			{ "Entering combat without one", "From what Leboof saw just before the fight." }))
		stack:Add(UI.OptionCheck(stack.inner, "Also list the missing ones in chat", EffectSetting("combatChat")))

		stack:Add(UI.OptionHeading(stack.inner, "Sounds out of combat: buffs while up"))
		stack:Add(UI.OptionSound(stack.inner, "When one appears", EffectSetting("upGained")))
		stack:Add(UI.OptionSound(stack.inner, "When one drops", EffectSetting("upLost")))

		stack:Add(UI.OptionHeading(stack.inner, "Sounds in combat"))
		stack:Add(UI.OptionSound(stack.inner, "Before a buff you cast runs out", EffectGet("cast"), EffectSet("cast"),
			{ "Before a buff you cast runs out", "Timed from your cast, with the duration Leboof last saw out of combat. It's a guess: it still plays if the buff was dispelled, its charges used, or it was cast on someone else." }))
		stack:Add(UI.OptionSelect(stack.inner, "How long before", Fx.LEADS, EffectSetting("castLead")))
		stack:Add(UI.OptionText(stack.inner, function()
			local available, reason = Fx.CooldownManager()
			if available then
				return "Blizzard's Cooldown Manager is on. It can play a sound in combat when a buff it tracks is applied or removed: open it, pick the buff, and add an alert."
			end
			return "Blizzard's Cooldown Manager isn't available here (" .. tostring(reason or "no reason given") .. "). It's the only way the game plays a sound in combat when a buff is applied or removed."
		end, 44))
		stack:Add(UI.OptionButton(stack.inner, "Blizzard's Cooldown Manager", "Open it", function() Fx.OpenCooldownManager() end))
	end,
	defaults = function()
		wipe(ns.db.effects)
		ns.CopyDefaults(ns.db.effects, ns.DEFAULTS.effects)
		wipe(ns.db.fx)
	end,
})

Page({
	id = "general",
	label = "General",
	fill = function(stack)
		stack:Add(UI.OptionCheck(stack.inner, "Show the minimap button",
			function() return not ns.db.minimap.hide end,
			function(v) ns.Minimap.SetShown(v) end))
		stack:Add(UI.OptionHeading(stack.inner, "About"))
		stack:Add(UI.OptionText(stack.inner, function()
			return "Leboof " .. ns.Version() .. "\n\n"
				.. "Leboof's icons never read aura data. In combat the game hides it from addons, so Leboof "
				.. "tells Blizzard's aura containers which of your buffs to show, and the game fills the "
				.. "icons itself. That's also why nothing can react to a buff (no sounds or glows), and why "
				.. "changes wait until combat ends.\n\n"
				.. "/leboof opens this window. /leboof help lists the chat commands."
		end, 150))
	end,
	defaults = function() ns.Minimap.SetShown(true) end,
})

-- Profiles: which profile this character uses, new ones, copying, renaming, deleting, resetting.
local Profiles = ns.Profiles

local function ProfileChoices(skipCurrent)
	return function()
		local list = {}
		for _, name in ipairs(Profiles.Names()) do
			if not (skipCurrent and name == Profiles.Current()) then list[#list + 1] = { name, name } end
		end
		return list
	end
end

StaticPopupDialogs.LEBOOF_PROFILE = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, data) data() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local function Confirm(text, action)
	StaticPopup_Show("LEBOOF_PROFILE", text, nil, function() Report(action()) end)
end

Page({
	id = "profiles",
	label = "Profiles",
	note = "Every setting is in a profile. Each character starts with its own; pick another to share it (say, between two warriors). Profiles are kept for all your characters.",
	fill = function(stack)
		stack:Add(UI.OptionHeading(stack.inner, "This character"))
		stack:Add(UI.OptionSelect(stack.inner, "Profile in use", ProfileChoices(false),
			function() return Profiles.Current() end,
			function(name) Report(Profiles.Switch(name)) end))
		stack:Add(UI.OptionText(stack.inner, function()
			local others = {}
			for _, char in ipairs(Profiles.UsedBy(Profiles.Current())) do
				if char ~= Profiles.CharKey() then others[#others + 1] = char end
			end
			return #others > 0 and ("Also used by: " .. table.concat(others, ", ")) or "No other character uses it."
		end, 24))

		stack:Add(UI.OptionHeading(stack.inner, "New"))
		stack:Add(UI.OptionEdit(stack.inner, "New profile (type a name, press Enter)",
			function() return "" end,
			function(text) return Report(Profiles.New(text)) end,
			{ "New profile", "Starts with the default settings, and this character switches to it." }))

		local fromChoices = ProfileChoices(true)
		local getFrom, setFrom = Picker(fromChoices)
		stack:Add(UI.OptionHeading(stack.inner, "Copy"))
		stack:Add(UI.OptionSelect(stack.inner, "Copy settings from", fromChoices, getFrom, setFrom))
		stack:Add(UI.OptionButton(stack.inner, "", "Copy into this profile", function()
			local from = getFrom()
			if not from then return ns.Print("there's no other profile to copy from.") end
			Confirm("Replace the settings in " .. Profiles.Current() .. " with a copy of " .. from .. "?",
				function() return Profiles.CopyFrom(from) end)
		end))

		stack:Add(UI.OptionHeading(stack.inner, "Manage"))
		stack:Add(UI.OptionEdit(stack.inner, "Rename this profile (press Enter)",
			function() return Profiles.Current() end,
			function(text) return Report(Profiles.Rename(text)) end,
			{ "Rename this profile", "Every character using it follows the new name." }))
		local getDel, setDel = Picker(fromChoices)
		stack:Add(UI.OptionSelect(stack.inner, "Delete a profile", fromChoices, getDel, setDel))
		stack:Add(UI.OptionButton(stack.inner, "", "Delete it", function()
			local name = getDel()
			if not name then return ns.Print("there's no other profile to delete.") end
			Confirm("Delete the profile " .. name .. "? Characters using it get a fresh profile of their own.",
				function() return Profiles.Delete(name) end)
		end, { "Delete a profile", "The profile in use can't be deleted: switch first." }))
		stack:Add(UI.OptionButton(stack.inner, "Every setting in this profile", "Reset to defaults", function()
			Confirm("Reset every setting in " .. Profiles.Current() .. " to the defaults?",
				function() return Profiles.Reset() end)
		end))
	end,
})
