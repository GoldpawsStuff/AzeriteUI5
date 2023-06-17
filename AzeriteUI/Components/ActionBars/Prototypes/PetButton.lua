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

local KeyBound = LibStub("LibKeyBound-1.0", true)

-- Lua API
local next = next
local select = select
local setmetatable = setmetatable
local string_format = string.format

-- GLOBALS: AutoCastShine_AutoCastStop, AutoCastShine_AutoCastStart
-- GLOBALS: IsModifiedClick, GetBindingKey, GetBindingText, SetBinding
-- GLOBALS: PickupPetAction, GetPetActionInfo, GetPetActionsUsable, GetPetActionCooldown
-- GLOBALS: CreateFrame, CooldownFrame_Set, InCombatLockdown, SetDesaturation
-- GLOBALS: GameTooltip, GameTooltip_SetDefaultAnchor

local PetButton = {}
local PetButton_MT = { __index = PetButton }

-- Default button config
local defaults = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = false,
	colors = {
		range = { 1, .15, .15 },
		mana = { .25, .25, 1 }
	},
	hideElements = {
		macro = true,
		hotkey = false,
		equipped = true,
		border = true,
		borderIfEmpty = true
	},
	keyBoundTarget = false,
	keyBoundClickButton = "LeftButton",
	clickOnDown = false,
	flyoutDirection = "UP"
}

ns.PetButtons = {}
ns.PetButton = PetButton
ns.PetButton.defaults = defaults

local UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then
		return
	end
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetPetAction(self.id)
end

ns.PetButton.Create = function(id, name, header, buttonConfig)

	local button = CreateFrame("CheckButton", name, header, "PetActionButtonTemplate")
	button.showgrid = 0
	button.id = id
	button.parent = header
	button.config = buttonConfig or ns:Copy(defaults)

	-- Retail has a new mixin that overrides some of our meta methods,
	-- so we're doing hard embedding now instead.
	for method,func in next,PetButton do
		button[method] = func
	end

	button:SetID(id)
	button:SetAttribute("type", "pet")
	button:SetAttribute("action", id)
	button:SetAttribute("buttonLock", true)

	button:RegisterForDrag("LeftButton", "RightButton")

	if (ns.IsRetail) then
		button:RegisterForClicks("AnyUp", "AnyDown")
	else
		button:RegisterForClicks("AnyUp") -- works in retail or require AnyDown too?
	end

	button:UnregisterAllEvents()
	button:SetScript("OnEvent", nil)
	button:SetScript("OnEnter", ns.PetButton.OnEnter)
	button:SetScript("OnLeave", ns.PetButton.OnLeave)
	button:SetScript("OnDragStart", ns.PetButton.OnDragStart)
	button:SetScript("OnReceiveDrag", ns.PetButton.OnReceiveDrag)

	button.NormalTexture = button:GetNormalTexture()

	ns.PetButtons[button] = true

	return button
end

PetButton.UpdateConfig = function(self, buttonConfig)
	self.config = buttonConfig or self.config
	self:Update()
end

PetButton.Update = function(self)
	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(self.id)

	if (not isToken) then
		self.icon:SetTexture(texture)
		self.tooltipName = name
	else
		self.icon:SetTexture(_G[texture])
		self.tooltipName = _G[name]
	end

	self.isToken = isToken

	if (spellID) then
		local spell = Spell:CreateFromSpellID(spellID)
		self.spellDataLoadedCancelFunc = spell:ContinueWithCancelOnSpellLoad(function()
			self.tooltipSubtext = spell:GetSpellSubtext()
		end)
	end

	if (isActive) then
		if (IsPetAttackAction(self.id)) then
			if (self.StartFlash) then
				self:StartFlash()
			end
		else
			if (self.StopFlash) then
				self:StopFlash()
			end
		end
	else
		if (self.StopFlash) then
			self:StopFlash()
		end
	end

	self:SetChecked(isActive)

	if (autoCastAllowed) then
		if (autoCastEnabled) then
			self.AutoCastable:Hide()
			AutoCastShine_AutoCastStart(self.AutoCastShine)
		else
			self.AutoCastable:Show()
			AutoCastShine_AutoCastStop(self.AutoCastShine)
		end
	else
		self.AutoCastable:Hide()
		AutoCastShine_AutoCastStop(self.AutoCastShine)
	end

	if (texture) then
		if (GetPetActionsUsable()) then
			SetDesaturation(self.icon, nil)
		else
			SetDesaturation(self.icon, 1)
		end
		self.icon:Show()
		self:ShowButton()
	else
		self.icon:Hide()
		self:HideButton()
		if (self.showgrid == 0) then

		end
	end
	self:UpdateCooldown()
	self:UpdateHotkeys()
end

PetButton.GetTexture = function(self)
	local name, texture = GetPetActionInfo(self.id)
	return name and texture
end

PetButton.HasAction = function(self)
	return GetPetActionInfo(self.id)
end

PetButton.UpdateCooldown = function(self)
	local start, duration, enable = GetPetActionCooldown(self.id)
	CooldownFrame_Set(self.cooldown, start, duration, enable)
end

PetButton.UpdateHotkeys = function(self)
	local key = self:GetHotkey() or ""
	local hotkey = self.HotKey
	if (key == "" or self.parent.config.hidehotkey) then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

PetButton.ShowButton = function(self)
	self:SetAlpha(1)
end

PetButton.HideButton = function(self)
	if (self.showgrid == 0 and not self.parent.config.showgrid) then
		self:SetAlpha(0)
	end
end

PetButton.ShowGrid = function(self)
	self.showgrid = self.showgrid + 1
	self:SetAlpha(1)
end

PetButton.HideGrid = function(self)
	if (self.showgrid > 0) then
		self.showgrid = self.showgrid - 1
	end
	if (self.showgrid == 0) and not (GetPetActionInfo(self.id)) and (not self.parent.config.showgrid) then
		self:SetAlpha(0)
	end
end

PetButton.GetHotkey = function(self)
	local key = GetBindingKey(format("BONUSACTIONBUTTON%d", self.id)) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound:ToShortKey(key)
end

PetButton.GetBindings = function(self)
	local keys, binding = "", nil

	binding = string_format("BONUSACTIONBUTTON%d", self.id)
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if (keys ~= "") then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey,"KEY_")
	end

	binding = "CLICK "..self:GetName()..":LeftButton"
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if (keys ~= "") then
			keys = keys .. ", "
		end
		keys = keys.. GetBindingText(hotKey,"KEY_")
	end

	return keys
end

PetButton.OnEnter = function(self)
	self.UpdateTooltip = UpdateTooltip
	self:UpdateTooltip()
end

PetButton.OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

PetButton.OnDragStart = function(self)
	if (InCombatLockdown()) then return end
	if (IsAltKeyDown() and IsControlKeyDown() or IsShiftKeyDown()) or (IsModifiedClick("PICKUPACTION")) then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

PetButton.OnReceiveDrag = function(self)
	if (InCombatLockdown()) then return end
	if (GetCursorInfo() == "petaction") then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end
