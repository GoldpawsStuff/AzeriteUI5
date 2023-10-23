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

local LAB = LibStub("LibActionButton-1.0-GE")

ns.ActionButtons = {}
ns.ActionButton = {}

local onEnter = function(self)
	-- Obey tooltip options if the tooltip module is enabled.
	local tooltips = ns:GetModule("Tooltips", true)
	if (tooltips and tooltips:IsEnabled() and tooltips.db.profile.hideInCombat and tooltips.db.profile.hideActionBarTooltipsInCombat and InCombatLockdown()) then
		return
	end
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local onLeave = function(self)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

ns.ActionButton.Create = function(id, name, header, buttonConfig)

	local button = LAB:CreateButton(id, name, header, buttonConfig)

	if (not button.OnEnter) then
		button.OnEnter = button:GetScript("OnEnter")
	end

	if (not button.OnLeave) then
		button.OnLeave = button:GetScript("OnLeave")
	end

	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)

	ns.ActionButtons[button] = true

	return button
end

