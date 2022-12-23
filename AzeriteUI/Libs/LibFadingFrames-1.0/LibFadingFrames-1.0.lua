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
local MAJOR_VERSION = "LibFadingFrames-1.0"
local MINOR_VERSION = -1

assert(LibStub, MAJOR_VERSION .. " requires LibStub.")

local LibMoreEvents = LibStub:GetLibrary("LibMoreEvents-1.0", true)
assert(MAJOR_VERSION .. " requires LibMoreEvents-1.0.")

local AceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
assert(MAJOR_VERSION .. " requires AceTimer-3.0.")

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

LibMoreEvents:Embed(lib)
AceTimer:Embed(lib)

lib.fadeFrames = lib.fadeFrames or {}
lib.fadeFrameType = lib.fadeFrameType or {}
lib.hoverFrames = lib.hoverFrames or {}
lib.hoverCount = lib.hoverCount or { default = 0 }
lib.gridCounter = lib.gridCounter or 0
lib.cache = lib.cache or { methods = {}, scrips = {} }
lib.embeds = lib.embeds or {}

-- Lua API
local next = next

-- Frame Metamethods
local setAlpha = getmetatable(CreateFrame("Frame")).__index.SetAlpha

lib.UpdateFadeFrames = function(self)
	if (not self.inWorld) then return end

	-- Something is forcing the frames to be shown,
	-- like an item currently on the cursor.
	if (self.gridCounter >= 1) then
		for frame in next,self.fadeFrames do
			setAlpha(frame, 1)
		end

	-- Bar fading is disabled, just copying the default settings here.
	elseif (not self.enableFading) then
		for frame in next,self.fadeFrames do

			if (self.fadeFrameType[frame] == "actionbutton") then
				-- The frame has an action or grid set to visible.
				if (frame:HasAction()) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
					setAlpha(frame, 1)
				else
					setAlpha(frame, 0)
				end
			else
				setAlpha(frame, 1)
			end
		end
	else
		-- Bar fading is enabled.
		for frame,fadeGroups in next,self.fadeFrames do

			-- The group is visible.
			if (self.hoverCount[fadeGroups] > 0) then

				if (self.fadeFrameType[frame] == "actionbutton") then
					-- The frame has an action or grid set to visible.
					if (frame:HasAction()) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
						setAlpha(frame, 1)
					else
						setAlpha(frame, 0)
					end
				else
					setAlpha(frame, 1)
				end

			else
				-- Group is hidden, hide this.
				setAlpha(frame, 0)
			end
		end
	end
end

lib.OnFadeFrameEnter = function(self, frame, fadeGroup)
	if (self.hoverFrames[frame]) then return end
	self.hoverCount[fadeGroup] = self.hoverCount[fadeGroup] + 1
	self.hoverFrames[frame] = fadeGroup
end

lib.OnFadeFrameLeave = function(self, frame, fadeGroup)
	if (not self.hoverFrames[frame]) then return end
	self.hoverCount[fadeGroup] = self.hoverCount[fadeGroup] - 1
	self.hoverFrames[frame] = nil
end

lib.CheckFadeFrames = function(self)
	for frame,fadeGroup in next,self.hoverFrames do
		if (not frame:IsMouseOver()) then
			self:OnFadeFrameLeave(frame, fadeGroup)
		end
	end
	for frame,fadeGroup in next,self.fadeFrames do
		if (not self.hoverFrames[frame] and frame:IsMouseOver()) then
			self:OnFadeFrameEnter(frame, fadeGroup)
		end
	end
end

lib.RegisterFrameForFading = function(self, frame, fadeGroup)
	if (self.fadeFrames[frame]) then
		return
	end

	local shouldInit = not not next(self.fadeFrames)

	fadeGroup = fadeGroup or "default"

	-- Not the best check ever, but it'll have to do for now.
	if (frame:GetObjectType() == "CheckButton") and (frame.HasAction) then
		self.fadeFrameType[frame] = "actionbutton"
	end

	-- Might be spammy, but I prefer not to replace frame methods.
	self:SecureHook(frame, "SetAlpha", "UpdateFadeFrames")

	if (not self.hoverCount[fadeGroup]) then
		self.hoverCount[fadeGroup] = 0
	end

	self.fadeFrames[frame] = fadeGroup

	if (shouldInit) then
		self:Enable()
	end

	self:UpdateFadeFrames()
end

lib.UnregisterFrameForFading = function(self, frame)
	if (not self.fadeFrames[frame]) then
		return
	end

	self:Unhook(frame, "SetAlpha", "UpdateFadeFrames")

	self.fadeFrames[frame] = nil
	self.fadeFrameType[frame] = nil

	if (not next(self.fadeFrames)) then
		self:Disable()
	end

	self:UpdateFadeFrames()
end

lib.EnableFading = function(self)
	if (self.enableFading) then return end

	self.enableFading = true

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")

	if (IsPlayerInWorld()) then
		self:OnEvent("PLAYER_ENTERING_WORLD")
	end

	if (not self.checkTimer) then
		self.checkTimer = self:ScheduleRepeatingTimer("CheckFadeFrames", 0.1)
	end

	self:CheckFadeFrames()
	self:UpdateFadeFrames()
end

lib.DisableFading = function(self)
	if (not self.enableFading) then return end

	self.enableFading = false

	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:UnregisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:UnregisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")

	if (self.checkTimer) then
		self.checkTimer:CancelTimer()
	end

	self:UpdateFadeFrames()
end

lib.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self.inWorld = true
		self.inCombat = nil

		for fadeGroup in next,self.hoverCount do
			self.hoverCount[fadeGroup] = 0
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil

	elseif (event == "ACTIONBAR_SHOWGRID") then
		self.gridCounter = self.gridCounter + 1

		if (self.gridCounter >= 1) then
			self:UpdateFadeFrames()
		end
		return

	elseif (event == "ACTIONBAR_HIDEGRID") then
		if (self.gridCounter > 0) then
			self.gridCounter = self.gridCounter - 1
		end
		if (self.gridCounter == 0) then
			self:UpdateFadeFrames()
		end
		return
	end
	self:UpdateFadeFrames()
end

local mixins = {
	RegisterFrameForFading = true,
	UnregisterFrameForFading = true
}

lib.Embed = function(self, target)
	for method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
