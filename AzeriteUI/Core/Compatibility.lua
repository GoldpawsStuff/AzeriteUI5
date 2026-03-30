--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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

-- TODO: Just stop checking for all of this and forcefully add back the API.

-- Backdrop template for Lua and XML
-- Allows us to always set these templates, even in Classic.
local MixinGlobal = Addon.."BackdropTemplateMixin"
_G[MixinGlobal] = {}
if (BackdropTemplateMixin) then
	_G[MixinGlobal] = CreateFromMixins(BackdropTemplateMixin) -- Usable in XML
	ns.Private.BackdropTemplate = "BackdropTemplate" -- Usable in Lua
end

for method,func in next,{

	-- Functions that always would return nothing
	IsXPUserDisabled = function() return false end, 
	GetTimeToWellRested = function() return nil end,
	UnitHasVehicleUI = function() return false end, 
	
	-- Namespace replacements
	AllowedToDoPartyConversion = C_PartyInfo and C_PartyInfo.AllowedToDoPartyConversion or nil,
	CanFormCrossFactionParties = C_PartyInfo and C_PartyInfo.CanFormCrossFactionParties or nil,
	CanInvite = C_PartyInfo and C_PartyInfo.CanInvite or nil,
	CanStartInstanceAbandonVote = C_PartyInfo and C_PartyInfo.CanStartInstanceAbandonVote or nil,
	ChallengeModeRestrictionsActive = C_PartyInfo and C_PartyInfo.ChallengeModeRestrictionsActive or nil,
	ConfirmConvertToRaid = C_PartyInfo and C_PartyInfo.ConfirmConvertToRaid or nil,
	ConfirmInviteTravelPass = C_PartyInfo and C_PartyInfo.ConfirmInviteTravelPass or nil,
	ConfirmInviteUnit = C_PartyInfo and C_PartyInfo.ConfirmInviteUnit or nil,
	ConfirmLeaveParty = C_PartyInfo and C_PartyInfo.ConfirmLeaveParty or nil,
	ConfirmRequestInviteFromUnit = C_PartyInfo and C_PartyInfo.ConfirmRequestInviteFromUnit or nil,
	ConvertToParty = C_PartyInfo and C_PartyInfo.ConvertToParty or nil,
	ConvertToRaid = C_PartyInfo and C_PartyInfo.ConvertToRaid or nil,
	DelveTeleportOut = C_PartyInfo and C_PartyInfo.DelveTeleportOut or nil,
	DisableAddOn = C_AddOns and C_AddOns.DisableAddOn or nil,
	DisableAllAddOns = C_AddOns and C_AddOns.DisableAllAddOns or nil,
	DoCountdown = C_PartyInfo and C_PartyInfo.DoCountdown or nil,
	EnableAddOn = C_AddOns and C_AddOns.EnableAddOn or nil,
	EnableAllAddOns = C_AddOns and C_AddOns.EnableAllAddOns or nil,
	GetActiveCategories = C_PartyInfo and C_PartyInfo.GetActiveCategories or nil,
	GetAddOnDependencies = C_AddOns and C_AddOns.GetAddOnDependencies or nil,
	GetAddOnEnableState = C_AddOns and C_AddOns.GetAddOnEnableState and function(character, name) return C_AddOns.GetAddOnEnableState(name, character) end,
	GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or nil,
	GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or nil, 
	GetAddOnOptionalDependencies = C_AddOns and C_AddOns.GetAddOnOptionalDependencies or nil,
	GetAvailableLootMethods = C_PartyInfo and C_PartyInfo.GetAvailableLootMethods or nil,
	GetCVarInfo = C_CVar and C_CVar.GetCVarInfo or nil,
	GetInstanceAbandonShutdownTime = C_PartyInfo and C_PartyInfo.GetInstanceAbandonShutdownTime or nil,
	GetInstanceAbandonVoteCooldownTime = C_PartyInfo and C_PartyInfo.GetInstanceAbandonVoteCooldownTime or nil,
	GetInstanceAbandonVoteRequirements = C_PartyInfo and C_PartyInfo.GetInstanceAbandonVoteRequirements or nil,
	GetInstanceAbandonVoteResponse = C_PartyInfo and C_PartyInfo.GetInstanceAbandonVoteResponse or nil,
	GetInstanceAbandonVoteTime = C_PartyInfo and C_PartyInfo.GetInstanceAbandonVoteTime or nil,
	GetInviteConfirmationInvalidQueues = C_PartyInfo and C_PartyInfo.GetInviteConfirmationInvalidQueues or nil,
	GetInviteReferralInfo = C_PartyInfo and C_PartyInfo.GetInviteReferralInfo or nil,
	GetLootMethod = C_PartyInfo and C_PartyInfo.GetLootMethod or nil,
	GetMinItemLevel = C_PartyInfo and C_PartyInfo.GetMinItemLevel or nil,
	GetMinLevel = C_PartyInfo and C_PartyInfo.GetMinLevel or nil,
	GetNumAddOns = C_AddOns and C_AddOns.GetNumAddOns or nil,
	GetNumFactions = C_Reputation and C_Reputation.GetNumFactions or nil,
	GetNumInstanceAbandonGroupVoteResponses = C_PartyInfo and C_PartyInfo.GetNumInstanceAbandonGroupVoteResponses or nil,
	GetRestrictPings = C_PartyInfo and C_PartyInfo.GetRestrictPings or nil,
	GetSetBonusesForSpecializationByItemID = C_Item and C_Item.GetSetBonusesForSpecializationByItemID or nil,
	GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or nil,
	InviteUnit = C_PartyInfo and C_PartyInfo.InviteUnit or nil,
	IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or nil,
	IsAddOnLoadOnDemand = C_AddOns and C_AddOns.IsAddOnLoadOnDemand or nil,
	IsAddonVersionCheckEnabled = C_AddOns and C_AddOns.IsAddonVersionCheckEnabled or nil,
	IsAutoRepeatSpell = C_Spell and C_Spell.IsAutoRepeatSpell or nil,
	IsChallengeModeActive = C_PartyInfo and C_PartyInfo.IsChallengeModeActive or nil,
	IsChallengeModeKeystoneOwner = C_PartyInfo and C_PartyInfo.IsChallengeModeKeystoneOwner or nil,
	IsCrossFactionParty = C_PartyInfo and C_PartyInfo.IsCrossFactionParty or nil,
	IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell or nil,
	IsDelveComplete = C_PartyInfo and C_PartyInfo.IsDelveComplete or nil,
	IsDelveInProgress = C_PartyInfo and C_PartyInfo.IsDelveInProgress or nil,
	IsPartyFull = C_PartyInfo and C_PartyInfo.IsPartyFull or nil,
	IsPartyInJailersTower = C_PartyInfo and C_PartyInfo.IsPartyInJailersTower or nil,
	IsPartyWalkIn = C_PartyInfo and C_PartyInfo.IsPartyWalkIn or nil,
	LeaveParty = C_PartyInfo and C_PartyInfo.LeaveParty or nil,
	LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or nil,
	RequestInviteFromUnit = C_PartyInfo and C_PartyInfo.RequestInviteFromUnit or nil,
	ResetAddOns = C_AddOns and C_AddOns.ResetAddOns or nil,
	ResetDisabledAddOns = C_AddOns and C_AddOns.ResetDisabledAddOns or nil,
	SaveAddOns = C_AddOns and C_AddOns.SaveAddOns or nil,
	SetAddonVersionCheck = C_AddOns and C_AddOns.SetAddonVersionCheck or nil,
	SetInstanceAbandonVoteResponse = C_PartyInfo and C_PartyInfo.SetInstanceAbandonVoteResponse or nil,
	SetLootMethod = C_PartyInfo and C_PartyInfo.SetLootMethod or nil,
	SetRestrictPings = C_PartyInfo and C_PartyInfo.SetRestrictPings or nil,
	StartInstanceAbandonVote = C_PartyInfo and C_PartyInfo.StartInstanceAbandonVote or nil,
	UnitAuraSlots = C_UnitAuras and C_UnitAuras.GetAuraSlots,

	-- Replacement for identical function
	UnitEffectiveLevel = UnitLevel,

	-- Rewritten old functions
	FillLocalizedClassList = LocalizedClassList and function(tbl, isFemale)
		local classList = LocalizedClassList(isFemale)
		MergeTable(tbl, classList)
		return tbl
	end or nil,
	GetFactionInfo = C_Reputation and C_Reputation.GetFactionDataByIndex and function(index)
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
	end or nil,
	GetItemStatDelta = C_Item and C_Item.GetItemStatDelta and function(itemLink1, itemLink2, existingTable)
		local statTable = C_Item.GetItemStatDelta(itemLink1, itemLink2)
		if existingTable then
			MergeTable(existingTable, statTable)
			return existingTable
		else
			return statTable
		end
	end or nil,
	GetItemStats = C_Item and C_Item.GetItemStats and function(itemLink, existingTable)
		local statTable = C_Item.GetItemStats(itemLink)
		if existingTable then
			MergeTable(existingTable, statTable)
			return existingTable
		else
			return statTable
		end
	end or nil,
	GetSpellCharges = C_Spell and C_Spell.GetSpellCharges and C_SpellBook and C_SpellBook.GetSpellBookItemCharges and Enum.SpellBookSpellBank and function(...)
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
	end or nil,
	GetSpellCooldown = C_Spell and C_Spell.GetSpellCooldown and C_SpellBook and C_SpellBook.GetSpellBookItemCooldown and Enum.SpellBookSpellBank and function(...)
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
	end or nil,
	GetSpellCount = C_SpellBook and C_SpellBook.GetSpellBookItemCastCount and C_Spell and C_Spell.GetSpellCastCount and Enum.SpellBookSpellBank and function(...)
		local numArgs = select("#", ...)
		if (numArgs == 2) then
			local index, bookType = ...
			local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
			return C_SpellBook.GetSpellBookItemCastCount(index, spellBank)
		else
			local spellIdentifier = select(1, ...)
			return C_Spell.GetSpellCastCount(spellIdentifier)
		end
	end or nil,
	GetSpellLossOfControlCooldown = C_SpellBook and C_SpellBook.GetSpellBookItemLossOfControlCooldown and C_Spell.GetSpellLossOfControlCooldown and Enum.SpellBookSpellBank and function(...)
		local numArgs = select("#", ...)
		if (numArgs == 2) then
			local spellSlot, bookType = ...
			local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
			return C_SpellBook.GetSpellBookItemLossOfControlCooldown(spellSlot, spellBank)
		else
			local spellIdentifier = select(1, ...)
			return C_Spell.GetSpellLossOfControlCooldown(spellIdentifier)
		end
	end or nil,
	GetWatchedFactionInfo = C_Reputation and C_Reputation.GetWatchedFactionData and function()
		local watchedFactionData = C_Reputation.GetWatchedFactionData()
		if (watchedFactionData) then
			return watchedFactionData.name,
					watchedFactionData.reaction,
					watchedFactionData.currentReactionThreshold,
					watchedFactionData.nextReactionThreshold,
					watchedFactionData.currentStanding,
					watchedFactionData.factionID
		else
			return nil
		end
	end or nil,
	IsAttackSpell = C_Spell and C_Spell.IsAutoAttackSpell and C_Spell.IsRangedAutoAttackSpell and function(spell)
		local isAutoAttack = C_Spell.IsAutoAttackSpell(spell)
		local isRangedAutoAttack = C_Spell.IsRangedAutoAttackSpell(spell)
		return isAutoAttack or isRangedAutoAttack
	end or nil,
	IsUsableSpell = C_SpellBook and C_SpellBook.IsSpellBookItemUsable and C_Spell and C_Spell.IsSpellUsable and Enum.SpellBookSpellBank and function(...)
		local numArgs = select("#", ...)
		if (numArgs == 2) then
			local index, bookType = ...
			local spellBank = (bookType == "spell") and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.pet
			return C_SpellBook.IsSpellBookItemUsable(index, spellBank)
		else
			local spellIdentifier = select(1, ...)
			return C_Spell.IsSpellUsable(spellIdentifier)
		end
	end or nil,
	UnitAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and AuraUtil and AuraUtil.UnpackAuraData and function(unitToken, index, filter)
		local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
		if not auraData then
			return nil
		end

		return AuraUtil.UnpackAuraData(auraData)
	end or nil,
	UnitAuraBySlot = C_UnitAuras and C_UnitAuras.GetAuraDataBySlot and AuraUtil and AuraUtil.UnpackAuraData and function(unitToken, index)
		local auraData = C_UnitAuras and C_UnitAuras.GetAuraDataBySlot(unitToken, index)
		if not auraData then
			return nil
		end
		return AuraUtil.UnpackAuraData(auraData)
	end or nil,
	UnitBuff = C_UnitAuras and C_UnitAuras.GetBuffDataByIndex and AuraUtil and AuraUtil.UnpackAuraData and function(unitToken, index, filter)
		local auraData = C_UnitAuras.GetBuffDataByIndex(unitToken, index, filter)
		if not auraData then
			return nil
		end

		return AuraUtil.UnpackAuraData(auraData)
	end or nil,
	UnitDebuff = C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex and AuraUtil and AuraUtil.UnpackAuraData and function(unitToken, index, filter)
		local auraData = C_UnitAuras.GetDebuffDataByIndex(unitToken, index, filter)
		if not auraData then
			return nil
		end

		return AuraUtil.UnpackAuraData(auraData)
	end or nil,
	
} do
	if (not _G[method]) then
		_G[method] = func
	end
end
