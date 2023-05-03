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
local RaidBossEmotes = ns:NewModule("RaidBossEmotes", "LibMoreEvents-1.0", "AceHook-3.0")
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local pairs, unpack = pairs, unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "TOP",
			[2] = 0,
			[3] = -440
		}
	}
}, ns.moduleDefaults) }

RaidBossEmotes.InitializeRaidBossEmoteFrame = function(self)

	-- The RaidWarnings have a tendency to look really weird,
	-- as the SetTextHeight method scales the text after it already
	-- has been turned into a bitmap and turned into a texture.
	-- So I'm just going to turn it off. Completely.
	RaidBossEmoteFrame:SetAlpha(.85)
	RaidBossEmoteFrame:SetHeight(80)

	RaidBossEmoteFrame.timings.RAID_NOTICE_MIN_HEIGHT = 26
	RaidBossEmoteFrame.timings.RAID_NOTICE_MAX_HEIGHT = 26
	RaidBossEmoteFrame.timings.RAID_NOTICE_SCALE_UP_TIME = 0
	RaidBossEmoteFrame.timings.RAID_NOTICE_SCALE_DOWN_TIME = 0

	-- WoW 10.1.0
	local slot1 = RaidBossEmoteFrameSlot1 or RaidBossEmoteFrame.slot1
	if (slot1) then
		slot1:SetFontObject(GetFont(26, true, "Chat"))
		slot1:SetShadowColor(0, 0, 0, .5)
		slot1:SetWidth(760)
		slot1.SetTextHeight = function() end
	end

	-- WoW 10.1.0
	local slot2 = RaidBossEmoteFrameSlot2 or RaidBossEmoteFrame.slot2
	if (slot2) then
		slot2:SetFontObject(GetFont(26, true, "Chat"))
		slot2:SetShadowColor(0, 0, 0, .5)
		slot2:SetWidth(760)
		slot2.SetTextHeight = function() end
	end

	self.frame = RaidBossEmoteFrame
end

RaidBossEmotes.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(CHAT_MSG_RAID_BOSS_EMOTE)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(760, 80)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "CENTER"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor

end

RaidBossEmotes.UpdatePositionAndScale = function(self)

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

RaidBossEmotes.OnAnchorUpdate = function(self, reason, layoutName, ...)
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

RaidBossEmotes.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("RaidBossEmotes", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	if (MFM) then
		MFM:RegisterPresets(self.db.profile.savedPosition)
	end

	self:InitializeRaidBossEmoteFrame()
	self:InitializeMovableFrameAnchor()
end
