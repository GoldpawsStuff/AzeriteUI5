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

ns.AuraFilters = ns.AuraFilters or {}

-- Data
local Spells = ns.AuraData.Spells
local Hidden = ns.AuraData.Hidden
local Priority = ns.AuraData.Priority

ns.AuraFilters.PlayerAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"
	button.spellID = spellID

	-- Hide blacklisted auras.
	if (button.spellID and Hidden[button.spellID]) then
		return
	end

	-- Show whitelisted auras.
	if (button.spellID and Spells[button.spellID]) then
		return true
	end

	if (isBossDebuff) then
		return true
	end

	if (UnitAffectingCombat("player")) then
		return (not button.noDuration and duration < 301) or (button.timeLeft and button.timeLeft > 0 and button.timeLeft < 31) or (count and count > 1)
	else
		return (not button.noDuration) or (button.timeLeft and button.timeLeft > 0 and button.timeLeft < 31) or (count and count > 1)
	end

end

ns.AuraFilters.TargetAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"
	button.spellID = spellID

	-- Hide blacklisted auras.
	if (button.spellID and Hidden[button.spellID]) then
		return
	end

	-- Show whitelisted auras.
	if (button.spellID and Spells[button.spellID]) then
		return true
	end

	if (isBossDebuff) then
		return true
	end

	if (UnitAffectingCombat("player")) then
		return (not button.noDuration and duration < 301) or (count and count > 1)
	else
		if (UnitCanAttack("player", unit)) then
			return (not button.noDuration and button.duration < 301) or (count and count > 1)
		elseif (UnitPlayerControlled(unit)) then
			return (not button.noDuration) or (count and count > 1)
		else
			return true
		end
	end
end

ns.AuraFilters.PartyAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"
	button.spellID = spellID

	-- Hide blacklisted auras.
	if (button.spellID and Hidden[button.spellID]) then
		return
	end

	-- Hide the enormous amounts of self-buffs and procs.
	if (caster == unit) then
		return
	elseif (isBossDebuff) then
		return true
	elseif (button.noDuration) then
		return
	elseif (UnitAffectingCombat("player")) then
		return ((button.duration < 301) or (button.timeLeft < 31) or (count and count > 1))
	else
		if (button.isDebuff) then
			return ((button.duration > 0) or (count and count > 1))
		elseif (button.isPlayer and canApply) then
			return (button.timeLeft < 31) or (count and count > 1)
		end
	end
end

ns.AuraFilters.NameplateAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"
	button.spellID = spellID

	-- Hide blacklisted auras.
	if (button.spellID and Hidden[button.spellID]) then
		return
	end

	if (isBossDebuff) then
		return true
	elseif (isStealable) then
		return true
	elseif (button.noDuration) then
		return
	elseif (caster == "player" or caster == "pet" or caster == "vehicle") then
		if (button.isDebuff) then
			return (button.duration < 301) -- Faerie Fire is 5 mins
		else
			return (button.duration < 31) -- show short buffs, like HoTs
		end
	end
end

ns.AuraFilters.ArenaAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"
	button.spellID = spellID

	-- Hide blacklisted auras.
	if (button.spellID and Hidden[button.spellID]) then
		return
	end

	-- Show whitelisted auras.
	if (button.spellID and Spells[button.spellID]) then
		return true
	end

	if (isStealable) then
		return true
	elseif (button.noDuration) then
		return
	else
		if (UnitCanAttack("player", unit)) then
			if (button.isDebuff) then
				return (button.duration < 301)
			else
				return (button.duration < 31)
			end
		else
			if (button.isDebuff) then
				return (button.duration < 301) or (count and count > 1)
			else
				return (button.duration < 31) or (count and count > 1)
			end
		end
	end
end
