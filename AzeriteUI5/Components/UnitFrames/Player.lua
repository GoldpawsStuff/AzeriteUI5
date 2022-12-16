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
local oUF = ns.oUF

local PlayerMod = ns:NewModule("PlayerFrame", "LibMoreEvents-1.0")

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "BOTTOMLEFT",
			[2] = 167,
			[3] = 100
		},
		Classic = {
			scale = 1,
			[1] = "TOPLEFT",
			[2] = 167,
			[3] = -100
		},
		Modern = {
			scale = 1,
			[1] = "TOPLEFT",
			[2] = 167,
			[3] = -100
		}
	}
}, ns.UnitFrame.defaults) }

local style = function(self, unit)

end

PlayerMod.DisableBlizzard = function(self)
	oUF:DisableBlizzard("player")

	-- Disable Player Alternate Power Bar
	PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_SHOW")
	PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_HIDE")
	PlayerPowerBarAlt:UnregisterEvent("PLAYER_ENTERING_WORLD")

	-- Disable player cast bar

	-- Disable class powers
	-- Disable monk stagger
	-- Disable death knight runes
end

PlayerMod.GetAnchor = function(self)
	if (not self.Anchor) then

		local anchor = ns.Widgets.RequestMovableFrameAnchor()
		anchor:SetScalable(true)
		anchor:SetMinMaxScale(.75, 1.25, .05)
		anchor:SetSize(439, 93)
		anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
		anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
		anchor:SetTitle(ns.Prefix.."PlayerFrame")
		anchor.Callback = function(_, ...) self:OnAnchorUpdate(...) end

		self.Anchor = anchor
	end
	return self.Anchor
end

PlayerMod.OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPosition = PlayerMod.db.profile.savedPosition

	if (reason == "LayoutsUpdated") then
		if (savedPosition[layoutName]) then

			-- Update defaults
			-- Update current positon
			self.Anchor:SetScale(savedPosition[layoutName].scale or self.Anchor:GetScale())
			self.Anchor:ClearAllPoints()
			self.Anchor:SetPoint(unpack(savedPosition[layoutName]))
			self.currentLayout = layoutName

		else
			savedPosition[layoutName] = { self.Anchor:GetPosition() }
			savedPosition[layoutName].scale = self.Anchor:GetScale()
		end

		-- Purge layouts not matching editmode themes or our defaults.
		for name in pairs(savedPosition) do
			if (not defaults.profile.savedPosition[name]) then
				local found
				for lname in pairs(C_EditMode.GetLayouts().layouts) do
					if (lname == name) then
						found = true
						break
					end
				end
				if (not found) then
					savedPosition[name] = nil
				end
			end
		end

		self:UpdatePositionAndScale()

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPosition[layoutName] = { point, x, y }
		savedPosition[layoutName].scale = self.Anchor:GetScale()

		self:UpdatePositionAndScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPosition[layoutName].scale = scale

		self:UpdatePositionAndScale()

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		if (not self.incombat) then
			self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
		end

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown for visible anchors.
		self.positionNeedsFix = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")

	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends for visible anchors.

	end
end

PlayerMod.UpdatePositionAndScale = function(self)
	if (ns.UnitFrames.Player) then
		local savedPosition = PlayerMod.db.profile.savedPosition
		if (self.currentLayout and savedPosition[self.currentLayout]) then
			ns.UnitFrames.Player:ClearAllPoints()
			ns.UnitFrames.Player:SetPoint(unpack(savedPosition[self.currentLayout]))
			ns.UnitFrames.Player:SetScale(savedPosition[self.currentLayout].scale)
		end
	end
	self.positionNeedsFix = nil
end

PlayerMod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		--self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self.incombat = nil
		if (self.positionNeedsFix) then
			self:UpdatePositionAndScale()
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true
	end
end

PlayerMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("PlayerFrame", defaults)
	self:SetEnabledState(self.db.profile.enabled)
	self:DisableBlizzard()

	oUF:RegisterStyle(ns.Prefix.."Player", style)
end

PlayerMod.OnEnable = function(self)
	if (ns.UnitFrames.Player) then
		ns.UnitFrames.Player:Enable()
	else
		oUF:SetActiveStyle(ns.Prefix.."Player")
		ns.UnitFrames.Player = oUF:Spawn("player", ns.Prefix.."UnitFramePlayer")
		ns.UnitFrames.Player.Anchor = self:GetAnchor()
	end
end

PlayerMod.OnDisable = function(self)
	if (ns.UnitFrames.Player) then
		ns.UnitFrames.Player:Disable()
	end
end
