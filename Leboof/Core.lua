-- Leboof: settings, modes and events. Everything is per character (LeboofCharDB), since the
-- buffs worth watching depend on the class.
local ADDON, ns = ...

local DEFAULTS = {
	point = "CENTER", x = 0, y = -180, -- the anchor's position, relative to UIParent
	size = 32,                          -- icon size
	gap = 4,                            -- space between icons and between the two rows
	locked = true,                      -- unlocked: the anchor can be dragged and shows a frame
	modes = {},                         -- key -> "keep" / "up" / "off", only where changed
}

ns.MODES = { keep = true, up = true, off = true }

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then
			dst[k] = type(v) == "table" and CopyDefaults({}, v) or v
		end
	end
	return dst
end

function ns.Print(msg)
	print("|cff66ccffLeboof|r: " .. msg)
end

function ns.Version()
	local v = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "?"
	return "v" .. v .. (ns.build and (" build " .. ns.build) or "")
end

-- The catalogue by key, and each entry's spell IDs (from Data.lua) as a set and a list.
ns.byKey = {}
for _, e in ipairs(ns.Catalogue) do
	ns.byKey[e.key] = e
	if e.names then
		e.ids, e.idList = {}, {}
		for _, name in ipairs(e.names) do
			for _, id in ipairs(ns.SpellIDs[name] or {}) do
				if not e.ids[id] then
					e.ids[id] = true
					e.idList[#e.idList + 1] = id
				end
			end
		end
	end
	e.label = e.label or e.names[1]
end

-- True if the character knows any of the entry's spells.
local function Knows(e)
	if not e.idList then return false end
	for _, id in ipairs(e.idList) do
		if C_SpellBook.IsSpellKnown(id) then return true end
	end
	return false
end

function ns.DefaultMode(e)
	local _, class = UnitClass("player")
	local mode = (e.class and e.class[class]) or e.other or "off"
	if mode == "keep" and not e.enchant and e.class and e.class[class] == "keep" and not Knows(e) then
		mode = "up"
	end
	return mode
end

function ns.Mode(e)
	return ns.db.modes[e.key] or ns.DefaultMode(e)
end

-- The display can only be rebuilt out of combat (the game closes the aura buttons to addons
-- while auras are secret). Changes made in combat wait for it to end.
local pending = false
function ns.Refresh(quiet)
	if InCombatLockdown() then
		if not pending and not quiet then ns.Print("the change applies when combat ends.") end
		pending = true
		return
	end
	pending = false
	ns.Layout()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("SPELLS_CHANGED")
events:SetScript("OnEvent", function(_, event, arg)
	if event == "ADDON_LOADED" and arg == ADDON then
		LeboofCharDB = CopyDefaults(LeboofCharDB or {}, DEFAULTS)
		ns.db = LeboofCharDB
	elseif event == "PLAYER_LOGIN" then
		ns.Refresh(true)
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pending then ns.Refresh() end
	elseif event == "SPELLS_CHANGED" then
		-- Learning a spell can change a default ("keep" needs the spell known).
		if ns.built and not InCombatLockdown() then ns.Layout() end
	end
end)

-- Slash commands ---------------------------------------------------------------------------

local function ListBuffs()
	local rows = { keep = {}, up = {}, off = {} }
	for _, e in ipairs(ns.Catalogue) do
		local mode = ns.Mode(e)
		local text = e.key .. (ns.db.modes[e.key] and "*" or "")
		table.insert(rows[mode], text)
	end
	ns.Print("|cffffd100keep|r: " .. (#rows.keep > 0 and table.concat(rows.keep, ", ") or "none"))
	ns.Print("|cffffd100up|r: " .. (#rows.up > 0 and table.concat(rows.up, ", ") or "none"))
	ns.Print("|cffffd100off|r: " .. (#rows.off > 0 and table.concat(rows.off, ", ") or "none"))
	ns.Print("* = changed from the default. Set one with /leboof <buff> keep|up|off|default")
end

local function Help()
	ns.Print(ns.Version())
	ns.Print("/leboof list - the buffs and their modes")
	ns.Print("/leboof <buff> keep|up|off|default - keep: always has a place, dim red when missing; up: shown only while up")
	ns.Print("/leboof unlock | lock - move the icons")
	ns.Print("/leboof size <16-64> | gap <0-20>")
	ns.Print("/leboof reset - default modes, size and position")
end

SLASH_LEBOOF1 = "/leboof"
SLASH_LEBOOF2 = "/lbf"
SlashCmdList.LEBOOF = function(msg)
	local cmd, arg = strsplit(" ", strtrim(msg or ""):lower(), 2)
	if cmd == "" or cmd == "help" then
		Help()
	elseif cmd == "list" then
		ListBuffs()
	elseif cmd == "unlock" or cmd == "lock" then
		ns.db.locked = (cmd == "lock")
		ns.Refresh()
	elseif cmd == "size" or cmd == "gap" then
		local n = tonumber(arg)
		local lo, hi = 16, 64
		if cmd == "gap" then lo, hi = 0, 20 end
		if not n or n < lo or n > hi then
			ns.Print(cmd .. " takes a number from " .. lo .. " to " .. hi .. ".")
			return
		end
		ns.db[cmd] = math.floor(n + 0.5)
		ns.Refresh()
	elseif cmd == "reset" then
		local modes = ns.db.modes
		for k in pairs(modes) do modes[k] = nil end
		for k, v in pairs(DEFAULTS) do
			if type(v) ~= "table" then ns.db[k] = v end
		end
		ns.Refresh()
		ns.Print("reset.")
	elseif ns.byKey[cmd] then
		local e = ns.byKey[cmd]
		if arg == "default" then
			ns.db.modes[cmd] = nil
		elseif ns.MODES[arg or ""] then
			ns.db.modes[cmd] = (arg ~= ns.DefaultMode(e)) and arg or nil
		else
			ns.Print(e.label .. " is " .. ns.Mode(e) .. ". Use keep, up, off or default.")
			return
		end
		ns.Print(e.label .. ": " .. ns.Mode(e))
		ns.Refresh()
	else
		ns.Print("unknown command or buff '" .. cmd .. "'. /leboof list shows the buffs.")
	end
end

function Leboof_OnAddonCompartmentClick()
	Help()
end
