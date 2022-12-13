--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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

local UnitFrames = ns:GetModule("UnitFrames", true)
if (not UnitFrames) then return end

local Blizzard = UnitFrames:NewModule("Blizzard", "LibMoreEvents-1.0")

Blizzard.DisablePlayerPowerBarAlt = function(self)
	PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_SHOW")
	PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_HIDE")
	PlayerPowerBarAlt:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

Blizzard.DisableClassNamePlatePowerBar = function(self)
	if (NamePlateDriverFrame.classNamePlatePowerBar) then
		NamePlateDriverFrame.classNamePlatePowerBar:Hide()
		NamePlateDriverFrame.classNamePlatePowerBar:UnregisterAllEvents()
	end
	if (NamePlateDriverFrame.SetupClassNameplateBars) then
		hooksecurefunc(NamePlateDriverFrame, "SetupClassNameplateBars", function(frame)
			if (not frame or frame:IsForbidden()) then
				return
			end
			if (frame.classNamePlateMechanicFrame) then
				frame.classNamePlateMechanicFrame:Hide()
			end
			if (frame.classNamePlatePowerBar) then
				frame.classNamePlatePowerBar:Hide()
				frame.classNamePlatePowerBar:UnregisterAllEvents()
			end
		end)
	end
	-- This is about sizes, should be set by styling, not this.
	--if (NamePlateDriverFrame.UpdateNamePlateOptions) then
	--	hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateOptions", function()
	--		if (InCombatLockdown()) then return end
	--		local w,h = unpack(ns.Config.NamePlates.Size)
	--		C_NamePlate.SetNamePlateFriendlySize(w,h)
	--		C_NamePlate.SetNamePlateEnemySize(w,h)
	--		C_NamePlate.SetNamePlateSelfSize(w,h)
	--	end)
	--end
end

Blizzard.OnEnable = function(self)
	self:DisablePlayerPowerBarAlt()
	self:DisableClassNamePlatePowerBar()
end
