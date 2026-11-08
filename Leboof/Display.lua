-- Leboof: the icons. The addon never reads aura data. Blizzard's aura containers
-- (Blizzard_AuraContainer: CustomAuraContainerTemplate) are told which spell IDs to show on the
-- player, and the game fills the buttons itself, in combat too. Everything the addon decides
-- (which buffs, where, how big) is set up out of combat.
--
--   row 1 (keep): one fixed place per buff. Behind each place sits our own dimmed red copy of
--                 the icon. When the buff is up, Blizzard's button covers it; when it's missing,
--                 the button hides and the copy shows through. No secret is read for this.
--                 Weapon enchants go at the end of the row, one small container each.
--   row 2 (up):   an aura group per warn time; the container lays the icons out and closes gaps.
-- Each button gets the animations chosen for its buff (AddAnimations; Effects.lua has the settings).
local _, ns = ...

local anchor, mover
local keepContainer, upContainer
local slots = {}       -- key -> slot button (keep row)
local enchants = {}    -- key -> { container = , button = }
local holders = {}     -- key -> our placeholder frame (keep row)
local upGroups = {}    -- group key -> true, for every up-row group made

local TEXCOORD = { 0.07, 0.93, 0.07, 0.93 }
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Time-left colour: red below `warn` seconds, white above.
local function WarnCurve(warn)
	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(Enum.LuaCurveType.Step)
	curve:AddPoint(0, CreateColor(1, 0.25, 0.25, 1))
	curve:AddPoint(warn, CreateColor(1, 1, 1, 1))
	return curve
end

local GLOW = { 1, 0.82, 0 }

-- Animations the game plays itself (Effects.lua). gained: "pop" (the icon grows in) or "flash"
-- (a white flash) when the buff appears. expiring "on": a pulsing gold edge in the game's refresh
-- window near the end of the buff (the pandemic window).
local function AddAnimations(button, gained, expiring)
	if gained == "pop" then
		local group = button:CreateAnimationGroup()
		local scale = group:CreateAnimation("Scale")
		scale:SetScaleFrom(1.6, 1.6)
		scale:SetScaleTo(1, 1)
		scale:SetDuration(0.25)
		scale:SetSmoothing("OUT")
		button:AddAuraShownAnimation(group)
	elseif gained == "flash" then
		local flash = button:CreateTexture(nil, "OVERLAY", nil, 7)
		flash:SetAllPoints()
		flash:SetColorTexture(1, 1, 1, 1)
		flash:SetBlendMode("ADD")
		flash:SetAlpha(0)
		local group = button:CreateAnimationGroup()
		local fade = group:CreateAnimation("Alpha")
		fade:SetTarget(flash)
		fade:SetFromAlpha(0.9)
		fade:SetToAlpha(0)
		fade:SetDuration(0.5)
		button:AddAuraShownAnimation(group)
	end

	if expiring == "on" then
		local group = button:CreateAnimationGroup()
		group:SetLooping("BOUNCE")
		local edges = {
			{ "TOPLEFT", -3, 3, "TOPRIGHT", 3, 1 }, { "BOTTOMLEFT", -3, -1, "BOTTOMRIGHT", 3, -3 },
			{ "TOPLEFT", -3, 3, "BOTTOMLEFT", -1, -3 }, { "TOPRIGHT", 1, 3, "BOTTOMRIGHT", 3, -3 },
		}
		for _, p in ipairs(edges) do
			local edge = button:CreateTexture(nil, "OVERLAY", nil, 6)
			edge:SetPoint(p[1], p[2], p[3])
			edge:SetPoint(p[4], p[5], p[6])
			edge:SetColorTexture(GLOW[1], GLOW[2], GLOW[3], 1)
			button:AddPandemicRegion(edge)
			local pulse = group:CreateAnimation("Alpha")
			pulse:SetTarget(edge)
			pulse:SetFromAlpha(1)
			pulse:SetToAlpha(0.2)
			pulse:SetDuration(0.5)
		end
		button:AddPandemicActiveAnimation(group)
	end
end

-- Returns the initializeFrame callback that builds a Blizzard aura button's parts. It runs once,
-- when the game creates the button, before the button is closed to addons.
local function ButtonStyler(warn, swipe, gained, expiring)
	return function(button)
		local size = ns.db.size
		button:SetSize(size, size)

		local border = button:CreateTexture(nil, "BACKGROUND")
		border:SetPoint("TOPLEFT", -1, 1)
		border:SetPoint("BOTTOMRIGHT", 1, -1)
		border:SetColorTexture(0, 0, 0, 1)

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexCoord(unpack(TEXCOORD))
		button:SetIcon(icon)

		if swipe then
			local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			cooldown:SetAllPoints()
			cooldown:SetDrawEdge(false)
			cooldown:SetReverse(true)
			cooldown:SetHideCountdownNumbers(true)
			button:SetDurationCooldown(cooldown)
		end

		local text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		text:SetPoint("BOTTOM", 0, 1)
		local options
		if warn and warn > 0 then
			options = { textColor = { curve = WarnCurve(warn), property = Enum.DurationTextBindingProperty.RemainingDuration } }
		end
		button:SetDurationText(text, options)

		local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		count:SetPoint("TOPRIGHT", -1, -1)
		button:SetApplicationCount(count)

		AddAnimations(button, gained, expiring)
	end
end

-- Which animations a buff's button has. A button's animations are fixed when the game creates it,
-- so each combination gets its own slot, group or container (they're switched, never removed).
local function AnimKey(e)
	return ns.Fx.Get(e, "gained") .. ":" .. ns.Fx.Get(e, "expiring")
end

local function NewContainer()
	local c = CreateFrame("AuraContainer", nil, anchor, "CustomAuraContainerTemplate")
	c:SetUnit("player")
	c:SetFrameLevel(anchor:GetFrameLevel() + 5)
	c:SetSize(1, 1)
	c:Show()
	return c
end

local function SavePosition()
	local point, _, _, x, y = anchor:GetPoint()
	ns.db.point, ns.db.x, ns.db.y = point, x, y
end

-- Creates the frames that never change. False if the game's aura containers aren't available.
local function Build()
	if ns.built then return true end
	if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
		pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
	end

	anchor = CreateFrame("Frame", "LeboofAnchor", UIParent)
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(true)
	anchor:SetSize(1, 1)

	local ok, err = pcall(function()
		keepContainer = NewContainer()
		keepContainer:SetPoint("TOPLEFT", anchor, "TOPLEFT")
		upContainer = NewContainer()
	end)
	if not ok then
		ns.Print("the game's aura containers aren't available, so nothing can be shown: " .. tostring(err))
		return false
	end

	-- Shown while unlocked: covers both rows and takes the drag.
	mover = CreateFrame("Frame", nil, anchor)
	mover:SetFrameLevel(anchor:GetFrameLevel() + 50)
	mover:EnableMouse(true)
	mover:RegisterForDrag("LeftButton")
	mover:SetScript("OnDragStart", function() anchor:StartMoving() end)
	mover:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing()
		SavePosition()
	end)
	local bg = mover:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.2, 0.6, 1, 0.35)
	local label = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("BOTTOM", mover, "TOP", 0, 2)
	label:SetText("Leboof: drag to move, /leboof lock when done")
	mover:Hide()

	ns.built = true
	return true
end

-- Our own "missing" icon for a keep-row place.
local function Holder(e)
	local h = holders[e.key]
	if not h then
		h = CreateFrame("Frame", nil, anchor)
		h:SetFrameLevel(anchor:GetFrameLevel() + 1)
		h.border = h:CreateTexture(nil, "BACKGROUND")
		h.border:SetPoint("TOPLEFT", -1, 1)
		h.border:SetPoint("BOTTOMRIGHT", 1, -1)
		h.border:SetColorTexture(0.7, 0, 0, 1)
		h.icon = h:CreateTexture(nil, "ARTWORK")
		h.icon:SetAllPoints()
		h.icon:SetTexCoord(unpack(TEXCOORD))
		h.icon:SetDesaturated(true)
		h.icon:SetVertexColor(1, 0.4, 0.4)
		h:SetAlpha(0.8)
		-- The pulse only shows while the buff is missing: Blizzard's button covers it otherwise.
		h.pulse = h:CreateAnimationGroup()
		h.pulse:SetLooping("BOUNCE")
		local fade = h.pulse:CreateAnimation("Alpha")
		fade:SetFromAlpha(1)
		fade:SetToAlpha(0.35)
		fade:SetDuration(0.7)
		holders[e.key] = h
	end
	if ns.Fx.Get(e, "missing") == "on" then
		if not h.pulse:IsPlaying() then h.pulse:Play() end
	else
		h.pulse:Stop()
	end
	local texture = e.icon -- an added buff: the icon it was seen with
	if not texture and e.enchant then
		texture = GetInventoryItemTexture("player", e.enchant == "MainHand" and INVSLOT_MAINHAND or INVSLOT_OFFHAND)
	elseif not texture and e.idList and e.idList[1] then
		texture = C_Spell.GetSpellTexture(e.idList[1])
	end
	h.icon:SetTexture(texture or QUESTION)
	return h
end

-- slots and enchants are keyed "<buff key>/<animations>".
local function Slot(e, key)
	local button = slots[key]
	if not button then
		button = keepContainer:AddAuraSlot(key, "HELPFUL", {
			candidateFilters = { includeSpellIDs = e.ids },
			initializeFrame = ButtonStyler(e.warn, false, ns.Fx.Get(e, "gained"), ns.Fx.Get(e, "expiring")),
		})
		slots[key] = button
	end
	return button
end

local function Enchant(e, key)
	local en = enchants[key]
	if not en then
		en = { container = NewContainer(), slot = AuraContainerItemEnchantmentSlot[e.enchant] }
		en.button = en.container:AddItemEnchantment(en.slot, {
			initializeFrame = ButtonStyler(e.warn, false, ns.Fx.Get(e, "gained"), ns.Fx.Get(e, "expiring")),
			hidePermanent = true,
		})
		enchants[key] = en
	end
	return en
end

local function Place(frame, x, y, size)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, y)
	frame:SetSize(size, size)
end

local function Layout()
	if not Build() then return end
	local db = ns.db
	local size, gap = db.size, db.gap

	anchor:ClearAllPoints()
	anchor:SetPoint(db.point, UIParent, db.point, db.x, db.y)

	-- Row 1: keep. Buffs first, then weapon enchants. The row grows from the anchor: to the right
	-- ("left"), both ways ("center") or to the left ("right").
	local entries = ns.Entries()
	local wanted = {} -- the slot and enchant keys in use; the rest are switched off below
	local count = 0
	for _, e in ipairs(entries) do
		local mode = ns.Mode(e)
		if mode == "keep" or (e.enchant and mode == "up") then count = count + 1 end
	end
	local keepWidth = count > 0 and (count * (size + gap) - gap) or 0
	local grow = db.grow
	local x = grow == "center" and -keepWidth / 2 or grow == "right" and -keepWidth or 0
	for pass = 1, 2 do
		for _, e in ipairs(entries) do
			if (pass == 1) == (e.enchant == nil) then
				local mode = ns.Mode(e)
				local placed = mode == "keep" or (e.enchant and mode == "up")
				if placed then
					local h = Holder(e)
					Place(h, x, 0, size)
					h:SetShown(mode == "keep")
					local key = e.key .. "/" .. AnimKey(e)
					wanted[key] = true
					if e.enchant then
						local en = Enchant(e, key)
						en.container:ClearAllPoints()
						en.container:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, 0)
						en.button:SetSize(size, size)
						en.container:SetItemEnchantmentEnabled(en.slot, true)
					else
						local button = Slot(e, key)
						-- Added buffs learn more IDs, so the filter is set again each time.
						keepContainer:SetAuraSlotCandidateFilters(key, { includeSpellIDs = e.ids })
						Place(button, x, 0, size)
						keepContainer:SetAuraSlotEnabled(key, true)
					end
					x = x + size + gap
				elseif holders[e.key] then
					holders[e.key]:Hide()
				end
			end
		end
	end
	-- Everything not placed this time goes: buffs off or removed, another profile's, or the
	-- buttons of a buff whose animations changed.
	for key in pairs(slots) do
		if not wanted[key] then keepContainer:SetAuraSlotEnabled(key, false) end
	end
	for key, en in pairs(enchants) do
		if not wanted[key] then en.container:SetItemEnchantmentEnabled(en.slot, false) end
	end
	local present = {}
	for _, e in ipairs(entries) do
		if ns.Mode(e) == "keep" or (e.enchant and ns.Mode(e) == "up") then present[e.key] = true end
	end
	for key, h in pairs(holders) do
		if not present[key] then h:Hide() end
	end
	local upY = keepWidth > 0 and -(size + gap) or 0

	-- Row 2: up. One aura group per warn time and animations ("warn<w>/<animations>"), shortest
	-- warn first, so procs sit on the left.
	local groups = {}
	for _, e in ipairs(entries) do
		if not e.enchant and ns.Mode(e) == "up" then
			local w = e.warn or 0
			local key = "warn" .. w .. "/" .. AnimKey(e)
			local g = groups[key]
			if not g then
				g = { ids = {}, warn = w, gained = ns.Fx.Get(e, "gained"), expiring = ns.Fx.Get(e, "expiring") }
				groups[key] = g
			end
			for id in pairs(e.ids) do g.ids[id] = true end
		end
	end
	local order = {}
	for key in pairs(groups) do order[#order + 1] = key end
	table.sort(order, function(a, b)
		if groups[a].warn ~= groups[b].warn then return groups[a].warn < groups[b].warn end
		return a < b
	end)
	for i, key in ipairs(order) do
		local g = groups[key]
		if not upGroups[key] then
			upContainer:AddAuraGroup(key, "HELPFUL", {
				candidateFilters = { includeSpellIDs = g.ids },
				initializeFrame = ButtonStyler(g.warn, true, g.gained, g.expiring),
				sortMethod = AuraContainerSortMethod.Expiration,
			})
			upGroups[key] = true
		end
		upContainer:SetAuraGroupCandidateFilters(key, { includeSpellIDs = g.ids })
		upContainer:SetAuraGroupLayout(key, {
			elementSpacing = gap, groupSpacing = gap,
			elementWidth = size, elementHeight = size, layoutIndex = i,
		})
		for n = 1, upContainer:GetAuraGroupFrameCount(key) do
			upContainer:GetAuraGroupFrame(key, n):SetSize(size, size)
		end
	end
	for key in pairs(upGroups) do
		upContainer:SetAuraGroupEnabled(key, groups[key] ~= nil)
	end
	-- The container sizes itself to its icons, so anchoring it by its top middle (or corner) is
	-- enough for the up row to grow the same way as the keep row.
	local GROW_POINTS = { left = "TOPLEFT", center = "TOP", right = "TOPRIGHT" }
	upContainer:ClearAllPoints()
	upContainer:SetPoint(GROW_POINTS[grow] or "TOP", anchor, "TOPLEFT", 0, upY)

	-- The mover covers the keep row and one up row.
	local moverWidth = math.max(keepWidth, size * 6 + gap * 5)
	local moverX = grow == "center" and -moverWidth / 2 or grow == "right" and -moverWidth or 0
	mover:ClearAllPoints()
	mover:SetPoint("TOPLEFT", anchor, "TOPLEFT", moverX - 2, 2)
	mover:SetSize(moverWidth + 4, -upY + size + 4)
	mover:SetShown(not db.locked)
end

function ns.Layout()
	local ok, err = pcall(Layout)
	if not ok then ns.Print("couldn't set up the icons: " .. tostring(err)) end
end

-- Weapon icons for the enchant placeholders follow the equipped weapon.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function()
	if not ns.built or InCombatLockdown() then return end
	for _, e in ipairs(ns.Catalogue) do
		if e.enchant and holders[e.key] then Holder(e) end
	end
end)
