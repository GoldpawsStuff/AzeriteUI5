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
local _, ns = ...

local KeyBound = LibStub("LibKeyBound-1.0", true)

-- GLOBALS: CreateFrame, CooldownFrame_Set
-- GLOBALS: GetBindingKey, GetShapeshiftFormInfo, GetShapeshiftFormCooldown

-- Lua API
local next = next
local string_format = string.format

local StanceButton = {}

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

ns.StanceButtons = {}
ns.StanceButton = StanceButton
ns.StanceButton.defaults = defaults

ns.StanceButton.Create = function(id, name, header, buttonConfig)

	local button = CreateFrame("CheckButton", name, header, "StanceButtonTemplate")
	button.id = id
	button.parent = header
	button.showgrid = 0
	button.config = buttonConfig or ns:Copy(defaults)

	-- Retail has a new mixin that overrides some of our meta methods,
	-- so we're doing hard embedding now instead.
	for method,func in next,StanceButton do
		button[method] = func
	end

	-- Reference the objects by member properties, not global names.
	button.icon = _G[button:GetName() .. "Icon"]
	button.cooldown = _G[button:GetName() .. "Cooldown"]
	button.hotkey = _G[button:GetName() .. "HotKey"]
	button.normalTexture = button:GetNormalTexture()
	button.normalTexture:SetTexture("")

	button:SetID(id)

	ns.StanceButtons[button] = true

	return button
end

StanceButton.UpdateConfig = function(self, buttonConfig)
	self.config = buttonConfig or self.config
	self:Update()
end

StanceButton.UpdateAction = function(self)
	self:Update()
end

StanceButton.Update = function(self)
	if (not self:IsShown()) then return end

	local id = self:GetID()
	local texture, isActive, isCastable = GetShapeshiftFormInfo(id)

	self.icon:SetTexture(texture)

	if (texture) then
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end
	local start, duration, enable = GetShapeshiftFormCooldown(id)
	CooldownFrame_Set(self.cooldown, start, duration, enable)

	if (isActive) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end

	if (isCastable) then
		self.icon:SetVertexColor(1.0, 1.0, 1.0)
	else
		self.icon:SetVertexColor(0.4, 0.4, 0.4)
	end

	self:UpdateHotkeys()
end

StanceButton.UpdateHotkeys = function(self)
	local key = self:GetHotkey() or ""
	local hotkey = self.hotkey

	if (key == "" or (self.parent.config.hideElements and self.parent.config.hideElements.hotkey)) then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

StanceButton.GetHotkey = function(self)
	local key = GetBindingKey(string_format("SHAPESHIFTBUTTON%d", self:GetID())) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound and KeyBound:ToShortKey(key)
end

StanceButton.GetTexture = function(self)
	return (GetShapeshiftFormInfo(self:GetID()))
end
