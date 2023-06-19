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

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local toRadians = function(d) return d*(math.pi/180) end

ns.RegisterConfig("PlayerClassPower", {
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
				Rotation = toRadians(5)
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
				Rotation = toRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 57, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 49, -76 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(4)
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
				Rotation = toRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 64, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 54, -79 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(4)
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
				Rotation = toRadians(1)
			}
		},
		Chi = { --[[ 5 ]]
			[1] = {
				Position = { "TOPLEFT", 82, -137 },
				Size = { 13, 13 }, BackdropSize = { 58, 58 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 62, -109 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(5)
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
				Rotation = toRadians(6)
			},
			[2] = {
				Position = { "TOPLEFT", 64, -111 },
				Size = { 13, 13 }, BackdropSize = { 60, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_plate"),
				Rotation = toRadians(5)
			},
			[3] = {
				Position = { "TOPLEFT", 50, -80 },
				Size = { 11, 15 }, BackdropSize = { 65, 60 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = toRadians(3)
			},
			[4] = {
				Position = { "TOPLEFT", 58, -44 },
				Size = { 12, 18 }, BackdropSize = { 78, 79 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = toRadians(3)
			},
			[5] = {
				Position = { "TOPLEFT", 82, -11 },
				Size = { 14, 21 }, BackdropSize = { 82, 96 },
				Texture = GetMedia("point_crystal"),  BackdropTexture = GetMedia("point_diamond"),
				Rotation = toRadians(1)
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
})
