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

local RaidBossEmotes = ns:NewModule("RaidBossEmotes", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

-- Addon API
local GetFont = ns.API.GetFont

local defaults = { profile = ns:Merge({}, ns.Module.defaults) }

RaidBossEmotes.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "TOP",
		[2] = 0 ,
		[3] = -440 * ns.API.GetEffectiveScale()
	}
	return defaults
end

RaidBossEmotes.PrepareFrames = function(self)
	if (self.frame) then return end

	self.frame = RaidBossEmoteFrame

	-- The RaidWarnings have a tendency to look really weird,
	-- as the SetTextHeight method scales the text after it already
	-- has been turned into a bitmap and turned into a texture.
	-- So I'm just going to turn it off. Completely.
	self.frame:SetAlpha(.85)
	self.frame:SetHeight(80)

	self.frame.timings.RAID_NOTICE_MIN_HEIGHT = 26
	self.frame.timings.RAID_NOTICE_MAX_HEIGHT = 26
	self.frame.timings.RAID_NOTICE_SCALE_UP_TIME = 0
	self.frame.timings.RAID_NOTICE_SCALE_DOWN_TIME = 0

	-- WoW 10.1.0
	local slot1 = _G[self.frame:GetName() .. "Slot1"] or self.frame.slot1
	if (slot1) then
		slot1:SetFontObject(GetFont(26, true, "Chat"))
		slot1:SetShadowColor(0, 0, 0, .5)
		slot1:SetWidth(760)
		slot1.SetTextHeight = function() end
	end

	-- WoW 10.1.0
	local slot2 = _G[self.frame:GetName() .. "Slot2"] or self.frame.slot2
	if (slot2) then
		slot2:SetFontObject(GetFont(26, true, "Chat"))
		slot2:SetShadowColor(0, 0, 0, .5)
		slot2:SetWidth(760)
		slot2.SetTextHeight = function() end
	end

end

RaidBossEmotes.UpdateAnchor = function(self)
	local config = self.db.profile.savedPosition

	self.anchor:SetSize(760, 80)
	self.anchor:SetScale(config.scale)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(config[1], UIParent, config[1], config[2], config[3])
end

RaidBossEmotes.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(CHAT_MSG_RAID_BOSS_EMOTE)

	ns.Module.OnEnable(self)
end
