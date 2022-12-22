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

local ActionBarMod = ns:NewModule("ActionBars", "LibMoreEvents-1.0", "AceConsole-3.0")

-- Return blizzard barID by barnum.
local BAR_TO_ID = {
	[1] = 1,
	[2] = BOTTOMLEFT_ACTIONBAR_PAGE,
	[3] = BOTTOMRIGHT_ACTIONBAR_PAGE,
	[4] = RIGHT_ACTIONBAR_PAGE,
	[5] = LEFT_ACTIONBAR_PAGE,
	[6] = MULTIBAR_5_ACTIONBAR_PAGE,
	[7] = MULTIBAR_6_ACTIONBAR_PAGE,
	[8] = MULTIBAR_7_ACTIONBAR_PAGE
}

local defaults = { profile = ns:Merge({
	enabled = true,
	bars = {
		["**"] = ns:Merge({
		}, ns.ActionBar.defaults),
		[1] = { --[[ primary action bar ]]
			layout = "map",
			maptype = "azerite",
			visibility = {
				dragon = true,
				possess = true,
				overridebar = true,
				vehicleui = true
			},
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "BOTTOMLEFT",
					[2] = 60,
					[3] = 42
				}
			}
		},
		[2] = { --[[ bottomleft multibar ]]
			enabled = false,
			layout = "map",
			maptype = "zigzag",
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "BOTTOMLEFT",
					[2] = 780,
					[3] = 42
				}
			}
		},
		[3] = { --[[ bottomright multibar ]]
			enabled = false,
			grid = {
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			},
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "RIGHT",
					[2] = 0,
					[3] = -40
				}
			}
		},
		[4] = { --[[ right multibar 1 ]]
			enabled = false,
			grid = {
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			},
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "RIGHT",
					[2] = 0,
					[3] = -(40 + 72)
				}
			}
		},
		[5] = { --[[ right multibar 2 ]]
			enabled = false,
			grid = {
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			},
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "RIGHT",
					[2] = 0,
					[3] = -(40 + 72*2)
				}
			}
		},
		[6] = { --[[]]
			enabled = false,
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "CENTER",
					[2] = 0,
					[3] = 72
				}
			}
		},
		[7] = { --[[]]
			enabled = false,
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "CENTER",
					[2] = 0,
					[3] = 0
				}
			}
		},
		[8] = { --[[]]
			enabled = false,
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "CENTER",
					[2] = 0,
					[3] = -72
				}
			}
		}
	}
}, ns.moduleDefaults) }


local ActionBar_OnSizeChanged = function(self)
	self.anchor:SetSize(self.GetSize())
end

local ActionBar_UpdatePositionAndScale = function(self)
	if (InCombatLockdown()) then
		self.positionNeedsFix = true
		return
	end
	if (not self.frame) then return end

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

local ActionBar_OnAnchorUpdate = function(self, reason, layoutName, ...)
	local savedPositions = self.config.savedPosition
	local defaultPositions = self.defaults.savedPosition
	local lockdown = InCombatLockdown()

	if (reason == "LayoutsUpdated") then

		if (savedPositions[layoutName]) then

			self.anchor:SetScale(savedPositions[layoutName].scale or self.anchor:GetScale())
			self.anchor:ClearAllPoints()
			self.anchor:SetPoint(unpack(savedPositions[layoutName]))

			local defaultPosition = defaultPositions[layoutName] or defaultPositions.Azerite
			if (defaultPosition) then
				self.anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			self.initialPositionSet = true
				--self.currentLayout = layoutName

		else
			-- The user is unlikely to have a preset with our name
			-- on the first time logging in.
			if (not self.initialPositionSet) then

				local defaultPosition = defaultPositions.Azerite

				self.anchor:SetScale(defaultPosition.scale)
				self.anchor:ClearAllPoints()
				self.anchor:SetPoint(unpack(defaultPosition))
				self.anchor:SetDefaultPosition(unpack(ddefaultPosition))

				self.initialPositionSet = true
				--self.currentLayout = layoutName
			end

			savedPositions[layoutName] = { self.anchor:GetPosition() }
			savedPositions[layoutName].scale = self.anchor:GetScale()
		end

		self.currentLayout = layoutName

		-- Purge layouts not matching editmode themes or our defaults.
		for name in pairs(savedPositions) do
			if (not defaultPositions[name] and name ~= "Modern" and name ~= "Classic") then
				local found
				for lname in pairs(C_EditMode.GetLayouts().layouts) do
					if (lname == name) then
						found = true
						break
					end
				end
				if (not found) then
					savedPositions[name] = nil
				end
			end
		end

		self:UpdatePositionAndScale()

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPositions[layoutName] = { point, x, y }
		savedPositions[layoutName].scale = self.anchor:GetScale()

		self:UpdatePositionAndScale()

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPositions[layoutName].scale = scale

		self:UpdatePositionAndScale()

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		if (not self.incombat) then
			self:OnAnchorUpdate("PositionUpdated", layoutName, ...)
		end

	elseif (reason == "CombatStart") then
		-- Fires right before combat lockdown for visible anchors.


	elseif (reason == "CombatEnd") then
		-- Fires when combat lockdown ends for visible anchors.

	end
end



-- Returns a localized named usable for our movable frame anchor.
ActionBarMod.GetBarDisplayName = function(self, id)
	local barID = tonumber(id)
	if (barID == RIGHT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR3_TEXT -- "Right Action Bar 1"
	elseif (barID == LEFT_ACTIONBAR_PAGE) then
		return SHOW_MULTIBAR4_TEXT -- "Right Action Bar 2"
	else
		return HUD_EDIT_MODE_ACTION_BAR_LABEL:format(barID) -- "Action Bar %d"
	end
end

ActionBarMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ActionBars", defaults)

	self.bars = {}

	self:SetEnabledState(self.db.profile.enabled)

end

ActionBarMod.OnEnable = function(self)
	if (next(self.bars)) then
		for i,bar in ipairs(self.bars) do
			bar:SetEnabled(bar.config.enabled)
		end
		return
	end

	for i = 1,8 do

		local bar = ns.ActionBar:Create(BAR_TO_ID[i], self.db.profile.bars[i], ns.Prefix.."ActionBar"..i)
		bar.defaults = defaults.profile.bars[i]

		bar:SetScript("OnSizeChanged", ActionBar_OnSizeChanged)
		bar.OnAnchorUpdate = ActionBar_OnAnchorUpdate
		bar.UpdatePositionAndScale = ActionBar_UpdatePositionAndScale

		local anchor = ns.Widgets.RequestMovableFrameAnchor()
		anchor:SetTitle(self:GetBarDisplayName(bar.id))
		anchor:SetScalable(true)
		anchor:SetMinMaxScale(.75, 1.25, .05)
		anchor:SetSize(1,1) -- will be updated later
		anchor:SetPoint(unpack(defaults.profile.bars[i].savedPosition.Azerite))
		anchor:SetScale(defaults.profile.bars[i].savedPosition.Azerite.scale)
		anchor.frameOffsetX = 0
		anchor.frameOffsetY = 0
		anchor.framePoint = "BOTTOMLEFT"
		anchor.Callback = function(anchor,...) bar:OnAnchorUpdate(...) end

		bar.anchor = anchor

		self.bars[i] = bar
	end
end

ActionBarMod.OnDisable = function(self)
	if (not next(self.bars)) then return end

	for i,bar in ipairs(self.bars) do
		bar:Disable()
	end
end
