[![patreon](https://www.goldpawsstuff.com/shared/img/common/pa-button.png)](https://www.patreon.com/goldpawsstuff)
[![paypal](https://www.goldpawsstuff.com/shared/img/common/pp-button.png)](https://www.paypal.me/goldpawsstuff)
[![discord](https://www.goldpawsstuff.com/shared/img/common/dd-button.png)](https://discord.gg/RwcSm8V3Dy)
[![twitter](https://www.goldpawsstuff.com/shared/img/common/tw-button.png)](https://twitter.com/GoldpawsStuff)

AzeriteUI5 is a custom user interface for World of Warcraft Dragonflight, Wrath Classic and Classic Era.

## FAQ
- To remove abilities from the action bars, hold alt+ctrl+shift and drag.
- To show a full buff display where you can right-click to cancel buffs, hold ctrl+shift while not being engaged in combat and not having a target currently selected.
- Yes, I plan to make a config menu instead of these chat commands.
- Yes, the config menu will allow you to manually disable nearly every module in the UI.
- Yes, I will be making arena frames.
- Yes, there will be layout choices for the actionbars.
- Yes, I do accept donations and will love you for it. Links above.

## Chat Commands
Note that the following commands do NOT work while engaged in combat. All settings are stored in the addons saved settings.

### Scaling & Positioning
- **/resetscale** - Resets the blizzard user interface scale to what the UI was designed for. Note that individual AzeriteUI frames can be scaled with the mousewheel from within the editmode while hovering over our green frame anchors.
- **/resettutorials** - Resets the completed status of our tutorials (currently only a fast setup tutorial) and shows them.
- **/runtutorials** - Runs any uncompleted tutorials which you chose to hide on login.

### Action Bars
Change actionbar settings like enabled bars, number of buttons and fading.
- **/enablebar \<barID\>** - Enable a bar. Valid barIDs are 1-8.
- **/disablebar \<barID\>** - Disable a bar. Valid barIDs are 1-8.
- **/enablebarfade** - Enable bar fading.
- **/disablebarfade** - Disable bar fading, keeping buttons with actions always visible.

### Movable Frames
- **/lock** - Toggles movable frame anchors. Only available in Wrath Classic, as this is tied to the EditMode in Retail.
