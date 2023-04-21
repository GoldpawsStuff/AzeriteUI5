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
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local _G = _G
local ipairs = ipairs
local select = select
local string_find = string.find
local string_format = string.format
local string_match = string.match

-- WoW API
local TooltipDataType = Enum.TooltipDataType
local AddTooltipPostCall = TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall

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

local defaults = { profile = ns:Merge({
	enabled = true
}, ns.moduleDefaults) }
if (not ns.IsRetail) then
	defaults.profile.savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "BOTTOMRIGHT",
			[2] = -319,
			[3] = 166
		}
	}
end

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
		_G.QuestScrollFrame and _G.QuestScrollFrame.StoryTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.CampaignTooltip,
		_G.NarciGameTooltip
	}) do
		if (tooltip) then
			self:SetBackdropStyle(tooltip)
		end
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

Tooltips.OnTooltipSetSpell = function(self, tooltip, data)
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
	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local itemID

	if (tooltip.GetItem) then -- Some tooltips don't have this func. Example - compare tooltip
		local name, link = tooltip:GetItem()
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
		local GMF = GetMouseFocus()
		local focusUnit = GMF and GMF.GetAttribute and GMF:GetAttribute("unit")
		if focusUnit then unit = focusUnit end
		if not unit or not UnitExists(unit) then
			return
		end
	end

	if (UnitIsPlayer(unit)) then
		local color = GetUnitColor(unit)
		if (color) then

			local unitName, unitRealm = UnitName(unit)
			local unitEffectiveLevel = UnitEffectiveLevel(unit)
			local displayName = color.colorCode..unitName.."|r"
			local gray = Colors.quest.gray.colorCode
			local levelText

			--if (unitEffectiveLevel and unitEffectiveLevel > 0) then
			--	local r, g, b, colorCode = GetDifficultyColorByLevel(unitEffectiveLevel)
			--	levelText = colorCode .. unitEffectiveLevel .. "|r"
			--end
			--if (not levelText) then
			--	displayName = BOSS_TEXTURE .. " " .. displayName
			--end


			if (unitRealm and unitRealm ~= "") then

				local relationship = UnitRealmRelationship(unit)
				if (relationship == _G.LE_REALM_RELATION_COALESCED) then
					displayName = displayName ..gray.. _G.FOREIGN_SERVER_LABEL .."|r"

				elseif (relationship == _G.LE_REALM_RELATION_VIRTUAL) then
					displayName = displayName ..gray..  _G.INTERACTIVE_SERVER_LABEL .."|r"
				end
			end

			if (levelText) then
				_G.GameTooltipTextLeft1:SetText(levelText .. gray .. ": |r" .. displayName)
			else
				_G.GameTooltipTextLeft1:SetText(displayName)
			end

		end

	end

end

Tooltips.SetUnitAura = function(self, tooltip, unit, index, filter)
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

Tooltips.SetDefaultAnchor = function(self, tooltip, parent)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local point, x, y = unpack(self.db.profile.savedPosition.Azerite)

	tooltip:SetOwner(parent, "ANCHOR_NONE")
	tooltip:ClearAllPoints()
	tooltip:SetPoint(point, self.frame, point)
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

	if (not ns.IsRetail) then
		self:SecureHook("GameTooltip_SetDefaultAnchor", "SetDefaultAnchor")
	end

	if (AddTooltipPostCall) then
		AddTooltipPostCall(TooltipDataType.Spell, function(tooltip, ...) self:OnTooltipSetSpell(tooltip, ...) end)
		AddTooltipPostCall(TooltipDataType.Item, function(tooltip, ...) self:OnTooltipSetItem(tooltip, ...) end)
		AddTooltipPostCall(TooltipDataType.Unit, function(tooltip, ...) self:OnTooltipSetUnit(tooltip, ...) end)
	else
		self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "OnTooltipSetSpell")
		self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "OnTooltipSetItem")
		self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "OnTooltipSetUnit")
	end

	self:SecureHook(GameTooltip, "SetUnitAura", "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitBuff", "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitDebuff", "SetUnitAura")

	if (ns.IsRetail) then
		self:SecureHook(GameTooltip, "SetUnitBuffByAuraInstanceID", "SetUnitAuraInstanceID")
		self:SecureHook(GameTooltip, "SetUnitDebuffByAuraInstanceID", "SetUnitAuraInstanceID")
	end

	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "OnTooltipCleared")

	self:SecureHookScript(GameTooltip.StatusBar, "OnValueChanged", "OnValueChanged")

end

Tooltips.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Tooltips", defaults)

	self:StyleStatusBar()
	self:StyleTooltips()
	self:SetHooks()

	if (self.InitializeMovableFrameAnchor) then
		self:InitializeMovableFrameAnchor()
	end
end

Tooltips.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
end

-- Movable Frames (Classics)
--------------------------------------------
if (ns.IsRetail) then return end

Tooltips.InitializeMovableFrameAnchor = function(self)

	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(250,120)
	frame:SetPoint(unpack(defaults.profile.savedPosition.Azerite))

	self.frame = frame

	-- Faking a global string for the label here.
	-- We're assuming the common word in those
	-- two strings is what we're looking for.
	local words1 = { string.split(" ", USE_UBERTOOLTIPS) }
	local words2 = { string.split(" ", SHOW_NEWBIE_TIPS_TEXT) }
	local label
	for _,word1 in ipairs(words1) do
		for _,word2 in ipairs(words1) do
			if (word1 == word2) then
				label = word1
				break
			end
		end
	end

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(label or USE_UBERTOOLTIPS)
	anchor:SetScalable(false)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(250, 120)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "BOTTOMRIGHT"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor

end

Tooltips.UpdatePositionAndScale = function(self)

	local savedPosition = self.currentLayout and self.db.profile.savedPosition[self.currentLayout]
	if (savedPosition) then
		local point, x, y = unpack(savedPosition)
		local scale = savedPosition.scale
		local frame = self.frame
		local anchor = self.anchor

		-- Set the scale before positioning,
		-- or everything will be wonky.
		frame:SetScale(scale * ns.API.GetDefaultElementScale())

		if (anchor and anchor.framePoint) then
			-- Position the frame at the anchor,
			-- with the given point and offsets.
			frame:ClearAllPoints()
			frame:SetPoint(anchor.framePoint, anchor, anchor.framePoint, (anchor.frameOffsetX or 0)/scale, (anchor.frameOffsetY or 0)/scale)

			-- Parse where this actually is relative to UIParent
			local point, x, y = ns.API.GetPosition(frame)

			-- Reposition the frame relative to UIParent,
			-- to avoid it being hooked to our anchor in combat.
			frame:ClearAllPoints()
			frame:SetPoint(point, UIParent, point, x, y)
		end
	end
end

Tooltips.OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPosition = self.db.profile.savedPosition
	local lockdown = InCombatLockdown()

	if (reason == "LayoutDeleted") then
		if (savedPosition[layoutName]) then
			savedPosition[layoutName] = nil
		end

	elseif (reason == "LayoutsUpdated") then

		if (savedPosition[layoutName]) then

			self.anchor:SetScale(savedPosition[layoutName].scale or self.anchor:GetScale())
			self.anchor:ClearAllPoints()
			self.anchor:SetPoint(unpack(savedPosition[layoutName]))

			local defaultPosition = defaults.profile.savedPosition[layoutName]
			if (defaultPosition) then
				self.anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			self.initialPositionSet = true
				--self.currentLayout = layoutName

		else
			-- The user is unlikely to have a preset with our name
			-- on the first time logging in.
			if (not self.initialPositionSet) then
				--print("setting default position for", layoutName, self.frame:GetName())

				local defaultPosition = defaults.profile.savedPosition.Azerite

				self.anchor:SetScale(defaultPosition.scale)
				self.anchor:ClearAllPoints()
				self.anchor:SetPoint(unpack(defaultPosition))
				self.anchor:SetDefaultPosition(unpack(defaultPosition))

				self.initialPositionSet = true
				--self.currentLayout = layoutName
			end

			savedPosition[layoutName] = { self.anchor:GetPosition() }
			savedPosition[layoutName].scale = self.anchor:GetScale()
		end

		self.currentLayout = layoutName

		self:UpdatePositionAndScale()

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPosition[layoutName] = { point, x, y }
		savedPosition[layoutName].scale = self.anchor:GetScale()

		self:UpdatePositionAndScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPosition[layoutName].scale = scale

		self:UpdatePositionAndScale()

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		--if (not self.incombat) then
			self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
		--end

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown for visible anchors.


	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends for visible anchors.

	end
end
