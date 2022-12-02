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
local API = ns.API or {}
ns.API = API

-- WoW API
local CreateFont = CreateFont

-- Lua API
local pairs = pairs
local rawset = rawset
local setmetatable = setmetatable
local string_format = string.format
local type = type

-- Full cache that spawns new objects on-the-fly.
local count, font_mt = 0
font_mt = {
	__index = function(t,k)
		-- Create a new category and subtable
		if (type(k) == "string") then
			local new = setmetatable({}, font_mt)
			rawset(t,k,new)
			return new
		-- Create a new font object
		elseif (type(k) == "number") then
			count = count + 1
			local new = CreateFont(string_format(ns.Prefix.."Font%d", count))
			new:SetJustifyH("LEFT") -- new fonts appear to be centered after 9.1.5
			rawset(t,k,new)
			return new
		end
	end
}
local Fonts = setmetatable({}, font_mt)

-- Caches used for iterations
local AllFonts, ChatFonts, NumberFonts, NormalFonts = {}, {}, {}, {}

-- Return a font object, re-use existing ones that match.
local GetFont = function(size, outline, type)
	local inherit = type == "Chat" and _G.ChatFontNormal or type == "Number" and _G.NumberFont_Normal_Med or _G.Game16Font
	local fontObject = Fonts[type or "Normal"][outline and "Outline" or "None"][size]
	if (fontObject:GetFontObject() ~= inherit) then
		fontObject:SetFontObject(inherit)
		fontObject:SetFont(fontObject:GetFont(), size, outline and "OUTLINE" or "")
		fontObject:SetShadowColor(0,0,0,0)
		fontObject:SetShadowOffset(0,0)
	end
	local exists = AllFonts[fontObject]
	if (not exists) then
		AllFonts[fontObject] = true
		ChatFonts[fontObject] = type == "Chat"
		NumberFonts[fontObject] = type == "Number"
		NormalFonts[fontObject] = type ~= "Chat" and type ~= "Number"
		if (ns.callbacks) then
			ns.callbacks:Fire("FontObject_Created", fontObject, type or "Normal")
		end
	end
	return fontObject
end

-- Iterators for our font caches. Provided for restyling purposes.
local GetAllFonts = function() return pairs(AllFonts) end
local GetAllChatFonts = function() return pairs(ChatFonts) end
local GetAllNumberFonts = function() return pairs(NumberFonts) end
local GetAllNormalFonts = function() return pairs(NormalFonts) end

-- Change the font face of a font object.
-- *Only accepts our own font objects.
local SetFontObject = function(fontObject, font)
	if (not fontObject) or (not AllFonts[fontObject]) then
		return
	end
	local _,size,style = fontObject:GetFont()
	fontObject:SetFont(fontObject:GetFont(), size, style)
end

-- Add some aliases for blizzard artwork.
local alias = {
	["plain"] = [[Interface\ChatFrame\ChatFrameBackground]]
}

-- Retrieve an asset from the media asset folder.
local GetMedia = function(name, type) 
	return alias[name] or string_format([[Interface\AddOns\%s\Assets\%s.%s]], Addon, name, type or "tga") 
end

-- Global API
---------------------------------------------------------
API.GetFont = GetFont
API.GetAllFonts = GetAllFonts
API.GetAllChatFonts = GetAllChatFonts
API.GetAllNumberFonts = GetAllNumberFonts
API.GetAllNormalFonts = GetAllNormalFonts
API.SetFontObject = SetFontObject
API.GetMedia = GetMedia
