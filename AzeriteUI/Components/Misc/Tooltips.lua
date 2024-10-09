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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local Tooltips = ns:NewModule("Tooltips", ns.MovableModulePrototype, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local _G = _G
local ipairs = ipairs
local next = next
local rawget = rawget
local rawset = rawset
local select = select
local setmetatable = setmetatable
local string_find = string.find
local string_format = string.format
local string_match = string.match
local tonumber = tonumber
local unpack = unpack

-- GLOBALS: C_UnitAuras, CreateFrame, GetMouseFocus, hooksecurefunc
-- GLOBALS: GameTooltip, GameTooltipTextLeft1, GameTooltipStatusBar, UIParent
-- GLOBALS: UnitAura, UnitClass, UnitExists, UnitEffectiveLevel, UnitHealth, UnitHealthMax, UnitName, UnitRealmRelationship, UnitIsDeadOrGhost, UnitIsPlayer
-- GLOBALS: LE_REALM_RELATION_COALESCED, LE_REALM_RELATION_VIRTUAL, FOREIGN_SERVER_LABEL, INTERACTIVE_SERVER_LABEL
-- GLOGALS: NarciGameTooltip

-- Addon API
local Colors = ns.Colors
local AbbreviateNumber = ns.API.AbbreviateNumber
local AbbreviateNumberBalanced = ns.API.AbbreviateNumberBalanced
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local GetUnitColor = ns.API.GetUnitColor
local UIHider = ns.Hider

local Backdrops = setmetatable({}, { __index = function(t,k)
	local bg = CreateFrame("Frame", nil, k, ns.BackdropTemplate)
	bg:SetAllPoints()
	bg:SetFrameLevel(k:GetFrameLevel())
	-- Hook into tooltip framelevel changes.
	-- Might help with some of the conflicts experienced with Silverdragon and Raider.IO
	hooksecurefunc(k, "SetFrameLevel", function(self) bg:SetFrameLevel(self:GetFrameLevel()) end)
	rawset(t,k,bg)
	return bg
end })

local defaults = { profile = ns:Merge({
	theme = "Classic",
	showItemID = false,
	showSpellID = false,
	showGuildName = false,
	anchor = true,
	anchorToCursor = false,
	hideInCombat = false,
	hideActionBarTooltipsInCombat = true,
	hideUnitFrameTooltipsInCombat = true
}, ns.MovableModulePrototype.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Tooltips.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "BOTTOMRIGHT",
		[2] = -319 * ns.API.GetEffectiveScale(),
		[3] = 166 * ns.API.GetEffectiveScale()
	}
	return defaults
end

Tooltips.UpdateBackdropTheme = function(self, tooltip)
	if (not tooltip) or (tooltip.IsEmbedded) or (tooltip:IsForbidden()) then return end

	-- Only do this once.
	if (not rawget(Backdrops, tooltip)) then
		tooltip:DisableDrawLayer("BACKGROUND")
		tooltip:DisableDrawLayer("BORDER")

		-- Don't want or need the extra padding here,
		-- as our current borders do not require them.
		if (NarciGameTooltip and tooltip == NarciGameTooltip) then

			-- Note that the WorldMap uses this to fit extra embedded stuff in,
			-- so we can't randomly just remove it from all tooltips, or stuff will break.
			-- Currently the only one we know of that needs tweaking, is the aforementioned.
			if (tooltip.SetPadding) then
				tooltip:SetPadding(0, 0, 0, 0)

				if (not self:IsHooked(tooltip, "SetPadding")) then
					-- Use a local copy to avoid hook looping.
					local setPadding = tooltip.SetPadding

					self:SecureHook(tooltip, "SetPadding", function(self, ...)
						--local padding = 0
						--for i = 1, select("#", ...) do
						--	padding = padding + tonumber((select(i, ...))) or 0
						--end
						--if (padding < .1) then
						--	return
						--end
						setPadding(self, 0, 0, 0, 0)
					end)
				end
			end
		end

		-- Glorious 9.1.5 crap
		-- They decided to move the entire backdrop into its own hashed frame.
		-- We like this, because it makes it easier to kill. Kill. Kill. Kill. Kill.
		if (tooltip.NineSlice) then
			tooltip.NineSlice:SetParent(UIHider)
		end

		-- Textures in the combat pet tooltips
		for _,texName in ipairs({
			"BorderTopLeft",
			"BorderTopRight",
			"BorderBottomRight",
			"BorderBottomLeft",
			"BorderTop",
			"BorderRight",
			"BorderBottom",
			"BorderLeft",
			"Background"
		}) do
			local region = self[texName]
			if (region) then
				region:SetTexture(nil)
				local drawLayer = region:GetDrawLayer()
				if (drawLayer) then
					tooltip:DisableDrawLayer(drawLayer)
				end
			end
		end

		-- Region names sourced from SharedXML\NineSlice.lua
		-- *Majority of this, if not all, was moved into frame.NineSlice in 9.1.5
		for _,pieceName in ipairs({
			"TopLeftCorner",
			"TopRightCorner",
			"BottomLeftCorner",
			"BottomRightCorner",
			"TopEdge",
			"BottomEdge",
			"LeftEdge",
			"RightEdge",
			"Center"
		}) do
			local region = tooltip[pieceName]
			if (region) then
				region:SetTexture(nil)
				local drawLayer = region:GetDrawLayer()
				if (drawLayer) then
					tooltip:DisableDrawLayer(drawLayer)
				end
			end
		end
	end

	local db = ns.GetConfig("Tooltips").themes[self.db.profile.theme].backdropStyle

	-- Store some values locally for faster updates.
	local backdrop = Backdrops[tooltip]
	backdrop.offsetLeft = db.offsetLeft
	backdrop.offsetRight = db.offsetRight
	backdrop.offsetTop = db.offsetTop
	backdrop.offsetBottom = db.offsetBottom
	backdrop.offsetBar = db.offsetBar
	backdrop.offsetBarBottom = db.offsetBarBottom

	-- Setup the backdrop theme.
	backdrop:SetBackdrop(nil)
	backdrop:SetBackdrop(db.backdrop)
	backdrop:ClearAllPoints()
	backdrop:SetPoint("LEFT", backdrop.offsetLeft, 0)
	backdrop:SetPoint("RIGHT", backdrop.offsetRight, 0)
	backdrop:SetPoint("TOP", 0, backdrop.offsetTop)
	backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom)
	backdrop:SetBackdropColor(unpack(db.backdropColor))
	backdrop:SetBackdropBorderColor(unpack(db.backdropBorderColor))

end

Tooltips.UpdateStatusBarTheme = function(self)

	local db = ns.GetConfig("Tooltips").themes[self.db.profile.theme].barStyle

	GameTooltip.StatusBar = GameTooltipStatusBar

	local bar = GameTooltip.StatusBar
	bar:SetScript("OnValueChanged", nil)
	bar:SetStatusBarTexture(db.texture)
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOMLEFT", bar:GetParent(), "BOTTOMLEFT", db.offsetLeft, db.offsetBottom)
	bar:SetPoint("BOTTOMRIGHT", bar:GetParent(), "BOTTOMRIGHT", -db.offsetRight, db.offsetBottom)
	bar:SetHeight(db.height)

	if (not self:IsHooked(bar, "OnShow")) then
		bar:HookScript("OnShow", function(self)
			local tooltip = self:GetParent()
			if (tooltip) then
				local backdrop = rawget(Backdrops, tooltip)
				if (backdrop) then
					backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom + backdrop.offsetBarBottom)
					Tooltips:OnValueChanged() -- Force an update to the bar's health value and color.
				end
			end
		end)
	end

	if (not self:IsHooked(bar, "OnHide")) then
		bar:HookScript("OnHide", function(self)
			local tooltip = self:GetParent()
			if (tooltip) then
				local backdrop = rawget(Backdrops, tooltip)
				if (backdrop) then
					backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom)
				end
			end
		end)
	end

	bar.Text = bar.Text or GameTooltip.StatusBar:CreateFontString(nil, "OVERLAY")
	bar.Text:SetPoint(unpack(db.valuePosition))
	bar.Text:SetFontObject(db.valueFont)
	bar.Text:SetTextColor(unpack(db.valueColor))

end

Tooltips.UpdateTooltipThemes = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "UpdateTooltipThemes")
	end

	for _,tooltip in next,{
		_G.ItemRefTooltip,
		_G.ItemRefShoppingTooltip1,
		_G.ItemRefShoppingTooltip2,
		_G.FriendsTooltip,
		_G.WarCampaignTooltip,
		_G.EmbeddedItemTooltip,
		_G.ReputationParagonTooltip,
		_G.GameTooltip,
		_G.ShoppingTooltip1,
		_G.ShoppingTooltip2,
		_G.QuickKeybindTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.StoryTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.CampaignTooltip,
		_G.NarciGameTooltip
	} do
		self:UpdateBackdropTheme(tooltip)
	end

	self:UpdateStatusBarTheme()
end

Tooltips.SetHealthValue = function(self, unit)

	-- It could be a wall or gate that does not count as a unit,
	-- so we need to check for the existence as well as it's alive status.
	if (UnitExists(unit) and UnitIsDeadOrGhost(unit)) then
		if (GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Hide()
		end
	else

		local msg, min, max

		if (unit) then
			local min, max = UnitHealth(unit), UnitHealthMax(unit)
			if (min == max) then
				msg = string_format("%s", AbbreviateNumberBalanced(min))
			else
				msg = string_format("%s / %s", AbbreviateNumber(min), AbbreviateNumber(max))
			end
		else
			local min,_,max = GameTooltip.StatusBar:GetValue(), GameTooltip.StatusBar:GetMinMaxValues()
			if (max > 100) then
				if (min == max) then
					msg = string_format("%s", AbbreviateNumberBalanced(min))
				else
					msg = string_format("%s / %s", AbbreviateNumber(min), AbbreviateNumber(max))
				end
			else
				msg = string_format("%.0f%%", min/max*100)
			end
			--msg = NOT_APPLICABLE
		end

		GameTooltip.StatusBar.Text:SetText(msg)

		if (not GameTooltip.StatusBar.Text:IsShown()) then
			GameTooltip.StatusBar.Text:Show()
		end

		if (not GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Show()
		end
	end
end

Tooltips.SetStatusBarColor = function(self, unit)
	local color = unit and GetUnitColor(unit)
	if (color) then
		GameTooltip.StatusBar:SetStatusBarColor(color[1], color[2], color[3])
	else
		local r, g, b = GameTooltipTextLeft1:GetTextColor()
		GameTooltip.StatusBar:SetStatusBarColor(r, g, b)
	end
end

Tooltips.OnValueChanged = function(self)
	local unit = select(2, GameTooltip.StatusBar:GetParent():GetUnit())

	if (not unit) then
		-- Removed in 11.0.0.
		local GMF = GetMouseFocus and GetMouseFocus()
		if (GMF and GMF.GetAttribute and GMF:GetAttribute("unit")) then
			unit = GMF:GetAttribute("unit")
		end
	end

	--if (not unit) then
	--	if (GameTooltip.StatusBar:IsShown()) then
	--		GameTooltip.StatusBar:Hide()
	--	end
	--	return
	--end

	self:SetHealthValue(unit)
	self:SetStatusBarColor(unit)
end

Tooltips.OnTooltipCleared = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	if (GameTooltip.StatusBar:IsShown()) then
		GameTooltip.StatusBar:Hide()
	end
end

Tooltips.OnTooltipSetSpell = function(self, tooltip, data)
	if (not self.db.profile.showSpellID) then return end

	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local id = (data and data.id) or select(2, tooltip:GetSpell())
	if (not id) then return end

	local ID = string_format("|cFFCA3C3C%s|r %d", ID, id)

	-- talent tooltips gets set twice, so let's avoid double ids
	for i = 3, tooltip:NumLines() do
		local line = _G[string_format("GameTooltipTextLeft%d", i)]
		local text = line and line:GetText()
		if (text and string_find(text, ID)) then
			return
		end
	end

	tooltip:AddLine(" ")
	tooltip:AddLine(ID)
	tooltip:Show()
end

Tooltips.OnTooltipSetItem = function(self, tooltip, data)
	if (not self.db.profile.showItemID) then return end

	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local itemID

	if (tooltip.GetItem) then -- Some tooltips don't have this func. Example - compare tooltip
		local _, link = tooltip:GetItem()
		if (link) then
			itemID = string_format("|cFFCA3C3C%s|r %s", ID, (data and data.id) or string_match(link, ":(%w+)"))
		end
	else
		local id = data and data.id
		if (id) then
			itemID = string_format("|cFFCA3C3C%s|r %s", ID, id)
		end
	end

	if (itemID) then
		tooltip:AddLine(" ")
		tooltip:AddLine(itemID)
		tooltip:Show()
	end

end

Tooltips.OnTooltipSetUnit = function(self, tooltip, data)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local _, unit = tooltip:GetUnit()
	if not unit then
		local GMF = GetMouseFocus and GetMouseFocus()
		local focusUnit = GMF and GMF.GetAttribute and GMF:GetAttribute("unit")
		if focusUnit then unit = focusUnit end
		if not unit or not UnitExists(unit) then
			return
		end
	end

	local color = GetUnitColor(unit)
	if (color) then

		local unitName, unitRealm = UnitName(unit)
		local displayName = color.colorCode..unitName.."|r"
		local gray = Colors.quest.gray.colorCode
		local levelText

		if (UnitIsPlayer(unit)) then
			if (unitRealm and unitRealm ~= "") then
				local relationship = UnitRealmRelationship(unit)
				if (relationship == _G.LE_REALM_RELATION_COALESCED) then
					displayName = displayName ..gray.. _G.FOREIGN_SERVER_LABEL .."|r"

				elseif (relationship == _G.LE_REALM_RELATION_VIRTUAL) then
					displayName = displayName ..gray..  _G.INTERACTIVE_SERVER_LABEL .."|r"
				end
			end
			if (UnitIsAFK(unit)) then
				displayName = displayName ..gray.. " <" .. _G.AFK ..">|r"
			end
		end

		if (levelText) then
			_G.GameTooltipTextLeft1:SetText(levelText .. gray .. ": |r" .. displayName)
		else
			_G.GameTooltipTextLeft1:SetText(displayName)
		end

	end

end

Tooltips.OnCompareItemShow = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	local frameLevel = GameTooltip:GetFrameLevel()
	for i = 1, 2 do
		local tooltip = _G["ShoppingTooltip"..i]
		if (tooltip:IsShown()) then
			if (frameLevel == tooltip:GetFrameLevel()) then
				tooltip:SetFrameLevel(i+1)
			end
		end
	end
end

Tooltips.SetUnitAura = function(self, tooltip, unit, index, filter)
	if (not self.db.profile.showSpellID) then return end

	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local name, _, _, _, _, _, source, _, _, spellID = UnitAura(unit, index, filter)
	if (not name) then return end

	if (source) then
		local _, class = UnitClass(source)
		local color = Colors.class[class or "PRIEST"]
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(string_format("|cFFCA3C3C%s|r %s", ID, spellID), string_format("%s%s|r", color.colorCode, UnitName(source) or UNKNOWN))
	else
		tooltip:AddLine(" ")
		tooltip:AddLine(string_format("|cFFCA3C3C%s|r %s", ID, spellID))
	end

	tooltip:Show()
end

Tooltips.SetUnitAuraInstanceID = function(self, tooltip, unit, auraInstanceID)
	if (not self.db.profile.showSpellID) then return end

	local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
	if (not data or not data.name) then return end

	if (data.sourceUnit) then
		local _, class = UnitClass(data.sourceUnit)
		local color = Colors.class[class or "PRIEST"]
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(string_format("|cFFCA3C3C%s|r %s", ID, data.spellId), string_format("%s%s|r", color.colorCode, UnitName(data.sourceUnit) or UNKNOWN))
	else
		tooltip:AddLine(" ")
		tooltip:AddLine(string_format("|cFFCA3C3C%s|r %s", ID, data.spellId))
	end

	tooltip:Show()
end

Tooltips.SetDefaultAnchor = function(self, tooltip, parent)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	if (not self.db.profile.anchor) then return end

	local config = self.db.profile.savedPosition

	if (self.db.profile.anchorToCursor) then

		tooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		tooltip:SetScale(config.scale)

	else

		local x = string_find(config[1], "LEFT") and 10 or string_find(config[1], "RIGHT") and -10 or 0
		local y = string_find(config[1], "TOP") and -18 or string_find(config[1], "BOTTOM") and 18 or 0

		tooltip:SetOwner(parent, "ANCHOR_NONE")
		tooltip:SetScale(config.scale)
		tooltip:ClearAllPoints()
		tooltip:SetPoint(config[1], UIParent, config[1], (config[2] + x)/config.scale, (config[3] + y)/config.scale)
	end

end

Tooltips.SetHooks = function(self)

	self:SecureHook("SharedTooltip_SetBackdropStyle", "UpdateBackdropTheme")
	self:SecureHook("GameTooltip_UnitColor", "SetStatusBarColor")
	self:SecureHook("GameTooltip_ShowCompareItem", "OnCompareItemShow")
	self:SecureHook("GameTooltip_SetDefaultAnchor", "SetDefaultAnchor")

	if (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, ...) self:OnTooltipSetSpell(tooltip, ...) end)
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, ...) self:OnTooltipSetItem(tooltip, ...) end)
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, ...) self:OnTooltipSetUnit(tooltip, ...) end)
	else
		self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "OnTooltipSetSpell")
		self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "OnTooltipSetItem")
		self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "OnTooltipSetUnit")
	end

	self:SecureHook(GameTooltip, "SetUnitAura", "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitBuff", "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitDebuff", "SetUnitAura")

	if (ns.WoW10) then
		self:SecureHook(GameTooltip, "SetUnitBuffByAuraInstanceID", "SetUnitAuraInstanceID")
		self:SecureHook(GameTooltip, "SetUnitDebuffByAuraInstanceID", "SetUnitAuraInstanceID")
	end

	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "OnTooltipCleared")
	self:SecureHookScript(GameTooltip.StatusBar, "OnValueChanged", "OnValueChanged")

end

Tooltips.UpdateAnchor = function(self)
	local config = self.db.profile.savedPosition

	self.anchor:SetSize(250, 120)
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

Tooltips.UpdateSettings = function(self)
	self:UpdateTooltipThemes()
end

Tooltips.PostUpdatePositionAndScale = function(self)
	GameTooltip:SetScale(self.db.profile.savedPosition.scale * ns.API.GetEffectiveScale())
end

Tooltips.OnEnable = function(self)

	if (ns.WoW10) then
		GameTooltipDefaultContainer.HighlightSystem = ns.Noop
		GameTooltipDefaultContainer.ClearHighlight = ns.Noop
	end

	self:UpdateTooltipThemes()
	self:SetHooks()

	self:CreateAnchor(L["Tooltips"])

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateTooltipThemes")

	ns.MovableModulePrototype.OnEnable(self)
end
