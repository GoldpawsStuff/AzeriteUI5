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

if (not ns.IsClassic) then return end

local Tracker = ns:NewModule("Tracker", ns.Module, "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua
local math_min = math.min
local string_match = string.match
local string_gsub = string.gsub
local tonumber = tonumber
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont

local defaults = { profile = ns:Merge({}, ns.Module.defaults) }

-- Generate module defaults on the fly
-- to recalculate default values relying on
-- changing factors like user interface scale.
Tracker.GenerateDefaults = function(self)
	defaults.profile.savedPosition = {
		scale = ns.API.GetEffectiveScale(),
		[1] = "BOTTOMRIGHT",
		[2] = -60 * ns.API.GetEffectiveScale(),
		[3] = 380 * ns.API.GetEffectiveScale()
	}
	return defaults
end

local config = {
	Width = 306,
	BottomOffset = 380,
	TopOffset = 260,
	TrackerWidth = 255,
	TrackerHeight = 1080 - 380 - 260,
	FontObject = GetFont(13, true),
	FontObjectTitle = GetFont(15, true)
}

Tracker.PrepareFrames = function(self)

	 local frame = CreateFrame("Frame", nil, UIParent)
	 frame:SetFrameStrata("LOW")
	 frame:SetSize(config.Width, config.TrackerHeight)
	 frame:SetPoint(unpack(defaults.profile.savedPosition))

	 self.frame = frame

	-- Re-position after UIParent messes with it.
	hooksecurefunc(QuestWatchFrame, "SetPoint", function(_,_, anchor)
		if (anchor ~= frame) then
			self:UpdateTrackerPosition()
		end
	end)

	-- Just in case some random addon messes with it.
	hooksecurefunc(QuestWatchFrame, "SetAllPoints", function()
		self:UpdateTrackerPosition()
	end)

	local dummyLine = QuestWatchFrame:CreateFontString()
	dummyLine:SetFontObject(config.FontObject)
	dummyLine:SetWidth(config.TrackerWidth)
	dummyLine:SetJustifyH("RIGHT")
	dummyLine:SetJustifyV("BOTTOM")
	dummyLine:SetIndentedWordWrap(false)
	dummyLine:SetWordWrap(true)
	dummyLine:SetNonSpaceWrap(false)
	dummyLine:SetSpacing(0)

	local title = QuestWatchQuestName
	title:ClearAllPoints()
	title:SetPoint("TOPRIGHT", QuestWatchFrame, "TOPRIGHT", 0, 0)

	-- Hook line styling
	hooksecurefunc("QuestWatch_Update", function()
		local questIndex
		local numObjectives
		local watchText
		local watchTextIndex = 1
		local objectivesCompleted
		local text, type, finished

		for i = 1, GetNumQuestWatches() do
			questIndex = GetQuestIndexForWatch(i)
			if (questIndex) then
				numObjectives = GetNumQuestLeaderBoards(questIndex)
				if (numObjectives > 0) then
					-- Set quest title
					watchText = _G["QuestWatchLine"..watchTextIndex]
					watchText.isTitle = true

					-- Kill trailing nonsense
					text = watchText:GetText() or ""
					text = string_gsub(text, "%.$", "")
					text = string_gsub(text, "%?$", "")
					text = string_gsub(text, "%!$", "")
					watchText:SetText(text)

					-- Align the quest title better
					if (watchTextIndex == 1) then
						watchText:ClearAllPoints()
						watchText:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, -4)
					else
						watchText:ClearAllPoints()
						watchText:SetPoint("TOPRIGHT", _G["QuestWatchLine"..(watchTextIndex - 1)], "BOTTOMRIGHT", 0, -10)
					end
					watchTextIndex = watchTextIndex + 1

					-- Style the objectives
					objectivesCompleted = 0
					for j = 1, numObjectives do

						-- Set Objective text
						text, type, finished = GetQuestLogLeaderBoard(j, questIndex)
						watchText = _G["QuestWatchLine"..watchTextIndex]
						watchText.isTitle = nil

						-- Kill trailing nonsense
						text = string_gsub(text, "%.$", "")
						text = string_gsub(text, "%?$", "")
						text = string_gsub(text, "%!$", "")

						local objectiveText, minCount, maxCount = string_match(text, "(.+): (%d+)/(%d+)")
						if (objectiveText and minCount and maxCount) then
							minCount = tonumber(minCount)
							maxCount = tonumber(maxCount)
							if (minCount and maxCount) then
								if (minCount == maxCount) then
									text = Colors.quest.green.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								elseif (maxCount > 0) and (minCount/maxCount >= 2/3 ) then
									text = Colors.quest.yellow.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								elseif (maxCount > 0) and (minCount/maxCount >= 1/3 ) then
									text = Colors.quest.orange.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								else
									text = Colors.quest.red.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								end
							end
						end
						watchText:SetText(text)

						-- Color the objectives
						if (finished) then
							watchText:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3])
							objectivesCompleted = objectivesCompleted + 1
						else
							watchText:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
						end

						watchText:ClearAllPoints()
						watchText:SetPoint("TOPRIGHT", "QuestWatchLine"..(watchTextIndex - 1), "BOTTOMRIGHT", 0, -4)

						--watchText:Show()

						watchTextIndex = watchTextIndex + 1
					end

					-- Brighten the quest title if all the quest objectives were met
					watchText = _G["QuestWatchLine"..(watchTextIndex - numObjectives - 1)]
					if ( objectivesCompleted == numObjectives ) then
						watchText:SetTextColor(Colors.title[1], Colors.title[2], Colors.title[3])
					else
						watchText:SetTextColor(Colors.title[1]*.75, Colors.title[2]*.75, Colors.title[3]*.75)
					end

				end
			end
		end

		local top, bottom

		local lineID = 1
		local line = _G["QuestWatchLine"..lineID]
		top = line:GetTop()

		while line do
			if (line:IsShown()) then
				line:SetShadowOffset(0,0)
				line:SetShadowColor(0,0,0,0)
				line:SetFontObject(line.isTitle and config.FontObjectTitle or config.FontObject)
				local _,size = line:GetFont()
				local spacing = size*.2 - size*.2%1

				line:SetJustifyH("RIGHT")
				line:SetJustifyV("BOTTOM")
				line:SetIndentedWordWrap(false)
				line:SetWordWrap(true)
				line:SetNonSpaceWrap(false)
				line:SetSpacing(spacing)

				dummyLine:SetFontObject(line:GetFontObject())
				dummyLine:SetText(line:GetText() or "")
				dummyLine:SetSpacing(spacing)

				line:SetWidth(config.TrackerWidth)
				line:SetHeight(dummyLine:GetHeight())

				bottom = line:GetBottom()
			end

			lineID = lineID + 1
			line = _G["QuestWatchLine"..lineID]
		end

		-- Avoid a nil bug that sometimes can happen with no objectives tracked,
		-- in weird circumstances I have been unable to reproduce.
		if (top and bottom) then
			QuestWatchFrame:SetHeight(top - bottom)
		end

	end)

end

Tracker.UpdateTrackerPosition = function(self)
	if (not self.frame) then return end

	QuestWatchFrame:SetParent(self.frame)
	QuestWatchFrame:SetWidth(config.TrackerWidth)
	QuestWatchFrame:SetClampedToScreen(false)
	QuestWatchFrame:SetAlpha(.9)
	QuestWatchFrame:ClearAllPoints()
	QuestWatchFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
end

Tracker.PostAnchorEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED") then
		self:UpdateTrackerPosition()
		QuestWatchFrame:SetAlpha(.9)

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self:UpdateTrackerPosition()
	end
end

Tracker.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			if (ImmersionFrame) then
				if (not self:IsHooked(ImmersionFrame, "OnShow")) then
					self:SecureHookScript(ImmersionFrame, "OnShow", function() WatchFrame:SetAlpha(0) end)
				end
				if (not self:IsHooked(ImmersionFrame, "OnHide")) then
					self:SecureHookScript(ImmersionFrame, "OnHide", function() WatchFrame:SetAlpha(.9) end)
				end
			end
		end
	end
end

Tracker.OnEnable = function(self)
	self:PrepareFrames()
	self:CreateAnchor(TRACKER_HEADER_OBJECTIVE, true)

	ns.Module.OnEnable(self)
end
