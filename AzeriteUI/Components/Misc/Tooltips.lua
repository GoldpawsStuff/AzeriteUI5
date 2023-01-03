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
local Tooltips = ns:NewModule("Tooltips", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local _G = _G
local ipairs = ipairs
local select = select
local string_format = string.format

-- Addon API
local Colors = ns.Colors
local AbbreviateNumber = ns.API.AbbreviateNumber
local AbbreviateNumberBalanced = ns.API.AbbreviateNumberBalanced
local GetDifficultyColorByLevel = ns.API.GetDifficultyColorByLevel
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local GetUnitColor = ns.API.GetUnitColor

local UIHider = ns.Hider
local noop = ns.Noop

local BOSS_TEXTURE = [[|TInterface\TargetingFrame\UI-TargetingFrame-Skull:14:14:-2:1|t]]

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

Tooltips.SetBackdropStyle = function(self, tooltip)
	if (not tooltip) or (tooltip.IsEmbedded) or (tooltip:IsForbidden()) then return end

	tooltip:DisableDrawLayer("BACKGROUND")
	tooltip:DisableDrawLayer("BORDER")

	-- Don't want or need the extra padding here,
	-- as our current borders do not require them.
	if (tooltip == NarciGameTooltip) then

		-- Note that the WorldMap uses this to fit extra embedded stuff in,
		-- so we can't randomly just remove it from all tooltips, or stuff will break.
		-- Currently the only one we know of that needs tweaking, is the aforementioned.
		if (tooltip.SetPadding) then
			tooltip:SetPadding(0, 0, 0, 0)

			-- Don't replace method. In case editmode.
			hooksecurefunc(tooltip, "SetPadding", function(self, ...)
				local padding = 0
				for i = 1, select("#", ...) do
					padding = padding + tonumber((select(i, ...))) or 0
				end
				if (padding < .1) then
					return
				end
				self:SetPadding(0, 0, 0, 0)
			end)
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
			local drawLayer, subLevel = region:GetDrawLayer()
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
			local drawLayer, subLevel = region:GetDrawLayer()
			if (drawLayer) then
				tooltip:DisableDrawLayer(drawLayer)
			end
		end
	end

	local backdrop = Backdrops[tooltip]
	backdrop.offsetLeft = -10
	backdrop.offsetRight = 10
	backdrop.offsetTop = 18
	backdrop.offsetBottom = -18
	backdrop.offsetBar = 0
	backdrop.offsetBarBottom = -6
	backdrop:SetBackdrop(nil)
	backdrop:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	})
	backdrop:ClearAllPoints()
	backdrop:SetPoint( "LEFT", backdrop.offsetLeft, 0 )
	backdrop:SetPoint( "RIGHT", backdrop.offsetRight, 0 )
	backdrop:SetPoint( "TOP", 0, backdrop.offsetTop )
	backdrop:SetPoint( "BOTTOM", 0, backdrop.offsetBottom )
	backdrop:SetBackdropColor(.05, .05, .05, .95)

end

Tooltips.StyleTooltips = function(self, event, ...)

	if (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
	end

	for _,tooltip in pairs({
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
		_G.QuestScrollFrame.StoryTooltip,
		_G.QuestScrollFrame.CampaignTooltip,
		_G.NarciGameTooltip
	}) do
		self:SetBackdropStyle(tooltip)
	end

end

Tooltips.StyleStatusBar = function(self)

	GameTooltip.StatusBar = GameTooltipStatusBar
	GameTooltip.StatusBar:SetScript("OnValueChanged", nil)
	GameTooltip.StatusBar:SetStatusBarTexture(GetMedia("bar-progress"))
	GameTooltip.StatusBar:ClearAllPoints()
	GameTooltip.StatusBar:SetPoint("BOTTOMLEFT", GameTooltip.StatusBar:GetParent(), "BOTTOMLEFT", -1, -4)
	GameTooltip.StatusBar:SetPoint("BOTTOMRIGHT", GameTooltip.StatusBar:GetParent(), "BOTTOMRIGHT", 1, -4)
	GameTooltip.StatusBar:SetHeight(4)

	GameTooltip.StatusBar:HookScript("OnShow", function(self)
		local tooltip = self:GetParent()
		if (tooltip) then
			local backdrop = Backdrops[tooltip]
			if (backdrop) then
				backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom + backdrop.offsetBarBottom)
			end
		end
	end)

	GameTooltip.StatusBar:HookScript("OnHide", function(self)
		local tooltip = self:GetParent()
		if (tooltip) then
			local backdrop = Backdrops[tooltip]
			if (backdrop) then
				backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom)
			end
		end
	end)

	GameTooltip.StatusBar.Text = GameTooltip.StatusBar:CreateFontString(nil, "OVERLAY")
	GameTooltip.StatusBar.Text:SetPoint("CENTER", 0, 0)
	GameTooltip.StatusBar.Text:SetFontObject(GetFont(13,true))
	GameTooltip.StatusBar.Text:SetTextColor(unpack(Colors.offwhite))

end

Tooltips.SetHealthValue = function(self, unit)
	if (UnitIsDeadOrGhost(unit)) then
		if (GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Hide()
		end
	else
		local msg
		local min,max = UnitHealth(unit), UnitHealthMax(unit)
		if (min and max) then
			if (min == max) then
				msg = string_format("%s", AbbreviateNumberBalanced(min))
			else
				msg = string_format("%s / %s", AbbreviateNumber(min), AbbreviateNumber(max))
			end
		else
			msg = NOT_APPLICABLE
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

Tooltips.OnValueChanged = function(self)
	local unit = select(2, GameTooltip.StatusBar:GetParent():GetUnit())
	if (not unit) then
		local GMF = GetMouseFocus()
		if (GMF and GMF.GetAttribute and GMF:GetAttribute("unit")) then
			unit = GMF:GetAttribute("unit")
		end
	end
	if (not unit) then
		if (GameTooltip.StatusBar:IsShown()) then
			GameTooltip.StatusBar:Hide()
		end
		return
	end
	self:SetHealthValue(unit)
end

Tooltips.OnTooltipCleared = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	if (GameTooltip.StatusBar:IsShown()) then
		GameTooltip.StatusBar:Hide()
	end
end

Tooltips.OnTooltipSetSpell = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

end

Tooltips.OnTooltipSetItem = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

end

Tooltips.OnTooltipSetUnit = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

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

Tooltips.SetUnitColor = function(self, unit)
	local color = GetUnitColor(unit) or Colors.reaction[5]
	if (color) then
		GameTooltip.StatusBar:SetStatusBarColor(color[1], color[2], color[3])
	end
end

Tooltips.SetHooks = function(self)

	self:SecureHook("SharedTooltip_SetBackdropStyle", "SetBackdropStyle")
	self:SecureHook("GameTooltip_UnitColor", "SetUnitColor")
	self:SecureHook("GameTooltip_ShowCompareItem", "OnCompareItemShow")

	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "OnTooltipCleared")

	--self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "OnTooltipSetSpell")
	--self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "OnTooltipSetItem")
	--self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "OnTooltipSetUnit")

	self:SecureHookScript(GameTooltip.StatusBar, "OnValueChanged", "OnValueChanged")

end

Tooltips.OnInitialize = function(self)

	self:StyleStatusBar()
	self:StyleTooltips()
	self:SetHooks()
end

Tooltips.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
end