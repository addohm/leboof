-- Leboof: buffs the player adds. The aura containers can only match spell IDs of buffs on the
-- player, and only the buff's own ID. So buffs are added from the ones on the player right now
-- (read out of combat, with the HELPFUL filter the containers use): whatever is on that list is a
-- buff the game shows on you, with the exact ID it will see. Nothing can be typed in.
--
-- An added buff starts with the one ID it was seen with. Out of combat, whenever a buff with the
-- same name shows up with another ID (another rank, a group version), that ID is added too.
-- Added buffs live in the profile: ns.db.custom[key] = { name, icon, ids = { [id] = true }, warn, order }.
local _, ns = ...

local SECTION = "Added by you"

local function Secret(v)
	return (issecretvalue and issecretvalue(v)) or false
end

-- The warning time for an added buff: a tenth of its duration, from 3 s to 2 min; none if permanent.
local function WarnFor(duration)
	if not duration or duration <= 0 then return 0 end
	return math.max(3, math.min(120, math.floor(duration / 10)))
end

-- Entry objects for the added buffs, rebuilt when the profile's list changes.
local cache = {}
local function CustomEntries()
	local custom = ns.db.custom
	local entries = {}
	for key, c in pairs(custom) do
		local e = cache[key]
		if not e or e.data ~= c then
			e = { key = key, data = c, custom = true, section = SECTION }
			cache[key] = e
		end
		e.label, e.icon, e.warn, e.ids = c.name, c.icon, c.warn, c.ids
		e.idList = {}
		for id in pairs(c.ids) do e.idList[#e.idList + 1] = id end
		table.sort(e.idList)
		entries[#entries + 1] = e
	end
	table.sort(entries, function(a, b) return (a.data.order or 0) < (b.data.order or 0) end)
	return entries
end

-- Every buff Leboof can show: the built-in ones, then the ones added to this profile.
function ns.Entries()
	local list = {}
	for _, e in ipairs(ns.Catalogue) do list[#list + 1] = e end
	for _, e in ipairs(CustomEntries()) do list[#list + 1] = e end
	return list
end

function ns.Entry(key)
	if ns.byKey[key] then return ns.byKey[key] end
	if ns.db.custom[key] then
		for _, e in ipairs(CustomEntries()) do
			if e.key == key then return e end
		end
	end
end

-- The entry whose spell IDs include this one, if any.
function ns.EntryForSpell(spellID)
	for _, e in ipairs(ns.Entries()) do
		if e.ids and e.ids[spellID] then return e end
	end
end

-- The buffs on the player now, readable only out of combat. Returns a list of
-- { spellId, name, icon, duration }, or nil and the reason.
function ns.ReadBuffs()
	if InCombatLockdown() then return nil, "Your buffs can only be read out of combat." end
	local list = {}
	local ok = pcall(function()
		for i = 1, 255 do
			local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
			if a == nil then break end
			if not Secret(a) and not Secret(a.spellId) and not Secret(a.name) and a.spellId then
				list[#list + 1] = { spellId = a.spellId, name = a.name, icon = a.icon, duration = a.duration }
			end
		end
	end)
	if not ok then return nil, "The game won't let Leboof read your buffs right now." end
	return list
end

-- Adds a buff read by ReadBuffs. A buff in Leboof's own list is switched on instead (it already
-- covers every rank).
function ns.AddBuff(buff)
	local e = ns.EntryForSpell(buff.spellId)
	if e and not e.custom then
		local mode = ns.DefaultMode(e)
		ns.SetMode(e, mode ~= "off" and mode or "up")
		return true
	end
	if e then return nil, buff.name .. " is already added." end
	local custom = ns.db.custom
	local order = 0
	for _, c in pairs(custom) do order = math.max(order, c.order or 0) end
	local key = "c" .. buff.spellId
	custom[key] = {
		name = buff.name, icon = buff.icon, ids = { [buff.spellId] = true },
		warn = WarnFor(buff.duration), order = order + 1,
	}
	ns.Refresh()
	return true
end

-- Stops tracking a buff: an added one is deleted, a built-in one turned off.
function ns.RemoveBuff(e)
	if e.custom then
		ns.db.custom[e.key] = nil
		ns.db.modes[e.key] = nil
		ns.Refresh()
	else
		ns.SetMode(e, "off")
	end
end

-- Learns other IDs of added buffs by name, out of combat.
local function Learn()
	if not ns.db or not next(ns.db.custom) then return end
	local buffs = ns.ReadBuffs()
	if not buffs then return end
	local byName = {}
	for _, c in pairs(ns.db.custom) do byName[c.name] = c end
	local changed = false
	for _, b in ipairs(buffs) do
		local c = byName[b.name]
		if c and not c.ids[b.spellId] and not ns.EntryForSpell(b.spellId) then
			c.ids[b.spellId] = true
			changed = true
		end
	end
	if changed then ns.Refresh(true) end
end

-- UNIT_AURA on the player, out of combat only, at most once a second: learn IDs, and refresh the
-- options window (its list of current buffs).
local scheduled = false
local function OnAurasChanged()
	scheduled = false
	if InCombatLockdown() or not ns.db then return end
	Learn()
	if ns.Window then ns.Window.Refresh() end
end

local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
	if InCombatLockdown() or scheduled then return end
	scheduled = true
	C_Timer.After(1, OnAurasChanged)
end)
