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

if (ns.API.IsAddOnEnabled("ConsolePort_Bar")) then return end

local LAB_Name = "LibActionButton-1.0-GE"
local LAB = LibStub(LAB_Name)

local ActionBarMod = ns:NewModule("ActionBars", "LibMoreEvents-1.0", "LibFadingFrames-1.0", "AceConsole-3.0", "AceTimer-3.0")

-- Lua API
local next = next
local string_format = string.format
local tonumber = tonumber
local unpack = unpack

-- GLOBALS: C_LevelLink, hooksecurefunc, InCombatLockdown, IsMounted, IsSpellOverlayed, UnitIsDeadOrGhost

-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local RegisterCooldown = ns.Widgets.RegisterCooldown
local UIHider = ns.Hider
local noop = ns.Noop

-- Just not there in Wrath
local IsSpellOverlayed = IsSpellOverlayed or function() end

-- Return blizzard barID by barnum.
local BAR_TO_ID = {
	[1] = 1,
	[2] = BOTTOMLEFT_ACTIONBAR_PAGE,
	[3] = BOTTOMRIGHT_ACTIONBAR_PAGE,
	[4] = RIGHT_ACTIONBAR_PAGE,
	[5] = LEFT_ACTIONBAR_PAGE
}
if (ns.IsRetail) then
	BAR_TO_ID[6] = MULTIBAR_5_ACTIONBAR_PAGE
	BAR_TO_ID[7] = MULTIBAR_6_ACTIONBAR_PAGE
	BAR_TO_ID[8] = MULTIBAR_7_ACTIONBAR_PAGE
end

local ID_TO_BAR = {}
for i,j in next,BAR_TO_ID do ID_TO_BAR[j] = i end

-- Module defaults.
local defaults = { profile = ns:Merge({
	clickOnDown = false
}, ns.Module.defaults) }

ActionBarMod.GenerateDefaults = function(self)
	defaults.profile.bars = {
		[1] = ns:Merge({ --[[ primary action bar ]]
			enabled = true,
			enableBarFading = true,
			fadeFrom = 8,
			layout = "zigzag",
			startAt = 9, -- at which button the zigzag pattern should begin
			growth = "horizontal", -- which direction the bar goes in
			growthHorizontal = "RIGHT", -- the bar's horizontal growth direction
			growthVertical = "UP", -- the bar's vertical growth direction
			visibility = {
				dragon = true,
				possess = true,
				overridebar = true,
				vehicleui = true
			},
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "BOTTOMLEFT",
				[2] = 60 * ns.API.GetEffectiveScale(),
				[3] = 42 * ns.API.GetEffectiveScale()
			}
		}, ns.ActionBar.defaults),

		[2] = ns:Merge({ --[[ bottomleft multibar ]]
			enabled = false,
			enableBarFading = true,
			fadeFrom = 1,
			layout = "zigzag",
			startAt = 2, -- at which button the zigzag pattern should begin
			growth = "horizontal", -- which direction the bar goes in
			growthHorizontal = "RIGHT", -- the bar's horizontal growth direction
			growthVertical = "DOWN", -- the bar's vertical growth direction
			offset = (64 - 44 + 8)/64, -- 28
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "BOTTOMLEFT",
				[2] = 752 * ns.API.GetEffectiveScale(),
				[3] = 42 * ns.API.GetEffectiveScale()
			}
		}, ns.ActionBar.defaults),

		[3] = ns:Merge({ --[[ bottomright multibar ]]
			enabled = false,
			fadeAlone = true,
			layout = "grid",
			breakpoint = 6,
			growth = "vertical",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "RIGHT",
				[2] = -40 * ns.API.GetEffectiveScale(),
				[3] = 0
			}
		}, ns.ActionBar.defaults),

		[4] = ns:Merge({ --[[ right multibar 1 ]]
			enabled = false,
			fadeAlone = true,
			layout = "grid",
			breakpoint = 6,
			growth = "vertical",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "RIGHT",
				[2] = -194 * ns.API.GetEffectiveScale(),
				[3] = 0
			}
		}, ns.ActionBar.defaults),

		[5] = ns:Merge({ --[[ right multibar 2 ]]
			enabled = false,
			fadeAlone = true,
			layout = "grid",
			breakpoint = 6,
			growth = "vertical",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "RIGHT",
				[2] = -348 * ns.API.GetEffectiveScale(),
				[3] = 0
			}
		}, ns.ActionBar.defaults)
	}

	if (ns.IsRetail) then
		defaults.profile.bars[6] = ns:Merge({ --[[]]
			enabled = false,
			fadeAlone = true,
			layout = "grid",
			breakpoint = NUM_ACTIONBAR_BUTTONS,
			growth = "horizontal",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "CENTER",
				[2] = 0,
				[3] = 82 * ns.API.GetEffectiveScale()
			}
		}, ns.ActionBar.defaults)

		defaults.profile.bars[7] = ns:Merge({ --[[]]
			enabled = false,
			fadeAlone = true,
			layout = "grid",
			breakpoint = NUM_ACTIONBAR_BUTTONS,
			growth = "horizontal",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "CENTER",
				[2] = 0,
				[3] = 0
			}
		}, ns.ActionBar.defaults)

		defaults.profile.bars[8] = ns:Merge({ --[[]]
			enabled = false,
			fadeAlone = true,
			layout = "grid",
			breakpoint = NUM_ACTIONBAR_BUTTONS,
			growth = "horizontal",
			growthHorizontal = "RIGHT",
			growthVertical = "DOWN",
			savedPosition = {
				scale = ns.API.GetEffectiveScale(),
				[1] = "CENTER",
				[2] = 0,
				[3] = -82 * ns.API.GetEffectiveScale()
			}
		}, ns.ActionBar.defaults)
	end

	return defaults
end

---------------------------------------------
-- LAB Overrides
---------------------------------------------

local onEnter = function(self)
	self.icon.darken:SetAlpha(0)
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local onLeave = function(self)
	self.icon.darken:SetAlpha(.1)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

local style = function(button)

	local db = ns.GetConfig("ActionButton")

	-- TODO: Move resets to the back-end and create styling methods.

	-- Clean up the button template
	for _,i in next,{ "AutoCastShine", "Border", "Name", "NewActionTexture", "NormalTexture", "SpellHighlightAnim", "SpellHighlightTexture",
		--[[ WoW10 ]] "CheckedTexture", "HighlightTexture", "BottomDivider", "RightDivider", "SlotArt", "SlotBackground" } do
		if (button[i] and button[i].Stop) then button[i]:Stop() elseif button[i] then button[i]:SetParent(UIHider) end
	end

	local m = db.ButtonMaskTexture
	local b = "" -- GetMedia("blank")

	button:SetAttribute("buttonLock", true)
	button:SetSize(unpack(db.ButtonSize))
	button:SetHitRectInsets(unpack(db.ButtonHitRects))
	button:SetNormalTexture("")
	button:SetHighlightTexture("")
	button:SetCheckedTexture("")
	button:GetHighlightTexture():Hide()
	button:GetCheckedTexture():Hide()

	-- New 3.4.1 checked texture keeps being reset.
	hooksecurefunc(button, "SetChecked", function() button:GetCheckedTexture():Hide() end)

	-- Custom slot texture
	local backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
	backdrop:SetSize(unpack(db.ButtonBackdropSize))
	backdrop:SetPoint(unpack(db.ButtonBackdropPosition))
	backdrop:SetTexture(db.ButtonBackdropTexture)
	backdrop:SetVertexColor(unpack(db.ButtonBackdropColor))
	button.backdrop = backdrop

	-- Icon
	local icon = button.icon
	icon:SetDrawLayer("BACKGROUND", 1)
	icon:ClearAllPoints()
	icon:SetPoint(unpack(db.ButtonIconPosition))
	icon:SetSize(unpack(db.ButtonIconSize))

	local i = 1
	while button.icon:GetMaskTexture(i) do
		button.icon:RemoveMaskTexture(button.icon:GetMaskTexture(i))
		i = i + 1
	end
	if (button.IconMask) then
		icon:RemoveMaskTexture(button.IconMask)
	end
	icon:SetMask(m)

	-- Custom icon darkener
	local darken = button:CreateTexture(nil, "BACKGROUND", nil, 2)
	darken:SetAllPoints(button.icon)
	darken:SetTexture(m)
	darken:SetVertexColor(0, 0, 0, .1)
	button.icon.darken = darken

	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)

	-- Some crap WoW10 border I can't figure out how to remove right now.
	button:DisableDrawLayer("ARTWORK")

	-- Button is pushed
	-- Responds to mouse and keybinds
	-- if we allow blizzard to handle it.
	local pushedTexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
	pushedTexture:SetVertexColor(1, 1, 1, .2)
	pushedTexture:SetTexture(m)
	pushedTexture:SetAllPoints(button.icon)
	button.PushedTexture = pushedTexture

	button:SetPushedTexture(button.PushedTexture)
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetDrawLayer("OVERLAY", 1)

	-- Autoattack flash
	local flash = button.Flash
	flash:SetDrawLayer("OVERLAY", 2)
	flash:SetAllPoints(icon)
	flash:SetVertexColor(1, 0, 0, .25)
	flash:SetTexture(m)
	flash:Hide()

	-- Button cooldown frame
	local cooldown = button.cooldown
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	cooldown:ClearAllPoints()
	cooldown:SetAllPoints(button.icon)
	cooldown:SetUseCircularEdge(true)
	cooldown:SetReverse(false)
	cooldown:SetSwipeTexture(m)
	cooldown:SetDrawSwipe(true)
	cooldown:SetBlingTexture(b, 0, 0, 0, 0)
	cooldown:SetDrawBling(false)
	cooldown:SetEdgeTexture(b)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true)

	button.UpdateCharge = function(self)
		local m = db.ButtonMaskTexture
		local b = "" --GetMedia("blank")
		local cooldown = self.chargeCooldown
		if (not cooldown) then return end
		cooldown:SetFrameStrata(self:GetFrameStrata())
		cooldown:SetFrameLevel(self:GetFrameLevel() + 2)
		cooldown:SetUseCircularEdge(true)
		cooldown:SetReverse(false)
		cooldown:SetSwipeTexture(m)
		cooldown:SetDrawSwipe(true)
		cooldown:SetBlingTexture(b, 0, 0, 0, 0)
		cooldown:SetDrawBling(false)
		cooldown:SetEdgeTexture(b)
		cooldown:SetDrawEdge(false)
		cooldown:SetHideCountdownNumbers(true)
		cooldown:SetAlpha(.5)
		cooldown:ClearAllPoints()
		cooldown:SetAllPoints(self.icon)
	end

	-- Custom overlay frame
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 3)
	overlay:SetAllPoints()
	button.overlay = overlay

	local border = overlay:CreateTexture(nil, "BORDER", nil, 1)
	border:SetPoint(unpack(db.ButtonBorderPosition))
	border:SetSize(unpack(db.ButtonBorderSize))
	border:SetTexture(db.ButtonBorderTexture)
	border:SetVertexColor(unpack(db.ButtonBorderColor))
	--border:SetAlpha(0)
	button.iconBorder = border

	-- Custom spell highlight
	local spellHighlight = overlay:CreateTexture(nil, "ARTWORK", nil, -7)
	spellHighlight:SetSize(unpack(db.ButtonSpellHighlightSize))
	spellHighlight:SetPoint(unpack(db.ButtonSpellHighlightPosition))
	spellHighlight:SetTexture(db.ButtonSpellHighlightTexture)
	spellHighlight:SetVertexColor(249/255, 188/255, 65/255, .75)
	spellHighlight:Hide()
	button.spellHighlight = spellHighlight

	-- Custom cooldown count
	local cooldownCount = overlay:CreateFontString(nil, "ARTWORK", nil, 1)
	cooldownCount:SetPoint(unpack(db.ButtonCooldownCountPosition))
	cooldownCount:SetFontObject(db.ButtonCooldownCountFont)
	cooldownCount:SetJustifyH(db.ButtonCooldownCountJustifyH)
	cooldownCount:SetJustifyV(db.ButtonCooldownCountJustifyV)
	cooldownCount:SetTextColor(unpack(db.ButtonCooldownCountColor))
	button.cooldownCount = cooldownCount

	-- Button charge/stack count
	local count = button.Count
	count:SetParent(overlay)
	count:SetDrawLayer("OVERLAY", 1)
	count:ClearAllPoints()
	count:SetPoint(unpack(db.ButtonCountPosition))
	count:SetFontObject(db.ButtonCountFont)
	count:SetJustifyH(db.ButtonCountJustifyH)
	count:SetJustifyV(db.ButtonCountJustifyV)
	count:SetTextColor(unpack(db.ButtonCountColor))

	-- Button keybind
	local hotkey = button.HotKey
	hotkey:SetParent(overlay)
	hotkey:SetDrawLayer("OVERLAY", 1)
	hotkey:ClearAllPoints()
	hotkey:SetPoint(unpack(db.ButtonKeybindPosition))
	hotkey:SetJustifyH(db.ButtonKeybindJustifyH)
	hotkey:SetJustifyV(db.ButtonKeybindJustifyV)
	hotkey:SetFontObject(db.ButtonKeybindFont)
	hotkey:SetTextColor(unpack(db.ButtonKeybindColor))

	RegisterCooldown(button.cooldown, button.cooldownCount)

	hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
	hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
	hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
	--hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
	hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
	hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
	hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
	hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
	hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

	local buttonConfig = button.config or {}
	buttonConfig.text = {
		hotkey = {
			font = {
				font = db.ButtonKeybindFont:GetFont(),
				size = select(2, db.ButtonKeybindFont:GetFont()),
				flags = select(3, db.ButtonKeybindFont:GetFont()),
			},
			color = db.ButtonKeybindColor,
			position = {
				anchor = db.ButtonKeybindPosition[1],
				relAnchor = db.ButtonKeybindPosition[1],
				offsetX = db.ButtonKeybindPosition[2],
				offsetY = db.ButtonKeybindPosition[3],
			},
			justifyH = db.ButtonKeybindJustifyH,
		},
		count = {
			font = {
				font = db.ButtonCountFont:GetFont(),
				size = select(2, db.ButtonCountFont:GetFont()),
				flags = select(3, db.ButtonCountFont:GetFont()),
			},
			color = db.ButtonCountColor,
			position = {
				anchor = db.ButtonCountPosition[1],
				relAnchor = db.ButtonCountPosition[1],
				offsetX = db.ButtonCountPosition[2],
				offsetY = db.ButtonCountPosition[3],
			},
			justifyH = db.ButtonCountJustifyH,
		}
	}
	button:UpdateConfig(buttonConfig)

	-- Disable masque for our buttons,
	-- they are not compatible.
	button.AddToMasque = noop
	button.AddToButtonFacade = noop
	button.LBFSkinned = nil
	button.MasqueSkinned = nil

	return button
end

ActionBarMod.CreateBars = function(self)
	if (next(self.bars)) then return end

	for i = 1,#BAR_TO_ID do

		local config = self.db.profile.bars[i]
		config.clickOnDown = self.db.profile.clickOnDown

		local bar = ns.ActionBar:Create(BAR_TO_ID[i], config, ns.Prefix.."ActionBar"..i)
		bar:Show() -- bar must be initially visible for button mask to be properly removed. weird.
		bar.buttonWidth, bar.buttonHeight = unpack(ns.GetConfig("ActionButton").ButtonSize)
		bar.defaults = defaults.profile.bars[i]

		for id,button in next,bar.buttons do
			style(button)
			self.buttons[button] = true
		end

		self.bars[i] = bar
	end

end

ActionBarMod.CreateAnchors = function(self)
	if (not next(self.bars)) then return end
	if (next(self.anchors)) then return end

	local defaults = self:GetDefaults()

	for i,bar in next,self.bars do

		local bar = bar
		local config = defaults.profile.bars[i]

		local anchor = ns:GetModule("MovableFramesManager"):RequestAnchor()
		anchor:SetScalable(true)
		anchor:SetSize(2,2)
		anchor:SetPoint(config.savedPosition[1], config.savedPosition[2], config.savedPosition[3])
		anchor:SetScale(config.savedPosition.scale)
		anchor:SetTitle(self:GenerateBarDisplayName(i))

		anchor:SetDefaultScale(ns.API.GetEffectiveScale())

		anchor.PreUpdate = function()
			self:UpdateAnchors()
		end

		local r, g, b = unpack(Colors.anchor.actionbars)
		anchor.Overlay:SetBackdropColor(r, g, b, .75)
		anchor.Overlay:SetBackdropBorderColor(r, g, b, 1)

		anchor.bar = bar
		bar.anchor = anchor

		self.anchors[bar] = anchor

	end
end

ActionBarMod.CreatePetBattleController = function(self)
	if (self.petBattleController) then return end
	if (not self.bars[1]) then return end

	local petBattleController = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	petBattleController:SetAttribute("_onstate-petbattle", string_format([[
		if (newstate == "petbattle") then
			b = b or table.new();
			b[1], b[2], b[3], b[4], b[5], b[6] = "%s", "%s", "%s", "%s", "%s", "%s";
			for i = 1,6 do
				local button, vbutton = "CLICK "..b[i]..":LeftButton", "ACTIONBUTTON"..i
				for k=1,select("#", GetBindingKey(button)) do
					local key = select(k, GetBindingKey(button))
					self:SetBinding(true, key, vbutton)
				end
				-- do the same for the default UIs bindings
				for k=1,select("#", GetBindingKey(vbutton)) do
					local key = select(k, GetBindingKey(vbutton))
					self:SetBinding(true, key, vbutton)
				end
			end
		else
			self:ClearBindings()
		end
	]], (function(b) local t={}; for i=1,6 do t[i]=b[i]:GetName() end; return unpack(t) end)(self.bars[1].buttons)))

	self.petBattleController = petBattleController
end

ActionBarMod.GenerateBarDisplayName = function(self, id)
	local barID = tonumber(id)
	if (barID == RIGHT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR3_TEXT -- "Right Action Bar 1"
	elseif (barID == LEFT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR4_TEXT -- "Right Action Bar 2"
	else
		return ITEM_SUFFIX_TEMPLATE:format(BINDING_HEADER_ACTIONBAR, barID)
		--return HUD_EDIT_MODE_ACTION_BAR_LABEL:format(barID) -- "Action Bar %d"
	end
end

ActionBarMod.GetDefaults = function(self)
	if (self.GenerateDefaults) then
		return self:GenerateDefaults()
	end
	return self.defaults
end

ActionBarMod.SetDefaults = function(self, defaults)
	self.db:RegisterDefaults(defaults)
end

ActionBarMod.UpdateChargeCooldowns = function(self)
	if (not self.chargeCooldowns) then
		self.chargeCooldowns = {}
	end

	local m = ns.GetConfig("ActionButton").ButtonMaskTexture
	local b = "" -- GetMedia("blank")

	local i = 1
	local cooldown = _G["LAB10ChargeCooldown"..i]
	while cooldown do
		if (not self.chargeCooldowns[cooldown]) then

			cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
			cooldown:ClearAllPoints()
			cooldown:SetAllPoints(button.icon)
			cooldown:SetUseCircularEdge(true)
			cooldown:SetReverse(false)
			cooldown:SetSwipeTexture(m)
			cooldown:SetDrawSwipe(true)
			cooldown:SetBlingTexture(b, 0, 0, 0, 0)
			cooldown:SetDrawBling(false)
			cooldown:SetEdgeTexture(b)
			cooldown:SetDrawEdge(false)
			cooldown:SetHideCountdownNumbers(true)

			hooksecurefunc(cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
			hooksecurefunc(cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
			hooksecurefunc(cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
			--hooksecurefunc(cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
			hooksecurefunc(cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
			hooksecurefunc(cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
			hooksecurefunc(cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
			hooksecurefunc(cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
			hooksecurefunc(cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

			hooksecurefunc(cooldown, "Show", function(self)
				local parent = self:GetParent()
				self:GetFrameStrata(parent:GetFrameStrata())
				self:SetFrameLevel(parent:GetFrameLevel() + 1)
			end)

			self.chargeCooldowns[cooldown] = true
		end
		i = i + 1
		cooldown = _G["LAB10ChargeCooldown"..i]
	end

end

ActionBarMod.UpdateAnchors = function(self)
	for i,bar in next,self.bars do
		if (bar.anchor) then
			local config = self.db.profile.bars[i].savedPosition
			if (config) then
				bar.anchor:SetSize(bar:GetSize())
				bar.anchor:SetScale(config.scale)
				bar.anchor:ClearAllPoints()
				bar.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
			end
		end
	end
end

ActionBarMod.UpdateBars = function(self, event)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateBars")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateBars")
	end
	for id,bar in next,self.bars do
		bar:Update()
	end
end

ActionBarMod.UpdateBindings = function(self)
	for i,bar in next,self.bars do
		if (bar:IsEnabled()) then
			bar:UpdateBindings()
		end
	end
end

ActionBarMod.UpdateDefaults = function(self)
	local defaults = self:GetDefaults()
	for i,bar in next,self.bars do
		if (bar.anchor) then
			local config = defaults.profile.bars[i].savedPosition
			config.scale = bar.anchor:GetDefaultScale()
			config[1], config[2], config[3] = bar.anchor:GetDefaultPosition()
		end
	end
	self:SetDefaults(defaults)
end

ActionBarMod.UpdatePositionAndScales = function(self)
	if (not next(self.bars)) then return end
	if (InCombatLockdown()) then
		self.updateneeded = true
		return
	end

	self.updateneeded = nil

	for i,bar in next,self.bars do
		local config = bar.config.savedPosition
		if (config) then
			bar:SetScale(config.scale)
			bar:ClearAllPoints()
			bar:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
		end
	end
end

ActionBarMod.UpdateEnabled = function(self, event)
	if (not next(self.bars)) then return end
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateBars")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateBars")
	end
	for id,bar in next,self.bars do
		if (bar.config.enabled) then
			bar:Enable()
		else
			bar:Disable()
		end
	end
end

ActionBarMod.UpdateSettings = function(self, event)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateSettings")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateBars")
	end
	if (ns.WoW10) then
		SetCVar("ActionButtonUseKeyDown", self.db.profile.clickOnDown)
	end
	for i,bar in next,self.bars do
		bar.config.clickOnDown = self.db.profile.clickOnDown
	end
	self:UpdateEnabled()
	self:UpdateBars()
	self:UpdateBindings()
	self:UpdatePositionAndScales()
	self:UpdateAnchors()
end

ActionBarMod.RefreshConfig = function(self)
	for i,bar in next,self.bars do
		bar.config = self.db.profile.bars[i]
	end
	self:UpdateSettings()
end

ActionBarMod.OnAnchorEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED") then
		self.incombat = nil

		self:UpdatePositionAndScales()
		self:UpdateAnchors()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end

		self.incombat = nil

		if (self.updateneeded) then
			self:UpdatePositionAndScales()
			self:UpdateAnchors()
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true

	elseif (event == "MFM_PositionUpdated") then
		local anchor, point, x, y = ...
		if (not anchor.bar) then return end

		anchor.bar.config.savedPosition[1] = point
		anchor.bar.config.savedPosition[2] = x
		anchor.bar.config.savedPosition[3] = y

		self:UpdatePositionAndScales()

	elseif (event == "MFM_ScaleUpdated") then
		local anchor, scale = ...
		if (not anchor.bar) then return end

		anchor.bar.config.savedPosition.scale = scale

		self:UpdatePositionAndScales()

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then
			local anchor = ...
			if (not anchor.bar) then return end

			self:OnAnchorEvent("MFM_PositionUpdated", ...)
		end

	elseif (event == "MFM_UIScaleChanged") then
		self:UpdateDefaults()
	end
end

ActionBarMod.OnEnable = function(self)
	self:CreateBars()
	self:CreateAnchors()
	self:UpdateSettings()

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateSettings")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnAnchorEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnAnchorEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnAnchorEvent")

	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_UIScaleChanged", "OnAnchorEvent")

end

ActionBarMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace(self:GetName(), self:GetDefaults())

	if (ns.WoW10) then
		self.db.profile.clickOnDown = GetCVarBool("ActionButtonUseKeyDown")
	end

	self.bars = {}
	self.buttons = {}
	self.anchors = {}

end
