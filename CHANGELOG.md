# v1.7
* Updated for 11.0

# v1.6.2
* Updated for 10.2.5

# v1.6.1
* Removed M+ UI right-click menu to avoid UI taint caused by using UIDropDownMenu functions.

# v1.6.0
* Guild keystones list now also shows players without the guild addon who have OpenRaidLib, such as from Details Damage Meter.

# v1.5.18
* Updated for 10.2.0.

# v1.5.17
* Updated for 10.1.5.

# v1.5.16
* Disabled Release Spirit Confirmation module to avoid weird dialogue taint.

# v1.5.15
* Fixed data not syncing.

# v1.5.13
* Improved data sync speed.

# v1.5.12
* Updated for 10.1, including new races.
* Fixed some sync errors.

# v1.5.11
* Fixed "No player named <name> is currently playing." spam when a sync is interrupted.

# v1.5.7
* Fixed overall leaderboard not displaying due to mangled data.

# v1.5.6
* Fixed issue displaying overall leaderboard times.

# v1.5.5
* Updated for patch 10.0.7
* Added new Forbidden Reach races to the Dragon Racing Leaderboard.
* Times are now automatically obtained, no need to do a race!

# v1.5.4
* Fixed data corruption preventing the leaderboard from displaying.
* Fixed races always reporting the player's main as having the best time, even if an alt achieved it.

# v1.5.3
* Fixed personal best times sometimes not being reported.

# v1.5.2
* Added better reporting of guild bests and account bests when completing a race.
* Fixed personal best message not being shown for the player that achieved it.

# v1.5.0
* Added alt tracking! You can now set your main in the AddOn settings.
  * The Dragon Racing Leaderboards will now combine best times for all players' characters into a single entry for their main. 
* Added guild best time message when completing a dragon race, so you know what to aim for!

# v1.4.1
* Fixed missing leaderboard icon.

# v1.4.0
* Added Dragon Racing Leaderboards! 
  * Compete with guildies for the top spot in each race, and overall as the champion Dragon Racer!
* Tentative fix for Release Spirit Confirmation not always closing after releasing.
* Fixed "You are not in a guild" messages when playing on a guild-less character.

# v1.3.5
* Fixed Mythic Plus weekly bests not updating correctly.
* Added Vault of the Incarnates to the Release Spirit Confirmation areas.

# v1.3.4
* Added Dracthyr as a clubbable race

# v1.3.3
* Updated for patch 10.0.2

# v1.3.2
* Updated for patch 10.0
* Updated branding to use new guild logo.

# v1.3.1
* Bumped TOC

# v1.3.0
* Oribos is now on high-alert for clubbers!
* Adds a confirmation dialog when releasing spirit in Castle Nathria, as a group res is pretty likely!

# v1.2.1
* Brings mangos

# v1.2.0
* Updated for patch 9.0.1.
* Adds score syncing.

# v1.1.0
* Reworks the systems behind the Clubbing Competition score to make them a global scoring system across the addon: Clubber Points.
Officers can now award these during events, so stay tuned!
* Fixes Mythic+ module reporting weekly bests per map, rather than overall weekly best.
* Fixes Guild Keystone list not displaying correctly.

# v1.0.23
* Some zones are now on high-alert and looking out for Clubbers, you'll have to lay low periodically to avoid confrontation.
* Fixes InfoHUD tabs resizing and sorting incorrectly.
* Fixes InfoHUD sometimes resizing to max height if a tab has no data in it.
* Fixes debug messages printing when a version request is sent.
* Fixes Mythic Plus UI not scrolling.
* Fixes Mythic Plus UI sorting offline players above away/busy players.

# v1.0.22
* Adds Mythic Keystones module 
    * See what keystones each guild member has and what their weekly best is!
* Adds WCCC Menu to the guild window
    * Easily access WCCC AddOn features from the guild panel!

# v1.0.21
* Adds missing AceHook library.

# v1.0.20
* Fixes an issue where "AddOn Loaded" and "Character not in the WCCC" messages would show incorrectly (usually during loading screens).

# v1.0.19
* First release version!

# Beta v1.0.18
* Adds indicator on players in the guild roster that are also using the AddOn.

# Beta v1.0.17
* First Beta release
* Updates to WoW Patch 8.3

# Alpha v1.0.16
* Fixes a sync error with Info HUD

# Alpha v1.0.15
* Adds Last Season's Top Clubbers display in the Clubbing Competition HUD
* Fixes a sync error with Info HUD
* Improves formatting of clubbing competition help tab.

# Alpha v1.0.14
* Gave the AddOn a swanky new name, the WCCC Clubbing Companion!
* Adds chat notification when an Info HUD message is updated whilst the HUD is hidden and auto show is off, or it's not a guild message so won't auto show.

# Alpha v1.0.13
* Adds close button to HUD panels.

# Alpha v1.0.12
* Adds Info HUD module.
* Adds confirmation message when creating the Clubbing Competition macro.

# Alpha v1.0.11
* Adds option to toggle club button on the Clubbing Competition HUD.

# Alpha v1.0.10
* Adds club button to the Clubbing Competition HUD.
* Adds new emote when the player clubs themself.
* Adds create macro button to the Clubbing Competition help menu.

# Alpha v1.0.9
* Tweaks points worth of each race.
* Adds Clubbing Competition HUD

# Alpha v1.0.8
* Adds "/wccc ver" version check command which behaves similar to the DBM command of the same name.

# Alpha v1.0.7
* Changes clubbing competition to only award points for Worgen, the current season race and the current frenzy race.

# Alpha v1.0.6
* Adds Frenzy mode.
* Adds version and update notice to main UI.

# Alpha v1.0.5
* Fixes direct sync comms not sending.

# Alpha v1.0.4
* Adds first time user pop-up explaining how to use the addon.

# Alpha v1.0.3
* Initial CursForge release, alpha version.

