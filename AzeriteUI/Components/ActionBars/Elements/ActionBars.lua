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
local pairs = pairs
local string_format = string.format
local tonumber = tonumber
local unpack = unpack

-- GLOBALS: C_LevelLink, hooksecurefunc, InCombatLockdown, IsMounted, UnitIsDeadOrGhost
-- GLOBALS: CreateFrame, ClearOverrideBindings, RegisterStateDriver, UnregisterStateDriver, UIParent

-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local RegisterCooldown = ns.Widgets.RegisterCooldown
local UIHider = ns.Hider
local noop = ns.Noop

-- Return blizzard barID by from own bar numbers.
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

-- Return our bar number from blizzard barID.
local ID_TO_BAR = {}
for i,j in next,BAR_TO_ID do ID_TO_BAR[j] = i end

-- Module defaults.
local defaults = { profile = ns:Merge({
	clickOnDown = false,
	dimWhenResting = false,
	dimWhenInactive = false
}, ns.Module.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
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

local style = function(self)

	local db = ns.GetConfig("ActionButton")

	local m = db.ButtonMaskTexture
	local b = "" -- GetMedia("blank")

	self:SetAttribute("buttonLock", true)
	self:SetSize(unpack(db.ButtonSize))
	self:SetHitRectInsets(unpack(db.ButtonHitRects))
	self.hitRects = { unpack(db.ButtonHitRects) }

	-- New 3.4.1 checked texture keeps being reset.
	--hooksecurefunc(self, "SetChecked", function() self:GetCheckedTexture():Hide() end)

	-- Custom slot texture
	self.backdrop = self:CreateTexture(nil, "BACKGROUND", nil, -7)
	self.backdrop:SetSize(unpack(db.ButtonBackdropSize))
	self.backdrop:SetPoint(unpack(db.ButtonBackdropPosition))
	self.backdrop:SetTexture(db.ButtonBackdropTexture)
	self.backdrop:SetVertexColor(unpack(db.ButtonBackdropColor))

	-- Icon
	self.icon:SetDrawLayer("BACKGROUND", 1)
	self.icon:ClearAllPoints()
	self.icon:SetPoint(unpack(db.ButtonIconPosition))
	self.icon:SetSize(unpack(db.ButtonIconSize))
	self.icon:SetMask(m)

	-- Some crap WoW10 border I can't figure out how to remove right now.
	--self:DisableDrawLayer("ARTWORK")

	self:GetPushedTexture():SetTexture(m)
	self:GetPushedTexture():SetVertexColor(1, 1, 1, .2)
	self:GetPushedTexture():SetAllPoints(self.icon)
	self:GetPushedTexture():SetBlendMode("ADD")
	self:GetPushedTexture():SetDrawLayer("OVERLAY", 2)

	self:GetCheckedTexture():SetTexture(m)
	self:GetCheckedTexture():SetVertexColor(1, .82, .1, .2)
	self:GetCheckedTexture():SetAllPoints(self.icon)
	self:GetCheckedTexture():SetBlendMode("ADD")
	self:GetCheckedTexture():SetDrawLayer("OVERLAY", 1)

	self:GetHighlightTexture():SetTexture(m)
	self:GetHighlightTexture():SetVertexColor(1, 1, 1, .2)
	self:GetHighlightTexture():SetAllPoints(self.icon)
	self:GetHighlightTexture():SetBlendMode("ADD")
	self:GetHighlightTexture():SetDrawLayer("HIGHLIGHT")

	-- Autoattack flash
	self.Flash:SetDrawLayer("OVERLAY", 2)
	self.Flash:SetAllPoints(self.icon)
	self.Flash:SetVertexColor(1, 0, 0, .25)
	self.Flash:SetTexture(m)
	self.Flash:Hide()

	-- Button cooldown frame
	-- ToDo: Make all this more streamlined through the back-end
	self.cooldown:SetFrameLevel(self:GetFrameLevel() + 1)
	self.cooldown:ClearAllPoints()
	self.cooldown:SetAllPoints(self.icon)
	self.cooldown:SetUseCircularEdge(true)
	self.cooldown:SetReverse(false)
	self.cooldown:SetSwipeTexture(m)
	self.cooldown:SetDrawSwipe(true)
	self.cooldown:SetBlingTexture(b, 0, 0, 0, 0)
	self.cooldown:SetDrawBling(false)
	self.cooldown:SetEdgeTexture(b)
	self.cooldown:SetDrawEdge(false)
	self.cooldown:SetHideCountdownNumbers(true)

	self.UpdateCharge = function(self)
		local m = db.ButtonMaskTexture
		local b = GetMedia("blank")

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

	-- Overlay Frame
	self.OverlayFrame = CreateFrame("Frame", nil, self)
	self.OverlayFrame:SetFrameLevel(self:GetFrameLevel() + 3)
	self.OverlayFrame:SetAllPoints()

	-- Icon Border
	self.IconBorder = self.OverlayFrame:CreateTexture(nil, "BORDER", nil, 1)
	self.IconBorder:SetPoint(unpack(db.ButtonBorderPosition))
	self.IconBorder:SetSize(unpack(db.ButtonBorderSize))
	self.IconBorder:SetTexture(db.ButtonBorderTexture)
	self.IconBorder:SetVertexColor(unpack(db.ButtonBorderColor))

	-- Blizzard Spell Activation / MaxDps (addon) / SpellActivationOverlay (addon for Wrath/Classic Era)
	self.CustomSpellActivationAlert = self.OverlayFrame:CreateTexture(nil, "ARTWORK", nil, -7)
	self.CustomSpellActivationAlert:SetSize(unpack(db.ButtonSpellHighlightSize))
	self.CustomSpellActivationAlert:SetPoint(unpack(db.ButtonSpellHighlightPosition))
	self.CustomSpellActivationAlert:SetTexture(db.ButtonSpellHighlightTexture)
	self.CustomSpellActivationAlert:SetVertexColor(249/255, 188/255, 65/255, .75)
	self.CustomSpellActivationAlert:Hide()

	-- Cooldown Timer Text
	self.cooldownCount = self.OverlayFrame:CreateFontString(nil, "ARTWORK", nil, 1)
	self.cooldownCount:SetPoint(unpack(db.ButtonCooldownCountPosition))
	self.cooldownCount:SetFontObject(db.ButtonCooldownCountFont)
	self.cooldownCount:SetJustifyH(db.ButtonCooldownCountJustifyH)
	self.cooldownCount:SetJustifyV(db.ButtonCooldownCountJustifyV)
	self.cooldownCount:SetTextColor(unpack(db.ButtonCooldownCountColor))

	-- Spell Charge / Item Stack Count
	self.Count:SetParent(self.OverlayFrame)
	self.Count:SetDrawLayer("OVERLAY", 1)
	self.Count:ClearAllPoints()
	self.Count:SetPoint(unpack(db.ButtonCountPosition))
	self.Count:SetFontObject(db.ButtonCountFont)
	self.Count:SetJustifyH(db.ButtonCountJustifyH)
	self.Count:SetJustifyV(db.ButtonCountJustifyV)
	self.Count:SetTextColor(unpack(db.ButtonCountColor))

	-- HotKey
	self.HotKey:SetParent(self.OverlayFrame)
	self.HotKey:SetDrawLayer("OVERLAY", 1)
	self.HotKey:ClearAllPoints()
	self.HotKey:SetPoint(unpack(db.ButtonKeybindPosition))
	self.HotKey:SetJustifyH(db.ButtonKeybindJustifyH)
	self.HotKey:SetJustifyV(db.ButtonKeybindJustifyV)
	self.HotKey:SetFontObject(db.ButtonKeybindFont)
	self.HotKey:SetTextColor(unpack(db.ButtonKeybindColor))

	RegisterCooldown(self.cooldown, self.cooldownCount)

	-- ToDo: Handle this in the back-end
	hooksecurefunc(self.cooldown, "SetSwipeTexture", function(c,t) if t ~= m then c:SetSwipeTexture(m) end end)
	hooksecurefunc(self.cooldown, "SetBlingTexture", function(c,t) if t ~= b then c:SetBlingTexture(b,0,0,0,0) end end)
	hooksecurefunc(self.cooldown, "SetEdgeTexture", function(c,t) if t ~= b then c:SetEdgeTexture(b) end end)
	--hooksecurefunc(self.cooldown, "SetSwipeColor", function(c,r,g,b,a) if not a or a>.76 then c:SetSwipeColor(r,g,b,.75) end end)
	hooksecurefunc(self.cooldown, "SetDrawSwipe", function(c,h) if not h then c:SetDrawSwipe(true) end end)
	hooksecurefunc(self.cooldown, "SetDrawBling", function(c,h) if h then c:SetDrawBling(false) end end)
	hooksecurefunc(self.cooldown, "SetDrawEdge", function(c,h) if h then c:SetDrawEdge(false) end end)
	hooksecurefunc(self.cooldown, "SetHideCountdownNumbers", function(c,h) if not h then c:SetHideCountdownNumbers(true) end end)
	hooksecurefunc(self.cooldown, "SetCooldown", function(c) c:SetAlpha(.75) end)

	local buttonConfig = self.config or {}

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

	self:UpdateConfig(buttonConfig)

	return self
end

ActionBarMod.CreateBars = function(self)
	if (next(self.bars)) then return end

	for i = 1,#BAR_TO_ID do

		local config = self.db.profile.bars[i]
		config.clickOnDown = self.db.profile.clickOnDown

		local bar = ns.ActionBar:Create(BAR_TO_ID[i], config, ns.Prefix.."ActionBar"..i)
		bar.buttonWidth, bar.buttonHeight = unpack(ns.GetConfig("ActionButton").ButtonSize)
		bar.defaults = defaults.profile.bars[i]

		for id,button in next,bar.buttons do
			style(button)
			self.buttons[button] = true
		end

		self.bars[i] = bar
	end

	if (not ns.IsClassic and not ns.IsTBC and not ns.IsWrath) then

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

		self.bars[1].Disable = function(self)
			ns.ActionBar.prototype.Disable(self)
			ClearOverrideBindings(self)
			UnregisterStateDriver(petBattleController, "petbattle")
		end

		self.bars[1].Enable = function(self)
			ns.ActionBar.prototype.Enable(self)
			self:UpdateBindings()
			RegisterStateDriver(petBattleController, "petbattle", "[petbattle]petbattle;nopetbattle")
		end
	end

	-- Make the flyouts remain visible when called from faded bars.
	-- *Note that the LAB10GE flyout handler does not exist
	-- before at least one action button has been created using it.
	--local flyoutHandler = ns.WoW10 and LAB10GEFlyoutHandlerFrame or SpellFlyout
	--if (flyoutHandler) then
	--	flyoutHandler:SetIgnoreParentAlpha(true)
	--end

end

ActionBarMod.CreateAnchors = function(self)
	if (not next(self.bars)) then return end
	if (next(self.anchors)) then return end

	local defaults = self:GetDefaults()

	for i,bar in next,self.bars do

		local defaultPos = defaults.profile.bars[i].savedPosition
		local pos = self.db.profile.bars[i].savedPosition

		local anchor = ns:GetModule("MovableFramesManager"):RequestAnchor()
		anchor:SetScalable(true)

		-- Set defaults explicitly
		anchor:SetDefaultScale(defaultPos.scale)
		anchor:SetDefaultPosition(defaultPos[1], defaultPos[2], defaultPos[3])

		-- Size & position according to saved settings
		anchor:SetSize(bar:GetSize()) -- assume this exists
		anchor:SetPoint(pos[1], pos[2], pos[3])
		anchor:SetScale(pos.scale)
		anchor:SetTitle(self:GenerateBarDisplayName(i))

		-- Update anchor according to current bar layout
		-- This will be called before anchors are shown
		anchor.PreUpdate = function(self)
			local pos = self.bar.config.savedPosition
			anchor:SetSize(self.bar:GetSize())
			anchor:SetScale(pos.scale)
			anchor:ClearAllPoints()
			anchor:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
		end

		-- Color the anchor according to anchor type
		local r, g, b = unpack(Colors.anchor.actionbars)
		anchor.Overlay:SetBackdropColor(r, g, b, .75)
		anchor.Overlay:SetBackdropBorderColor(r, g, b, 1)

		anchor.bar = bar
		bar.anchor = anchor

		self.anchors[bar] = anchor
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnAnchorEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnAnchorEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnAnchorEvent")

	ns.RegisterCallback(self, "MFM_PositionUpdated", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_AnchorShown", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_ScaleUpdated", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_Dragging", "OnAnchorEvent")
	ns.RegisterCallback(self, "MFM_UIScaleChanged", "OnAnchorEvent")

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

ActionBarMod.UpdateBarButtonCounts = function(self)
	for i,bar in next,self.bars do
		for j,button in next,bar.buttons do
			if j > bar.config.numbuttons then break end
			-- Updating the config will trigger a full button update,
			-- even though this method isn't directly exposed.
			button:UpdateConfig(button.config) -- pass its config, or it'll reset!
		end
	end
end

ActionBarMod.UpdateBindings = function(self)
	for i,bar in next,self.bars do
		if (bar:IsEnabled()) then
			bar:UpdateBindings()
		end
	end
end

-- Called by the movable frame manager
-- when defaults somehow are changed,
-- like when the user interface scale is modified.
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
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateEnabled")
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateEnabled")
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
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateSettings")
	end

	-- Follow the global click on down settings in WoW10 and above.
	if (ns.WoW10) then
		SetCVar("ActionButtonUseKeyDown", self.db.profile.clickOnDown)
	end

	-- Copy global settings to individual bars for easier updates.
	-- We do not grant user access to these settings per bar.
	for i,bar in next,self.bars do
		bar.config.clickOnDown = self.db.profile.clickOnDown
		bar.config.dimWhenResting = self.db.profile.dimWhenResting
		bar.config.dimWhenInactive = self.db.profile.dimWhenInactive

		-- Copy select settings into each button's config table.
		for id,button in pairs(bar.buttons) do
			button.config.clickOnDown = bar.config.clickOnDown
			button.config.dimWhenResting = bar.config.dimWhenResting
			button.config.dimWhenInactive = bar.config.dimWhenInactive

			-- Update config and trigger a full button update.
			button:UpdateConfig(button.config)
		end
	end

	self:UpdateEnabled()
	self:UpdateBars()
	self:UpdateBarButtonCounts()
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

	-- Will this fix the positioning bug that occurs more often than not on bar 2 for a lot of users? No.
	-- The idea is to avoid parsing bugs of the initial position by ensuring
	-- that the bars have the same size and layout as previous session.
	self:UpdatePositionAndScales()

	-- Create the anchors and update settings
	-- only after all the bars have been created
	-- and their previous settings restored.
	self:CreateAnchors()

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateSettings")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")

	self:UpdateSettings()

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
