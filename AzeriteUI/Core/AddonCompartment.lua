--[[

    The MIT License (MIT)

    Copyright (c) 2024 Patrick Heyer

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

-- GLOBALS: Azerite_OnAddonCompartmentEnter, Azerite_OnAddonCompartmentLeave, Azerite_OnAddonCompartmentClick
-- GLOBALS: GameTooltip

local Addon, ns = ...

if (not ns.IsRetail) then return end

local AddonCompartment = ns:NewModule("AddonCompartment")

local GetAddOnMetadata = _G.GetAddOnMetadata
local title = GetAddOnMetadata(Addon, "Title");
local icon = GetAddOnMetadata(Addon, "IconTexture");

AddonCompartment.AddonCompartmentEnter = function(self, _, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPRIGHT", menuButtonFrame, "BOTTOMRIGHT", 0, 0)

    GameTooltip:ClearLines()
    GameTooltip:AddDoubleLine(title, ns.Version)
    GameTooltip_AddBlankLineToTooltip(GameTooltip)
    GameTooltip:AddLine("Left click to open Azerite UI configuration")
    GameTooltip:AddLine("Right click to open frame manager")

    GameTooltip:Show()
end

AddonCompartment.AddonCompartmentLeave = function(self)
    GameTooltip:Hide()
end

AddonCompartment.AddonCompartmentClick = function(self, _, button)
    if (button == "LeftButton") then
        if (self.options) then
            self.options:OpenOptionsMenu()
        end
    elseif (button == "RightButton") then
        if (self.framesManager) then
            self.framesManager:ToggleMFMFrame()
        end
    end
end

AddonCompartment.OnEnable = function(self)
    self.options = ns:GetModule("Options") or {}
    self.framesManager = ns:GetModule("MovableFramesManager") or {}
end

_G[ns.Prefix .. "_OnAddonCompartmentEnter"] = function(...) AddonCompartment:AddonCompartmentEnter(...) end
_G[ns.Prefix .. "_OnAddonCompartmentLeave"] = function(...) AddonCompartment:AddonCompartmentLeave(...) end
_G[ns.Prefix .. "_OnAddonCompartmentClick"] = function(...) AddonCompartment:AddonCompartmentClick(...) end
