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
local VehicleSeat = ns:NewModule("VehicleSeat")

-- Lua API
local pairs, unpack = pairs, unpack

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "BOTTOMRIGHT",
			[2] = -480+64,
			[3] = 210-64
		}
	}
}, ns.moduleDefaults) }

VehicleSeat.InitializeVehicleSeatIndicator = function(self)

	VehicleSeatIndicator:SetParent(UIParent)
	VehicleSeatIndicator:SetFrameStrata("BACKGROUND")

	-- This will block UIParent_ManageFramePositions() from being executed
	VehicleSeatIndicator.IsShown = function() return false end

	self.frame = VehicleSeatIndicator
end

VehicleSeat.InitializeMovableFrameAnchor = function(self)

	local anchor = ns.Widgets.RequestMovableFrameAnchor()
	anchor:SetTitle("Vehicle Seat")
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(128, 128)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "CENTER"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor
end

VehicleSeat.UpdatePositionAndScale = function(self)

	local savedPosition = self.currentLayout and self.db.profile.savedPosition[self.currentLayout]
	if (savedPosition) then
		local point, x, y = unpack(savedPosition)
		local scale = savedPosition.scale
		local frame = self.frame
		local anchor = self.anchor

		-- Set the scale before positioning,
		-- or everything will be wonky.
		frame:SetScale(scale)

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

VehicleSeat.OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPosition = self.db.profile.savedPosition
	local lockdown = InCombatLockdown()

	if (reason == "LayoutsUpdated") then

		if (savedPosition[layoutName]) then

			self.anchor:SetScale(savedPosition[layoutName].scale or self.anchor:GetScale())
			self.anchor:ClearAllPoints()
			self.anchor:SetPoint(unpack(savedPosition[layoutName]))

			local defaultPosition = defaults.profile.savedPosition[layoutName]
			if (defaultPosition) then
				self.anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			self.initialPositionSet = true
				--self.currentLayout = layoutName

		else
			-- The user is unlikely to have a preset with our name
			-- on the first time logging in.
			if (not self.initialPositionSet) then
				--print("setting default position for", layoutName, self.frame:GetName())

				local defaultPosition = defaults.profile.savedPosition.Azerite

				self.anchor:SetScale(defaultPosition.scale)
				self.anchor:ClearAllPoints()
				self.anchor:SetPoint(unpack(defaultPosition))
				self.anchor:SetDefaultPosition(unpack(defaultPosition))

				self.initialPositionSet = true
				--self.currentLayout = layoutName
			end

			savedPosition[layoutName] = { self.anchor:GetPosition() }
			savedPosition[layoutName].scale = self.anchor:GetScale()
		end

		self.currentLayout = layoutName

		-- Purge layouts not matching editmode themes or our defaults.
		for name in pairs(savedPosition) do
			if (not defaults.profile.savedPosition[name] and name ~= "Modern" and name ~= "Classic") then
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
		savedPosition[layoutName].scale = self.anchor:GetScale()

		self:UpdatePositionAndScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPosition[layoutName].scale = scale

		self:UpdatePositionAndScale()

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		--if (not self.incombat) then
			self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
		--end

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown for visible anchors.


	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends for visible anchors.

	end
end

VehicleSeat.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("VehicleSeat", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	self:InitializeVehicleSeatIndicator()
	self:InitializeMovableFrameAnchor()
end