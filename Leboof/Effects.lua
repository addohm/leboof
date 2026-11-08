-- Leboof: animations and sounds.
--
-- Animations are handed to Blizzard's aura buttons (Display.lua), which play them in combat too:
-- a pop or flash when a buff appears, a pulsing glow in the game's refresh window (the end of the
-- buff), and a pulse on the keep row's red copy (it only shows while the buff is missing).
--
-- Sounds need to know when something happened, and in combat addons can't. So:
--   out of combat   the player's buffs are readable: sounds when a buff is gained, drops, or runs
--                   low (under its warning time), and a warning on entering combat with a "keep
--                   up" buff missing (from the last out-of-combat look)
--   in combat       a sound shortly before a buff you cast yourself should end, timed from the
--                   cast (UNIT_SPELLCAST_SUCCEEDED is readable) with the duration last seen out of
--                   combat; a guess, wrong if the buff ends early. Blizzard's Cooldown Manager can
--                   play sounds when a buff is applied or removed: Leboof only points there.
--
-- Settings: ns.db.effects holds the defaults, ns.db.fx[key] a buff's own choices (nil = default).
local _, ns = ...

local Fx = {}
ns.Fx = Fx

Fx.SOUNDS = {
	{ "none", "None" },
	{ "RAID_WARNING", "Raid warning" },
	{ "READY_CHECK", "Ready check" },
	{ "RAID_BOSS_EMOTE_WARNING", "Boss emote" },
	{ "UI_RAID_BOSS_WHISPER_WARNING", "Boss whisper" },
	{ "ALARM_CLOCK_WARNING_3", "Alarm clock" },
	{ "TELL_MESSAGE", "Whisper" },
	{ "MAP_PING", "Map ping" },
}
Fx.GAINED = { { "none", "None" }, { "pop", "Pop" }, { "flash", "Flash" } }
Fx.LEADS = { { 3, "3 s" }, { 5, "5 s" }, { 10, "10 s" }, { 15, "15 s" }, { 30, "30 s" } }

local function Label(list, value)
	for _, v in ipairs(list) do
		if v[1] == value then return v[2] end
	end
	return tostring(value)
end
Fx.Label = Label

function Fx.Play(name)
	local id = name and name ~= "none" and SOUNDKIT and SOUNDKIT[name]
	if id then PlaySound(id, "Master") end
end

-- A buff's setting: its own choice, else the default for its row.
--   gained                              the animation when it appears
--   expiring, expiringColor             the warning glow near the end (Glow.STYLES, Glow.COLORS)
--   missing, missingColor               the expired glow on the red copy
--   sGained, sLost, sExpiring, sCombat  out-of-combat sounds (sCombat: entering combat without it)
--   sCast                               the sound before your own cast runs out
function Fx.Default(e, field)
	local d = ns.db.effects
	local keep = ns.Mode(e) == "keep"
	if field == "gained" then return d.gained end
	if field == "expiring" or field == "expiringColor" or field == "missing" or field == "missingColor" then
		return d[field]
	end
	if field == "sGained" then return keep and "none" or d.upGained end
	if field == "sLost" then return keep and d.keepLost or d.upLost end
	if field == "sExpiring" then return keep and d.keepExpiring or "none" end
	if field == "sCombat" then return keep and d.combatMissing or "none" end
	if field == "sCast" then return d.cast end
end

-- Before glow styles, the two glows were just on or off.
local OLD_GLOW = { on = "pulse", off = "none" }

function Fx.Get(e, field)
	local own = ns.db.fx[e.key]
	local value
	if own and own[field] ~= nil then value = own[field] else value = Fx.Default(e, field) end
	if field == "expiring" or field == "missing" then value = OLD_GLOW[value] or value end
	return value
end

-- value nil goes back to the default.
function Fx.Set(e, field, value)
	local fx = ns.db.fx
	fx[e.key] = fx[e.key] or {}
	fx[e.key][field] = value
	if next(fx[e.key]) == nil then fx[e.key] = nil end
	ns.Refresh()
end

-- Out of combat: what's up, and when it ends ---------------------------------------------------

local Secret = function(v) return (issecretvalue and issecretvalue(v)) or false end

-- key -> expiration time (0 for no time limit) for every tracked buff that's up; nil if unknown.
local state
local played = {} -- key -> the expiration a "running out" sound was played for

-- Learned durations, per character (talents change them): spellID -> seconds.
local function Durations()
	local all = LeboofDB.durations or {}
	LeboofDB.durations = all
	local me = ns.Profiles.CharKey()
	all[me] = all[me] or {}
	return all[me]
end

local function ReadState()
	local buffs = ns.ReadBuffs()
	if not buffs then return nil end
	local now = GetTime()
	local found = {}
	local durations = Durations()
	for _, b in ipairs(buffs) do
		local e = ns.EntryForSpell(b.spellId)
		if e and ns.Mode(e) ~= "off" then
			local exp = (b.expirationTime and b.expirationTime > 0) and b.expirationTime or 0
			found[e.key] = math.max(found[e.key] or 0, exp)
		end
		if b.duration and b.duration > 0 then durations[b.spellId] = b.duration end
	end
	-- Weapon enchants.
	local ok, hasMain, mainMs, _, _, hasOff, offMs = pcall(GetWeaponEnchantInfo)
	if ok and not Secret(hasMain) and not Secret(hasOff) then
		if hasMain and mainMs and ns.Mode(ns.byKey.mainhand) ~= "off" then found.mainhand = now + mainMs / 1000 end
		if hasOff and offMs and ns.Mode(ns.byKey.offhand) ~= "off" then found.offhand = now + offMs / 1000 end
	end
	return found
end

local function Compare(old, new)
	for _, e in ipairs(ns.Entries()) do
		local was, is = old[e.key], new[e.key]
		if is and not was then
			Fx.Play(Fx.Get(e, "sGained"))
		elseif was and not is then
			Fx.Play(Fx.Get(e, "sLost"))
		end
	end
end

-- Re-reads the buffs out of combat; quiet = take them as the new starting point, without sounds.
function Fx.Update(quiet)
	if InCombatLockdown() then return end
	local new = ReadState()
	if not new then return end
	if state and not quiet then Compare(state, new) end
	state = new
end

-- Every second out of combat: "running out" sounds, from the expirations last read.
local function CheckExpiring()
	if InCombatLockdown() or not state then return end
	local now = GetTime()
	for _, e in ipairs(ns.Entries()) do
		local exp = state[e.key]
		if exp and exp > 0 and played[e.key] ~= exp then
			local left = exp - now
			if left > 0 and left <= (e.warn or 0) then
				played[e.key] = exp
				Fx.Play(Fx.Get(e, "sExpiring"))
			end
		end
	end
end

-- Entering combat: one warning if a "keep up" buff was missing just before.
local function CombatStarted()
	if not state then return end
	local missing, sound = {}, nil
	for _, e in ipairs(ns.Entries()) do
		if ns.Mode(e) == "keep" and not state[e.key] then
			local s = Fx.Get(e, "sCombat")
			if s ~= "none" then
				missing[#missing + 1] = e.label
				sound = sound or s
			end
		end
	end
	if #missing > 0 then
		Fx.Play(sound)
		if ns.db.effects.combatChat then ns.Print("missing: " .. table.concat(missing, ", ")) end
	end
end

-- In combat: timed from your own casts ---------------------------------------------------------

local castTimers = {} -- key -> timer

local function OnCast(spellID)
	if Secret(spellID) then return end
	local e = ns.EntryForSpell(spellID)
	if not e or ns.Mode(e) == "off" then return end
	local sound = Fx.Get(e, "sCast")
	if sound == "none" then return end
	local duration = Durations()[spellID]
	if not duration then
		for _, id in ipairs(e.idList or {}) do
			duration = duration or Durations()[id]
		end
	end
	if not duration then return end -- not seen out of combat yet
	local lead = ns.db.effects.castLead
	if castTimers[e.key] then castTimers[e.key]:Cancel() end
	castTimers[e.key] = C_Timer.NewTimer(math.max(0, duration - lead), function()
		castTimers[e.key] = nil
		-- Out of combat the buff can be checked: skip if it's gone or was refreshed since.
		if not InCombatLockdown() and state then
			local exp = state[e.key]
			if not exp or exp - GetTime() > lead + 1 then return end
		end
		Fx.Play(sound)
	end)
end

-- Blizzard's Cooldown Manager ----------------------------------------------------------------

-- Whether the game's Cooldown Manager is available here, and if not, the game's reason.
function Fx.CooldownManager()
	if not (C_CooldownViewer and C_CooldownViewer.IsCooldownViewerAvailable) then
		return false, "This client has no Cooldown Manager."
	end
	local ok, available, reason = pcall(C_CooldownViewer.IsCooldownViewerAvailable)
	if not ok then return false, "The game wouldn't say." end
	return available, reason
end

function Fx.OpenCooldownManager()
	if not C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then
		pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
	end
	if CooldownViewerSettings and CooldownViewerSettings.TogglePanel then
		CooldownViewerSettings:TogglePanel()
		return true
	end
	ns.Print("couldn't open the Cooldown Manager's settings. Try /cdm.")
end

-- Events ---------------------------------------------------------------------------------------

local scheduled = false
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("WEAPON_ENCHANT_CHANGED")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:SetScript("OnEvent", function(_, event, _, _, spellID)
	if event == "PLAYER_LOGIN" then
		Fx.Update(true)
		C_Timer.NewTicker(1, CheckExpiring)
	elseif event == "PLAYER_REGEN_DISABLED" then
		CombatStarted()
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- What changed during the fight isn't announced: start again from what's up now.
		Fx.Update(true)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		OnCast(spellID)
	elseif not InCombatLockdown() and not scheduled then
		-- UNIT_AURA, WEAPON_ENCHANT_CHANGED: a moment later, so several changes count as one.
		scheduled = true
		C_Timer.After(0.2, function()
			scheduled = false
			Fx.Update()
		end)
	end
end)
