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
if (ns.IsClassic) then return end

local oUF = ns.oUF

local ArenaFrameMod = ns:Merge(ns:NewModule("ArenaFrames", "LibMoreEvents-1.0"), ns.UnitFrame.modulePrototype)
local MFM = ns:GetModule("MovableFramesManager")

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		[MFM:GetDefaultLayout()] = {
			enabled = true,
			scale = ns.API.GetEffectiveScale(),
			[1] = "TOPRIGHT",
			[2] = -64 * ns.API.GetEffectiveScale(),
			[3] = -279 * ns.API.GetEffectiveScale()
		}
	}
}, ns.UnitFrame.defaults) }

ArenaFrameMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ArenaFrames", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	MFM:RegisterPresets(self.db.profile.savedPosition)

	-- Disable Blizzard arena enemy frames.
	for i = 1, MAX_ARENA_ENEMIES or 5 do -- constant created by Blizzard_ArenaUI in wrath
		oUF:DisableBlizzard("arena"..i)
	end
end
