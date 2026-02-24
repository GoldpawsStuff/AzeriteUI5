--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

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

-- GLOBALS: LoadAddOn, ChannelFrame

local FixBlizzardBugs = ns:NewModule("FixBlizzardBugs")

-- Workaround for https://worldofwarcraft.blizzard.com/en-gb/news/24030413/hotfixes-november-16-2023
local InCombatLockdown = _G.InCombatLockdown

if (issecurevariable("IsItemInRange")) then
	local IsItemInRange = _G.IsItemInRange
	_G.IsItemInRange = function(...)
		return InCombatLockdown() and true or IsItemInRange(...)
	end
end

if (issecurevariable("UnitInRange")) then
	local UnitInRange = _G.UnitInRange
	_G.UnitInRange = function(...)
		return InCombatLockdown() and true or UnitInRange(...)
	end
end

FixBlizzardBugs.OnInitialize = function(self)
	-- Don't call this prior to our own addon loading,
	-- or it'll completely mess up the loading order.
	LoadAddOn("Blizzard_Channels")

	-- Kill off the non-stop voice chat error 17 on retail.
	-- This only occurs in linux, but we can't check for that.
	ChannelFrame:UnregisterEvent("VOICE_CHAT_ERROR")

end
