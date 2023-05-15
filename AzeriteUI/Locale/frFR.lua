local Addon, ns = ...

local L = LibStub("AceLocale-3.0"):NewLocale(Addon, "frFR")
if (not L) then return end

-- General all-purpose words
--------------------------------------------------
L["Create"] = "Créer"
L["Copy"] = "Copier"
L["Delete"] = "Effacer"
L["Save"] = "Sauver"
L["Apply"] = "Appliquer"
L["Cancel"] = "Annuler"
L["Hide"] = "Cacher"
L["Enable"] = "Activer"

-- Movable Frames & EditMode interaction
--------------------------------------------------
L["Layout:"] = "Disposition :"
L["Name the New Layout"] = "Nom de la nouvelle disposition"
L["HUD Edit Mode"] = "Mode édition ATH"
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
L["Action Bar Settings"] = "Paramètre de la barre d’actions"
L["Action Bars"] = "Barres d’action"
L["Action Bar %d"] = "Barre d’actions %d"
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
