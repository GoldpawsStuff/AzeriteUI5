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
local ArcheologyBar = ns:NewModule("ArcheologyBar", "LibMoreEvents-1.0", "AceHook-3.0")
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local pairs, unpack = pairs, unpack

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "BOTTOM",
			[2] = 0,
			[3] = 390
		}
	}
}, ns.moduleDefaults) }

ArcheologyBar.InitializeArcheologyBar = function(self)
	self.frame = ArcheologyDigsiteProgressBar
end

ArcheologyBar.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(PROFESSIONS_ARCHAEOLOGY)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(240, 24)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "CENTER"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor

end

ArcheologyBar.UpdatePositionAndScale = function(self)
	if (not self.frame) then return end

	local savedPosition = self.currentLayout and self.db.profile.savedPosition[self.currentLayout]
	if (savedPosition) then
		local point, x, y = unpack(savedPosition)
		local scale = savedPosition.scale
		local anchor = self.anchor
		local frame = self.frame

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

ArcheologyBar.OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPosition = self.db.profile.savedPosition
	local lockdown = InCombatLockdown()

	if (reason == "LayoutDeleted") then
		if (savedPosition[layoutName]) then
			savedPosition[layoutName] = nil
		end

	elseif (reason == "LayoutsUpdated") then

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

ArcheologyBar.OnEvent = function(self, event, addon)
	if (event == "ADDON_LOADED") then
		if (addon ~= "Blizzard_ArchaeologyUI") then return end
		self:InitializeArcheologyBar()
		self:UpdatePositionAndScale()
		self:UnregisterEvent("ADDON_LOADED", "OnEvent")
	end
end

ArcheologyBar.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ArcheologyBar", defaults)
	--self.db:SetProfile("Default")

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	if (MFM) then
		MFM:RegisterPresets(self.db.profile.savedPosition)
	end

	self:InitializeArcheologyBar()
	self:InitializeMovableFrameAnchor()

	if (not self.frame) then
		self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end
end
