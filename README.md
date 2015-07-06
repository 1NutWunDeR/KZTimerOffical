Alliedmodders: https://forums.alliedmods.net/showthread.php?t=223274    
KZTimer steam group: http://steamcommunity.com/groups/KZTIMER (provides KZTimer Global Version download-link, update/kreedz news, videos and more)                                                                      
**Known but unsolved problems and bugs:**
[SM] Native "PushArrayArray" reported: Failed to grow array

**Please read the following information carefully before you start asking stupid questions:**
- Download includes DHooks2 extension (https://forums.alliedmods.net/showthread.php?t=180114), Cleaner extension (https://forums.alliedmods.net/showthread.php?t=195008)  and latest GeoIP database (http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/)
- Ranking system is based on your mapcycle.txt file (keep it always up to date)
- A very large sqlite database might cause server lags (i prefer a mysql database)
- KZTimer interferes with menus of other plugins. You are able to add exceptions in addons\sourcemod\configs\kztimer\exceptions_list.txt for sourcemod commands which create menus (e.g. sm_knife)
(Fix for sm vote commands: https://forums.alliedmods.net/showpost.php?p=2265536&postcount=487)
This example works for all plugins which need an internal fix.
- Datatable warnings are harmless as long as server logging is disabled! (Cleaner extension removes these warnings)
- Do you have trouble with huge red error boxes your server? (KZ Maps)  That's probably because mapmakers forgot to add one or more model files to their map package/archive. The following plugin will fix it for the known cases:
https://www.dropbox.com/s/vtlbefh38dppseq/KZErrorBoxFixer.zip
- Supported jumpstats types: Longjump, Block Longjump (inc. fail stats), Ladderjump, Weirdjump, Bunnyhop, Drop Bunnyhop, Multi Bunnyhop
- Do you want start and stop zones instead of buttons? Here's a quick tutorial by jonitaikaponi: https://forums.alliedmods.net/showpost.php?p=2255636&postcount=456
- kz_bhop_single_touch issue: This function does not work on a few maps because the mapmaker has grouped bhop blocks (trigger_teleport) to 1 entity (e.g. bhop_areaportal_v1). KZTimer can't detect a difference between those blocks and teleports you back to the start of the affected block section as soon as you hit the second bhop plattform of this "bhop block group". You have to contact the mapmaker or just disable kz_bhop_single_touch on these maps
- those server cvars are hard coded (execuded on map start. they will be reseted if you unload kztimer):
sv_infinite_ammo 2;mp_endmatch_votenextmap 0;mp_do_warmup_period 0;mp_warmuptime 0;mp_match_can_clinch 0;mp_match_end_changelevel 1;mp_match_restart_delay 10;mp_endmatch_votenextleveltime 10;mp_endmatch_votenextmap 0;mp_halftime 0;bot_zombie 1;mp_do_warmup_period 0;mp_maxrounds 1;mp_ignore_round_win_conditions 0, 
if kz_autorespawn is enabled: mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0
else: mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0 


**About KZTimer**
- SQLite & MySQL support
- Sourcebans support
- Workshop maps support
- Console command to enable/disable KZTimer: rcon sm plugins load/unload KZTimer
- Multi-Language support (english, chinese, french, german, russian and swedish)
- KZTimer is in the final version (only bugs will be fixed from now on!)

Changelog
=======
<SPOILER>
v1.73
- added server convar "kz_double_duck" (DEFAULT: 0): on/off - Allows you to get up edges that are 32 units high or less without jumping ("0": double duck feature is only enabled if your map timer is disabled. "1": always enabled; (credits to Mehis, https://forums.alliedmods.net/showpost.php?p=2308824&postcount=4)
- added server convar "kz_team_restriction" (DEFAULT: 0): Team restriction (0 = both allowed, 1 = only ct allowed, 2 = only t allowed)
- added jump technique "countjump" (https://www.youtube.com/watch?v=tX5Iz3A1lbo) - prespeed limit: 315
- added colorchat option "red jumps only"
- added a protection against chat flooding
- added client command "!stopsound" (Stops map music)
- added client command "!specs" (prints in chat a list of all spectators)
- updated all language files
- minor bug fixes and optimizations
- updated files: all language files (sourcemod\translations), sourcemod\plugins\KZTimerGlobal.smx, sourcemod\configs\kztimer\hidden_chat_commands.txt and sourcemod\configs\kztimer\skillgroups.cfg

v1.72
- fixed the abuse of slap commands to achieve better jumpstats (thx 2 pLekz)
- fixed spectator voice communication
- improved kztimer anti-cheat system 
- added server convar "kz_min_skill_group": Minimum skill group to play on this server excluding vips and admins. Everyone below the chosen skill group gets kicked.
- added server convar "kz_slay_on_endbutton_press" (default 0): Slays other players when someone finishs the map. 
- added server convar "kz_allow_round_end" (default 0): on/off - Allows to end the current round 
- added support for Right-to-Left Languages (credits: https://forums.alliedmods.net/showthread.php?t=178279)
- updated "cfg\sourcemod\kztimer\main.cfg" and all map type configs
- optimized prestrafe values on tickrate 64 servers
- lowered default skill group limits (sourcemod\configs\kztimer\skillgroups.cfg)
- added latest versions of cleaner (+windows support), dhooks, smlib and geoip.dat to the kztimer package
- minor optimizations and bug fixes

Installation notes v1.72 if you want to upgrade kztimer from an older version: 
1) Backup your sourcemod folder and csgo/cfg/sourcemod/KZTimer.cfg
2) Make sure that your server is running sourcemod 1.7.0 or a newer version.
3) Shutdown your cs:go server
4) You have to remove all files from "csgo\addons\sourcemod\extensions" which CONTAIN "dhooks.ext.2" in their name. (Reason: KZTimer archive includes a newer dhooks version with a different file name)
5) Delete csgo/cfg/sourcemod/KZTimer.cfg
6) Extract all files from the archive to the root folder of csgo. I'd recommend to replace all files.
7) Restart your server. Done!

v1.71b
- fixed two minor bugs
- added forcesuicide on left/right script detection

v1.71
- fixed displaying of a wrong pre strafe value after players used +noclip (thx 2 haru)
- fixed map end glitch where the map does not change
- optimized strafe air-time calculation
- optimized jump sync calculation
- optimized default jump stats values
- added +left/+right script detection
- added "godlike jumps and map records only" choice for "quake sounds" player option
- added "advanced center panel" player option: Displays whether or not players have hit a crouch jump and whether or not players have released their forward key in the right moment on long jumps
- minor optimizations and bug fixes

v1.7 
- fixed a undo exploit (i won't go into detail but thx to aMo)
- added a few missing chat phrases to the russian translation file
- reworked spec list options (options: 1. counter+names...  2. counter.. 3. disabled) | default: 1 
- removed landing edge value from longjump stats... too inaccurate at the moment
- added airtime(%) to strafe stats (beta)
- added impressive jumpstats chat message, new order: perfect (blue), impressive(green), godlike (red)
- added impressive sound file "csgo/sound/quake/impressive_kz.mp3"
- renamed all jumpstats convars (i'd recommend to delete your old KZTimer.cfg. The plugin creates a new config on server restart)
- minor bug fixes
- modified files: sourcemod/plugins/KZTimerGlobal.smx, sourcemod/translations/ru/kztimer.phrases.txt

v1.69
-

v1.68
- replaced gamedata/setname.games.txt (this will fix the issue with the replay bots)
- minor bug fixes 

v1.67
- fixed func_door teleports
- fixed the abuse of a few admin fun commands to cheat times (thx 2 gargos from aus kz)
- improved weapon switch mimics of replay bots
- improved !maptop command (now it will bring up the entire map top menu)
- added takeoff speed to speedometer for kz_prestrafe 0
- added client command !hidechat (hides chat and voice icons) and !hideweapon (hides your weapon viewmodel)
- added detailed jumpstats (only green and red jumps) of observed players in spec mode

v1.66
- fixed multibhop bug (a few mbhops were not registered)
- increased the activation range for self-built climb buttons
- minor optimizations

v1.65 
- added native methods KZTimer_GetAvgTimeTp, KZTimer_GetAvgTimePro and KZTimer_GetSkillGroup
- fixed pro replay hud
- fixed the possibility to do checkpoints mid-air
- fixed closing of the checkpoint menu after joining the spectator mode
- fixed jumpstats sounds for replay bots
- fixed kz_challenge_points glitch
- fixed timer bug on kz_olympus
- blocked LAJ stats for slanting ladders
- minor bug fixes

v1.64
- fixed load/unload procedure of kztimer
- added jumpstats type: Ladder jump
- added client option !beam: Showing the trajectory of your last jump
- added client command !wr: prints in chat the record of the current map
- added client command !avg: prints in chat the average time of the current map
- added kz_dynamic_timelimit - on/off: Sets a suitable timelimit by calculating the average run time (This method requires kz_map_end 1, greater than 5 map times and a default timelimit in your server config for maps with less than 5 times)
- added failstats for block lj's
- added player rank to spec hud
- added moving direction sideways and backwards to jump types
- added unstoppable quake sound (only client & specs) for improving your time (sound/quake/unstoppable.mp3)
- updated all language files
- updated bhop_.cfg
- performance tweaks
- minor bug fixes / optimizations

v1.631
- fixed button press delay
- added missing sprites halo01.vmt and laser.vmt (this might be the reason for those error boxes)

v1.63
- fixed !hide command for replay bots
- fixed the start/stop timer bug #2 (*hidden timers*)
- fixed double team join bug (this might eliminate the floating usp bug)

v1.62.1
- removed !aclog because it caused massive server lags, sry my fault

v1.62
- fixed a start/stop timer bug @thx to HtC^w/Amber
- fixed kz_country_tag 0 + timer bug
- fixed kz_checkpoints 0 + player profile formatting bug
- fixed prestrafe bug
- added client command !aclog (prints in console the anticheat log of kztimer)
- added kz_challenge_points - Allows players to bet points on challenges (default: 1)
- updated a few language phrases
- code optimizations

v1.61
- fixed the abuse of internal color tags in chat (e.g. say {DARKRED} LOLOL {YELLOW} ^.^) - thx2 nebs and chuckles

v1.6
- renamed server cvar kz_bhop_multi_touching to kz_bhop_single_touch

v1.59
- fixed a minor multibhop bug
- fixed he/flash grenade attack spamming by adding "1 he/flash counts like 9 shots" to kz_attack_spam_protection
- increased USP weapon speed to 250.0 even if kz_prestrafe is disabled
- added auto-creation of spawn points (32 per team) on map start (spawnpoints7 plugin is not longer necessary)
- added server cvar kz_bhop_multi_touching (on/off - Allows players to touch a single bhop block more than once (0 required for global records)
Addtional information: KZTimer compares your last bhop block with the current block when "disabled". If you touch a block twice you will be teleported back to the start of the section.
This function doesn't work for maps which use 1 entity for more than 1 bhop block because these blocks share the same entity/block id. Fault of the mapper.. e.g. bhop_areaportal_v1
- new native methods: KZTimer_EmulateStartButtonPress, KZTimer_EmulateStopButtonPress and KZTimer_GetCurrentTime (These methods allow players to create start and end zones with 3rd party plugins or a 'stage addon' for KZTimer)
- removed unnecessary server cvars (cleanup): kz_recalc_top100_on_mapstart, kz_pro_mode, kz_fps_check (< 120 fps check remains), kz_multiplayer_bhop, kz_colored_chatranks and kz_checkpoints_on_bhop_plattforms (colored chat ranks and multiplayer bhop hard-coded enabled and kz_checkpoints_on_bhop_plattforms hard-coded disabled from now on)
- map chooser plugin is not longer required to run KZTimer
- updated all language files
- minor performance tweaks

v1.58
- fixed missing viewmodel after somebody uses !spec
- fixed "custom entities detected" glitch
- minor bug fixes

v1.57
- fixed player freezing after round restart
- fixed the abuse of +hook to get a further longjump
- fixed the abuse of custom entities (i won't go into detail here)
- fixed a pause bug in combination with kz_auto_timer 1
- minor bug fixes

v1.56
- fixed wrong ground speed after disabling kz_prestrafe (thx to Chuckles)
- fixed vertical jump bug on multi-bhop jumps (thx to GnagarN)
- added client command !help2 (explanation of the ranking system) 
- added sourcemod/configs/kztimer/hidden_chat_commands.txt (list of hidden chat commands -> this list was hard coded)

v1.55
- fixed redundant calculation of points for challenge winners 
- fixed displaying of the top 5 challengers with 10000+ points
- fixed weapons stripper method (knife plugins should work again) 
- fixed the viewmodel of tp and pro replay bots
- added kz_attack_spam_protection (max 40 shots, +5 new/extra shots per minute)
- added log off (prevents server crashes because of datatable warnings on servers without the cleaner extention) and sv_infinite_ammo 2 to cfg/sourcemod/kztimer/main.cfg
- added client option 'start weapon' USP/Knife
- added hookmod detection 
- added low fps check (fps_max < 120 results in a kick)  - thx to HtC^w
- minor optimizations


v1.54
- added admin command sm_refreshprofile <steamid>
- added server cvar kz_ranking_extra_points_firsttime (Gives players x (tp time = x, pro time = 2 * x) extra points for finishing a map (tp and pro) for the first time) 
- renamed kz_ranking_extra_points to kz_ranking_extra_points_improvements
- added skill group to chattag of admin's and vip's

v1.53
- fixed a minor jumpstats bug
- minor optimizations

v1.52b
- removed "steamgroup" language phrase

v1.52
- fixed chat phrase "ChallengeAborted"
- fixed timer bug on bhop_areaportal (moving plattforms)
- fixed func door bunnyhop blocks (e.g. on bhop_monsterjam)

v1.51
- added multi-language support (client command: !language)
- added four new language files (german, russian by blind, chinese by pchun, french by alouette)
- added admin command sm_resetplayerchallenges <steamid> (Resets (won) challenges for given steamid - requires z flag)
- fixed jumpstats glitch on kz_olympus
- fixed vertical jump glitch on multibhops
- minor optimizations

v1.5
- added server cvar kz_ranking_extra_points (Gives players x extra points for improving their time. That makes it a easier to rank up.)
-> YOU SHOULD execute sm_ResetExtraPoints after updating from an old kztimer version(<1.49) if u wanna give extrapoints because extra points are saved in an old database field which was used otherwise and got some wrong values
- fixed two minor bugs on player profiles
- added admin command sm_ResetExtraPoints
- fixed two jumpstats bugs
- minor optimizations

v1.49
- new optional feature: DHooks extention. Dhooks prevents a wrong mimic of replay bots after teleporting! (Old replays remain broken)
- overhauled the ranking system (you should recalculate all player ranks after updating kztimer: !kzadmin -> recalculate player ranks). 
- replaced skillgroups.txt by skillgroups.cfg. The new config file allows you to change rank limits
- added MAPPER clantag (steamid's can be added in sourcemod/configs/kztimer/mapmakers.txt)
- added skill group points to !ranks command

 
v1.48
- fixed missing team join message
- minor optimizations

v1.47
- removed global records
- fixed a bug, which allowed players to abuse pause on boosters
- fixed "player joined CT/T" chat message on player disconnect
- added further strafe hack preventions
- put some server cvars from the main.cfg back into the kztimer mapstart method because they must be set anways
- --> mp_endmatch_votenextmap 0;mp_do_warmup_period 0;mp_warmuptime 0;mp_match_can_clinch 0;mp_match_end_changelevel 1;mp_match_restart_delay 10;mp_endmatch_votenextleveltime 10;mp_endmatch_votenextmap 0;mp_halftime 0;bot_zombie 1;mp_do_warmup_period 0;mp_maxrounds 1	
- added an auto. .nav file generator but only for maps in your mapcycle.txt (execuded on plugin start)
- minor bug fixes and optimizations

v1.46
- optimized prestrafe method (tickrate 64)

v1.45
- fixed a prestrafe bug
- increased refreshing of speed/keys center panel
- re-integrated dhooks extention (should fix the wrong position of the replay bots after a teleport. old replays remain broken) - dhooks is optional!


v1.44
- changed global database login (new host ip)
- database admin commands requires root flag now

v1.43
- added <"SET NAMES  'utf8'"> (global database)
- divided kz_replay_bot_skin in kz_replay_tpbot_skin and kz_replay_probot_skin
- divided kz_replay_bot_arm_skin in kz_replay_tpbot_arm_skin and kz_replay_probot_arm_skin
- added colors tags in all center/hint messages

v1.42
- added cfg/sourcemod/kztimer/main.cfg (these server cvars were hard-coded) (don't forget to add this file. very important!)
- moved the map type configs to cfg/sourcemod/kztimer/map_types/ (u have to update your folder structure!)
- added server cvar kz_info_bot: provides information about nextmap and timeleft in his player name
- added server cvar kz_recalc_top100_on_mapstart: on/off - starts a recalculation of top 100 player ranks at map start.
- added server cvar kz_pro_mode: (!) EXPERIMENTAL (!) on/off - jump penalty, prespeed cap at 300.0, own global top, prestrafe and server settings which feels much more 
like in 1.6. This makes maps which requires multibhops (> 280 units) impossible. Also only tickrate 102.4 supported
additional info: Those were the features of the kztimer pro version
- fixed team selection bug (only windows servers were affected. MAJOR FIX)
- fixed sm_deleteproreplay command (file access was blocked through a handle)
- removed target name panel (replaced by weapon_reticle_knife_show)
- added jumpstats support for scalable ljblocks (func_movelinear entities)
- fixed a noclip bug (thx 2 AXO) 
- optimized the ranking system
- minor optimizations

v1.41
- fixed a "undo tp" bug which occurs in combination with bunnyhop plattforms (thx 2 skill vs luck)
- added "unfinished maps" to player profile
- changed global database password
- minor optimizations

v1.4
- fixed timer bug (thx 2 skill vs luck) 
- minor optimizations

v1.39
- fixed a timer bug on bhop_eazy_csgo
- fixed chat spam of remaining time if mp_timelimit is set to 0
- fixed team selection overlay glitch (windows only)

v1.38
- fixed random map end crashes (major fix)
- fixed a jumpstats glitch (thx 2 x3ro)
- added color support for kz_welcome_msg
- added "start" to adv climbers menu
- added kz_checkpoints_on_bhop_plattforms (on/off checkpoints on bhop plattforms)
- minor code optimizations
- *knife plugin updated

v1.37
- removed ljtop sql message in console
- fixed a noclip glitch (thx 2 umbrella)
- kzadmin menu optimized

v1.36
- added server cvar kz_colored_ranks (on/off - colored chat ranks)
- added client command !ranks (prints available player ranks into cha)
- minor optimizations

v1.35
- renamed default skill groups
- minor optimizations

v1.34 
- fixed surf glitch
- fixed replay bot panel

v1.33 
- code optimization (contains a lot smaller bug fixes)
- added client commands !ljblock and !flashlight
- added longjump block stats
- db table playerjumpstats3 replaces playerjumpstats2 

--> how to port jumpstats data from the old table into the new table: 
- install the new version of kztimer
- start the server and stop it then again (kztimer  creates automatically the new db table playerjumpstats3)
- use navicat lite (or some other db front end) and export the data from playerjumpstats2 into a .txt file. (format doenst matter)
- Afterwards u have to import the file in playerjumpstats3 --> DONE


v1.32 
- fixed a tp glitch (thx 2 x3ro)
- optimized wall touch method to prevent fail detections (jumpstats)
- added a chat message for players if they missed their personal best 
- minor optimizations

v1.31 
- fixed dropbhop glitch
- fixed wrong rank promotion after earning points
- fixed a minor jumpstats glitch
- changed global database password

v1.30 
- changed replay bot names: -TYPE- REPLAY BOT -NAME- (-TIME-)
- adjusted the replay panel
- removed db_deleteInvalidGlobalEntries from MapEnd method (*watchdog*)
- fixed some minor issues for workshop maps
- -> fixed: Exception list is not loaded.
- -> fixed: Timer freezes, gets stuck and when you stop the time it sometimes takes 10 seconds to register.
</SPOILER>
