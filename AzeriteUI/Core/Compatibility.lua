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
local Addon, ns = ...

-- Backdrop template for Lua and XML
-- Allows us to always set these templates, even in Classic.
local MixinGlobal = Addon.."BackdropTemplateMixin"
_G[MixinGlobal] = {}
if (BackdropTemplateMixin) then
	_G[MixinGlobal] = CreateFromMixins(BackdropTemplateMixin) -- Usable in XML
	ns.Private.BackdropTemplate = "BackdropTemplate" -- Usable in Lua
end

-- Classics
if (not _G.UnitEffectiveLevel) then
	_G.UnitEffectiveLevel = UnitLevel
end

if (not _G.IsXPUserDisabled) then
	_G.IsXPUserDisabled = function() return false end
end

if (not _G.UnitHasVehicleUI) then
	_G.UnitHasVehicleUI = function() return false end
end

if (not _G.GetTimeToWellRested) then
	_G.GetTimeToWellRested = function() return nil end
end

local tocversion = select(4, GetBuildInfo())

-- Deprecated in 10.1.0
if (tocversion >= 100100) or (tocversion >= 40400 and tocversion < 50000) then
	if (not _G.GetAddOnMetadata) then
		_G.GetAddOnMetadata = C_AddOns.GetAddOnMetadata
	end
end

-- Deprecated in 10.2.0
if (tocversion >= 100200) or (tocversion >= 40400 and tocversion < 50000) then
	local original_SetPortraitToTexture = SetPortraitToTexture
	for method,func in next,{
		GetCVarInfo = C_CVar.GetCVarInfo,
		EnableAddOn = C_AddOns.EnableAddOn,
		DisableAddOn = C_AddOns.DisableAddOn,
		GetAddOnEnableState = function(character, name) return C_AddOns.GetAddOnEnableState(name, character) end,
		LoadAddOn = C_AddOns.LoadAddOn,
		IsAddOnLoaded = C_AddOns.IsAddOnLoaded,
		EnableAllAddOns = C_AddOns.EnableAllAddOns,
		DisableAllAddOns = C_AddOns.DisableAllAddOns,
		GetAddOnInfo = C_AddOns.GetAddOnInfo,
		GetAddOnDependencies = C_AddOns.GetAddOnDependencies,
		GetAddOnOptionalDependencies = C_AddOns.GetAddOnOptionalDependencies,
		GetNumAddOns = C_AddOns.GetNumAddOns,
		SaveAddOns = C_AddOns.SaveAddOns,
		ResetAddOns = C_AddOns.ResetAddOns,
		ResetDisabledAddOns = C_AddOns.ResetDisabledAddOns,
		IsAddonVersionCheckEnabled = C_AddOns.IsAddonVersionCheckEnabled,
		SetAddonVersionCheck = C_AddOns.SetAddonVersionCheck,
		IsAddOnLoadOnDemand = C_AddOns.IsAddOnLoadOnDemand,
		SetPortraitToTexture = function(texture, asset)
			if asset ~= nil then
				if type(texture) == "string" then
					texture = _G[texture]
				end
				original_SetPortraitToTexture(texture, asset)
			end
		end
	} do
		if (not _G[method]) then
			_G[method] = func
		end
	end
end

-- Deprecated in 10.2.5
if (tocversion >= 100205) or (tocversion >= 40400 and tocversion < 50000) then
	for method,func in next,{
		GetTimeToWellRested = function() return nil end,
		FillLocalizedClassList = function(tbl, isFemale)
			local classList = LocalizedClassList(isFemale)
			MergeTable(tbl, classList)
			return tbl
		end,
		GetSetBonusesForSpecializationByItemID = C_Item.GetSetBonusesForSpecializationByItemID,
		GetItemStats = function(itemLink, existingTable)
			local statTable = C_Item.GetItemStats(itemLink)
			if existingTable then
				MergeTable(existingTable, statTable)
				return existingTable
			else
				return statTable
			end
		end,
		GetItemStatDelta = function(itemLink1, itemLink2, existingTable)
			local statTable = C_Item.GetItemStatDelta(itemLink1, itemLink2)
			if existingTable then
				MergeTable(existingTable, statTable)
				return existingTable
			else
				return statTable
			end
		end,
		UnitAura = function(unitToken, index, filter)
			local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
			if not auraData then
				return nil
			end

			return AuraUtil.UnpackAuraData(auraData)
		end,
		UnitBuff = function(unitToken, index, filter)
			local auraData = C_UnitAuras.GetBuffDataByIndex(unitToken, index, filter)
			if not auraData then
				return nil
			end

			return AuraUtil.UnpackAuraData(auraData)
		end,
		UnitDebuff = function(unitToken, index, filter)
			local auraData = C_UnitAuras.GetDebuffDataByIndex(unitToken, index, filter)
			if not auraData then
				return nil
			end

			return AuraUtil.UnpackAuraData(auraData)
		end,
		UnitAuraBySlot = function(unitToken, index)
			local auraData = C_UnitAuras.GetAuraDataBySlot(unitToken, index)
			if not auraData then
				return nil
			end

			return AuraUtil.UnpackAuraData(auraData)
		end,
		UnitAuraSlots = C_UnitAuras.GetAuraSlots
	} do
		if (not _G[method]) then
			_G[method] = func
		end
	end
end

-- Deprecated in 10.x.x, removed in 11.0.0
if (tocversion >= 110000) then
	for method,func in next, {
		GetSpellCharges = function(...)
			local numArgs = select("#", ...)

			if (numArgs == 2) then
				local index, bookType
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
				spellChargeInfo = C_SpellBook.GetSpellBookItemCharges(index, spellBank)
			else
				local spell = select(1, ...)
				spellChargeInfo = C_Spell.GetSpellCharges(spell)
			end

			if spellChargeInfo then
				return spellChargeInfo.currentCharges,
					   spellChargeInfo.maxCharges,
					   spellChargeInfo.cooldownStartTime,
					   spellChargeInfo.cooldownDuration,
					   spellChargeInfo.chargeModRate
			end
		end,
		GetSpellCooldown = function(...)
			local numArgs = select("#", ...)
			local spellCooldownInfo = nil

			if ((numArgs == 2)) then
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
				spellCooldownInfo = C_SpellBook.GetSpellBookItemCooldown(spellOrIndex, spellBank)
			else
				local spell = select(1, ...)
				spellCooldownInfo = C_Spell.GetSpellCooldown(spell)
			end

			if spellCooldownInfo then
				return spellCooldownInfo.startTime,
					   spellCooldownInfo.duration,
					   spellCooldownInfo.isEnabled,
					   spellCooldownInfo.modRate
			end
		end,
		GetSpellCount = function(...)
			local numArgs = select("#", ...)

			if (numArgs == 2) then
				local index, bookType = ...
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
				return C_SpellBook.GetSpellBookItemCastCount(index, spellBank)
			else
				local spellIdentifier = select(1, ...)
				return C_Spell.GetSpellCastCount(spellIdentifier)
			end
		end,
		GetSpellLossOfControlCooldown = function(...)
			local numArgs = select("#", ...)

			if (numArgs == 2) then
				local index, bookType = ...
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
				return C_SpellBook.GetSpellBookItemLossOfControlCooldown(index, spellBank)
			else
				local spellIdentifier = select(1, ...)
				return C_Spell.GetSpellLossOfControlCooldown(spellIdentifier)
			end
		end,
		GetSpellLossOfControlCooldown = function(...)
			local numArgs = select("#", ...)

			if (numArgs == 2) then
				local spellSlot, bookType = ...
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
				return C_SpellBook.GetSpellBookItemLossOfControlCooldown(spellSlot, spellBank)
			else
				local spellIdentifier = select(1, ...)
				return C_Spell.GetSpellLossOfControlCooldown(spellIdentifier)
			end
		end,
		GetSpellTexture = C_Spell.GetSpellTexture,
		IsAttackSpell = function(spell)
			local isAutoAttack = C_Spell.IsAutoAttackSpell(spell)
			local isRangedAutoAttack = C_Spell.IsRangedAutoAttackSpell(spell)

			return isAutoAttack or isRangedAutoAttack
		end,
		IsAutoRepeatSpell = C_Spell.IsAutoRepeatSpell,
		IsCurrentSpell = C_Spell.IsCurrentSpell,
		IsSpellInRange = function(...)
			local numArgs = select("#", ...)

			if (numArgs == 3) then
				local index, bookType, unit = ...
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet

				return C_SpellBook.IsSpellBookItemInRange(index, spellBank, unit)
			else
				local spellName, unit = ...
				return C_Spell.IsSpellInRange(spellName, unit)
			end
		end,
		IsUsableSpell = function(...)
			local numArgs = select("#", ...)

			if (numArgs == 2) then
				local index, bookType = ...
				local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
				return C_SpellBook.IsSpellBookItemUsable(index, spellBank)
			else
				local spellIdentifier = select(1, ...)
				return C_Spell.IsSpellUsable(spellIdentifier)
			end
		end,
		GetWatchedFactionInfo = function()
			local watchedFactionData = C_Reputation.GetWatchedFactionData()

			if watchedFactionData then
				return watchedFactionData.name,
					   watchedFactionData.reaction,
					   watchedFactionData.currentReactionThreshold,
					   watchedFactionData.nextReactionThreshold,
					   watchedFactionData.currentStanding,
					   watchedFactionData.factionID
			else
				return nil
			end
		end,
		GetWatchedFactionInfo = function()
			local watchedFactionData = C_Reputation.GetWatchedFactionData()

			if watchedFactionData then
				return watchedFactionData.name,
					   watchedFactionData.reaction,
					   watchedFactionData.currentReactionThreshold,
					   watchedFactionData.nextReactionThreshold,
					   watchedFactionData.currentStanding,
					   watchedFactionData.factionID
			else
				return nil
			end
		end,
		GetNumFactions = C_Reputation.GetNumFactions,
		GetFactionInfo = function(index)
			local factionData = C_Reputation.GetFactionDataByIndex(index)

			if (factionData) then
				return factionData.name,
					   factionData.description,
					   factionData.reaction,
					   factionData.currentReactionThreshold,
					   factionData.nextReactionThreshold,
					   factionData.currentStanding,
					   factionData.atWarWith,
					   factionData.canToggleAtWar,
					   factionData.isHeader,
					   factionData.isCollapsed,
					   factionData.isHeaderWithRep,
					   factionData.isWatched,
					   factionData.isChild,
					   factionData.factionID,
					   factionData.hasBonusRepRain,
					   factionData.canSetInactive
			else
				return nil
			end
		end
	} do
		if (not _G[method]) then
			_G[method] = func
		end
	end
end
