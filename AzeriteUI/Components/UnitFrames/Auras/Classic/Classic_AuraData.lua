--[[

	The MIT License (MIT)

	Copyright (c) 2023 Lars Norberg

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

if (not ns.IsClassic) then return end

-- Speed!
local Add = ns.AuraData.Add

-- Priority
--------------------------------------------------
Add(   770, true)		 				-- Faerie Fire
Add(   778, true)		 				-- Faerie Fire
Add(  9749, true)		 				-- Faerie Fire
Add(  9907, true)		 				-- Faerie Fire
Add( 12294, true)		 				-- Mortal Strike
Add( 21551, true)		 				-- Mortal Strike
Add( 21552, true)		 				-- Mortal Strike
Add( 21553, true)		 				-- Mortal Strike
Add(  9035, true)		 				-- Hex of Weakness
Add( 19281, true)		 				-- Hex of Weakness
Add( 19282, true)		 				-- Hex of Weakness
Add( 19283, true)		 				-- Hex of Weakness
Add( 19284, true)		 				-- Hex of Weakness
Add( 19285, true)		 				-- Hex of Weakness
Add( 23230, true)		 				-- Blood Fury Debuff
Add( 23605, true)		 				-- Nightfall, Spell Vulnerability

-- Interrupts
--------------------------------------------------
Add( 15752, "INTERRUPT") 				-- Linken's Boomerang Disarm
Add( 19244, "INTERRUPT") 				-- Spell Lock - Rank 1 (Warlock)
Add( 19647, "INTERRUPT", 19244) 		-- Spell Lock - Rank 2 (Warlock)
Add(  8042, "INTERRUPT") 				-- Earth Shock (Shaman)
Add(  8044, "INTERRUPT", 8042) 			-- Earth Shock (Shaman)
Add(  8045, "INTERRUPT", 8042) 			-- Earth Shock (Shaman)
Add(  8046, "INTERRUPT", 8042) 			-- Earth Shock (Shaman)
Add( 10412, "INTERRUPT", 8042) 			-- Earth Shock (Shaman)
Add( 10413, "INTERRUPT", 8042) 			-- Earth Shock (Shaman)
Add( 10414, "INTERRUPT", 8042) 			-- Earth Shock (Shaman)
Add( 16979, "INTERRUPT") 				-- Feral Charge (Druid)
Add(  2139, "INTERRUPT") 				-- Counterspell (Mage)
Add(  1766, "INTERRUPT") 				-- Kick (Rogue)
Add(  1767, "INTERRUPT", 1766)			-- Kick (Rogue)
Add(  1768, "INTERRUPT", 1766)			-- Kick (Rogue)
Add(  1769, "INTERRUPT", 1766)			-- Kick (Rogue)
Add( 14251, "INTERRUPT") 				-- Riposte (Rogue)
Add(  6552, "INTERRUPT") 				-- Pummel
Add(  6554, "INTERRUPT", 6552) 			-- Pummel
Add(    72, "INTERRUPT") 				-- Shield Bash
Add(  1671, "INTERRUPT", 72)			-- Shield Bash
Add(  1672, "INTERRUPT", 72)			-- Shield Bash

-- Druid
--------------------------------------------------
Add( 22812, "BUFF_HELP") 				-- Barkskin
Add(  5211, "CC") 						-- Bash
Add(  6798, "CC", 5211) 				-- Bash
Add(  8983, "CC", 5211) 				-- Bash
Add(  1850, "BUFF_HARM") 				-- Dash
Add(  9821, "BUFF_HARM", 1850) 			-- Dash
Add(   339, "ROOT") 					-- Entangling Roots
Add(  1062, "ROOT", 339) 				-- Entangling Roots
Add(  5195, "ROOT", 339) 				-- Entangling Roots
Add(  5196, "ROOT", 339) 				-- Entangling Roots
Add(  9852, "ROOT", 339) 				-- Entangling Roots
Add(  9853, "ROOT", 339) 				-- Entangling Roots
Add(   770, "BUFF_OTHER") 				-- Faerie Fire
Add(   778, "BUFF_OTHER", 770) 			-- Faerie Fire
Add(  9749, "BUFF_OTHER", 770) 			-- Faerie Fire
Add(  9907, "BUFF_OTHER", 770) 			-- Faerie Fire
--Add(16979, "ROOT") 					-- Feral Charge Stun (TODO: invalid spellId)
Add(  2637, "CC") 						-- Hibernate
Add( 18657, "CC", 2637) 				-- Hibernate
Add( 18658, "CC", 2637) 				-- Hibernate
Add( 29166, "BUFF_HARM") 				-- Innervate
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
Add(  9005, "CC") 						-- Pounce Stun
Add(  9823, "CC", 9005) 				-- Pounce Stun
Add(  9827, "CC", 9005) 				-- Pounce Stun
Add( 16922, "CC") 						-- Starfire Stun

-- Hunter
--------------------------------------------------
Add( 13159, "BUFF_HARM") 				-- Aspect of the Pack
Add(  5118, "BUFF_HARM", 13159) 		-- Aspect of the Cheetah
Add( 19574, "BUFF_HARM") 				-- Bestial Wrath
Add( 25999, "ROOT") 					-- Boar Charge
Add( 19410, "CC") 						-- Concussive Shot Stun
Add( 19306, "ROOT") 					-- Counterattack Root
Add( 19263, "BUFF_HELP") 				-- Deterrence
Add( 19185, "ROOT") 					-- Entrapment
Add(  3355, "CC") 						-- Freezing Trap
Add( 14308, "CC", 3355) 				-- Freezing Trap
Add( 14309, "CC", 3355) 				-- Freezing Trap
Add(  3045, "BUFF_HARM") 				-- Rapid Fire
Add(  1513, "CC") 						-- Scare Beast
Add( 14326, "CC", 1513) 				-- Scare Beast
Add( 14327, "CC", 1513) 				-- Scare Beast
Add( 19503, "CC") 						-- Scatter Shot
Add(  3034, "ROOT") 					-- Viper Sting
Add( 14279, "ROOT", 3034) 				-- Viper Sting
Add( 14280, "ROOT", 3034) 				-- Viper Sting
Add( 19229, "ROOT") 					-- Wing Clip Root
Add( 20909, "ROOT", 19306) 				-- Wing Clip Root
Add( 20910, "ROOT", 19306) 				-- Wing Clip Root
Add( 19386, "CC") 						-- Wyvern Sting
Add( 24132, "CC", 19386) 				-- Wyvern Sting
Add( 24133, "CC", 19386) 				-- Wyvern Sting

-- Mage
--------------------------------------------------
Add( 12042, "BUFF_HARM") 				-- Arcane Power
Add( 12051, "BUFF_HARM") 				-- Evocation
Add(   543, "BUFF_HELP") 				-- Fire Ward
Add(  8457, "BUFF_HELP", 543) 			-- Fire Ward
Add(  8458, "BUFF_HELP", 543) 			-- Fire Ward
Add( 10223, "BUFF_HELP", 543) 			-- Fire Ward
Add( 10225, "BUFF_HELP", 543) 			-- Fire Ward
Add(   122, "ROOT") 					-- Frost Nova
Add(   865, "ROOT", 122) 				-- Frost Nova
Add(  6131, "ROOT", 122) 				-- Frost Nova
Add( 10230, "ROOT", 122) 				-- Frost Nova
Add(  6143, "BUFF_HELP") 				-- Frost Ward
Add(  8461, "BUFF_HELP", 6143) 			-- Frost Ward
Add(  8462, "BUFF_HELP", 6143) 			-- Frost Ward
Add( 10177, "BUFF_HELP", 6143) 			-- Frost Ward
Add( 28609, "BUFF_HELP", 6143) 			-- Frost Ward
Add( 12494, "ROOT") 					-- Frostbite
Add( 11426, "BUFF_HELP") 				-- Ice Barrier
Add( 13031, "CC", 11426) 				-- Ice Barrier
Add( 13032, "CC", 11426) 				-- Ice Barrier
Add( 13033, "CC", 11426) 				-- Ice Barrier
Add( 11958, "IMMUNITY") 				-- Ice Block
Add( 12355, "CC") 						-- Impact Stun
Add( 18469, "CC") 						-- Improved Counterspell
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

-- Paladin
--------------------------------------------------
Add(  1044, "BUFF_HELP") 				-- Blessing of Freedom
Add(  1022, "IMMUNITY") 				-- Blessing of Protection
Add(  5599, "IMMUNITY", 1022) 			-- Blessing of Protection
Add( 10278, "IMMUNITY", 1022) 			-- Blessing of Protection
Add(  6940, "BUFF_HELP") 				-- Blessing of Sacrifice
Add( 20729, "BUFF_HELP", 6940) 			-- Blessing of Sacrifice
Add(   498, "IMMUNITY") 				-- Divine Shield
Add(  5573, "IMMUNITY", 498) 			-- Divine Shield
Add(   642, "IMMUNITY", 498) 			-- Divine Shield
Add(  1020, "IMMUNITY", 498) 			-- Divine Shield
Add(   853, "CC") 						-- Hammer of Justice
Add(  5588, "CC", 853) 					-- Hammer of Justice
Add(  5589, "CC", 853) 					-- Hammer of Justice
Add( 10308, "CC", 853) 					-- Hammer of Justice
Add( 20066, "CC") 						-- Repentance
Add( 20170, "CC") 						-- Seal of Justice stun

-- Priest
--------------------------------------------------
Add( 15269, "CC") 						-- Blackout
Add( 14892, "BUFF_HELP") 				-- Inspiration
Add( 15362, "BUFF_HELP", 14892) 		-- Inspiration
Add( 15363, "BUFF_HELP", 14892) 		-- Inspiration
Add(   605, "CC") 						-- Mind Control
Add( 10911, "CC", 605) 					-- Mind Control
Add( 10912, "CC", 605) 					-- Mind Control
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
Add(  8122, "CC") 						-- Psychic Scream
Add(  8124, "CC", 8122) 				-- Psychic Scream
Add( 10888, "CC", 8122) 				-- Psychic Scream
Add( 10890, "CC", 8122) 				-- Psychic Scream
Add( 15487, "CC") 						-- Silence

-- Rogue
--------------------------------------------------
Add( 13750, "BUFF_HARM") 				-- Adrenaline Rush
Add( 13877, "BUFF_HARM") 				-- Blade Flurry
Add(  2094, "CC") 						-- Blind
Add(  1833, "CC") 						-- Cheap Shot
Add(  3409, "ROOT") 					-- Crippling Poison
Add( 11201, "ROOT", 3409) 				-- Crippling Poison
Add(  5277, "BUFF_HELP") 				-- Evasion
Add( 14278, "BUFF_HELP") 				-- Ghostly Strike
Add(  1776, "CC") 						-- Gouge
Add(  1777, "CC", 1776) 				-- Gouge
Add(  8629, "CC", 1776) 				-- Gouge
Add( 11285, "CC", 1776) 				-- Gouge
Add( 11286, "CC", 1776) 				-- Gouge
Add( 18425, "CC") 						-- Improved Kick
Add(   408, "CC") 						-- Kidney Shot
Add(  8643, "CC", 408) 					-- Kidney Shot
Add(  2070, "CC") 						-- Sap
Add(  6770, "CC", 2070) 				-- Sap
Add( 11297, "CC", 2070) 				-- Sap
Add(  2983, "BUFF_HARM") 				-- Sprint
Add(  8696, "BUFF_HARM", 2983) 			-- Sprint
Add( 11305, "BUFF_HARM", 2983) 			-- Sprint

-- Shaman
--------------------------------------------------
Add( 12548, "ROOT") 					-- Frost Shock
Add(  8178, "IMMUNITY") 				-- Grounding Totem Effect
Add( 16188, "BUFF_HELP") 				-- Nature's Swiftness

-- Warlock
--------------------------------------------------
Add(   710, "CC") 						-- Banish
Add( 18647, "CC", 710) 					-- Banish
Add( 18223, "ROOT") 					-- Curse of Exhaustion
Add( 18310, "ROOT", 18223) 				-- Curse of Exhaustion
Add( 18313, "ROOT", 18223) 				-- Curse of Exhaustion
Add(  1714, "ROOT") 					-- Curse of Tongues
Add( 11719, "ROOT", 1714) 				-- Curse of Tongues
Add(  6789, "CC") 						-- Death Coil
Add( 17925, "CC", 6789) 				-- Death Coil
Add( 17926, "CC", 6789) 				-- Death Coil
Add(  5782, "CC") 						-- Fear
Add(  6213, "CC", 5782) 				-- Fear
Add(  6215, "CC", 5782) 				-- Fear
Add(  5484, "CC") 						-- Howl of Terror
Add( 17928, "CC", 5484) 				-- Howl of Terror
Add( 18093, "CC") 						-- Pyroclasm
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
Add( 24259, "CC") 						-- Spell Lock Silence

-- Warrior
--------------------------------------------------
Add( 18499, "BUFF_HARM") 				-- Berserker Rage
Add(  7922, "CC") 						-- Charge Stun
Add( 12809, "CC") 						-- Concussion Blow
Add( 12328, "BUFF_HARM") 				-- Death Wish
Add( 23694, "ROOT") 					-- Improved Hamstring
Add( 18498, "CC") 						-- Improved Shield Bash
Add( 20253, "CC") 						-- Intercept Stun
Add( 20614, "CC", 20253) 				-- Intercept Stun
Add( 20615, "CC", 20253) 				-- Intercept Stun
Add(  5246, "CC") 						-- Intimidating Shout (Other targets)
Add( 20511, "CC", 5246) 				-- Intimidating Shout (Main target)
Add(  5530, "CC") 						-- Mace Spec Stun (Warrior & Rogue)
Add(  1719, "BUFF_HARM") 				-- Recklessness
Add( 20230, "IMMUNITY") 				-- Retaliation
Add( 12798, "CC") 						-- Revenge Stun
Add(   871, "BUFF_HELP") 				-- Shield Wall

-- Racials
--------------------------------------------------
Add( 20600, "BUFF_HARM") 				-- Perception
Add( 20594, "BUFF_HARM") 				-- Stoneform
Add( 20549, "CC") 						-- War Stomp
Add(  7744, "BUFF_HARM") 				-- Will of the Forsaken

-- Other
--------------------------------------------------
Add( 23506, "BUFF_HELP") 				-- Arena Grand Master trinket
Add( 23451, "BUFF_HARM") 				-- Battleground Speed buff
Add( 23493, "BUFF_HELP") 				-- Battleground Heal buff
Add( 23505, "BUFF_HARM") 				-- Battleground Damage buff
Add( 14253, "BUFF_HARM") 				-- Black Husk Shield
Add( 12733, "BUFF_HARM") 				-- Blacksmith trinket, Fear immunity
Add( 29506, "BUFF_HELP") 				-- Burrower's Shell trinket
Add( 22734, "BUFF_OTHER") 				-- Drink
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
Add( 14530, "BUFF_HARM") 				-- Nifty Stopwatch
Add( 23605, "BUFF_OTHER") 				-- Nightfall, Spell Vulnerability
Add( 13327, "CC") 						-- Reckless Charge
Add( 11359, "BUFF_HARM") 				-- Restorative Potion
Add( 23132, "BUFF_HARM") 				-- Shadow Reflector
Add(  5024, "BUFF_HARM") 				-- Skull of Impending Doom
Add(  9774, "BUFF_HARM") 				-- Spider Belt & Ornate Mithril Boots
Add(  9175, "BUFF_HARM") 				-- Swift Boots
Add(  2379, "BUFF_HARM") 				-- Swiftness Potion
Add( 19769, "CC") 						-- Thorium Grenade
Add(   835, "CC") 						-- Tidal Charm
