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

local ID_TO_BAR = {}
for i,j in pairs(BAR_TO_ID) do ID_TO_BAR[j] = i end

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
				breakpoint = 6,
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			},
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "RIGHT",
					[2] = -40,
					[3] = 0
				}
			}
		},
		[4] = { --[[ right multibar 1 ]]
			enabled = false,
			grid = {
				breakpoint = 6,
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			},
			savedPosition = {
				breakpoint = 6,
				Azerite = {
					scale = 1,
					[1] = "RIGHT",
					[2] = -(40 + 10 + 72*2),
					[3] = 0
				}
			}
		},
		[5] = { --[[ right multibar 2 ]]
			enabled = false,
			grid = {
				breakpoint = 6,
				growth = "vertical",
				growthHorizontal = "RIGHT",
				growthVertical = "DOWN",
			},
			savedPosition = {
				Azerite = {
					scale = 1,
					[1] = "RIGHT",
					[2] = -(40 + 10 + 72*2 + 10 + 72*2),
					[3] = 0
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
					[3] = 72 + 10
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
					[3] = -(72 + 10)
				}
			}
		}
	}
}, ns.moduleDefaults) }

ActionBarMod.UpdatePositionAndScale = function(self, bar)
	if (InCombatLockdown()) then
		self.positionNeedsFix = true
		return
	end

	local savedPosition = bar.currentLayout and bar.config.savedPosition[bar.currentLayout]
	if (savedPosition) then
		local point, x, y = unpack(savedPosition)
		local scale = savedPosition.scale
		local anchor = bar.anchor

		-- Set the scale before positioning,
		-- or everything will be wonky.
		bar:SetScale(scale * ns.API.GetDefaultElementScale())

		if (anchor and anchor.framePoint) then
			-- Position the frame at the anchor,
			-- with the given point and offsets.
			bar:ClearAllPoints()
			bar:SetPoint(anchor.framePoint, anchor, anchor.framePoint, (anchor.frameOffsetX or 0)/scale, (anchor.frameOffsetY or 0)/scale)

			-- Parse where this actually is relative to UIParent
			local point, x, y = ns.API.GetPosition(bar)

			-- Reposition the frame relative to UIParent,
			-- to avoid it being hooked to our anchor in combat.
			bar:ClearAllPoints()
			bar:SetPoint(point, UIParent, point, x, y)
		end
	end

end

ActionBarMod.OnAnchorUpdate = function(self, bar, reason, layoutName, ...)
	local savedPositions = self.db.profile.bars[ID_TO_BAR[bar.id]].savedPosition
	local defaultPositions = self.db.defaults.profile.bars[ID_TO_BAR[bar.id]].savedPosition

	local anchor = bar.anchor

	if (reason == "LayoutsUpdated") then

		if (savedPositions[layoutName]) then

			anchor:SetScale(savedPositions[layoutName].scale or anchor:GetScale())
			anchor:ClearAllPoints()
			anchor:SetPoint(unpack(savedPositions[layoutName]))

			local defaultPosition = defaultPositions[layoutName] or defaultPositions.Azerite
			if (defaultPosition) then
				anchor:SetDefaultPosition(unpack(defaultPosition))
			end

			bar.initialPositionSet = true
				--self.currentLayout = layoutName

		else
			-- The user is unlikely to have a preset with our name
			-- on the first time logging in.
			if (not bar.initialPositionSet) then

				local defaultPosition = defaultPositions.Azerite

				anchor:SetScale(defaultPosition.scale)
				anchor:ClearAllPoints()
				anchor:SetPoint(unpack(defaultPosition))
				anchor:SetDefaultPosition(unpack(ddefaultPosition))

				bar.initialPositionSet = true
				--self.currentLayout = layoutName
			end

			savedPositions[layoutName] = { anchor:GetPosition() }
			savedPositions[layoutName].scale = anchor:GetScale()
		end

		bar.currentLayout = layoutName

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

		self:UpdatePositionAndScale(bar)

	elseif (reason == "PositionUpdated") then
		-- Fires when position has been changed.
		local point, x, y = ...

		savedPositions[layoutName] = { point, x, y }
		savedPositions[layoutName].scale = anchor:GetScale()

		self:UpdatePositionAndScale(bar)

	elseif (reason == "ScaleUpdated") then
		-- Fires when scale has been mousewheel updated.
		local scale = ...

		savedPositions[layoutName].scale = scale

		self:UpdatePositionAndScale(bar)

	elseif (reason == "Dragging") then
		-- Fires on every drag update. Spammy.
		if (not self.incombat) then
			self:OnAnchorUpdate(bar, "PositionUpdated", layoutName, ...)
		end
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

ActionBarMod.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self.incombat = nil
		if (self.positionNeedsFix) then
			self:UpdatePositionAndScale()
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.incombat = true
	end
end

ActionBarMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ActionBars", defaults)
	self.bars = {}

	self:SetEnabledState(self.db.profile.enabled)

	for i = 1,8 do

		local config = self.db.profile.bars[i]
		local bar = ns.ActionBar:Create(BAR_TO_ID[i], config, ns.Prefix.."ActionBar"..i)
		bar:SetPoint(unpack(defaults.profile.bars[i].savedPosition.Azerite))
		bar:SetSize(2,2)
		bar:UpdateButtons()
		bar:UpdateButtonLayout()

		local anchor = ns.Widgets.RequestMovableFrameAnchor()
		anchor:SetTitle(self:GetBarDisplayName(i))
		anchor:SetScalable(true)
		anchor:SetMinMaxScale(.75, 1.25, .05)
		anchor:SetSize(bar:GetSize()) -- will be updated later
		anchor:SetPoint(unpack(defaults.profile.bars[i].savedPosition.Azerite))
		anchor:SetScale(defaults.profile.bars[i].savedPosition.Azerite.scale)
		anchor.frameOffsetX = 0
		anchor.frameOffsetY = 0
		anchor.framePoint = "BOTTOMLEFT"
		anchor.Callback = function(_,...) self:OnAnchorUpdate(bar, ...) end

		-- do this on layout updates too
		if (config.grid and config.grid.growth == "vertical") then
			anchor.Text:SetRotation((-90 / 180) * math.pi)
			anchor.Title:SetRotation((-90 / 180) * math.pi)
		end

		bar.anchor = anchor

		self.bars[i] = bar
	end

end

ActionBarMod.OnEnable = function(self)
	for i,bar in next,self.bars do
		bar:SetEnabled(bar.config.enabled)
	end
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
end

ActionBarMod.OnDisable = function(self)
	for i,bar in next,self.bars do
		bar:Disable()
	end
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
end
