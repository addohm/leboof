-- Leboof: the icons. The addon never reads aura data. Blizzard's aura containers
-- (Blizzard_AuraContainer: CustomAuraContainerTemplate) are told which spell IDs to show on the
-- player, and the game fills the buttons itself, in combat too. Everything the addon decides
-- (which buffs, where, how big) is set up out of combat.
--
--   row 1 (keep): one fixed place per buff: Blizzard's button while the buff is up, our own dimmed
--                 red copy while it's missing. The copy sits in a "presence" frame the game
--                 squeezes to nothing while the buff is up (see PlaceExpired), so it's gone, not
--                 just covered, and a see-through icon doesn't pick up its red. No secret is read.
--                 Weapon enchants go at the end of the row, one small container each.
--   row 2 (up):   an aura group per warn time; the container lays the icons out and closes gaps.
-- Each button gets the glows and look chosen for its buff (ButtonStyler; Effects.lua has the settings).
local _, ns = ...

local anchor, mover
local keepContainer, upContainer
local slots = {}       -- key -> slot button (keep row)
local enchants = {}    -- key -> { container = , button = }
local upGroups = {}    -- group key -> true, for every up-row group made

local TEXCOORD = { 0.07, 0.93, 0.07, 0.93 }
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Time-left colour: red below `warn` seconds, white above, at `alpha` opacity above (the icon's
-- opacity while up) and full opacity below.
local function WarnCurve(warn, alpha)
	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(Enum.LuaCurveType.Step)
	curve:AddPoint(0, CreateColor(1, 0.25, 0.25, 1))
	curve:AddPoint(warn, CreateColor(1, 1, 1, alpha or 1))
	return curve
end

local function IconTexture(e)
	local texture = e.icon -- an added buff: the icon it was seen with
	if not texture and e.enchant then
		texture = GetInventoryItemTexture("player", e.enchant == "MainHand" and INVSLOT_MAINHAND or INVSLOT_OFFHAND)
	elseif not texture and e.idList and e.idList[1] then
		texture = C_Spell.GetSpellTexture(e.idList[1])
	end
	return texture or QUESTION
end


-- The warning glow (Glow.lua, any style and colour): the game shows it in its refresh window near
-- the end of the buff (the pandemic window), in combat too.
local function Margin(size)
	return math.ceil(size * 0.25) + 3 -- how far any glow style reaches past the icon
end

-- The refresh-window glow: the game shows it in its pandemic window. Only auras with a refresh
-- window get one, so this is for the second row (and buffs whose duration isn't known yet).
local function AddGlow(button, glow, color, size)
	local holder = CreateFrame("Frame", nil, button)
	holder:SetAllPoints(button)
	holder:SetFrameLevel(button:GetFrameLevel() + 3) -- above the icon's face
	local built = ns.Glow.Build(holder, glow, color, size)
	for _, region in ipairs(built.regions) do button:AddPandemicRegion(region) end
	for _, group in ipairs(built.groups) do button:AddPandemicActiveAnimation(group) end
end

-- The keep row's warning, at the warning time, in combat too. The game drives an invisible bar
-- from the buff's time left (SetDurationBar, RemainingTime): its fill shrinks k px a second. The
-- bar is placed so that the fill's end crosses the glow's area as the time left goes from
-- warn + T to warn (T = span / k: a fraction of a second, a few for hour-long buffs). A "window"
-- frame runs from the fill's end to the bar's end, inside a frame clipped to the glow's area: so
-- whatever is in it is hidden above the warning time and shown under it. In it: the warning glow,
-- and, if the icon is faded or grey while up (reveal), the real icon at full strength, so the
-- icon "returns to normal" at the warning time. As with the expired glow, the game does the sizing
-- with secret values and Leboof never learns them.
-- total: the buff's full duration (learned out of combat). Returns the window's host frame (its
-- icon texture in host.icon when revealing), or nil if it can't be timed.
local function AddTimedGlow(button, glow, color, size, warn, total, reveal)
	if (glow == "none" and not reveal) or not total or warn <= 0 or total - warn < 2 then return nil end
	local margin = Margin(size)
	local span = size + 2 * margin
	local k = math.min(span / 0.5, 100000 / total) -- px per second; caps the bar near 100000 px
	local bar = CreateFrame("StatusBar", nil, button)
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	bar:SetStatusBarColor(1, 1, 1, 0)
	bar:SetMinMaxValues(0, total)
	bar:SetSize(k * total, 1)
	bar:SetPoint("LEFT", button, "LEFT", -margin - k * warn, 0)
	button:SetDurationBar(bar, {
		direction = Enum.StatusBarTimerDirection.RemainingTime,
		interpolation = Enum.StatusBarInterpolation.Immediate,
	})
	local area = CreateFrame("Frame", nil, button)
	area:SetFrameLevel(button:GetFrameLevel() + 3) -- above the icon's face
	area:SetPoint("TOPLEFT", button, "TOPLEFT", -margin, margin)
	area:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", margin, -margin)
	area:SetClipsChildren(true)
	local window = CreateFrame("Frame", nil, area, "DisableUntrustedLayoutScriptsTemplate")
	window:SetHeight(span)
	window:SetPoint("LEFT", bar:GetStatusBarTexture(), "RIGHT")
	window:SetPoint("RIGHT", bar, "RIGHT", 1, 0)
	window:SetClipsChildren(true)
	local host = CreateFrame("Frame", nil, window)
	host:SetAllPoints(button)
	if reveal then
		local edge = host:CreateTexture(nil, "BACKGROUND")
		edge:SetPoint("TOPLEFT", -1, 1)
		edge:SetPoint("BOTTOMRIGHT", 1, -1)
		edge:SetColorTexture(0, 0, 0, 1)
		host.icon = host:CreateTexture(nil, "ARTWORK")
		host.icon:SetAllPoints()
		host.icon:SetTexCoord(unpack(TEXCOORD))
	end
	if glow ~= "none" then
		local built = ns.Glow.Build(host, glow, color, size)
		-- Its animations start with the buff; the clipping keeps them out of sight until the warning.
		for _, group in ipairs(built.groups) do button:AddAuraShownAnimation(group) end
	end
	return host
end

-- Returns the initializeFrame callback that builds a Blizzard aura button's parts. It runs once,
-- when the game creates the button, before the button is closed to addons.
-- total: for the keep row, the buff's full duration, to time the warning; else nil.
-- alpha, grey: how the icon looks while the buff is up (its opacity, and greyed or not), until the
-- warning: they go on the icon's "face" (border, icon, swipe), not on the glows or the timer above.
-- iconTexture: the buff's own icon, for the keep row's faded face (see below).
local function ButtonStyler(warn, swipe, glow, color, total, alpha, grey, iconTexture)
	return function(button)
		local size = ns.db.size
		alpha = alpha or 1
		local faded = alpha < 1 or grey
		button:SetSize(size, size)

		local face = CreateFrame("Frame", nil, button)
		face:SetAllPoints(button)
		face:SetFrameLevel(button:GetFrameLevel() + 1)
		face:SetAlpha(alpha)

		local edge = face:CreateTexture(nil, "BACKGROUND")
		edge:SetPoint("TOPLEFT", -1, 1)
		edge:SetPoint("BOTTOMRIGHT", 1, -1)
		edge:SetColorTexture(0, 0, 0, 1)

		local icon = face:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexCoord(unpack(TEXCOORD))
		icon:SetDesaturated(grey and true or false)

		if swipe then
			local cooldown = CreateFrame("Cooldown", nil, face, "CooldownFrameTemplate")
			cooldown:SetAllPoints()
			cooldown:SetDrawEdge(false)
			cooldown:SetReverse(true)
			cooldown:SetHideCountdownNumbers(true)
			button:SetDurationCooldown(cooldown)
		end

		-- The warning. Keep row with a known duration: timed (the glow, and, when faded, the real
		-- icon at full strength). Then the face shows the buff's own icon, faded, and the game fills
		-- the revealed one (one icon per button). Otherwise: the refresh-window glow, and the face
		-- goes back to full opacity in that window (grey can't be undone there).
		local host = AddTimedGlow(button, glow, color, size, warn, total, faded and iconTexture ~= nil)
		if host and host.icon then
			icon:SetTexture(iconTexture)
			button:SetIcon(host.icon)
		else
			button:SetIcon(icon)
			if not host then
				AddGlow(button, glow, color, size)
				if alpha < 1 then
					local restore = face:CreateAnimationGroup()
					restore:SetLooping("REPEAT")
					local full = restore:CreateAnimation("Alpha")
					full:SetFromAlpha(1)
					full:SetToAlpha(1)
					full:SetDuration(1)
					button:AddPandemicActiveAnimation(restore)
				end
			end
		end

		-- The timer and stacks sit above everything. The timer turns red, and back to full
		-- opacity, at the warning time (the game applies the colour curve in combat too).
		local top = CreateFrame("Frame", nil, button)
		top:SetAllPoints(button)
		top:SetFrameLevel(button:GetFrameLevel() + 6)
		local text = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		text:SetPoint("BOTTOM", 0, 1)
		local options
		if warn and warn > 0 then
			options = { textColor = { curve = WarnCurve(warn, alpha), property = Enum.DurationTextBindingProperty.RemainingDuration } }
		else
			text:SetAlpha(alpha)
		end
		button:SetDurationText(text, options)

		local count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		count:SetPoint("TOPRIGHT", -1, -1)
		count:SetAlpha(alpha)
		button:SetApplicationCount(count)
	end
end

-- Which animations a buff's button has. A button's animations are fixed when the game creates it,
-- so each combination gets its own slot, group or container (they're switched, never removed).
local function AnimKey(e)
	local Fx = ns.Fx
	return Fx.Get(e, "expiring") .. ":" .. Fx.Get(e, "expiringColor") .. ":" .. ns.db.size .. ":" .. Fx.Warn(e)
		.. ":" .. Fx.Get(e, "upAlpha") .. ":" .. tostring(Fx.Get(e, "upGrey"))
end

-- upRow: the second row's buttons, with a cooldown swipe.
local function Styler(e, warn, upRow)
	local Fx = ns.Fx
	local total = not upRow and not e.enchant and Fx.Duration(e) or nil
	return ButtonStyler(warn, upRow, Fx.Get(e, "expiring"), Fx.Get(e, "expiringColor"), total,
		Fx.Get(e, "upAlpha"), Fx.Get(e, "upGrey"), not upRow and IconTexture(e) or nil)
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
-- A dimmed red copy of a buff's icon: the "missing" look.
local function RedCopy(parent)
	local c = CreateFrame("Frame", nil, parent)
	c.border = c:CreateTexture(nil, "BACKGROUND")
	c.border:SetPoint("TOPLEFT", -1, 1)
	c.border:SetPoint("BOTTOMRIGHT", 1, -1)
	c.border:SetColorTexture(0.7, 0, 0, 1)
	c.icon = c:CreateTexture(nil, "ARTWORK")
	c.icon:SetAllPoints()
	c.icon:SetTexCoord(unpack(TEXCOORD))
	c.icon:SetDesaturated(true)
	c.icon:SetVertexColor(1, 0.4, 0.4)
	c:SetAlpha(0.8)
	return c
end


-- The expired glow. Blizzard's button covers the red copy while the buff is up, but a glow reaches
-- past the icon, so it needs hiding some other way. Each keep-row buff gets its own container
-- holding only that buff, with invisible buttons. A container sizes itself to its buttons: 1 px
-- wide while the buff is missing, `span` + 1 while it's up. The glow sits in a clipping frame
-- stretched from the container's right edge to the far side of the glow's area, so it's full
-- size while the buff is missing and nothing while it's up. The game does the sizing (the size
-- is secret); Blizzard allows anchoring our frames to a container when they're made with
-- DisableUntrustedLayoutScriptsTemplate.
-- The red copy sits in the same frame, so it's hidden with the glow while the buff is up. "Only when
-- missing" buffs have nothing else; "keep up" ones also have Blizzard's button for while it's up.
local presence = {} -- buff key -> { container, clip, host, copy, glow, slot (enchants) }

local function Invisible(button)
	button:SetSize(1, 1)
	button:EnableMouse(false)
end

local function Presence(e)
	local p = presence[e.key]
	if not p then
		p = { container = NewContainer() }
		if e.enchant then
			p.slot = AuraContainerItemEnchantmentSlot[e.enchant]
			p.container:AddItemEnchantment(p.slot, { initializeFrame = Invisible, hidePermanent = true })
		else
			p.container:AddAuraGroup("buff", "HELPFUL", {
				candidateFilters = { includeSpellIDs = e.ids },
				maxFrameCount = 1,
				initializeFrame = Invisible,
			})
		end
		p.clip = CreateFrame("Frame", nil, anchor, "DisableUntrustedLayoutScriptsTemplate")
		p.clip:SetClipsChildren(true)
		p.clip:SetFrameLevel(anchor:GetFrameLevel() + 2)
		p.host = CreateFrame("Frame", nil, p.clip)
		p.copy = RedCopy(p.host)
		p.copy:SetAllPoints(p.host)
		p.glow = CreateFrame("Frame", nil, p.host)
		p.glow:SetAllPoints(p.host)
		p.glow:SetFrameLevel(p.copy:GetFrameLevel() + 2) -- the glow above the copy
		presence[e.key] = p
	end
	return p
end

-- Places the red copy (copy = true) and the expired glow for a top-row buff whose icon is at x.
local function PlaceExpired(e, x, size, copy)
	local p = Presence(e)
	local margin = Margin(size)
	local span = size + 2 * margin
	if e.enchant then
		p.container:SetItemEnchantmentLayout({ elementWidth = span + 1, elementHeight = 1 })
		p.container:SetItemEnchantmentEnabled(p.slot, true)
	else
		p.container:SetAuraGroupCandidateFilters("buff", { includeSpellIDs = e.ids })
		p.container:SetAuraGroupLayout("buff", { elementWidth = span + 1, elementHeight = 1 })
		p.container:SetAuraGroupEnabled("buff", true)
	end
	p.container:ClearAllPoints()
	p.container:SetPoint("TOPLEFT", anchor, "TOPLEFT", x - margin - 1, margin)
	p.clip:ClearAllPoints()
	p.clip:SetPoint("TOPLEFT", p.container, "TOPRIGHT")
	p.clip:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", x + size + margin, -size - margin)
	p.clip:Show()
	p.host:ClearAllPoints()
	p.host:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, 0)
	p.host:SetSize(size, size)
	p.copy:SetShown(copy and true or false)
	if copy then p.copy.icon:SetTexture(IconTexture(e)) end
	ns.Glow.Show(p.glow, ns.Fx.Get(e, "missing"), ns.Fx.Get(e, "missingColor"), size)
end

local function HideExpired(key)
	local p = presence[key]
	if not p then return end
	p.clip:Hide()
	if p.slot then
		p.container:SetItemEnchantmentEnabled(p.slot, false)
	else
		p.container:SetAuraGroupEnabled("buff", false)
	end
end

-- slots and enchants are keyed "<buff key>/<animations>".
local function Slot(e, key)
	local button = slots[key]
	if not button then
		button = keepContainer:AddAuraSlot(key, "HELPFUL", {
			candidateFilters = { includeSpellIDs = e.ids },
			initializeFrame = Styler(e, ns.Fx.Warn(e), false),
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
			initializeFrame = Styler(e, ns.Fx.Warn(e), false),
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
		if mode == "keep" or mode == "missing" or (e.enchant and mode == "up") then count = count + 1 end
	end
	local step = size + gap
	local keepWidth = count > 0 and (count * step - gap) or 0
	local grow = db.grow
	local x = grow == "center" and -keepWidth / 2 or grow == "right" and -keepWidth or 0
	for pass = 1, 2 do
		for _, e in ipairs(entries) do
			if (pass == 1) == (e.enchant == nil) then
				local mode = ns.Mode(e)
				local placed = mode == "keep" or mode == "missing" or (e.enchant and mode == "up")
				if mode == "missing" then
					-- Only when missing: no Blizzard button, just the red copy and the expired
					-- glow, both in the frame the game squeezes to nothing while the buff is up.
					PlaceExpired(e, x, size, true)
					x = x + step
				elseif placed then
					-- Keep up: the same, plus Blizzard's button for while it's up. (A weapon enchant
					-- shown "up" only gets the button.)
					if mode == "keep" then PlaceExpired(e, x, size, true) else HideExpired(e.key) end
					-- The keep row's warning glow is timed from the buff's duration: part of the key.
					local key = e.key .. "/" .. AnimKey(e) .. ":" .. (e.enchant and 0 or ns.Fx.Duration(e) or 0)
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
					x = x + step
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
	for key in pairs(presence) do
		local e = ns.Entry(key)
		local mode = e and ns.Mode(e)
		if mode ~= "keep" and mode ~= "missing" then HideExpired(key) end
	end
	local upY = keepWidth > 0 and -(size + gap) or 0

	-- Row 2: up. One aura group per warn time and animations ("warn<w>/<animations>"), shortest
	-- warn first, so procs sit on the left.
	local groups = {}
	for _, e in ipairs(entries) do
		if not e.enchant and ns.Mode(e) == "up" then
			local w = ns.Fx.Warn(e)
			local key = "warn" .. w .. "/" .. AnimKey(e)
			local g = groups[key]
			if not g then
				g = { ids = {}, warn = w, entry = e }
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
				initializeFrame = Styler(g.entry, g.warn, true),
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

-- Weapon icons for the enchants' red copies follow the equipped weapon.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function()
	if ns.built and not InCombatLockdown() then ns.Layout() end
end)
