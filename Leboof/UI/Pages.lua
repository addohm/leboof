-- Leboof: the options window's tabs: Buffs (a mode for every buff), Layout (size, spacing,
-- moving the icons) and General (minimap button, about).
local _, ns = ...
local UI = ns.UI

local MODE_CHOICES = {
	{ "keep", "Keep up" },
	{ "up", "While up" },
	{ "off", "Off" },
}
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
	local texture = e.enchant and ENCHANT_ICONS[e.enchant] or (e.idList and e.idList[1] and C_Spell.GetSpellTexture(e.idList[1]))
	return "|T" .. tostring(texture or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":20:20:0:0:64:64:5:59:5:59|t  "
end

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
			def.fill(panel.stack)
		end,
		refresh = function(panel) panel.stack:Sync() end,
		defaults = def.defaults,
	})
end

-- Buffs: a picker per buff, under its section's heading. A changed mode is marked.
Page({
	id = "buffs",
	label = "Buffs",
	note = "Keep up: a fixed place in the top row, a dimmed red copy while it's missing. While up: the second row, only while it's on you. Changes made in combat apply when combat ends.",
	fill = function(stack)
		local section
		for _, e in ipairs(ns.Catalogue) do
			if e.section ~= section then
				section = e.section
				stack:Add(UI.OptionHeading(stack.inner, section))
			end
			local icon = Icon(e)
			stack:Add(UI.OptionSelect(stack.inner, icon .. e.label, MODE_CHOICES,
				function() return ns.Mode(e) end,
				function(mode) ns.SetMode(e, mode) end,
				{
					font = "GameFontHighlight",
					tooltip = function()
						local lines = { e.label }
						if e.names and #e.names > 1 then lines[#lines + 1] = "Counts: " .. table.concat(e.names, ", ") end
						lines[#lines + 1] = "Default for you: " .. MODE_NAMES[ns.DefaultMode(e)]
						if e.warn and e.warn > 0 then lines[#lines + 1] = "Time left turns red under " .. e.warn .. " s" end
						return lines
					end,
					sync = function(row)
						local changed = ns.db.modes[e.key] and "  |cff999999(changed)|r" or ""
						row.label:SetText(icon .. e.label .. changed)
					end,
				}))
		end
	end,
	defaults = function() ns.ResetModes() end,
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
				.. "Leboof never reads aura data. In combat the game hides it from addons, so Leboof "
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

local function Report(ok, err)
	if not ok and err then ns.Print(err) end
	ns.Window.Refresh()
	return ok
end

local function ProfileChoices(skipCurrent)
	return function()
		local list = {}
		for _, name in ipairs(Profiles.Names()) do
			if not (skipCurrent and name == Profiles.Current()) then list[#list + 1] = { name, name } end
		end
		return list
	end
end

-- The profile picked in a "from" or "delete" picker: kept while it still exists.
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
