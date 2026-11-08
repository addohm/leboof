-- Leboof: the sound log (/leboof soundlog). While it's on, every sound any addon plays is logged
-- with the time, the sound's name (if it's a standard one) and the addon that played it, found
-- from the call stack. Leboof's own sounds also say why they played. The log is printed to chat,
-- kept in LeboofDB.soundlog (saved at /reload or logout), and shown in a window ready to copy.
-- It only watches: hooksecurefunc runs after the game has played the sound.
local _, ns = ...

local Log = {}
ns.SoundLog = Log

local MAX = 300
local hooked = false
local kitNames -- sound kit ID -> SOUNDKIT name, made when first needed

local function Data()
	LeboofDB.soundlog = LeboofDB.soundlog or { on = false, entries = {} }
	return LeboofDB.soundlog
end

local function KitName(id)
	if not kitNames then
		kitNames = {}
		for name, kit in pairs(SOUNDKIT or {}) do
			if type(kit) == "number" then kitNames[kit] = name end
		end
	end
	return kitNames[id]
end

-- The addon in the call stack that played the sound: the first AddOns path that isn't this file.
local function Source()
	local ok, stack = pcall(debugstack, 3)
	if not ok or type(stack) ~= "string" then return "unknown" end
	for line in stack:gmatch("[^\n]+") do
		if not line:find("SoundLog.lua", 1, true) then
			local addon = line:match("AddOns[/\\]([^/\\]+)")
			if addon then return addon end
		end
	end
	return "the game (no addon in the call stack)"
end

-- Set by Leboof just before it plays a sound, so its entry says why.
local reason

function Log.Reason(text)
	reason = Data().on and hooked and text or nil
end

local function Add(kind, what)
	local data = Data()
	if not data.on then return end
	local why = reason
	reason = nil
	local entry = string.format("%s %s%s: %s, from %s%s", date("%H:%M:%S"),
		InCombatLockdown() and "[combat] " or "", kind, what, Source(), why and (" (" .. why .. ")") or "")
	table.insert(data.entries, entry)
	while #data.entries > MAX do table.remove(data.entries, 1) end
	ns.Print("|cff999999sound|r " .. entry)
end

local function DescribeKit(id)
	local name = type(id) == "number" and KitName(id)
	return name and (name .. " (" .. id .. ")") or tostring(id)
end

local function Hook()
	if hooked then return end
	hooked = true
	hooksecurefunc("PlaySound", function(id) pcall(Add, "sound", DescribeKit(id)) end)
	hooksecurefunc("PlaySoundFile", function(file) pcall(Add, "sound file", tostring(file)) end)
	if C_Sound and C_Sound.PlaySoundWithOptions then
		-- Blizzard's Cooldown Manager alerts play this way.
		hooksecurefunc(C_Sound, "PlaySoundWithOptions", function(params)
			local id = type(params) == "table" and params.soundKitID
			pcall(Add, "sound", DescribeKit(id))
		end)
	end
	if C_VoiceChat and C_VoiceChat.SpeakText then
		hooksecurefunc(C_VoiceChat, "SpeakText", function(_, text) pcall(Add, "speech", tostring(text)) end)
	end
end

function Log.SetOn(on)
	Data().on = on
	if on then
		Hook()
		ns.Print("sound log on: every sound played is listed here, with the addon that played it. /leboof soundlog show to copy it, /leboof soundlog off to stop.")
	else
		ns.Print("sound log off. /leboof soundlog show still shows what was logged.")
	end
end

function Log.Clear()
	Data().entries = {}
	ns.Print("sound log cleared.")
end

-- A window with the log as text, selected, for Ctrl+C.
local window
function Log.Show()
	if not window then
		window = CreateFrame("Frame", "LeboofSoundLog", UIParent, "BackdropTemplate")
		window:SetSize(620, 360)
		window:SetPoint("CENTER")
		window:SetFrameStrata("DIALOG")
		window:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		window:SetBackdropColor(0.05, 0.06, 0.09, 0.96)
		window:SetBackdropBorderColor(0.6, 0.45, 0.15, 1)
		window:EnableMouse(true)
		window:SetMovable(true)
		window:RegisterForDrag("LeftButton")
		window:SetScript("OnDragStart", window.StartMoving)
		window:SetScript("OnDragStop", window.StopMovingOrSizing)
		tinsert(UISpecialFrames, "LeboofSoundLog")

		local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", 14, -12)
		title:SetText("Leboof sound log: Ctrl+C copies it (it's selected)")
		local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -2, -2)

		local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 14, -36)
		scroll:SetPoint("BOTTOMRIGHT", -32, 14)
		local box = CreateFrame("EditBox", nil, scroll)
		box:SetMultiLine(true)
		box:SetAutoFocus(false)
		box:SetFontObject(ChatFontNormal)
		box:SetWidth(560)
		box:SetScript("OnEscapePressed", function() window:Hide() end)
		scroll:SetScrollChild(box)
		window.box = box
	end
	local entries = Data().entries
	local text = #entries > 0 and table.concat(entries, "\n") or "Nothing logged yet. /leboof soundlog turns the log on."
	window.box:SetText(text)
	window:Show()
	window.box:SetFocus()
	window.box:HighlightText()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	if Data().on then Hook() end
end)
