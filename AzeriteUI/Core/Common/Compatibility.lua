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
