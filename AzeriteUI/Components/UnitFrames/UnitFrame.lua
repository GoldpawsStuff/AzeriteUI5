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
local oUF = ns.oUF

local LibSmoothBar = LibStub("LibSmoothBar-1.0")
local LibSpinBar = LibStub("LibSpinBar-1.0")
local LibOrb = LibStub("LibOrb-1.0")

local next = next

-- UnitFrame Callbacks
---------------------------------------------------
local UnitFrame_CreateBar = function(self, name, parent, ...)
	return LibSmoothBar:CreateSmoothBar(name, parent or self, ...)
end

local UnitFrame_CreateRing = function(self, name, parent, ...)
	return LibSpinBar:CreateSpinBar(name, parent or self, ...)
end

local UnitFrame_CreateOrb = function(self, name, parent, ...)
	return LibOrb:CreateOrb(name, parent or self, ...)
end

local UnitFrame_OnEnter = function(self, ...)
	self.isMouseOver = true
	if (self.OnEnter) then
		self:OnEnter(...)
	end
	return _G.UnitFrame_OnEnter(self, ...)
end

local UnitFrame_OnLeave = function(self, ...)
	self.isMouseOver = nil
	if (self.OnLeave) then
		self:OnLeave(...)
	end
	return _G.UnitFrame_OnLeave(self, ...)
end

local UnitFrame_OnHide = function(self, ...)
	self.isMouseOver = nil
	if (self.OnHide) then
		self:OnHide(...)
	end
end

-- UnitFrame Module Defauts
local defaults = {
	enabled = true,
	scale = 1
}

-- UnitFrame Prototype
---------------------------------------------------
oUF:RegisterMetaFunction("CreateBar", UnitFrame_CreateBar)
oUF:RegisterMetaFunction("CreateRing", UnitFrame_CreateRing)
oUF:RegisterMetaFunction("CreateOrb", UnitFrame_CreateOrb)

ns.UnitFrames = {}
ns.UnitFrame = {}
ns.UnitFrame.defaults = defaults

ns.UnitFrame.InitializeUnitFrame = function(self)

	self.isUnitFrame = true
	self.colors = ns.Colors

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:SetScript("OnHide", UnitFrame_OnHide)

end

ns.UnitFrame.Spawn = function(unit, overrideName, ...)

	local frame = oUF:Spawn(unit, overrideName)

	ns.UnitFrame.InitializeUnitFrame(frame)
	ns.UnitFrames[frame] = true

	return frame
end

-- UnitFrame Module Prototype
---------------------------------------------------
ns.UnitFrame.modulePrototype = {
	OnEnable = function(self)
		local frame = self.frame
		if (frame and frame.Enable) then
			frame:Enable()
		else
			if (self.Spawn) then
				self:Spawn()
			end
		end
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatEvent")
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEvent")
	end,

	OnDisable = function(self)
		local frame = self.frame
		if (frame and frame.Disable) then
			frame:Disable()
		end
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnCombatEvent")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEvent")
	end,

	OnCombatEvent = function(self, event, ...)
		if (event == "PLAYER_REGEN_ENABLED") then
			if (InCombatLockdown()) then return end
			self.incombat = nil
			if (self.positionNeedsFix) then
				self:UpdatePositionAndScale()
			end
		elseif (event == "PLAYER_REGEN_DISABLED") then
			self.incombat = true
		end
	end,

	OnAnchorUpdate = function(self, reason, layoutName, ...)
		local savedPositions = self.db.profile.savedPosition
		local defaultPositions = self.db.defaults.profile.savedPosition
		local lockdown = InCombatLockdown()

		if (reason == "LayoutDeleted") then
			if (savedPositions[layoutName]) then
				savedPositions[layoutName] = nil
			end

		elseif (reason == "LayoutsUpdated") then

			if (savedPositions[layoutName]) then

				self.anchor:SetScale(savedPositions[layoutName].scale or self.anchor:GetScale())
				self.anchor:ClearAllPoints()
				self.anchor:SetPoint(unpack(savedPositions[layoutName]))

				local defaultPosition = self.db.defaults.profile.savedPosition[layoutName] or defaultPositions.Azerite
				if (defaultPosition) then
					self.anchor:SetDefaultPosition(unpack(defaultPosition))
				end

				self.initialPositionSet = true
					--self.currentLayout = layoutName

			else
				-- The user is unlikely to have a preset with our name
				-- on the first time logging in.
				if (not self.initialPositionSet) then

					local defaultPosition = defaultPositions.Azerite

					self.anchor:SetScale(defaultPosition.scale)
					self.anchor:ClearAllPoints()
					self.anchor:SetPoint(unpack(defaultPosition))
					self.anchor:SetDefaultPosition(unpack(defaultPosition))

					self.initialPositionSet = true
					--self.currentLayout = layoutName
				end

				savedPositions[layoutName] = { self.anchor:GetPosition() }
				savedPositions[layoutName].scale = self.anchor:GetScale()
			end

			self.currentLayout = layoutName

			self:UpdatePositionAndScale()

		elseif (reason == "PositionUpdated") then
			-- Fires when position has been changed.
			local point, x, y = ...

			savedPositions[layoutName] = { point, x, y }
			savedPositions[layoutName].scale = self.anchor:GetScale()

			self:UpdatePositionAndScale()

		elseif (reason == "ScaleUpdated") then
			-- Fires when scale has been mousewheel updated.
			local scale = ...

			savedPositions[layoutName].scale = scale

			self:UpdatePositionAndScale()

		elseif (reason == "Dragging") then
			-- Fires on every drag update. Spammy.
			if (not self.incombat) then
				self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
			end

		elseif (reason == "CombatStart") then
			-- Fires right before combat lockdown for visible anchors.


		elseif (reason == "CombatEnd") then
			-- Fires when combat lockdown ends for visible anchors.

		end
	end,

	UpdatePositionAndScale = function(self)
		if (InCombatLockdown()) then
			self.positionNeedsFix = true
			return
		end
		if (not self.frame) then return end

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
}
