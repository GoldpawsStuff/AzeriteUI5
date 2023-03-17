# AzeriteUI5 for Dragonflight Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [5.0.49-RC] 2023-03-17
### Changed
- Changed how nameplate auras are filtered in Retail.
- Changed how auras are colored in retail to better differentiate between manually cast debuffs, procs and auras from other players or items.

## [5.0.48-RC] 2023-03-13
### Fixed
- Fixed an issue with Monk Stagger post updates that would throw an endless amount of errors.
- The retail scroll to bottom button on the chat frames should no longer hover in mid air.
- Added the new 10.1 chat frame scrollbar to elements that are only visible on mouseover.

## [5.0.47-RC] 2023-03-11
### Fixed
- Fixed an issue where some addons would throw tooltip errors combined with our UI.

## [5.0.46-RC] 2023-03-09
### Fixed
- The personal resource display once again shows your class color for your health bar.
- The Wrath dungeon finder icon should now be placed on the Minimap where it belongs.
- Fixed the sorting order of player cast auras in Wrath and Classic.

## [5.0.45-RC] 2023-03-07
### Changed
- Increased number of visible auras on non-boss target frames to 16.

## [5.0.44-RC] 2023-03-04
### Added
- Added Elite, Rare and Boss indicators to hostile nameplates.

### Fixed
- Fixed an issue where Classic and Wrath chat bubbles sometimes would be shown before their font object had been set, which would cause an error.

## [5.0.43-RC] 2023-03-02
### Added
- Added support for Classic Era to AzeriteUI5.
- Added styling of group finder finder icons in Wrath and Retail.
- Added styling of PvP queue icons in Wrath and Classic.
- Added the `/calendar` chat command to Wrath Classic, since it was missing it and the flavor has a calendar.

### Changed
- Changed nameplate opacity-, scale- and range settings.
- Raised the frame level of the red error text, the yellow objective update text and yellow system message text, as this sometimes would appear behind several other frames like the combo points and the worldmap.
- Moved the delay text of the floating player castbar to the right of the castbar frame, to make it easier to read.
- Made the hitbox of the player frame larger. It should now include the crystal/orb area too, as well as some of the space above the healthbar where buffs live.

### Fixed
- Fixed an issue where the wrong textures would be displayed on the player and target unitframes directly after leveling up.
- Fixed an issue where some system error messages could cause a bug when error speech is enabled in the audio settings.
- Fixed a bug where certain Blizzard tutorials sometimes would be attempted killed twice.

## [5.0.42-RC] 2023-03-01
### Fixed
- The user interface should now also work for Paladins in Wrath Classic.
- Fixed a graphical glitch with the spark of the minimap ring bars.

## [5.0.41-RC] 2023-02-28
### Added
- Added name coloring of player characters to most unit tooltips that previously lacked this.
- Added spellID and itemID to most tooltips.

## [5.0.40-RC] 2023-02-28
### Fixed
- The Wrath Classic consolidated aura display available from the buff display visible when holding ctrl+shift while out of combat and with no target selected, *phew*, now extends the correct way and has a visible consolidation button.

## [5.0.39-RC] 2023-02-28
### Changed
- The full buff display now requires ctrl and shift to be held, in the addition to the previous limitations. They will no longer be visible when out of combat in groups, and it's not open for discussion.

## [5.0.38-RC] 2023-02-27
### Added
- Added a general player buff display to the top right corner of the screen. It will mostly be visible when in a group, not currently engaged in combat and with no current target selected. Can also be made visible outside of groups when holding both ctrl and shift at the same time, as long as you're not engaged in combat or currently have a target selected.

### Changed
- Changed sorting, filtering and coloring of most unit auras. Auras applied by the player should now be easier to see, easier to track and better sorted than before.
- The targeted nameplate will be clamped a bit closer to the edges of the screen now, and not forced so far towards the center as it previously was.

### Fixed
- Nameplates should once again have visible auras applied by the player. For the most part we're following the same visibility filters as blizzard, except for specifically showing auras labeled as boss auras and also some short duration beneficial buffs cast by the player, like most HoTs.

## [5.0.37-RC] 2023-02-27
### Fixed
- You should no longer be spammed with error messages anytime a buff or debuff changes while in combat.

## [5.0.36-RC] 2023-02-24
### Added
- Added support for Wrath Classic to AzeriteUI5.
- Added Wrath Classic totembar. (Untested)
- Added chat bubble styling in Wrath Classic.
- Added combat feedback texts to most unitframes.

### Changed
- Aura filtering on the player- and target unit frames will now show longer duration buffs when not currently engaged in combat.

### Fixed
- Fixed an issue that prevented aura filters from functioning at all in Retail.
- Changed how chat frames are handled, which should result in less tab text related bugs upon receiving whispers.
- Slightly changed how actionbar paging works when a bonusbar is active. May or may not affect Retail dragonriding.
- Fixed some issues with the opacity of empty actionbar slots when in vehicles, especially in Wrath.
- Fixed an issue where some micro menu buttons would react to both downpress and release and thus instantly hide the window you were trying to open.
- Fixed an issue where the minimap ring bars wouldn't instantly update when changing what reputation was tracked.
- When resetting an editable editmode layout to AzeriteUI defaults, changes should now stick through relogs, instead of just reloads as previously.

## [5.0.35-RC] 2023-02-21 (Dragonflight)
### Fixed
- Fixed an issue that would prevent the button to reset the current EditMode preset to AzeriteUI defaults from working.

## [5.0.34-RC] 2023-02-21 (Dragonflight)
### Added
- Actionbuttons now have spell activation glows.
- Actionbuttons now have differently colored spell activation glows when MaxDps is enabled.

### Changed
- Party frames will no longer be semi-transparent when the party member is out of range. Because it looked like shit.

### Fixed
- Fixed an issue with the color tables on protected casts on the target unit frame that would cause an error.

## [5.0.33-RC] 2023-02-15 (Dragonflight)
### Changed
- Party frames now uses the same aura filter as the nameplates, they previously used the same filter as the target frame.

### Fixed
- Nameplate health values should no longer overlap the nameplate castbars.

## [5.0.32-RC] 2023-02-14 (Dragonflight)
### Changed
- Nameplate castbars should now linger for half a second after interrupted or failed casts.
- Nameplate castbars are now colored yellow for interruptable casts and gray for protected casts, to better mimic the default blizzard coloring.
- The floating player castbar will now disable itself when the personal resource display is enabled.

### Fixed
- The personal resource display castbar should no longer block out the health bar.
- The personal resource display castbar text should no longer collide with the power bar.

## [5.0.31-RC] 2023-02-09 (Dragonflight)
### Changed
- Retribution paladins now have a crystal instead of an orb. No magic crystal ball for them. They're just too violent.

### Fixed
- Fixed a wrong upvalue in the nameplate castbar element resulting in a bug when a cast changed its protected status.
- Fixed an issue preventing the taxi exit / vehicle exit / dismount button functioning properly in 10.0.0 and higher.
- The power crystal shouldn't randomly disappear when entering various vehicle like situations anymore.
- Nameplate protected casts should now be much easier to identify.
- Nameplate scales should be back to their previous size matching AzeriteUI4 and AzeriteUI3 again. Sorry folks that loved the larger ones!

## [5.0.30-RC] 2023-02-07 (Dragonflight)
### Added
- Added castbars for nameplates. Does not apply to the personal resource display.
- Added a taxi exit / vehicle exit / dismount button to the minimap.

## [5.0.29-RC] 2023-02-06 (Dragonflight)
- Updated for WoW client patch 10.0.5.
- Introduced our new movable frame system.

### Added
- Added a separate profiling system for our own movable frames. Their anchors and preset window appear alongside the blizzard editmode window. Our movable frames presets are no longer locked to the current editmode preset. Instead we now have an additional separate window showing when the editmode is active, handling the presets of our own "green" frames. Also, in the preset window for our own "green" frames, you can find buttons to reset or create an editmode preset named "Azerite" with a setup ideal for the AzeriteUI default layout.
- Added a welcome message with the ability to reset or create an editmode preset named "Azerite" where the blizzard frames are in the default positions for AzeriteUI. To get the intended overall scale for the user interface as well, use the chat command `/resetscale`. If you accidentally click cancel and wish to see the tutorials again, use the `/resettutorials` command.

### Changed
- Introduced our new movable frame system. This forces a one-time settings reset upon the first login of each character. After this characters should be able to share movable frame presets between them, yet have their current preset choice saved separately to each character.

### Fixed
- Shouldn't be a weird, hovering mail icon next to the minimap anymore.
- Fixed a font related issue that sometimes would cause a bug when temporary (whisper) chat windows were opened.

### Removed
- Removed the previous chat command to reset the current editmode layout. It has been replaced by a new intro tutorial and a new editmode integration, explained above.

## [5.0.28-RC] 2023-01-23 (Dragonflight)
### Changed
- Party frames should once again be right-clickable.

## [5.0.27-RC] 2023-01-23 (Dragonflight)
### Changed
- The target frame now have a bigger hitbox including the character name and portrait.
- Party frames are now spawned using secure group headers, and not as individual unit frames. The goal is to work around some strange update problems resulting in party frames displaying wrong units.

## [5.0.26-RC] 2023-01-19 (Dragonflight)
### Fixed
- Fixed an issue where the zone ability styling would be applied indefinitely until the whole thing was just a blob.
- Fixed an issue preventing the extraactionbutton keybind from being displayed.

## [5.0.25-RC] 2023-01-19 (Dragonflight)
### Fixed
- The classpower element should no longer take up clickable screen space.
- The floating castbar element should no longer take up clickable screen space.
- A problem with identifying debuffs and debuff types were solved, resulting on much better aura sorting, filtering and correctly colored borders on debuffs.

## [5.0.24-RC] 2023-01-13 (Dragonflight)
### Fixed
- Unified the buff frame fixes to work for both retail and the PTR, and worked around a new retail issue that the previous build introduced.

## [5.0.23-RC] 2023-01-13 (Dragonflight)
### Fixed
- Fixed some editmode integrations and additions causing bugs in WoW Client Patch 10.0.5.

## [5.0.22-Beta] 2023-01-09 (Dragonflight)
### Changed
- Unitframes should now only respond to mouse release, not downpress. This should solve the issues with disappearing context menus.

### Fixed
- Fixed an issue where classpowers would bug out from getting update calls without max/min values passed.

## [5.0.21-Beta] 2023-01-06 (Dragonflight)
### Added
- Added back version label to the UI for anything not release tagged, because bug reports are fully useless for me without this information.

## [5.0.20-Beta] 2023-01-06 (Dragonflight)
### Fixed
- The classpower element should no longer bug out for rogues with more than 5 combo points. However, it currently only shows a maximum of 6, even when you have 7. An update with the last point is coming in a few days!

## [5.0.19-Beta] 2023-01-06 (Dragonflight)
### Changed
- Adjusted the nameplate aura filter to be a bit more selective.
- Enforce a few nameplate related cvars that messes with our plates.

## [5.0.18-Beta] 2023-01-06 (Dragonflight)
### Added
- Added the floating player castbar.
- Added latency, framerate, zone name, clock and new mail warning to the minimap.
- Added styling and positioning of the MBB addon icon.

## [5.0.17-Alpha] 2023-01-06 (Dragonflight)
### Fixed
- Fixed an issue with unit names in raid groups.

## [5.0.16-Alpha] 2023-01-06 (Dragonflight)
### Added
- Added Combo Points, Arcane Charges, Chi, Holy Power, Soul Shards, Stagger and Runes.

## [5.0.15-Alpha] 2023-01-05 (Dragonflight)
### Changed
- Attempted to prevent actionbuttons from being grayed out while dragonriding.

### Fixed
- The editmode azerite preset will no longer unintentionally attempt to reset on every logon.

## [5.0.14-Alpha] 2023-01-05 (Dragonflight)
### Added
- Added XP and Reputation tracking.

### Fixed
- More tracker theme change fixes.
- Fixed an issue related to a chat tab alpha update hook.
- Party frames are now parented to their visibility driver and should hide when in a raid group.

## [5.0.13-Alpha] 2023-01-03 (Dragonflight)
### Fixed
- The issue where some unit frames would bug out from their color post updates not receiving a color should now be fixed.

## [5.0.12-Alpha] 2023-01-03 (Dragonflight)
### Changed
- Party frames no longer appear when in a raid group.
- Player buffs now have a dark gray border, while debuffs should be colored by school of magic, if any.

### Fixed
- Updated issues related to powerType colors causing the power crystal to sometimes bug out.
- Fixed an issue related to caching of objective tracker mask textures when toggling between blizzard and azerite modes.

## [5.0.11-Alpha] 2023-01-03 (Dragonflight)
### Changed
- Updated LibEditModeOverride.

## [5.0.10-Alpha] 2022-12-30 (Dragonflight)
### Fixed
- The chat command messages about scaling and layouts will no longer be shown on every portal, zoning or teleport. Just after fresh logins and manual reloads.

## [5.0.9-Alpha] 2022-12-30 (Dragonflight)
### Fixed
- The Azerite layout in the editmode will no longer reset on every single login. I did not intend for that to happen.

## [5.0.8-Alpha] 2022-12-30 (Dragonflight)
### Fixed
- Fixed some bugs in the initial positioning of actionbars and unitframes on the initial login on a character.
- Fixed an issue that prevented our custom party (not raid) frames from showing.
- Attempted to work around the initial Azerite editmode preset being wrong by adding a forced timed profile reset on the initial login, or when the addon decides it's time for an update. We're still in Alpha, forced resets happen.

## [5.0.7-Alpha] 2022-12-29 (Dragonflight)
### Changed
- The blizzard compact party frames should no longer forcefully be disabled.

## [5.0.6-Alpha] 2022-12-29 (Dragonflight)
### Added
- Added startup chat messages to inform about `/resetscale` and `/resetlayout`.

## [5.0.5-Alpha] 2022-12-29 (Dragonflight)
### Changed
- The blizzard compact raid frames should no longer forcefully be disabled.

## [5.0.4-Alpha] 2022-12-29 (Dragonflight)
### Changed
- Reworked the retail health prediction post-update element to pass same values as the classic version, removing the need for extra function calls in the front-end.

### Fixed
- Added some missing post updates to correctly color actionbuttons.

## [5.0.3-Alpha] 2022-12-27 (Dragonflight)
### Added
- Clicking the middle mouse button on the minimap now opens the relevant expansion landing page like covenant, dragon stuff, order hall and so on.
- Mousewheel now zooms in and out on the minimap.

## [5.0.2-Alpha] 2022-12-27 (Dragonflight)
### Fixed
- Fixed an issue with heal prediction that caused a lot of bugs and broken health bars.

## [5.0.1-Alpha] 2022-12-23 (Dragonflight)
- First public commit.
