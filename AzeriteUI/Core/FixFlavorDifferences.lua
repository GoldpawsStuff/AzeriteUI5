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

local L = LibStub("AceLocale-3.0"):GetLocale(Addon)

local FlavorDifferences = ns:NewModule("FlavorDifferences", "AceConsole-3.0", "LibMoreEvents-1.0")

-- Lua API
local string_match = string_match
local string_lower = string_lower
local tonumber = tonumber

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont

FlavorDifferences.OnInitialize = function(self)

	-- Add back retail like stop watch commands.
	if (not SlashCmdList["STOPWATCH"]) then

		local commands = {
			SLASH_STOPWATCH_PARAM_PLAY1 = "play",
			SLASH_STOPWATCH_PARAM_PLAY2 = "play",
			SLASH_STOPWATCH_PARAM_PAUSE1 = "pause",
			SLASH_STOPWATCH_PARAM_PAUSE2 = "pause",
			SLASH_STOPWATCH_PARAM_STOP1 = "stop",
			SLASH_STOPWATCH_PARAM_STOP2 = "clear",
			SLASH_STOPWATCH_PARAM_STOP3 = "reset",
			SLASH_STOPWATCH_PARAM_STOP4 = "stop",
			SLASH_STOPWATCH_PARAM_STOP5 = "clear",
			SLASH_STOPWATCH_PARAM_STOP6 = "reset"
		}

		-- try to match a command
		local matchCommand = function(param, text)
			local i, compare
			i = 1
			repeat
				compare = commands[param..i]
				if (compare and string_lower(compare) == string_lower(text)) then
					return true
				end
				i = i + 1
			until (not compare)
			return false
		end

		local stopWatch = function(_,msg)
			if (not IsAddOnLoaded("Blizzard_TimeManager")) then
				UIParentLoadAddOn("Blizzard_TimeManager")
			end
			if (StopwatchFrame) then
				local text = string_match(msg, "%s*([^%s]+)%s*")
				if (text) then
					text = string_lower(text)

					-- in any of the following cases, the stopwatch will be shown
					StopwatchFrame:Show()

					if (matchCommand("SLASH_STOPWATCH_PARAM_PLAY", text)) then
						Stopwatch_Play()
						return
					end
					if (matchCommand("SLASH_STOPWATCH_PARAM_PAUSE", text)) then
						Stopwatch_Pause()
						return
					end
					if (matchCommand("SLASH_STOPWATCH_PARAM_STOP", text)) then
						Stopwatch_Clear()
						return
					end
					-- try to match a countdown
					-- kinda ghetto, but hey, it's simple and it works =)
					local hour, minute, second = string_match(msg, "(%d+):(%d+):(%d+)")
					if (not hour) then
						minute, second = string_match(msg, "(%d+):(%d+)")
						if (not minute) then
							second = string_match(msg, "(%d+)")
						end
					end
					Stopwatch_StartCountdown(tonumber(hour), tonumber(minute), tonumber(second))
				else
					Stopwatch_Toggle()
				end
			end
		end
		self:RegisterChatCommand("stopwatch", stopWatch)
	end

	-- Add back retail like calendar command.
	if (not SlashCmdList["CALENDAR"]) then
		self:RegisterChatCommand("calendar", function()
			if (ToggleCalendar) then
				ToggleCalendar()
			end
		end)
	end

	-- Workaround for the completely random bg popup taints in Classic 1.13.x.
	-- This hides the tainted and only randomly working bg popups,
	-- and instead will show a red warning message on the top of the screen,
	-- directing the player to either join the bg or leave the queue
	-- using the bg finder eye located at the border of the minimap.
	if (ns.IsClassic or ns.IsTBC) then

		local battleground = CreateFrame("Frame", nil, UIParent)
		battleground:SetSize(574, 40)
		battleground:SetPoint("TOP", 0, -29)
		battleground:Hide()
		battleground.Text = battleground:CreateFontString(nil, "OVERLAY")
		battleground.Text:SetFontObject(GetFont(18,true))
		battleground.Text:SetText(L["You can now enter a new battleground, right-click the eye icon on the minimap to enter or leave!"])
		battleground.Text:SetPoint("TOP")
		battleground.Text:SetJustifyH("CENTER")
		battleground.Text:SetWidth(battleground:GetWidth())
		battleground.Text:SetTextColor(1, 0, 0)

		local animation = battleground:CreateAnimationGroup()
		animation:SetLooping("BOUNCE")

		local fadeOut = animation:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(.3)
		fadeOut:SetDuration(.5)
		fadeOut:SetSmoothing("IN_OUT")

		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", function()
			for i = 1, MAX_BATTLEFIELD_QUEUES do
				local status, map, instanceID = GetBattlefieldStatus(i)

				if (status == "confirm") then
					StaticPopup_Hide("CONFIRM_BATTLEFIELD_ENTRY")

					battleground:Show()
					animation:Play()

					return
				end
			end
			battleground:Hide()
			animation:Stop()
		end)
	end

end
