--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local _, ns = ...

-- Lua API
local bit_bor = bit.bor
local select, type = select, type

-- Setup Aura Environment
ns.AuraData = {
	Spells = {}, 			-- [spellID] = <bitFlags> (see Flags below)
	SpellParents = {}, 		-- [spellID] = <number> (spellID of parent spell)
	Priority = {}, 			-- [spellID] = <boolean,nil> (true/false)
	Hidden = {}, 			-- [spellID] = <boolean,nil> (true/false)
	Flags = {

		-- Crowd Control & Debuffs
		BUFF_HARM = 		2^0,
		BUFF_HELP = 		2^1,
		BUFF_OTHER = 		2^2,
		BUFF_SPEED_BOOST = 	2^3,
		DEBUFF_HARM = 		2^4,
		INTERRUPT = 		2^5,
		CC = 				2^6,
		ROOT = 				2^7,
		IMMUNITY = 			2^8,
		IMMUNITY_SPELL = 	2^9,

		-- General Damage & Healing
		DPS = 				2^10,
		HEAL = 				2^11

	},
	-- @input spellID <number> always first argument, must be there
	-- @input [spellType] <string> spell type identifier
	-- @input [spellParent] <number> spellID of parent spell (e.g multiple versions of polymorph)
	-- @input [isPriority[, isHidden]] <boolean,nil> adds to priority/hidden tables. comes as a pair.
	Add = function(spellID, ...)
		local spellType, spellParent, isPriority, isHidden

		-- Parse the input arguments
		for i = 1,select("#", ...) do
			local arg = select(i, ...)
			local t = type(arg)
			if (t == "number" and not spellParent) then
				spellParent = arg
			elseif (t == "string" and not spellType) then
				spellType = arg
			elseif (t == "boolean") then
				if (i > 1) then
					-- isHidden requires isPriority to be set prior
					local lastType = type((select(i-1, ...)))
					if (lastType == "nil" or lastType == "boolean") then
						isHidden = arg
					else
						isPriority = arg
					end
				else
					isPriority = arg
				end
			end
		end

		if (isPriority) then
			ns.AuraData.Priority[spellID] = true
		end

		if (isHidden) then
			ns.AuraData.Hidden[isHidden] = true
		end

		-- Add spellType bits using logical or
		-- to avoid double registrations canceling it out.
		if (spellType) then
			ns.AuraData.Spells[spellID] = bit_bor((ns.AuraData.Spells[spellID] or 0), ns.AuraData.Flags[spellType])
		end
	end
}

if (not ns.IsRetail) then return end

-- Speed!
local Add = ns.AuraData.Add

-- Priority
--------------------------------------------------
Add(117405, true) 						-- Binding Shot
Add(208997, true) 						-- Counterstrike Totem
Add(209749, true) 						-- Faerie Swarm
Add(375901, true) 						-- Mindgames
Add(343294, true) 						-- Soul Reaper (Unholy)
Add(122470, true) 						-- Touch of Karma
Add(316099, true) 						-- Unstable Affliction
Add(342938, true) 						-- Unstable Affliction
Add( 34914, true) 						-- Vampiric Touch

-- Interrupts
--------------------------------------------------
Add( 31935, "INTERRUPT") 				-- Avenger's Shield (Paladin)
Add(212619, "INTERRUPT") 				-- Call Felhunter (Warlock)
Add(147362, "INTERRUPT") 				-- Counter Shot (Hunter)
Add(  2139, "INTERRUPT") 				-- Counterspell (Mage)
Add(183752, "INTERRUPT") 				-- Disrupt (Demon Hunter)
Add(  1766, "INTERRUPT") 				-- Kick (Rogue)
Add( 47528, "INTERRUPT") 				-- Mind Freeze (Death Knight)
Add(187707, "INTERRUPT") 				-- Muzzle (Hunter)
Add(  6552, "INTERRUPT") 				-- Pummel (Warrior)
Add(351338, "INTERRUPT") 				-- Quell (Evoker)
Add( 96231, "INTERRUPT") 				-- Rebuke (Paladin)
Add( 91807, "INTERRUPT") 				-- Shambling Rush (Death Knight)
Add(217824, "INTERRUPT") 				-- Shield of Virtue (Protection PvP Talent)
Add( 93985, "INTERRUPT") 				-- Skull Bash (Feral/Guardian)
Add(116705, "INTERRUPT") 				-- Spear Hand Strike (Monk)
Add( 19647, "INTERRUPT") 				-- Spell Lock (Warlock)
Add(132409, "INTERRUPT") 				-- Spell Lock (Warlock)
Add( 57994, "INTERRUPT") 				-- Wind Shear (Shaman)

-- Death Knight
--------------------------------------------------
Add(383269, "BUFF_HARM") 				-- Abomination Limb
Add(377048, "CC") 						-- Absolute Zero
Add( 48707, "IMMUNITY_SPELL") 			-- Anti-Magic Shell
Add(145629, "BUFF_HELP") 				-- Anti-Magic Zone
Add(221562, "CC") 						-- Asphyxiate
Add(207167, "CC") 						-- Blinding Sleet
Add(194844, "BUFF_HELP") 				-- Bonestorm
Add(152279, "BUFF_HARM") 				-- Breath of Sindragosa
Add(288849, "DEBUFF_HARM") 				-- Crypt Fever (Necromancer's Bargain Unholy PvP Talent)
Add( 81256, "BUFF_HELP") 				-- Dancing Rune Weapon
Add( 77606, "DEBUFF_HARM") 				-- Dark Simulacrum
Add( 63560, "BUFF_HARM") 				-- Dark Transformation
Add(287254, "CC") 						-- Dead of Winter
Add( 48265, "BUFF_SPEED_BOOST") 		-- Death's Advance
Add(204080, "ROOT") 					-- Deathchill
Add(233395, "ROOT", 204080) 			-- Deathchill (Remorseless Winter)
Add(204085, "ROOT", 204080) 			-- Deathchill (Chains of Ice)
Add( 47568, "BUFF_HARM") 				-- Empower Rune Weapon
Add( 91800, "CC") 						-- Gnaw
Add( 91797, "CC", 91800) 				-- Gnaw (Monstrous Blow)
Add( 48792, "BUFF_HELP") 				-- Icebound Fortitude
Add( 49039, "BUFF_OTHER") 				-- Lichborne
Add(356528, "DEBUFF_HARM") 				-- Necrotic Wound
Add(  3714, "BUFF_OTHER") 				-- Path of Frost
Add( 51271, "BUFF_HARM") 				-- Pillar of Frost
Add(194679, "BUFF_HELP") 				-- Rune Tap
--Add( 91807, "ROOT") 					-- Shambling Rush (defined as Interrupt)
Add(343294, "DEBUFF_HARM") 				-- Soul Reaper
Add( 47476, "CC") 						-- Strangulate
Add(219809, "BUFF_HELP") 				-- Tombstone
Add(207289, "BUFF_HARM") 				-- Unholy Assault
Add( 55233, "BUFF_HELP") 				-- Vampiric Blood
Add(212552, "BUFF_SPEED_BOOST") 		-- Wraith Walk
Add(210141, "CC") 						-- Zombie Explosion (Reanimation Unholy PvP Talent)

-- Demon Hunter
--------------------------------------------------
Add(212800, "BUFF_HELP") 				-- Blur
Add(179057, "CC") 						-- Chaos Nova
Add(390195, "BUFF_HARM") 				-- Chaos Theory
Add(209426, "BUFF_HELP") 				-- Darkness
Add(205629, "BUFF_HELP") 				-- Demonic Trample
Add(213491, "CC") 						-- Demonic Trample (short stun on targets)
Add(320338, "DEBUFF_HARM") 				-- Essence Break
Add(211881, "CC") 						-- Fel Eruption
Add(354610, "IMMUNITY") 				-- Glimpse
Add(205630, "CC") 						-- Illidan's Grasp - Grab
Add(208618, "CC", 205630) 				-- Illidan's Grasp - Stun
Add(217832, "CC") 						-- Imprison
Add(221527, "CC", 217832) 				-- Imprison (PvP Talent)
Add(187827, "BUFF_HELP") 				-- Metamorphosis - Vengeance
Add(162264, "BUFF_HARM") 				-- Metamorphosis - Havoc
Add(196555, "IMMUNITY") 				-- Netherwalk
Add(206804, "BUFF_HARM") 				-- Rain from Above (down)
Add(206803, "IMMUNITY", 206804) 		-- Rain from Above (up)
Add(207685, "CC") 						-- Sigil of Misery
Add(204490, "CC") 						-- Sigil of Silence
Add(188501, "BUFF_HARM") 				-- Spectral Sight
Add(370970, "ROOT") 					-- The Hunt (Root)

-- Druid
--------------------------------------------------
Add( 22812, "BUFF_HELP") 				-- Barkskin
Add( 50334, "BUFF_HELP") 				-- Berserk (Guardian)
Add(106951, "BUFF_HARM") 				-- Berserk (Feral)
Add(145152, "BUFF_HARM") 				-- Bloodtalons
Add(155835, "BUFF_HELP") 				-- Bristling Fur
Add(194223, "BUFF_HARM") 				-- Celestial Alignment
Add(383410, "BUFF_HARM", 194223) 		-- Celestial Alignment (Orbital Strike)
Add(391528, "BUFF_HARM") 				-- Convoke the Spirits
Add( 33786, "CC") 						-- Cyclone
Add(  1850, "BUFF_SPEED_BOOST") 		-- Dash
Add(   339, "ROOT") 					-- Entangling Roots
Add(170855, "ROOT", 339) 				-- Entangling Roots (Nature's Grasp)
Add(209749, "CC") 						-- Faerie Swarm
Add(274838, "DEBUFF_HARM") 				-- Feral Frenzy
Add(197721, "BUFF_HELP") 				-- Flourish
Add( 22842, "BUFF_HELP") 				-- Frenzied Regeneration
Add(319454, "BUFF_HARM") 				-- Heart of the Wild
Add(108291, "BUFF_HARM", 319454) 		-- Heart of the Wild (Balance Affinity)
Add(108292, "BUFF_HARM", 319454) 		-- Heart of the Wild (Feral Affinity)
Add(108293, "BUFF_HARM", 319454) 		-- Heart of the Wild (Guardian Affinity)
Add(108294, "BUFF_HARM", 319454) 		-- Heart of the Wild (Resto Affinity)
Add(  2637, "CC") 						-- Hibernate
Add(200947, "DEBUFF_HARM") 				-- High Winds
Add( 45334, "ROOT") 					-- Immobilized (Wild Charge in Bear Form)
Add(    99, "CC") 						-- Incapacitating Roar
Add(102543, "BUFF_HARM") 				-- Incarnation: King of the Jungle
Add(102558, "BUFF_HARM") 				-- Incarnation: Guardian of Ursoc
Add( 33891, "BUFF_HARM") 				-- Incarnation: Tree of Life
Add(102560, "BUFF_HARM") 				-- Incarnation: Chosen of Elune
Add(390414, "BUFF_HARM", 102560) 		-- Incarnation: Chosen of Elune (Orbital Strike)
Add(117679, "BUFF_HARM", 33891) 		-- Incarnation (grants access to Tree of Life form)
Add( 58180, "DEBUFF_HARM") 				-- Infected Wounds
Add( 29166, "BUFF_HARM") 				-- Innervate
Add(102342, "BUFF_HELP") 				-- Ironbark
Add(362486, "IMMUNITY") 				-- Keeper of the Grove
Add(102359, "ROOT") 					-- Mass Entanglement
Add(203123, "CC") 						-- Maim
Add(  5211, "CC") 						-- Mighty Bash
Add(247563, "BUFF_HELP") 				-- Nature's Grasp (Resto Entangling Bark PvP Talent)
Add(132158, "BUFF_HARM") 				-- Nature's Swiftness
Add(202244, "CC") 						-- Overrun (Guardian PvP Talent)
Add(  5215, "BUFF_OTHER") 				-- Prowl
Add(200851, "IMMUNITY") 				-- Rage of the Sleeper
Add(163505, "CC") 						-- Rake
Add(410063, "DEBUFF_HARM") 				-- Reactive Resin (Snare for 2 stacks then root/silence at 3)
Add(410065, "CC") 						-- Reactive Resin (Root and Silence)
Add( 61336, "BUFF_HELP") 				-- Survival Instincts
Add( 81261, "CC") 						-- Solar Beam
Add(106898, "BUFF_SPEED_BOOST") 		-- Stampeding Roar (from Human Form)
Add( 77764, "BUFF_SPEED_BOOST", 106898) -- Stampeding Roar (from Cat Form)
Add( 77761, "BUFF_SPEED_BOOST", 106898) -- Stampeding Roar (from Bear Form)
Add(202347, "DEBUFF_HARM") 				-- Stellar Flare
Add(305497, "BUFF_HELP") 				-- Thorns (PvP Talent)
Add(252216, "BUFF_SPEED_BOOST", 1850) 	-- Tiger Dash
Add(  5217, "BUFF_HARM") 				-- Tiger's Fury
Add(127797, "CC") 						-- Ursol's Vortex
Add(202425, "BUFF_HARM") 				-- Warrior of Elune
Add(410406, "BUFF_HARM") 				-- Wild Attunement

-- Evoker
--------------------------------------------------
Add(403631, "IMMUNITY") 				-- Breath of Eons (Immune to CC)
Add(383005, "DEBUFF_HARM") 				-- Chrono Loop
Add(357210, "IMMUNITY") 				-- Deep Breath (Immune to CC)
Add(375087, "BUFF_HARM") 				-- Dragonrage
Add(359816, "IMMUNITY") 				-- Dream Flight (Immune to CC)
Add(370960, "BUFF_HELP") 				-- Emerald Communion
Add(358267, "BUFF_SPEED_BOOST") 		-- Hover
Add(355689, "ROOT") 					-- Landslide
Add(378464, "IMMUNITY") 				-- Nullifying Shroud
Add(363916, "BUFF_HELP") 				-- Obsidian Scales
Add(372048, "DEBUFF_HARM") 				-- Oppressing Roar
Add(374348, "BUFF_HELP") 				-- Renewing Blaze
Add(408544, "CC") 						-- Seismic Slam
Add(360806, "CC") 						-- Sleep Walk
Add(406732, "BUFF_HELP") 				-- Spatial Paradox
Add(372245, "CC") 						-- Terror of the Skies
Add(357170, "BUFF_HELP") 				-- Time Dilation
Add(404977, "BUFF_HELP") 				-- Time Skip
Add(378441, "IMMUNITY") 				-- Time Stop

-- Hunter
--------------------------------------------------
Add(131894, "DEBUFF_HARM") 				-- A Murder of Crows
Add(186257, "BUFF_SPEED_BOOST") 		-- Aspect of the Cheetah
Add(186289, "BUFF_HARM") 				-- Aspect of the Eagle
Add(186265, "IMMUNITY") 				-- Aspect of the Turtle
Add( 19574, "BUFF_HARM") 				-- Bestial Wrath
Add(186254, "BUFF_HARM", 19574) 		-- Bestial Wrath (on pet)
Add(117526, "CC") 						-- Binding Shot
Add(117405, "ROOT") 					-- Binding Shot (aura when you're in the area)
Add(321538, "DEBUFF_HARM") 				-- Bloodshed
Add(199483, "BUFF_OTHER") 				-- Camouflage
Add(360952, "BUFF_HARM") 				-- Coordinated Assault
Add(357021, "CC") 						-- Consecutive Concussion
Add(203337, "CC", 3355) 				-- Diamond Ice (Survival PvP Talent)
Add(393456, "ROOT") 					-- Entrapment
Add(212431, "DEBUFF_HARM") 				-- Explosive Shot
Add(  5384, "BUFF_HELP") 				-- Feign Death
Add(324149, "DEBUFF_HARM") 				-- Flayed Shot
Add(  3355, "CC") 						-- Freezing Trap
Add(190925, "ROOT") 					-- Harpoon
Add(203233, "BUFF_SPEED_BOOST", 186257) -- Hunting Pack (PvP Talent)
Add(248519, "IMMUNITY_SPELL") 			-- Interlope (BM PvP Talent)
Add( 24394, "CC") 						-- Intimidation
Add( 54216, "BUFF_HELP") 				-- Master's Call
Add(   136, "BUFF_HELP") 				-- Mend Pet
Add(209997, "BUFF_HELP") 				-- Play Dead
Add(118922, "BUFF_SPEED_BOOST") 		-- Posthaste
Add( 53480, "BUFF_HELP") 				-- Roar of Sacrifice (PvP Talent)
Add(400456, "BUFF_HARM") 				-- Salvo
Add(  1513, "CC") 						-- Scare Beast
Add(213691, "CC") 						-- Scatter Shot
Add(356723, "CC") 						-- Scorpid Venom
Add(360966, "BUFF_HARM") 				-- Spearhead
Add(356727, "CC") 						-- Spider Venom
Add(162480, "ROOT") 					-- Steel Trap
Add(407032, "CC") 						-- Sticky Tar Bomb
Add(407031, "CC", 407032) 				-- Sticky Tar Bomb (AoE)
Add(202748, "BUFF_HELP") 				-- Survival Tactics (PvP Talent)
Add(212638, "ROOT") 					-- Tracker's Net
Add(288613, "BUFF_HARM") 				-- Trueshot

-- Mage
--------------------------------------------------
Add(342246, "BUFF_HELP") 				-- Alter Time (Arcane)
Add(110909, "BUFF_HELP", 342246) 		-- Alter Time (Fire/Frost)
Add(365362, "BUFF_HARM") 				-- Arcane Surge
Add( 87023, "BUFF_OTHER") 				-- Cauterize
Add(190319, "BUFF_HARM") 				-- Combustion
Add( 31661, "CC") 						-- Dragon's Breath
Add( 12051, "BUFF_HARM") 				-- Evocation
Add( 33395, "ROOT") 					-- Freeze
Add(390612, "DEBUFF_HARM") 				-- Frost Bomb
Add(   122, "ROOT") 					-- Frost Nova
Add(378760, "ROOT") 					-- Frostbite
Add(228600, "ROOT") 					-- Glacial Spike Root
Add(110960, "BUFF_HELP") 				-- Greater Invisibility (Countdown)
Add(113862, "BUFF_HELP") 				-- Greater Invisibility
Add(383874, "BUFF_HARM") 				-- Hyperthermia
Add( 41425, "BUFF_OTHER") 				-- Hypothermia
Add( 45438, "IMMUNITY") 				-- Ice Block
Add(414658, "BUFF_HELP", 45438) 		-- Ice Cold
Add(108839, "BUFF_OTHER") 				-- Ice Floes
Add(198144, "BUFF_HARM") 				-- Ice Form
Add(157997, "ROOT") 					-- Ice Nova
Add( 12472, "BUFF_HARM") 				-- Icy Veins
Add( 12654, "DEBUFF_HARM") 				-- Ignite
Add(    66, "BUFF_HARM") 				-- Invisibility (Countdown)
Add( 32612, "BUFF_HARM") 				-- Invisibility
Add(414664, "BUFF_HARM") 				-- Mass Invisibility
Add(383121, "CC") 						-- Mass Polymorph
Add(   118, "CC") 						-- Polymorph
Add( 61305, "CC") 						-- Polymorph Black Cat
Add(277792, "CC") 						-- Polymorph Bumblebee
Add(277787, "CC") 						-- Polymorph Direhorn
Add(391622, "CC") 						-- Polymorph Duck
Add(161354, "CC") 						-- Polymorph Monkey
Add(161372, "CC") 						-- Polymorph Peacock
Add(161355, "CC") 						-- Polymorph Penguin
Add( 28272, "CC") 						-- Polymorph Pig
Add(161353, "CC") 						-- Polymorph Polar Bear Cub
Add(126819, "CC") 						-- Polymorph Porcupine
Add( 61721, "CC") 						-- Polymorph Rabbit
Add( 61025, "CC") 						-- Polymorph Serpent
Add( 61780, "CC") 						-- Polymorph Turkey
Add( 28271, "CC") 						-- Polymorph Turtle
Add(205025, "BUFF_HARM") 				-- Presence of Mind
Add(376103, "DEBUFF_HARM") 				-- Radiant Spark
Add( 82691, "CC") 						-- Ring of Frost
Add(   130, "BUFF_OTHER") 				-- Slow Fall
Add(389831, "CC") 						-- Snowdrift
Add(198111, "BUFF_HELP") 				-- Temporal Shield (Arcane PvP Talent)
Add(342242, "BUFF_HARM") 				-- Time Warp (procced by Time Anomality) (Arcane Talent)
Add(210824, "DEBUFF_HARM") 				-- Touch of the Magi
Add(228358, "DEBUFF_HARM") 				-- Winter's Chill

-- Monk
--------------------------------------------------
Add(202162, "BUFF_HELP") 				-- Avert Harm (Brew PvP Talent)
Add(324382, "ROOT") 					-- Clash
Add(122278, "BUFF_HELP") 				-- Dampen Harm
Add(122783, "BUFF_HELP") 				-- Diffuse Magic
Add(116706, "ROOT") 					-- Disable
Add(202335, "BUFF_HARM") 				-- Double Barrel (Brew PvP Talent) - "next cast will..." buff
Add(202346, "CC") 						-- Double Barrel (Brew PvP Talent)
Add(394112, "BUFF_HELP") 				-- Escape from Reality
Add(120954, "BUFF_HELP") 				-- Fortifying Brew (Brewmaster)
Add(233759, "CC")						-- Grapple Weapon (MW/WW PvP Talent)
Add(202248, "IMMUNITY_SPELL") 			-- Guided Meditation (Brew PvP Talent)
Add(202274, "CC") 						-- Incendiary Brew (Brew PvP Talent)
Add(132578, "BUFF_HELP") 				-- Invoke Niuzao, the Black Ox
Add(119381, "CC") 						-- Leg Sweep
Add(116849, "BUFF_HELP") 				-- Life Cocoon
Add(213664, "BUFF_HELP") 				-- Nimble Brew (Brew PvP Talent)
Add(115078, "CC") 						-- Paralysis
Add(353319, "IMMUNITY_SPELL") 			-- Peaceweaver
Add(152173, "BUFF_HARM") 				-- Serenity
Add(393047, "DEBUFF_HARM") 				-- Skyreach
Add(198909, "CC") 						-- Song of Chi-Ji
Add(137639, "BUFF_HARM") 				-- Storm, Earth, and Fire
Add(116841, "BUFF_SPEED_BOOST") 		-- Tiger's Lust
Add(125174, "BUFF_HELP") 				-- Touch of Karma (Buff)
Add(122470, "DEBUFF_HARM") 				-- Touch of Karma (Debuff)
Add(387184, "BUFF_HARM") 				-- Weapons of Order (Brewmaster)
Add(209584, "BUFF_HELP") 				-- Zen Focus Tea (MW PvP Talent)
Add(115176, "BUFF_HELP") 				-- Zen Meditation

-- Paladin
--------------------------------------------------
Add( 31850, "BUFF_HELP") 				-- Ardent Defender
Add( 31821, "BUFF_HELP") 				-- Aura Mastery
Add( 31884, "BUFF_HARM") 				-- Avenging Wrath
Add( 31935, "CC") 						-- Avenger's Shield (defined as Interrupt)
Add(216331, "BUFF_HARM", 31884) 		-- Avenging Crusader (Holy Talent)
Add(  1044, "BUFF_HELP") 				-- Blessing of Freedom
Add(305395, "BUFF_HELP", 1044) 			-- Blessing of Freedom with Unbound Freedom (PvP Talent)
Add(  1022, "BUFF_HELP") 				-- Blessing of Protection
Add(  6940, "BUFF_HELP") 				-- Blessing of Sacrifice
Add(199448, "BUFF_HELP") 				-- Blessing of Sacrifice (Ultimate Sacrifice Holy PvP Talent)
Add(210256, "BUFF_HELP") 				-- Blessing of Sanctuary (Ret PvP Talent)
Add(204018, "BUFF_HELP") 				-- Blessing of Spellwarding
Add(105421, "CC") 						-- Blinding Light
Add(231895, "BUFF_HARM", 31884) 		-- Crusade (Retribution Talent)
Add(  2812, "DEBUFF_HARM") 				-- Denounce
Add(210294, "BUFF_HELP") 				-- Divine Favor
Add(415246, "BUFF_HELP") 				-- Divine Plea (Holy PvP Talent)
Add(   498, "BUFF_HELP") 				-- Divine Protection
Add(403876, "BUFF_HELP", 498) 			-- Divine Protection (Retribution)
Add(   642, "IMMUNITY") 				-- Divine Shield
Add(221883, "BUFF_SPEED_BOOST") 		-- Divine Steed
Add(221885, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(221886, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(221887, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(254471, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(254472, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(254473, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(254474, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(276111, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(276112, "BUFF_SPEED_BOOST", 221883) -- Divine Steed
Add(343527, "DEBUFF_HARM") 				-- Execution Sentence
Add(385149, "CC") 						-- Exorcism stun
Add(343721, "DEBUFF_HARM") 				-- Final Reckoning
Add( 25771, "BUFF_OTHER") 				-- Forbearance
Add( 86659, "BUFF_HELP") 				-- Guardian of Ancient Kings
Add(212641, "BUFF_HELP", 86659) 		-- Guardian of Ancient Kings (Glyphed)
Add(228050, "IMMUNITY") 				-- Guardian of the Forgotten Queen (Protection PvP Talent)
Add(   853, "CC") 						-- Hammer of Justice
Add(414273, "BUFF_HELP") 				-- Hand of Divinity
Add( 20066, "CC") 						-- Repentance
Add(157128, "BUFF_HELP") 				-- Saved by the Light
Add(410201, "DEBUFF_HARM") 				-- Searing Glare
Add(389539, "BUFF_HARM", 31884) 		-- Sentinel (Protection Talent)
Add(184662, "BUFF_HELP") 				-- Shield of Vengeance
Add(215652, "BUFF_HARM") 				-- Shield of Virtue (Protection PvP Talent) - "next cast will..." buff
--Add(217824, "CC") 					-- Shield of Virtue (Protection PvP Talent) (defined as Interrupt)
Add(199545, "BUFF_HELP") 				-- Steed of Glory (Protection PvP Talent)
Add( 10326, "CC") 						-- Turn Evil
Add(199450, "BUFF_HELP", 199448) 		-- Ultimate Sacrifice (Holy PvP Talent) - debuff on the paladin
Add(255941, "CC") 						-- Wake of Ashes stun
Add(403695, "DEBUFF_HARM") 				-- Wake of Ashes (Truth's Wake)

-- Priest
--------------------------------------------------
Add(121557, "BUFF_SPEED_BOOST") 		-- Angelic Feather
Add(200183, "BUFF_HELP") 				-- Apotheosis
Add(197862, "BUFF_HELP") 				-- Archangel (Disc PvP Talent)
Add(211336, "BUFF_HELP") 				-- Archbishop Benedictus' Restitution (Resurrection Buff)
Add(211319, "BUFF_OTHER") 				-- Archbishop Benedictus' Restitution (Debuff)
Add( 65081, "BUFF_SPEED_BOOST") 		-- Body and Soul
Add(197871, "BUFF_HARM") 				-- Dark Archangel (Disc PvP Talent) - on the priest
Add(197874, "BUFF_HARM", 197871) 		-- Dark Archangel (Disc PvP Talent) - on others
Add(391109, "BUFF_HARM") 				-- Dark Ascension
Add( 19236, "BUFF_HELP") 				-- Desperate Prayer
Add(335467, "DEBUFF_HARM") 				-- Devouring Plague
Add( 47585, "BUFF_HELP") 				-- Dispersion
Add(329543, "BUFF_HELP") 				-- Divine Ascension (down)
Add(328530, "IMMUNITY", 329543) 		-- Divine Ascension (up)
Add( 64843, "BUFF_HELP") 				-- Divine Hymn
Add( 47788, "BUFF_HELP") 				-- Guardian Spirit
Add(213610, "IMMUNITY_SPELL") 			-- Holy Ward
Add(200196, "CC") 						-- Holy Word: Chastise
Add(200200, "CC", 200196) 				-- Holy Word: Chastise (Stun)
Add(289655, "BUFF_HELP") 				-- Holy Word: Concentration
Add(111759, "BUFF_OTHER") 				-- Levitate
Add(271466, "BUFF_HELP", 81782) 		-- Luminous Barrier
Add(375901, "DEBUFF_HARM") 				-- Mindgames
Add(205369, "CC") 						-- Mind Bomb (Countdown)
Add(226943, "CC", 205369) 				-- Mind Bomb (Disorient)
Add(   605, "CC") 						-- Mind Control
Add(   453, "BUFF_OTHER") 				-- Mind Soothe
Add( 33206, "BUFF_HELP") 				-- Pain Suppression
Add(408558, "IMMUNITY") 				-- Phase Shift
Add( 10060, "BUFF_HARM") 				-- Power Infusion
Add( 81782, "BUFF_HELP") 				-- Power Word: Barrier
Add( 64044, "CC") 						-- Psychic Horror
Add(  8122, "CC") 						-- Psychic Scream
Add(199845, "DEBUFF_HARM") 				-- Psyflay (Psyfiend) debuff
Add( 47536, "BUFF_HELP") 				-- Rapture
Add(232707, "BUFF_HELP") 				-- Ray of Hope (Holy PvP Talent)
Add(  9484, "CC") 						-- Shackle Undead
Add(322105, "BUFF_HARM") 				-- Shadow Covenant
Add(214621, "DEBUFF_HARM") 				-- Schism
Add( 15487, "CC") 						-- Silence
Add( 87204, "CC") 						-- Sin and Punishment
--Add( 27827, "BUFF_HELP") 				-- Spirit of Redemption
Add(215769, "BUFF_HELP") 				-- Spirit of Redemption (Spirit of the Redeemer Holy PvP Talent)
Add(322431, "BUFF_HARM") 				-- Thoughtsteal (Buff)
Add(322459, "DEBUFF_HARM") 				-- Thoughtstolen (Shaman)
Add(322464, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Mage)
Add(322442, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Druid)
Add(322462, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Priest - Holy)
Add(322457, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Paladin)
Add(322463, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Warlock)
Add(322461, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Priest - Discipline)
Add(322458, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Monk)
Add(322460, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Priest - Shadow)
Add(394902, "DEBUFF_HARM", 322459) 		-- Thoughtstolen (Evoker)
Add(373447, "BUFF_HELP") 				-- Translucent Image (Fade)
Add( 15286, "BUFF_HELP") 				-- Vampiric Embrace
Add( 34914, "DEBUFF_HARM") 				-- Vampiric Touch
Add(114404, "ROOT") 					-- Void Tendrils
Add(358861, "CC") 						-- Void Volley: Horrify (Shadow PvP Talent)
Add(194249, "BUFF_HARM") 				-- Voidform
Add(421453, "IMMUNITY") 				-- Ultimate Penitence

Add( 15407, "DPS") 						-- Mindflay

-- Rogue
--------------------------------------------------
Add( 13750, "BUFF_HARM") 				-- Adrenaline Rush
Add(  2094, "CC") 						-- Blind
Add(  1833, "CC") 						-- Cheap Shot
Add( 45182, "BUFF_HELP") 				-- Cheating Death
Add( 31224, "IMMUNITY_SPELL") 			-- Cloak of Shadows
Add(360194, "DEBUFF_HARM") 				-- Deathmark
Add(207777, "CC") 						-- Dismantle
Add(  5277, "BUFF_HELP") 				-- Evasion
Add(  1966, "BUFF_HELP") 				-- Feint
Add(394758, "BUFF_HARM") 				-- Flagellation
Add(  1330, "CC") 						-- Garrote - Silence
Add(  1776, "CC") 						-- Gouge
Add(   408, "CC") 						-- Kidney Shot
Add( 51690, "BUFF_HARM") 				-- Killing Spree
Add(256735, "BUFF_HARM") 				-- Master Assassin
Add(193357, "BUFF_HARM") 				-- Ruthless Precision
Add(  6770, "CC") 						-- Sap
Add(375939, "BUFF_HARM") 				-- Sepsis
Add(385408, "DEBUFF_HARM") 				-- Sepsis
Add(121471, "BUFF_HARM") 				-- Shadow Blades
Add(185422, "BUFF_HARM") 				-- Shadow Dance
Add( 36554, "BUFF_SPEED_BOOST") 		-- Shadowstep
Add(207736, "BUFF_HARM") 				-- Shadowy Duel
Add(319504, "DEBUFF_HARM") 				-- Shiv
Add(212183, "CC") 						-- Smoke Bomb (PvP Talent)
Add(  2983, "BUFF_SPEED_BOOST") 		-- Sprint
Add(  1784, "BUFF_OTHER") 				-- Stealth
Add(115191, "BUFF_OTHER", 1784) 		-- Stealth (with Subterfuge talented)
Add(115192, "BUFF_HARM") 				-- Subterfuge
Add(212283, "BUFF_HARM") 				-- Symbols of Death
Add(193359, "BUFF_HARM") 				-- True Bearing
Add( 11327, "BUFF_HELP") 				-- Vanish

-- Shaman
--------------------------------------------------
Add(114049, "BUFF_HARM") 				-- Ascendance
Add(114050, "BUFF_HARM", 114049) 		-- Ascendance (Elemental)
Add(114051, "BUFF_HARM", 114049) 		-- Ascendance (Enhancement)
Add(114052, "BUFF_HELP", 114049) 		-- Ascendance (Restoration)
Add(108281, "BUFF_HELP") 				-- Ancestral Guidance
Add(207495, "BUFF_HELP") 				-- Ancestral Protection (Totem)
Add(207498, "BUFF_HELP", 207495) 		-- Ancestral Protection (Player)
Add(108271, "BUFF_HELP") 				-- Astral Shift
Add(204361, "BUFF_HARM") 				-- Bloodlust (Enhancement PvP Talent)
Add(409293, "IMMUNITY") 				-- Burrow
Add(208997, "DEBUFF_HARM") 				-- Counterstrike Totem (PvP Talent)
Add(384352, "BUFF_HARM") 				-- Doom Winds
Add(356738, "ROOT") 					-- Earth Unleashed
Add(201633, "BUFF_HELP") 				-- Earthen Wall Totem
Add( 64695, "ROOT") 					-- Earthgrab Totem
Add( 77505, "CC") 						-- Earthquake (Stun)
Add(333957, "BUFF_HARM") 				-- Feral Spirit
Add(188389, "DEBUFF_HARM") 				-- Flame Shock
Add(  2645, "BUFF_SPEED_BOOST") 		-- Ghost Wolf
Add(  8178, "IMMUNITY_SPELL") 			-- Grounding Totem Effect (PvP Talent)
Add(118337, "BUFF_HELP") 				-- Harden Skin
Add(204362, "BUFF_HARM", 204361) 		-- Heroism (Enhancement PvP Talent)
Add( 51514, "CC") 						-- Hex
Add(211015, "CC", 51514) 				-- Hex (Cockroach)
Add(210873, "CC", 51514) 				-- Hex (Compy)
Add(309328, "CC", 51514) 				-- Hex (Living Honey)
Add(269352, "CC", 51514) 				-- Hex (Skeletal Hatchling)
Add(211010, "CC", 51514) 				-- Hex (Snake)
Add(211004, "CC", 51514) 				-- Hex (Spider)
Add(277784, "CC", 51514) 				-- Hex (Wicker Mongrel)
Add(277778, "CC", 51514) 				-- Hex (Zandalari Tendonripper)
Add(305485, "CC") 						-- Lightning Lasso (PvP Talent)
Add(375986, "BUFF_HARM") 				-- Primordial Wave
Add(118345, "CC") 						-- Pulverize
Add(118905, "CC") 						-- Static Charge
Add(325174, "BUFF_HELP") 				-- Spirit Link Totem
Add( 58875, "BUFF_SPEED_BOOST") 		-- Spirit Walk
Add(260881, "BUFF_HELP") 				-- Spirit Wolf
Add(378078, "BUFF_HELP") 				-- Spiritwalker's Aegis
Add( 79206, "BUFF_OTHER") 				-- Spiritwalker's Grace
Add(191634, "BUFF_HARM") 				-- Stormkeeper (Ele)
Add(383009, "BUFF_HARM") 				-- Stormkeeper (Resto)
Add(197214, "CC") 						-- Sundering
Add(285515, "ROOT") 					-- Surge of Power (Root)
Add(378076, "BUFF_SPEED_BOOST") 		-- Thunderous Paws
Add(356824, "DEBUFF_HARM") 				-- Water Unleashed
Add(   546, "BUFF_OTHER") 				-- Water Walking
Add(192082, "BUFF_SPEED_BOOST") 		-- Windrush Totem

-- Warlock
--------------------------------------------------
Add( 89766, "CC") 						-- Axe Toss
Add(200548, "DEBUFF_HARM", 80240) 		-- Bane of Havoc (Destro PvP Talent)
Add(   710, "CC") 						-- Banish
Add(111400, "BUFF_SPEED_BOOST") 		-- Burning Rush
Add(  1714, "DEBUFF_HARM") 				-- Curse of Tongues
Add(   702, "DEBUFF_HARM") 				-- Curse of Weakness
Add(108416, "BUFF_HELP") 				-- Dark Pact
Add(113942, "BUFF_OTHER") 				-- Demonic Gateway
Add(387633, "BUFF_SPEED_BOOST") 		-- Demonic Momentum (Soulburn)
Add(265273, "BUFF_HARM") 				-- Demonic Power (Demonic Tyrant)
Add(267171, "BUFF_HARM") 				-- Demonic Strength
Add(118699, "CC") 						-- Fear
Add(130616, "CC", 118699) 				-- Fear (Horrify)
Add(213688, "CC") 						-- Fel Cleave - Fel Lord stun (Demo PvP Talent)
Add(333889, "BUFF_HELP") 				-- Fel Domination
Add(200587, "DEBUFF_HARM") 				-- Fel Fissure (PvP Talent)
Add( 80240, "DEBUFF_HARM") 				-- Havoc
Add(  5484, "CC") 						-- Howl of Terror
Add( 22703, "CC") 						-- Infernal Awakening
Add( 30213, "DEBUFF_HARM") 				-- Legion Strike
Add(  6789, "CC") 						-- Mortal Coil
Add(267218, "BUFF_HARM") 				-- Nether Portal
Add(212295, "IMMUNITY_SPELL") 			-- Nether Ward (PvP Talent)
Add(417537, "DEBUFF_HARM") 				-- Oblivion
Add(  6358, "CC") 						-- Seduction
Add( 30283, "CC") 						-- Shadowfury
Add(410598, "DEBUFF_HARM") 				-- Soul Rip
Add(386997, "DEBUFF_HARM") 				-- Soul Rot
Add( 20707, "BUFF_OTHER") 				-- Soulstone
Add(  1098, "CC") 						-- Subjugate Demon
Add(104773, "BUFF_HELP") 				-- Unending Resolve
Add(316099, "DEBUFF_HARM") 				-- Unstable Affliction
Add(342938, "DEBUFF_HARM", 316099) 		-- Unstable Affliction (Affliction PvP Talent)
Add(196364, "CC") 						-- Unstable Affliction (Silence)

-- Warrior
--------------------------------------------------
Add(107574, "BUFF_HARM") 				-- Avatar
Add(227847, "IMMUNITY") 				-- Bladestorm (Arms)
Add(389774, "IMMUNITY", 227847) 		-- Bladestorm (Hurricane)
Add(105771, "ROOT") 					-- Charge
Add( 18499, "BUFF_OTHER") 				-- Berserker Rage
Add(384100, "BUFF_OTHER", 18499) 		-- Berserker Shout
Add(202164, "BUFF_SPEED_BOOST") 		-- Bounding Stride
Add(213871, "BUFF_HELP") 				-- Bodyguard (Prot PvP Talent)
Add(208086, "DEBUFF_HARM") 				-- Colossus Smash
Add(199261, "BUFF_HARM") 				-- Death Wish
Add(386208, "BUFF_HELP") 				-- Defensive Stance
Add(118038, "BUFF_HELP") 				-- Die by the Sword
Add(236077, "CC") 						-- Disarm (PvP Talent)
Add(236273, "CC") 						-- Duel (Arms PvP Talent)
Add(184364, "BUFF_HELP") 				-- Enraged Regeneration
Add(147833, "BUFF_HELP") 				-- Intervene
Add(  5246, "CC") 						-- Intimidating Shout
Add( 12975, "BUFF_HELP") 				-- Last Stand
Add(316593, "CC", 5246) 				-- Menace (Main target)
Add(316595, "CC", 5246) 				-- Menace (Other targets)
Add(198819, "DEBUFF_HARM") 				-- Mortal Strike when applied with Sharpen Blade (50% healing reduc)
Add(424752, "ROOT") 					-- Piercing Howl (PvP Talent Root)
Add( 97463, "BUFF_HELP") 				-- Rallying Cry
Add(  1719, "BUFF_HARM") 				-- Recklessness
Add(   871, "BUFF_HELP") 				-- Shield Wall
Add(132168, "CC") 						-- Shockwave
Add(198817, "DEBUFF_HARM") 				-- Sharpen Blade
Add(354788, "DEBUFF_HARM") 				-- Slaughterhouse
Add(376080, "CC") 						-- Spear of Bastion
Add( 23920, "IMMUNITY_SPELL") 			-- Spell Reflection
Add(132169, "CC") 						-- Storm Bolt
Add( 52437, "BUFF_HARM" ) 				-- Sudden Death
Add(397364, "DEBUFF_HARM") 				-- Thunderous Roar
Add(199042, "ROOT") 					-- Thunderstruck (Prot PvP Talent)
Add(236321, "BUFF_HELP") 				-- War Banner (PvP Talent)
Add(356356, "ROOT") 					-- Warbringer
Add(199085, "CC") 						-- Warpath (Prot PvP Talent)

-- Other
--------------------------------------------------
Add(314646, "BUFF_OTHER") 				-- Drink (40k mana vendor item)
Add(348436, "BUFF_OTHER", 314646) 		-- Drink (20k mana vendor item)
Add(345231, "BUFF_HELP") 				-- Gladiator's Emblem
Add(240559, "DEBUFF_HARM") 				-- Grievous Wound (Mythic Plus Affix)
Add(115804, "DEBUFF_HARM") 				-- Mortal Wounds
Add(377362, "IMMUNITY") 				-- Precognition
Add(167152, "BUFF_OTHER", 314646) 		-- Refreshment (mage food)
Add( 34709, "BUFF_OTHER") 				-- Shadow Sight

-- Racials
--------------------------------------------------
Add(255723, "CC") 						-- Bull Rush
Add(273104, "BUFF_HELP") 				-- Fireblood
Add(287712, "CC") 						-- Haymaker
Add(107079, "CC") 						-- Quaking Palm
Add( 58984, "BUFF_HELP") 				-- Shadowmeld
Add(256948, "BUFF_OTHER") 				-- Spatial Rift
Add( 65116, "BUFF_HELP") 				-- Stoneform
Add( 20549, "CC") 						-- War Stomp

-- Dragonflight: Dragonriding
--------------------------------------------------
Add(388380, "BUFF_SPEED_BOOST") 		-- Dragonrider's Compassion
Add(388673, "CC") 						-- Dragonrider's Initiative

-- Shadowlands: Covenant/Soulbind
--------------------------------------------------
Add(331866, "CC") 						-- Agent of Chaos (Venthyr - Nadjia Trait)
Add(330752, "BUFF_HELP") 				-- Ascendant Phial (Kyrian - Kleia Trait)
Add(327140, "BUFF_OTHER") 				-- Forgeborne Reveries (Necrolord - Bonesmith Heirmir Trait)
Add(354051, "ROOT") 					-- Nimble Steps
Add(320224, "BUFF_HELP") 				-- Podtender (Night Fae - Dreamweaver Trait)
Add(310143, "BUFF_SPEED_BOOST") 		-- Soulshape
Add(332505, "BUFF_OTHER") 				-- Soulsteel Clamps (Kyrian - Mikanikos Trait)
Add(332506, "BUFF_OTHER", 332505) 		-- Soulsteel Clamps (Kyrian - Mikanikos Trait) - when moving
Add(332423, "CC") 						-- Sparkling Driftglobe Core (Kyrian - Mikanikos Trait)
Add(324263, "CC") 						-- Sulfuric Emission (Necrolord - Emeni Trait)
Add(323524, "IMMUNITY") 				-- Ultimate Form (Necrolord - Marileth Trait)

--Trinkets
--------------------------------------------------
Add(356567, "CC") 						-- Shackles of Malediction
Add(358259, "CC") 						-- Gladiator's Maledict
Add(362699, "IMMUNITY_SPELL") 			-- Gladiator's Resolve
Add(363522, "BUFF_HELP") 				-- Gladiator's Eternal Aegis

-- Legacy (may be deprecated)
--------------------------------------------------
--Add(305252, "CC") 					-- Gladiator's Maledict
--Add(313148, "CC") 					-- Forbidden Obsidian Claw

-- Special
--------------------------------------------------
--Add(  6788, "S"pecial)  				-- Weakened Soul
--------------------------------------------------

-- Dragonflight Dungeons - Season 2
--------------------------------------------------
Add(368091, "DEBUFF_HARM") 				-- Infected Bite
Add(266107, "DEBUFF_HARM") 				-- Thirst for Blood
