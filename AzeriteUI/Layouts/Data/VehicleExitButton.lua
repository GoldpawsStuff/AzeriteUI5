--[[

	The MIT License (MIT)

	Copyright (c) 2024 Lars Norberg

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

-- Lua API
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi
local unpack = unpack

-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia

local r = 100

ns.RegisterConfig("VehicleExitButton", {
	VehicleExitButtonPosition = {  "CENTER", Minimap, "CENTER", -((45/180 * math_pi) * r), ((45/180 * math_pi) * r) },
	VehicleExitButtonSize = { 32, 32 },
	VehicleExitButtonTexturePosition = { "CENTER", 0, 0 },
	VehicleExitButtonTextureSize = { 80, 80 },
	VehicleExitButtonTexture = GetMedia("icon_exit_flight")
})
