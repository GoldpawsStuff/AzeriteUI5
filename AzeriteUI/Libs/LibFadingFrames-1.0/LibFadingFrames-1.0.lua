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
local MAJOR_VERSION = "LibFadingFrames-1.0"
local MINOR_VERSION = 8

assert(LibStub, MAJOR_VERSION .. " requires LibStub.")

local LibMoreEvents = LibStub:GetLibrary("LibMoreEvents-1.0", true)
assert(MAJOR_VERSION .. " requires LibMoreEvents-1.0.")

local AceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
assert(MAJOR_VERSION .. " requires AceTimer-3.0.")

local AceHook = LibStub:GetLibrary("AceHook-3.0", true)
assert(MAJOR_VERSION .. " requires AceHook-3.0.")

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

LibMoreEvents:Embed(lib)
AceTimer:Embed(lib)
AceHook:Embed(lib)

lib.fadeFrames = lib.fadeFrames or {}
lib.fadeFrameType = lib.fadeFrameType or {}
lib.fadeFrameHitRects = lib.fadeFrameHitRects or {}
lib.hoverFrames = lib.hoverFrames or {}
lib.hoverCount = lib.hoverCount or { default = 0 }
lib.gridCounter = lib.gridCounter or 0
lib.cache = lib.cache or { methods = {}, scrips = {} }
lib.embeds = lib.embeds or {}

-- Lua API
local next = next

-- Frame Metamethods
local setAlpha = getmetatable(CreateFrame("Frame")).__index.SetAlpha

lib.UpdateFadeFrame = function(self, frame)

	local isActionButton = self.fadeFrameType[frame] == "actionbutton"
	if (isActionButton and (self.inCombat and frame:GetTexture()) or (self.gridCounter >= 1)) then
		setAlpha(frame, 1)
		return
	end

	if (not self.enableFading) then
		if (isActionButton) then
			-- The frame has an action or grid set to visible.
			if (frame:GetTexture()) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
				setAlpha(frame, 1)
			else
				setAlpha(frame, 0)
			end
		else
			setAlpha(frame, 1)
		end
	else
		-- The group is visible.
		if (self.hoverCount[self.fadeFrames[frame]] > 0) then
			if (isActionButton) then
				-- The frame has an action or grid set to visible.
				if (frame:GetTexture()) or (frame.config and frame.config.showGrid) or (frame.parent and frame.parent.config.showGrid) then
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

lib.UpdateFadeFrames = function(self)
	if (not self.inWorld) then return end
	for frame in next,self.fadeFrames do
		self:UpdateFadeFrame(frame)
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
	local needupdate
	for frame,fadeGroup in next,self.hoverFrames do
		-- Frame could've been unregistered while hovered.
		if (not self.fadeFrames[frame] or not frame:IsMouseOver(unpack(lib.fadeFrameHitRects[frame]))) then
			self:OnFadeFrameLeave(frame, fadeGroup)
			needupdate = true
		end
	end
	for frame,fadeGroup in next,self.fadeFrames do
		if (not self.hoverFrames[frame] and frame:IsMouseOver(unpack(lib.fadeFrameHitRects[frame]))) then
			self:OnFadeFrameEnter(frame, fadeGroup)
			needupdate = true
		end
	end
	if (needupdate) then
		self:UpdateFadeFrames()
	end
end

lib.RegisterFrameForFading = function(self, frame, fadeGroup, ...)
	if (lib.fadeFrames[frame]) then
		return
	end

	local shouldInit = not next(lib.fadeFrames)

	fadeGroup = fadeGroup or "default"

	-- Not the best check ever, but it'll have to do for now.
	if (frame:GetObjectType() == "CheckButton") and (frame.HasAction) then
		lib.fadeFrameType[frame] = "actionbutton"
	end

	-- Might be spammy, but I prefer not to replace frame methods.
	lib:SecureHook(frame, "SetAlpha", "UpdateFadeFrame")

	if (not lib.hoverCount[fadeGroup]) then
		lib.hoverCount[fadeGroup] = 0
	end

	lib.fadeFrames[frame] = fadeGroup

	-- Convert frame hit rects to mouseover values.
	if (...) then
		local left, right, top, bottom = ...
		lib.fadeFrameHitRects[frame] = { -top, bottom, left, -right }
	else
		lib.fadeFrameHitRects[frame] = { 0, 0, 0, 0 }
	end

	if (shouldInit) then
		lib:Enable()
	end

	lib:UpdateFadeFrames()
end

lib.UnregisterFrameForFading = function(self, frame, noAlphaChange)
	if (not lib.fadeFrames[frame]) then
		if (not noAlphaChange) then
			setAlpha(frame, 1)
		end
		return
	end

	lib:Unhook(frame, "SetAlpha", "UpdateFadeFrame")

	lib.fadeFrames[frame] = nil
	lib.fadeFrameType[frame] = nil
	lib.fadeFrameHitRects[frame] = nil

	if (not noAlphaChange) then
		setAlpha(frame, 1)
	end

	if (not next(lib.fadeFrames)) then
		lib:Disable()
	end

	lib:UpdateFadeFrames()
end

lib.Enable = function(self)
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

lib.Disable = function(self)
	if (not self.enableFading) then return end

	self.enableFading = false

	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:UnregisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:UnregisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")

	if (self.checkTimer) then
		self:CancelTimer(self.checkTimer)
		self.checkTimer = nil
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
