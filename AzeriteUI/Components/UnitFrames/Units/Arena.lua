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

do return end

if (ns.IsClassic) then return end

local oUF = ns.oUF

local ArenaFrameMod = ns:NewModule("ArenaFrames", ns.UnitFrameModule, "LibMoreEvents-1.0")

local defaults = { profile = ns:Merge({}, ns.Module.defaults) }

ArenaFrameMod.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "CENTER",
		[2] = 300 * ns.API.GetEffectiveScale(),
		[3] = 80 * ns.API.GetEffectiveScale()
	}
	return defaults
end

ArenaFrameMod.CreateUnitFrames = function(self)
end

ArenaFrameMod.OnEnable = function(self)

	-- Disable Blizzard arena enemy frames.
	for i = 1, MAX_ARENA_ENEMIES or 5 do -- constant created by Blizzard_ArenaUI in wrath
		oUF:DisableBlizzard("arena"..i)
	end

	self:CreateUnitFrames()

	ns.Module.OnEnable(self)
end
