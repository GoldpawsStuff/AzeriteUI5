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
local ChatFrames = ns:NewModule("ChatFrames", "LibMoreEvents-1.0", "AceHook-3.0")

ChatFrames.StyleFrame = function(self, frame)
	if (frame.isSkinned) then return end

	local name = frame:GetName()
	local id = frame:GetID()

	frame:SetFrameStrata("MEDIUM")
	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	frame:SetFading(5)
	frame:SetTimeVisible(25)
	frame:SetIndentedWordWrap(false)

	-- Hide textures
	for i = 1, #CHAT_FRAME_TEXTURES do
		_G[name..CHAT_FRAME_TEXTURES[i]]:SetTexture(nil)
	end

end

ChatFrames.StyleTempFrame = function(self)
	local frame = FCF_GetCurrentChatFrame()
	if (not frame or frame.isSkinned) then return end
	self:StyleFrame(frame)
end

ChatFrames.SetChatFramePosition = function(self)
end

ChatFrames.SaveChatFramePositionAndDimensions = function(self)
end

ChatFrames.UpdateEditBoxColor = function(self)
end

ChatFrames.UpdateTabAlpha = function(self, frame)
	local tab = _G[frame .. "Tab"]
	if (tab.noMouseAlpha == .4 or tab.noMouseAlpha == .2) then
		tab:SetAlpha(0)
		tab.noMouseAlpha = 0
	end
end

ChatFrames.AddToast = function(self)
end

ChatFrames.HookChat = function(self)
	self:SecureHook("ChatEdit_UpdateHeader", "UpdateEditBoxColor")
	self:SecureHook("FCF_OpenTemporaryWindow", "StyleTempFrame")
	self:SecureHook("FCF_RestorePositionAndDimensions", "SetChatFramePosition")
	self:SecureHook("FCF_SavePositionAndDimensions", "SaveChatFramePositionAndDimensions")
	self:SecureHook("FCFTab_UpdateAlpha", "UpdateTabAlpha")
	self:SecureHook(BNToastFrame, "AddToast", "AddToast")
end

ChatFrames.OnEvent = function(self, event, ...)
end

ChatFrames.OnInitialize = function(self)
	if (not ns.db.global.chatframes.enableChat) then
		return self:Disable()
	end

end

ChatFrames.OnEnable = function(self)
	self:HookChat()
end
