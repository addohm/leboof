-- Leboof: the buffs it can track. Each entry is matched by spell name: tools/gen_data.py writes
-- every spell ID with one of these names into Data.lua, so all ranks (and the group versions,
-- like Prayer of Fortitude) count as the same buff.
--
-- Modes:
--   keep  a fixed icon in the first row; when the buff is missing a dimmed red copy shows instead
--   up    shown in the second row only while the buff is up; the row closes its gaps
--   off   not shown
-- `class` gives the default mode for those classes; every other class has it off. So by default
-- each class sees its own buffs (self-buffs, procs, cooldowns, shields, HoTs) and nothing else.
-- A "keep" default only applies if the character knows one of the spell's IDs (so a level 10
-- druid without Omen of Clarity isn't shown it as missing); otherwise it falls back to "up".
-- `warn` is when the time left turns red, in seconds. `note` is shown in the options window's
-- tooltips: where a world buff comes from, or which race a racial is for. Sections are the headings in the options
-- window's Buffs tab; the order here is the order on screen.
local _, ns = ...

ns.Catalogue = {}

local function Section(name, entries)
	for _, e in ipairs(entries) do
		e.section = name
		ns.Catalogue[#ns.Catalogue + 1] = e
	end
end

Section("Class and group buffs", {
	{ key = "battleshout", names = { "Battle Shout" }, class = { WARRIOR = "keep" }, warn = 15 },
	{ key = "innerfire", names = { "Inner Fire" }, class = { PRIEST = "keep" }, warn = 60 },
	{ key = "fort", names = { "Power Word: Fortitude", "Prayer of Fortitude" }, class = { PRIEST = "keep" }, warn = 120 },
	{ key = "motw", names = { "Mark of the Wild", "Gift of the Wild" }, class = { DRUID = "keep" }, warn = 120 },
	{ key = "omen", names = { "Omen of Clarity" }, class = { DRUID = "keep" }, warn = 60 },
	{ key = "thorns", names = { "Thorns" }, class = { DRUID = "up" }, warn = 60 },
	{ key = "spirit", names = { "Divine Spirit", "Prayer of Spirit" }, class = { PRIEST = "keep" }, warn = 120 },
	{ key = "shadowprot", names = { "Shadow Protection", "Prayer of Shadow Protection" }, class = { PRIEST = "up" }, warn = 120 },
	{ key = "shadowguard", names = { "Shadowguard" }, class = { PRIEST = "keep" }, warn = 60, note = "Troll priests." },
	{ key = "touchofweakness", names = { "Touch of Weakness" }, class = { PRIEST = "keep" }, warn = 60, note = "Undead priests." },
	{ key = "intellect", names = { "Arcane Intellect", "Arcane Brilliance" }, warn = 120 },
	{ key = "might", names = { "Blessing of Might", "Greater Blessing of Might" }, warn = 60 },
	{ key = "wisdom", names = { "Blessing of Wisdom", "Greater Blessing of Wisdom" }, warn = 60 },
	{ key = "kings", names = { "Blessing of Kings", "Greater Blessing of Kings" }, warn = 60 },
})

Section("Procs and cooldowns", {
	{ key = "flurry", names = { "Flurry" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "enrage", names = { "Enrage" }, class = { WARRIOR = "up", DRUID = "up" }, warn = 3 },
	{ key = "bloodrage", names = { "Bloodrage" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "berserkerrage", names = { "Berserker Rage" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "deathwish", names = { "Death Wish" }, class = { WARRIOR = "up" }, warn = 5 },
	{ key = "recklessness", names = { "Recklessness" }, class = { WARRIOR = "up" }, warn = 5 },
	{ key = "sweeping", names = { "Sweeping Strikes" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "recklessswings", names = { "Reckless Swings" }, class = { WARRIOR = "up" }, warn = 2 },
	{ key = "goredrinker", names = { "Gore Drinker" }, class = { WARRIOR = "up" }, warn = 2 },
	{ key = "shieldblock", names = { "Shield Block" }, class = { WARRIOR = "up" }, warn = 2 },
	{ key = "shieldwall", names = { "Shield Wall" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "laststand", names = { "Last Stand" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "retaliation", names = { "Retaliation" }, class = { WARRIOR = "up" }, warn = 3 },
	{ key = "shadowform", names = { "Shadowform" }, class = { PRIEST = "up" }, warn = 0 },
	{ key = "innerfocus", names = { "Inner Focus" }, class = { PRIEST = "up" }, warn = 0 },
	{ key = "fade", names = { "Fade" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "spirittap", names = { "Spirit Tap" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "darkinspiration", names = { "Dark Inspiration" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "inspiration", names = { "Inspiration" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "divineaegis", names = { "Divine Aegis" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "prayerofmending", names = { "Prayer of Mending" }, class = { PRIEST = "up" }, warn = 5 },
	{ key = "elunesgrace", names = { "Elune's Grace" }, class = { PRIEST = "up" }, warn = 3, note = "Night elf priests." },
	{ key = "feedback", names = { "Feedback" }, class = { PRIEST = "up" }, warn = 3, note = "Human priests." },
	{ key = "darksacrifice", names = { "Dark Sacrifice" }, class = { PRIEST = "up" }, warn = 3, note = "Undead priests." },
	{ key = "clearcasting", names = { "Clearcasting" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "barkskin", names = { "Barkskin" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "naturesgrasp", names = { "Nature's Grasp" }, class = { DRUID = "up" }, warn = 5 },
	{ key = "dash", names = { "Dash" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "frenziedregen", names = { "Frenzied Regeneration" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "naturesswiftness", names = { "Nature's Swiftness" }, class = { DRUID = "up" }, warn = 0 },
	{ key = "naturesgrace", names = { "Nature's Grace" }, class = { DRUID = "up" }, warn = 1 },
	{ key = "eclipse", names = { "Eclipse" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "leaderofthepack", names = { "Leader of the Pack" }, class = { DRUID = "up" }, warn = 0 },
	{ key = "moonkinaura", names = { "Moonkin Aura" }, class = { DRUID = "up" }, warn = 0 },
	{ key = "wildgrowth", names = { "Wild Growth" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "powerinfusion", names = { "Power Infusion" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "innervate", names = { "Innervate" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "fearward", names = { "Fear Ward" }, class = { PRIEST = "up" }, warn = 30 },
	{ key = "shield", names = { "Power Word: Shield" }, class = { PRIEST = "up" }, warn = 5 },
	{ key = "renew", names = { "Renew" }, class = { PRIEST = "up" }, warn = 3 },
	{ key = "rejuv", names = { "Rejuvenation" }, class = { DRUID = "up" }, warn = 3 },
	{ key = "regrowth", names = { "Regrowth" }, class = { DRUID = "up" }, warn = 3 },
})

Section("World buffs", {
	{ key = "rallyingcry", names = { "Rallying Cry of the Dragonslayer" }, warn = 300,
		note = "From Onyxia's head (Onyxia's Lair opens Dec 9). No effect inside raids." },
	{ key = "warchief", names = { "Warchief's Blessing" }, warn = 300,
		note = "From Rend's head in Upper Blackrock Spire, which may not be in Forever: unconfirmed. No effect inside raids." },
	{ key = "songflower", names = { "Songflower Serenade" }, warn = 300, note = "Songflowers in Felwood. No effect inside raids." },
	{ key = "fengus", names = { "Fengus' Ferocity" }, warn = 300, note = "Dire Maul tribute run. No effect inside raids." },
	{ key = "moldar", names = { "Mol'dar's Moxie" }, warn = 300, note = "Dire Maul tribute run. No effect inside raids." },
	{ key = "slipkik", names = { "Slip'kik's Savvy" }, warn = 300, note = "Dire Maul tribute run. No effect inside raids." },
	{ key = "silithyst", names = { "Traces of Silithyst" }, warn = 120, note = "Turning in Silithyst in Silithus." },
	{ key = "sayge", label = "Sayge's Dark Fortune", warn = 300, names = {
		"Sayge's Dark Fortune of Damage", "Sayge's Dark Fortune of Agility", "Sayge's Dark Fortune of Intelligence",
		"Sayge's Dark Fortune of Spirit", "Sayge's Dark Fortune of Stamina", "Sayge's Dark Fortune of Strength",
		"Sayge's Dark Fortune of Armor", "Sayge's Dark Fortune of Resistance",
	}, note = "Sayge at the Darkmoon Faire. Whether the Faire runs in Forever is unconfirmed. No effect inside raids." },
})

-- Temporary weapon enchants (oils, sharpening stones). They always go at the end of the first
-- row; "up" leaves the place empty instead of showing the missing look.
Section("Weapon enchants", {
	{ key = "mainhand", enchant = "MainHand", label = "Main hand enchant", warn = 120 },
	{ key = "offhand", enchant = "OffHand", label = "Off hand enchant", warn = 120 },
})
