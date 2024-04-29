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

if (not ns.IsWrath) then return end

-- Speed!
local Add = ns.AuraData.Add

-- Priority
--------------------------------------------------
Add( 23230, true) 						-- Blood Fury Debuff
Add(   770, true) 			 			-- Faerie Fire
Add( 16857, true) 						-- Faerie Fire (Feral)
Add(  9035, true) 						-- Hex of Weakness
Add( 19281, true) 						-- Hex of Weakness
Add( 19282, true) 						-- Hex of Weakness
Add( 19283, true) 						-- Hex of Weakness
Add( 19284, true) 						-- Hex of Weakness
Add( 19285, true) 						-- Hex of Weakness
Add( 12294, true) 						-- Mortal Strike
Add( 21551, true) 						-- Mortal Strike
Add( 21552, true) 						-- Mortal Strike
Add( 21553, true) 						-- Mortal Strike
Add( 23605, true) 						-- Nightfall, Spell Vulnerability

-- Interrupts
--------------------------------------------------
Add( 29443, "INTERRUPT") 				-- Clutch of Foresight
Add(  2139, "INTERRUPT") 				-- Counterspell (Mage)
Add( 26679, "INTERRUPT") 				-- Deadly Throw
Add( 16979, "INTERRUPT") 				-- Feral Charge (Druid)
Add( 13491, "INTERRUPT") 				-- Iron Knuckles
Add(  1766, "INTERRUPT") 				-- Kick (Rogue)
Add(  1767, "INTERRUPT", 1766) 			-- Kick (Rogue)
Add(  1768, "INTERRUPT", 1766) 			-- Kick (Rogue)
Add(  1769, "INTERRUPT", 1766) 			-- Kick (Rogue)
Add( 38768, "INTERRUPT", 1766) 			-- Kick (Rogue)
Add( 15752, "INTERRUPT") 				-- Linken's Boomerang Disarm
Add( 22570, "INTERRUPT") 				-- Maim
Add(  6552, "INTERRUPT") 				-- Pummel
Add(  6554, "INTERRUPT", 6552) 			-- Pummel
Add(    72, "INTERRUPT") 				-- Shield Bash
Add(  1671, "INTERRUPT", 72) 			-- Shield Bash
Add(  1672, "INTERRUPT", 72) 			-- Shield Bash
Add( 29704, "INTERRUPT", 72) 			-- Shield Bash
Add( 19244, "INTERRUPT") 				-- Spell Lock - Rank 1 (Warlock)
Add( 19647, "INTERRUPT", 19244) 		-- Spell Lock - Rank 2 (Warlock)

-- Death Knight
--------------------------------------------------
Add( 48707, "IMMUNITY_SPELL") 			-- Anti-Magic Shell
Add( 50461, "BUFF_HELP") 				-- Anti-Magic Zone
Add( 45524, "ROOT") 					-- Chains of Ice
Add( 49028, "BUFF_HARM") 				-- Dancing Rune Weapon // might not work - spell id vs aura
Add( 47481, "CC") 						-- Gnaw
Add( 47484, "BUFF_HELP") 				-- Huddle (Ghoul)
Add( 49203, "CC") 						-- Hungering Cold
Add( 48792, "BUFF_HELP") 				-- Icebound Fortitude
Add( 49039, "IMMUNITY_SPELL") 			-- Lichborne
Add( 47528, "INTERRUPT") 				-- Mind Freeze
Add( 47476, "CC") 						-- Strangulate

-- Druid
--------------------------------------------------
Add(  5211, "CC") 						-- Bash
Add(  6798, "CC", 5211) 				-- Bash
Add(  8983, "CC", 5211) 				-- Bash
Add( 22812, "BUFF_HELP") 				-- Barkskin
Add( 50334, "BUFF_HARM") 				-- Berserk
Add(   768, "BUFF_OTHER") 				-- Cat Form
Add( 33786, "CC") 						-- Cyclone
Add( 33357, "BUFF_OTHER") 				-- Dash
Add(  1850, "BUFF_HARM") 				-- Dash
Add(  9821, "BUFF_HARM", 1850) 			-- Dash
Add(  9634, "BUFF_OTHER") 				-- Dire Bear Form
Add( 53308, "ROOT") 					-- Entangling Roots
Add(   339, "ROOT") 					-- Entangling Roots
Add(  1062, "ROOT", 339) 				-- Entangling Roots
Add(  5195, "ROOT", 339) 				-- Entangling Roots
Add(  5196, "ROOT", 339) 				-- Entangling Roots
Add(  9852, "ROOT", 339) 				-- Entangling Roots
Add(  9853, "ROOT", 339) 				-- Entangling Roots
Add( 26989, "ROOT", 339) 				-- Entangling Roots
Add( 27010, "ROOT", 339) 				-- Entangling Roots
Add( 53313, "ROOT") 					-- Entangling Roots (From Nature's Grasp)
Add(   770, "BUFF_OTHER") 				-- Faerie Fire
Add( 16857, "BUFF_OTHER", 770) 			-- Faerie Fire (Feral)
Add( 19675, "ROOT") 					-- Feral Charge Effect
Add( 45334, "ROOT", 19675) 				-- Feral Charge Effect
--Add(16979, "ROOT") 					-- Feral Charge Stun (wrong spellID)
Add( 22842, "BUFF_HELP") 				-- Frenzied Regeneration
Add(  2637, "CC") 						-- Hibernate
Add( 18657, "CC", 2637) 				-- Hibernate
Add( 18658, "CC", 2637) 				-- Hibernate
Add( 29166, "BUFF_HARM") 				-- Innervate
Add( 49802, "CC") 						-- Maim
Add( 24858, "BUFF_OTHER") 				-- Moonkin Form
Add( 53312, "BUFF_OTHER") 				-- Nature's Grasp
Add( 16689, "BUFF_HARM") 				-- Nature's Grasp Buff
Add( 16810, "BUFF_HARM", 16689) 		-- Nature's Grasp Buff
Add( 16811, "BUFF_HARM", 16689) 		-- Nature's Grasp Buff
Add( 16812, "BUFF_HARM", 16689) 		-- Nature's Grasp Buff
Add( 16813, "BUFF_HARM", 16689) 		-- Nature's Grasp Buff
Add( 17329, "BUFF_HARM", 16689) 		-- Nature's Grasp Buff
Add( 19970, "ROOT", 339) 				-- Nature's Grasp Rank 6
Add( 19971, "ROOT", 339) 				-- Nature's Grasp Rank 5
Add( 19972, "ROOT", 339) 				-- Nature's Grasp Rank 4
Add( 19973, "ROOT", 339) 				-- Nature's Grasp Rank 3
Add( 19974, "ROOT", 339) 				-- Nature's Grasp Rank 2
Add( 19975, "ROOT", 339) 				-- Nature's Grasp Rank 1
Add( 17116, "BUFF_HELP") 				-- Nature's Swiftness
Add( 49803, "CC") 						-- Pounce
Add(  9005, "CC") 						-- Pounce Stun
Add(  9823, "CC", 9005) 				-- Pounce Stun
Add(  9827, "CC", 9005) 				-- Pounce Stun
Add( 27006, "CC", 9005) 				-- Pounce Stun
Add( 69369, "BUFF_HARM") 				-- Predator's Swiftness
Add( 53201, "BUFF_HARM") 				-- Starfall
Add( 16922, "CC") 						-- Starfire Stun
Add( 61336, "BUFF_HELP") 				-- Survival Instincts
Add(   783, "BUFF_OTHER") 				-- Travel Form
Add( 33891, "BUFF_OTHER") 				-- Tree of Life

-- Hunter
--------------------------------------------------
Add( 13159, "BUFF_HARM") 				-- Aspect of the Pack
Add(  5118, "BUFF_HARM", 13159) 		-- Aspect of the Cheetah
Add( 19574, "BUFF_HARM") 				-- Bestial Wrath
Add( 25999, "ROOT") 					-- Boar Charge
Add( 53359, "CC") 						-- Chimera Shot - Scorpid (Disarm)
Add( 48999, "ROOT") 					-- Counterattack
Add( 19306, "ROOT") 					-- Counterattack Root
Add( 20909, "ROOT", 19306) 				-- Counterattack Root
Add( 20910, "ROOT", 19306) 				-- Counterattack Root
Add( 27067, "ROOT", 19306) 				-- Counterattack Root
Add(  1742, "BUFF_HELP") 				-- Cower (Pet)
Add( 19263, "IMMUNITY") 				-- Deterrence
Add( 19185, "ROOT") 					-- Entrapment
Add( 64803, "ROOT", 19185) 				-- Entrapment
Add( 64804, "ROOT", 19185) 				-- Entrapment
Add(  5384, "BUFF_HELP") 				-- Feign Death
Add( 60210, "CC") 						-- Freezing Arrow Effect
Add(  3355, "CC") 						-- Freezing Trap
Add( 14308, "CC", 3355) 				-- Freezing Trap
Add( 14309, "CC", 3355) 				-- Freezing Trap
Add( 53476, "BUFF_HELP") 				-- Intervene (Pet)
Add( 24394, "CC") 						-- Intimidation
Add( 19577, "BUFF_HARM", 24394) 		-- Intimidation (Buff)
Add( 53271, "BUFF_HELP") 				-- Master's Call
Add( 27046, "BUFF_HELP") 				-- Mend Pet
Add( 53548, "ROOT") 					-- Pin (Pet)
Add( 26090, "INTERRUPT") 				-- Pummel (Pet)
Add(  3045, "BUFF_HARM") 				-- Rapid Fire
Add( 53562, "CC") 						-- Ravage (Pet)
Add( 53480, "BUFF_HELP") 				-- Roar of Sacrifice (Hunter Pet Skill)
Add(  1513, "CC") 						-- Scare Beast
Add( 14326, "CC", 1513) 				-- Scare Beast
Add( 14327, "CC", 1513) 				-- Scare Beast
Add( 19503, "CC") 						-- Scatter Shot
Add( 26064, "BUFF_HELP") 				-- Shell Shield (Pet)
Add( 34490, "CC") 						-- Silencing Shot
Add( 53543, "CC") 						-- Snatch (Pet Disarm)
Add( 34471, "IMMUNITY_SPELL") 			-- The Beast Within
Add(  4167, "ROOT") 					-- Web (Pet)
Add(  3034, "ROOT") 					-- Viper Sting
Add( 14279, "ROOT", 3034) 				-- Viper Sting
Add( 14280, "ROOT", 3034) 				-- Viper Sting
Add( 27018, "ROOT", 3034) 				-- Viper Sting
Add( 49012, "CC") 						-- Wyvern Sting
Add( 19386, "CC") 						-- Wyvern Sting
Add( 24132, "CC", 19386) 				-- Wyvern Sting
Add( 24133, "CC", 19386) 				-- Wyvern Sting
Add( 27068, "CC", 19386) 				-- Wyvern Sting

-- Mage
--------------------------------------------------
Add( 12042, "BUFF_HARM") 				-- Arcane Power
Add( 54748, "BUFF_HARM") 				-- Burning Determination (Interrupt/Silence Immunity)
Add( 44572, "CC") 						-- Deep Freeze
Add( 31661, "CC") 						-- Dragon's Breath
Add( 33041, "CC", 31661) 				-- Dragon's Breath
Add( 33042, "CC", 31661) 				-- Dragon's Breath
Add( 33043, "CC", 31661) 				-- Dragon's Breath
Add( 42950, "CC") 						-- Dragon's Breath
Add( 12051, "BUFF_HARM") 				-- Evocation
Add(   543, "BUFF_HELP") 				-- Fire Ward
Add(  8457, "BUFF_HELP", 543) 			-- Fire Ward
Add(  8458, "BUFF_HELP", 543) 			-- Fire Ward
Add( 10223, "BUFF_HELP", 543) 			-- Fire Ward
Add( 10225, "BUFF_HELP", 543) 			-- Fire Ward
Add( 64346, "CC") 						-- Fiery Payback (Fire Mage Disarm)
Add( 44544, "BUFF_HARM") 				-- Fingers of Frost
Add( 33395, "ROOT") 					-- Freeze
Add( 12494, "ROOT") 					-- Frostbite
Add(   122, "ROOT") 					-- Frost Nova
Add(   865, "ROOT", 122) 				-- Frost Nova
Add(  6131, "ROOT", 122) 				-- Frost Nova
Add( 10230, "ROOT", 122) 				-- Frost Nova
Add( 27088, "ROOT", 122) 				-- Frost Nova
Add( 42917, "ROOT", 122) 				-- Frost Nova
Add(  6143, "BUFF_HELP") 				-- Frost Ward
Add(  8461, "BUFF_HELP", 6143) 			-- Frost Ward
Add(  8462, "BUFF_HELP", 6143) 			-- Frost Ward
Add( 10177, "BUFF_HELP", 6143) 			-- Frost Ward
Add( 28609, "BUFF_HELP", 6143) 			-- Frost Ward
Add( 41425, "BUFF_OTHER") 				-- Hypothermia
Add( 11426, "BUFF_HELP") 				-- Ice Barrier
Add( 13031, "BUFF_HELP", 11426) 		-- Ice Barrier
Add( 13032, "BUFF_HELP", 11426) 		-- Ice Barrier
Add( 13033, "BUFF_HELP", 11426) 		-- Ice Barrier
Add( 43039, "BUFF_OTHER") 				-- Ice Barrier
Add( 45438, "IMMUNITY") 				-- Ice Block
Add( 12472, "BUFF_HARM") 				-- Icy Veins
Add( 12355, "CC") 						-- Impact Stun
Add( 55021, "CC") 						-- Improved Counterspell
Add( 18469, "CC") 						-- Improved Counterspell
Add(    66, "BUFF_HARM") 				-- Invisibility
Add(  1463, "BUFF_HELP") 				-- Mana Shield
Add(  8494, "BUFF_HELP", 1463) 			-- Mana Shield
Add(  8495, "BUFF_HELP", 1463) 			-- Mana Shield
Add( 10191, "BUFF_HELP", 1463) 			-- Mana Shield
Add( 10192, "BUFF_HELP", 1463) 			-- Mana Shield
Add( 10193, "BUFF_HELP", 1463) 			-- Mana Shield
Add(   118, "CC") 						-- Polymorph
Add( 12824, "CC", 118) 					-- Polymorph
Add( 12825, "CC", 118) 					-- Polymorph
Add( 12826, "CC", 118) 					-- Polymorph
Add( 28270, "CC", 118) 					-- Polymorph
Add( 28271, "CC", 118) 					-- Polymorph
Add( 28272, "CC", 118) 					-- Polymorph
Add( 71319, "CC", 118) 					-- Polymorph
Add( 61305, "CC", 118) 					-- Polymorph
Add( 61721, "CC", 118) 					-- Polymorph
Add( 12043, "BUFF_HARM") 				-- Presence of Mind
Add( 55080, "ROOT", 122) 				-- Shattered Barrier

-- Paladin
--------------------------------------------------
Add( 31852, "BUFF_HELP") 				-- Ardent Defender
Add( 31821, "BUFF_HELP") 				-- Aura Mastery
Add( 31884, "BUFF_HARM") 				-- Avenging Wrath
Add(  1044, "BUFF_HELP") 				-- Blessing of Freedom
Add(  1022, "IMMUNITY") 				-- Blessing of Protection
Add(  5599, "IMMUNITY", 1022) 			-- Blessing of Protection
Add( 10278, "IMMUNITY", 1022) 			-- Blessing of Protection
Add(  6940, "BUFF_HELP") 				-- Blessing of Sacrifice
Add( 20729, "BUFF_HELP", 6940) 			-- Blessing of Sacrifice
Add( 20216, "BUFF_HELP") 				-- Divine Favor
Add( 31842, "BUFF_HELP") 				-- Divine Illumination
Add( 19753, "IMMUNITY") 				-- Divine Intervention
Add( 54428, "BUFF_OTHER") 				-- Divine Plea
Add( 64205, "BUFF_HELP") 				-- Divine Sacrifice
Add(   642, "IMMUNITY") 				-- Divine Shield
Add(   498, "IMMUNITY", 642) 			-- Divine Shield
Add(  1020, "IMMUNITY", 642) 			-- Divine Shield
Add(  5573, "IMMUNITY", 642) 			-- Divine Shield
Add( 25771, "BUFF_OTHER") 				-- Forbearance
Add(   853, "CC") 						-- Hammer of Justice
Add(  5588, "CC", 853) 					-- Hammer of Justice
Add(  5589, "CC", 853) 					-- Hammer of Justice
Add( 10308, "CC", 853) 					-- Hammer of Justice
Add( 48817, "CC") 						-- Holy Wrath
Add( 20066, "CC") 						-- Repentance
Add( 58597, "BUFF_OTHER") 				-- Sacred Shield Proc
Add( 20170, "CC") 						-- Seal of Justice stun
Add( 63529, "CC") 						-- Silenced - Shield of the Templar
Add( 59578, "BUFF_OTHER") 				-- The Art of War
Add( 10326, "CC") 						-- Turn Evil
Add(  2878, "CC", 10326) 				-- Turn Evil
Add(  5627, "CC", 10326) 				-- Turn Evil

-- Priest
--------------------------------------------------
Add( 47585, "IMMUNITY") 				-- Dispersion
Add( 64843, "BUFF_HELP") 				-- Divine Hymn
Add(  6346, "BUFF_HELP") 				-- Fear Ward
Add( 47788, "BUFF_HELP") 				-- Guardian Spirit
Add( 64901, "BUFF_HELP") 				-- Hymn of Hope
Add( 14751, "BUFF_HELP") 				-- Inner Focus
Add( 14892, "BUFF_HELP") 				-- Inspiration
Add( 15362, "BUFF_HELP", 14892) 		-- Inspiration
Add( 15363, "BUFF_HELP", 14892) 		-- Inspiration
Add(   605, "CC") 						-- Mind Control
Add( 10911, "CC", 605) 					-- Mind Control
Add( 10912, "CC", 605) 					-- Mind Control
Add(   453, "BUFF_OTHER") 				-- Mind Soothe
Add(  8192, "BUFF_OTHER", 453) 			-- Mind Soothe
Add( 10953, "BUFF_OTHER", 453) 			-- Mind Soothe
Add( 25596, "BUFF_OTHER", 453) 			-- Mind Soothe
Add( 33206, "BUFF_HELP") 				-- Pain Suppression
Add( 48066, "BUFF_OTHER") 				-- Power Word: Shield
Add( 10060, "BUFF_HARM") 				-- Power Infusion
Add(    17, "BUFF_HELP") 				-- Power Word: Shield
Add(   592, "BUFF_HELP", 17) 			-- Power Word: Shield
Add(   600, "BUFF_HELP", 17) 			-- Power Word: Shield
Add(  3747, "BUFF_HELP", 17) 			-- Power Word: Shield
Add(  6065, "BUFF_HELP", 17) 			-- Power Word: Shield
Add(  6066, "BUFF_HELP", 17) 			-- Power Word: Shield
Add( 10898, "BUFF_HELP", 17) 			-- Power Word: Shield
Add( 10899, "BUFF_HELP", 17) 			-- Power Word: Shield
Add( 10900, "BUFF_HELP", 17) 			-- Power Word: Shield
Add( 10901, "BUFF_HELP", 17) 			-- Power Word: Shield
Add( 64044, "CC") 						-- Psychic Horror (Horrify)
Add( 64058, "CC") 						-- Psychic Horror (Disarm)
Add(  8122, "CC") 						-- Psychic Scream
Add(  8124, "CC", 8122) 				-- Psychic Scream
Add( 10888, "CC", 8122) 				-- Psychic Scream
Add( 10890, "CC", 8122) 				-- Psychic Scream
Add(  9484, "CC") 						-- Shackle Undead
Add(  9485, "CC", 9484) 				-- Shackle Undead
Add( 10955, "CC", 9484) 				-- Shackle Undead
Add( 15487, "CC") 						-- Silence
Add( 20711, "BUFF_HELP") 				-- Spirit of Redemption
Add( 27827, "IMMUNITY") 				-- Spirit of Redemption

-- Rogue
-------------------------------------------------
Add( 13750, "BUFF_HARM") 				-- Adrenaline Rush
Add( 13877, "BUFF_HARM") 				-- Blade Flurry
Add(  2094, "CC") 						-- Blind
Add(  1833, "CC") 						-- Cheap Shot
Add( 45182, "BUFF_HELP") 				-- Cheating Death
Add( 31224, "IMMUNITY_SPELL") 			-- Cloak of Shadows
Add( 14177, "BUFF_HARM") 				-- Cold Blood
Add(  3409, "ROOT") 					-- Crippling Poison
Add( 11201, "ROOT", 3409) 				-- Crippling Poison
Add(51722, "CC") 						-- Dismantle
Add(  5277, "BUFF_HELP") 				-- Evasion
Add( 26669, "BUFF_HELP", 5277) 			-- Evasion
Add(  1330, "CC") 						-- Garrote Silence
Add( 14278, "BUFF_HELP") 				-- Ghostly Strike
Add(  1776, "CC") 						-- Gouge
Add(  1777, "CC", 1776) 				-- Gouge
Add(  8629, "CC", 1776) 				-- Gouge
Add( 11285, "CC", 1776) 				-- Gouge
Add( 11286, "CC", 1776) 				-- Gouge
Add( 38764, "CC", 1776) 				-- Gouge
Add( 18425, "CC") 						-- Improved Kick
Add(   408, "CC") 						-- Kidney Shot
Add(  8643, "CC", 408) 					-- Kidney Shot
Add( 51690, "BUFF_HARM") 				-- Killing Spree
Add( 14251, "BUFF_OTHER") 				-- Riposte (Rogue)
Add(  2070, "CC") 						-- Sap
Add(  6770, "CC", 2070) 				-- Sap
Add( 11297, "CC", 2070) 				-- Sap
Add( 51724, "CC") 						-- Sap
Add( 51713, "BUFF_HARM") 				-- Shadow Dance
Add(  2983, "BUFF_HARM") 				-- Sprint
Add(  8696, "BUFF_HARM", 2983) 			-- Sprint
Add( 11305, "BUFF_HARM", 2983) 			-- Sprint

-- Shaman
--------------------------------------------------
Add( 58861, "CC") 						-- Bash (Spirit Wolf)
Add(  2825, "BUFF_HARM") 				-- Bloodlust
Add( 64695, "ROOT") 					-- Earthgrab (Elemental)
Add( 16166, "BUFF_HARM") 				-- Elemental Mastery
Add( 63685, "ROOT") 					-- Freeze (Enhancement)
Add( 12548, "ROOT") 					-- Frost Shock
Add(  8178, "IMMUNITY_SPELL") 			-- Grounding Totem Effect
Add( 32182, "BUFF_HARM") 				-- Heroism
Add( 51514, "CC") 						-- Hex
Add( 16191, "BUFF_HARM") 				-- Mana Tide Totem
Add( 16188, "BUFF_HELP") 				-- Nature's Swiftness
Add( 30823, "BUFF_HELP") 				-- Shamanistic Rage
Add( 58875, "BUFF_OTHER") 				-- Spirit Walk (Spirit Wolf)
Add( 39796, "CC") 						-- Stoneclaw Totem
Add( 55277, "BUFF_OTHER") 				-- Stoneclaw Totem (Absorb)
Add( 57994, "INTERRUPT")  				-- Wind Shear

-- Warlock
--------------------------------------------------
Add(   710, "CC") 						-- Banish
Add( 18647, "CC", 710) 					-- Banish
Add( 18223, "ROOT") 					-- Curse of Exhaustion
Add( 18310,  "ROOT", 18223) 			-- Curse of Exhaustion
Add( 18313,  "ROOT", 18223) 			-- Curse of Exhaustion
Add(  1714, "ROOT") 					-- Curse of Tongues
Add( 11719,  "ROOT", 1714) 				-- Curse of Tongues
Add( 47860, "CC") 						-- Death Coil
Add(  6789, "CC") 						-- Death Coil
Add( 17925, "CC", 6789) 				-- Death Coil
Add( 17926, "CC", 6789) 				-- Death Coil
Add( 27223, "CC", 6789) 				-- Death Coil
Add( 60995, "CC") 						-- Demon Charge (Metamorphosis)
Add( 19482, "CC") 						-- Doom Guard Stun
Add(  5782, "CC") 						-- Fear
Add(  6213, "CC", 5782) 				-- Fear
Add(  6215, "CC", 5782) 				-- Fear
Add( 18708, "BUFF_HELP") 				-- Fel Domination
Add( 30153, "CC") 						-- Felguard Stun
Add( 30195, "CC", 30153) 				-- Felguard Stun
Add( 30197, "CC", 30153) 				-- Felguard Stun
Add(  5484, "CC") 						-- Howl of Terror
Add( 17928, "CC", 5484) 				-- Howl of Terror
Add( 22703, "CC") 						-- Inferno Effect
Add( 47995, "CC") 						-- Intercept (Felguard)
Add( 47241, "BUFF_HARM") 				-- Metamorphosis
Add( 30299, "BUFF_HELP") 				-- Nether Protection
Add( 30301, "BUFF_HELP", 30299) 		-- Nether Protection
Add( 30302, "BUFF_HELP", 30399) 		-- Nether Protection
Add(  4511, "IMMUNITY") 				-- Phase Shift
Add( 18093, "CC") 						-- Pyroclasm
Add( 47986, "BUFF_OTHER") 				-- Sacrifice
Add(  7812, "BUFF_HELP") 				-- Sacrifice
Add( 19438, "BUFF_HELP", 7812) 			-- Sacrifice
Add( 19440, "BUFF_HELP", 7812) 			-- Sacrifice
Add( 19441, "BUFF_HELP", 7812) 			-- Sacrifice
Add( 19442, "BUFF_HELP", 7812) 			-- Sacrifice
Add( 19443, "BUFF_HELP", 7812) 			-- Sacrifice
Add(  6358, "CC") 						-- Seduction
Add(  6229, "BUFF_HELP") 				-- Shadow Ward
Add( 11739, "BUFF_HELP", 6229) 			-- Shadow Ward
Add( 11740, "BUFF_HELP", 6229) 			-- Shadow Ward
Add( 28610, "BUFF_HELP", 6229) 			-- Shadow Ward
Add( 30283, "CC") 						-- Shadowfury
Add( 30413, "CC", 30283) 				-- Shadowfury
Add( 30414, "CC", 30283) 				-- Shadowfury
Add( 47847, "CC", 30283) 				-- Shadowfury
Add( 24259, "CC") 						-- Spell Lock Silence
Add( 32752, "CC") 						-- Summoning Disorientation
Add( 43523, "CC") 						-- Unstable Affliction
Add( 31117, "CC", 43523) 				-- Unstable Affliction

-- Warrior
-------------------------------------------------
Add(  2457, "BUFF_OTHER") 				-- Battle Stance
Add( 18499, "BUFF_HARM") 				-- Berserker Rage
Add(  2458, "BUFF_OTHER") 				-- Berserker Stance
Add( 46924, "IMMUNITY") 				-- Bladestorm
Add(  7922, "CC") 						-- Charge Stun
Add( 12809, "CC") 						-- Concussion Blow
Add( 12292, "BUFF_HARM") 				-- Death Wish
Add(    71, "BUFF_OTHER") 				-- Defensive Stance
Add(   676, "BUFF_OTHER") 				-- Disarm
Add( 55694, "BUFF_HELP") 				-- Enraged Regeneration
Add( 23694, "ROOT") 					-- Improved Hamstring
Add( 18498, "CC") 						-- Improved Shield Bash
Add( 20253, "CC") 						-- Intercept Stun
Add( 20614, "CC", 20253) 				-- Intercept Stun
Add( 20615, "CC", 20253) 				-- Intercept Stun
Add( 25273, "CC", 20253) 				-- Intercept Stun
Add( 25274, "CC", 20253) 				-- Intercept Stun
Add(  3411, "BUFF_HELP") 				-- Intervene
Add(  5246, "CC") 						-- Intimidating Shout
Add( 20511, "CC", 5246) 				-- Intimidating Shout
Add( 12975, "BUFF_HELP") 				-- Last Stand
Add( 12976, "BUFF_HELP") 				-- Last Stand
Add(  5530, "CC") 						-- Mace Spec Stun (Warrior & Rogue)
Add( 12294, "BUFF_OTHER") 				-- Mortal Strike
Add( 21551, "BUFF_OTHER", 12294) 		-- Mortal Strike
Add( 21552, "BUFF_OTHER", 12294) 		-- Mortal Strike
Add( 21553, "BUFF_OTHER", 12294) 		-- Mortal Strike
Add( 25248, "BUFF_OTHER", 12294) 		-- Mortal Strike
Add( 30330, "BUFF_OTHER", 12294) 		-- Mortal Strike
Add(  1719, "BUFF_HARM") 				-- Recklessness
Add( 20230, "IMMUNITY") 				-- Retaliation
Add( 12798, "CC") 						-- Revenge Stun
Add(  2565, "BUFF_HELP") 				-- Shield Block
Add(   871, "BUFF_HELP") 				-- Shield Wall
Add( 46968, "CC") 						-- Shockwave
Add( 23920, "IMMUNITY_SPELL") 			-- Spell Reflection
Add( 60503, "BUFF_HARM") 				-- Taste for Blood
Add( 64849, "BUFF_HARM") 				-- Unrelenting Assault (1/2)
Add( 65925, "BUFF_HARM") 				-- Unrelenting Assault (2/2)

-- Racials
--------------------------------------------------
Add( 28730, "CC") 						-- Arcane Torrent (Mana)
Add( 25046, "CC") 						-- Arcane Torrent (Energy)
Add( 50613, "CC") 						-- Arcane Torrent (Runic Power)
Add( 20572, "BUFF_HARM") 				-- Blood Fury
Add( 20600, "BUFF_HARM") 				-- Perception
Add( 20594, "BUFF_HARM") 				-- Stoneform
Add( 20549, "CC") 						-- War Stomp
Add(  7744, "BUFF_HARM") 				-- Will of the Forsaken

-- Other
--------------------------------------------------
Add( 23506, "BUFF_HELP") 				-- Arena Grand Master trinket
Add( 23505, "BUFF_HARM") 				-- Battleground Damage buff
Add( 23493, "BUFF_HELP") 				-- Battleground Heal buff
Add( 23451, "BUFF_HARM") 				-- Battleground Speed buff
Add( 14253, "BUFF_HARM") 				-- Black Husk Shield
Add( 12733, "BUFF_HARM") 				-- Blacksmith trinket, Fear immunity
Add( 29506, "BUFF_HELP") 				-- Burrower's Shell trinket
Add( 30457, "CC") 						-- Complete Vulnerability
Add( 22734, "BUFF_OTHER") 				-- Drink
Add( 46755, "BUFF_OTHER", 22734) 		-- Drink
Add( 27089, "BUFF_OTHER", 22734) 		-- Drink
Add( 43183, "BUFF_OTHER", 22734) 		-- Drink
Add( 57073, "BUFF_OTHER", 22734) 		-- Drink
Add( 23097, "BUFF_HARM") 				-- Fire Reflector
Add(  5134, "CC") 						-- Flash Bomb
Add(  6615, "BUFF_HARM") 				-- Free Action Potion
Add( 18798, "CC") 						-- Freezing Band
Add( 23131, "BUFF_HARM") 				-- Frost Reflector
Add( 13141, "BUFF_HARM") 				-- Gnomish Rocket Boots
Add( 13237, "CC") 						-- Goblin Mortar trinket
Add(  8892, "BUFF_HARM") 				-- Goblin Rocket Boots
Add( 16621, "IMMUNITY") 				-- Invulnerable Mail
Add(  4068, "CC") 						-- Iron Grenade
Add(  3169, "IMMUNITY") 				-- Limited Invulnerability Potion
Add( 15753, "CC") 						-- Linken's Boomerang Stun
Add( 24364, "BUFF_HARM") 				-- Living Action Potion
Add(  1090, "CC") 						-- Magic Dust
Add( 13494, "BUFF_HARM") 				-- Manual Crowd Pummeler Haste buff
Add( 23723, "BUFF_HARM") 				-- Mind Quickening Gem
Add( 13099, "ROOT") 					-- Net-o-Matic
Add( 13119, "ROOT") 					-- Net-o-Matic
Add( 13120, "ROOT") 					-- Net-o-Matic
Add( 13138, "ROOT") 					-- Net-o-Matic
Add( 13139, "ROOT") 					-- Net-o-Matic
Add( 16566, "ROOT") 					-- Net-o-Matic
Add( 14530, "BUFF_HARM") 				-- Nifty Stopwatch
Add( 30456, "BUFF_HELP") 				-- Nigh-Invulnerability
Add( 23605, "BUFF_OTHER") 				-- Nightfall, Spell Vulnerability
Add( 13327, "CC") 						-- Reckless Charge
Add( 11359, "BUFF_HARM") 				-- Restorative Potion
Add( 23132, "BUFF_HARM") 				-- Shadow Reflector
Add(  5024, "BUFF_HARM") 				-- Skull of Impending Doom
Add( 33961, "IMMUNITY_SPELL") 			-- Spell Reflection (Sethekk Initiate)
Add(  9774, "BUFF_HARM") 				-- Spider Belt & Ornate Mithril Boots
Add(  9175, "BUFF_HARM") 				-- Swift Boots
Add(  2379, "BUFF_HARM") 				-- Swiftness Potion
Add( 19769, "CC") 						-- Thorium Grenade
Add(   835, "CC") 						-- Tidal Charm
