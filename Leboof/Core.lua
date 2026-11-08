-- Leboof: settings, modes and events. All settings live in a profile (Profiles.lua); ns.db is the
-- profile the character uses, by default its own.
local ADDON, ns = ...

ns.ICON = "Interface\\AddOns\\Leboof\\Media\\Icon" -- art/make_logo.py

local DEFAULTS = {
	point = "CENTER", x = 0, y = -180, -- the anchor's position, relative to UIParent
	size = 32,                          -- icon size
	gap = 4,                            -- space between icons and between the two rows
	grow = "center",                    -- the rows grow from the anchor: "center", "left" or "right"
	locked = true,                      -- unlocked: the anchor can be dragged and shows a frame
	modes = {},                         -- key -> "keep" / "up" / "off", only where changed
	custom = {},                        -- buffs the player added (Custom.lua)
	effects = {                         -- animation and sound defaults (Effects.lua)
		gained = "pop", expiring = "pixel", expiringColor = "gold", missing = "pulse", missingColor = "red",
		keepLost = "RAID_WARNING", keepExpiring = "MAP_PING", combatMissing = "RAID_WARNING", combatChat = true,
		upGained = "none", upLost = "none",
		cast = "none", castLead = 5,
	},
	fx = {},                            -- key -> a buff's own animation and sound choices
	window = {},                        -- the options window: pos, size, tab
	minimap = { angle = 250, hide = false }, -- clear of Nothing Wasted (200) and Ticky (225)
}
ns.DEFAULTS = DEFAULTS

ns.MODES = { keep = true, up = true, off = true }

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then
			dst[k] = type(v) == "table" and CopyDefaults({}, v) or v
		elseif type(v) == "table" and type(dst[k]) == "table" then
			CopyDefaults(dst[k], v)
		end
	end
	return dst
end
ns.CopyDefaults = CopyDefaults

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
	if e.custom then return "up" end
	local _, class = UnitClass("player")
	local mode = (e.class and e.class[class]) or "off"
	if mode == "keep" and not e.enchant and e.class and e.class[class] == "keep" and not Knows(e) then
		mode = "up"
	end
	return mode
end

function ns.Mode(e)
	return ns.db.modes[e.key] or ns.DefaultMode(e)
end

-- Saves a mode; only modes that differ from the default are kept.
function ns.SetMode(e, mode)
	if mode == "default" then mode = nil end
	ns.db.modes[e.key] = (mode and mode ~= ns.DefaultMode(e)) and mode or nil
	ns.Refresh()
end

function ns.ResetModes()
	wipe(ns.db.modes)
end

function ns.ResetLayout()
	for k, v in pairs(DEFAULTS) do
		if type(v) ~= "table" then ns.db[k] = v end
	end
end

-- The icons can only be rebuilt out of combat (the game closes the aura buttons to addons while
-- auras are secret). Changes made in combat wait for it to end.
local pending = false
function ns.Refresh(quiet)
	if ns.Window then ns.Window.Refresh() end
	if InCombatLockdown() then
		if not pending and not quiet then ns.Print("the change applies when combat ends.") end
		pending = true
		return
	end
	pending = false
	ns.Layout()
	-- What's tracked may have changed: take the buffs that are up as the new starting point.
	if ns.Fx then ns.Fx.Update(true) end
end

function ns.SetLocked(locked)
	ns.db.locked = locked
	ns.Refresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("SPELLS_CHANGED")
events:SetScript("OnEvent", function(_, event, arg)
	if event == "ADDON_LOADED" and arg == ADDON then
		ns.Profiles.Init()
	elseif event == "PLAYER_LOGIN" then
		ns.Refresh(true)
		ns.Minimap.Init()
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
	for _, e in ipairs(ns.Entries()) do
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
	ns.Print("/leboof - open or close the options window")
	ns.Print("/leboof list - the buffs and their modes")
	ns.Print("/leboof <buff> keep|up|off|default - keep: always has a place, dim red when missing; up: shown only while up")
	ns.Print("/leboof unlock | lock - move the icons")
	ns.Print("/leboof size <16-64> | gap <0-20>")
	ns.Print("/leboof minimap - show or hide the minimap button")
	ns.Print("/leboof profile - the profile in use and the others (the Profiles tab manages them)")
	ns.Print("/leboof reset - default modes, size and position")
end

SLASH_LEBOOF1 = "/leboof"
SLASH_LEBOOF2 = "/lbf"
SlashCmdList.LEBOOF = function(msg)
	local cmd, arg = strsplit(" ", strtrim(msg or ""):lower(), 2)
	if cmd == "" then
		ns.Window.Toggle()
	elseif cmd == "help" then
		Help()
	elseif cmd == "list" then
		ListBuffs()
	elseif cmd == "unlock" or cmd == "lock" then
		ns.SetLocked(cmd == "lock")
	elseif cmd == "minimap" then
		ns.Minimap.SetShown(ns.db.minimap.hide)
	elseif cmd == "profile" then
		ns.Print("profile: " .. ns.Profiles.Current() .. ". All: " .. table.concat(ns.Profiles.Names(), ", "))
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
		ns.ResetModes()
		ns.ResetLayout()
		ns.Refresh()
		ns.Print("reset.")
	elseif ns.Entry(cmd) then
		local e = ns.Entry(cmd)
		if arg ~= "default" and not ns.MODES[arg or ""] then
			ns.Print(e.label .. " is " .. ns.Mode(e) .. ". Use keep, up, off or default.")
			return
		end
		ns.SetMode(e, arg)
		ns.Print(e.label .. ": " .. ns.Mode(e))
	else
		ns.Print("unknown command or buff '" .. cmd .. "'. /leboof help lists the commands.")
	end
end
