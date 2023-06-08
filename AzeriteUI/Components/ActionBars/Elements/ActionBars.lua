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

if (ns.API.IsAddOnEnabled("ConsolePort_Bar")) then return end

local L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)
local LAB_Name = "LibActionButton-1.0-GE"
local LAB, LAB_Version = LibStub(LAB_Name)

local ActionBarMod = ns:NewModule("ActionBars", "LibMoreEvents-1.0", "LibFadingFrames-1.0", "AceConsole-3.0", "AceTimer-3.0")
local GUI = ns:GetModule("Options")

-- Lua API
local pairs = pairs
local next = next
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_split = string.split
local string_upper = string.upper
local tonumber = tonumber
local unpack = unpack

-- GLOBALS: C_LevelLink, hooksecurefunc, InCombatLockdown, IsMounted, IsSpellOverlayed, UnitIsDeadOrGhost

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local RegisterCooldown = ns.Widgets.RegisterCooldown
local UIHider = ns.Hider
local noop = ns.Noop

-- Just not there in Wrath
local IsSpellOverlayed = IsSpellOverlayed or function() end

-- Frame Metamethods
local mt = getmetatable(CreateFrame("Frame"))
local clearAllPoints = mt.__index.ClearAllPoints
local setPoint = mt.__index.SetPoint

-- Utility
local clearSetPoint = function(frame, ...)
	clearAllPoints(frame)
	setPoint(frame, ...)
end

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
for i,j in pairs(BAR_TO_ID) do ID_TO_BAR[j] = i end

-- Module defaults.
local defaults = { profile = ns:Merge({}, ns.Module.defaults) }

ActionBarMod.GenerateDefaults = function(self)

	defaults = { profile = ns:Merge({
		enabled = true,
		bars = {
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
	}, ns.Module.defaults) }

	if (ns.IsRetail) then
		defaults.profile.bars[6] = ns:Merge({ --[[]]
			enabled = false,
			layout = "grid",
			breakpoint = 12,
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
			layout = "grid",
			breakpoint = 12,
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
			layout = "grid",
			breakpoint = 12,
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

local config = {

	ButtonSize = { 64, 64 },
	ButtonHitRects =  { -10, -10, -10, -10 },
	ButtonMaskTexture = GetMedia("actionbutton-mask-circular"),

	ButtonBackdropPosition = { "CENTER", 0, 0 },
	ButtonBackdropSize = { 134.295081967, 134.295081967 },
	ButtonBackdropTexture = GetMedia("actionbutton-backdrop"),
	ButtonBackdropColor = { .67, .67, .67, 1 },

	ButtonIconPosition = { "CENTER", 0, 0 },
	ButtonIconSize = { 44, 44 },

	ButtonKeybindPosition = { "TOPLEFT", -5, -5 },
	ButtonKeybindJustifyH = "CENTER",
	ButtonKeybindJustifyV = "BOTTOM",
	ButtonKeybindFont = GetFont(15, true),
	ButtonKeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	ButtonCountPosition = { "BOTTOMRIGHT", -3, 3 },
	ButtonCountJustifyH = "CENTER",
	ButtonCountJustifyV = "BOTTOM",
	ButtonCountFont = GetFont(18, true),
	ButtonCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },

	ButtonCooldownCountPosition = { "CENTER", 1, 0 },
	ButtonCooldownCountJustifyH = "CENTER",
	ButtonCooldownCountJustifyV = "MIDDLE",
	ButtonCooldownCountFont = GetFont(16, true),
	ButtonCooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	ButtonBorderPosition = { "CENTER", 0, 0 },
	ButtonBorderSize = { 134.295081967, 134.295081967 },
	ButtonBorderTexture = GetMedia("actionbutton-border"),
	ButtonBorderColor = { Colors.ui[1], Colors.ui[2], Colors.ui[3], 1 },

	ButtonSpellHighlightPosition = { "CENTER", 0, 0 },
	ButtonSpellHighlightSize = { 134.295081967, 134.295081967 },
	ButtonSpellHighlightTexture = GetMedia("actionbutton-spellhighlight"),

}

---------------------------------------------
-- LAB Overrides & MaxDps Integration
---------------------------------------------
local ShowMaxDps = function(self)
	if (self.spellHighlight) then
		if (self.maxDpsGlowColor) then
			local r, g, b, a = unpack(self.maxDpsGlowColor)
			self.spellHighlight:SetVertexColor(r, g, b, a or .75)
		else
			self.spellHighlight:SetVertexColor(249/255, 188/255, 65/255, .75)
		end
		self.spellHighlight:Show()
	end
end

local HideMaxDps = function(self)
	if (self.spellHighlight) then
		if (not self.maxDpsGlowShown) then
			self.spellHighlight:Hide()
		end
	end
end

local UpdateMaxDps = function(self)
	if (self.maxDpsGlowShown) then
		ShowMaxDps(self)
	else
		local spellId = self:GetSpellId()
		if (spellId and IsSpellOverlayed(spellId)) then
			ShowMaxDps(self)
		else
			HideMaxDps(self)
		end
	end
end

local UpdateUsable = function(self)
	local config = self.config

	if (UnitIsDeadOrGhost("player") or (IsMounted() and not self.header.isDragonRiding)) then
		self.icon:SetDesaturated(true)
		self.icon:SetVertexColor(.4, .36, .32)

	elseif (self.outOfRange) then
		self.icon:SetDesaturated(true)
		self.icon:SetVertexColor(unpack(config.colors.range))
	else
		local isUsable, notEnoughMana = self:IsUsable()
		if (isUsable) then
			self.icon:SetDesaturated(false)
			self.icon:SetVertexColor(1, 1, 1)

		elseif (notEnoughMana) then
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(unpack(config.colors.mana))
		else
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(.4, .36, .32)
		end
	end

	if (C_LevelLink and self._state_type == "action") then
		local isLevelLinkLocked = C_LevelLink.IsActionLocked(self._state_action)
		if (not self.icon:IsDesaturated()) then
			self.icon:SetDesaturated(isLevelLinkLocked)
			if (isLevelLinkLocked) then
				self.icon:SetVertexColor(.4, .36, .32)
			end
		end
		if (self.LevelLinkLockIcon) then
			self.LevelLinkLockIcon:SetShown(isLevelLinkLocked)
		end
	end

end

local buttonOnEnter = function(self)
	self.icon.darken:SetAlpha(0)
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local buttonOnLeave = function(self)
	self.icon.darken:SetAlpha(.1)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

local style = function(button)

	local db = config
	local usingMaxDps = IsAddOnEnabled("MaxDps")

	-- Clean up the button template
	for _,i in next,{ "AutoCastShine", "Border", "Name", "NewActionTexture", "NormalTexture", "SpellHighlightAnim", "SpellHighlightTexture",
		--[[ WoW10 ]] "CheckedTexture", "HighlightTexture", "BottomDivider", "RightDivider", "SlotArt", "SlotBackground" } do
		if (button[i] and button[i].Stop) then button[i]:Stop() elseif button[i] then button[i]:SetParent(UIHider) end
	end

	local m = db.ButtonMaskTexture
	local b = GetMedia("blank")

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

	button:SetScript("OnEnter", buttonOnEnter)
	button:SetScript("OnLeave", buttonOnLeave)

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
		local m = config.ButtonMaskTexture
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

	--button.UpdateLocal = UpdateUsable

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

	local config = button.config or {}
	config.text = {
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
	button:UpdateConfig(config)

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

		local bar = ns.ActionBar:Create(BAR_TO_ID[i], config, ns.Prefix.."ActionBar"..i)
		bar.defaults = defaults.profile.bars[i]

		for id,button in next,bar.buttons do
			style(button)
			self.buttons[button] = true
		end

		--bar:Update()

		self.bars[i] = bar
	end

end

ActionBarMod.CreateAnchors = function(self)
	if (not next(self.bars)) then return end
	if (next(self.lookup.anchor)) then return end

	local defaults = self:GetDefaults()

	for i,bar in ipairs(self.bars) do

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

		bar.anchor = anchor

		self.lookup.bar[anchor] = bar
		self.lookup.anchor[bar] = anchor
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

ActionBarMod.CreateMaxDpsOverlays = function(self, event, addon)

	-- Just in case this was loaded on demand.
	if (addon and addon ~= "MaxDps") then return end
	if (addon == "MaxDps") then
		self:UnregisterEvent("ADDON_LOADED", "CreateMaxDpsOverlays")
	end

	-- Register our actionbutton library fork with MaxDps.
	MaxDps:RegisterLibActionButton(LAB_Name) -- Used to be LAB_Version, needs name now.

	-- This will hide the MaxDps overlays for the most part.
	MaxDps.GetTexture = function() end

	local maxDpsGlow = MaxDps.Glow
	MaxDps.Glow = function(this, button, id, texture, type, color)
		if (not self.buttons[button]) then
			return Glow(this, button, id, texture, type, color)
		end
		local col = color and { color.r, color.g, color.b, color.a } or nil
		if (not color) and (type) then
			if (type == "normal") then
				local c = this.db.global.highlightColor
				col = { c.r, c.g, c.b, c.a }

			elseif (type == "cooldown") then
				local c = this.db.global.cooldownColor
				col = { c.r, c.g, c.b, c.a }
			end
		end
		button.maxDpsGlowColor = col
		button.maxDpsGlowShown = true
		UpdateMaxDps(button)
	end

	local maxDpsHideGlow = MaxDps.HideGlow
	MaxDps.HideGlow = function(this, button, id)
		if (not self.buttons[button]) then
			return HideGlow(this, button, id)
		end
		button.maxDpsGlowColor = nil
		button.maxDpsGlowShown = nil
		UpdateMaxDps(button)
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnMaxDPSEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnMaxDPSEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnMaxDPSEvent")

	LAB.RegisterCallback(self, "OnButtonShowOverlayGlow", "OnMaxDPSEvent")
	LAB.RegisterCallback(self, "OnButtonHideOverlayGlow", "OnMaxDPSEvent")

	self.MaxDps = true
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
		return self:GenerateDefaults(self.defaults)
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

	local m = config.ButtonMaskTexture
	local b = GetMedia("blank")

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
	if (not next(self.lookup.anchor)) then return end

	for i,bar in ipairs(self.bars) do

		local anchor = self.lookup.anchor[bar]
		if (anchor) then

			local config = self.db.profile.bars[i].savedPosition
			if (config) then
				anchor:SetSize(bar:GetSize())
				anchor:SetScale(config.scale)
				anchor:ClearAllPoints()
				anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
			end
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

ActionBarMod.UpdateDefaults = function(self)

	local defaults = self:GetDefaults()

	for i,bar in ipairs(self.bars) do

		local anchor = self.lookup.anchor[bar]
		if (anchor) then

			local config = defaults.profile.bars[i].savedPosition

			config.scale = anchor:GetDefaultScale()
			config[1], config[2], config[3] = anchor:GetDefaultPosition()
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

	for i,bar in ipairs(self.bars) do

		local config = bar.config.savedPosition
		if (config) then

			bar:SetScale(config.scale)
			bar:ClearAllPoints()
			bar:SetPoint(config[1], UIParent, config[1], config[2]/config.scale, config[3]/config.scale)
		end
	end

end

ActionBarMod.UpdateEnabled = function(self)
	for id,bar in next,self.bars do

		local config = bar.config
		if (config.enabled and not bar:IsEnabled()) or (not config.enabled and bar:IsEnabled()) then

			if (InCombatLockdown()) then
				self.needupdate = true
				return
			end

			if (config.enabled) then
				bar:Enable()
			else
				bar:Disable()
			end
		end

	end
end

ActionBarMod.UpdateSettings = function(self)
	if (InCombatLockdown()) then
		self.needupdate = true
		return
	end

	self:UpdateEnabled()

	for id,bar in next,self.bars do
		bar:Update()
		bar:UpdateAnchor()
	end
end

ActionBarMod.RefreshConfig = function(self)
	self:UpdateSettings()
	self:UpdateBindings()
	self:UpdatePositionAndScales()
	self:UpdateAnchors()
end

ActionBarMod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_SHAPESHIFT_FORM") then
		self:UpdateSettings()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end

		if (self.needupdate) then
			self.needupdate = nil
			self:UpdateSettings()
		end

	elseif (event == "UPDATE_BINDINGS") then
		for id,bar in next,self.bars do
			bar:UpdateBindings()
		end
	end
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

		local bar = self.lookup.bar[anchor]
		if (not bar) then return end

		--print(event, point, x, y)
		bar.config.savedPosition[1] = point
		bar.config.savedPosition[2] = x
		bar.config.savedPosition[3] = y

		self:UpdatePositionAndScales()

	elseif (event == "MFM_ScaleUpdated") then
		local anchor, scale = ...

		local bar = self.lookup.bar[anchor]
		if (not bar) then return end

		bar.config.savedPosition.scale = scale

		self:UpdatePositionAndScales()

	elseif (event == "MFM_Dragging") then
		if (not self.incombat) then

			local anchor = ...
			local bar = self.lookup.bar[anchor]
			if (not bar) then return end

			self:OnAnchorEvent("MFM_PositionUpdated", ...)
		end

	elseif (event == "MFM_UIScaleChanged") then
		self:UpdateDefaults()
	end
end

ActionBarMod.OnButtonEvent = function(self, event, ...)

	if (event == "OnButtonUpdate") then
		local button = ...
		if (self.buttons[button]) then
			button.cooldown:ClearAllPoints()
			button.cooldown:SetAllPoints(button.icon)
			button.cooldown:SetDrawEdge(false)

			local i = 1
			while button.icon:GetMaskTexture(i) do
				button.icon:RemoveMaskTexture(button.icon:GetMaskTexture(i))
				i = i + 1
			end
			button.icon:SetMask(config.ButtonMaskTexture)

			local spellId = button:GetSpellId()
			if spellId and IsSpellOverlayed(spellId) then
				button.spellHighlight:Show()
			else
				button.spellHighlight:Hide()
			end

			-- The update function calls this for valid actions
			UpdateUsable(button)
		end

	elseif (event == "OnButtonUsable" or event == "OnButtonState") then
		local button = ...
		if (self.buttons[button]) then
			UpdateUsable(button)
		end
	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
		local arg1 = ...
		for button in next, LAB.activeButtons do
			local spellId = button:GetSpellId()
			if (spellId and spellId == arg1) then
				button.spellHighlight:Show()
			else
				if (button._state_type == "action") then
					local actionType, id = GetActionInfo(button._state_action)
					if (actionType == "flyout" and FlyoutHasSpell(id, arg1)) then
						button.spellHighlight:Hide()
					end
				end
			end
		end

	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE") then
		local arg1 = ...
		for button in next, LAB.activeButtons do
			local spellId = button:GetSpellId()
			if (spellId and spellId == arg1) then
				button.spellHighlight:Hide()
			else
				if (button._state_type == "action") then
					local actionType, id = GetActionInfo(button._state_action)
					if (actionType == "flyout" and FlyoutHasSpell(id, arg1)) then
						button.spellHighlight:Hide()
					end
				end
			end
		end
	end

end

ActionBarMod.OnMaxDPSEvent = function(self, event, ...)

	if (event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_SHAPESHIFT_FORM") then
		for button in next, LAB.activeButtons do
			if (self.buttons[button]) then
				if (button.maxDpsGlowShown) then
					button.maxDpsGlowColor = nil
					button.maxDpsGlowShown = nil
					UpdateMaxDps(button)
				end
			end
		end
	end

end

ActionBarMod.OnEnable = function(self)
	self:CreateBars()
	self:CreateAnchors()
	self:RefreshConfig()

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

	self:RegisterEvent("UPDATE_BINDINGS", "OnButtonEvent")

	if (not IsAddOnEnabled("MaxDps")) then
		self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "OnButtonEvent")
		self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", "OnButtonEvent")
	end

	LAB.RegisterCallback(self, "OnButtonUpdate", "OnButtonEvent")
	LAB.RegisterCallback(self, "OnButtonUsable", "OnButtonEvent")


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
	self:SetEnabledState(self.db.profile.enabled)

	if (not self.db.profile.enabled) then return end

	self.bars = {}
	self.buttons = {}
	self.lookup = { bar = {}, anchor = {} }

	if (ns.IsRetail) then
		if (IsAddOnEnabled("MaxDps")) then
			if (IsAddOnLoaded("MaxDps")) then
				self:CreateMaxDpsOverlays()
			else
				self:RegisterEvent("ADDON_LOADED", "CreateMaxDpsOverlays")
			end
		end
	end

end
