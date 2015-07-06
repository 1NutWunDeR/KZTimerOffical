#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike>
#include <button>
#include <entity>
#include <setname>
#include <smlib>
#include <KZTimer>
#include <geoip>
#include <colors>
#include <basecomm>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <dhooks>
#include <hgr>
#include <sourcebans>
#include <mapchooser>

#define VERSION "1.73"
#define PLUGIN_VERSION 173
#define ADMIN_LEVEL ADMFLAG_UNBAN
#define ADMIN_LEVEL2 ADMFLAG_ROOT
#define MYSQL 0
#define SQLITE 1
#define WHITE 0x01
#define DARKRED 0x02
#define PURPLE 0x03
#define GREEN 0x04
#define MOSSGREEN 0x05
#define LIMEGREEN 0x06
#define RED 0x07
#define GRAY 0x08
#define YELLOW 0x09
#define DARKGREY 0x0A
#define BLUE 0x0B
#define DARKBLUE 0x0C
#define LIGHTBLUE 0x0D
#define PINK 0x0E
#define LIGHTRED 0x0F
#define QUOTE 0x22
#define PERCENT 0x25
#define CPLIMIT 50 
#define MAX_PR_PLAYERS 1066
#define MAX_BHOPBLOCKS 2048
#define BLOCK_TELEPORT 0.05	
#define BLOCK_COOLDOWN 0.1
#define HIDE_RADAR (1 << 12)
#define HIDE_CHAT ( 1<<7 )
#define SF_BUTTON_DONTMOVE (1<<0)		
#define SF_BUTTON_TOUCH_ACTIVATES (1<<8)	
#define SF_DOOR_PTOUCH (1<<10)		
#define BM_MAGIC 0xBAADF00D
#define BINARY_FORMAT_VERSION 0x01
#define ADDITIONAL_FIELD_TELEPORTED_ORIGIN (1<<0)
#define ADDITIONAL_FIELD_TELEPORTED_ANGLES (1<<1)
#define ADDITIONAL_FIELD_TELEPORTED_VELOCITY (1<<2)
#define FRAME_INFO_SIZE 15
#define FRAME_INFO_SIZE_V1 14
#define AT_SIZE 10
#define ORIGIN_SNAPSHOT_INTERVAL 150
#define FILE_HEADER_LENGTH 74
#define SOURCEBANS_AVAILABLE()	(GetFeatureStatus(FeatureType_Native, "SBBanPlayer") == FeatureStatus_Available)

enum FrameInfo 
{
	playerButtons = 0,
	playerImpulse,
	Float:actualVelocity[3],
	Float:predictedVelocity[3],
	Float:predictedAngles[2], 
	CSWeaponID:newWeapon,
	playerSubtype,
	playerSeed,
	additionalFields, 
	pause, 
}

enum AdditionalTeleport 
{
	Float:atOrigin[3],
	Float:atAngles[3],
	Float:atVelocity[3],
	atFlags
}

enum FileHeader 
{
	FH_binaryFormatVersion = 0,
	String:FH_Time[32],
	String:FH_Playername[32],
	FH_Checkpoints,
	FH_tickCount,
	Float:FH_initialPosition[3],
	Float:FH_initialAngles[3],
	Handle:FH_frames
}

enum VelocityOverride
{
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
}

enum EJoinTeamReason
{
	k_OneTeamChange=0,
	k_TeamsFull=1,
	k_TTeamFull=2,
	k_CTTeamFull=3
}

// kztimer decl.
new g_DbType;
new g_ReplayRecordTps;
new Handle:g_hStaminaLandCost = INVALID_HANDLE;
new Handle:g_hMaxSpeed = INVALID_HANDLE;
new Handle:g_hWaterAccelerate = INVALID_HANDLE;
new Handle:g_hStaminaJumpCost = INVALID_HANDLE;
new Handle:g_hGravity = INVALID_HANDLE;
new Handle:g_hAirAccelerate = INVALID_HANDLE;
new Handle:g_hFriction = INVALID_HANDLE;
new Handle:g_hAccelerate = INVALID_HANDLE;
new Handle:g_hMaxVelocity = INVALID_HANDLE;
new Handle:g_hCheats = INVALID_HANDLE;
new Handle:g_hMaxRounds = INVALID_HANDLE;
new Handle:g_hEnableBunnyhoping = INVALID_HANDLE;
new Handle:g_hTeleport = INVALID_HANDLE;
new Handle:g_hMainMenu = INVALID_HANDLE;
new Handle:g_hSDK_Touch = INVALID_HANDLE;
new Handle:g_hAdminMenu = INVALID_HANDLE;
new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_hDb = INVALID_HANDLE;
new Handle:hStartPress = INVALID_HANDLE;
new Handle:hEndPress = INVALID_HANDLE;
new Handle:g_hLangMenu = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;
new Handle:g_hRecording[MAXPLAYERS+1];
new Handle:g_hLoadedRecordsAdditionalTeleport = INVALID_HANDLE;
new Handle:g_hBotMimicsRecord[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new Handle:g_hP2PRed[MAXPLAYERS+1] = { INVALID_HANDLE,... };
new Handle:g_hP2PGreen[MAXPLAYERS+1] = { INVALID_HANDLE,... };
new Handle:g_hRecordingAdditionalTeleport[MAXPLAYERS+1];
new Handle:g_hclimbersmenu[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hTopJumpersMenu[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hWelcomeMsg = INVALID_HANDLE;
new String:g_sWelcomeMsg[512];  
new Handle:g_hReplayBotPlayerModel = INVALID_HANDLE;
new String:g_sReplayBotPlayerModel[256];  
new Handle:g_hReplayBotArmModel = INVALID_HANDLE;
new String:g_sReplayBotArmModel[256];  
new Handle:g_hReplayBotPlayerModel2 = INVALID_HANDLE;
new String:g_sReplayBotPlayerModel2[256];  
new Handle:g_hReplayBotArmModel2 = INVALID_HANDLE;
new String:g_sReplayBotArmModel2[256];  
new Handle:g_hPlayerModel = INVALID_HANDLE;
new String:g_sPlayerModel[256];  
new Handle:g_hArmModel = INVALID_HANDLE;
new String:g_sArmModel[256];  
new Handle:g_hdist_good_weird = INVALID_HANDLE;
new Float:g_dist_min_weird;
new Handle:g_hdist_impressive_weird = INVALID_HANDLE;
new Float:g_dist_impressive_weird;
new Handle:g_hdist_perfect_weird = INVALID_HANDLE;
new Float:g_dist_perfect_weird;
new Handle:g_hdist_godlike_weird = INVALID_HANDLE;
new Float:g_dist_god_weird;
new Handle:g_hdist_good_dropbhop = INVALID_HANDLE;
new Float:g_dist_min_dropbhop;
new Handle:g_hdist_impressive_dropbhop = INVALID_HANDLE;
new Float:g_dist_impressive_dropbhop;
new Handle:g_hdist_perfect_dropbhop = INVALID_HANDLE;
new Float:g_dist_perfect_dropbhop;
new Handle:g_hdist_godlike_dropbhop = INVALID_HANDLE;
new Float:g_dist_god_dropbhop;
new Handle:g_hdist_good_bhop = INVALID_HANDLE;
new Float:g_dist_min_bhop;
new Handle:g_hdist_impressive_bhop = INVALID_HANDLE;
new Float:g_dist_impressive_bhop;
new Handle:g_hdist_perfect_bhop = INVALID_HANDLE;
new Float:g_dist_perfect_bhop;
new Handle:g_hdist_godlike_bhop = INVALID_HANDLE;
new Float:g_dist_god_bhop;
new Handle:g_hdist_good_multibhop = INVALID_HANDLE;
new Float:g_dist_min_multibhop;
new Handle:g_hdist_impressive_multibhop = INVALID_HANDLE;
new Float:g_dist_impressive_multibhop;
new Handle:g_hdist_perfect_multibhop = INVALID_HANDLE;
new Float:g_dist_perfect_multibhop;
new Handle:g_hdist_godlike_multibhop = INVALID_HANDLE;
new Float:g_dist_god_multibhop;
new Handle:g_hdist_good_ladder = INVALID_HANDLE;
new Float:g_dist_min_ladder;
new Handle:g_hdist_perfect_ladder = INVALID_HANDLE;
new Float:g_dist_perfect_ladder;
new Handle:g_hdist_impressive_ladder = INVALID_HANDLE;
new Float:g_dist_impressive_ladder;
new Handle:g_hdist_godlike_ladder = INVALID_HANDLE;
new Float:g_dist_god_ladder;
new Handle:g_hBanDuration = INVALID_HANDLE;
new Float:g_fBanDuration;
new Handle:g_hdist_good_lj = INVALID_HANDLE;
new Float:g_dist_min_lj;
new Handle:g_hdist_impressive_lj = INVALID_HANDLE;
new Float:g_dist_impressive_lj;
new Handle:g_hdist_perfect_lj = INVALID_HANDLE;
new Float:g_dist_perfect_lj;
new Handle:g_hdist_godlike_lj = INVALID_HANDLE;
new Float:g_dist_god_lj;
new Handle:g_hdist_good_countjump = INVALID_HANDLE;
new Float:g_dist_min_countjump;
new Handle:g_hdist_impressive_countjump = INVALID_HANDLE;
new Float:g_dist_impressive_countjump;
new Handle:g_hdist_perfect_countjump = INVALID_HANDLE;
new Float:g_dist_perfect_countjump;
new Handle:g_hdist_godlike_countjump = INVALID_HANDLE;
new Float:g_dist_god_countjump;
new Handle:g_hBhopSpeedCap = INVALID_HANDLE;
new Float:g_fBhopSpeedCap;
new Handle:g_hMaxBhopPreSpeed = INVALID_HANDLE;
new Float:g_fMaxBhopPreSpeed;
new Handle:g_hcvarRestore = INVALID_HANDLE;
new bool:g_bRestore;
new Handle:g_hAllowRoundEndCvar = INVALID_HANDLE;
new bool:g_bAllowRoundEndCvar;
new Handle:g_hNoClipS = INVALID_HANDLE;
new bool:g_bNoClipS;
new Handle:g_hReplayBot = INVALID_HANDLE;
new bool:g_bReplayBot;
new Handle:g_hAutoBan = INVALID_HANDLE;
new bool:g_bAutoBan;
new Handle:g_hSlayPlayers = INVALID_HANDLE;
new bool:g_bSlayPlayers;
new Handle:g_hDoubleDuckCvar = INVALID_HANDLE;
new bool:g_bDoubleDuckCvar;
new Handle:g_hPauseServerside = INVALID_HANDLE;
new bool:g_bPauseServerside;
new Handle:g_hChallengePoints = INVALID_HANDLE;
new bool:g_bChallengePoints;
new Handle:g_hAutoBhopConVar = INVALID_HANDLE;
new bool:g_bAutoBhopConVar;
new bool:g_bAutoBhop;
new Handle:g_hVipClantag = INVALID_HANDLE;
new bool:g_bVipClantag;
new Handle:g_hDynamicTimelimit = INVALID_HANDLE;
new bool:g_bDynamicTimelimit;
new Handle:g_hAdminClantag = INVALID_HANDLE;
new bool:g_bAdminClantag;
new Handle:g_hConnectMsg = INVALID_HANDLE;
new bool:g_bConnectMsg;
new Handle:g_hRadioCommands = INVALID_HANDLE;
new bool:g_bRadioCommands;
new Handle:g_hInfoBot = INVALID_HANDLE;
new bool:g_bInfoBot;
new Handle:g_hAttackSpamProtection = INVALID_HANDLE;
new bool:g_bAttackSpamProtection;
new Handle:g_hGoToServer = INVALID_HANDLE;
new bool:g_bGoToServer;
new Handle:g_hPlayerSkinChange = INVALID_HANDLE;
new bool:g_bPlayerSkinChange;
new Handle:g_hJumpStats = INVALID_HANDLE;
new bool:g_bJumpStats;
new Handle:g_hCountry = INVALID_HANDLE;
new bool:g_bCountry;
new Handle:g_hAutoRespawn = INVALID_HANDLE;
new bool:g_bAutoRespawn;
new Handle:g_hAllowCheckpoints = INVALID_HANDLE;
new bool:g_bAllowCheckpoints;
new Handle:g_hSingleTouch = INVALID_HANDLE;
new bool:g_bSingleTouch;
new Handle:g_hPointSystem = INVALID_HANDLE;
new bool:g_bPointSystem;
new Handle:g_hCleanWeapons = INVALID_HANDLE;
new bool:g_bCleanWeapons;
new Handle:g_hcvargodmode = INVALID_HANDLE;
new bool:g_bAutoTimer;
new Handle:g_hAutoTimer = INVALID_HANDLE;
new bool:g_bgodmode;
new Handle:g_hEnforcer = INVALID_HANDLE;
new bool:g_bEnforcer;
new Handle:g_hPreStrafe = INVALID_HANDLE;
new bool:g_bPreStrafe;
new Handle:g_hMapEnd = INVALID_HANDLE;
new bool:g_bMapEnd;
new Handle:g_hAutohealing_Hp = INVALID_HANDLE;
new g_Autohealing_Hp;
new Handle:g_hTeam_Restriction = INVALID_HANDLE;
new g_Team_Restriction;
new Handle:g_hExtraPoints = INVALID_HANDLE;
new g_ExtraPoints;
new Handle:g_hExtraPoints2 = INVALID_HANDLE;
new g_ExtraPoints2;
new Handle:g_hMinSkillGroup = INVALID_HANDLE;
new g_MinSkillGroup;
new Handle:g_hReplayBotProColor = INVALID_HANDLE;
new Handle:g_hReplayBotTpColor = INVALID_HANDLE;
new Float:g_fMapStartTime;
new Float:g_fBhopDoorSp[300];
new Float:g_fSpawnTime[MAXPLAYERS+1];
new Float:g_fvMeasurePos[MAXPLAYERS+1][2][3];
new Float:g_fafAvgJumps[MAXPLAYERS+1] = {1.0, ...};
new Float:g_fafAvgSpeed[MAXPLAYERS+1] = {250.0, ...};
new Float:g_favVEL[MAXPLAYERS+1][3];
new Float:g_fafAvgPerfJumps[MAXPLAYERS+1] = {0.3333, ...};
new Float:g_fLastJump[MAXPLAYERS+1] = {0.0, ...};
new Float:g_fBlockHeight[MAXPLAYERS + 1];
new Float:g_fEdgeVector[MAXPLAYERS + 1][3];
new Float:g_fEdgeDistJumpOff[MAXPLAYERS + 1];
new Float:g_fEdgePoint1[MAXPLAYERS + 1][3];
new Float:g_fEdgePoint2[MAXPLAYERS + 1][3];
new Float:g_fOriginBlock[MAXPLAYERS + 1][2][3];
new Float:g_fDestBlock[MAXPLAYERS + 1][2][3];
new Float:g_fStartTime[MAXPLAYERS+1];
new Float:g_fFinalTime[MAXPLAYERS+1];
new Float:g_fPauseTime[MAXPLAYERS+1];
new Float:g_fLastTimeNoClipUsed[MAXPLAYERS+1];
new Float:g_fLastOverlay[MAXPLAYERS+1];
new Float:g_fStartPauseTime[MAXPLAYERS+1];
new Float:g_fPlayerCordsLastPosition[MAXPLAYERS+1][3];
new Float:g_fPlayerLastTime[MAXPLAYERS+1];
new Float:g_fPlayerAnglesLastPosition[MAXPLAYERS+1][3];
new Float:g_fPlayerCords[MAXPLAYERS+1][CPLIMIT][3];
new Float:g_fPlayerAngles[MAXPLAYERS+1][CPLIMIT][3];
new Float:g_fPlayerCordsRestart[MAXPLAYERS+1][3]; 
new Float:g_fPlayerAnglesRestart[MAXPLAYERS+1][3]; 
new Float:g_fPlayerCordsRestore[MAXPLAYERS+1][3];
new Float:g_fPlayerAnglesRestore[MAXPLAYERS+1][3];
new Float:g_fPlayerCordsUndoTp[MAXPLAYERS+1][3];
new Float:g_fPlayerAnglesUndoTp[MAXPLAYERS+1][3];
new Float:g_fLastPositionOnGround[MAXPLAYERS+1][3];
new Float:g_fPersonalRecord[MAXPLAYERS+1];
new Float:g_fPersonalRecordPro[MAXPLAYERS+1];
new Float:g_fCurrentRunTime[MAXPLAYERS+1];
new Float:g_fVelocityModifierLastChange[MAXPLAYERS+1];
new Float:g_fLastTimeButtonSound[MAXPLAYERS+1];
new Float:g_fLastChatMsg[MAXPLAYERS+1];
new Float:g_fPlayerConnectedTime[MAXPLAYERS+1];
new Float:g_fStartCommandUsed_LastTime[MAXPLAYERS+1];
new Float:g_fProfileMenuLastQuery[MAXPLAYERS+1];
new Float:g_favg_protime;
new Float:g_favg_tptime;
new Float:g_fSpawnpointOrigin[3];
new Float:g_fSpawnpointAngle[3];
new Float:g_js_fJump_JumpOff_Pos[MAXPLAYERS+1][3];
new Float:g_js_fJump_Landing_Pos[MAXPLAYERS+1][3];
new Float:g_js_fJump_JumpOff_PosLastHeight[MAXPLAYERS+1];
new Float:g_js_fJump_DistanceX[MAXPLAYERS+1];
new Float:g_js_fJump_DistanceZ[MAXPLAYERS+1];
new Float:g_js_fJump_Distance[MAXPLAYERS+1];
new Float:g_js_fPreStrafe[MAXPLAYERS+1];
new Float:g_js_fDropped_Units[MAXPLAYERS+1];
new Float:g_js_fMax_Speed[MAXPLAYERS+1];
new Float:g_js_fMax_Speed_Final[MAXPLAYERS +1];
new Float:g_js_fMax_Height[MAXPLAYERS+1];
new Float:g_js_AvgLadderSpeed[MAXPLAYERS+1];
new Float:g_js_fLast_Jump_Time[MAXPLAYERS+1];
new Float:g_js_Good_Sync_Frames[MAXPLAYERS+1];
new Float:g_js_Sync_Frames[MAXPLAYERS+1];
new Float:g_js_Strafe_Air_Time[MAXPLAYERS+1][100];
new Float:g_js_Strafe_Good_Sync[MAXPLAYERS+1][100];
new Float:g_js_Strafe_Frames[MAXPLAYERS+1][100];
new Float:g_js_Strafe_Gained[MAXPLAYERS+1][100];
new Float:g_js_Strafe_Max_Speed[MAXPLAYERS+1][100];
new Float:g_js_Strafe_Lost[MAXPLAYERS+1][100];
new Float:g_js_fPersonal_CJ_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_Wj_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_DropBhop_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_Bhop_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_MultiBhop_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_Lj_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_LadderJump_Record[MAX_PR_PLAYERS]=-1.0;
new Float:g_js_fPersonal_LjBlockRecord_Dist[MAX_PR_PLAYERS]=-1.0;
new Float:g_fLastSpeed[MAXPLAYERS+1];
new Float:g_fJumpButtonLastTimeUsed[MAXPLAYERS+1];
new Float:g_fCrouchButtonLastTimeUsed[MAXPLAYERS+1];
new Float:g_fFailedLandingPos[MAXPLAYERS+1][3];
new Float:g_fAirTime[MAXPLAYERS+1];
new Float:g_fLastTimeDoubleDucked[MAXPLAYERS+1];
new Float:g_fJumpOffTime[MAXPLAYERS+1];
new Float:g_fLandingTime[MAXPLAYERS+1];
new Float:g_fLastUndo[MAXPLAYERS +1];
new Float:g_flastHeight[MAXPLAYERS +1];
new Float:g_fInitialPosition[MAXPLAYERS+1][3];
new Float:g_fInitialAngles[MAXPLAYERS+1][3];
new Float:g_PrestrafeVelocity[MAXPLAYERS+1];
new Float:g_fChallenge_RequestTime[MAXPLAYERS+1];
new Float:g_fSpawnPosition[MAXPLAYERS+1][3]; 
new Float:g_fLastPosition[MAXPLAYERS + 1][3];
new Float:g_fMovingDirection[MAXPLAYERS+1];
new Float:g_fLastAngles[MAXPLAYERS + 1][3];
new Float:g_fLastTimeBhopBlock[MAXPLAYERS+1];
new Float:g_js_fLadderDirection[MAXPLAYERS+1];
new Float:g_fRecordTime;
new Float:g_flastTimeSpecsChecked;
new Float:g_fRecordTimePro;
new Float:g_fStartButtonPos[3];
new Float:g_fEndButtonPos[3];
new Float:g_pr_finishedmaps_tp_perc[MAX_PR_PLAYERS]; 
new Float:g_pr_finishedmaps_pro_perc[MAX_PR_PLAYERS]; 
new MoveType:g_LastMoveType[MAXPLAYERS+1];
new bool:g_bLateLoaded = false;
new bool:g_bCountJump[MAXPLAYERS + 1];
new bool:g_bRoundEnd;
new bool:g_bFirstStartButtonPush;
new bool:g_bFirstEndButtonPush;
new bool:g_bProReplay;
new bool:g_bTpReplay;
new bool:g_pr_RankingRecalc_InProgress;
new bool:g_bAntiCheat;
new bool:g_bHookMod;
new bool:g_bMapChooser;
new bool:g_bUseCPrefs;
new bool:g_bTop100Refresh;
new bool:g_bManualRecalc; 
new bool:g_bNewTpBot;
new bool:g_bNewProBot; 
new bool:g_bLoaded[MAXPLAYERS+1];
new bool:g_bLadderJump[MAXPLAYERS+1];
new bool:g_bFirstButtonTouch[MAXPLAYERS+1];
new bool:g_bLJBlock[MAXPLAYERS + 1];
new bool:g_js_block_lj_jumpoff_pos[MAXPLAYERS + 1];
new bool:g_bClientOwnReason[MAXPLAYERS + 1];
new bool:g_js_block_lj_valid[MAXPLAYERS + 1];
new bool:g_js_bFuncMoveLinear[MAXPLAYERS+1];
new bool:g_bUndoTimer[MAXPLAYERS+1];
new bool:g_bValidTeleport[MAXPLAYERS+1];
new bool:g_pr_Calculating[MAXPLAYERS+1];
new bool:g_bChallenge_Checkpoints[MAXPLAYERS+1];
new bool:g_bTopMenuOpen[MAXPLAYERS+1]; 
new bool:g_bMapMenuOpen[MAXPLAYERS+1]; 
new bool:g_bNoClipUsed[MAXPLAYERS+1];
new bool:g_bMenuOpen[MAXPLAYERS+1];
new bool:g_bRespawnAtTimer[MAXPLAYERS+1];
new bool:g_bPause[MAXPLAYERS+1];
new bool:g_bPauseWasActivated[MAXPLAYERS+1];
new bool:g_bOverlay[MAXPLAYERS+1];
new bool:g_bLastButtonJump[MAXPLAYERS+1];
new bool:g_js_bPlayerJumped[MAXPLAYERS+1];
new bool:g_js_bPerfJumpOff[MAXPLAYERS+1];
new bool:g_js_bPerfJumpOff2[MAXPLAYERS+1];
new bool:g_bSpectate[MAXPLAYERS+1];
new bool:g_bTimeractivated[MAXPLAYERS+1];
new bool:g_bFirstTeamJoin[MAXPLAYERS+1];
new bool:g_bFirstSpawn[MAXPLAYERS+1];
new bool:g_bMissedTpBest[MAXPLAYERS+1];
new bool:g_bMissedProBest[MAXPLAYERS+1];
new bool:g_bRestorePosition[MAXPLAYERS+1]; 
new bool:g_bRestorePositionMsg[MAXPLAYERS+1]; 
new bool:g_bClimbersMenuOpen[MAXPLAYERS+1];  
new bool:g_bNoClip[MAXPLAYERS+1];
new bool:g_bOnBhopPlattform[MAXPLAYERS+1]; 
new bool:g_bMapFinished[MAXPLAYERS+1]; 
new bool:g_bRespawnPosition[MAXPLAYERS+1]; 
new bool:g_bKickStatus[MAXPLAYERS+1]; 
new bool:g_bUndo[MAXPLAYERS+1];
new bool:g_bTouchedBooster[MAXPLAYERS+1]; 
new bool:g_bHyperscroll[MAXPLAYERS+1]; 
new bool:g_bProfileRecalc[MAX_PR_PLAYERS];
new bool:g_bProfileSelected[MAXPLAYERS+1]; 
new bool:g_bSelectProfile[MAXPLAYERS+1]; 
new bool:g_bClimbersMenuwasOpen[MAXPLAYERS+1]; 
new bool:g_js_bDropJump[MAXPLAYERS+1];    
new bool:g_js_bInvalidGround[MAXPLAYERS+1];
new bool:g_bChallenge_Abort[MAXPLAYERS+1];
new bool:g_bLastInvalidGround[MAXPLAYERS+1];
new bool:g_bValidTeleportCall[MAXPLAYERS+1];
new bool:g_bMapRankToChat[MAXPLAYERS+1];
new bool:g_bChallenge[MAXPLAYERS+1];
new bool:g_js_bBhop[MAXPLAYERS+1];
new bool:g_bChallenge_Request[MAXPLAYERS+1];
new bool:g_js_Strafing_AW[MAXPLAYERS+1];
new bool:g_js_Strafing_SD[MAXPLAYERS+1];
new bool:g_pr_showmsg[MAXPLAYERS+1];
new bool:g_CMOpen[MAXPLAYERS+1];
new bool:g_bBeam[MAXPLAYERS+1];
new bool:g_bRecalcRankInProgess[MAXPLAYERS+1];
new g_ColorChat[MAXPLAYERS+1];
new bool:g_bLanguageSelected[MAXPLAYERS+1];
new bool:g_bNewReplay[MAXPLAYERS+1];
new bool:g_bPositionRestored[MAXPLAYERS+1];
new bool:g_bInfoPanel[MAXPLAYERS+1];
new bool:g_bClimbersMenuSounds[MAXPLAYERS+1];
new g_EnableQuakeSounds[MAXPLAYERS+1];
new bool:g_bShowNames[MAXPLAYERS+1]; 
new bool:g_bSpecInfo[MAXPLAYERS+1];
new bool:g_bStrafeSync[MAXPLAYERS+1];
new bool:g_bSaving[MAXPLAYERS+1];
new bool:g_bStartWithUsp[MAXPLAYERS+1];
new bool:g_bGoToClient[MAXPLAYERS+1]; 
new bool:g_bShowTime[MAXPLAYERS+1]; 
new bool:g_bHide[MAXPLAYERS+1];   
new bool:g_bSayHook[MAXPLAYERS+1]; 
new g_ShowSpecs[MAXPLAYERS+1]; 
new bool:g_bFlagged[MAXPLAYERS+1];
new bool:g_bMeasurePosSet[MAXPLAYERS+1][2];
new bool:g_bCPTextMessage[MAXPLAYERS+1]; 
new bool:g_bAdvancedClimbersMenu[MAXPLAYERS+1];
new bool:g_bAutoBhopClient[MAXPLAYERS+1];
new bool:g_bJumpBeam[MAXPLAYERS+1];
new bool:g_bHideChat[MAXPLAYERS+1];
new bool:g_bViewModel[MAXPLAYERS+1];
new bool:g_bAdvInfoPanel[MAXPLAYERS+1];
new bool:g_borg_AdvInfoPanel[MAXPLAYERS+1];
new bool:g_borg_ViewModel[MAXPLAYERS+1];
new bool:g_borg_HideChat[MAXPLAYERS+1];
new bool:g_borg_JumpBeam[MAXPLAYERS+1];
new bool:g_borg_StartWithUsp[MAXPLAYERS+1];
new g_org_ColorChat[MAXPLAYERS+1];
new bool:g_borg_InfoPanel[MAXPLAYERS+1];
new bool:g_borg_ClimbersMenuSounds[MAXPLAYERS+1];
new g_org_EnableQuakeSounds[MAXPLAYERS+1];
new bool:g_borg_ShowNames[MAXPLAYERS+1]; 
new bool:g_borg_StrafeSync[MAXPLAYERS+1];
new bool:g_borg_GoToClient[MAXPLAYERS+1]; 
new bool:g_borg_ShowTime[MAXPLAYERS+1]; 
new bool:g_borg_Hide[MAXPLAYERS+1]; 
new g_org_ShowSpecs[MAXPLAYERS+1]; 
new bool:g_borg_CPTextMessage[MAXPLAYERS+1]; 
new bool:g_borg_AdvancedClimbersMenu[MAXPLAYERS+1];
new bool:g_borg_AutoBhopClient[MAXPLAYERS+1];
new bool:g_bOnGround[MAXPLAYERS+1];
new bool:g_bLegitButtons[MAXPLAYERS+1];
new bool:g_bPrestrafeTooHigh[MAXPLAYERS+1];
new g_Beam[3];
new g_BhopMultipleList[MAX_BHOPBLOCKS];
new g_BhopMultipleTeleList[MAX_BHOPBLOCKS];
new g_BhopMultipleCount;
new g_BhopDoorList[MAX_BHOPBLOCKS];
new g_BhopDoorTeleList[MAX_BHOPBLOCKS];
new g_BhopDoorCount;
new g_BhopButtonList[MAX_BHOPBLOCKS];
new g_BhopButtonTeleList[MAX_BHOPBLOCKS];
new g_BhopButtonCount;
new g_Offs_vecOrigin = -1;
new g_Offs_vecMins = -1;
new g_Offs_vecMaxs = -1;
new g_DoorOffs_vecPosition1 = -1;
new g_DoorOffs_vecPosition2 = -1;
new g_DoorOffs_flSpeed = -1;
new g_DoorOffs_spawnflags = -1;
new g_DoorOffs_NoiseMoving = -1;
new g_DoorOffs_sLockedSound = -1;
new g_DoorOffs_bLocked = -1;
new g_ButtonOffs_vecPosition1 = -1;
new g_ButtonOffs_vecPosition2 = -1;
new g_ButtonOffs_flSpeed = -1;
new g_ButtonOffs_spawnflags = -1;
new g_TSpawns=-1;
new g_CTSpawns=-1;
new g_ownerOffset;
new g_ragdolls = -1;
new g_Server_Tickrate;
new g_MapTimesCountPro;
new g_MapTimesCountTp;
new g_ProBot=-1;
new g_TpBot=-1;
new g_InfoBot=-1;
new g_ReplayBotTpColor[3];
new g_ReplayBotProColor[3];
new g_pr_Recalc_ClientID = 0;
new g_pr_Recalc_AdminID=-1; 
new g_pr_AllPlayers;
new g_pr_RankedPlayers;
new g_pr_MapCount;
new g_pr_MapCountTp;
new g_pr_rank_Percentage[9];
new g_pr_PointUnit;
new g_pr_TableRowCount;
new g_pr_points[MAX_PR_PLAYERS];
new g_pr_maprecords_row_counter[MAX_PR_PLAYERS];
new g_pr_maprecords_row_count[MAX_PR_PLAYERS];
new g_pr_oldpoints[MAX_PR_PLAYERS];  
new g_pr_multiplier[MAX_PR_PLAYERS]; 
new g_pr_finishedmaps_tp[MAX_PR_PLAYERS]; 
new g_pr_finishedmaps_pro[MAX_PR_PLAYERS];
new g_js_Personal_LjBlock_Record[MAX_PR_PLAYERS]=-1;
new g_js_BhopRank[MAX_PR_PLAYERS];
new g_js_MultiBhopRank[MAX_PR_PLAYERS];
new g_js_LjRank[MAX_PR_PLAYERS];
new g_js_LadderJumpRank[MAX_PR_PLAYERS];
new g_js_LjBlockRank[MAX_PR_PLAYERS];
new g_js_DropBhopRank[MAX_PR_PLAYERS];
new g_js_WjRank[MAX_PR_PLAYERS];
new g_js_CJRank[MAX_PR_PLAYERS];
new g_js_LadderDirectionCounter[MAXPLAYERS+1];
new g_js_TotalGroundFrames[MAXPLAYERS+1];
new g_js_Sync_Final[MAXPLAYERS+1];
new g_js_GroundFrames[MAXPLAYERS+1];
new g_js_LadderFrames[MAXPLAYERS+1];
new g_js_StrafeCount[MAXPLAYERS+1];
new g_js_Strafes_Final[MAXPLAYERS+1];
new g_js_GODLIKE_Count[MAXPLAYERS+1]; 
new g_js_MultiBhop_Count[MAXPLAYERS+1];
new g_js_Last_Ground_Frames[MAXPLAYERS+1];
new g_js_DuckCounter[MAXPLAYERS+1];
new g_PlayerRank[MAXPLAYERS+1];
new g_Skillgroup[MAXPLAYERS+1];
new g_LastGroundEnt[MAXPLAYERS+1];
new g_SelectedTeam[MAXPLAYERS+1];
new g_BotMimicRecordTickCount[MAXPLAYERS+1] = {0,...};
new g_BotActiveWeapon[MAXPLAYERS+1] = {-1,...};
new g_CurrentAdditionalTeleportIndex[MAXPLAYERS+1];
new g_RecordedTicks[MAXPLAYERS+1];
new g_RecordPreviousWeapon[MAXPLAYERS+1];
new g_OriginSnapshotInterval[MAXPLAYERS+1];
new g_BotMimicTick[MAXPLAYERS+1] = {0,...};
new g_BlockDist[MAXPLAYERS + 1];
new g_AttackCounter[MAXPLAYERS + 1];
new g_aiJumps[MAXPLAYERS+1] = {0, ...};
new g_aaiLastJumps[MAXPLAYERS+1][30];
new g_NumberJumpsAbove[MAXPLAYERS+1];
new g_MenuLevel[MAXPLAYERS+1];
new g_Challenge_Bet[MAXPLAYERS+1];
new g_MapRankTp[MAXPLAYERS+1];
new g_MapRankPro[MAXPLAYERS+1];
new g_OldMapRankPro[MAXPLAYERS+1];
new g_Time_Type[MAXPLAYERS+1];
new g_Sound_Type[MAXPLAYERS+1];
new g_TpRecordCount[MAXPLAYERS+1];
new g_ProRecordCount[MAXPLAYERS+1];
new g_FinishingType[MAXPLAYERS+1];
new g_OldMapRankTp[MAXPLAYERS+1];
new g_Challenge_WinRatio[MAX_PR_PLAYERS];
new g_CountdownTime[MAXPLAYERS+1];
new g_Challenge_PointsRatio[MAX_PR_PLAYERS];
new g_CurrentCp[MAXPLAYERS+1];
new g_CounterCp[MAXPLAYERS+1];
new g_OverallCp[MAXPLAYERS+1];
new g_OverallTp[MAXPLAYERS+1];
new g_fps_max[MAXPLAYERS+1];
new g_SpecTarget[MAXPLAYERS+1];
new g_SpecTarget2[MAXPLAYERS+1];//test
new g_PrestrafeFrameCounter[MAXPLAYERS+1];
new g_LastButton[MAXPLAYERS + 1];
new g_CurrentButton[MAXPLAYERS+1];
new g_MVPStars[MAXPLAYERS+1];
new g_Tp_Final[MAXPLAYERS+1];
new g_JumpCheck1[MAXPLAYERS+1];
new g_JumpCheck2[MAXPLAYERS+1];
new g_AdminMenuLastPage[MAXPLAYERS+1];
new g_OptionsMenuLastPage[MAXPLAYERS+1];
new String:g_js_szLastJumpDistance[MAXPLAYERS+1][256];
new String:g_pr_chat_coloredrank[MAXPLAYERS+1][32];
new String:g_pr_rankname[MAXPLAYERS+1][32];  
new String:g_pr_szrank[MAXPLAYERS+1][512];  
new String:g_pr_szName[MAX_PR_PLAYERS][64];  
new String:g_pr_szSteamID[MAX_PR_PLAYERS][32]; 
new String:g_szMapPrefix[2][32]; 
new String:g_szMapmakers[100][32];  
new String:g_szReplayName[128];  
new String:g_szReplayTime[128]; 
new String:g_szReplayNameTp[128];  
new String:g_szReplayTimeTp[128]; 
new String:g_szChallenge_OpponentID[MAXPLAYERS+1][32]; 
new String:g_szTimeDifference[MAXPLAYERS+1][32]; 
new String:g_szFinalTime[MAXPLAYERS+1][32];
new String:g_szMapName[128];
new String:g_szMapTopName[MAXPLAYERS+1][128];
new String:g_szTimerTitle[MAXPLAYERS+1][255];
new String:g_szRecordPlayerPro[MAX_NAME_LENGTH];
new String:g_szRecordPlayer[MAX_NAME_LENGTH];
new String:g_szProfileName[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:g_szPlayerPanelText[MAXPLAYERS+1][512];
new String:g_szProfileSteamId[MAXPLAYERS+1][32];
new String:g_szCountry[MAXPLAYERS+1][100];
new String:g_szCountryCode[MAXPLAYERS+1][16]; 
new String:g_szSteamID[MAXPLAYERS+1][32];  
new String:g_szSkillGroups[9][32];
new String:g_szServerName[64];  
new String:g_szMapPath[256]; 
new String:g_szServerIp[32]; 
new String:g_szServerCountry[100]; 
new String:g_szServerCountryCode[32];  
new const String:MAPPERS_PATH[] = "configs/kztimer/mapmakers.txt";
new const String:KZ_REPLAY_PATH[] = "data/kz_replays/";
new const String:ANTICHEAT_LOG_PATH[] = "logs/kztimer_anticheat.log";
new const String:BLOCKED_LIST_PATH[] = "configs/kztimer/hidden_chat_commands.txt";
new const String:EXCEPTION_LIST_PATH[] = "configs/kztimer/exception_list.txt";
new const String:CP_FULL_SOUND_PATH[] = "sound/quake/wickedsick.mp3";
new const String:CP_RELATIVE_SOUND_PATH[] = "*quake/wickedsick.mp3";
new const String:PRO_FULL_SOUND_PATH[] = "sound/quake/holyshit.mp3";
new const String:PRO_RELATIVE_SOUND_PATH[] = "*quake/holyshit.mp3";
new const String:UNSTOPPABLE_SOUND_PATH[] = "sound/quake/unstoppable.mp3";
new const String:UNSTOPPABLE_RELATIVE_SOUND_PATH[] = "*quake/unstoppable.mp3";
new const String:GODLIKE_FULL_SOUND_PATH[] = "sound/quake/godlike.mp3";
new const String:GODLIKE_RELATIVE_SOUND_PATH[] = "*quake/godlike.mp3";
new const String:GODLIKE_RAMPAGE_FULL_SOUND_PATH[] = "sound/quake/rampage.mp3";
new const String:GODLIKE_RAMPAGE_RELATIVE_SOUND_PATH[] = "*quake/rampage.mp3";
new const String:GODLIKE_DOMINATING_FULL_SOUND_PATH[] = "sound/quake/dominating.mp3";
new const String:GODLIKE_DOMINATING_RELATIVE_SOUND_PATH[] = "*quake/dominating.mp3";
//new const String:OWNAGE_FULL_SOUND_PATH[] = "sound/quake/ownage.mp3";
//new const String:OWNAGE_RELATIVE_SOUND_PATH[] = "*quake/ownage.mp3";
new const String:PERFECT_FULL_SOUND_PATH[] = "sound/quake/perfect.mp3";
new const String:PERFECT_RELATIVE_SOUND_PATH[] = "*quake/perfect.mp3";
new const String:IMPRESSIVE_FULL_SOUND_PATH[] = "sound/quake/impressive_kz.mp3";
new const String:IMPRESSIVE_RELATIVE_SOUND_PATH[] = "*quake/impressive_kz.mp3";
new String:RadioCMDS[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog",
	"getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin",
	"getout", "negative","enemydown","cheer","thanks","nice","compliment"};
new String:g_BlockedChatText[256][256];
new String:g_szReplay_PlayerName[MAXPLAYERS+1][64];

#include "kztimer/admin.sp"
#include "kztimer/commands.sp"
#include "kztimer/hooks.sp"
#include "kztimer/buttonpress.sp"
#include "kztimer/sql.sp"
#include "kztimer/misc.sp"
#include "kztimer/timer.sp"
#include "kztimer/replay.sp"
#include "kztimer/jumpstats.sp"

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("KZTimer");
	MarkNativeAsOptional("HGR_IsHooking");
	MarkNativeAsOptional("HGR_IsGrabbing");
	MarkNativeAsOptional("HGR_IsBeingGrabbed");
	MarkNativeAsOptional("HGR_IsRoping");
	MarkNativeAsOptional("HGR_IsPushing");
	MarkNativeAsOptional("HasEndOfMapVoteFinished");
	MarkNativeAsOptional("EndOfMapVoteEnabled");	
	hStartPress = CreateGlobalForward("CL_OnStartTimerPress", ET_Ignore, Param_Cell);
	hEndPress = CreateGlobalForward("CL_OnEndTimerPress", ET_Ignore, Param_Cell);
	CreateNative("KZTimer_GetTimerStatus", Native_GetTimerStatus);
	CreateNative("KZTimer_StopUpdatingOfClimbersMenu", Native_StopUpdatingOfClimbersMenu);
	CreateNative("KZTimer_StopTimer", Native_StopTimer);
	CreateNative("KZTimer_EmulateStartButtonPress", Native_EmulateStartButtonPress);
	CreateNative("KZTimer_EmulateStopButtonPress", Native_EmulateStopButtonPress);
	CreateNative("KZTimer_GetCurrentTime", Native_GetCurrentTime);
	CreateNative("KZTimer_GetAvgTimeTp", Native_GetAvgTimeTp);
	CreateNative("KZTimer_GetAvgTimePro", Native_GetAvgTimePro);
	CreateNative("KZTimer_GetSkillGroup", Native_GetSkillGroup);
	g_bLateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	
	//get srv tick
	new Float:fltickrate = 1.0 / GetTickInterval( );
	if (fltickrate > 65)
		if (fltickrate < 103)
			g_Server_Tickrate = 102;
		else
			g_Server_Tickrate = 128;
	else
		g_Server_Tickrate= 64;
	
	//lanuage file
	LoadTranslations("kztimer.phrases");	
	
	// https://forums.alliedmods.net/showthread.php?p=1436866
	// GeoIP Language Selection by GoD-Tony
	Init_GeoLang();
	if (LibraryExists("clientprefs"))
	{
		g_hCookie = RegClientCookie("GeoLanguage", "The client's preferred language.", CookieAccess_Protected);
		SetCookieMenuItem(CookieMenu_GeoLanguage, 0, "Language");
		g_bUseCPrefs = true;
	}
	
	CreateConVar("kztimer_version", VERSION, "kztimer Version.", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hDoubleDuckCvar = 	CreateConVar("kz_double_duck", "0", "on/off - Allows you to get up edges that are 32 units high or less without jumping (double duck is always enabled if your timer is disabled)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bDoubleDuckCvar     = GetConVarBool(g_hDoubleDuckCvar);
	HookConVarChange(g_hDoubleDuckCvar, OnSettingChanged);
	
	g_hSlayPlayers = 	CreateConVar("kz_slay_on_endbutton_press", "0", "on/off - Slays other players when someone finishs the map. (helpful on mg_ course maps)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bSlayPlayers     = GetConVarBool(g_hSlayPlayers);
	HookConVarChange(g_hSlayPlayers, OnSettingChanged);	
	
	g_hAllowRoundEndCvar = CreateConVar("kz_round_end", "0", "on/off - Allows to end the current round", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAllowRoundEndCvar     = GetConVarBool(g_hAllowRoundEndCvar);
	HookConVarChange(g_hAllowRoundEndCvar, OnSettingChanged);	
	
	g_hConnectMsg = CreateConVar("kz_connect_msg", "1", "on/off - Enables a player connect message with country and disconnect message in chat", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bConnectMsg     = GetConVarBool(g_hConnectMsg);
	HookConVarChange(g_hConnectMsg, OnSettingChanged);	

	g_hMapEnd = CreateConVar("kz_map_end", "1", "on/off - Allows to end the current map when the timelimit has run out (mp_timelimit must be greater than 0)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bMapEnd     = GetConVarBool(g_hMapEnd);
	HookConVarChange(g_hMapEnd, OnSettingChanged);
	
	g_hReplayBot = CreateConVar("kz_replay_bot", "1", "on/off - Bots mimic the local tp and pro record", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bReplayBot     = GetConVarBool(g_hReplayBot);
	HookConVarChange(g_hReplayBot, OnSettingChanged);	
	
	g_hPreStrafe = CreateConVar("kz_prestrafe", "1", "on/off - Prestrafe", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPreStrafe     = GetConVarBool(g_hPreStrafe);
	HookConVarChange(g_hPreStrafe, OnSettingChanged);	

	g_hInfoBot	  = CreateConVar("kz_info_bot", "0", "on/off - provides information about nextmap and timeleft in his player name", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bInfoBot     = GetConVarBool(g_hInfoBot);
	HookConVarChange(g_hInfoBot, OnSettingChanged);		
	
	g_hNoClipS = CreateConVar("kz_noclip", "1", "on/off - Allows players to use noclip when they have finished the map", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bNoClipS     = GetConVarBool(g_hNoClipS);
	HookConVarChange(g_hNoClipS, OnSettingChanged);	

	g_hVipClantag = 	CreateConVar("kz_vip_clantag", "1", "on/off - VIP clan tag (necessary flag: a)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bVipClantag     = GetConVarBool(g_hVipClantag);
	HookConVarChange(g_hVipClantag, OnSettingChanged);	
	
	g_hAdminClantag = 	CreateConVar("kz_admin_clantag", "1", "on/off - Admin clan tag (necessary flag: b - z)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAdminClantag     = GetConVarBool(g_hAdminClantag);
	HookConVarChange(g_hAdminClantag, OnSettingChanged);	
	
	g_hAutoTimer = CreateConVar("kz_auto_timer", "0", "on/off - Timer starts automatically when a player joins a team, dies or uses !start/!r", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoTimer     = GetConVarBool(g_hAutoTimer);
	HookConVarChange(g_hAutoTimer, OnSettingChanged);

	g_hGoToServer = CreateConVar("kz_goto", "1", "on/off - Allows players to use the !goto command", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bGoToServer     = GetConVarBool(g_hGoToServer);
	HookConVarChange(g_hGoToServer, OnSettingChanged);	
	
	g_hcvargodmode = CreateConVar("kz_godmode", "1", "on/off - unlimited hp", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bgodmode     = GetConVarBool(g_hcvargodmode);
	HookConVarChange(g_hcvargodmode, OnSettingChanged);

	g_hPauseServerside    = CreateConVar("kz_pause", "1", "on/off - Allows players to use the !pause command", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPauseServerside    = GetConVarBool(g_hPauseServerside);
	HookConVarChange(g_hPauseServerside, OnSettingChanged);

	g_hSingleTouch    = CreateConVar("kz_bhop_single_touch", "0", "on/off - Disallows players to touch a single bhop block multiple times", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bSingleTouch    = GetConVarBool(g_hSingleTouch);
	HookConVarChange(g_hSingleTouch, OnSettingChanged);
	
	g_hcvarRestore    = CreateConVar("kz_restore", "1", "on/off - Restoring of time and last position after reconnect", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bRestore        = GetConVarBool(g_hcvarRestore);
	HookConVarChange(g_hcvarRestore, OnSettingChanged);

	g_hAttackSpamProtection    = CreateConVar("kz_attack_spam_protection", "1", "on/off - max 40 shots; +5 new/extra shots per minute; 1 he/flash counts like 9 shots", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAttackSpamProtection       = GetConVarBool(g_hAttackSpamProtection);
	HookConVarChange(g_hAttackSpamProtection, OnSettingChanged);
	
	g_hAllowCheckpoints = CreateConVar("kz_checkpoints", "1", "on/off - Allows player to do checkpoints", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAllowCheckpoints     = GetConVarBool(g_hAllowCheckpoints);
	HookConVarChange(g_hAllowCheckpoints, OnSettingChanged);	
	
	g_hEnforcer = CreateConVar("kz_settings_enforcer", "1", "on/off - Kreedz settings enforcer", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bEnforcer     = GetConVarBool(g_hEnforcer);
	HookConVarChange(g_hEnforcer, OnSettingChanged);
	
	g_hAutoRespawn = CreateConVar("kz_autorespawn", "1", "on/off - Auto respawn", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoRespawn     = GetConVarBool(g_hAutoRespawn);
	HookConVarChange(g_hAutoRespawn, OnSettingChanged);	

	g_hRadioCommands = CreateConVar("kz_use_radio", "0", "on/off - Allows players to use radio commands", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bRadioCommands     = GetConVarBool(g_hRadioCommands);
	HookConVarChange(g_hRadioCommands, OnSettingChanged);	

	g_hTeam_Restriction 	= CreateConVar("kz_team_restriction", "0", "Team restriction (0 = both allowed, 1 = only ct allowed, 2 = only t allowed)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_Team_Restriction     = GetConVarInt(g_hTeam_Restriction);
	HookConVarChange(g_hTeam_Restriction, OnSettingChanged);	

	g_hAutohealing_Hp 	= CreateConVar("kz_autoheal", "50", "Sets HP amount for autohealing (requires kz_godmode 0)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_Autohealing_Hp     = GetConVarInt(g_hAutohealing_Hp);
	HookConVarChange(g_hAutohealing_Hp, OnSettingChanged);	
	
	g_hCleanWeapons 	= CreateConVar("kz_clean_weapons", "1", "on/off - Removes all weapons on the ground", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCleanWeapons     = GetConVarBool(g_hCleanWeapons);
	HookConVarChange(g_hCleanWeapons, OnSettingChanged);

	g_hJumpStats 	= CreateConVar("kz_jumpstats", "1", "on/off - Measuring of jump distances (longjump, weirdjump, bhop, dropbhop, multibhop, ladderjump)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bJumpStats     = GetConVarBool(g_hJumpStats);
	HookConVarChange(g_hJumpStats, OnSettingChanged);	
	
	g_hCountry 	= CreateConVar("kz_country_tag", "1", "on/off - Country clan tag", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCountry     = GetConVarBool(g_hCountry);
	HookConVarChange(g_hCountry, OnSettingChanged);
	
	g_hChallengePoints 	= CreateConVar("kz_challenge_points", "1", "on/off - Allows players to bet points on their challenges", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bChallengePoints     = GetConVarBool(g_hChallengePoints);
	HookConVarChange(g_hChallengePoints, OnSettingChanged);
		
	g_hAutoBhopConVar 	= CreateConVar("kz_auto_bhop", "0", "on/off - AutoBhop on bhop_ and surf_ maps (climb maps are not supported)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoBhopConVar     = GetConVarBool(g_hAutoBhopConVar);
	HookConVarChange(g_hAutoBhopConVar, OnSettingChanged);
	
	g_hDynamicTimelimit 	= CreateConVar("kz_dynamic_timelimit", "1", "on/off - Sets a suitable timelimit by calculating the average run time (This method requires kz_map_end 1, greater than 5 map times and a default timelimit in your server config for maps with less than 5 times", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bDynamicTimelimit     = GetConVarBool(g_hDynamicTimelimit);
	HookConVarChange(g_hDynamicTimelimit, OnSettingChanged);

	g_hBhopSpeedCap   = CreateConVar("kz_prespeed_cap", "380.0", "Limits player's pre speed (kz_settings_enforcer must be disabled)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 5000.0);
	g_fBhopSpeedCap    = GetConVarFloat(g_hBhopSpeedCap);
	HookConVarChange(g_hBhopSpeedCap, OnSettingChanged);	

	g_hMinSkillGroup   = CreateConVar("kz_min_skill_group", "1.0", "Minimum skill group to play on this server excluding vips and admins. Everyone below the chosen skill group gets kicked. (1=NEW,2=SCRUB,3=TRAINEE,4=CASUAL,5=REGULAR,6=SKILLED,7=EXPERT,8=SEMIPRO,9=PRO)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 9.0);
	g_MinSkillGroup    = GetConVarInt(g_hMinSkillGroup);
	HookConVarChange(g_hMinSkillGroup, OnSettingChanged);	
	
	g_hExtraPoints   = CreateConVar("kz_ranking_extra_points_improvements", "10.0", "Gives players x extra points for improving their time.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_ExtraPoints    = GetConVarInt(g_hExtraPoints);
	HookConVarChange(g_hExtraPoints, OnSettingChanged);	

	g_hExtraPoints2   = CreateConVar("kz_ranking_extra_points_firsttime", "25.0", "Gives players x (tp time = x, pro time = 2 * x) extra points for finishing a map (tp and pro) for the first time.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_ExtraPoints2    = GetConVarInt(g_hExtraPoints2);
	HookConVarChange(g_hExtraPoints2, OnSettingChanged);	
	
	g_hPointSystem    = CreateConVar("kz_point_system", "1", "on/off - Player point system", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPointSystem    = GetConVarBool(g_hPointSystem);
	HookConVarChange(g_hPointSystem, OnSettingChanged);
	
	g_hPlayerSkinChange 	= CreateConVar("kz_custom_models", "1", "on/off - Allows kztimer to change the models of players and bots", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPlayerSkinChange     = GetConVarBool(g_hPlayerSkinChange);
	HookConVarChange(g_hPlayerSkinChange, OnSettingChanged);

	g_hReplayBotPlayerModel2   = CreateConVar("kz_replay_tpbot_skin", "models/player/tm_professional_var1.mdl", "Replay tp bot skin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hReplayBotPlayerModel2,g_sReplayBotPlayerModel2,256);
	HookConVarChange(g_hReplayBotPlayerModel2, OnSettingChanged);	
	
	g_hReplayBotArmModel2   = CreateConVar("kz_replay_tpbot_arm_skin", "models/weapons/t_arms_professional.mdl", "Replay tp bot arm skin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hReplayBotArmModel2,g_sReplayBotArmModel2,256);
	HookConVarChange(g_hReplayBotArmModel2, OnSettingChanged);	
	
	g_hReplayBotPlayerModel   = CreateConVar("kz_replay_probot_skin", "models/player/tm_professional_var1.mdl", "Replay pro bot skin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hReplayBotPlayerModel,g_sReplayBotPlayerModel,256);
	HookConVarChange(g_hReplayBotPlayerModel, OnSettingChanged);	
	
	g_hReplayBotArmModel   = CreateConVar("kz_replay_probot_arm_skin", "models/weapons/t_arms_professional.mdl", "Replay pro bot arm skin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hReplayBotArmModel,g_sReplayBotArmModel,256);
	HookConVarChange(g_hReplayBotArmModel, OnSettingChanged);	
	
	g_hPlayerModel   = CreateConVar("kz_player_skin", "models/player/ctm_sas_varianta.mdl", "Player skin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hPlayerModel,g_sPlayerModel,256);
	HookConVarChange(g_hPlayerModel, OnSettingChanged);	
	
	g_hArmModel   = CreateConVar("kz_player_arm_skin", "models/weapons/ct_arms_sas.mdl", "Player arm skin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hArmModel,g_sArmModel,256);
	HookConVarChange(g_hArmModel, OnSettingChanged);
	
	g_hWelcomeMsg   = CreateConVar("kz_welcome_msg", " {yellow}>>{default} {grey}Welcome! This server is using {lime}KZTimer v1.73","Welcome message (supported color tags: {default}, {darkred}, {green}, {lightgreen}, {blue} {olive}, {lime}, {red}, {purple}, {grey}, {yellow}, {lightblue}, {steelblue}, {darkblue}, {pink}, {lightred})", FCVAR_PLUGIN|FCVAR_NOTIFY);
	GetConVarString(g_hWelcomeMsg,g_sWelcomeMsg,512);
	HookConVarChange(g_hWelcomeMsg, OnSettingChanged);

	g_hReplayBotProColor   = CreateConVar("kz_replay_bot_pro_color", "52 91 248","The default pro replay bot color - Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_hReplayBotProColor, OnSettingChanged);	
	decl String:szProColor[256];
	GetConVarString(g_hReplayBotProColor,szProColor,256);
	GetRGBColor(0,szProColor);
	
	g_hReplayBotTpColor   = CreateConVar("kz_replay_bot_tp_color", "223 213 0","The default tp replay bot color - Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_hReplayBotTpColor, OnSettingChanged);	
	decl String:szTpColor[256];
	GetConVarString(g_hReplayBotTpColor,szTpColor,256);
	GetRGBColor(1,szTpColor);
	
	g_hAutoBan 	= CreateConVar("kz_anticheat_auto_ban", "1", "on/off - auto-ban (bhop hack) including deletion of their records (anti-cheat log: sourcemod/logs)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoBan     = GetConVarBool(g_hAutoBan);
	HookConVarChange(g_hAutoBan, OnSettingChanged);	
	
	g_hBanDuration   = CreateConVar("kz_anticheat_ban_duration", "72.0", "Ban duration in hours", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 999999.0);

	//settings enforcer
	g_hStaminaLandCost = FindConVar("sv_staminalandcost");
	g_hStaminaJumpCost = FindConVar("sv_staminajumpcost");
	g_hGravity = FindConVar("sv_gravity");
	g_hAirAccelerate = FindConVar("sv_airaccelerate");
	g_hMaxSpeed = FindConVar("sv_maxspeed");
	g_hWaterAccelerate = FindConVar("sv_wateraccelerate");
	g_hFriction = FindConVar("sv_friction");
	g_hAccelerate = FindConVar("sv_accelerate");
	g_hMaxVelocity = FindConVar("sv_maxvelocity");
	g_hCheats = FindConVar("sv_cheats");
	g_hEnableBunnyhoping = FindConVar("sv_enablebunnyhopping");
	g_hMaxRounds = FindConVar("mp_maxrounds");
	HookConVarChange(g_hStaminaLandCost, OnSettingChanged);
	HookConVarChange(g_hStaminaJumpCost, OnSettingChanged);
	HookConVarChange(g_hMaxSpeed, OnSettingChanged);
	HookConVarChange(g_hGravity, OnSettingChanged);
	HookConVarChange(g_hWaterAccelerate, OnSettingChanged);
	HookConVarChange(g_hAirAccelerate, OnSettingChanged);
	HookConVarChange(g_hFriction, OnSettingChanged);
	HookConVarChange(g_hAccelerate, OnSettingChanged);
	HookConVarChange(g_hMaxVelocity, OnSettingChanged);
	HookConVarChange(g_hCheats, OnSettingChanged);
	HookConVarChange(g_hEnableBunnyhoping, OnSettingChanged);
	HookConVarChange(g_hMaxRounds, OnSettingChanged);

	if (g_Server_Tickrate == 64)
	{
		g_hMaxBhopPreSpeed   = CreateConVar("kz_max_prespeed_bhop_dropbhop", "325.0", "Max counted pre speed for bhop,dropbhop (no speed limiter)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 400.0);
		g_hdist_good_countjump    	= CreateConVar("kz_dist_min_cj", "240.0", "Minimum distance for count jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_perfect_countjump   	= CreateConVar("kz_dist_perfect_cj", "265.0", "Minimum distance for count jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
		g_hdist_impressive_countjump   	= CreateConVar("kz_dist_impressive_cj", "270.0", "Minimum distance for count jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
		g_hdist_godlike_countjump    	= CreateConVar("kz_dist_god_cj", "275.0", "Minimum distance for count jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 245.0, true, 999.0);	
		g_hdist_good_lj    	= CreateConVar("kz_dist_min_lj", "235.0", "Minimum distance for long jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_perfect_lj   	= CreateConVar("kz_dist_perfect_lj", "255.0", "Minimum distance for long jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
		g_hdist_impressive_lj   	= CreateConVar("kz_dist_impressive_lj", "258.0", "Minimum distance for long jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
		g_hdist_godlike_lj    	= CreateConVar("kz_dist_god_lj", "263.0", "Minimum distance for long jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 245.0, true, 999.0);	
		g_hdist_good_weird  = CreateConVar("kz_dist_min_wj", "250.0", "Minimum distance for weird jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_perfect_weird  = CreateConVar("kz_dist_perfect_wj", "265.0", "Minimum distance for weird jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_impressive_weird  = CreateConVar("kz_dist_impressive_wj", "275.0", "Minimum distance for weird jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_godlike_weird   = CreateConVar("kz_dist_god_wj", "278.0", "Minimum distance for weird jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_good_dropbhop  = CreateConVar("kz_dist_min_dropbhop", "240.0", "Minimum distance for drop bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_perfect_dropbhop  = CreateConVar("kz_dist_perfect_dropbhop", "290.0", "Minimum distance for drop bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);	
		g_hdist_impressive_dropbhop  = CreateConVar("kz_dist_impressive_dropbhop", "295.0", "Minimum distance for drop bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_godlike_dropbhop   = CreateConVar("kz_dist_god_dropbhop", "298.0", "Minimum distance for drop bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_good_bhop  = CreateConVar("kz_dist_min_bhop", "240.0", "Minimum distance for bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_perfect_bhop  = CreateConVar("kz_dist_perfect_bhop", "290.0", "Minimum distance for bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_impressive_bhop  = CreateConVar("kz_dist_impressive_bhop", "295.0", "Minimum distance for bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_godlike_bhop   = CreateConVar("kz_dist_god_bhop", "298.0", "Minimum distance for bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
		g_hdist_good_multibhop  = CreateConVar("kz_dist_min_multibhop", "300.0", "Minimum distance for multi-bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
		g_hdist_perfect_multibhop  = CreateConVar("kz_dist_perfect_multibhop", "330.0", "Minimum distance for multi-bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
		g_hdist_impressive_multibhop  = CreateConVar("kz_dist_impressive_multibhop", "340.0", "Minimum distance for multi-bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
		g_hdist_godlike_multibhop   = CreateConVar("kz_dist_god_multibhop", "343.0", "Minimum distance for multi-bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
		g_hdist_good_ladder  = CreateConVar("kz_dist_min_ladder", "100.0", "Minimum distance for ladder jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 70.0, true, 9999.0);
		g_hdist_perfect_ladder  = CreateConVar("kz_dist_perfect_ladder", "150.0", "Minimum distance for ladder jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
		g_hdist_impressive_ladder  = CreateConVar("kz_dist_impressive_ladder", "155.0", "Minimum distance for ladder jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
		g_hdist_godlike_ladder   = CreateConVar("kz_dist_god_ladder", "160.0", "Minimum distance for ladder jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
	}
	else
	{
		if (g_Server_Tickrate == 128)
		{
			g_hMaxBhopPreSpeed   = CreateConVar("kz_max_prespeed_bhop_dropbhop", "360.0", "Max counted pre speed for bhop,dropbhop (no speed limiter)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 400.0);
			g_hdist_good_countjump    	= CreateConVar("kz_dist_min_cj", "240.0", "Minimum distance for count jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_countjump   	= CreateConVar("kz_dist_perfect_cj", "280.0", "Minimum distance for count jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_impressive_countjump   	= CreateConVar("kz_dist_impressive_cj", "285.0", "Minimum distance for count jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_godlike_countjump    	= CreateConVar("kz_dist_god_cj", "290.0", "Minimum distance for count jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 245.0, true, 999.0);	
			g_hdist_good_lj    	= CreateConVar("kz_dist_min_lj", "240.0", "Minimum distance for long jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_lj   	= CreateConVar("kz_dist_perfect_lj", "265.0", "Minimum distance for long jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_impressive_lj   	= CreateConVar("kz_dist_impressive_lj", "270.0", "Minimum distance for long jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_godlike_lj    	= CreateConVar("kz_dist_god_lj", "275.0", "Minimum distance for long jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 245.0, true, 999.0);	
			g_hdist_good_weird  = CreateConVar("kz_dist_min_wj", "250.0", "Minimum distance for weird jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_weird  = CreateConVar("kz_dist_perfect_wj", "280.0", "Minimum distance for weird jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_impressive_weird  = CreateConVar("kz_dist_impressive_wj", "285.0", "Minimum distance for weird jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_godlike_weird   = CreateConVar("kz_dist_god_wj", "290.0", "Minimum distance for weird jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_good_dropbhop  = CreateConVar("kz_dist_min_dropbhop", "240.0", "Minimum distance for drop bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_dropbhop  = CreateConVar("kz_dist_perfect_dropbhop", "315.0", "Minimum distance for drop bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);	
			g_hdist_impressive_dropbhop  = CreateConVar("kz_dist_impressive_dropbhop", "320.0", "Minimum distance for drop bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_godlike_dropbhop   = CreateConVar("kz_dist_god_dropbhop", "325.0", "Minimum distance for drop bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_good_bhop  = CreateConVar("kz_dist_min_bhop", "240.0", "Minimum distance for bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_bhop  = CreateConVar("kz_dist_perfect_bhop", "320.0", "Minimum distance for bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_impressive_bhop  = CreateConVar("kz_dist_impressive_bhop", "325.0", "Minimum distance for bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_godlike_bhop   = CreateConVar("kz_dist_god_bhop", "330.0", "Minimum distance for bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_good_multibhop  = CreateConVar("kz_dist_min_multibhop", "300.0", "Minimum distance for multi-bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_perfect_multibhop  = CreateConVar("kz_dist_perfect_multibhop", "340.0", "Minimum distance for multi-bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_impressive_multibhop  = CreateConVar("kz_dist_impressive_multibhop", "345.0", "Minimum distance for multi-bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_godlike_multibhop   = CreateConVar("kz_dist_god_multibhop", "348.0", "Minimum distance for multi-bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_good_ladder  = CreateConVar("kz_dist_min_ladder", "100.0", "Minimum distance for ladder jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 70.0, true, 9999.0);
			g_hdist_perfect_ladder  = CreateConVar("kz_dist_perfect_ladder", "155.0", "Minimum distance for ladder jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
			g_hdist_impressive_ladder  = CreateConVar("kz_dist_impressive_ladder", "165.0", "Minimum distance for ladder jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
			g_hdist_godlike_ladder   = CreateConVar("kz_dist_god_ladder", "175.0", "Minimum distance for ladder jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);		
		}
		else
		{
			g_hMaxBhopPreSpeed   = CreateConVar("kz_max_prespeed_bhop_dropbhop", "350.0", "Max counted pre speed for bhop,dropbhop (no speed limiter)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 300.0, true, 400.0);
			g_hdist_good_countjump    	= CreateConVar("kz_dist_min_cj", "240.0", "Minimum distance for count jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_countjump   	= CreateConVar("kz_dist_perfect_cj", "275.0", "Minimum distance for count jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_impressive_countjump   	= CreateConVar("kz_dist_impressive_cj", "280.0", "Minimum distance for count jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_godlike_countjump    	= CreateConVar("kz_dist_god_cj", "285.0", "Minimum distance for count jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 245.0, true, 999.0);	
			g_hdist_good_lj    	= CreateConVar("kz_dist_min_lj", "240.0", "Minimum distance for long jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_lj   	= CreateConVar("kz_dist_perfect_lj", "260.0", "Minimum distance for long jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_impressive_lj   	= CreateConVar("kz_dist_impressive_lj", "265.0", "Minimum distance for long jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 999.0);
			g_hdist_godlike_lj    	= CreateConVar("kz_dist_god_lj", "270.0", "Minimum distance for long jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 245.0, true, 999.0);	
			g_hdist_good_weird  = CreateConVar("kz_dist_min_wj", "250.0", "Minimum distance for weird jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_weird  = CreateConVar("kz_dist_perfect_wj", "280.0", "Minimum distance for weird jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_impressive_weird  = CreateConVar("kz_dist_impressive_wj", "285.0", "Minimum distance for weird jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_godlike_weird   = CreateConVar("kz_dist_god_wj", "288.0", "Minimum distance for weird jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_good_dropbhop  = CreateConVar("kz_dist_min_dropbhop", "240.0", "Minimum distance for drop bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_dropbhop  = CreateConVar("kz_dist_perfect_dropbhop", "310.0", "Minimum distance for drop bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);	
			g_hdist_impressive_dropbhop  = CreateConVar("kz_dist_impressive_dropbhop", "315.0", "Minimum distance for drop bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_godlike_dropbhop   = CreateConVar("kz_dist_god_dropbhop", "320.0", "Minimum distance for drop bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_good_bhop  = CreateConVar("kz_dist_min_bhop", "240.0", "Minimum distance for bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_perfect_bhop  = CreateConVar("kz_dist_perfect_bhop", "315.0", "Minimum distance for bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_impressive_bhop  = CreateConVar("kz_dist_impressive_bhop", "320.0", "Minimum distance for bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_godlike_bhop   = CreateConVar("kz_dist_god_bhop", "325.0", "Minimum distance for bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 999.0);
			g_hdist_good_multibhop  = CreateConVar("kz_dist_min_multibhop", "300.0", "Minimum distance for multi-bhops to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_perfect_multibhop  = CreateConVar("kz_dist_perfect_multibhop", "335.0", "Minimum distance for multi-bhops to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_impressive_multibhop  = CreateConVar("kz_dist_impressive_multibhop", "340.0", "Minimum distance for multi-bhops to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_godlike_multibhop   = CreateConVar("kz_dist_god_multibhop", "345.0", "Minimum distance for multi-bhops to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 200.0, true, 9999.0);
			g_hdist_good_ladder  = CreateConVar("kz_dist_min_ladder", "100.0", "Minimum distance for ladder jumps to be considered good [Client Message]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 70.0, true, 9999.0);
			g_hdist_perfect_ladder  = CreateConVar("kz_dist_perfect_ladder", "150.0", "Minimum distance for ladder jumps to be considered perfect [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
			g_hdist_impressive_ladder  = CreateConVar("kz_dist_impressive_ladder", "160.0", "Minimum distance for ladder jumps to be considered impressive [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);
			g_hdist_godlike_ladder   = CreateConVar("kz_dist_god_ladder", "170.0", "Minimum distance for ladder jumps to be considered godlike [JumpStats Colorchat All]", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 9999.0);		
		}
	}	
		
	g_fBanDuration    = GetConVarFloat(g_hBanDuration);
	HookConVarChange(g_hBanDuration, OnSettingChanged);	
	
	g_fMaxBhopPreSpeed    = GetConVarFloat(g_hMaxBhopPreSpeed);
	HookConVarChange(g_hMaxBhopPreSpeed, OnSettingChanged);	

	g_dist_min_countjump	= GetConVarFloat(g_hdist_good_countjump);
	HookConVarChange(g_hdist_good_countjump, OnSettingChanged);	
	
	g_dist_impressive_countjump    = GetConVarFloat(g_hdist_impressive_countjump);
	HookConVarChange(g_hdist_impressive_countjump, OnSettingChanged);	
	
	g_dist_perfect_countjump	= GetConVarFloat(g_hdist_perfect_countjump);
	HookConVarChange(g_hdist_perfect_countjump, OnSettingChanged);	
	
	g_dist_god_countjump    = GetConVarFloat(g_hdist_godlike_countjump);
	HookConVarChange(g_hdist_godlike_countjump, OnSettingChanged);	
	
	g_dist_min_weird	= GetConVarFloat(g_hdist_good_weird);
	HookConVarChange(g_hdist_good_weird, OnSettingChanged);	
	
	g_dist_impressive_weird    = GetConVarFloat(g_hdist_impressive_weird);
	HookConVarChange(g_hdist_impressive_weird, OnSettingChanged);	
	
	g_dist_perfect_weird	= GetConVarFloat(g_hdist_perfect_weird);
	HookConVarChange(g_hdist_perfect_weird, OnSettingChanged);	
	
	g_dist_god_weird    = GetConVarFloat(g_hdist_godlike_weird);
	HookConVarChange(g_hdist_godlike_weird, OnSettingChanged);	

	g_dist_min_dropbhop	= GetConVarFloat(g_hdist_good_dropbhop);
	HookConVarChange(g_hdist_good_dropbhop, OnSettingChanged);	

	g_dist_impressive_dropbhop    = GetConVarFloat(g_hdist_impressive_dropbhop);
	HookConVarChange(g_hdist_impressive_dropbhop, OnSettingChanged);	
	
	g_dist_perfect_dropbhop	= GetConVarFloat(g_hdist_perfect_dropbhop);
	HookConVarChange(g_hdist_perfect_dropbhop, OnSettingChanged);	
	
	g_dist_god_dropbhop    = GetConVarFloat(g_hdist_godlike_dropbhop);
	HookConVarChange(g_hdist_godlike_dropbhop, OnSettingChanged);	
		
	g_dist_min_bhop	= GetConVarFloat(g_hdist_good_bhop);
	HookConVarChange(g_hdist_good_bhop, OnSettingChanged);	

	g_dist_impressive_bhop    = GetConVarFloat(g_hdist_impressive_bhop);
	HookConVarChange(g_hdist_impressive_bhop, OnSettingChanged);	
	
	g_dist_perfect_bhop	= GetConVarFloat(g_hdist_perfect_bhop);
	HookConVarChange(g_hdist_perfect_bhop, OnSettingChanged);	
	
	g_dist_god_bhop    = GetConVarFloat(g_hdist_godlike_bhop);
	HookConVarChange(g_hdist_godlike_bhop, OnSettingChanged);	
	
	g_dist_min_multibhop	= GetConVarFloat(g_hdist_good_multibhop);
	HookConVarChange(g_hdist_good_multibhop, OnSettingChanged);	

	g_dist_impressive_multibhop    = GetConVarFloat(g_hdist_impressive_multibhop);
	HookConVarChange(g_hdist_impressive_multibhop, OnSettingChanged);	
	
	g_dist_perfect_multibhop	= GetConVarFloat(g_hdist_perfect_multibhop);
	HookConVarChange(g_hdist_perfect_multibhop, OnSettingChanged);	

	g_dist_god_multibhop    = GetConVarFloat(g_hdist_godlike_multibhop);
	HookConVarChange(g_hdist_godlike_multibhop, OnSettingChanged);	
		
	g_dist_min_lj      = GetConVarFloat(g_hdist_good_lj);
	HookConVarChange(g_hdist_good_lj, OnSettingChanged);	

	g_dist_impressive_lj    = GetConVarFloat(g_hdist_impressive_lj);
	HookConVarChange(g_hdist_impressive_lj, OnSettingChanged);	
	
	g_dist_perfect_lj      = GetConVarFloat(g_hdist_perfect_lj);
	HookConVarChange(g_hdist_perfect_lj, OnSettingChanged);	
	
	g_dist_god_lj      = GetConVarFloat(g_hdist_godlike_lj);
	HookConVarChange(g_hdist_godlike_lj, OnSettingChanged);	

	g_dist_min_ladder      = GetConVarFloat(g_hdist_good_ladder);
	HookConVarChange(g_hdist_good_ladder, OnSettingChanged);	

	g_dist_impressive_ladder    = GetConVarFloat(g_hdist_impressive_ladder);
	HookConVarChange(g_hdist_impressive_ladder, OnSettingChanged);	
	
	g_dist_perfect_ladder      = GetConVarFloat(g_hdist_perfect_ladder);
	HookConVarChange(g_hdist_perfect_ladder, OnSettingChanged);	
	
	g_dist_god_ladder      = GetConVarFloat(g_hdist_godlike_ladder);
	HookConVarChange(g_hdist_godlike_ladder, OnSettingChanged);	
	
	db_setupDatabase();
	SetServerConvars();
	
	//client commands
	RegConsoleCmd("sm_usp", Client_Usp, "[KZTimer] spawns a usp silencer");
	RegConsoleCmd("sm_beam", Client_PlayerJumpBeam, "[KZTimer] onf/off - showing the trajectory of the jump");
	RegConsoleCmd("sm_avg", Client_Avg, "[KZTimer] prints in chat the average time of the current map");
	RegConsoleCmd("sm_accept", Client_Accept, "[KZTimer] allows you to accept a challenge request");
	RegConsoleCmd("sm_goto", Client_GoTo, "[KZTimer] teleports you to a selected player");
	RegConsoleCmd("sm_showkeys", Client_InfoPanel, "[KZTimer] on/off speed/showkeys center panel");
	RegConsoleCmd("sm_language", Client_Language, "[KZTimer] select your language");
	RegConsoleCmd("sm_sync", Client_StrafeSync,"[KZTimer] on/off strafe sync in chat");
	RegConsoleCmd("sm_surrender", Client_Surrender, "[KZTimer] surrender your current challenge");
	RegConsoleCmd("sm_next", Client_Next,"[KZTimer] goto next checkpoint");
	RegConsoleCmd("sm_bhop", Client_AutoBhop,"[KZTimer] on/off autobhop (only mg_,surf_ and bhop_ maps supported)");
	RegConsoleCmd("sm_undo", Client_Undo,"[KZTimer] undoes your last telepoint");
	RegConsoleCmd("sm_flashlight", Client_Flashlight,"[KZTimer] on/off flashlight");
	RegConsoleCmd("sm_prev", Client_Prev,"[KZTimer] goto previous checkpoint");
	RegConsoleCmd("sm_ljblock", Client_Ljblock,"[KZTimer] registers a lj block");
	RegConsoleCmd("sm_adv", Client_AdvClimbersMenu, "[KZTimer] advanced climbers menu (additional: !next, !prev and !undo)");
	RegConsoleCmd("sm_unstuck", Client_Prev,"[KZTimer] go to previous checkpoint");
	RegConsoleCmd("sm_maptop", Client_MapTop,"[KZTimer] displays local map top for a given map");
	RegConsoleCmd("sm_stuck", Client_Prev,"[KZTimer] go to previous checkpoint");
	RegConsoleCmd("sm_checkpoint", Client_Save,"[KZTimer] save your current position");
	RegConsoleCmd("sm_gocheck", Client_Tele,"[KZTimer] go to latest checkpoint");
	RegConsoleCmd("sm_compare", Client_Compare, "[KZTimer] compare your challenge results");
	RegConsoleCmd("sm_menu", Client_Kzmenu, "[KZTimer] opens checkpoint menu");
	RegConsoleCmd("sm_cpmenu", Client_Kzmenu, "[KZTimer] opens checkpoint menu");
	RegConsoleCmd("sm_wr", Client_Wr, "[KZTimer] prints records in chat");
	RegConsoleCmd("sm_measure",Command_Menu, "[KZTimer] allows you to measure the distance between 2 points");
	RegConsoleCmd("sm_abort", Client_Abort, "[KZTimer] abort your current challenge");
	RegConsoleCmd("sm_spec", Client_Spec, "[KZTimer] chooses a player who you want to spectate and switch you to spectators");
	RegConsoleCmd("sm_specs", Command_Specs, "[KZTimer] prints in chat a list of all spectators");
	RegConsoleCmd("sm_watch", Client_Spec, "[KZTimer] chooses a player who you want to spectate and switch you to spectators");
	RegConsoleCmd("sm_spectate", Client_Spec, "[KZTimer] chooses a player who you want to spectate and switch you to spectators");
	RegConsoleCmd("sm_challenge", Client_Challenge, "[KZTimer] allows you to start a race against others");
	RegConsoleCmd("sm_helpmenu", Client_Help, "[KZTimer] help menu which displays all kztimer commands");
	RegConsoleCmd("sm_help", Client_Help, "[KZTimer] help menu which displays all kztimer commands");
	RegConsoleCmd("sm_profile", Client_Profile, "[KZTimer] opens a player profile");
	RegConsoleCmd("sm_rank", Client_Profile, "[KZTimer] opens a player profile");
	RegConsoleCmd("sm_hidechat", Client_HideChat, "[KZTimer] hides your ingame chat and voice icons");
	RegConsoleCmd("sm_hideweapon", Client_HideWeapon, "[KZTimer] hides your weapon model");
	RegConsoleCmd("sm_options", Client_OptionMenu, "[KZTimer] opens options menu");
	RegConsoleCmd("sm_top", Client_Top, "[KZTimer] displays top rankings (Top 100 Players, Top 50 overall, Top 20 Pro, Top 20 with Teleports, Top 20 LJ, Top 20 Bhop, Top 20 Multi-Bhop, Top 20 WeirdJump, Top 20 Drop Bunnyhop)");
	RegConsoleCmd("sm_topclimbers", Client_Top, "[KZTimer] displays top rankings (Top 100 Players, Top 50 overall, Top 20 Pro, Top 20 with Teleports, Top 20 LJ, Top 20 Bhop, Top 20 Multi-Bhop, Top 20 WeirdJump, Top 20 Drop Bunnyhop)");
	RegConsoleCmd("sm_start", Client_Start, "[KZTimer] go back to start");
	RegConsoleCmd("sm_stopsound", Client_Stopsound, "[KZTimer] Stops map music");
	RegConsoleCmd("sm_r", Client_Start, "[KZTimer] go back to start");
	RegConsoleCmd("sm_stop", Client_Stop, "[KZTimer] stops your timer");
	RegConsoleCmd("sm_ranks", Client_Ranks, "[KZTimer] prints in chat the available player ranks");
	RegConsoleCmd("sm_speed", Client_InfoPanel, "[KZTimer] on/off speed/showkeys center panel");
	RegConsoleCmd("sm_pause", Client_Pause,"[KZTimer] on/off pause (timer on hold and movement frozen)");
	RegConsoleCmd("sm_showsettings", Client_Showsettings,"[KZTimer] shows kztimer server settings");
	RegConsoleCmd("sm_latest", Client_Latest,"[KZTimer] shows latest map records");
	RegConsoleCmd("sm_hide", Client_Hide, "[KZTimer] on/off - hides other players");
	RegConsoleCmd("sm_bhopcheck", Command_Stats, "[KZTimer] checks bhop stats for a given player");
	RegConsoleCmd("+noclip", NoClip, "[KZTimer] Player noclip on");
	RegConsoleCmd("-noclip", UnNoClip, "[KZTimer] Player noclip off");
	RegAdminCmd("sm_kzadmin", Admin_KzPanel, ADMIN_LEVEL, "[KZTimer] Displays the kztimer menu panel (requires flag e)");
	RegAdminCmd("sm_refreshprofile", Admin_RefreshProfile, ADMIN_LEVEL, "[KZTimer] Recalculates player profile for given steam id");
	RegAdminCmd("sm_resetchallenges", Admin_DropChallenges, ADMIN_LEVEL2, "[KZTimer] Resets all player challenges (drops table challenges) - requires z flag");
	RegAdminCmd("sm_resettimes", Admin_DropAllMapRecords, ADMIN_LEVEL2, "[KZTimer] Resets all player times (drops table playertimes) - requires z flag");
	RegAdminCmd("sm_resetranks", Admin_DropPlayerRanks, ADMIN_LEVEL2, "[KZTimer] Resets the all player points  (drops table playerrank - requires z flag)");
	RegAdminCmd("sm_resetmaptimes", Admin_ResetMapRecords, ADMIN_LEVEL2, "[KZTimer] Resets player times for given map - requires z flag");
	RegAdminCmd("sm_resetplayerchallenges", Admin_ResetChallenges, ADMIN_LEVEL2, "[KZTimer] Resets (won) challenges for given steamid - requires z flag");
	RegAdminCmd("sm_resetplayertimes", Admin_ResetRecords, ADMIN_LEVEL2, "[KZTimer] Resets tp & pro map times (+extrapoints) for given steamid with or without given map - requires z flag");
	RegAdminCmd("sm_resetplayertptime", Admin_ResetRecordTp, ADMIN_LEVEL2, "[KZTimer] Resets tp map time for given steamid and map - requires z flag");
	RegAdminCmd("sm_resetplayerprotime", Admin_ResetRecordPro, ADMIN_LEVEL2, "[KZTimer] Resets pro map time for given steamid and map - requires z flag");
	RegAdminCmd("sm_resetjumpstats", Admin_DropPlayerJump, ADMIN_LEVEL2, "[KZTimer] Resets jump stats (drops table playerjumpstats) - requires z flag");	
	RegAdminCmd("sm_resetallljrecords", Admin_ResetAllLjRecords, ADMIN_LEVEL2, "[KZTimer] Resets all lj records - requires z flag");
	RegAdminCmd("sm_resetallladderjumprecords", Admin_ResetAllLadderJumpRecords, ADMIN_LEVEL2, "[KZTimer] Resets all ladder jump records - requires z flag");
	RegAdminCmd("sm_resetallljblockrecords", Admin_ResetAllLjBlockRecords, ADMIN_LEVEL2, "[KZTimer] Resets all lj block records - requires z flag");
	RegAdminCmd("sm_resetallwjrecords", Admin_ResetAllWjRecords, ADMIN_LEVEL2, "[KZTimer] Resets all wj records - requires z flag");
	RegAdminCmd("sm_resetallbhoprecords", Admin_ResetAllBhopRecords, ADMIN_LEVEL2, "[KZTimer] Resets all bhop records - requires z flag");
	RegAdminCmd("sm_resetalldropbhopecords", Admin_ResetAllDropBhopRecords, ADMIN_LEVEL2, "[KZTimer] Resets all drop bjop records - requires z flag");
	RegAdminCmd("sm_resetallmultibhoprecords", Admin_ResetAllMultiBhopRecords, ADMIN_LEVEL2, "[KZTimer] Resets all multi bhop records - requires z flag");
	RegAdminCmd("sm_resetljrecord", Admin_ResetLjRecords, ADMIN_LEVEL2, "[KZTimer] Resets lj record for given steamid - requires z flag");
	RegAdminCmd("sm_resetcjrecord", Admin_ResetCjRecords, ADMIN_LEVEL2, "[KZTimer] Resets cj record for given steamid - requires z flag");
	RegAdminCmd("sm_resetladderjumprecord", Admin_ResetLadderJumpRecords, ADMIN_LEVEL2, "[KZTimer] Resets ladderjump record for given steamid - requires z flag");
	RegAdminCmd("sm_resetljblockrecord", Admin_ResetLjBlockRecords, ADMIN_LEVEL2, "[KZTimer] Resets lj block record for given steamid - requires z flag");
	RegAdminCmd("sm_resetbhoprecord", Admin_ResetBhopRecords, ADMIN_LEVEL2, "[KZTimer] Resets bhop record for given steamid - requires z flag");	
	RegAdminCmd("sm_resetdropbhoprecord", Admin_ResetDropBhopRecords, ADMIN_LEVEL2, "[KZTimer] Resets drop bhop record for given steamid - requires z flag");
	RegAdminCmd("sm_resetwjrecord", Admin_ResetWjRecords, ADMIN_LEVEL2, "[KZTimer] Resets wj record for given steamid - requires z flag");	
	RegAdminCmd("sm_resetmultibhoprecord", Admin_ResetMultiBhopRecords, ADMIN_LEVEL2, "[KZTimer] Resets multi bhop record for given steamid - requires z flag");
	RegAdminCmd("sm_resetplayerjumpstats", Admin_ResetPlayerJumpstats, ADMIN_LEVEL2, "[KZTimer] Resets jump stats for given steamid - requires z flag");
	RegAdminCmd("sm_deleteproreplay", Admin_DeleteProReplay, ADMIN_LEVEL2, "[KZTimer] Deletes pro replay for a given map - requires z flag");
	RegAdminCmd("sm_deletetpreplay", Admin_DeleteTpReplay, ADMIN_LEVEL2, "[KZTimer] Deletes tp replay for a given map - requires z flag");	
	RegAdminCmd("sm_resetextrapoints", Admin_ResetExtraPoints, ADMIN_LEVEL2, "[KZTimer] Resets given extra points for all players with or without given steamid");	

	
	//chat command listener
	AddCommandListener(Say_Hook, "say");
	AddCommandListener(Say_Hook, "say_team");

	//exec kztimer.cfg
	AutoExecConfig(true, "KZTimer");
	
	//mic
	g_ownerOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	g_ragdolls = FindSendPropOffs("CCSPlayer","m_hRagdoll");

	//Credits: Measure by DaFox
	//https://forums.alliedmods.net/showthread.php?t=88830
	g_hMainMenu = CreateMenu(Handler_MainMenu)
	SetMenuTitle(g_hMainMenu,"KZTimer - Measure")
	AddMenuItem(g_hMainMenu,"","Point 1 (Red)")
	AddMenuItem(g_hMainMenu,"","Point 2 (Green)")
	AddMenuItem(g_hMainMenu,"","Find Distance")
	AddMenuItem(g_hMainMenu,"","Reset")

	//add to admin menu
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
	//hooks
	
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start",Event_OnRoundStart,EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_jump", Event_OnJump, EventHookMode_Pre);
	HookEvent("weapon_fire",  Event_OnFire, EventHookMode_Pre);
	HookEvent("player_jump", Event_OnJumpMacroDox, EventHookMode_Post);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Post);
	HookEvent("player_team", Event_OnPlayerTeamRestriction, EventHookMode_Pre);
	HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre); 
	HookEntityOutput("trigger_teleport", "OnStartTouch", Teleport_OnStartTouch);	
	HookEntityOutput("trigger_multiple", "OnStartTouch", Teleport_OnStartTouch);	
	HookEntityOutput("trigger_teleport", "OnEndTouch", Teleport_OnEndTouch);	
	HookEntityOutput("trigger_multiple", "OnEndTouch", Teleport_OnEndTouch);	
	HookEntityOutput("func_button", "OnPressed", ButtonPress);

	//mapcycle array
	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);	

	//exception list
	decl String:sPath[PLATFORM_MAX_PATH];
	decl String:line[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", EXCEPTION_LIST_PATH);
	new Handle:fileHandle=OpenFile(sPath,"r");		
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
	{
		if ((StrContains(line,"//",true) == -1))
		{
			TrimString(line);
			if (!StrEqual(line,""))
			{
				AddCommandListener(Command_ext_Menu, line);
			}
		}
	}
	if (fileHandle != INVALID_HANDLE)
		CloseHandle(fileHandle);
		
	//add command listeners	
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_ext_Menu, "radio1");
	AddCommandListener(Command_ext_Menu, "radio2");
	AddCommandListener(Command_ext_Menu, "radio3");
	AddCommandListener(Command_ext_Menu, "sm_nominate");
	AddCommandListener(Command_ext_Menu, "sm_admin");
	AddCommandListener(Command_ext_Menu, "sm_votekick");
	AddCommandListener(Command_ext_Menu, "sm_voteban");
	AddCommandListener(Command_ext_Menu, "sm_votemenu");
	AddCommandListener(Command_ext_Menu, "sm_revote");

	//hook radio commands
	for(new g; g < sizeof(RadioCMDS); g++)
		AddCommandListener(BlockRadio, RadioCMDS[g]);

	//button sound hook
	AddNormalSoundHook(NormalSHook_callback);

	//nav files
	CreateNavFiles();

	// Botmimic 2
	// https://forums.alliedmods.net/showthread.php?t=180114
	// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
	CheatFlag("bot_zombie", false, true);
	CheatFlag("bot_mimic", false, true);
	g_hLoadedRecordsAdditionalTeleport = CreateTrie();
	new Handle:hGameData = LoadGameConfigFile("sdktools.games");
	if(hGameData == INVALID_HANDLE) 
	{
		SetFailState("GameConfigFile sdkhooks.games was not found.")
		return
	}
	new iOffset = GameConfGetOffset(hGameData, "Teleport");
	CloseHandle(hGameData);
	if(iOffset == -1)
		return;

	if(LibraryExists("dhooks"))
	{
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if(g_hTeleport == INVALID_HANDLE)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_Bool);
	}

	// MultiPlayer Bunny Hops: Source
	// https://forums.alliedmods.net/showthread.php?p=808724
	g_Offs_vecOrigin = FindSendPropInfo("CBaseEntity","m_vecOrigin");
	g_Offs_vecMins = FindSendPropInfo("CBaseEntity","m_vecMins");
	g_Offs_vecMaxs = FindSendPropInfo("CBaseEntity","m_vecMaxs");
	new Handle:hGameConf = LoadGameConfigFile("sdkhooks.games")
	StartPrepSDKCall(SDKCall_Entity)
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"Touch")
	PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer)
	g_hSDK_Touch = EndPrepSDKCall()
	CloseHandle(hGameConf)
	if(g_hSDK_Touch == INVALID_HANDLE) 
	{
		SetFailState("Unable to prepare virtual function CBaseEntity::Touch")
		return
	}
		
	// 		
	if(g_bLateLoaded) 
	{ 
		//OnPluginPauseChange(false);	
		CreateTimer(3.0, LoadPlayerSettings, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}

}

public OnPluginPauseChange(bool:pause1) 
{
	if (pause1) 
	{
		AlterBhopBlocks(true);
		g_BhopDoorCount = 0;
		g_BhopButtonCount = 0;
		for(new i = 0; i < g_BhopMultipleCount; i++) 
		{
			new ent = g_BhopMultipleList[i];
			if(IsValidEntity(ent)) 
				SDKUnhook(ent,SDKHook_StartTouch,Entity_Touch2);
		}
	}
	else
	{
		g_BhopDoorCount = 0;
		g_BhopButtonCount = 0;	
		g_BhopMultipleCount = 0;
		FindBhopBlocks();
		FindMultipleBlocks();
	}
}

public OnLibraryAdded(const String:name[])
{	
	if (StrEqual("hookgrabrope", name))
		g_bHookMod = true;
	new Handle:tmp = FindPluginByFile("mapchooser_extended.smx");
	if ((StrEqual("mapchooser", name)) ||(tmp != INVALID_HANDLE && GetPluginStatus(tmp) == Plugin_Running))
		g_bMapChooser = true;
	if (tmp != INVALID_HANDLE)
		CloseHandle(tmp);
	
	//botmimic 2
	if(StrEqual(name, "dhooks") && g_hTeleport == INVALID_HANDLE)
	{
		// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
		new Handle:hGameData = LoadGameConfigFile("sdktools.games");
		if(hGameData == INVALID_HANDLE)
			return;
		new iOffset = GameConfGetOffset(hGameData, "Teleport");
		CloseHandle(hGameData);
		if(iOffset == -1)
			return;
		
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if(g_hTeleport == INVALID_HANDLE)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		if(GetEngineVersion() == Engine_CSGO)
			DHookAddParam(g_hTeleport, HookParamType_Bool);
		
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public OnPluginEnd()
{
	//remove climb buttons
	DeleteButtons(67);
	
	//remove clan tags
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x))
		{
			SetEntPropEnt(x, Prop_Send, "m_bSpotted", 1);
			SetEntProp(x, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(x, Prop_Send, "m_iAccount", 1);			
			CS_SetClientClanTag(x, "");
			OnClientDisconnect(x);
		}
 	}
		
	//unhook
	UnhookEntityOutput("trigger_teleport", "OnStartTouch", Teleport_OnStartTouch);	
	UnhookEntityOutput("trigger_multiple", "OnStartTouch", Teleport_OnStartTouch);	
	UnhookEntityOutput("trigger_teleport", "OnEndTouch", Teleport_OnEndTouch);	
	UnhookEntityOutput("trigger_multiple", "OnEndTouch", Teleport_OnEndTouch);	
	UnhookEntityOutput("func_button", "OnPressed", ButtonPress);

	//set server convars back to default
	ServerCommand("sm_cvar sv_enablebunnyhopping 0;sv_friction 5.2;sv_accelerate 5.5;sv_airaccelerate 10;sv_maxvelocity 2000;sv_staminajumpcost .08;sv_staminalandcost .050");
	ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0;mp_respawnwavetime_ct 10.0;mp_respawnwavetime_t 10.0;bot_zombie 0;mp_ignore_round_win_conditions 0");
	ServerCommand("sv_infinite_ammo 0;mp_endmatch_votenextmap 1;mp_do_warmup_period 1;mp_warmuptime 60;mp_match_can_clinch 1;mp_match_end_changelevel 0");
	ServerCommand("mp_match_restart_delay 15;mp_endmatch_votenextleveltime 20;mp_endmatch_votenextmap 1;mp_halftime 0;mp_do_warmup_period 1;mp_maxrounds 0;bot_quota 0");		
	ServerCommand("mp_startmoney 800; mp_playercashawards 1; mp_teamcashawards 1");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		g_hAdminMenu = INVALID_HANDLE;
	if(StrEqual(name, "dhooks"))
		g_hTeleport = INVALID_HANDLE;
	if (StrEqual("hookgrabrope", name))
		g_bHookMod = false;
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("hookgrabrope"))
		g_bHookMod = true;
}

public OnMapStart()
{	
	ServerCommand("sv_pure 0");
	SetServerConvars();
	CheckSpawnPoints();
	
	//reload language files
	LoadTranslations("kztimer.phrases");	

	decl String:sPath[PLATFORM_MAX_PATH];
	decl String:line[64];

	//add mapmakers list 
	for (new x = 0; x < 100; x++)
		Format(g_szMapmakers[x],sizeof(g_szMapmakers), "");	
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", MAPPERS_PATH);
	new count = 0;
	new Handle:fileHandle = OpenFile(sPath,"r");	
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
	{			
		TrimString(line);
		if ((StrContains(line,"//",true) == -1) && count < 100)
		{
			Format(g_szMapmakers[count],sizeof(g_szMapmakers), "%s", line);
			count++;
		}		
	}
	
	//add blocked chat commands list
	for (new x = 0; x < 256; x++)
		Format(g_BlockedChatText[x],sizeof(g_BlockedChatText), "");	
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", BLOCKED_LIST_PATH);
	count = 0;
	fileHandle = OpenFile(sPath,"r");	
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
	{
		TrimString(line);
		if ((StrContains(line,"//",true) == -1) && count < 256)
		{
			Format(g_BlockedChatText[count],sizeof(g_BlockedChatText), "%s", line);
			count++;
		}
	}
	if (fileHandle != INVALID_HANDLE)
		CloseHandle(fileHandle);
	
	//defaults
	g_bFirstStartButtonPush=true;
	g_bFirstEndButtonPush=true;			
	g_fMapStartTime = GetEngineTime();
	g_fRecordTime=9999999.0;
	g_fRecordTimePro=9999999.0;
	g_fStartButtonPos = Float:{-999999.9,-999999.9,-999999.9};
	g_fEndButtonPos = Float:{-999999.9,-999999.9,-999999.9};
	g_fSpawnpointOrigin = Float:{-999999.9,-999999.9,-999999.9};
	g_fSpawnpointAngle = Float:{-999999.9,-999999.9,-999999.9};
	g_MapTimesCountPro = 0;
	g_MapTimesCountTp = 0;
	g_ProBot = -1;
	g_TpBot = -1;
	g_InfoBot = -1
	g_bAntiCheat = false;
	g_bAutoBhop=false;
	g_bRoundEnd=false;
	CheatFlag("bot_zombie", false, true);
	
	//get mapname
	GetCurrentMap(g_szMapName, 128);
	Format(g_szMapPath, sizeof(g_szMapPath), "maps/%s.bsp", g_szMapName); 	

	//workshop fix
	new String:mapPieces[6][128];
	new lastPiece = ExplodeString(g_szMapName, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
	Format(g_szMapName, sizeof(g_szMapName), "%s", mapPieces[lastPiece-1]); 
	
	//get map tag
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);
	StrToLower(g_szMapName);

	//precache
	InitPrecache();	
	SetCashState();
	
	//sql queries
	db_GetMapRecord_CP();
	db_GetMapRecord_Pro();
	db_CalculatePlayerCount();
	db_viewMapProRankCount();
	db_viewMapTpRankCount();
	db_ClearLatestRecords();
	db_GetDynamicTimelimit();
	db_CalcAvgRunTime();
	
	//timers
	CreateTimer(0.1, KZTimer1, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(1.0, KZTimer2, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(60.0, AttackTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(600.0, PlayerRanksTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(190.0, SpecInfo, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	//create buttons
	CreateTimer(2.0, CreateMapButtons, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);	
	
	//AutoBhop?
	if(StrEqual(g_szMapPrefix[0],"surf") || StrEqual(g_szMapPrefix[0],"bhop") || StrEqual(g_szMapPrefix[0],"mg"))
		if (g_bAutoBhopConVar)
			g_bAutoBhop=true;		
			
	//anticheat
	if((StrEqual(g_szMapPrefix[0],"kz") || StrEqual(g_szMapPrefix[0],"xc")  || StrEqual(g_szMapPrefix[0],"bkz") || StrEqual(g_szMapPrefix[0],"kzpro")) || g_bAutoBhop == false)
		g_bAntiCheat=true;

	//main cfg
	CreateTimer(1.0, DelayedStuff, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);	

	//server infos
	GetServerInfo();
	
	//Bhop block stuff
	g_BhopDoorCount = 0;
	g_BhopButtonCount = 0;	
	g_BhopMultipleCount = 0;
	FindBhopBlocks();
	FindMultipleBlocks();
		
	//Bots
	LoadReplays();
	LoadInfoBot();
	
	if (g_bLateLoaded)
	{
		OnConfigsExecuted();
		OnAutoConfigsBuffered();
	}
	
	for (new i = 1; i <= MaxClients; i++)
		g_Skillgroup[i] = 0;
		
}

public OnMapEnd()
{
	AlterBhopBlocks(true);
	g_BhopDoorCount = 0;
	g_ProBot = -1;
	g_TpBot = -1;
	g_BhopButtonCount = 0;
	g_BhopMultipleCount = 0;
	for(new i = 0; i < g_BhopMultipleCount; i++) 
	{
		new ent = g_BhopMultipleList[i];
		if(IsValidEntity(ent)) 
		{
			SDKUnhook(ent,SDKHook_StartTouch,Entity_Touch2);
		}
	}
	ServerCommand("bot_quota 0");
	db_Cleanup();
}

public OnConfigsExecuted()
{
	new String:map[128];
	new String:map2[128];
	new mapListSerial = -1;
	new MapCountPro;
	g_pr_MapCount=0;
	g_pr_MapCountTp = 0;
	if (ReadMapList(g_MapList, 
			mapListSerial, 
			"mapcyclefile", 
			MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT)
		== INVALID_HANDLE)
	{
		if (mapListSerial == -1)
		{
			SetFailState("<KZTIMER> Mapcycle.txt is empty or does not exists.");
		}
	}
	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{
		GetArrayString(g_MapList, i, map, sizeof(map));
		if (!StrEqual(map, "", false))
		{
			//fix workshop map name			
			new String:mapPieces[6][128];
			new String:prefix[2][32];
			new lastPiece = ExplodeString(map, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
			Format(map2, sizeof(map2), "%s", mapPieces[lastPiece-1]); 
			SetArrayString(g_MapList, i, map2);
			g_pr_MapCount++;

			ExplodeString(map2, "_", prefix, 2, 32);			
			if(StrEqual(prefix[0],"kzpro"))
				MapCountPro++;		
		}
	}	
	g_pr_MapCountTp = g_pr_MapCount - MapCountPro;
	
	//skillgroups
	SetSkillGroups();

	//get mapname
	GetCurrentMap(g_szMapName, 128);
	Format(g_szMapPath, sizeof(g_szMapPath), "maps/%s.bsp", g_szMapName); 	
			
	//workshop fix
	new String:mapPieces[6][128];
	new lastPiece = ExplodeString(g_szMapName, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
	Format(g_szMapName, sizeof(g_szMapName), "%s", mapPieces[lastPiece-1]); 
   
	//get map tag
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);
	StrToLower(g_szMapName);		

	//AutoBhop?
	if(StrEqual(g_szMapPrefix[0],"surf") || StrEqual(g_szMapPrefix[0],"bhop") || StrEqual(g_szMapPrefix[0],"mg"))
		if (g_bAutoBhopConVar)
			g_bAutoBhop=true;		
	
	//cheat protection
	if((StrEqual(g_szMapPrefix[0],"kz") || StrEqual(g_szMapPrefix[0],"xc") || StrEqual(g_szMapPrefix[0],"bkz") || StrEqual(g_szMapPrefix[0],"kzpro")) || g_bAutoBhop == false)
		g_bAntiCheat=true;

	ServerCommand("sv_pure 0");	
}


public OnAutoConfigsBuffered() 
{
	//just to be sure that it's not empty
	decl String:szMap[128];  
	decl String:szPrefix[2][32];  
	GetCurrentMap(szMap, 128);
	decl String:mapPieces[6][128];
	new lastPiece = ExplodeString(szMap, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
	Format(szMap, sizeof(szMap), "%s", mapPieces[lastPiece-1]); 
 	ExplodeString(szMap, "_", szPrefix, 2, 32);

	//map tag kzpro?
	if (StrEqual("kzpro", szPrefix[0]))
		Format(szPrefix[0], 32, "kz"); 
	
	//map config
	decl String:szPath[256];		
	Format(szPath, sizeof(szPath), "sourcemod/kztimer/map_types/%s_.cfg",szPrefix[0]);
	decl String:szPath2[256];
	Format(szPath2, sizeof(szPath2), "cfg/%s",szPath);
	if (FileExists(szPath2))
		ServerCommand("exec %s", szPath);
	else
		SetFailState("<KZTIMER> %s not found.", szPath2);
	
	SetServerTags();
}

public OnClientConnected(client)
	g_SelectedTeam[client]=0;

public OnClientPutInServer(client)
{
	
	if (!IsValidClient(client))
		return;

	g_pr_Calculating[client]=true;
	 
	//SDKHooks/Dhooks
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost); 
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);	
	SDKHook(client, SDKHook_StartTouch, Hook_OnTouch);
	SDKHook(client, SDKHook_PostThink, Hook_PostThink);	
	if (IsFakeClient(client))
	{
		g_hRecordingAdditionalTeleport[client] = CreateArray(_:AdditionalTeleport);
		CS_SetMVPCount(client,1);	
		return;
	}	
	else
		g_MVPStars[client] = 0;	
			
	//defaults
	SetClientDefaults(client);
	
	//client country
	GetCountry(client);		

	//client language
	if (g_bUseCPrefs && !IsFakeClient(client))
		if (AreClientCookiesCached(client) && !g_bLoaded[client])
			LoadCookies(client);
			

	if(LibraryExists("dhooks"))
		DHookEntity(g_hTeleport, false, client);	
	
	//get client data
	GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], 32, true);
	
	db_viewPlayerOptions(client, g_szSteamID[client]);	
 	db_viewPersonalRecords(client,g_szSteamID[client],g_szMapName);	
	db_viewPersonalBhopRecord(client, g_szSteamID[client]);
	db_viewPersonalMultiBhopRecord(client, g_szSteamID[client]);	
	db_viewPersonalWeirdRecord(client, g_szSteamID[client]);
	db_viewPersonalDropBhopRecord(client, g_szSteamID[client]); 
	db_viewPersonalLJBlockRecord(client, g_szSteamID[client]);
	db_viewPersonalLadderJumpRecord(client, g_szSteamID[client]);
	db_viewPersonalCJRecord(client, g_szSteamID[client]);
	db_viewPersonalLJRecord(client, g_szSteamID[client]);
	
	// ' char fix
	FixPlayerName(client);
	
	//position restoring
	if(g_bRestore)
		db_selectLastRun(client);		
			
	//console info
	PrintConsoleInfo(client);
	
	if (g_bLateLoaded && IsPlayerAlive(client))
		PlayerSpawn(client);
	
}

public OnClientAuthorized(client)
{
	if (g_bConnectMsg && !IsFakeClient(client))
	{
		decl String:s_Country[32];
		decl String:s_clientName[32];
		decl String:s_address[32];		
		GetClientIP(client, s_address, 32);
		GetClientName(client, s_clientName, 32);
		Format(s_Country, 100, "Unknown");
		GeoipCountry(s_address, s_Country, 100);     
		if(!strcmp(s_Country, NULL_STRING))
			Format( s_Country, 100, "Unknown", s_Country );
		else				
			if( StrContains( s_Country, "United", false ) != -1 || 
				StrContains( s_Country, "Republic", false ) != -1 || 
				StrContains( s_Country, "Federation", false ) != -1 || 
				StrContains( s_Country, "Island", false ) != -1 || 
				StrContains( s_Country, "Netherlands", false ) != -1 || 
				StrContains( s_Country, "Isle", false ) != -1 || 
				StrContains( s_Country, "Bahamas", false ) != -1 || 
				StrContains( s_Country, "Maldives", false ) != -1 || 
				StrContains( s_Country, "Philippines", false ) != -1 || 
				StrContains( s_Country, "Vatican", false ) != -1 )
			{
				Format( s_Country, 100, "The %s", s_Country );
			}				
					
		if (StrEqual(s_Country, "Unknown",false) || StrEqual(s_Country, "Localhost",false))
		{	
			for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != client)
				PrintToChat(i, "%t", "Connected1", WHITE,MOSSGREEN, s_clientName, WHITE);
		}
		else
		{
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i) && i != client)
					PrintToChat(i, "%t", "Connected2", WHITE, MOSSGREEN,s_clientName, WHITE,GREEN,s_Country);
		}
	}
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client) && g_hRecordingAdditionalTeleport[client] != INVALID_HANDLE)
		CloseHandle(g_hRecordingAdditionalTeleport[client]);

	g_fPlayerLastTime[client] = -1.0;
	if(g_fStartTime[client] != -1.0 && g_bTimeractivated[client])
	{
		if (g_bPause[client])
		{
			g_fPauseTime[client] = GetEngineTime() - g_fStartPauseTime[client];
			g_fPlayerLastTime[client] = GetEngineTime() - g_fStartTime[client] - g_fPauseTime[client];	
		}
		else
			g_fPlayerLastTime[client] = g_fCurrentRunTime[client];
	}
		
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost); 
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);	
	SDKUnhook(client, SDKHook_StartTouch, Hook_OnTouch);
	SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
	
	if (client == g_ProBot || client == g_TpBot)
	{
		StopPlayerMimic(client);
		if (client == g_ProBot)
			g_ProBot = -1;
		else
			g_TpBot = -1;
		return;
	}	

	//Database	
	if (IsValidClient(client))
	{
		db_insertLastPosition(client,g_szMapName);
		db_updatePlayerOptions(client);
	}	
	
	// Stop recording
	if(g_hRecording[client] != INVALID_HANDLE)
		StopRecording(client);

	// Macrodox
	ResetPos(client);
	g_aiJumps[client] = 0;
	g_fafAvgJumps[client] = 5.0;
	g_fafAvgSpeed[client] = 250.0;
	g_fafAvgPerfJumps[client] = 0.3333;
	g_bFlagged[client] = false;
	g_favVEL[client][2] = 0.0;

	//language
	g_bLoaded[client] = false;
}

public OnClientCookiesCached(client)
{
	if (IsFakeClient(client))
		return;
	
	// If they aren't in-game yet then we'll catch them on the PutInServer forward.
	if (IsClientInGame(client) && !g_bLoaded[client])
	{
		LoadCookies(client);
	}
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	if(convar == g_hGoToServer)
	{
		if(newValue[0] == '1')
			g_bGoToServer = true;
		else
			g_bGoToServer = false;
	}		
	if(convar == g_hChallengePoints)
	{
		if(newValue[0] == '1')
			g_bChallengePoints = true;
		else
			g_bChallengePoints = false;
	}
	if(convar == g_hPreStrafe)
	{
		if(newValue[0] == '1')
			g_bPreStrafe = true;
		else
		{
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					SetEntPropFloat(i, Prop_Send, "m_flVelocityModifier", 1.0);						
			g_bPreStrafe = false;
		}
	}	
	if(convar == g_hNoClipS)
	{
		if(newValue[0] == '1')
			g_bNoClipS = true;
		else
			g_bNoClipS = false;
	}	
	if(convar == g_hAutoBan)
	{
		if(newValue[0] == '1')
			g_bAutoBan = true;
		else
			g_bAutoBan = false;
	}	
	if(convar == g_hReplayBot)
	{
		if(newValue[0] == '1')
		{
			g_bReplayBot = true;
			LoadReplays();
		}
		else
		{		
			for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i))	
			{
				if (i == g_TpBot || i == g_ProBot)
				{
					StopPlayerMimic(i);
					KickClient(i);					
				}
				else 
				{
					if(g_hRecording[i] != INVALID_HANDLE)
						StopRecording(i);
				}				
			}
			if (g_bInfoBot)
				ServerCommand("bot_quota 1");
			else
				ServerCommand("bot_quota 0");
			g_bReplayBot = false;	
		}
	}
	if(convar == g_hAdminClantag)
	{
		if(newValue[0] == '1')
		{
			g_bAdminClantag = true;
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);						
		}
		else
		{
			g_bAdminClantag = false;
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
	}	
	if(convar == g_hVipClantag)
	{
		if(newValue[0] == '1')
		{
			g_bVipClantag = true;
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
		else
		{
			g_bVipClantag = false;
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
	}
	if(convar == g_hAutoTimer)
	{
		if(newValue[0] == '1')
			g_bAutoTimer = true;
		else
			g_bAutoTimer = false;
	}		
	if(convar == g_hPauseServerside)
	{
		if(newValue[0] == '1')
			g_bPauseServerside = true;
		else
			g_bPauseServerside = false;
	}
	if(convar == g_hDynamicTimelimit)
	{
		if(newValue[0] == '1')
			g_bDynamicTimelimit = true;
		else
			g_bDynamicTimelimit = false;
	}	
	if(convar == g_hAutohealing_Hp)
		g_Autohealing_Hp = StringToInt(newValue[0]);	
	if(convar == g_hTeam_Restriction)
		g_Team_Restriction = StringToInt(newValue[0]);	
		
	if(convar == g_hAutoRespawn)
	{
		if(newValue[0] == '1')
		{
			ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
			g_bAutoRespawn = true;
		}
		else
		{
			ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");
			g_bAutoRespawn = false;
		}
	}	
	if(convar == g_hAllowCheckpoints)
	{
		if(newValue[0] == '1')
			g_bAllowCheckpoints = true;
		else
			g_bAllowCheckpoints = false;
	}
	if(convar == g_hRadioCommands)
	{
		if(newValue[0] == '1')
			g_bRadioCommands = true;
		else
			g_bRadioCommands = false;
	}	
	if(convar == g_hcvarRestore)
	{
		if(newValue[0] == '1')
			g_bRestore = true;			
		else
			g_bRestore = false;
	}
	if(convar == g_hMapEnd)
	{
		if(newValue[0] == '1')
			g_bMapEnd = true;			
		else
			g_bMapEnd = false;
	}
	if(convar == g_hConnectMsg)
	{
		if(newValue[0] == '1')
			g_bConnectMsg = true;			
		else
			g_bConnectMsg = false;
	}
	if(convar == g_hPlayerSkinChange)
	{
		if(newValue[0] == '1')
		{
			g_bPlayerSkinChange = true;
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
				{
					if (i == g_TpBot)
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", g_sReplayBotArmModel2);
						SetEntityModel(i,  g_sReplayBotPlayerModel2);
					}					
					else
						if (i == g_ProBot)
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", g_sReplayBotPlayerModel);
							SetEntityModel(i,  g_sReplayBotPlayerModel);
						}
						else
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", g_sArmModel);
							SetEntityModel(i,  g_sPlayerModel);
						}
				}
		}
		else
			g_bPlayerSkinChange = false;
	}	
	if(convar == g_hPointSystem)
	{
		if(newValue[0] == '1')
		{
			g_bPointSystem = true;		
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))				
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);					
		}
		else
		{
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					Format(g_pr_rankname[i], 32, "");
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);
				}
			g_bPointSystem = false;
		}
	}		
	if(convar == g_hAttackSpamProtection)
	{
		if(newValue[0] == '1')
		{
			g_bAttackSpamProtection = true;
		}
		else
		{	
			g_bAttackSpamProtection = false;
		}
	}		
	if(convar == g_hCleanWeapons)
	{
		if(newValue[0] == '1')
		{
			decl String:szclass[32];
			g_bCleanWeapons = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i))
				{
					for(new j = 0; j < 4; j++)
					{
						new weapon = GetPlayerWeaponSlot(i, j);
						if(weapon != -1 && j != 2)
						{
							GetEdictClassname(weapon, szclass, sizeof(szclass));
							RemovePlayerItem(i, weapon);
							RemoveEdict(weapon);							
							new equipweapon = GetPlayerWeaponSlot(i, 2)
							if (equipweapon != -1)
								EquipPlayerWeapon(i, equipweapon); 
						}
					}
				}
			}
			
		}
		else
			g_bCleanWeapons = false;
	}	
	if(convar == g_hEnforcer)
	{
		if(newValue[0] == '1')		
		{
			g_bEnforcer = true;
			SetConVarFloat(g_hStaminaLandCost, 0.0);
			SetConVarFloat(g_hStaminaJumpCost, 0.0);
			SetConVarFloat(g_hMaxSpeed, 320.0);
			SetConVarFloat(g_hGravity, 800.0);
			SetConVarFloat(g_hAirAccelerate, 100.0);
			SetConVarFloat(g_hFriction, 5.0);
			SetConVarFloat(g_hAccelerate, 6.5);
			SetConVarFloat(g_hMaxVelocity, 2000.0);
			SetConVarFloat(g_hBhopSpeedCap, 380.0);
			SetConVarFloat(g_hWaterAccelerate, 10.0);
			SetConVarInt(g_hCheats, 0);
			SetConVarInt(g_hEnableBunnyhoping, 1);		
		}
		else
			g_bEnforcer = false;
	}	
	if(convar == g_hJumpStats)
	{
		if(newValue[0] == '1')		
			g_bJumpStats = true;
		else
			g_bJumpStats = false;
	}
	if(convar == g_hSlayPlayers)
	{
		if(newValue[0] == '1')		
			g_bSlayPlayers = true;
		else
			g_bSlayPlayers = false;
	}
	if(convar == g_hDoubleDuckCvar)
	{
		if(newValue[0] == '1')		
			g_bDoubleDuckCvar = true;
		else
			g_bDoubleDuckCvar = false;
	}
	if(convar == g_hAllowRoundEndCvar)
	{
		if(newValue[0] == '1')		
		{
			ServerCommand("mp_ignore_round_win_conditions 0");
			g_bAllowRoundEndCvar = true;
		}
		else
		{
			ServerCommand("mp_ignore_round_win_conditions 1;mp_maxrounds 1");
			g_bAllowRoundEndCvar = false;
		}
	}	
	if(convar == g_hSingleTouch)
	{
		if(newValue[0] == '1')		
			g_bSingleTouch = true;
		else
			g_bSingleTouch = false;
	}		
	if(convar == g_hAutoBhopConVar)
	{
		if(newValue[0] == '1')		
		{		
			g_bAutoBhopConVar = true;		
			if(StrEqual(g_szMapPrefix[0],"surf") || StrEqual(g_szMapPrefix[0],"bhop") || StrEqual(g_szMapPrefix[0],"mg"))
			{
				g_bAntiCheat	= false;
				g_bAutoBhop = true;
			}
		}
		else
		{
			g_bAutoBhopConVar = false;
			g_bAutoBhop = false;
			g_bAntiCheat = true;
		}
	}		
		
	if(convar == g_hCountry)
	{
		if(newValue[0] == '1')
		{
			g_bCountry = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					GetCountry(i);
					if (g_bPointSystem)
						CreateTimer(0.5, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		else
		{
			g_bCountry = false;
			if (g_bPointSystem)
				for (new i = 1; i <= MaxClients; i++)
					if (IsValidClient(i))				
						CreateTimer(0.5, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
	}		
	if(convar == g_hMinSkillGroup)
		g_MinSkillGroup = StringToInt(newValue[0]);			
		
	if(convar == g_hExtraPoints)
		g_ExtraPoints = StringToInt(newValue[0]);	
		
	if(convar == g_hExtraPoints2)
		g_ExtraPoints2 = StringToInt(newValue[0]);			
	
	if(convar == g_hdist_good_multibhop)
		g_dist_min_multibhop = StringToFloat(newValue[0]);	

	if(convar == g_hdist_impressive_multibhop)
		g_dist_impressive_multibhop = StringToFloat(newValue[0]);			
		
	if(convar == g_hdist_perfect_multibhop)
		g_dist_perfect_multibhop = StringToFloat(newValue[0]);			
	
	if(convar == g_hdist_godlike_multibhop)
		g_dist_god_multibhop = StringToFloat(newValue[0]);	
	
	if(convar == g_hdist_good_bhop)
		g_dist_min_bhop = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_impressive_bhop)
		g_dist_impressive_bhop = StringToFloat(newValue[0]);		
		
	if(convar == g_hdist_perfect_bhop)
		g_dist_perfect_bhop = StringToFloat(newValue[0]);		
	
	if(convar == g_hdist_godlike_bhop)
		g_dist_god_bhop = StringToFloat(newValue[0]);		

	if(convar == g_hdist_good_dropbhop)
		g_dist_min_dropbhop = StringToFloat(newValue[0]);

	if(convar == g_hdist_impressive_dropbhop)
		g_dist_impressive_dropbhop = StringToFloat(newValue[0]);		
		
	if(convar == g_hdist_perfect_dropbhop)
		g_dist_perfect_dropbhop = StringToFloat(newValue[0]);		
	
	if(convar == g_hdist_godlike_dropbhop)
		g_dist_god_dropbhop = StringToFloat(newValue[0]);	

	if(convar == g_hdist_good_weird)
		g_dist_min_weird = StringToFloat(newValue[0]);

	if(convar == g_hdist_impressive_weird)
		g_dist_impressive_weird = StringToFloat(newValue[0]);	
		
	if(convar == g_hdist_perfect_weird)
		g_dist_perfect_weird = StringToFloat(newValue[0]);		
	
	if(convar == g_hdist_godlike_weird)
		g_dist_god_weird = StringToFloat(newValue[0]);	
	
	if(convar == g_hdist_good_lj)
		g_dist_min_lj = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_impressive_lj)
		g_dist_impressive_lj = StringToFloat(newValue[0]);
		
	if(convar == g_hdist_perfect_lj)
		g_dist_perfect_lj = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_godlike_lj)
		g_dist_god_lj = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_good_countjump)
		g_dist_min_countjump = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_impressive_countjump)
		g_dist_impressive_countjump = StringToFloat(newValue[0]);
		
	if(convar == g_hdist_perfect_countjump)
		g_dist_perfect_countjump = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_godlike_countjump)
		g_dist_god_countjump = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_good_ladder)
		g_dist_min_ladder = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_impressive_ladder)
		g_dist_impressive_ladder = StringToFloat(newValue[0]);
		
	if(convar == g_hdist_perfect_ladder)
		g_dist_perfect_ladder = StringToFloat(newValue[0]);
	
	if(convar == g_hdist_godlike_ladder)
		g_dist_god_ladder = StringToFloat(newValue[0]);
	
	if(convar == g_hBanDuration)
		g_fBanDuration = StringToFloat(newValue[0]);
	
	if(convar == g_hMaxBhopPreSpeed)
		g_fMaxBhopPreSpeed = StringToFloat(newValue[0]);	
	
	if(convar == g_hcvargodmode)
	{
		if(newValue[0] == '1')
			g_bgodmode = true;
		else
			g_bgodmode = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{	
				if (g_bgodmode)
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				else
					SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}
	}	
	if(convar == g_hInfoBot)
	{
		if(newValue[0] == '1')		
		{
			g_bInfoBot = true;
			LoadInfoBot();
		}
		else
		{
			g_bInfoBot = false;
			for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && IsFakeClient(i))	
			{
				if (i == g_InfoBot)
				{
					new count = 0;
					g_InfoBot = -1;
					KickClient(i);		
					decl String:szBuffer[64];
					if(g_bProReplay)
						count++;
					if(g_bTpReplay)
						count++;
					Format(szBuffer, sizeof(szBuffer), "bot_quota %i", count); 	
					ServerCommand(szBuffer);							
				}
			}
		}
	}	
	if(convar == g_hReplayBotPlayerModel)
	{
		Format(g_sReplayBotPlayerModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);
		AddFileToDownloadsTable(g_sReplayBotPlayerModel);
		if (g_ProBot != -1)
			SetEntityModel(g_ProBot,  newValue[0]);	
	}
	if(convar == g_hReplayBotArmModel)
	{
		Format(g_sReplayBotArmModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);		
		AddFileToDownloadsTable(g_sReplayBotArmModel);
		if (g_ProBot != -1)
				SetEntPropString(g_ProBot, Prop_Send, "m_szArmsModel", newValue[0]);	
	}
	if(convar == g_hReplayBotPlayerModel2)
	{
		Format(g_sReplayBotPlayerModel2,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);
		AddFileToDownloadsTable(g_sReplayBotPlayerModel2);
		if (g_TpBot != -1)
			SetEntityModel(g_TpBot,  newValue[0]);
	}
	if(convar == g_hReplayBotArmModel2)
	{
		Format(g_sReplayBotArmModel2,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);		
		AddFileToDownloadsTable(g_sReplayBotArmModel2);
		if (g_TpBot != -1)
				SetEntPropString(g_TpBot, Prop_Send, "m_szArmsModel", newValue[0]);
	}
	if(convar == g_hPlayerModel)
	{
		Format(g_sPlayerModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);	
		AddFileToDownloadsTable(g_sPlayerModel);
		if (!g_bPlayerSkinChange)
			return;
		for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_TpBot && i != g_ProBot)	
				SetEntityModel(i,  newValue[0]);
	}
	if(convar == g_hArmModel)
	{
		Format(g_sArmModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);		
		AddFileToDownloadsTable(g_sArmModel);
		if (!g_bPlayerSkinChange)
			return;
		for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_TpBot && i != g_ProBot)	
				SetEntPropString(i, Prop_Send, "m_szArmsModel", newValue[0]);
	}	
	if(convar == g_hWelcomeMsg)
		Format(g_sWelcomeMsg,512,"%s", newValue[0]);
	
	if(convar == g_hReplayBotTpColor)
	{
		decl String:color[256];
		Format(color,256,"%s", newValue[0]);
		GetRGBColor(1,color);	
	}	
	if(convar == g_hReplayBotProColor)
	{
		decl String:color[256];
		Format(color,256,"%s", newValue[0]);
		GetRGBColor(0,color);
	}		
	
	//Settings Enforcer
	if(convar == g_hBhopSpeedCap)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 380.0)
			SetConVarFloat(g_hBhopSpeedCap, 380.0);
		else
			g_fBhopSpeedCap = StringToFloat(newValue[0]);	
	}
	
	if(convar == g_hStaminaLandCost)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 0.0)
			SetConVarFloat(g_hStaminaLandCost, 0.0);			
	}	
	if(convar == g_hStaminaJumpCost)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 0.0)
			SetConVarFloat(g_hStaminaJumpCost, 0.0);			
	}	
	if(convar == g_hMaxSpeed)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 320.0)
			SetConVarFloat(g_hMaxSpeed, 320.0);			
	}
	
	if(convar == g_hGravity)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 800.0)
			SetConVarFloat(g_hGravity, 800.0);			
	}
	if(convar == g_hAirAccelerate)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 100.0)
			SetConVarFloat(g_hAirAccelerate, 100.0);			
	}
	if(convar == g_hFriction)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 5.0)
			SetConVarFloat(g_hFriction, 5.0);			
	}
	if(convar == g_hAccelerate)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 6.5)
			SetConVarFloat(g_hAccelerate, 6.5);			
	}
	if(convar == g_hMaxVelocity)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 2000.0)
			SetConVarFloat(g_hMaxVelocity, 2000.0);			
	}
	if(convar == g_hWaterAccelerate)
	{
		new Float:fTmp = StringToFloat(newValue[0]);
		if (g_bEnforcer && fTmp != 10.0)
			SetConVarFloat(g_hWaterAccelerate, 10.0);	
	}
	if(convar == g_hCheats)
	{			
		new iTmp = StringToInt(newValue[0]);
		if (g_bEnforcer && iTmp != 0)
			SetConVarInt(g_hCheats, 0);			
	}
	if(convar == g_hMaxRounds)
	{			
		if (!g_bAllowRoundEndCvar)
			SetConVarInt(g_hMaxRounds, 1);			
	}	
	if(convar == g_hEnableBunnyhoping)
	{
		new iTmp = StringToInt(newValue[0]);
		if (g_bEnforcer && iTmp != 1)
			SetConVarInt(g_hEnableBunnyhoping, 1);	
	}
}

public Native_GetTimerStatus(Handle:plugin, numParams)
	return g_bTimeractivated[GetNativeCell(1)];

public Native_StopUpdatingOfClimbersMenu(Handle:plugin, numParams)
{
	g_bMenuOpen[GetNativeCell(1)] = true;
	if (g_hclimbersmenu[GetNativeCell(1)] != INVALID_HANDLE)
	{	
		g_hclimbersmenu[GetNativeCell(1)] = INVALID_HANDLE;
	}
	if (g_bClimbersMenuOpen[GetNativeCell(1)])
		g_bClimbersMenuwasOpen[GetNativeCell(1)]=true;
	else
		g_bClimbersMenuwasOpen[GetNativeCell(1)]=false;
	g_bClimbersMenuOpen[GetNativeCell(1)] = false;		
}

public Native_StopTimer(Handle:plugin, numParams)
	Client_Stop(GetNativeCell(1),0);

public Native_GetCurrentTime(Handle:plugin, numParams)
	return _:g_fCurrentRunTime[GetNativeCell(1)];

public Native_GetSkillGroup(Handle:plugin, numParams)
	return g_Skillgroup[GetNativeCell(1)];

public Native_GetAvgTimeTp(Handle:plugin, numParams)
{
	if (g_MapTimesCountTp==0)
		return _:0.0;
	else
		return _:g_favg_tptime;
}	

public Native_GetAvgTimePro(Handle:plugin, numParams)
{
	if (g_MapTimesCountPro==0)
		return _:0.0;
	else
		return _:g_favg_protime;
}
		
public Native_EmulateStartButtonPress(Handle:plugin, numParams)
{
	g_bLegitButtons[GetNativeCell(1)] = false;
	CL_OnStartTimerPress(GetNativeCell(1));
}
	
public Native_EmulateStopButtonPress(Handle:plugin, numParams)
{
	g_bLegitButtons[GetNativeCell(1)] = false;
	CL_OnEndTimerPress(GetNativeCell(1))
}		

public Plugin:myinfo =
{
	name = "KZTimer",
	author = "1NutWunDeR",
	description = "timer plugin",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=223274"
}