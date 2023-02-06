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
local ErrorsFrame = ns:NewModule("ErrorsFrame", "LibMoreEvents-1.0", "AceHook-3.0")
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
			[3] = -600
		}
	}
}, ns.moduleDefaults) }

local blackList = {
	msgTypes = {
		[LE_GAME_ERR_ABILITY_COOLDOWN] = true,
		[LE_GAME_ERR_SPELL_COOLDOWN] = true,
		[LE_GAME_ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS] = true,
		[LE_GAME_ERR_OUT_OF_SOUL_SHARDS] = true,
		[LE_GAME_ERR_OUT_OF_FOCUS] = true,
		[LE_GAME_ERR_OUT_OF_COMBO_POINTS] = true,
		[LE_GAME_ERR_OUT_OF_HEALTH] = true,
		[LE_GAME_ERR_OUT_OF_RAGE] = true,
		[LE_GAME_ERR_OUT_OF_RANGE] = true,
		[LE_GAME_ERR_OUT_OF_ENERGY] = true
	},
	[ ERR_ABILITY_COOLDOWN ] = true, 						-- Ability is not ready yet.
	[ ERR_ATTACK_CHARMED ] = true, 							-- Can't attack while charmed.
	[ ERR_ATTACK_CONFUSED ] = true, 						-- Can't attack while confused.
	[ ERR_ATTACK_DEAD ] = true, 							-- Can't attack while dead.
	[ ERR_ATTACK_FLEEING ] = true, 							-- Can't attack while fleeing.
	[ ERR_ATTACK_PACIFIED ] = true, 						-- Can't attack while pacified.
	[ ERR_ATTACK_STUNNED ] = true, 							-- Can't attack while stunned.
	[ ERR_AUTOFOLLOW_TOO_FAR ] = true, 						-- Target is too far away.
	[ ERR_BADATTACKFACING ] = true, 						-- You are facing the wrong way!
	[ ERR_BADATTACKPOS ] = true, 							-- You are too far away!
	[ ERR_CLIENT_LOCKED_OUT ] = true, 						-- You can't do that right now.
	[ ERR_ITEM_COOLDOWN ] = true, 							-- Item is not ready yet.
	[ ERR_OUT_OF_ENERGY ] = true, 							-- Not enough energy
	[ ERR_OUT_OF_FOCUS ] = true, 							-- Not enough focus
	[ ERR_OUT_OF_HEALTH ] = true, 							-- Not enough health
	[ ERR_OUT_OF_MANA ] = true, 							-- Not enough mana
	[ ERR_OUT_OF_RAGE ] = true, 							-- Not enough rage
	[ ERR_OUT_OF_RANGE ] = true, 							-- Out of range.
	[ ERR_SPELL_COOLDOWN ] = true, 							-- Spell is not ready yet.
	[ ERR_SPELL_FAILED_ALREADY_AT_FULL_HEALTH ] = true, 	-- You are already at full health.
	[ ERR_SPELL_OUT_OF_RANGE ] = true, 						-- Out of range.
	[ ERR_USE_TOO_FAR ] = true, 							-- You are too far away.
	[ SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW ] = true, 		-- You can't do that right now.
	[ SPELL_FAILED_CASTER_AURASTATE ] = true, 				-- You can't do that yet
	[ SPELL_FAILED_CASTER_DEAD ] = true, 					-- You are dead
	[ SPELL_FAILED_CASTER_DEAD_FEMALE ] = true, 			-- You are dead
	[ SPELL_FAILED_CHARMED ] = true, 						-- Can't do that while charmed
	[ SPELL_FAILED_CONFUSED ] = true, 						-- Can't do that while confused
	[ SPELL_FAILED_FLEEING ] = true, 						-- Can't do that while fleeing
	[ SPELL_FAILED_ITEM_NOT_READY ] = true, 				-- Item is not ready yet
	[ SPELL_FAILED_NO_COMBO_POINTS ] = true, 				-- That ability requires combo points
	[ SPELL_FAILED_NOT_BEHIND ] = true, 					-- You must be behind your target.
	[ SPELL_FAILED_NOT_INFRONT ] = true, 					-- You must be in front of your target.
	[ SPELL_FAILED_OUT_OF_RANGE ] = true, 					-- Out of range
	[ SPELL_FAILED_PACIFIED ] = true, 						-- Can't use that ability while pacified
	[ SPELL_FAILED_SPELL_IN_PROGRESS ] = true, 				-- Another action is in progress
	[ SPELL_FAILED_STUNNED ] = true, 						-- Can't do that while stunned
	[ SPELL_FAILED_UNIT_NOT_INFRONT ] = true, 				-- Target needs to be in front of you.
	[ SPELL_FAILED_UNIT_NOT_BEHIND ] = true, 				-- Target needs to be behind you.
}

ErrorsFrame.InitializeErrorsFrame = function(self)

	self.frame = UIErrorsFrame

	UIErrorsFrame:UnregisterAllEvents()
	UIErrorsFrame:SetFrameStrata("LOW")
	UIErrorsFrame:SetHeight(22)
	UIErrorsFrame:SetAlpha(.75)
	UIErrorsFrame:SetFontObject(GetFont(18, true))
	UIErrorsFrame:SetShadowColor(0, 0, 0, .5)

	self:RegisterEvent("SYSMSG", "OnEvent")
	self:RegisterEvent("UI_ERROR_MESSAGE", "OnEvent")
	self:RegisterEvent("UI_INFO_MESSAGE", "OnEvent")

	-- Macros can toggle this, so we need to hook into it.
	self:SecureHook(UIErrorsFrame, "RegisterEvent", "OnRegisterEvent")
	self:SecureHook(UIErrorsFrame, "UnregisterEvent", "OnUnregisterEvent")

end

ErrorsFrame.InitializeMovableFrameAnchor = function(self)

	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(SYSTEM_MESSAGES)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(760, 22)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "CENTER"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor

end

ErrorsFrame.UpdatePositionAndScale = function(self)

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

ErrorsFrame.OnAnchorUpdate = function(self, reason, layoutName, ...)
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

ErrorsFrame.OnRegisterEvent = function(self, event, ...)
	UIErrorsFrame:UnregisterEvent(event)
	self:RegisterEvent(event, "OnEvent", ...)
end

ErrorsFrame.OnUnregisterEvent = function(self, event)
	self:UnregisterEvent(event, "OnEvent")
end

ErrorsFrame.OnEvent = function(self, event, ...)
	if event == "SYSMSG" then
		local msg, r, g, b = ...
		if (not msg or blackList[msg]) then return end
		UIErrorsFrame:CheckAddMessage(msg, r, g, b, 1)
	elseif (event == "UI_ERROR_MESSAGE") then
		local messageType, msg = ...
		if (not msg or blackList.msgTypes[messageType] or blackList[msg]) then return end
		if (UIErrorsFrame.TryDisplayMessage) then
			UIErrorsFrame:TryDisplayMessage(messageType, msg, 1, 0, 0, 1)
		else
			UIErrorsFrame:AddMessage(msg, 1, 0, 0, 1)
		end
		-- Play an error sound if the appropriate cvars allows it.
		-- Blizzard plays these sound too, but they don't slave it to the error speech setting. We do.
		if (GetCVarBool("Sound_EnableDialog") and GetCVarBool("Sound_EnableErrorSpeech")) then
			local errorStringId, soundKitID, voiceID = GetGameMessageInfo(messageType)
			if (voiceID) then
				-- No idea what channel this ends up in.
				-- *Edit: Seems to be Dialog by default for this one.
				PlayVocalErrorSoundID(voiceID)
			elseif (soundKitID) then
				-- Blizzard sends this to the Master channel. We won't.
				PlaySoundKitID(soundKitID, "Dialog")
			end
		end

	elseif (event == "UI_INFO_MESSAGE") then
		local messageType, msg = ...
		if (not msg or blackList.msgTypes[messageType] or blackList[msg]) then return end
		if (UIErrorsFrame.TryDisplayMessage) then
			UIErrorsFrame:TryDisplayMessage(messageType, msg, 1, .82, 0, 1)
		else
			UIErrorsFrame:AddMessage(msg, 1, .82, 0, 1)
		end
	end
end

ErrorsFrame.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ErrorsFrame", defaults)
	--self.db:SetProfile("Default")

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	if (MFM) then
		MFM:RegisterPresets(self.db.profile.savedPosition)
	end

	self:InitializeErrorsFrame()
	self:InitializeMovableFrameAnchor()
end
