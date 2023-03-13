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
local oUF = ns.oUF

local ClassPowerMod = ns:Merge(ns:NewModule("PlayerClassPowerFrame", "LibMoreEvents-1.0"), ns.UnitFrame.modulePrototype)
local MFM = ns:GetModule("MovableFramesManager", true)

-- Lua API
local next = next
local string_gsub = string.gsub
local type = type
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local noop = ns.Noop

-- Constants
local playerClass = ns.PlayerClass
local playerLevel = UnitLevel("player")
local playerXPDisabled = IsXPUserDisabled()

local defaults = { profile = ns:Merge({
	enabled = true,
	savedPosition = {
		Azerite = {
			scale = 1,
			[1] = "CENTER",
			[2] = -(285 - 124/2),
			[3] = -(168 - 168/2)
		}
	}
}, ns.UnitFrame.defaults) }

-- Proper conversion constant.
local deg2rad = math.pi / 180
local degreesToRadians = function(degrees)
	return degrees*deg2rad
end

local config = {

	ClassPowerFrameSize = { 124, 168 },

	-- Class Power
	-- *also include layout data for Stagger and Runes,
	--  which are separate elements from ClassPower.
	ClassPowerPointOrientation = "UP",
	ClassPowerSparkTexture = GetMedia("blank"),
	ClassPowerCaseColor = { 211/255, 200/255, 169/255 },
	ClassPowerSlotColor = { 130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3 },
	ClassPowerSlotOffset = 1.5,

	-- Note that the following are just layout names.
	-- They may not always be used for what their name implies.
	-- The important part is number of points and layout. Not powerType.
	ClassPowerLayouts = {
		Stagger = { --[[ 3 ]]
			[1] = {
				Position = { "TOPLEFT", 62, -109 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[2] = {
				Position = { "TOPLEFT", 41, -58 },
				Size = { 39, 40 }, BackdropSize = { 80, 80 },
				Texture = GetMedia("point_hearth"), BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[3] = {
				Position = { "TOPLEFT", 64, -36 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			}
		},
		ArcaneCharges = { --[[ 4 ]]
			[1] = {
				Position = { "TOPLEFT", 78, -139 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 57, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 49, -76 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(4)
			},
			[4] = {
				Position = { "TOPLEFT", 72, -33 },
				Size = { 51, 52 }, BackdropSize = { 104, 104 },
				Texture = GetMedia("point_hearth"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			}
		},
		ComboPoints = { --[[ 5 ]]
			[1] = {
				Position = { "TOPLEFT", 82, -137 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 64, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 54, -79 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(4)
			},
			[4] = {
				Position = { "TOPLEFT", 60, -44 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[5] = {
				Position = { "TOPLEFT", 82, -11 },
				Size = { 14, 21 }, BackdropSize = { 82, 96 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(1)
			}
		},
		Chi = { --[[ 5 ]]
			[1] = {
				Position = { "TOPLEFT", 82, -137 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 62, -109 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 51, -73 },
				Size = { 39, 40  }, BackdropSize = { 80, 80 },
				Texture = GetMedia("point_hearth"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[4] = {
				Position = { "TOPLEFT", 64, -36 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			},
			[5] = {
				Position = { "TOPLEFT", 82, -9 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = nil
			}
		},
		SoulShards = { --[[ 5 ]]
			[1] = {
				Position = { "TOPLEFT", 82, -137 },
				Size = { 12, 12 }, BackdropSize = { 54, 54 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 64, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = degreesToRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 50, -80 },
				Size = { 11, 15 }, BackdropSize = { 65, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(3)
			},
			[4] = {
				Position = { "TOPLEFT", 58, -44 },
				Size = { 12, 18 }, BackdropSize = { 78, 79 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(3)
			},
			[5] = {
				Position = { "TOPLEFT", 82, -11 },
				Size = { 14, 21 }, BackdropSize = { 82, 96 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = degreesToRadians(1)
			}
		},
		Runes = { --[[ 6 ]]
			[1] = {
				Position = { "TOPLEFT", 82, -131 },
				Size = { 28, 28 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_rune2"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[2] = {
				Position = { "TOPLEFT", 58, -107 },
				Size = { 28, 28 }, BackdropSize = { 68, 68 },
				Texture = GetMedia("point_rune4"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[3] = {
				Position = { "TOPLEFT", 32, -83 },
				Size = { 30, 30 }, BackdropSize = { 74, 74 },
				Texture = GetMedia("point_rune1"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[4] = {
				Position = { "TOPLEFT", 65, -64 },
				Size = { 28, 28 }, BackdropSize = { 68, 68 },
				Texture = GetMedia("point_rune3"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[5] = {
				Position = { "TOPLEFT", 39, -38 },
				Size = { 32, 32 }, BackdropSize = { 78, 78 },
				Texture = GetMedia("point_rune2"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			},
			[6] = {
				Position = { "TOPLEFT", 79, -10 },
				Size = { 40, 40 }, BackdropSize = { 98, 98 },
				Texture = GetMedia("point_rune1"),  BackdropTexture = GetMedia("point_dk_block"),
				Rotation = nil
			}
		}
	}

}

-- Element Callbacks
--------------------------------------------
-- Create a point used for classpowers, stagger and runes.
local ClassPower_CreatePoint = function(element, index)
	local db = config

	local point = element:GetParent():CreateBar(nil, element)
	point:SetOrientation(db.ClassPowerPointOrientation)
	point:SetSparkTexture(db.ClassPowerSparkTexture)
	point:SetMinMaxValues(0, 1)
	point:SetValue(1)

	local case = point:CreateTexture(nil, "BACKGROUND", nil, -2)
	case:SetPoint("CENTER")
	case:SetVertexColor(unpack(db.ClassPowerCaseColor))

	point.case = case

	local slot = point:CreateTexture(nil, "BACKGROUND", nil, -1)
	slot:SetPoint("TOPLEFT", -db.ClassPowerSlotOffset, db.ClassPowerSlotOffset)
	slot:SetPoint("BOTTOMRIGHT", db.ClassPowerSlotOffset, -db.ClassPowerSlotOffset)
	slot:SetVertexColor(unpack(db.ClassPowerSlotColor))

	point.slot = slot

	return point
end

local ClassPower_PostUpdateColor = function(element, r, g, b)
	--for i = 1, #element do
	--	local point = element[i]
	--	point:SetStatusBarColor(r, g, b) -- needed?
	--end
end

-- Update classpower layout and textures.
-- *also used for one-time setup of stagger and runes.
local ClassPower_PostUpdate = function(element, cur, max)
	if (not cur or not max) then
		return
	end

	local style
	if (max >= 6) then
		style = "Runes"
	elseif (max == 5) then
		style = playerClass == "MONK" and "Chi" or playerClass == "WARLOCK" and "SoulShards" or "ComboPoints"
	elseif (max == 4) then
		style = "ArcaneCharges"
	elseif (max == 3) then
		style = "Stagger"
	end

	if (not style) then
		return element:Hide()
	end

	if (not element:IsShown()) then
		element:Show()
	end

	for i = 1, #element do
		local point = element[i]
		if (point:IsShown()) then
			local value = point:GetValue()
			local pmin, pmax = point:GetMinMaxValues()
			if (element.inCombat) then
				point:SetAlpha((cur == max) and 1 or (value < pmax) and .5 or 1)
			else
				point:SetAlpha((cur == max) and 0 or (value < pmax) and .5 or 1)
			end
		end
	end

	if (style ~= element.style) then

		local layoutdb = config.ClassPowerLayouts[style]
		if (layoutdb) then

			local id = 0
			for i,info in next,layoutdb do
				local point = element[i]
				if (point) then
					local rotation = info.PointRotation or 0

					point:ClearAllPoints()
					point:SetPoint(unpack(info.Position))
					point:SetSize(unpack(info.Size))
					point:SetStatusBarTexture(info.Texture)
					point:GetStatusBarTexture():SetRotation(rotation)

					point.case:SetSize(unpack(info.BackdropSize))
					point.case:SetTexture(info.BackdropTexture)
					point.case:SetRotation(rotation)

					point.slot:SetTexture(info.Texture)
					point.slot:SetRotation(rotation)

					id = id + 1
				end
			end

			-- Should be handled by the element,
			-- no idea why I'm adding it here.
			for i = id + 1, #element do
				element[i]:Hide()
			end
		end

		element.style = style
	end

end

local Runes_PostUpdate = function(element, runemap, hasVehicle, allReady)
	for i = 1, #element do
		local rune = element[i]
		if (rune:IsShown()) then
			local value = rune:GetValue()
			local min, max = rune:GetMinMaxValues()
			if (element.inCombat) then
				rune:SetAlpha(allReady and 1 or (value < max) and .5 or 1)
			else
				rune:SetAlpha(allReady and 0 or (value < max) and .5 or 1)
			end
		end
	end
end

local Runes_PostUpdateColor = function(element, r, g, b, color, rune)
	if (rune) then
		rune:SetStatusBarColor(r, g, b)
	else
		if (not ns.IsWrath) then
			color = element.__owner.colors.power.RUNES
			r, g, b = color[1], color[2], color[3]
		end
		for i = 1, #element do
			local rune = element[i]
			if (ns.IsWrath) then
				color = element.__owner.colors.runes[rune.runeType]
				r, g, b = color[1], color[2], color[3]
			end
			rune:SetStatusBarColor(r, g, b)
		end
	end
end

local Stagger_SetStatusBarColor = function(element, r, g, b)
	--for i,point in next,element do
	for i = 1,3 do
		local point = element[i]
		point:SetStatusBarColor(r, g, b)
	end
end

local Stagger_PostUpdate = function(element, cur, max)

	element[1].min = 0
	element[1].max = max * .3
	element[2].min = element[1].max
	element[2].max = max * .6
	element[3].min = element[2].max
	element[3].max = max

	--for i,point in next,element do
	for i = 1,3 do
		local point = element[i]
		local value = (cur > point.max) and point.max or (cur < point.min) and point.min or cur

		point:SetMinMaxValues(point.min, point.max)
		point:SetValue(value)

		if (element.inCombat) then
			point:SetAlpha((cur == max) and 1 or (value < point.max) and .5 or 1)
		else
			point:SetAlpha((cur == 0) and 0 or (value < point.max) and .5 or 1)
		end
	end
end

-- Frame Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		local runes = self.Runes
		if (runes and not runes.inCombat) then
			runes.inCombat = true
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and not stagger.inCombat) then
			stagger.inCombat = true
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower and not classpower.inCombat) then
			classpower.inCombat = true
			classpower:ForceUpdate()
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		local runes = self.Runes
		if (runes and runes.inCombat) then
			runes.inCombat = false
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and stagger.inCombat) then
			stagger.inCombat = false
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower and classpower.inCombat) then
			classpower.inCombat = false
			classpower:ForceUpdate()
		end
	end
end

local UnitFrame_OnHide = function(self)
	self.inCombat = nil
end

local style = function(self, unit)

	local db = config

	self:SetSize(unpack(config.ClassPowerFrameSize))

	local SCP = IsAddOnEnabled("SimpleClassPower")
	if (not SCP) then

		-- Class Power
		--------------------------------------------
		-- 	Supported class powers:
		-- 	- All     - Combo Points
		-- 	- Mage    - Arcane Charges
		-- 	- Monk    - Chi Orbs
		-- 	- Paladin - Holy Power
		-- 	- Warlock - Soul Shards
		--------------------------------------------
		local classpower = CreateFrame("Frame", nil, self)
		classpower:SetAllPoints(self)

		local maxPoints = 10 -- for fuck's sake
		for i = 1,maxPoints do
			classpower[i] = ClassPower_CreatePoint(classpower)
		end

		--ClassPower_PostUpdate(classpower, 0, maxPoints)

		self.ClassPower = classpower
		self.ClassPower.PostUpdate = ClassPower_PostUpdate
		self.ClassPower.PostUpdateColor = ClassPower_PostUpdateColor

		-- Monk Stagger
		--------------------------------------------
		if (playerClass == "MONK") then

			local stagger = CreateFrame("Frame", nil, self)
			stagger:SetAllPoints(self)

			stagger.SetValue = noop
			stagger.SetMinMaxValues = noop
			stagger.SetStatusBarColor = Stagger_SetStatusBarColor

			for i = 1,3 do
				stagger[i] = ClassPower_CreatePoint(stagger)
			end

			ClassPower_PostUpdate(stagger, 0, 3)

			self.Stagger = stagger
			self.Stagger.PostUpdate = Stagger_PostUpdate
		end

	end

	-- Death Knight Runes
	--------------------------------------------
	if (playerClass == "DEATHKNIGHT") then

		local runes = CreateFrame("Frame", nil, self)
		runes:SetAllPoints(self)

		runes.sortOrder = "ASC"
		for i = 1,6 do
			runes[i] = ClassPower_CreatePoint(runes)
		end

		ClassPower_PostUpdate(runes, 6, 6)

		self.Runes = runes
		self.Runes.PostUpdate = Runes_PostUpdate
		self.Runes.PostUpdateColor = Runes_PostUpdateColor
	end

	-- Scripts & Events
	--------------------------------------------
	self.OnEvent = UnitFrame_OnEvent
	self.OnHide = UnitFrame_OnHide

	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnEvent, true)

end

ClassPowerMod.Spawn = function(self)

	-- UnitFrame
	---------------------------------------------------
	local unit, name = "player", "PlayerClassPower"

	oUF:RegisterStyle(ns.Prefix..name, style)
	oUF:SetActiveStyle(ns.Prefix..name)

	self.frame = ns.UnitFrame.Spawn(unit, ns.Prefix.."UnitFrame"..name)
	self.frame:EnableMouse(false)

	-- Movable Frame Anchor
	---------------------------------------------------
	local anchor = MFM:RequestAnchor()
	anchor:SetTitle(CLASS)
	anchor:SetScalable(true)
	anchor:SetMinMaxScale(.75, 1.25, .05)
	anchor:SetSize(124, 168)
	anchor:SetPoint(unpack(defaults.profile.savedPosition.Azerite))
	anchor:SetScale(defaults.profile.savedPosition.Azerite.scale)
	anchor.frameOffsetX = 0
	anchor.frameOffsetY = 0
	anchor.framePoint = "TOPLEFT"
	anchor.Callback = function(anchor, ...) self:OnAnchorUpdate(...) end

	self.anchor = anchor
end

ClassPowerMod.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("PlayerClassPowerFrame", defaults)

	self:SetEnabledState(self.db.profile.enabled)

	-- Register the available layout names
	-- with the movable frames manager.
	if (MFM) then
		MFM:RegisterPresets(self.db.profile.savedPosition)
	end
end
