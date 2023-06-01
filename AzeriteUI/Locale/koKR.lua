local Addon, ns = ...

local L = LibStub("AceLocale-3.0"):NewLocale(Addon, "koKR")
if (not L) then return end

-- General all-purpose words
--------------------------------------------------
L["Create"] = "만들기"
L["Copy"] = "복사"
L["Reset"] = "새로고침"
L["Delete"] = "삭제"
L["Save"] = "저장"
L["Apply"] = "적용"
L["Cancel"] = "취소"
L["Hide"] = "숨기기"
L["Enable"] = "활성"
L["Right"] = "오른쪽"
L["Left"] = "왼쪽"
L["Down"] = "아래쪽"
L["Up"] = "위로"

-- Movable Frames & EditMode interaction
--------------------------------------------------
L["Are you sure you want to delete the preset '%s'? This cannot be undone."] = true
L["Create New Profile"] = true
L["Create a new settings profile."] = true
L["Name of new profile:"] = true
L["The new profile needs a name."] = true
L["Profile already exists."] = true
L["Layout:"] = "구성:"
L["Name the New Layout"] = "신규 레이아웃의 이름을 정하세요"
L["HUD Edit Mode"] = "HUD 편집 모드"
L["Click the button below to reset the currently selected EditMode preset to positions matching the default AzeriteUI layout."] = true
L["Reset EditMode Layout"] = true
L["Click the button below to create an EditMode preset named 'Azerite'."] = true
L["Create EditMode Layout"] = true
L["<Left-Click and drag to move>"] = true
L["<MouseWheel to change scale>"] = true
L["<Ctrl and Right-Click to undo last change>"] = true
L["<Shift-Click to reset to default>"] = true
L["Position"] = true
L["Anchor Point"] = true
L["Top-Left Corner"] = true
L["Top Center"] = true
L["Top-Right Corner"] = true
L["Middle Right Side"] = true
L["Bottom-Right Corner"] = true
L["Bottom Center"] = true
L["Bottom-Left Corner"] = true
L["Middle Left Side"] = true
L["Center"] = true
L["Offset X"] = true
L["Sets the horizontal offset from your chosen anchor point. Positive values means right, negative values means left."] = true
L["Offset Y"] = true
L["Sets the vertical offset from your chosen anchor point. Positive values means up, negative values means down."] = true

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
L["Action Bar Settings"] = "행동 단축바 설정"
L["Action Bars"] = "행동 단축바"
L["Action Bar %d"] = "행동 단축바 %d"
L["Toggle whether to enable this action bar or not."] = true
L["Enable Bar Fading"] = true
L["Toggle whether to enable the buttons of this action bar to fade out."] = true
L["Only show on mouseover"] = true
L["Enable this to only show faded bars on mouseover, and not force them visible in combat."] = true
L["Start Fading from"] = true
L["Choose which button to start the fading from."] = true
L["Bar Layout"] = true
L["Choose the action bar layout type."] = true
L["Grid Layout"] = true
L["ZigZag Layout"] = true
L["First ZigZag Button"] = true
L["Sets which button the zigzag pattern should begin at."] = true
L["Number of buttons"] = true
L["Sets the number of action buttons on the action bar."] = true
L["Button Padding"] = true
L["Sets the padding between buttons on the same line."] = true
L["Line Padding"] = true
L["Sets the padding between multiple lines of buttons."] = true
L["Line Break"] = true
L["Sets when a new line of buttons should begin."] = true
L["Initial Growth"] = true
L["Choose whether the bar initially should expand horizontally or vertically."] = true
L["Horizontal Layout"] = true
L["Vertical Layout"] = true
L["Horizontal Growth"] = true
L["Choose which horizontal direction the bar should expand in."] = true
L["Vertical Growth"] = true
L["Choose which vertical direction the bar should expand in."] = true
L["Sets the anchor point."] = true

-- Unit Frame Settings
L["Unit Frames"] = "개체창"
L["UnitFrame Settings"] = true
L["Enable Aura Sorting"] = true
L["Here you can change settings related to the aura buttons appearing at each unitframe."] = true
L["When enabled, unitframe auras will be sorted depending on time left and who cast the aura. When disabled, unitframe auras will appear in the order they were applied, like in the default user interface."] = true
L["Toggle whether to enable this unit frame or not."] = true
L["Cast Bar"] = "시전바"
L["Boss Frames"] = "우두머리 개체창"
L["Party Frames"] = "파티 개체창"
L["Raid Frames"] = "공격대창"
L["Arena Frames"] = "투기장 개체창"
L["Combo Points"] = "연계 점수"
L["Arcane Charges"] = "비전 충전물"
L["Chi"] = "기"
L["Stagger"] = "시간차"
L["Holy Power"] = "신성한 힘"
L["Soul Shards"] = "영혼의 조각"
L["Essence"] = "정수"
L["Runes"] = "룬"

-- Tooltip Settings
L["Tooltips"] = true
L["Tooltip Settings"] = true
L["Show itemID"] = true
L["Toggle whether to add itemID to item tooltips or not."] = true
L["Show spellID"] = true
L["Toggle whether to add spellIDs and auraIDs in tooltips containing actions, spells or auras."] = true

-- Player Aura Settings
L["Player Auras"] = true
L["Aura Settings"] = true
L["Here you can change settings related to the aura buttons appearing by default in the top right corner of the screen. None of these settings apply to the aura buttons found at the unitframes."] = true
L["Toggle whether to show the player aura buttons or not."] = true
L["Visibility"] = true
L["Choose when your auras will be visible."] = true
L["Enable Aura Fading"] = true
L["Toggle whether to enable the player aura buttons to fade out when not moused over."] = true
L["Enable Modifier Key"] = true
L["Require a modifier key to show the auras."] = true
L["Modifier Key"] = true
L["Choose which modifier key to hold  down to show the aura buttons."] = true
L["Sets the anchor point."] = true
L["Horizontal Growth"] = true
L["Choose which horizontal direction the aura buttons should expand in."] = true
L["Vertical Growth"] = true
L["Choose which vertical direction the aura buttons should expand in."] = true
L["Horizontal Padding"] = true
L["Sets the horizontal padding between your aura buttons."] = true
L["Vertical Padding"] = true
L["Sets the horizontal padding between your aura buttons."] = true
L["Buttons Per Row"] = true
L["Sets the maximum number of aura buttons per row."] = true
L["Sets the anchor point."] = true

-- Bag/Container Settings
L["Bag Settings"] = true
L["Bags"] = true
L["Sort Direction"] = true
L["Choose in which direction items in your bags are sorted."] = true
L["Left to Right"] = true
L["Right to Left"] = true
L["Insert Point"] = true
L["Choose from which side new items are inserted into your bags."] = true

-- Fading & Explorer Mode Settings
L["Frame Fading"] = true
L["Frame Fade Settings"] = true
