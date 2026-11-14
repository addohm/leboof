-- A small fake WoW client for Leboof's tests. Frames accept any method call; aura containers
-- check what Blizzard's CustomAuraContainer checks (unique slot/group keys, known keys, valid
-- filter strings) and record what the addon asked for.
local M = { printed = {}, combat = false, class = "WARRIOR", known = {}, frames = {} }

-- Unknown methods (capitalised names) do nothing; unknown fields are nil, as on a real frame.
local function Permissive(t)
	return setmetatable(t, { __index = function(_, k)
		if type(k) == "string" and k:match("^%u") then return function() return nil end end
	end })
end

local function NewFrame(kind, name)
	local f = { kind = kind, name = name, shown = true, points = {}, scripts = {}, events = {}, level = 1, w = 0, h = 0 }
	function f:Show()
		local was = self.shown
		self.shown = true
		if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
	end
	function f:Hide() self.shown = false end
	function f:SetShown(v) self.shown = v and true or false end
	function f:IsShown() return self.shown end
	function f:SetSize(w, h) self.w, self.h = w, h end
	function f:GetSize() return self.w, self.h end
	function f:SetWidth(w) self.w = w end
	function f:SetHeight(h) self.h = h end
	function f:GetWidth() return self.w end
	function f:GetHeight() return self.h end
	function f:GetCenter() return 0, 0 end
	function f:GetEffectiveScale() return 1 end
	function f:GetChecked() return self.checked end
	function f:SetText(t) self.text = t end
	function f:GetText() return self.text end
	function f:SetChecked(v) self.checked = v end
	function f:ClearAllPoints() self.points = {} end
	function f:SetPoint(...) table.insert(self.points, { ... }) end
	function f:GetPoint() local p = self.points[1] or {} return p[1], nil, p[3], p[4], p[5] end
	function f:GetFrameLevel() return self.level end
	function f:SetFrameLevel(l) self.level = l end
	function f:SetScript(event, fn) self.scripts[event] = fn end
	function f:RegisterEvent(e) self.events[e] = true end
	function f:RegisterUnitEvent(e) self.events[e] = true end
	function f:SetAlpha(a) self.alpha = a end
	function f:CreateTexture()
		local t = Permissive({})
		function t:SetDesaturated(v) self.desaturated = v end
		function t:SetTexture(v) self.texture = v end
		return t
	end
	function f:CreateAnimationGroup()
		local g = Permissive({ animations = {}, playing = false })
		function g:CreateAnimation(kind)
			local a = Permissive({ kind = kind })
			table.insert(self.animations, a)
			return a
		end
		function g:Play() self.playing = true end
		function g:Stop() self.playing = false end
		function g:IsPlaying() return self.playing end
		return g
	end
	-- Aura buttons record the animations handed to them.
	f.shownAnims, f.pandemicAnims, f.pandemicRegions = {}, {}, {}
	function f:AddAuraShownAnimation(g) table.insert(self.shownAnims, g) end
	function f:AddPandemicActiveAnimation(g) table.insert(self.pandemicAnims, g) end
	function f:AddPandemicRegion(r) table.insert(self.pandemicRegions, r) end
	function f:SetIcon(t) self.iconTexture = t end
	function f:SetDurationBar(bar, options) self.durationBar, self.durationBarOptions = bar, options end
	function f:SetMinMaxValues(lo, hi) self.min, self.max = lo, hi end
	function f:GetStatusBarTexture()
		self.fill = self.fill or Permissive({ isFill = true })
		return self.fill
	end
	function f:CreateFontString()
		local fs = Permissive({})
		function fs:SetText(t) self.text = t end
		function fs:GetText() return self.text end
		return fs
	end
	table.insert(M.frames, f)
	return Permissive(f)
end

local function NewButton(init)
	local b = NewFrame("AuraButton")
	if init then init(b) end
	return b
end

local function NewContainer()
	local c = NewFrame("AuraContainer")
	c.slots, c.groups, c.enchants = {}, {}, {}
	function c:SetUnit(u) self.unit = u end
	function c:AddAuraSlot(key, filter, options)
		assert(filter == "HELPFUL" or filter == "HARMFUL", "bad filter string")
		assert(not self.slots[key], "aura slot '" .. key .. "' already exists with this key.")
		assert(options.candidateFilters and options.candidateFilters.includeSpellIDs, "no spell IDs")
		local b = NewButton(options.initializeFrame)
		self.slots[key] = { button = b, filters = options.candidateFilters, enabled = true }
		return b
	end
	function c:SetAuraSlotCandidateFilters(key, filters)
		assert(self.slots[key], "aura slot '" .. key .. "' was not found with this key.")
		self.slots[key].filters = filters
	end
	function c:SetAuraSlotEnabled(key, enabled)
		assert(self.slots[key], "aura slot '" .. key .. "' was not found with this key.")
		assert(type(enabled) == "boolean")
		self.slots[key].enabled = enabled
	end
	function c:AddAuraGroup(key, filter, options)
		assert(filter == "HELPFUL" or filter == "HARMFUL", "bad filter string")
		assert(not self.groups[key], "aura group '" .. key .. "' already exists with this key.")
		self.groups[key] = { filters = options.candidateFilters, enabled = true, frames = {} }
		for i = 1, 10 do self.groups[key].frames[i] = NewButton(options.initializeFrame) end
	end
	local function Group(self, key)
		assert(self.groups[key], "aura group '" .. tostring(key) .. "' was not found with this key.")
		return self.groups[key]
	end
	function c:SetAuraGroupEnabled(key, enabled) assert(type(enabled) == "boolean") Group(self, key).enabled = enabled end
	function c:SetAuraGroupCandidateFilters(key, filters) Group(self, key).filters = filters end
	function c:SetAuraGroupLayout(key, layout) Group(self, key).layout = layout end
	function c:GetAuraGroupFrameCount(key) return #Group(self, key).frames end
	function c:GetAuraGroupFrame(key, i) return Group(self, key).frames[i] end
	function c:AddItemEnchantment(slot, options)
		assert(slot ~= nil, "itemEnchantmentSlot must be valid")
		assert(not self.enchants[slot], "item enchantment already exists with this slot.")
		local b = NewButton(options.initializeFrame)
		self.enchants[slot] = { button = b, enabled = true }
		return b
	end
	function c:SetItemEnchantmentEnabled(slot, enabled)
		assert(self.enchants[slot], "item enchantment was not found with this slot.")
		self.enchants[slot].enabled = enabled
	end
	M.containers = M.containers or {}
	table.insert(M.containers, c)
	return c
end

function CreateFrame(kind, name, parent, template)
	if kind == "AuraContainer" then
		assert(template == "CustomAuraContainerTemplate")
		return NewContainer()
	end
	local f = NewFrame(kind, name)
	f.parent = parent
	if kind == "DropdownButton" then
		function f:SetupMenu(generator) self.generator = generator end
	end
	if name then _G[name] = f end
	return f
end

-- Runs a dropdown's menu generator into a plain table: { buttons = { { text, items = { checkbox } } } },
-- each checkbox { text, isSelected, setSelected }.
function M.Menu(dropdown)
	return M.RunMenu(function(root) dropdown.generator(dropdown, root) end)
end

-- Runs a menu generator(root) into the same kind of table; radios are kept with the checkboxes.
function M.RunMenu(generate)
	local function Description()
		local d = { buttons = {}, items = {} }
		function d:CreateButton(text)
			local sub = Description()
			sub.text = text
			table.insert(self.buttons, sub)
			return sub
		end
		function d:CreateCheckbox(text, isSelected, setSelected)
			local item = { text = text, isSelected = isSelected, setSelected = setSelected }
			function item:SetTooltip(fn) self.tooltip = fn end
			table.insert(self.items, item)
			return item
		end
		d.CreateRadio = d.CreateCheckbox
		function d:CreateTitle(text) self.title = text end
		return d
	end
	local root = Description()
	generate(root)
	return root
end

UIParent = NewFrame("Frame", "UIParent")
Minimap = NewFrame("Frame", "Minimap")
Minimap:SetSize(140, 140)
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
function GameTooltip_Hide() end
UISpecialFrames = {}
tinsert = table.insert
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function GetCursorPosition() return 0, 0 end
M.name, M.surname, M.realm = "Tester", "Smith", "Realm"
-- On Forever the second value is the surname.
function UnitName() return M.name, M.surname end
function GetRealmName() return M.realm end
YES, NO = "Yes", "No"
StaticPopupDialogs = {}
-- The test accepts popups with WM.Accept().
function StaticPopup_Show(which, text, _, data) M.popup = { which = which, text = text, data = data } end
function M.Accept()
	local p = assert(M.popup, "no popup shown")
	M.popup = nil
	StaticPopupDialogs[p.which].OnAccept(nil, p.data)
end
INVSLOT_MAINHAND, INVSLOT_OFFHAND = 16, 17
SlashCmdList = {}
Enum = {
	LuaCurveType = { Linear = 0, Step = 1 },
	DurationTextBindingProperty = { RemainingDuration = 0 },
	StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 },
	StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 },
}
AuraContainerSortMethod = { Default = 0, Expiration = 4 }
AuraContainerItemEnchantmentSlot = { MainHand = 0, OffHand = 1, Ranged = 2 }

C_AddOns = {
	IsAddOnLoaded = function() return true end,
	LoadAddOn = function() return true end,
	GetAddOnMetadata = function(_, field) if field == "Version" then return "0.0.0" end end,
}
-- The player's buffs (WM.buffs), readable out of combat only, as on Forever.
M.buffs = {}
C_UnitAuras = { GetAuraDataByIndex = function(unit, i, filter)
	assert(unit == "player" and filter == "HELPFUL")
	if M.combat then error("aura data is secret") end
	return M.buffs[i]
end }
-- A clock the tests move (WM.Advance). C_Timer.After runs at once; NewTimer and NewTicker wait
-- for WM.Advance.
M.now = 1000
function GetTime() return M.now end
M.timers = {}
C_Timer = {
	After = function(_, fn) fn() end,
	NewTimer = function(seconds, fn)
		local t = { at = M.now + seconds, fn = fn }
		function t:Cancel() self.cancelled = true end
		table.insert(M.timers, t)
		return t
	end,
	NewTicker = function(seconds, fn)
		local t = { at = M.now + seconds, every = seconds, fn = fn }
		function t:Cancel() self.cancelled = true end
		table.insert(M.timers, t)
		return t
	end,
}
function M.Advance(seconds)
	local target = M.now + seconds
	while true do
		local next
		for _, t in ipairs(M.timers) do
			if not t.cancelled and t.at <= target and (not next or t.at < next.at) then next = t end
		end
		if not next then break end
		M.now = next.at
		if next.every then next.at = next.at + next.every else next.cancelled = true end
		next.fn()
	end
	M.now = target
end
-- hooksecurefunc([table,] name, hook): the hook runs after the original.
function hooksecurefunc(t, name, hook)
	if type(t) == "string" then t, name, hook = _G, t, name end
	local original = t[name]
	t[name] = function(...)
		local a, b, c, d = original(...)
		hook(...)
		return a, b, c, d
	end
end
-- A call stack whose file names look like an addon's.
function debugstack(start)
	local tb = debug.traceback("", (start or 1) + 1)
	return (tb:gsub("([%w_]+%.lua):", "Interface/AddOns/Leboof/%1:"))
end
function date(fmt) return "12:00:00" end
ChatFontNormal = {}
-- Sounds played, by sound kit ID; SOUNDKIT maps each name to a made-up ID.
M.sounds = {}
SOUNDKIT = setmetatable({ READY_CHECK = 8960 }, { __index = function(_, name) return "kit:" .. name end })
function PlaySound(id) table.insert(M.sounds, id) end
function M.Played(name)
	for _, id in ipairs(M.sounds) do if id == SOUNDKIT[name] then return true end end
	return false
end
M.enchant = {}
function GetWeaponEnchantInfo()
	local e = M.enchant
	return e.main ~= nil, e.main, 0, 0, e.off ~= nil, e.off, 0, 0
end
C_CooldownViewer = { IsCooldownViewerAvailable = function() return false, "Turned off" end }
MenuUtil = { CreateContextMenu = function(owner, generator) M.contextMenu = { owner = owner, generator = generator } end }
C_SpellBook = { IsSpellKnown = function(id) return M.known[id] == true end }
C_Spell = { GetSpellTexture = function(id) return 100000 + id end }
C_CurveUtil = { CreateColorCurve = function()
	local curve = { points = {} }
	function curve:SetType(t) self.type = t end
	function curve:AddPoint(x, y) table.insert(self.points, { x, y }) end
	return curve
end }
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
function UnitClass() return "Class", M.class end
function InCombatLockdown() return M.combat end
function GetInventoryItemTexture() return 1234 end
function print(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
	table.insert(M.printed, table.concat(parts, " "))
end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function strsplit(sep, s, limit)
	local out, start = {}, 1
	while true do
		if limit and #out == limit - 1 then break end
		local i = s:find(sep, start, true)
		if not i then break end
		table.insert(out, s:sub(start, i - 1))
		start = i + #sep
	end
	table.insert(out, s:sub(start))
	return unpack(out)
end

-- Fires an event at every frame that registered it.
function M.Fire(event, ...)
	for _, f in ipairs(M.frames) do
		if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
	end
end

function M.Slash(msg) SlashCmdList.LEBOOF(msg) end

return M
