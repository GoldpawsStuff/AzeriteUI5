local Addon, ns = ...

local L = LibStub("AceLocale-3.0"):NewLocale(Addon, "zhTW")
if (not L) then return end

-- General all-purpose words
--------------------------------------------------
L["Create"] = "建立"
L["Copy"] = "複製"
L["Delete"] = "刪除"
L["Save"] = "儲存"
L["Apply"] = "套用"
L["Cancel"] = "取消"
L["Hide"] = "隱藏"
L["Enable"] = "開啟"

-- Movable Frames & EditMode interaction
--------------------------------------------------
L["Layout:"] = "版面設定："
L["Name the New Layout"] = "為新版面設定命名"
L["HUD Edit Mode"] = "介面配置編輯模式"
L["Click the button below to reset the currently selected EditMode preset to positions matching the default AzeriteUI layout."] = true
L["Reset EditMode Layout"] = true
L["Click the button below to create an EditMode preset named 'Azerite'."] = true
L["Create EditMode Layout"] = true
L["<Left-Click and drag to move>"] = true
L["<MouseWheel to change scale>"] = true
L["<Ctrl and Right-Click to undo last change>"] = true
L["<Shift-Click to reset to default>"] = true

-- Intro Tutorials
--------------------------------------------------
L["Welcome to %s"] = true
L["Congratulations, you are now running AzeriteUI for Retail!|n|nTo create or reset an editmode layout named 'Azerite' and switch to it, click the '|cffffd200%s|r' button. To hide this window for now, click the '|cffffd200%s|r' button. To cancel this tutorial, click the '|cffffd200%s|r' button."] = true
L["You are now running AzeriteUI for %s!|n|nTo set the game's general interface scale to AzeriteUI defaults and position the chat frames to match, click the '|cffffd200%s|r' button. To hide this window for now, click the '|cffffd200%s|r' button. To cancel this tutorial and handle interface scaling yourself, click the '|cffffd200%s|r' button."] = true

-- Misc
--------------------------------------------------
-- Classic Era Battleground Ready message
L["You can now enter a new battleground, right-click the eye icon on the minimap to enter or leave!"] = true

-- Options Menu
--------------------------------------------------
-- Action Bar Settings
L["Action Bar Settings"] = "快捷列設定"
L["Action Bars"] = "快捷列"
L["Action Bar %d"] = "快捷列%d"
L["Toggle whether to enable this action bar or not."] = true
L["Number of buttons"] = true
L["Sets the number of action buttons on the action bar."] = true

-- Unit Frame Settings
L["Unit Frames"] = true
L["UnitFrame Settings"] = true

-- Player Aura Settings
L["Player Auras"] = true
L["Aura Settings"] = true

-- Fading & Explorer Mode Settings
L["Frame Fading"] = true
L["Frame Fade Settings"] = true