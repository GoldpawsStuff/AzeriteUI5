# AzeriteUI5 Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] 2024-10-09
- Bunch of fixes for Retail written by Pat. More is coming including proper patch notes before this goes live.

## [5.2.183-Release] 2024-09-25
- Updated for Classic Era client patch 1.15.4.

## [5.2.182-Release] 2024-09-02
### Added
- Added the new Professions entry to our cogwheel dropdown menu in Retail.

### Fixed
- A bug in Retail when enabling the Explorer Mode was fixed.

## [5.2.181-Alpha] 2024-08-25
### Fixed
- Boss unit frames once again appear in Retail. They are also movable and scalable through `/lock` as before.

### Removed
- All EditMode integrations and automations removed. You know fully have to set up the Blizzard parts of the user interface yourself, no automatic preset creation or selection anymore.

## [5.2.180-Release] 2024-08-24
- Note that for Retail users that didn't use the Alpha/Beta development versions leading up to this Release, there will be a full settings reset as a lot of settings got broken and stored incorrectly as a result of the bugs after WoW Retail patch 11.0.2.

### Fixed
- Reworked the Retail loading order for multiple modules to avoid incorrect scaling.
- Fixed some incorrect texture crops in the health predict element of the player- and target healthbars.
- Fixed an issue where the XP bar located on the Minimap would bug out if the mouse cursor hovered above the display button upon reloading the user interface.
- Changed how chat frame buttons are shown and hidden in Classic Era to avoid complications with button positioning when using the addon Dialogue UI.
- Slightly reduced the size of the Minimap border to avoid a tiny fully transparent area in Classic Era.
- Slightly adjusted the position of the Vehicle Exit button on the Minimap in Classic Era.
- Fixed reputation tracking in Classic Era.
- Removed usage of `GetMouseFocus` from Retail.
- The XP bar is once again displayed on the Minimap in Retail. The Retail reputation tracking seems to be missing in action, though. A fix for that is coming later.

## [5.2.174-Release] 2024-07-10
- Previously updated for WoW Classic Era Client Patch 1.15.3.

### Fixed
- The new friends button in Season of Discovery now hides on mouseover.

## [5.2.173-Release] 2024-07-03
### Added
- Added NDui to the list of addons that make our nameplates auto-disable.

## [5.2.172-Release] 2024-06-24
### Fixed
- Disabled the trinket cooldown part of raid(5) and enemy arena frames, as this has been broken since the last WoW patch, or maybe a bit longer. Note that I plan to fully replace both raid(5) and enemy arena frames with something slimmer and more fitting. I aim to rewrite the aura filtering and try to write something that is actually usable in arena and not just pretty on screenshots! Hope this bugfix works, I'm a week away from being able to test it myself (longer story than this changelog). Don't hesitate to drop by my discord and tell me when something is wrong! Over and out!

## [5.2.171-Release] 2024-05-02
### Added
- Added raid target icons to the raid(25) and raid(40) raid frames.
- Added group numbers to the raid(25) and raid(40) raid frames.

### Fixed
- Fixed an issue where the floating player castbar would keep re-enabling itself even when disabled in the `/azerite` options menu.

## [5.2.170-Release] 2024-04-30
- Support for Cataclysm Classic Pre-Patch.

## [5.2.169-Release] 2024-04-29
### Added
- Added an option to the chat settings in `/azerite` to toggle whether or not the primary chat window is cleared on logon and reloads. Also added a slider to adjust the number of seconds the window is kept clear.
- Added soft target icons to our nameplates in all versions of the game.

### Changed
- Modified the power value display on the player's power crystal to be much clearer and more readable.
- Modified the mana value displayed beneath the power crystal's power value while in Druid forms to be brighter andre more readable.
- Nameplates have a higher minimum opacity when in instances now.
- Unit tooltips now display if a player is away from keyboard.
- Classic Era Debuffs with a high duration on the player unit frame will now still be shown in combat.
- Slightly decreased the size but increased the opacity and readability of the player unit frame cast text.
- Slightly modified the class coloring of Paladins, Warlocks and Druids.

### Removed
- Removed support for and integration with LibHealComm-4.0 as it's no longer maintained by the author and no working versions for SoD Phase 3 are available. Having it supported even optionally would cause bugs as we cannot control what versions people might be using.

## [5.2.166-RC] 2024-04-13
### Changed
- Low Focus and Energy will no longer affect the Explorer Mode. These resources regenerate so fast that the Explorer Mode shouldn't be affected by them. Druid Mana in forms still remain as an option.
- The mana value on the power crystal for druid in forms will now appear from as much as 75% of maximum mana, but will be colored blue until below 25% mana where it will turn red.

### Fixed
- The Explorer Mode properly starts and exits again. Issues preventing it from starting on logons and reloads and preventing it from exiting on combat start, targeting and similar has been resolved.

## [5.2.165-RC] 2024-04-04
### Changed
- Default unit frame grouping in raid(15) and raid(40) group frames is now by player group, not by role as previously. Options of this is coming.

### Fixed
- Fixed `GetTimeToWellRested` nil bug when hovering over the XP bar in SoD phase 3.
- Actionbutton fading should be updated instantly when moving abilities around.

## [5.2.164-RC] 2024-04-03
- Updated for WoW Client Patch 1.15.2.

## [5.2.163-RC] 2024-04-01
### Changed
- Did a lot of work on the fade framing system.
- Debuffs on the player frame and friendly targets should once again have their borders colored according to debuff type.
- Buffs on hostile targets on the target unit frame now has their borders colored to indicate magic school.

### Fixed
- Fixed several inconsistencies in fade updates of actionbuttons when changing action page for any reason.
- Fixed an issue where the Explorer mode even when disabled interfered with regular frame fading and caused all actionbutton fadeouts to be instant instead of timed.
- Added some event registrations to unit frame name updates in an effort to battle the issue where names sometimes get mixed up in the group frames.

## [5.2.162-RC] 2024-03-26
### Fixed
- Updated the name of the Retail Minimap TrackingFrame to work with WoW Client Patch 10.2.6.

## [5.2.161-RC] 2024-03-22
- Updated for WoW Client Patch 10.2.6.
- Started work on supporting WoW Client Patch 4.4.0.

## [5.2.160-RC] 2024-03-17
### Changed
- Brightened up some of the non-hostile faction colors for tooltips and unitframe health bars.

## [5.2.159-RC] 2024-03-11
### Fixed
- It should now be possible to `/reload` the user interface while in an instanced raid group without losing the raid leader unit frame and getting an error message.

## [5.2.158-RC] 2024-02-13
### Fixed
- Fixed wrong threat texture on target unit frame portraits for critters.

## [5.2.157-RC] 2024-02-07
### Fixed
- Fixed and updated for WoW Classic Era 1.15.1.

## [5.2.156-RC] 2024-02-01
- Certain features that will remain in alpha testing a while will no longer be included in these patch notes until they're actually ready to be tested by the public.

### Changed
- Display names on arena enemy frames, boss frames, the focus frame, the target of target frame and nameplates will now be abbreviated before truncation in an effort to make names easier to read.

### Fixed
- Fixed an issue where the git development version would fail to load the embedded UTF8 library.

## [5.2.155-RC] 2024-01-20
### Fixed
- Party frames should now be explicitly disabled on startup and reloads to prevent blizzard party frames from showing in the classics.
- Fixed an issue where the enemy arena frames looked in the wrong place for the saved settings and would bug out upon loading.

## [5.2.154-RC] 2024-01-17
- Updated for WoW Client Patch 10.2.5.

### Changed
- Replaced the visibility options on all group frames. The default settings match the intended default behavior of the old settings, but now you can choose specifically which frames to see in which group sizes.

## [5.2.153-RC] 2024-01-13
### Added
- Added an option to disable HealComm in Classic Era and Wrath, as this sometimes would cause a drop in framerate for some users.

### Changed
- The option to exit the explorer mode when having any sort of replacement actionbar now also applies to Dragonriding in Retail. This option is enabled by default.
- The alternate playerframe is now available from public versions of the user interface as long as `/devmode` is enabled. Note that I'll ignore any issue reports or questions about missing items or when it'll be ready. This is in development and thus you use it at your own risk and without help.

## [5.2.152-RC] 2024-01-04
### Added
- Added an alternate version of the player unit frame with its own options and position. Accessible by first disabling the player unit frame, then enabling this element. Currently only available through git version with development mode enabled.

### Fixed
- Fixed an issue where changes to a character's talent points sometimes would cause an error.

## [5.2.151-RC] 2023-12-22
### Added
- You can now lock frames to specific anchor points from within the `/lock` interface, keeping them always relative to your selection portion of the screen. This feature is a part of the preparation for the upcoming profile and layout sharing features, where having the ability to lock frames to specific anchor points will make the layouts far more compatible with multiple screen setups.

### Fixed
- Fixed an issue where entering combat directly from a vehicle with a visible vehicle indicator would taint the editmode.

## [5.2.150-RC] 2023-12-20
### Fixed
- Fixed an issue introduced in the previous build(149) causing the options menu to break during startup and thus breaking the entire addon.

## [5.2.149-RC] 2023-12-19
### Fixed
- Pet- and stance buttons should no longer fire off a bug about a missing `hideElements` field.

## [5.2.148-RC] 2023-12-18
### Added
- Added the options to hide hotkeys for actionbars. You can find the option of the main page of the actionbar group in the `/azerite` options menu.
- Added various auraIDs to whitelists for the player- and target unit frames. This is work in progress, and currently mainly crowd control and debuffs of note have been focused on. I'm working on adding lists for general damage and healing too.

### Changed
- Attempting to update actionbutton back-end to return the spellID of pure macro buttons to fix some issues with MaxDps. Work in progress.

## [5.2.147-RC] 2023-12-17
### Added
- Added the player class power frame to Explorer Mode and added the relevant options for it.

### Fixed
- Added the missing function calls that broke raid(25) and raid(40) group frames in the previous update.

## [5.2.146-RC] 2023-12-17
### Added
- Added first draft of a new unitframe element that will show dispellable debuffs, boss debuffs and a possible custom list of auras to track. In development, feedback will be prioritized.
- Started writing aura lists for Classic, Wrath and Dragonflight for use with our aura filters.

### Fixed
- Actionbars will now once more become visible when you place an item, spell, macro or mount on the cursor. The Explorer Mode will also temporarily exit.

## [5.2.145-RC] 2023-12-14
### Added
- Added an optional initial delay to the Explorer Mode on login, reloads, other zoning screens and after combat ends. As default there is only a delay on the very first login on a character, but all of the mentioned situations can be modified in the `/azerite` options menu.

### Fixed
- Now using Caboyd's fork of LibHealComm-4.0 with support for SoD runes.
- Fixed wrong upvalue used in the party member aura filter function which were causing an avalanche of bugs and a crippling framerate drop.

## [5.2.144-RC] 2023-12-13
### Added
- Added the Explorer Mode option to keep the user interface faded while targeting something dead. This option is only enabled if either or both options for exiting the Explorer Mode while targeting something is selected.

### Changed
- Made the Explorer Mode options menu more dynamic, hiding options we can't currently access.

### Fixed
- Did yet another bug haul over empty actionbar slots that kept popping up when disabling bar fading.
- Fixed a bug related to the unit frame healprediction element in the Classics.

## [5.2.143-RC] 2023-12-13
### Changed
- Cleaned up the code about the turbulent last few days.
- Slightly changed a part of the Classics back-end.
- Removed a lot of ambiguity and room for misuse in the LibFadingFrames-1.0 back-end.

## [5.2.142-RC] 2023-12-13
### Fixed
- Fixed a major and majorly moronic actionbutton taint introduced yesterday.
- Did some safeguards to avoid addon conflicts from not detecting their enabled status properly at logon.

## [5.2.141-RC] 2023-12-12
### Fixed
- Fixed the weird action button flickering and C stack overflow that would occur for empty slots on bars not currently included in the regular actionbar fading system.

## [5.2.140-RC] 2023-12-12
### Added
- Added the pet- and focus unit frames to Explorer Mode.
- Added a multitude of options to the `/azerite` options menu to tweak when Explorer Mode exists.

### Changed
- The `/azerite` options menu now has a slightly changed category sorting in the category selection on the left side of the menu. Some categories are considered higher priority and will be listed before the other categories. Hopefully this will make it easier to navigate in the menu and faster to find new features.
- Actionbars that are set to fully fade out with all their buttons and fade separately from other actionbars will no longer force the Explorer Mode to exit. Hovering over them will shown only them and nothing else.

### Removed
- Options related to the focus frame in Explorer Mode has been removed from Classic Era, as the focus unit frame does not exist there.

## [5.2.139-RC] 2023-12-11
### Changed
- Fading frames now fade in and out smoothly, like they did in older versions of AzeriteUI before Dragonflight and the editmode forced a full rewrite. I wrote this system in my custom fade library back-end, so no changes were required to anything else. My frames simply need to register or unregister for fading, and the magic happens. So when and if we wish to add more optional elements to our Explorer Mode in the future, that will be easy.

## [5.2.138-RC] 2023-12-10
### Added
- Added the first draft of our slightly configurable Explorer Mode. This is a feature that allows you to fade out various frames while in "safe" situations. Selecting a target, entering combat, having low mana or less than full health are all examples of "unsafe" situations that instantly will make all the selected objects visible. Explorer Mode is for the time being disabled by default, to avoid confusing current users. You can find it in the `/azerite` options menu!

## [5.2.137-RC] 2023-12-09
### Changed
- Changed the party aura filters to show more of the buffs you have cast on your party members. Also changed it to show longer duration auras that are about to run out, like Blessings in Classic Era and WotLK.

## [5.2.136-RC] 2023-12-04
### Added
- Added an option to stop tracking to the Classic Era minimap tracking menu.
- Added a selection dropdown to `/lock` listing all the movable frames. All movable frames are listed here and you can select them regardless of whether their anchor currently is within the bounds of the screen or not.

### Changed
- The previous system where power bars in group frames where visible depending on class and amount of power left has been removed. The new system always hides non-mana power bars but always shows mana bars regardless of amount left, and for raid(5) and arena enemy frames all power bars are always shown.

### Fixed
- The Classic Era tracking menu now shows what you currently are tracking, if anything at all.
- The power crystal backdrop on the target unit frame is now hidden for units that currently have no power.
- Stance-/shapeshift buttons that spawn during combat from having leveled and learned a new spell should now both appear and be styled with actual icons and graphics once combat ends.

## [5.2.135-RC] 2023-12-02
### Fixed
- Fixed a class power related issue that was causing bugs for Monks and Death Knights.

## [5.2.134-RC] 2023-12-01
### Fixed
- Fixed inconsistencies in date back-end.
- Fixed an issue that would cause stance buttons in Retail to bug out when they were set to fade out.
- Fixed an issue where the time tooltip incorrectly would give the impression that a calendar existed in Classic Era and Season of Discovery.

## [5.2.132-RC] 2023-11-22
### Added
- You can now choose tooltip theme in the `/azerite` options menu. Currently only two themes are available, the old blocky `Azerite` theme and a new, simplified version of the traditional blizzard tooltip called `Classic`.

### Changed
- The default tooltip theme is now the blizzard looking `Classic` theme. You can change this in the `/azerite` options menu.
- To avoid issues with the arena enemy aura elements bugging out in the arena solo shuffle prep phase we're disabling the aura element until an arena opponent actually exists and can be queried.

## [5.2.133-RC] 2023-11-29
### Changed
- Added options to toggle specific class powers in the `/azerite` options menu without the need to create separate options profiles for separate characters.

### Fixed
- All class powers (including Runes and Stagger) are now simply listed as "Class Power" in both the `/azerite` options menu and in `/lock` mode.

## [5.2.132-RC] 2023-11-22
### Added
- You can now choose tooltip theme in the /azerite options menu. Currently only two themes are available, the old blocky Azerite theme and a new, simplified version of the traditional blizzard tooltip called Classic.

### Changed
- The default tooltip theme is now the blizzard looking Classic theme. You can change this in the /azerite options menu.
- To avoid issues with the arena enemy aura elements bugging out in the arena solo shuffle prep phase we're disabling the aura element until an arena opponent actually exists and can be queried.

## [5.2.131-RC] 2023-11-20
### Fixed
- The fading frames library will no longer break the frame fading on logon in Wrath and Classic Era.

## [5.2.130-RC] 2023-11-20
### Fixed
- Turning off arena prep frames in solo shuffles until we can figure out what makes them bug out.

## [5.2.129-RC] 2023-11-20
### Fixed
- Actionbuttons should no longer fade out when a flyout bar is visible.
- Problems with keybinds not functioning in pet battles have been fixed.

## [5.2.128-RC] 2023-11-19
### Fixed
- Fixed issues related to the tooltip statusbar display for walls, gates and similar objects.
- Fixed issues related to health absorb displays in Retail 10.2 in oUF.

## [5.2.127-RC] 2023-11-17
- Updated for WoW Client Patch 1.15.0.

### Fixed
- Added a more secure workaround for a nameplate related error that I find it impossible to reproduce.
- Added a general fix to work around `UnitInRange` and `IsItemInRange` being protected and blocked in combat in WoW Retail build 52188.

## [5.2.126-RC] 2023-11-16
### Changed
- The console variable `scriptErrors` will now forcefully be set to `1` as these reports exist for a reason.

### Fixed
- May or may not have fixed a nameplate related error that some users were experiencing.

## [5.2.125-RC] 2023-11-07
- Updated for WoW Client Patch 10.2.0.

### Added
- Added an option to always use the player unit frame power crystal, even for mana.

### Fixed
- We're now manually embedding LibEditModeOverride again, as the external version is outdated and causes startup bugs.

## [5.2.124-RC] 2023-11-01
### Fixed
- Fixed an issue that would prevent the player class power (runes, combo points, etc) from being disabled.

## [5.2.123-RC] 2023-11-01
### Fixed
- An issue that would cause the Minimap to slightly drift when changing user interface scaling has been fixed.
- An issue that could cause all actionbar anchors to break for some users have been fixed.
- Issues related to how default positions were recalculated according to current scale and resolution have been worked on.

## [5.2.122-RC] 2023-10-31
### Fixed
- Fixed a bug in our back-end with the upcoming SpellActivationGlow integration.

## [5.2.121-RC] 2023-10-30
### Fixed
- Changed how action bar defaults are stored. Resetting to default positions may or may not work better now.
- Restructured how various action button states are being tracked and applied in relation to button dimming. Changes to action button dimming settings should now be applied instantly and no longer require a reload or state change first.

## [5.2.120-RC] 2023-10-29
### Fixed
- Attempted to work around an issue where chat textures refused to fade along with the rest of the UI.
- The bag bar should once again be attached to the backpack or the combined bags.

## [5.2.119-RC] 2023-10-27
### Added
- Added the option to select between the AzeriteUI and Blizzard theme on the Retail Objectives Tracker. This is an experimental feature and subject to bug out when using the Blizard theme.

### Changed
- Attempting to make [#47](https://github.com/GoldpawsStuff/AzeriteUI5/issues/47) happen.

### Fixed
- Attempting to fix [#46](https://github.com/GoldpawsStuff/AzeriteUI5/issues/46).

## [5.2.118-RC] 2023-10-23
### Added
- Added anchoring options to the tooltips. Tooltips shown in the default position can now be shown at the cursor, or totally ignored to be handled by Blizzard and third party addons instead.
- Added visibility options to the tooltips. General tooltips, unitframe tooltips and actionbar tooltips can now be hidden in combat.

### Changed
- Powerbars on enemy arena frames in the arena preperation phase should now be hidden, since this is info we can't access anyway.

### Fixed
- May or may not have fixed or worsened some scaling problems with group frames.

## [5.2.117-RC] 2023-10-22
### Fixed
- The player- and target unitframes now properly fades out along with the rest of the interface when the option to fade the interface has been chosen in the addon Immersion.

## [5.2.116-RC] 2023-10-21
### Added
- Added an option to disable the Retail objectives tracker. *(Experimental)*
- Added an option to disable the Wrath Classic objectives tracker.
- Added an option to disable the Classic Era quest tracker.
- Added an option to never expire the tracking of auto-tracked quests in Classic Era.
- Added an option to toggle enemy arena frame visibility within battlegrounds, where they are used as flag carrier frames by the game.

### Changed
- Actionbuttons while now never be dimmed while dragonriding, in a vehicle, using an override bar or using a temporary shapeshift bar, regardless of whether you're resting or not.
- The default coloring of aura button border on any unit frame should now be dark gray, not bright orange which appeared on some frames like the arena enemy frames.

### Fixed
- Fixed an issue where the aura buttons of the arena enemy frames in Classic Era and Wrath Classic used the input arguments of the Retail version's post update function, causing an insufferable error spam while in battlegrounds or arenas.
- Fixed an issue with the chat fading settings where visible time and fading time had been mixed up.
- Fixed an issue where both the mana orb and power crystal were visible at the same time for a short period when entering vehicles.

## [5.2.115-RC] 2023-10-19
### Added
- Options for chat fading- and duration have been added to our `/azerite` options menu.

### Changed
- Changed unit drivers for the player- and pet frames to custom ones to avoid the frames disappearing for a short moment when entering a vehicle.

## [5.2.114-RC] 2023-10-18
### Fixed
- Fixed an issue where spell activation overlay glows for actionbuttons sometimes would remain visible even after the activation period ended.

## [5.2.113-RC] 2023-10-15
### Fixed
- The Wrath Classic 3.4.3 Dungeon Finder button in our micro menu now works. It can however not be clicked in combat. This is a restriction enforced by the game and cannot be overridden.

## [5.2.112-RC] 2023-10-14
### Changed
- Our nameplates will now auto-disable when the conflicting addon `ClassicPlatesPlus` is enabled.

### Fixed
- Rewrote the unit- and visibility macro drivers for the Raid(5) unit frames. The frames should hide when disabled again, and properly decide between raid- and party units depending on your settings and the current group type. Currently untested.

## [5.2.111-RC] 2023-10-11
- Updated for WoW Client Patch 3.4.3.

### Changed
- The block of information next to the Minimap containing the clock, zone name, resting status, latency and performance stats now is movable and configurable. Also, it's no longer considered a part of the minimap but an entity of its own. The previous options to configure the time display now lives in their own category in our options menu. This is a work in progress and more options will be added before the next tagged release.

### Fixed
- Fixed an issue with a library being loaded twice, which caused an error when using GitHub developer versions.
- General alignment problems with the Raid(5) unitframes should have been sorted out now. They now use the same code and systems as the Enemy Arena unitframes, which they also mirror in looks and layout.
- Status displays like "Offline" and "Away" should no longer appear on enemy arena frames. They are not needed.
- The power bars on enemy arena frames should now be hidden when the unit is dead or the info isn't available.

## [5.2.110-RC] 2023-10-08
### Changed
- Moved LibMoreEvents-1.0 to externals as this is a public library available on GitHub and CurseForge now.

### Fixed
- Worked around a Blizzard bug where the actionbar backdrop grids when holding a pet ability on the cursor in Classic Era would remain visible even after the ability was placed or dropped.

## [5.2.109-RC] 2023-09-20
### Added
- Added an experimental pet happiness display to the pet unit frame in Classic and Wrath.
- Added options to dim down the actionbuttons when resting or at any time when not engaged in combat or having a current target. They are disabled by default, but available from the front page of the actionbar menu.

### Changed
- Started on a rework of the actionbutton library.
- Changed various libraries to externals and removed them from the project folder structure.

## [5.2.108-RC] 2023-09-11
### Added
- Added better support for ConsolePort keybinds on our own actionbuttons.

### Changed
- Pet Happiness when not optimal will now replace the health value display on the pet unit frame in Wrath and Classic.
- The target unit frame aura filter has been slightly modified in Wrath and Classic. Experimental work in progress.

## [5.2.107-RC] 2023-09-06
- Updated for Retail client patch 10.1.7.

## [5.2.106-RC] 2023-08-30
### Fixed
- The Classic QuestTimerFrame is now actually movable, instead of just stretchable.

## [5.2.105-RC] 2023-08-30
### Added
- The Classic QuestTimerFrame is now movable.

## [5.2.104-RC] 2023-08-30
### Fixed
- Fixed an issue where the classic pet bar didn't respond to hotkeys, just the mouse.

## [5.2.103-RC] 2023-08-26
### Fixed
- Fixed an issue with raid(5) in Wrath.

## [5.2.102-RC] 2023-08-24
### Changed
- Updated for Classic client patch 1.14.4.
- Updated various libraries.

## [5.2.101-RC] 2023-08-21
### Changed
- The ToT and Focus unit frames should no longer color your NPC minions according to their class, but rather their faction standing as regular NPCs.

### Fixed
- Fixed an issue where the rested status shown next to the zone name would only update on reloads and relogs and not on zone changes.

## [5.2.100-RC] 2023-08-18
### Fixed
- The boss frames, arena enemy frames and various group frames now responds to scale changes again. Be warned that this might change the scale of those frames, and is not a bug. It's the previous unscalable size that was the bug.
- Anchoring inconsistencies in the arena enemy frames have been solved. They should mirror the raid(5) frames more accurately now.

## [5.2.99-RC] 2023-08-17
### Added
- The `HonorLevelUpBanner` and `PrestigeLevelUpBanner` frames should also be moved along with the other banners in `/lock` mode now.

## [5.2.98-RC] 2023-08-17
### Added
- There is now a text notification on the minimap when you're resting.

### Changed
- The various mid-screen banner announcements are now movable. Examples of banners are the level up display, honor level gain display, the boss fight banner and so on.

### Fixed
- You should no longer get an error message when master looter is set or changed in Classic Era and Wrath.
- The option to only show the pet bar on mouseover even in combat now actually works.

## [5.2.97-RC] 2023-08-11
### Changed
- The anchor for alert frames in `/lock` is now a bit larger.
- Friendly bosses will no longer get a huge target frame, regardless of options chosen for this. Only attackable enemy bosses will get the huge frame.

## [5.2.96-RC] 2023-08-11
### Changed
- Neither the action bars, pet bar, stance bar or modifications to the encounter bar, zone ability buttons or the extra action buttons will be loaded if ConsolePort's bar module is enabled.

### Fixed
- Update macro drivers for the visibility of small party sized raid frames. Does this ever end?

## [5.2.95-RC] 2023-08-10
### Fixed
- The option to disconnect pet action bar fading from the main action bar fading now actually works. Only the pet bar will fade in when this option is enabled now.

## [5.2.94-RC] 2023-08-10
### Fixed
- Fixed an issue where a movable frame anchor's default position would be recorded without taking its default scale into consideration, resulting in weird placements when shift + clicking the frame in `/lock` mode.
- Fixed an issue where enabling an action bar which hadn't previously been visible that session would result in the icon mask not being applied.

## [5.2.93-RC] 2023-08-09
### Changed
- The party frames now have an option to be shown in small party sized raid groups. When this option is enabled, the raid(5) frames will stop existing.

### Changed
- The alert frame anchor is now movable. Alerts refer to most centered temporary popups like item upgrades, group loot and special currency gains. Moving the anchor also affects alert growth direction, where if anchored to the top horizontal portion of the screen will grow downwards, everything else upwards.

## [5.2.92-RC] 2023-08-03
### Fixed
- Did a major overhaul of the groupe frame visibility drivers, as it turns out they were fairly bugged.
- The override action bar should no longer pop up if reloading while it would have been visible in the blizzard interface.
- Changed to anchoring of the blizzard top center UI widget frame to make it bug out and become without text less often.

## [5.2.91-RC] 2023-07-27
### Fixed
- Changed how grouped units are tracked locally to fix issues with changes to range fading of raid frames not working properly.

## [5.2.90-RC] 2023-07-27
### Fixed
- Fixed a breaking bug occurring in Classic Era that could cause the global lua function `type` to be replaced with a string, thus breaking the entire user interface and nearly all addons. According to some other WoW UI devs, I should be flogged.

## [5.2.89-RC] 2023-07-26
### Removed
- Nameplate widget containers and soft target frames are now hidden. We mark soft targets with outlines, we'll add another way to track friendship reputations, if that really is needed.

## [5.2.88-RC] 2023-07-25
### Changed
- The MaxDps outline colors are no longer set by your MaxDps settings, but instead hardcoded to bright white for next spell and purple for cooldowns. Just feels more epic that way.

### Fixed
- Changed how the EncounterBar (vigor, etc) is reanchored to avoid that pesky C loop overflow sometimes happening after portals.

## [5.2.87-RC] 2023-07-25
### Fixed
- Raid frames of various sizes are now possible to properly toggle without the need for a reload.
- When disabling range fading on raid frames the unitframes should now reset to full opacity.

### Removed
- Removed overlay castbars from raid(25) and raid(40) unitframes. We don't need this level of information from that many raid members.

## [5.2.86-RC] 2023-07-24
### Added
- The range fading of group unit frames is now optional. It is enabled by default for large raid frames (6-40 players) and disabled by default for small sized raid frames (1-5 players).
- You can now choose between the Wrath ice power crystal and the regular power crystal colored by resource type in all WoW client versions.

### Changed
- Finetuned the minimap ringbar spark position and size to work better for Classic and Wrath.

### Fixed
- Disabled the non-functioning dispellable aura element to avoid raid frames bugging out in Wrath and Classic.
- Worked around an issue where the Encounter bar (dragon riding vigour e.g.) sometimes would bug out when encountering a loading screen while mounted on the dragon mount.

## [5.2.85-RC] 2023-07-23
### Added
- Added an option to only show auras on the currently targeted nameplate.

### Fixed
- Fixed an issue that would cause the options menu to bug out when trying to load settings for auto-disabled modules.
- Fixed an issue where the options menu would bug out upon updating the nameplate settings.

## [5.2.84-RC] 2023-07-21
### Added
- Added the option to toggle nameplate auras.

### Fixed
- Fixed an issue upon login with the mirror timers (breath, fatigue) in Classic and Wrath.

## [5.2.83-RC] 2023-07-21
### Fixed
- Fixed wrong function call in the arena trinket plugin in Retail.
- Raid layouts should be less weird now.

## [5.2.82-RC] 2023-07-20
### Fixed
- The issue with the missing mana orb positioning info for maximum level characters has been fixed.
- The minimap error popping up at login or reload in Classic and Wrath have been fixed.

## [5.2.81-RC] 2023-07-19
- Supports Retail 10.1.5.
- Supports Classic Hardcore 1.14.4.
- Note that several features are currently under development and most uploaded builds are development builds. I strongly recommend against installing anything from GitHub at this point. Use the official tagged builds from CurseForge and Wago.

### Added
- Added options to disable the player- and target unit frame overlay castbars.
- Added first draft of arena enemy frames. These frames mirror the new 5 player raid frames. Note that several features here are still under development and will be added, like trinket cooldown tracking, big CC display and more.
- Added separate raid frames for raids of up to 5 players. These frames mirror the look of the enemy arena frames. If these are disabled, party frames with portraits will be shown in raids of up to 5 players.
- Added separate raid frames for raids of up to 25 players. If the above are disabled, these raid frames will also be shown in raids of up to 5 players.
- Added separate raid frames for large raids of up to 40 players. If the 25 player raid frames are disabled, these frames will also be shown in raid of up to 25 players. If the 5 player raid frames also are disabled in addition to this, these frames will also be shown in raids of up to 5 players. You still following?
- Added anchors to move and scale the Blizzard UI widgets found at the top center of the screen and below the minimap.
- Added an option to automatically load an EditMode layout when enabling a settings profile.
- Added mirror timer bars to Retail.

### Changed
- Previously when mousing over a faded actionbar, all faded bars would fade in at once. Now you can make bars only fade in their own buttons and not every single faded button in the user interface at once.
- Party auras should be a bit more restrictive now and hide self-cast buffs by the party members.
- Party frames will now by default appear for raids of up to 5 players when none of the available sized frames are enabled.
- Our nameplate module will now disable itself when the addon namePlateM+ is enabled.
- The target frame should no longer show various low health level 1 NPCs in starting zones as critters on Retail.
- The alert frames are now by default moved to the top of the screen and grow downwards. I plan to add options for this.
- Removed a few of the most annoying quest overlay textures from the Minimap.
- Updated the oUF for retail to the most recent WoW 10.1.5 compatible version.
- Did a lot of aura tweaking for arena and raid(5) frames.
- The 12 hour clock format is now only the default for the US region, while other regions get a 24 hour clock format as default. This is just a change to the default setting, which only will affect non-US user that currently had the setting set to its default.
- The mirror timers are now movable in all versions.

### Fixed
- Fixed issues preventing any absorb bars from showin up at all. We now separate between absorbs when health is missing and absorbs when health is at maximum. The absorb bar will never take up more space than that of the missing health when health is missing, except when the health of the unit is at maximum, then it will be overlayed, but limited to less than health of the full health bar in size. It makes sense when you see it.
- Fixed an issue preventing the floating castbar from properly enabling or disabling itself when the Personal Resource Display was toggled in Retail.
- The bag options in retail now actually does change the sorting and insertion directions.
- The absorb overlay on nameplates should no longer be shrunken and weird.
- The encounter bar (including dragonriding vigor) shouldn't pop as much around the screen as before.
- Fixed an issue where the description text on the experience status bar would show the wrong level as the next level immediately after leveling up.
- The target unit frame castbar and auras should remain hidden once disabled through the `/azerite` options menu now.
- Fixed issues related to PvP trinkets in the arena unit frames.
- Fixed the alignment of the arena prep frames.

### Removed
- Removed the new spell activation alert surrounding the extra action button. It's redundant, as the extra buttons only appear when needed anyway.

## [5.1.74-Release] 2023-06-24
### Added
- Out of range units in the raid frames should now be transparent.

## [5.1.73-Release] 2023-06-21
### Added
- Added the option to show a regular sized target frame for critters and bosses.
- Added a confirmation prompt before resetting your selected settings profile in `/azerite` or `/lock`.

### Fixed
- The area you can mouse over while still being able to click the player- and target unit frames should now be less enormous.

## [5.1.72-Release] 2023-06-21
- Bumped the Wrath interface version to WoW Client Patch 3.4.2.

### Changed
- The raid frames will now also as default appear in raids with less than five people. This is a setting you can change from the `/azerite` options menu under the unitframes submenu in the raid- and party sections.
- Adjusted the screen segments used by our movable frames to feel more logical.
- The user interface will no longer load when another directly conflicting user interface is discovered.
- Removed the combat feedback text from raid frames, as this was just too visually spammy and resource intensive.

### Fixed
- Fixed the object type of Leader- and Master Looter indicators in the Raid Frames, which both had been registered wrongly as fontstrings instead of textures.

## [5.1.71-Release] 2023-06-19
### Fixed
- Fixed an issues where buffs in the floating full buff display always would be glued to the top right corner of our container frame, regardless of anchor point chosen.
- Fixed the position of the vehicle exit button in Wrath.

## [5.1.70-Release] 2023-06-18
### Fixed
- Fixed an issue where the actionbars would throw an anchor error upon changing the game's UI scale.
- Fixed some inconsistencies with the scaling of the vehicle exit button in Classic and Wrath.
- Disabled elements in the `/azerite` menus unitframe section will no longer cause the UI to bug out on next `/reload`.

## [5.1.69-Release] 2023-06-18
### Fixed
- Settings should be properly loaded and saved and stick through sessions in Retail now.
- Raid frames should start without incident now.

## [5.1.68-Release] 2023-06-17
- Fixed the incorrect version number.

### Added
- Added an option to toggle the cast on down setting for the action bars. In Retail since the 10.0 patch this applies to every clickable button in the game, in the Classics this is limited to our own action buttons only.

### Changed
- The action bars, pet bar and stance bar should no longer grab keybinds from blizzard or bartender when disabled.

## [5.1.67-Release] 2023-06-16
- This version is backwards incompatible and will force a full reset of its settings.
- This version is compatible with Wrath 3.4.2 PTR and Dragonflight 10.1.5 PTR.

### Added
- Added an options menu accessible through the command `/az` or `/azerite`.
- Added a stance/shapeshift bar with layout- and visibility options.
- Added a pet action bar with layout- and visibility options.
- Added threat glow to the nameplates and to the player- and target unit frames.
- Added nameplate highlight outline for soft targeting in Retail. Thanks Billybishop@GitHub for writing this!
- Added the option to keep actionbars faded out in combat and only visible on mouseover.
- Added the command `/resetsettings` to fully reset this addon's settings to its defaults.
- Started working on proper localization for the addon. A lot of general phrases copied from blizzard are already in place, but some phrases and longer texts remains untranslated for non-English locales. Work in progress.

### Changed
- The Movable Frames Manager can now be opened with `/lock` in all versions of the game. Some elements in Retail are however slaved to the EditMode and requires that be open for adjustments. This includes the Retail Objectives Tracker.
- Moved settings for unitframe aura sorting into the new options menu.
- Moved settings for Retail bag sorting and new item insertion into the new options menu.
- The player auras located in the upper right corner are now movable, and has new settings in the new option menu for visibility.
- Redid scaling options for most frames. The default scale will now be a scale that gives our intended size relative to your current uiscale in the game's graphics settings. All movable frames will also get their scales and positions autoadjusted when the user changes the game's uiscale.
- Redid how our movable frame system works in relation to saved settings. Most settings within modules like the actionbars should now be tied to the current movable frame profile. Meaning settings like enabled bars and bar layouts also change alongside the positioning profile.

### Fixed
- Updated TaintLess.xml to the most recent version to be compatible with Wrath 3.4.2.
- Fixed the position and size of the glowing edge on the minimap xp/reputation ring shaped status bars.
- Fixed an issue with the Retail chatframe scrollbars that would cause bugs and prevent them from updating correctly.
- Fixed an issue with the actionbar frame fading that would prevent fading from working correctly after a settings change.

### Removed
- Removed most chat commands. All these settings have been moved to the new options menu.

## [5.0.65-RC] 2023-05-06
### Fixed
- Classic Era enemy castbars are once again working as intended.
- Reagent counts in Classic Era for spells like Slow Fall and Gift of the Wild should now properly show up on the action bars.

## [5.0.64-RC] 2023-05-04
### Changed
- Updated retail version of the oUF unitframe library.
- Added buttonPadding and breakPadding arguments to the yet undocumented `/setlayout` command. I'll be creating documentation for this and all other chat commands on the AzeriteUI github pages in the near future!

### Removed
- Hid the new AddonCompartmentFrame from the minimap. We don't want this.

## [5.0.63-RC] 2023-05-03
- Bumped for WoW client patch 10.1.0.

### Added
- Added a command to adjust the button layout of the actionbars.

### Changed
- Moved the addon's icon texture into the new field in the WoW 10.1.0 TOC structure.

### Fixed
- Fixed names for raid boss emote slots in WoW 10.1.0.

## [5.0.62-RC] 2023-04-22
### Fixed
- Fixed tooltip placement in Classic and Wrath further.

## [5.0.61-RC] 2023-04-21
### Added
- Added a custom (yet identical to the default) durability widget, which is movable.

### Fixed
- Fixed an issue that caused the tooltip to appear in the game's default position when moved away from AzeriteUI's default position. This would primarily happen in Classic, but probably also in the other flavors sometimes too.

## [5.0.60-RC] 2023-04-20
### Changed
- Debuffs should properly be sorted before buffs on most unit frames now.

### Fixed
- Fixed some inconsistencies in weapon enchant timer bars.
- Added some experimental changes to how font families and sizes are chosen in order to make Cyrillic and Chinese fonts more readable and correctly sized.

## [5.0.59-RC] 2023-04-17
### Fixed
- The nameplate module should now properly disable itself when a known nameplate addon like Plater or TidyPlates is loaded.

## [5.0.58-RC] 2023-04-13
### Fixed
- Buffs in the top right corner buff display visible while holding Ctrl + Shift can now properly be canceled when right-clicking on them also in Retail.

## [5.0.57-RC] 2023-04-13
### Fixed
- Temporary weapon enchants should now show the correct tooltip.

## [5.0.56-RC] 2023-04-12
### Fixed
- Fixed an issue where we attempted to rotate text in Classic, where it is not yet implemented in the WoW API.

## [5.0.55-RC] 2023-04-12
### Added
- Added the chat command `/setbuttons x y`where `x`represent the bar number and `y` represents the number of buttons you wish that bar to have, from 1 to 12.

### Changed
- All primary actionbars will now be auto-disabled when ConsolePort's actionbar module is loaded.

### Fixed
- Fixed some inconsistencies in how and when custom chat bubbles was enabled and disabled in Wrath.
- Fixed a bug in the actionbar layout method that would cause the two rows of six buttons in the sidebars to be displayed on top of each other.

## [5.0.54-RC] 2023-04-02
### Added
- Added a crafting order notification to the new mail display. Removed the blizzard icon for the same.

### Changed
- The actionbuttons should now obey the blizzard options to cast on focus- and mouseover unitframes. The latter only applies to Dragonflight, as the option only exists there. I might build it into Wrath and Classic too, though this takes a larger workaround as the game does not inherently support it there.
- Actions that have more than one total charge should now also show the remaining charges when it's only one left, as to opposed to previously where it would only show the count if it was more than one charge remaining.

### Fixed
- Temporary weapon enchant cooldowns in the aura frame should be slightly more readable now.
- Added an extra callback to handle group member info being wrong after group leader changes in Wrath.
- Fixed a typo in the unitframe xml file that may or may not have caused problems.

## [5.0.53-RC] 2023-03-25
- Updated for WoW 10.0.7.

### Added
- Added the social/friends button from Retail to our cogwheel micro menu. You can now open your friends panel without a keybind.

## [5.0.52-RC] 2023-03-20
### Fixed
- The backdrop alignment of the health bar on Boss- and Critter frames should once again be correct.

## [5.0.51-RC] 2023-03-20
### Added
- Added the chat commands `/disableaurasorting`and `/enableaurasorting` to toggle the time based display of auras. If you like your auras to stay more or less in the same place when you maintain a rotation, regardless of time left, you might want to try the first command. Applies to all unitframes including the nameplates.

### Fixed
- Latency display should be much more consistent and correct now.

## [5.0.50-RC] 2023-03-20
### Fixed
- Changed how the vehicle seat indicator is positioned, to avoid the mega stretched icon in Wrath.
- Fixed where and how the health prediction element was shown on the target unit frame.
- Warrior actionbars should finally change when changing stances in Classic Era.

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
