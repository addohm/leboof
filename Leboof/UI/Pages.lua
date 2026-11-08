-- Leboof: the options window's tabs: Buffs (what's tracked, adding and removing), Layout (size,
-- spacing, moving the icons), General (minimap button, about) and Profiles.
local _, ns = ...
local UI = ns.UI

local MODE_NAMES = { keep = "Keep up", up = "While up", off = "Off" }

local SIZES = {}
for _, n in ipairs({ 20, 24, 28, 32, 36, 40, 44, 48, 56, 64 }) do SIZES[#SIZES + 1] = { n, n .. " px" } end
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
				local changed = ns.db.modes[ref.entry.key] and "  |cff999999(changed)|r" or ""
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
	row.remove, row.ref = remove, ref
	return row
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
			sub:CreateCheckbox(MenuText(e), function() return Tracked(e) end, function() SetTracked(e, not Tracked(e)) end)
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
