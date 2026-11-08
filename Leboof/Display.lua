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
local _, ns = ...

local anchor, mover
local keepContainer, upContainer
local slots = {}       -- key -> slot button (keep row)
local enchants = {}    -- key -> { container = , button = }
local holders = {}     -- key -> our placeholder frame (keep row)
local upGroups = {}    -- warn seconds -> group key (up row)

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

-- Returns the initializeFrame callback that builds a Blizzard aura button's parts. It runs once,
-- when the game creates the button, before the button is closed to addons.
local function ButtonStyler(warn, swipe)
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
	end
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
		holders[e.key] = h
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

local function Slot(e)
	local button = slots[e.key]
	if not button then
		button = keepContainer:AddAuraSlot(e.key, "HELPFUL", {
			candidateFilters = { includeSpellIDs = e.ids },
			initializeFrame = ButtonStyler(e.warn, false),
		})
		slots[e.key] = button
	end
	return button
end

local function Enchant(e)
	local en = enchants[e.key]
	if not en then
		en = { container = NewContainer() }
		en.button = en.container:AddItemEnchantment(AuraContainerItemEnchantmentSlot[e.enchant], {
			initializeFrame = ButtonStyler(e.warn, false),
			hidePermanent = true,
		})
		enchants[e.key] = en
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

	-- Row 1: keep. Buffs first, then weapon enchants.
	local entries = ns.Entries()
	local x = 0
	for pass = 1, 2 do
		for _, e in ipairs(entries) do
			if (pass == 1) == (e.enchant == nil) then
				local mode = ns.Mode(e)
				local placed = mode == "keep" or (e.enchant and mode == "up")
				if placed then
					local h = Holder(e)
					Place(h, x, 0, size)
					h:SetShown(mode == "keep")
					if e.enchant then
						local en = Enchant(e)
						en.container:ClearAllPoints()
						en.container:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, 0)
						en.button:SetSize(size, size)
						en.container:SetItemEnchantmentEnabled(AuraContainerItemEnchantmentSlot[e.enchant], true)
					else
						local button = Slot(e)
						-- Added buffs learn more IDs, so the filter is set again each time.
						keepContainer:SetAuraSlotCandidateFilters(e.key, { includeSpellIDs = e.ids })
						Place(button, x, 0, size)
						keepContainer:SetAuraSlotEnabled(e.key, true)
					end
					x = x + size + gap
				else
					if holders[e.key] then holders[e.key]:Hide() end
					if slots[e.key] then keepContainer:SetAuraSlotEnabled(e.key, false) end
					if enchants[e.key] then
						enchants[e.key].container:SetItemEnchantmentEnabled(AuraContainerItemEnchantmentSlot[e.enchant], false)
					end
				end
			end
		end
	end
	-- Places of buffs that were removed (added buffs, or another profile's) go too.
	local present = {}
	for _, e in ipairs(entries) do present[e.key] = true end
	for key in pairs(slots) do
		if not present[key] then keepContainer:SetAuraSlotEnabled(key, false) end
	end
	for key, h in pairs(holders) do
		if not present[key] then h:Hide() end
	end
	local keepWidth = x > 0 and (x - gap) or 0
	local upY = keepWidth > 0 and -(size + gap) or 0

	-- Row 2: up. One aura group per warn time, shortest first, so procs sit on the left.
	local byWarn = {}
	for _, e in ipairs(entries) do
		if not e.enchant and ns.Mode(e) == "up" then
			local w = e.warn or 0
			byWarn[w] = byWarn[w] or {}
			for id in pairs(e.ids) do byWarn[w][id] = true end
		end
	end
	for w in pairs(byWarn) do
		if not upGroups[w] then
			local key = "warn" .. w
			upContainer:AddAuraGroup(key, "HELPFUL", {
				candidateFilters = { includeSpellIDs = byWarn[w] },
				initializeFrame = ButtonStyler(w, true),
				sortMethod = AuraContainerSortMethod.Expiration,
			})
			upGroups[w] = key
		end
	end
	for w, key in pairs(upGroups) do
		if byWarn[w] then
			upContainer:SetAuraGroupCandidateFilters(key, { includeSpellIDs = byWarn[w] })
			upContainer:SetAuraGroupLayout(key, {
				elementSpacing = gap, groupSpacing = gap,
				elementWidth = size, elementHeight = size, layoutIndex = w,
			})
			for i = 1, upContainer:GetAuraGroupFrameCount(key) do
				upContainer:GetAuraGroupFrame(key, i):SetSize(size, size)
			end
		end
		upContainer:SetAuraGroupEnabled(key, byWarn[w] ~= nil)
	end
	upContainer:ClearAllPoints()
	upContainer:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, upY)

	-- The mover covers the keep row and one up row.
	mover:ClearAllPoints()
	mover:SetPoint("TOPLEFT", anchor, "TOPLEFT", -2, 2)
	mover:SetSize(math.max(keepWidth, size * 6 + gap * 5) + 4, -upY + size + 4)
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
