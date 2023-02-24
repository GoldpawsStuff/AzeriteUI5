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
if (not ns.IsWrath) or (not MultiCastActionBarFrame) or (ns.PlayerClass ~= "SHAMAN") then
	return
end

local MultiCast = ns:NewModule("MultiCast", "LibMoreEvents-1.0", "AceHook-3.0")

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local config = {
	MultiCastPosition = { "CENTER", UIParent, "CENTER", 0, -200 },
	MultiCastSize = { 230, 38 }
}

MultiCast.UpdateMultiCastBar = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	MultiCastActionBarFrame:ClearAllPoints()
	MultiCastActionBarFrame:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0)
end

MultiCast.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateMultiCastBar()
	end
end

MultiCast.OnInitialize = function(self)
	local bar = CreateFrame("Frame", ns.Prefix.."MultiCastFrame", UIParent)
	bar:SetSize(unpack(config.MultiCastSize))
	bar:SetPoint(unpack(config.MultiCastPosition))
	bar:SetScale(1.25)

	MultiCastActionBarFrame:SetScript("OnShow", nil)
	MultiCastActionBarFrame:SetScript("OnHide", nil)
	MultiCastActionBarFrame:SetScript("OnUpdate", nil)
	MultiCastActionBarFrame:SetParent(bar)

	self:SecureHook("ShowMultiCastActionBar", "UpdateMultiCastBar")
end

MultiCast.OnEnable = function(self)
	self:UpdateMultiCastBar()
end
