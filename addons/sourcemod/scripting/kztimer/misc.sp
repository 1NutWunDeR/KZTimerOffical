public SetServerConvars()
{
	ConVar cvWinConditions = FindConVar("mp_ignore_round_win_conditions");
	ConVar mp_respawn_on_death_ct = FindConVar("mp_respawn_on_death_ct");
	ConVar mp_respawn_on_death_t = FindConVar("mp_respawn_on_death_t");		
	ConVar host_players_show = FindConVar("host_players_show");
	ConVar sv_max_queries_sec = FindConVar("sv_max_queries_sec");
	ConVar sv_full_alltalk = FindConVar("sv_full_alltalk");
	ConVar sv_infinite_ammo = FindConVar("sv_infinite_ammo");
	ConVar mp_do_warmup_period = FindConVar("mp_do_warmup_period");
	ConVar mp_warmuptime = FindConVar("mp_warmuptime");
	ConVar mp_match_can_clinch = FindConVar("mp_match_can_clinch");
	ConVar mp_match_end_changelevel = FindConVar("mp_match_end_changelevel");
	ConVar mp_match_end_restart = FindConVar("mp_match_end_restart");
	ConVar mp_freezetime = FindConVar("mp_freezetime");
	ConVar mp_match_restart_delay = FindConVar("mp_match_restart_delay");
	ConVar mp_endmatch_votenextleveltime = FindConVar("mp_endmatch_votenextleveltime");
	ConVar mp_endmatch_votenextmap = FindConVar("mp_endmatch_votenextmap");
	ConVar mp_halftime = FindConVar("mp_halftime");	
	ConVar bot_zombie = FindConVar("bot_zombie");

	if (!g_bAllowRoundEndCvar)
	{	
		SetConVarBool(cvWinConditions, true);
		SetConVarInt(g_hMaxRounds, 1);
		SetConVarFloat(mp_freezetime, 0.0);
	}
	else	
		SetConVarBool(cvWinConditions, false);	
	
	if (g_bEnforcer)		
	{
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

	if (g_bAutoRespawn)
	{
		ConVar mp_respawnwavetime_ct = FindConVar("mp_respawnwavetime_ct");
		ConVar mp_respawnwavetime_t = FindConVar("mp_respawnwavetime_t");
		SetConVarInt(mp_respawn_on_death_ct, 1);
		SetConVarInt(mp_respawn_on_death_t, 1);
		SetConVarFloat(mp_respawnwavetime_ct, 3.0);
		SetConVarFloat(mp_respawnwavetime_t, 3.0);
	}
	else
	{
		SetConVarInt(mp_respawn_on_death_ct, 0);
		SetConVarInt(mp_respawn_on_death_t, 0);	
	}
	SetConVarInt(host_players_show, 2);
	SetConVarInt(sv_max_queries_sec, 6);
	SetConVarBool(sv_full_alltalk, true);
	SetConVarInt(sv_infinite_ammo, 2);
	SetConVarBool(mp_endmatch_votenextmap, false);
	SetConVarFloat(mp_warmuptime, 0.0);
	SetConVarBool(mp_match_can_clinch, false);
	SetConVarBool(mp_match_end_changelevel, true);
	SetConVarBool(mp_match_end_restart, false);
	SetConVarInt(mp_match_restart_delay, 10);
	SetConVarFloat(mp_endmatch_votenextleveltime, 3.0);
	SetConVarBool(mp_halftime, false);
	SetConVarBool(bot_zombie, true);
	SetConVarBool(mp_do_warmup_period, false);
}

public DoValidTeleport(client, Float:origin[3],Float:angles[3],bool:VEL_NULLVECTOR)
{
	if (!IsValidClient(client))
		return;
	g_bValidTeleport[client]=true;
	if (VEL_NULLVECTOR)
		TeleportEntity(client, origin, angles, NULL_VECTOR);
	else
		TeleportEntity(client, origin, angles, Float:{0.0,0.0,-100.0});
	CreateTimer(0.2, RemoveValidation, client,TIMER_FLAG_NO_MAPCHANGE);
}

public LadderCheck(client,Float:speed)
{
	decl Float:pos[3],Float:dist; 
	GetClientAbsOrigin(client, pos);
	dist = pos[2]- g_fLastPosition[client][2];
	if (GetEntityMoveType(client) == MOVETYPE_LADDER && dist > 0.5)
	{
		g_js_AvgLadderSpeed[client]+= speed;
		g_js_LadderFrames[client]++;
	}
	
	if(!(GetEntityFlags(client) & FL_ONGROUND) && GetEntityMoveType(client) == MOVETYPE_WALK && g_LastMoveType[client] == MOVETYPE_LADDER)
	{
		//start ladder jump
		if (g_js_LadderFrames[client] > 20)
		{
			new Float:AvgSpeed = g_js_AvgLadderSpeed[client] / g_js_LadderFrames[client];
			if (AvgSpeed < 100.0)
				Prethink(client, true);
		}
	}
	if (g_js_LadderFrames[client] > 0 && GetEntityMoveType(client) != MOVETYPE_LADDER)
	{
		g_js_AvgLadderSpeed[client] = 0.0;
		g_js_LadderFrames[client] = 0;	
	}
}

public CheckSpawnPoints() 
{
	if(StrEqual(g_szMapPrefix[0],"kz") || StrEqual(g_szMapPrefix[0],"xc")  || StrEqual(g_szMapPrefix[0],"kzpro") || StrEqual(g_szMapPrefix[0],"bkz") || StrEqual(g_szMapPrefix[0],"surf")  || StrEqual(g_szMapPrefix[0],"bhop"))
	{
		new ent, ct, t, spawnpoint;
		ct = 0;
		t= 0;	
		ent = -1;	
		while ((ent = FindEntityByClassname(ent, "info_player_terrorist")) != -1)
		{		
			if (t==0)
			{
				GetEntPropVector(ent, Prop_Data, "m_angRotation", g_fSpawnpointAngle); 
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", g_fSpawnpointOrigin);				
			}
			t++;
		}	
		while ((ent = FindEntityByClassname(ent, "info_player_counterterrorist")) != -1)
		{	
			if (ct==0 && t==0)
			{
				GetEntPropVector(ent, Prop_Data, "m_angRotation", g_fSpawnpointAngle); 
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", g_fSpawnpointOrigin);				
			}
			ct++;
		}	
		
		if (t > 0 || ct > 0)
		{
			if (t < 64)
			{
				while (t < 64)
				{
					spawnpoint = CreateEntityByName("info_player_terrorist");
					if (IsValidEntity(spawnpoint) && DispatchSpawn(spawnpoint))
					{
						ActivateEntity(spawnpoint);
						TeleportEntity(spawnpoint, g_fSpawnpointOrigin, g_fSpawnpointAngle, NULL_VECTOR);
						t++;
					}
				}		
			}

			if (ct < 64)
			{
				while (ct < 64)
				{
					spawnpoint = CreateEntityByName("info_player_counterterrorist");
					if (IsValidEntity(spawnpoint) && DispatchSpawn(spawnpoint))
					{
						ActivateEntity(spawnpoint);
						TeleportEntity(spawnpoint, g_fSpawnpointOrigin, g_fSpawnpointAngle, NULL_VECTOR);
						ct++;
					}
				}			
			}
		}
	}
}

public Action:CallAdmin_OnDrawOwnReason(client)
{
	g_bClientOwnReason[client] = true;
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
    if(client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
        return true;  
    return false;
}  

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
FormatLanguage(String:language[])
{
	// Format the input language.
	new length = strlen(language);
	
	if (length <= 1)
		return;
	
	// Capitalize first letter.
	language[0] = CharToUpper(language[0]);
	
	// Lower case the rest.
	for (new i = 1; i < length; i++)
	{
		language[i] = CharToLower(language[i]);
	}
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
LoadCookies(client)
{
	decl String:sCookie[4];
	sCookie[0] = '\0';
	g_bLanguageSelected[client] = true;
	GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));	
	if (sCookie[0] != '\0')
		SetClientLanguageByCode(client, sCookie);	
	else
		g_bLanguageSelected[client] = false;
	g_bLoaded[client] = true;
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
SetClientLanguageByCode(client, const String:code[])
{
	/* Set a client's language based on the language code. */
	new iLangID = GetLanguageByCode(code);	
	if (iLangID >= 0)
		SetClientLanguage(client, iLangID);
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
public LanguageMenu_Handler(Handle:menu, MenuAction:action, client, item)
{
	/* Handle the language selection menu. */
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			// Disable selection for currently used language.
			decl String:sLangID[4];
			GetMenuItem(menu, item, sLangID, sizeof(sLangID));
			
			if (StringToInt(sLangID) == GetClientLanguage(client))
			{
				return ITEMDRAW_DISABLED;
			}
			
			return ITEMDRAW_DEFAULT;
		}
		
		case MenuAction_Select:
		{
			decl String:sLangID[4], String:sLanguage[32];
			GetMenuItem(menu, item, sLangID, sizeof(sLangID), _, sLanguage, sizeof(sLanguage));
			
			new iLangID = StringToInt(sLangID);
			SetClientLanguage(client, iLangID);
			
			if (g_bUseCPrefs)
			{
				decl String:sLangCode[6];
				GetLanguageInfo(iLangID, sLangCode, sizeof(sLangCode));
				SetClientCookie(client, g_hCookie, sLangCode);
			}
			
			PrintToChat(client, "[%cKZ%c] Language changed to \"%s\".", MOSSGREEN,WHITE, sLanguage);
		}
	}
	
	return 0;
}


// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
Init_GeoLang()
{
	// Create and cache language selection menu.
	new Handle:hLangArray = CreateArray(32);
	decl String:sLangID[4];
	decl String:sLanguage[128];
	
	new maxLangs = GetLanguageCount();
	for (new i = 0; i < maxLangs; i++)
	{
		GetLanguageInfo(i, _, _, sLanguage, sizeof(sLanguage));
		if (StrEqual(sLanguage,"german") || StrEqual(sLanguage,"russian") || StrEqual(sLanguage,"schinese") || StrEqual(sLanguage,"english")  || StrEqual(sLanguage,"swedish")  || StrEqual(sLanguage,"french"))
		{
			FormatLanguage(sLanguage);
			PushArrayString(hLangArray, sLanguage);
		}
	}
	
	// Sort languages alphabetically.
	SortADTArray(hLangArray, Sort_Ascending, Sort_String);
	
	// Create and cache the menu.
	g_hLangMenu = CreateMenu(LanguageMenu_Handler, MenuAction_DrawItem);
	SetMenuTitle(g_hLangMenu, "KZTimer Language:");
	SetMenuPagination(g_hLangMenu, MENU_NO_PAGINATION); 
	
	maxLangs = GetArraySize(hLangArray);
	for (new i = 0; i < maxLangs; i++)
	{
		GetArrayString(hLangArray, i, sLanguage, sizeof(sLanguage));
		
		// Get language ID.
		IntToString(GetLanguageByName(sLanguage), sLangID, sizeof(sLangID));
		
		// Add to menu.
		if (StrEqual(sLanguage,"Schinese"))
			Format(sLanguage, 128, "Chinese");	
		AddMenuItem(g_hLangMenu, sLangID, sLanguage);
	}
	
	SetMenuExitButton(g_hLangMenu, true);
	
	CloseHandle(hLangArray);
}

// https://forums.alliedmods.net/showthread.php?p=1436866
// GeoIP Language Selection by GoD-Tony
public CookieMenu_GeoLanguage(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	/* Menu when accessed through !settings. */
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			Format(buffer, maxlen, "Language");
		}
		case CookieMenuAction_SelectOption:
		{
			DisplayMenu(g_hLangMenu, client, MENU_TIME_FOREVER);
		}
	}
}

public OnMapVoteStarted()
{
   	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		g_bMenuOpen[client] = true;
		if (g_bClimbersMenuOpen[client])
			g_bClimbersMenuwasOpen[client]=true;
		else
			g_bClimbersMenuwasOpen[client]=false;		
		g_bClimbersMenuOpen[client] = false;
	}
}

public SetSkillGroups()
{
	//Map Points	
	new mapcount;
	if (g_pr_MapCount < 1)
		mapcount = 1;
	else
		mapcount = g_pr_MapCount;	
	g_pr_PointUnit = 1; 
	new Float: MaxPoints = float(mapcount) * 1300.0 + 4000.0; //1300 = map max, 4000 = jumpstats max
	new g_RankCount = 0;
	
	decl String:sPath[PLATFORM_MAX_PATH], String:sBuffer[32];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/kztimer/skillgroups.cfg");	
	
	if (FileExists(sPath))
	{
		new Handle:hKeyValues = CreateKeyValues("KZTimer.SkillGroups");
		if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
		{
			do
			{
				if (g_RankCount <= 8)
				{
					KvGetString(hKeyValues, "name", g_szSkillGroups[g_RankCount], 32);
					KvGetString(hKeyValues, "percentage", sBuffer,32);
					if (g_RankCount != 0)
						g_pr_rank_Percentage[g_RankCount] = RoundToCeil(MaxPoints * StringToFloat(sBuffer));  
				}
				g_RankCount++;
			}
			while (KvGotoNextKey(hKeyValues));
		}
		if (hKeyValues != INVALID_HANDLE)
			CloseHandle(hKeyValues);
	}
	else
		SetFailState("<KZTIMER> addons/sourcemod/configs/kztimer/skillgroups.cfg not found.");
}

public SetServerTags()
{
	new Handle:CvarHandle;	
	CvarHandle = FindConVar("sv_tags");
	decl String:szServerTags[2048];
	GetConVarString(CvarHandle, szServerTags, 2048);
	if (StrContains(szServerTags,"KZTimer",true) == -1)
	{
		Format(szServerTags, 2048, "%s, KZTimer",szServerTags);
		SetConVarString(CvarHandle, szServerTags);		
	}
	if (StrContains(szServerTags,"KZTimer 1.",true) == -1 && StrContains(szServerTags,"Tickrate",true) == -1)
	{
		Format(szServerTags, 2048, "%s, KZTimer %s, Tickrate %i",szServerTags,VERSION,g_Server_Tickrate);
		SetConVarString(CvarHandle, szServerTags);
	}
	if (CvarHandle != INVALID_HANDLE)
		CloseHandle(CvarHandle);
}

public PrintConsoleInfo(client)
{
	new timeleft;
	GetMapTimeLeft(timeleft)
	new mins, secs;	
	decl String:finalOutput[1024];
	mins = timeleft / 60;
	secs = timeleft % 60;
	Format(finalOutput, 1024, "%d:%02d", mins, secs);
	new Float:fltickrate = 1.0 / GetTickInterval( );

	PrintToConsole(client, "-----------------------------------------------------------------------------------------------------------");
	PrintToConsole(client, "This server is running KZTimer v%s - Author: 1NuTWunDeR - Server tickrate: %i", VERSION, RoundToNearest(fltickrate));
	PrintToConsole(client, "Steam group of KZTimer: http://steamcommunity.com/groups/KZTIMER");
	if (timeleft > 0)
		PrintToConsole(client, "Timeleft on %s: %s",g_szMapName, finalOutput);
	PrintToConsole(client, "- Menu formatting is optimized for 1920x1080..");	
	PrintToConsole(client, "- Max recording time for replays: 120min");	
	PrintToConsole(client, "- It's not possible to hide the spec minimap for replay bots through coding.");	
	PrintToConsole(client, "But you can disable it by typing hideradar into your console!");	
	PrintToConsole(client, " ");
	PrintToConsole(client, "Client commands:");
	PrintToConsole(client, "!help, !help2, !menu, !options, !checkpoint, !gocheck, !prev, !next, !undo, !profile, !compare, !specs");
	PrintToConsole(client, "!bhopcheck, !maptop, top, !start, !stop, !pause, !challenge, !surrender, !goto, !spec, !wr, !avg,");
	PrintToConsole(client, "!showsettings, !latest, !measure, !ljblock, !ranks, !flashlight, !language, !usp, !globalcheck, !beam,");
	PrintToConsole(client, "!adv, !speed, !showkeys, !hide, !sync, !bhop, !hidechat, !hideweapon, !stopsound");
	PrintToConsole(client, " ");
	PrintToConsole(client, "Live scoreboard:");
	PrintToConsole(client, "Kills: Time in seconds");
	PrintToConsole(client, "Assists: Checkpoints");
	PrintToConsole(client, "Deaths: Teleports");
	PrintToConsole(client, "MVP Stars: Number of finished map runs on the current map");
	PrintToConsole(client, " ");
	PrintToConsole(client, "Skill groups:");
	PrintToConsole(client, "%s (%ip), %s (%ip), %s (%ip), %s (%ip)",g_szSkillGroups[1],g_pr_rank_Percentage[1],g_szSkillGroups[2], g_pr_rank_Percentage[2],g_szSkillGroups[3], g_pr_rank_Percentage[3],g_szSkillGroups[4], g_pr_rank_Percentage[4]);
	PrintToConsole(client, "%s (%ip), %s (%ip), %s (%ip), %s (%ip)",g_szSkillGroups[5], g_pr_rank_Percentage[5], g_szSkillGroups[6],g_pr_rank_Percentage[6], g_szSkillGroups[7], g_pr_rank_Percentage[7], g_szSkillGroups[8], g_pr_rank_Percentage[8]);
	PrintToConsole(client, "-----------------------------------------------------------------------------------------------------------");		
	PrintToConsole(client," ");
}
stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

stock Client_SetAssists(client, value)
{
	new assists_offset = FindDataMapOffs( client, "m_iFrags" ) + 4; 
	SetEntData(client, assists_offset, value );
}

public SetStandingStartButton(client)
{	
	CreateButton(client,"climb_startbuttonx");
}


public SetStandingStopButton(client)
{
	CreateButton(client,"climb_endbuttonx");
}

public Action:BlockRadio(client, const String:command[], args) 
{
	if(!g_bRadioCommands && IsValidClient(client))
	{
		PrintToChat(client, "%t", "RadioCommandsDisabled", LIMEGREEN,WHITE);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public StringToUpper(String:input[]) 
{
	for(new i = 0; ; i++) 
	{
		if(input[i] == '\0') 
			return;
		input[i] = CharToUpper(input[i]);
	}
}

public GetServerInfo()
{
	GetConVarString(FindConVar("hostname"),g_szServerName,sizeof(g_szServerName));
	
	new pieces[4];
	decl String:code2[3];
	decl String:NetIP[256];
	new longip = GetConVarInt(FindConVar("hostip"));
	new port = GetConVarInt( FindConVar( "hostport" ));
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	
	//kreedz europe 128 tick exception cccc debug
	//Format(NetIP, sizeof(NetIP), "37.187.171.52");
	
	
	GeoipCountry(NetIP, g_szServerCountry, 100);

	if(!strcmp(g_szServerCountry, NULL_STRING))
		Format( g_szServerCountry, 100, "Unknown", g_szServerCountry );
	else				
		if( StrContains( g_szServerCountry, "United", false ) != -1 || 
			StrContains( g_szServerCountry, "Republic", false ) != -1 || 
			StrContains( g_szServerCountry, "Federation", false ) != -1 || 
			StrContains( g_szServerCountry, "Island", false ) != -1 || 
			StrContains( g_szServerCountry, "Netherlands", false ) != -1 || 
			StrContains( g_szServerCountry, "Isle", false ) != -1 || 
			StrContains( g_szServerCountry, "Bahamas", false ) != -1 || 
			StrContains( g_szServerCountry, "Maldives", false ) != -1 || 
			StrContains( g_szServerCountry, "Philippines", false ) != -1 || 
			StrContains( g_szServerCountry, "Vatican", false ) != -1 )
		{
			Format( g_szServerCountry, 100, "The %s", g_szServerCountry );
		}	
	if(GeoipCode2(NetIP, code2))
		Format(g_szServerCountryCode, 16, "%s",code2);
	else
		Format(g_szServerCountryCode, 16, "??",code2);
	Format(g_szServerIp, sizeof(g_szServerIp), "%s:%i",NetIP,port);
	
}

public GetCountry(client)
{
	if(client != 0)
	{
		if(!IsFakeClient(client))
		{
			decl String:IP[16];
			decl String:code2[3];
			GetClientIP(client, IP, 16);
			
			//COUNTRY
			GeoipCountry(IP, g_szCountry[client], 100);     
			if(!strcmp(g_szCountry[client], NULL_STRING))
				Format( g_szCountry[client], 100, "Unknown", g_szCountry[client] );
			else				
				if( StrContains( g_szCountry[client], "United", false ) != -1 || 
					StrContains( g_szCountry[client], "Republic", false ) != -1 || 
					StrContains( g_szCountry[client], "Federation", false ) != -1 || 
					StrContains( g_szCountry[client], "Island", false ) != -1 || 
					StrContains( g_szCountry[client], "Netherlands", false ) != -1 || 
					StrContains( g_szCountry[client], "Isle", false ) != -1 || 
					StrContains( g_szCountry[client], "Bahamas", false ) != -1 || 
					StrContains( g_szCountry[client], "Maldives", false ) != -1 || 
					StrContains( g_szCountry[client], "Philippines", false ) != -1 || 
					StrContains( g_szCountry[client], "Vatican", false ) != -1 )
				{
					Format( g_szCountry[client], 100, "The %s", g_szCountry[client] );
				}				
			//CODE
			if(GeoipCode2(IP, code2))
			{
				Format(g_szCountryCode[client], 16, "%s",code2);		
			}
			else
				Format(g_szCountryCode[client], 16, "??");	
		}
	}
}

stock StripAllWeapons(client)
{
	new iEnt;
	for (new i = 0; i <= 5; i++)
	{
		if (i != 2)
			while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, iEnt);
				RemoveEdict(iEnt);
			}
	}
	if (GetPlayerWeaponSlot(client, 2) == -1)
		GivePlayerItem(client, "weapon_knife");
}

public PlayButtonSound(client)
{
	if (!IsFakeClient(client))
	{
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "play *buttons/button3.wav"); 
		ClientCommand(client, buffer); 	
	}
	//spec stop sound
	for(new i = 1; i <= MaxClients; i++) 
	{		
		if (IsValidClient(i) && !IsPlayerAlive(i))
		{			
			new SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				new Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");	
				if (Target == client)
				{
					decl String:szsound[255];
					Format(szsound, sizeof(szsound), "play *buttons/button3.wav"); 
					ClientCommand(i,szsound);
				}
			}					
		}
	}	
}

public PlayUnstoppableSound(client)
{
	decl String:buffer[255];
	Format(buffer, sizeof(buffer), "play %s", UNSTOPPABLE_RELATIVE_SOUND_PATH);  
	if (IsValidClient(client) && !IsFakeClient(client) && g_EnableQuakeSounds[client] == 1)
		ClientCommand(client, buffer); 	
	//spec stop sound
	for(new i = 1; i <= MaxClients; i++) 
	{		
		if (IsValidClient(i) && !IsPlayerAlive(i))
		{			
			new SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				new Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");	
				if (Target == client && g_EnableQuakeSounds[i] == 1)
					ClientCommand(i,buffer);
			}					
		}
	}	
}

public DeleteButtons(client)
{
	decl String:classname[32];
	Format(classname,32,"prop_physics_override");
	for (new i; i < GetEntityCount(); i++)
    {
        if (IsValidEdict(i) && GetEntityClassname(i, classname, 32))
		{
			decl String:targetname[64];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "climb_startbuttonx", false) || StrEqual(targetname, "climb_endbuttonx", false))
			{
				if (StrEqual(targetname, "climb_startbuttonx", false))
				{
					g_fStartButtonPos[0] = -999999.9;
					g_fStartButtonPos[1] = -999999.9;
					g_fStartButtonPos[2] = -999999.9;
				}
				else
				{
					g_fEndButtonPos[0] = -999999.9;
					g_fEndButtonPos[1] = -999999.9;
					g_fEndButtonPos[2] = -999999.9;		
				}
				AcceptEntityInput(i, "Kill"); 
				RemoveEdict(i);
			}
		}	
	}
	Format(classname,32,"env_sprite");
	for (new i; i < GetEntityCount(); i++)
	{
        if (IsValidEdict(i) && GetEntityClassname(i, classname, 32))
		{
			decl String:targetname[64];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "starttimersign", false) || StrEqual(targetname, "stoptimersign", false))
			{
				AcceptEntityInput(i, "Kill");
				RemoveEdict(i);
			}
		}
	}
	g_bFirstEndButtonPush=true;
	g_bFirstStartButtonPush=true;
	//stop timer 
	for (new i = 1; i <= MaxClients; i++)
	if (IsValidClient(i) && !IsFakeClient(i) && client != 67)	
	{
		Client_Stop(i,0);
	}
	if (IsValidClient(client))
		KzAdminMenu(client);
}

public CreateButton(client,String:targetname[]) 
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		//location (crosshair)
		new Float:locationPlayer[3];
		new Float:location[3];
		GetClientAbsOrigin(client, locationPlayer);
		GetClientEyePosition(client, location);
		new Float:ang[3];
		GetClientEyeAngles(client, ang);
		new Float:location2[3];
		location2[0] = (location[0]+(100*((Cosine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
		location2[1] = (location[1]+(100*((Sine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
		ang[0] -= (2*ang[0]);
		location2[2] = (location[2]+(100*(Sine(DegToRad(ang[0])))));
		location2[2] = locationPlayer[2];
	
		new ent = CreateEntityByName("prop_physics_override");
		if (ent != -1)
		{  
			DispatchKeyValue(ent, "model", "models/props/switch001.mdl");	
			DispatchKeyValue(ent, "spawnflags", "264");
			DispatchKeyValue(ent, "targetname",targetname);
			DispatchSpawn(ent);  
			ang[0] = 0.0;
			ang[1] += 180.0;
			TeleportEntity(ent, location2, ang, NULL_VECTOR);
			SDKHook(ent, SDKHook_UsePost, OnUsePost);	
			new Float:location3[3];
			location3 = location2;
			location3[2]+=150.0; 
			if (StrEqual(targetname, "climb_startbuttonx"))
			{							
				g_fStartButtonPos = location3;
				PrintToChat(client,"%c[%cKZ%c] Start button built!", WHITE,MOSSGREEN,WHITE);
				g_bFirstStartButtonPush=false;
			}
			else
			{			
				g_fEndButtonPos = location3;
				PrintToChat(client,"%c[%cKZ%c] Stop button built!", WHITE,MOSSGREEN,WHITE);
				g_bFirstEndButtonPush = false;
			}
			ang[1] -= 180.0;
		}
		new sprite = CreateEntityByName("env_sprite");
		if(sprite != -1) 
		{ 
			DispatchKeyValue(sprite, "classname", "env_sprite");
			DispatchKeyValue(sprite, "spawnflags", "1");
			DispatchKeyValue(sprite, "scale", "0.2");
			if (StrEqual(targetname, "climb_startbuttonx"))
			{
				DispatchKeyValue(sprite, "model", "materials/models/props/startkztimer.vmt"); 
				DispatchKeyValue(sprite, "targetname", "starttimersign");
			}
			else
			{
				DispatchKeyValue(sprite, "model", "materials/models/props/stopkztimer.vmt"); 
				DispatchKeyValue(sprite, "targetname", "stoptimersign");
			}
			DispatchKeyValue(sprite, "rendermode", "1");
			DispatchKeyValue(sprite, "framerate", "0");
			DispatchKeyValue(sprite, "HDRColorScale", "1.0");
			DispatchKeyValue(sprite, "rendercolor", "255 255 255");
			DispatchKeyValue(sprite, "renderamt", "255");
			DispatchSpawn(sprite);
			location = location2;	
			location[2]+=95;
			ang[0] = 0.0;
			TeleportEntity(sprite, location, ang, NULL_VECTOR);
		}
		
		if (StrEqual(targetname, "climb_startbuttonx"))
		{
			db_updateMapButtons(location2[0],location2[1],location2[2],ang[1],0);
			g_fStartButtonPos = location2;
		}
		else
		{
			db_updateMapButtons(location2[0],location2[1],location2[2],ang[1],1);
			g_fEndButtonPos =  location2;
		}
	}
	else
		PrintToChat(client, "%t", "AdminSetButton", MOSSGREEN,WHITE); 
	KzAdminMenu(client);
}

public FixPlayerName(client)
{
	decl String:szName[64];
	decl String:szOldName[64];
	GetClientName(client,szName,64);
	Format(szOldName, 64,"%s ",szName);
	ReplaceChar("'", "`", szName);
	if (!(StrEqual(szOldName,szName)))
	{
		SetClientInfo(client, "name", szName);
		SetEntPropString(client, Prop_Data, "m_szNetname", szName);
		CS_SetClientName(client, szName);
	}
}

public SetClientDefaults(client)
{	
	g_fLastTimeBhopBlock[client] = GetEngineTime();
	g_LastGroundEnt[client] = - 1;	
	g_bFlagged[client] = false;
	g_bSaving[client] = false;
	g_bHyperscroll[client] = false;
	g_fLastOverlay[client] = GetEngineTime() - 5.0;	
	g_bValidTeleport[client]=false;
	g_bProfileSelected[client]=false;
	g_bNewReplay[client] = false;
	g_bFirstButtonTouch[client]=true;
	g_bTimeractivated[client] = false;	
	g_bKickStatus[client] = false;
	g_bSpectate[client] = false;	
	g_bFirstTeamJoin[client] = true;		
	g_bFirstSpawn[client] = true;
	g_bSayHook[client] = false;
	g_bUndo[client] = false;
	g_bUndoTimer[client] = false;
	g_bRespawnAtTimer[client] = false;
	g_js_bPlayerJumped[client] = false;
	g_bRecalcRankInProgess[client] = false;
	g_bPrestrafeTooHigh[client] = false;
	g_bPause[client] = false;
	g_bPositionRestored[client] = false;
	g_bPauseWasActivated[client]=false;
	g_bTopMenuOpen[client] = false;
	g_bMapMenuOpen[client] = false;
	g_bRestorePosition[client] = false;
	g_bRestorePositionMsg[client] = false;
	g_bRespawnPosition[client] = false;
	g_bNoClip[client] = false;		
	g_bMapFinished[client] = false;
	g_bMapRankToChat[client] = false;
	g_bOnBhopPlattform[client] = false;
	g_bChallenge[client] = false;
	g_bOverlay[client]=false;
	g_js_bFuncMoveLinear[client] = false;
	g_bChallenge_Request[client] = false;
	g_bClientOwnReason[client] = false;
	g_bSpecInfo[client]=true;
	g_js_Last_Ground_Frames[client] = 11;
	g_js_MultiBhop_Count[client] = 1;
	g_AdminMenuLastPage[client] = 0;
	g_fLastChatMsg[client] = 0.0;
	g_Skillgroup[client] = 0;
	g_OptionsMenuLastPage[client] = 0;	
	g_MenuLevel[client] = -1;
	g_CurrentCp[client] = -1;
	g_AttackCounter[client] = 0;
	g_SpecTarget[client] = -1;
	g_CounterCp[client] = 0;
	g_OverallCp[client] = 0;
	g_OverallTp[client] = 0;
	g_pr_points[client] = 0;
	g_PrestrafeFrameCounter[client] = 0;
	g_PrestrafeVelocity[client] = 1.0;
	g_fCurrentRunTime[client] = -1.0;
	g_fPlayerCordsLastPosition[client] = Float:{0.0,0.0,0.0};
	g_fPlayerCordsUndoTp[client] = Float:{0.0,0.0,0.0};
	g_fPlayerConnectedTime[client] = GetEngineTime();			
	g_fLastTimeButtonSound[client] = GetEngineTime();
	g_fLastTimeNoClipUsed[client] = -1.0;
	g_fStartTime[client] = -1.0;
	g_fLastTimeBhopBlock[client] = GetEngineTime();
	g_fPlayerLastTime[client] = -1.0;
	g_js_GroundFrames[client] = 0;
	g_fStartPauseTime[client] = 0.0;
	g_js_fJump_JumpOff_PosLastHeight[client] = -1.012345;
	g_js_Good_Sync_Frames[client] = 0.0;
	g_js_Sync_Frames[client] = 0.0;
	g_js_GODLIKE_Count[client] = 0;
	g_fPauseTime[client] = 0.0;
	g_MapRankTp[client] = 99999;
	g_MapRankPro[client] = 99999;
	g_OldMapRankPro[client] = 99999;
	g_OldMapRankTp[client] = 99999;	
	g_fProfileMenuLastQuery[client] = GetEngineTime();
	g_PlayerRank[client] = 99999;
	Format(g_szPlayerPanelText[client], 512, "");
	Format(g_pr_rankname[client], 32, "");
	Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>0.0 units</font>");
	for( new i = 0; i < CPLIMIT; i++ )
		g_fPlayerCords[client][i] = Float:{0.0,0.0,0.0};
	for( new i = 0; i < 100; i++ )
	{
		g_js_Strafe_Good_Sync[client][i] = 0.0;
		g_js_Strafe_Frames[client][i] = 0.0;
	}
	new x = 0;
	while (x < 30)
	{
		g_aaiLastJumps[client][x] = -1;
		x++;
	}	
	
	// Client options
	g_bInfoPanel[client]=false;
	g_bHideChat[client]=false;
	g_bClimbersMenuSounds[client]=true;
	g_EnableQuakeSounds[client]= 1;
	g_bShowNames[client]=true; 
	g_bStrafeSync[client]=false;
	g_bGoToClient[client]=true; 
	g_bShowTime[client]=true; 
	g_bHide[client]=false; 
	g_bCPTextMessage[client]=false; 
	g_bStartWithUsp[client] = false;
	g_bAdvancedClimbersMenu[client]=true;
	g_ColorChat[client]=1; 
	g_ShowSpecs[client]=0;
	g_bAutoBhopClient[client]=true;
	g_bJumpBeam[client]=false;
	g_bViewModel[client]=true;
	g_bAdvInfoPanel[client]=false;
}

// - Get Runtime -
public GetcurrentRunTime(client)
{
	decl String:szTime[32];
	decl Float:flPause, Float:flTime;	
	if (g_bPause[client])
	{
		flPause = GetEngineTime() - g_fStartPauseTime[client];
		flTime =  GetEngineTime() - g_fStartTime[client] - flPause;	
		FormatTimeFloat(client, flTime, 1,szTime,sizeof(szTime));
		Format(g_szTimerTitle[client], 255, "%s\n%s (PAUSE)", g_szPlayerPanelText[client],szTime);
	}
	else
	{		
		g_fCurrentRunTime[client] = GetEngineTime() - g_fStartTime[client] - g_fPauseTime[client];	
		FormatTimeFloat(client, g_fCurrentRunTime[client], 1,szTime,sizeof(szTime));
		if(g_bShowTime[client])
		{		
			if(StrEqual(g_szPlayerPanelText[client],""))		
				Format(g_szTimerTitle[client], 255, "%s", szTime);
			else
				Format(g_szTimerTitle[client], 255, "%s\n%s", g_szPlayerPanelText[client],szTime);
		}
		else
		{
			Format(g_szTimerTitle[client], 255, "%s", g_szPlayerPanelText[client]);
		}
	}	
}

public Float:GetSpeed(client)
{
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new Float:speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	return speed;
}


public Float:GetVelocity(client)
{
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new Float:speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)+Pow(fVelocity[2],2.0));
	return speed;
}

public PlayOwnageSound(client)
{
	//decl String:buffer[255];	
	/*for (new i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i) && g_EnableQuakeSounds[i] >= 1 && i != client)
		{	
			Format(buffer, sizeof(buffer), "play %s", OWNAGE_RELATIVE_SOUND_PATH); 	
			ClientCommand(i, buffer); 
		}
	}*/
}

public PlayLeetJumpSound(client)
{
	decl String:buffer[255];	

	//all sound
	if (g_js_GODLIKE_Count[client] == 3 || g_js_GODLIKE_Count[client] == 5)
	{
		for (new i = 1; i <= MaxClients; i++)
		{ 
			if(IsValidClient(i) && !IsFakeClient(i) && i != client && g_ColorChat[i] >= 1 && g_EnableQuakeSounds[i] == 1)
			{	
					if (g_js_GODLIKE_Count[client]==3)
					{
						Format(buffer, sizeof(buffer), "play %s", GODLIKE_RAMPAGE_RELATIVE_SOUND_PATH); 	
						ClientCommand(i, buffer); 
					}
					else
						if (g_js_GODLIKE_Count[client]==5)
						{
							Format(buffer, sizeof(buffer), "play %s", GODLIKE_DOMINATING_RELATIVE_SOUND_PATH); 		
							ClientCommand(i, buffer); 
						}
			}
		}
	}
	//client sound
	if 	(IsValidClient(client) && !IsFakeClient(client) && g_EnableQuakeSounds[client] >= 1)
	{
		if (g_js_GODLIKE_Count[client] != 3 && g_js_GODLIKE_Count[client] != 5 && g_EnableQuakeSounds[client])
		{
			Format(buffer, sizeof(buffer), "play %s", GODLIKE_RELATIVE_SOUND_PATH); 
			ClientCommand(client, buffer); 
		}
			else
			if (g_js_GODLIKE_Count[client]==3 && g_EnableQuakeSounds[client])
			{
				Format(buffer, sizeof(buffer), "play %s", GODLIKE_RAMPAGE_RELATIVE_SOUND_PATH); 	
				ClientCommand(client, buffer); 
			}
			else
			if (g_js_GODLIKE_Count[client]==5 && g_EnableQuakeSounds[client])
			{
				Format(buffer, sizeof(buffer), "play %s", GODLIKE_DOMINATING_RELATIVE_SOUND_PATH); 		
				ClientCommand(client, buffer); 
			}					
	}
}

public SetCashState()
{
	ServerCommand("mp_startmoney 0; mp_playercashawards 0; mp_teamcashawards 0");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			SetEntProp(i, Prop_Send, "m_iAccount", 0);
	}
}

public PlayRecordSound(iRecordtype)
{
	decl String:buffer[255];
	if (iRecordtype==1)
	    for(new i = 1; i <= GetMaxClients(); i++) 
		{ 
			if(IsValidClient(i) && !IsFakeClient(i) && g_EnableQuakeSounds[i] >= 1) 
			{ 
				Format(buffer, sizeof(buffer), "play %s", PRO_RELATIVE_SOUND_PATH); 
				ClientCommand(i, buffer); 
			}
		} 
	else
		if (iRecordtype==2 || iRecordtype == 3)
			for(new i = 1; i <= GetMaxClients(); i++) 
			{ 
				if(IsValidClient(i) && !IsFakeClient(i) && g_EnableQuakeSounds[i] >= 1) 
				{ 
					Format(buffer, sizeof(buffer), "play %s", CP_RELATIVE_SOUND_PATH); 
					ClientCommand(i, buffer); 
				}
			}
}

public InitPrecache()
{
	AddFileToDownloadsTable( UNSTOPPABLE_SOUND_PATH );
	FakePrecacheSound( UNSTOPPABLE_RELATIVE_SOUND_PATH );	
	AddFileToDownloadsTable( PRO_FULL_SOUND_PATH );
	FakePrecacheSound( PRO_RELATIVE_SOUND_PATH );	
	AddFileToDownloadsTable( CP_FULL_SOUND_PATH );
	FakePrecacheSound( CP_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( PRO_FULL_SOUND_PATH );
	FakePrecacheSound( PRO_RELATIVE_SOUND_PATH );	
	AddFileToDownloadsTable( GODLIKE_FULL_SOUND_PATH );
	FakePrecacheSound( GODLIKE_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( GODLIKE_DOMINATING_FULL_SOUND_PATH );
	FakePrecacheSound( GODLIKE_DOMINATING_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( GODLIKE_RAMPAGE_FULL_SOUND_PATH );
	FakePrecacheSound( GODLIKE_RAMPAGE_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( PERFECT_FULL_SOUND_PATH );
	FakePrecacheSound( PERFECT_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable( IMPRESSIVE_FULL_SOUND_PATH );
	FakePrecacheSound( IMPRESSIVE_RELATIVE_SOUND_PATH );
	//AddFileToDownloadsTable( OWNAGE_FULL_SOUND_PATH );
	//FakePrecacheSound( OWNAGE_RELATIVE_SOUND_PATH );
	AddFileToDownloadsTable("models/props/switch001.mdl");
	AddFileToDownloadsTable("models/props/switch001.vvd");
	AddFileToDownloadsTable("models/props/switch001.phy");
	AddFileToDownloadsTable("models/props/switch001.vtx");
	AddFileToDownloadsTable("models/props/switch001.dx90.vtx");		
	AddFileToDownloadsTable("materials/models/props/switch.vmt");
	AddFileToDownloadsTable("materials/models/props/switch.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001_normal.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001_normal.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001_lightwarp.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/props/switch001_exponent.vmt");
	AddFileToDownloadsTable("materials/models/props/switch001_exponent.vtf");
	AddFileToDownloadsTable("materials/models/props/startkztimer.vmt");
	AddFileToDownloadsTable("materials/models/props/startkztimer.vtf");	
	AddFileToDownloadsTable("materials/models/props/stopkztimer.vmt");
	AddFileToDownloadsTable("materials/models/props/stopkztimer.vtf");
	AddFileToDownloadsTable("materials/sprites/bluelaser1.vmt");
	AddFileToDownloadsTable("materials/sprites/bluelaser1.vtf");
	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/laser.vtf");
	AddFileToDownloadsTable("materials/sprites/halo01.vmt");
	AddFileToDownloadsTable("materials/sprites/halo01.vtf");
	AddFileToDownloadsTable(g_sArmModel);
	AddFileToDownloadsTable(g_sPlayerModel);
	AddFileToDownloadsTable(g_sReplayBotArmModel);
	AddFileToDownloadsTable(g_sReplayBotPlayerModel);
	AddFileToDownloadsTable(g_sReplayBotArmModel2);
	AddFileToDownloadsTable(g_sReplayBotPlayerModel2);
	g_Beam[0] = PrecacheModel("materials/sprites/laser.vmt", true);
	g_Beam[1] = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_Beam[2] = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
	PrecacheModel("materials/models/props/startkztimer.vmt",true);
	PrecacheModel("materials/models/props/stopkztimer.vmt",true);
	PrecacheModel("models/props/switch001.mdl",true);	
	PrecacheModel(g_sReplayBotArmModel,true);
	PrecacheModel(g_sReplayBotPlayerModel,true);
	PrecacheModel(g_sReplayBotArmModel2,true);
	PrecacheModel(g_sReplayBotPlayerModel2,true);
	PrecacheModel(g_sArmModel,true);
	PrecacheModel(g_sPlayerModel,true);
}

// thx to V952 https://forums.alliedmods.net/showthread.php?t=212886
stock TraceClientViewEntity(client)
{
	new Float:m_vecOrigin[3];
	new Float:m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	new Handle:tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new pEntity = -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}

// thx to V952 https://forums.alliedmods.net/showthread.php?t=212886
public bool:TRDontHitSelf(entity, mask, any:data)
{
	if (entity == data)
		return false;
	return true;
}

public PrintMapRecords(client)
{
	decl String:szTime[32];
	new Float:mintime;
	if (g_fRecordTime < g_fRecordTimePro)
		mintime=g_fRecordTime;
	else
		mintime=g_fRecordTimePro;
	mintime+=0.0002;
	if (g_fRecordTimePro != 9999999.0)
	{
		FormatTimeFloat(client, g_fRecordTimePro, 3,szTime,sizeof(szTime));
		PrintToChat(client, "%t", "ProRecord",MOSSGREEN,WHITE,DARKBLUE,WHITE, szTime, g_szRecordPlayerPro); 
	}	
	if (g_fRecordTime != 9999999.0)
	{
		FormatTimeFloat(client, g_fRecordTime, 3,szTime,sizeof(szTime));
		PrintToChat(client, "%t", "TpRecord",MOSSGREEN,WHITE,YELLOW,WHITE, szTime, g_szRecordPlayer); 
	}	
}

public MapFinishedMsgs(client, type)
{	
	if (IsValidClient(client))
	{
		g_bSaving[client]=false;
		decl String:szTime[32];
		decl String:szName[MAX_NAME_LENGTH];
		GetClientName(client, szName, MAX_NAME_LENGTH);
		new count;
		new rank;
		if (type==1)
		{
			count = g_MapTimesCountPro;
			rank = g_MapRankPro[client];
			FormatTimeFloat(client, g_fRecordTimePro, 3, szTime, sizeof(szTime));	
		}
		else
		if (type==0)
		{
			count = g_MapTimesCountTp;
			rank = g_MapRankTp[client];		
			FormatTimeFloat(client, g_fRecordTime, 3, szTime, sizeof(szTime));	
		}
		for(new i = 1; i <= GetMaxClients(); i++) 
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				if (g_Time_Type[client] == 0)
				{
					PrintToChat(i, "%t", "MapFinished0",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,YELLOW,GRAY,  LIMEGREEN, g_szFinalTime[client],GRAY,LIMEGREEN,g_Tp_Final[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE); 
					PrintToConsole(i, "%s finished with a TP TIME of (%s, TP's: %i). [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_Tp_Final[client],rank,count,szTime); 
				}
				else
				if (g_Time_Type[client] == 1)
				{
					PrintToChat(i, "%t", "MapFinished1",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE); 
					PrintToConsole(i, "%s finished with a PRO TIME of (%s). [rank #%i/%i | record %s]",szName,g_szFinalTime[client],rank,count,szTime);  
				}			
				else
					if (g_Time_Type[client] == 2)
					{
						PrintToChat(i, "%t", "MapFinished2",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,YELLOW,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY,LIMEGREEN,g_Tp_Final[client],GRAY,GREEN, g_szTimeDifference[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE);  				
						PrintToConsole(i, "%s finished with a TP TIME of (%s, TP's: %i). Improving their best time by (%s).  [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_Tp_Final[client],g_szTimeDifference[client],rank,count,szTime);  
					}
					else
						if (g_Time_Type[client] == 3)
						{
							PrintToChat(i, "%t", "MapFinished3",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY,GREEN, g_szTimeDifference[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE);  				
							PrintToConsole(i, "%s finished with a PRO TIME of (%s). Improving their best time by (%s).  [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_szTimeDifference[client],rank,count,szTime); 	
						}
						else
							if (g_Time_Type[client] == 4)
							{
								PrintToChat(i, "%t", "MapFinished4",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,YELLOW,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY,LIMEGREEN,g_Tp_Final[client],GRAY,RED, g_szTimeDifference[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE);  	
								PrintToConsole(i, "%s finished with a TP TIME of (%s, TP's: %i). Missing their best time by (%s).  [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_Tp_Final[client],g_szTimeDifference[client],rank,count,szTime); 
							}
							else
								if (g_Time_Type[client] == 5)
								{
									PrintToChat(i, "%t", "MapFinished5",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE,GRAY,LIMEGREEN, g_szFinalTime[client],GRAY,RED, g_szTimeDifference[client],GRAY, WHITE, LIMEGREEN, rank, WHITE,count,LIMEGREEN,szTime,WHITE);  	
									PrintToConsole(i, "%s finished with a PRO TIME of (%s). Missing their best time by (%s).  [rank #%i/%i | record %s]",szName,g_szFinalTime[client],g_szTimeDifference[client],rank,count,szTime); 
								}
				if (g_FinishingType[client] == 2)				
				{
					PrintToChat(i, "%t", "NewProRecord",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,DARKBLUE);  
					PrintToConsole(i, "[KZ] %s has beaten the PRO RECORD",szName); 	
				}		
				else
					if (g_FinishingType[client] == 1)				
					{
						PrintToChat(i, "%t", "NewTpRecord",MOSSGREEN,WHITE,LIMEGREEN,szName,GRAY,YELLOW); 	
						PrintToConsole(i, "[KZ] %s has beaten the TP RECORD",szName); 	
					}					
			}
		
		if (rank==99999 && IsValidClient(client))
			PrintToChat(client, "[%cKZ%c] %cFailed to save your data correctly! Please contact an admin.",MOSSGREEN,WHITE,DARKRED,RED,DARKRED); 	
			
		//noclip MsgMsg
		if (IsValidClient(client) && g_bMapFinished[client] == false && !StrEqual(g_pr_rankname[client],g_szSkillGroups[8]) && !(GetUserFlagBits(client) & ADMFLAG_RESERVATION) && !(GetUserFlagBits(client) & ADMFLAG_ROOT) && !(GetUserFlagBits(client) & ADMFLAG_GENERIC) && g_bNoClipS)
			PrintToChat(client, "%t", "NoClipUnlocked",MOSSGREEN,WHITE,YELLOW);
		g_bMapFinished[client] = true;
		CreateTimer(0.0, UpdatePlayerProfile, client,TIMER_FLAG_NO_MAPCHANGE);
		
		if (g_Time_Type[client] == 0 || g_Time_Type[client] == 1 || g_Time_Type[client] == 2 || g_Time_Type[client] == 3)
			CheckMapRanks(client, g_Tp_Final[client]);
	}
	//recalc avg
	db_CalcAvgRunTime();
	
	//sound all
	PlayRecordSound(g_Sound_Type[client]);			

	//sound Client
	if (g_Sound_Type[client] == 5)
		PlayUnstoppableSound(client);
}

public CheckMapRanks(client, tps)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsValidClient(i) && !IsFakeClient(i) && i != client)	
	{	
		if (tps > 0)
		{
			if (g_OldMapRankTp[client] > g_MapRankTp[client] && g_OldMapRankTp[client] > g_MapRankTp[i] && g_MapRankTp[client] <= g_MapRankTp[i])
				g_MapRankTp[i]++;
		}
		else
		{
			if (g_OldMapRankPro[client] < g_MapRankPro[client] && g_OldMapRankPro[client] > g_MapRankPro[i] && g_MapRankPro[client] <= g_MapRankPro[i])
				g_MapRankPro[i]++;
		}			
	}
}

public ReplaceChar(String:sSplitChar[], String:sReplace[], String:sString[64])
{
	StrCat(sString, sizeof(sString), " ");
	new String:sBuffer[16][256];
	ExplodeString(sString, sSplitChar, sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
	strcopy(sString, sizeof(sString), "");
	for (new i = 0; i < sizeof(sBuffer); i++)
	{
		if (strcmp(sBuffer[i], "") == 0)
			continue;
		if (i != 0)
		{
			decl String:sTmpStr[256];
			Format(sTmpStr, sizeof(sTmpStr), "%s%s", sReplace, sBuffer[i]);
			StrCat(sString, sizeof(sString), sTmpStr);
		}
		else
		{
			StrCat(sString, sizeof(sString), sBuffer[i]);
		}
	}
}

public FormatTimeFloat(client, Float:time, type, String:string[], length)
{
	if (!IsValidClient(client))
		return;
	decl String:szMilli[16];
	decl String:szSeconds[16];
	decl String:szMinutes[16];
	decl String:szHours[16];
	decl String:szMilli2[16];
	decl String:szSeconds2[16];
	decl String:szMinutes2[16];
	new imilli;
	new imilli2;
	new iseconds;
	new iminutes;
	new ihours;
	time = FloatAbs(time);
	imilli = RoundToZero(time*100);
	imilli2 = RoundToZero(time*10);
	imilli = imilli%100;
	imilli2 = imilli2%10;
	iseconds = RoundToZero(time);
	iseconds = iseconds%60;	
	iminutes = RoundToZero(time/60);	
	iminutes = iminutes%60;	
	ihours = RoundToZero((time/60)/60);

	if (imilli < 10)
		Format(szMilli, 16, "0%dms", imilli);
	else
		Format(szMilli, 16, "%dms", imilli);
	if (iseconds < 10)
		Format(szSeconds, 16, "0%ds", iseconds);
	else
		Format(szSeconds, 16, "%ds", iseconds);
	if (iminutes < 10)
		Format(szMinutes, 16, "0%dm", iminutes);
	else
		Format(szMinutes, 16, "%dm", iminutes);	
		
	
	Format(szMilli2, 16, "%d", imilli2);
	if (iseconds < 10)
		Format(szSeconds2, 16, "0%d", iseconds);
	else
		Format(szSeconds2, 16, "%d", iseconds);
	if (iminutes < 10)
		Format(szMinutes2, 16, "0%d", iminutes);
	else
		Format(szMinutes2, 16, "%d", iminutes);	
	//Time: 00m 00s 00ms
	if (type==0)
	{
		Format(szHours, 16, "%dm", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			if (g_bClimbersMenuOpen[client])
			{
				if (g_bAdvancedClimbersMenu[client])
					Format(string, length, "Time: %s:%s:%s.%s", szHours, szMinutes2,szSeconds2,szMilli2);
				else
					Format(string, length, "%s:%s:%s.%s", szHours, szMinutes2,szSeconds2,szMilli2);
			}
			else
				Format(string, length, "%s:%s:%s.%s", szHours, szMinutes2,szSeconds2,szMilli2);
		}
		else
		{
			if (g_bClimbersMenuOpen[client])
			{
				if (g_bAdvancedClimbersMenu[client])
					Format(string, length, "Time: %s:%s.%s", szMinutes2,szSeconds2,szMilli2);
				else
					Format(string, length, "%s:%s.%s", szMinutes2,szSeconds2,szMilli2);
			}
			else
				Format(string, length, "%s:%s.%s", szMinutes2,szSeconds2,szMilli2);
		}
	}
	//00m 00s 00ms
	if (type==1)
	{
		Format(szHours, 16, "%dm", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%dh", ihours);
			Format(string, length, "%s %s %s %s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			Format(string, length, "%s %s %s", szMinutes,szSeconds,szMilli);	
	}
	else
	//00h 00m 00s 00ms
	if (type==2)
	{
		imilli = RoundToZero(time*1000);
		imilli = imilli%1000;
		if (imilli < 10)
			Format(szMilli, 16, "00%dms", imilli);
		else
		if (imilli < 100)
			Format(szMilli, 16, "0%dms", imilli);
		else
			Format(szMilli, 16, "%dms", imilli);
		Format(szHours, 16, "%dh", ihours);
		Format(string, 32, "%s %s %s %s",szHours, szMinutes,szSeconds,szMilli);
	}
	else
	//00:00:00
	if (type==3)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "%s:%s:%s.%s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			Format(string, length, "%s:%s.%s", szMinutes,szSeconds,szMilli);	
	}
	//Time: 00:00:00
	if (type==4)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "Time: %s:%s:%s", szHours, szMinutes,szSeconds);
		}
		else
			Format(string, length, "Time: %s:%s", szMinutes,szSeconds);	
	}
	if (type==5)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);	
		if (ihours>0)	
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "Timeleft: %s:%s:%s", szHours, szMinutes,szSeconds);
		}
		else
			Format(string, length, "Timeleft: %s:%s", szMinutes,szSeconds);	
	}
}


public SetPlayerRank(client)
{
	if (!IsValidClient(client) || IsFakeClient(client) || g_pr_Calculating[client])
		return;
	if (g_bPointSystem)
	{
		if (g_pr_points[client] < g_pr_rank_Percentage[1])
		{
			g_Skillgroup[client] = 1;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[0]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",WHITE,g_szSkillGroups[0],WHITE);
		}
		else
		if (g_pr_rank_Percentage[1] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[2])
		{
			g_Skillgroup[client] = 2;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[1]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",WHITE,g_szSkillGroups[1],WHITE);
		}
		else
		if (g_pr_rank_Percentage[2] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[3])
		{
			g_Skillgroup[client] = 3;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[2]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",GRAY,g_szSkillGroups[2],WHITE);		
		}
		else
		if (g_pr_rank_Percentage[3] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[4])
		{
			g_Skillgroup[client] = 4;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[3]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",LIGHTBLUE,g_szSkillGroups[3],WHITE);		
		}
		else
		if (g_pr_rank_Percentage[4] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[5])
		{
			g_Skillgroup[client] = 5;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[4]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",BLUE,g_szSkillGroups[4],WHITE);
		}
		else
		if (g_pr_rank_Percentage[5] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[6])
		{
			g_Skillgroup[client] = 6;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[5]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",DARKBLUE,g_szSkillGroups[5],WHITE);
		}
		else
		if (g_pr_rank_Percentage[6] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[7])
		{
			g_Skillgroup[client] = 7;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[6]);
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",PINK,g_szSkillGroups[6],WHITE);
		}
		else
		if (g_pr_rank_Percentage[7] <= g_pr_points[client] && g_pr_points[client] < g_pr_rank_Percentage[8])
		{
			g_Skillgroup[client] = 8;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[7]);	
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",LIGHTRED,g_szSkillGroups[7],WHITE);
		}
		else
		if (g_pr_points[client] >= g_pr_rank_Percentage[8])
		{
			g_Skillgroup[client] = 9;
			Format(g_pr_rankname[client], 32, "%s",g_szSkillGroups[8]);	
			Format(g_pr_chat_coloredrank[client], 32, "[%c%s%c]",DARKRED,g_szSkillGroups[8],WHITE);
		}
	}	
	else
	{
		g_Skillgroup[client] = 0;
		Format(g_pr_rankname[client], 32, "");	
	}	
		
	// VIP tag
	if (g_bVipClantag)			
		if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && !(GetUserFlagBits(client) & ADMFLAG_ROOT) && !(GetUserFlagBits(client) & ADMFLAG_GENERIC))
		{
			Format(g_pr_chat_coloredrank[client], 32, "%s %cVIP%c",g_pr_chat_coloredrank[client],YELLOW,WHITE);
			Format(g_pr_rankname[client], 32, "VIP");	
		}
	
	//ADMIN tag
	if (g_bAdminClantag)
	{	if (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_GENERIC) 
		{		
			Format(g_pr_chat_coloredrank[client], 32, "%s %cADMIN%c",g_pr_chat_coloredrank[client],LIMEGREEN,WHITE);
			Format(g_pr_rankname[client], 32, "ADMIN");	
			return;
		}
	}
	
	//DEV TAG
	if (StrEqual(g_szSteamID[client],"STEAM_1:1:73507922"))
	{
		Format(g_pr_chat_coloredrank[client], 32, "%s %cDEV%c",g_pr_chat_coloredrank[client],LIMEGREEN,WHITE);
		return;
	}
	
	// MAPPER Clantag
	for (new x = 0; x < 100; x++)
	{
		if ((StrContains(g_szMapmakers[x],"STEAM",true) != -1))
		{
			if (StrEqual(g_szMapmakers[x],g_szSteamID[client]))
			{			
				Format(g_pr_chat_coloredrank[client], 32, "%s %cMAPPER%c",g_pr_chat_coloredrank[client],LIMEGREEN,WHITE);
				Format(g_pr_rankname[client], 32, "MAPPER");			
				break;
			}		
		}
	}			
}

stock Action:PrintSpecMessageAll(client)
{
	decl String:szName[32];
	GetClientName(client, szName, sizeof(szName));
	ReplaceString(szName,32,"{darkred}","",false);
	ReplaceString(szName,32,"{green}","",false);
	ReplaceString(szName,32,"{lightgreen}","",false);
	ReplaceString(szName,32,"{blue}","",false);
	ReplaceString(szName,32,"{olive}","",false);
	ReplaceString(szName,32,"{lime}","",false);
	ReplaceString(szName,32,"{red}","",false);
	ReplaceString(szName,32,"{purple}","",false);
	ReplaceString(szName,32,"{grey}","",false);
	ReplaceString(szName,32,"{yellow}","",false);
	ReplaceString(szName,32,"{lightblue}","",false);
	ReplaceString(szName,32,"{steelblue}","",false);
	ReplaceString(szName,32,"{darkblue}","",false);
	ReplaceString(szName,32,"{pink}","",false);
	ReplaceString(szName,32,"{lightred}","",false);
	decl String:szTextToAll[1024];
	GetCmdArgString(szTextToAll, sizeof(szTextToAll));
	StripQuotes(szTextToAll);
	if (StrEqual(szTextToAll,"") || StrEqual(szTextToAll," ") || StrEqual(szTextToAll,"  "))
		return Plugin_Handled;

	ReplaceString(szTextToAll,1024,"{darkred}","",false);
	ReplaceString(szTextToAll,1024,"{green}","",false);
	ReplaceString(szTextToAll,1024,"{lightgreen}","",false);
	ReplaceString(szTextToAll,1024,"{blue}","",false);
	ReplaceString(szTextToAll,1024,"{olive}","",false);
	ReplaceString(szTextToAll,1024,"{lime}","",false);
	ReplaceString(szTextToAll,1024,"{red}","",false);
	ReplaceString(szTextToAll,1024,"{purple}","",false);
	ReplaceString(szTextToAll,1024,"{grey}","",false);
	ReplaceString(szTextToAll,1024,"{yellow}","",false);
	ReplaceString(szTextToAll,1024,"{lightblue}","",false);
	ReplaceString(szTextToAll,1024,"{steelblue}","",false);
	ReplaceString(szTextToAll,1024,"{darkblue}","",false);
	ReplaceString(szTextToAll,1024,"{pink}","",false);
	ReplaceString(szTextToAll,1024,"{lightred}","",false);
	
	//text right to left?
	decl String:sTextNew[1024];
	if(RTLify(sTextNew, szTextToAll))
		FormatEx(szTextToAll, 1024, sTextNew);
	
	decl String:szChatRank[64];
	Format(szChatRank, 64, "%s",g_pr_chat_coloredrank[client]);
				
	if (g_bCountry && (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag)))		
		CPrintToChatAll("{green}%s{default} %s *SPEC* {grey}%s{default}: %s",g_szCountryCode[client], szChatRank, szName,szTextToAll);
	else
		if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
			CPrintToChatAll("%s *SPEC* {grey}%s{default}: %s", szChatRank,szName,szTextToAll);
		else
			if (g_bCountry)
				CPrintToChatAll("[{green}%s{default}] *SPEC* {grey}%s{default}: %s", g_szCountryCode[client],szName, szTextToAll);
			else		
				CPrintToChatAll("*SPEC* {grey}%s{default}: %s", szName, szTextToAll);
	for (new i = 1; i <= MaxClients; i++)
		if (IsValidClient(i))	
		{
			if (g_bCountry && (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag)))
				PrintToConsole(i, "%s [%s] *SPEC* %s: %s", g_szCountryCode[client],g_pr_rankname[client],szName, szTextToAll);
			else	
				if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
					PrintToConsole(i, "[%s] *SPEC* %s: %s", g_szCountryCode[client],szName, szTextToAll);		
				else
					if (g_bPointSystem)
						PrintToConsole(i, "[%s] *SPEC* %s: %s", g_pr_rankname[client],szName, szTextToAll);	
						else
							PrintToConsole(i, "*SPEC* %s: %s", szName, szTextToAll);
		}
	return Plugin_Handled;
}

public HookCheck(client)
{
	if (g_bHookMod)
	{
		if (HGR_IsHooking(client) || HGR_IsGrabbing(client) || HGR_IsBeingGrabbed(client) || HGR_IsRoping(client) || HGR_IsPushing(client))
		{
			PrintToConsole(client, "[KZ] Timer stopped. Reason: Hook command used.")
			g_js_bPlayerJumped[client] = false;
			g_bTimeractivated[client] = false;
		}
	}
}

public LjBlockCheck(client, Float:origin[3])
{
	if(g_bLJBlock[client])
	{
		TE_SendBlockPoint(client, g_fDestBlock[client][0], g_fDestBlock[client][1], g_Beam[0]);
		TE_SendBlockPoint(client, g_fOriginBlock[client][0], g_fOriginBlock[client][1], g_Beam[0]);
	}		
	
	if (g_bOnGround[client])
	{		
		//LJBlock Stuff
		if (!g_js_bPlayerJumped[client])
		{
			decl Float:temp[3];
			if(g_bLJBlock[client])
			{
				g_js_block_lj_valid[client]=true;
				g_js_block_lj_jumpoff_pos[client]=false;
				if(IsCoordInBlockPoint(origin,g_fDestBlock[client],false))
				{
					//block2
					GetEdgeOrigin2(client, origin, temp);
					g_fEdgeDistJumpOff[client] = GetVectorDistance(temp, origin);
					g_js_block_lj_jumpoff_pos[client]=true;
				}	
				else
					if (IsCoordInBlockPoint(origin,g_fOriginBlock[client],false))
					{
						//block1
						GetEdgeOrigin1(client, origin, temp);
						g_fEdgeDistJumpOff[client] = GetVectorDistance(temp, origin);
						g_js_block_lj_jumpoff_pos[client]=false;
					}
					else
						g_js_block_lj_valid[client] = false;
			}
			else
				g_js_block_lj_valid[client] = false;
		}
	}
}

public AttackProtection(client, &buttons)
{
	if (g_bAttackSpamProtection && !IsFakeClient(client))
	{
		decl String:classnamex[64];
		GetClientWeapon(client, classnamex, 64);
		if(StrContains(classnamex,"knife",true) == -1 && g_AttackCounter[client] >= 40)
		{
			if(buttons & IN_ATTACK)
			{
				decl ent; 
				ent = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if (IsValidEntity(ent))
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
			}
		}
	}	
}

public StrToLower(String:arg[])
{
	for (new i = 0; i < strlen(arg); i++)
	{
		arg[i] = CharToLower(arg[i]);
	}
}


//http://pastebin.com/YdUWS93H
public bool:CheatFlag(const String:voice_inputfromfile[], bool:isCommand, bool:remove)
{
	if(remove)
	{
		if (!isCommand)
		{
			new Handle:hConVar = FindConVar(voice_inputfromfile);
			if (hConVar != INVALID_HANDLE)
			{
				new flags = GetConVarFlags(hConVar);
				SetConVarFlags(hConVar, flags &= ~FCVAR_CHEAT);
				CloseHandle(hConVar);
				return true;
			} 
			else 
			{
				CloseHandle(hConVar);
				return false;
			}
		} 
		else 
		{
			new flags = GetCommandFlags(voice_inputfromfile);
			if (SetCommandFlags(voice_inputfromfile, flags &= ~FCVAR_CHEAT))
				return true;
			else 
				return false;
		}
	}
	else
	{
		if (!isCommand)
		{
			new Handle:hConVar = FindConVar(voice_inputfromfile);
			if (hConVar != INVALID_HANDLE)
			{
				new flags = GetConVarFlags(hConVar);
				SetConVarFlags(hConVar, flags & FCVAR_CHEAT);
				CloseHandle(hConVar);
				return true;
			}
			else 
			{
				CloseHandle(hConVar);
				return false;
			}
			
			
		} else
		{
			new flags = GetCommandFlags(voice_inputfromfile);
			if (SetCommandFlags(voice_inputfromfile, flags & FCVAR_CHEAT))	
				return true;
			else 
				return false;
				
		}
	}
}

public PlayerPanel(client)
{	
	if (!IsValidClient(client) || g_bMapMenuOpen[client] || g_bTopMenuOpen[client] || IsFakeClient(client))
		return;
	
	if (GetClientMenu(client) == MenuSource_None)
	{
		g_bMenuOpen[client] = false;
		g_bClimbersMenuOpen[client] = false;		
	}	
	if (g_bMenuOpen[client] || g_bClimbersMenuOpen[client]) 
		return;	
	if (g_bTimeractivated[client])
	{
		GetcurrentRunTime(client);
		if(!StrEqual(g_szTimerTitle[client],""))		
		{
			new Handle:panel = CreatePanel();
			DrawPanelText(panel, g_szTimerTitle[client]);
			SendPanelToClient(panel, client, PanelHandler, 1);
			CloseHandle(panel);
		}
	}
	else
	{
		decl String:szTmp[255];
		new Handle:panel = CreatePanel();				
		if(!StrEqual(g_szPlayerPanelText[client],""))
			Format(szTmp, 255, "%s\nSpeed: %.1f u/s",g_szPlayerPanelText[client],GetSpeed(client));
		else
			Format(szTmp, 255, "Speed: %.1f u/s",GetSpeed(client));
		
		DrawPanelText(panel, szTmp);
		SendPanelToClient(panel, client, PanelHandler, 1);
		CloseHandle(panel);
		
	}
}

public GetRGBColor(bot, String:color[256])
{
	decl String:sPart[4];
	new iFirstSpace = FindCharInString(color, ' ', false) + 1;
	new iLastSpace  = FindCharInString(color, ' ', true) + 1;
	strcopy(sPart, iFirstSpace, color);
	if (bot==1)
		g_ReplayBotTpColor[0] = StringToInt(sPart);
	else
		g_ReplayBotProColor[0] = StringToInt(sPart);
	strcopy(sPart, iLastSpace - iFirstSpace, color[iFirstSpace]);
	if (bot==1)
		g_ReplayBotTpColor[1] = StringToInt(sPart);
	else
		g_ReplayBotProColor[1] = StringToInt(sPart);
	strcopy(sPart, strlen(color) - iLastSpace + 1, color[iLastSpace]);
	if (bot==1)
		g_ReplayBotTpColor[2] = StringToInt(sPart);
	else
		g_ReplayBotProColor[2] = StringToInt(sPart);
	
	if (bot == 0 && g_ProBot != -1 && IsValidClient(g_ProBot))
		SetEntityRenderColor(g_ProBot, g_ReplayBotProColor[0], g_ReplayBotProColor[1], g_ReplayBotProColor[2], 50);
	if (bot == 1 && g_TpBot != -1  && IsValidClient(g_TpBot))
		SetEntityRenderColor(g_TpBot, g_ReplayBotTpColor[0], g_ReplayBotTpColor[1], g_ReplayBotTpColor[2], 50);
}

public SpecList(client)
{
	if (!IsValidClient(client) || g_bMapMenuOpen[client] || g_bTopMenuOpen[client]  || IsFakeClient(client))
		return;
		
	if (GetClientMenu(client) == MenuSource_None)
	{
		g_bMenuOpen[client] = false;
		g_bClimbersMenuOpen[client] = false;		
	}
	if (g_bTimeractivated[client] && !g_bSpectate[client]) 
		return; 
	if (g_bMenuOpen[client] || g_bClimbersMenuOpen[client]) 
		return;
	if(!StrEqual(g_szPlayerPanelText[client],""))
	{
		new Handle:panel = CreatePanel();
		DrawPanelText(panel, g_szPlayerPanelText[client]);
		SendPanelToClient(panel, client, PanelHandler, 1);
		CloseHandle(panel);
	}
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public bool:TraceRayDontHitSelf(entity, mask, any:data) 
{
	return (entity != data);
}

stock bool:IntoBool(status)
{
	if(status > 0)
		return true;
	else
		return false;
}

stock BooltoInt(bool:status)
{
	if(status)
		return 1;
	else
		return 0;
}


public PlayQuakeSound_Spec(client, String:buffer[255])
{
	new SpecMode;
	new bool:god;
	if (StrEqual("play *quake/godlike.mp3", buffer))
		god = true;
	
	for(new x = 1; x <= MaxClients; x++) 
	{
		if (IsValidClient(x) && !IsPlayerAlive(x))
		{			
			SpecMode = GetEntProp(x, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				new Target = GetEntPropEnt(x, Prop_Send, "m_hObserverTarget");	
				if (Target == client)
				{
					if ((god == false && g_EnableQuakeSounds[x] == 1) || (god == true && g_EnableQuakeSounds[x] >= 1)  && (god == false && g_ColorChat[x] == 1) || (god == true && g_ColorChat[x] >= 1))
						ClientCommand(x, buffer); 
				}
			}					
		}		
	}
}
public SetPlayerBeam(client, Float:origin[3])
{	
	if(!g_bBeam[client] || g_bOnGround[client] || !g_js_bPlayerJumped[client])
		return;
	new Float:v1[3], Float:v2[3];
	v1[0] = origin[0];
	v1[1] = origin[1];
	v1[2] = g_js_fJump_JumpOff_Pos[client][2];	
	v2[0] = g_fLastPosition[client][0];
	v2[1] = g_fLastPosition[client][1];
	v2[2] = g_js_fJump_JumpOff_Pos[client][2];		
	new color[4] = {255, 255, 255, 100};
	TE_SetupBeamPoints(v1, v2, g_Beam[2], 0, 0, 0, 2.5, 3.0, 3.0, 10, 0.0, color, 0);
	if (g_bJumpBeam[client])
		TE_SendToClient(client);
}
				
public PerformBan(client, String:szbantype[16])
{
	if (IsValidClient(client))
	{
		decl String:szName[64];
		GetClientName(client,szName,64);
		new duration = RoundToZero(g_fBanDuration*60);
		decl String:KickMsg[255];
		Format(KickMsg, sizeof(KickMsg), "KZ-AntiCheat: You have been banned from the server. (reason: %s)",szbantype); 		
		
		if (SOURCEBANS_AVAILABLE())
			SBBanPlayer(0, client, duration, "BhopHack");
		else
			BanClient(client, duration, BANFLAG_AUTO, "BhopHack", KickMsg, "KZTimer");
		KickClient(client, KickMsg);
		db_DeleteCheater(client,g_szSteamID[client]);
	}
}

public bool:WallCheck(client)
{
	decl Float:pos[3];
	decl Float:endpos[3];
	decl Float:angs[3];
	decl Float:vecs[3];                    
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angs);
	GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
	angs[1] = -180.0;
	while (angs[1] != 180.0)
	{
		new Handle:trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

		if(TR_DidHit(trace))
		{				
				TR_GetEndPosition(endpos, trace);
				new Float: fdist = GetVectorDistance(endpos, pos, false);			
				if (fdist <= 25.0)
				{			
					CloseHandle(trace); 
					return true;
				}
		}
		CloseHandle(trace); 
		angs[1]+=15.0;
	}
	return false;
}

public Prestrafe(client, Float: ang, &buttons)
{				
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !(g_bOnGround[client]))
		return;

	decl bool: turning_right;
	turning_right = false;
	decl bool: turning_left;
	turning_left = false;
	
	if( ang < g_fLastAngles[client][1])
		turning_right = true;
	else 
		if( ang > g_fLastAngles[client][1])
			turning_left = true;	

			
	decl String:classname[64];
	if (!g_bPreStrafe)
	{		
		GetClientWeapon(client, classname, 64);
		if(StrEqual(classname, "weapon_hkp2000"))
			SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.042);
		else
			SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.0);
	}
	else
	{
		//var
		decl MaxFrameCount;	
		GetClientWeapon(client, classname, 64);
		decl Float: IncSpeed, Float: DecSpeed;
		decl Float:  speed;
		speed = GetSpeed(client);
		decl bool: bForward;
		
		//direction
		if (GetClientMovingDirection(client,false) > 0.0)
			bForward=true;
		else
			bForward=false;
			
		
		//no mouse movement?
		if (!turning_right && !turning_left)
		{	
			decl Float: diff;
			diff = GetEngineTime() - g_fVelocityModifierLastChange[client]
			if (diff > 0.2)
			{
				if(StrEqual(classname, "weapon_hkp2000"))
					g_PrestrafeVelocity[client] = 1.042;
				else
					g_PrestrafeVelocity[client] = 1.0;
				g_fVelocityModifierLastChange[client] = GetEngineTime();
				SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", g_PrestrafeVelocity[client]);
			}
			return;
		}

		if ((g_bOnGround[client]) && ((buttons & IN_MOVERIGHT) || (buttons & IN_MOVELEFT)) && speed > 249.0)
		{       				
			//tickrate depending values
			if (g_Server_Tickrate == 64)
			{
				MaxFrameCount = 47;
				IncSpeed = 0.0016;
				if ((g_PrestrafeVelocity[client] > 1.08 && StrEqual(classname, "weapon_hkp2000")) || (g_PrestrafeVelocity[client] > 1.04 && !StrEqual(classname, "weapon_hkp2000")))
					IncSpeed = 0.00125;
				DecSpeed = 0.005;
			}
			
			if (g_Server_Tickrate == 102)
			{
				MaxFrameCount = 60;	
				IncSpeed = 0.0011;
				if ((g_PrestrafeVelocity[client] > 1.08 && StrEqual(classname, "weapon_hkp2000")) || (g_PrestrafeVelocity[client] > 1.04 && !StrEqual(classname, "weapon_hkp2000")))
					IncSpeed = 0.001;			
				DecSpeed = 0.005;
				
			}
			
			if (g_Server_Tickrate == 128)
			{
				MaxFrameCount = 75;	
				IncSpeed = 0.0009;
				if ((g_PrestrafeVelocity[client] > 1.08 && StrEqual(classname, "weapon_hkp2000")) || (g_PrestrafeVelocity[client] > 1.04 && !StrEqual(classname, "weapon_hkp2000")))
					IncSpeed = 0.001;			
				DecSpeed = 0.005;
			}
			if (((buttons & IN_MOVERIGHT && turning_right || turning_left && !bForward)) || ((buttons & IN_MOVELEFT && turning_left || turning_right && !bForward)))
			{		
				g_PrestrafeFrameCounter[client]++;						
				//Add speed if Prestrafe frames are less than max frame count	
				
				if (g_PrestrafeFrameCounter[client] < MaxFrameCount)
				{	
					//increase speed
					g_PrestrafeVelocity[client]+= IncSpeed;
					
					//usp
					if(StrEqual(classname, "weapon_hkp2000"))
					{		
						if (g_PrestrafeVelocity[client] > 1.15)
							g_PrestrafeVelocity[client]-=0.007;
					}
					else
						if (g_PrestrafeVelocity[client] > 1.104)
							g_PrestrafeVelocity[client]-=0.007;
					
					g_PrestrafeVelocity[client]+= IncSpeed;
				}
				else
				{
					//decrease speed
					g_PrestrafeVelocity[client]-= DecSpeed;
					
					//usp reset 250.0 speed
					if(StrEqual(classname, "weapon_hkp2000"))
					{
						if (g_PrestrafeVelocity[client]< 1.042)
						{
							g_PrestrafeFrameCounter[client] = 0;
							g_PrestrafeVelocity[client]= 1.042;
						}
					}
					else	
						//knife reset 250.0 speed
						if (g_PrestrafeVelocity[client]< 1.0)
						{	
							g_PrestrafeFrameCounter[client] = 0;
							g_PrestrafeVelocity[client]= 1.0;	
						}
					g_PrestrafeFrameCounter[client] = g_PrestrafeFrameCounter[client] - 2;
				}
			}
			else
			{
				//no prestrafe
				g_PrestrafeVelocity[client] -= 0.04;
				if(StrEqual(classname, "weapon_hkp2000"))
				{
					if (g_PrestrafeVelocity[client]< 1.042)
						g_PrestrafeVelocity[client]= 1.042;
				}
				else						
				if (g_PrestrafeVelocity[client]< 1.0)
					g_PrestrafeVelocity[client]= 1.0;		
			}
		}
		else
		{
			if(StrEqual(classname, "weapon_hkp2000"))
				g_PrestrafeVelocity[client] = 1.042;
			else
				g_PrestrafeVelocity[client] = 1.0;	
			g_PrestrafeFrameCounter[client] = 0;
		}
		
		//Set VelocityModifier	
		SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", g_PrestrafeVelocity[client]);
		g_fVelocityModifierLastChange[client] = GetEngineTime();
	}
}

stock Float:GetClientMovingDirection(client, bool:ladder)
{
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
	      
	new Float:fEyeAngles[3];
	GetClientEyeAngles(client, fEyeAngles);

	if(fEyeAngles[0] > 70.0) fEyeAngles[0] = 70.0;
	if(fEyeAngles[0] < -70.0) fEyeAngles[0] = -70.0;

	new Float:fViewDirection[3];
	
	if (ladder)
		GetEntPropVector(client, Prop_Send, "m_vecLadderNormal", fViewDirection);	
	else
		GetAngleVectors(fEyeAngles, fViewDirection, NULL_VECTOR, NULL_VECTOR);
	   
	NormalizeVector(fVelocity, fVelocity);
	NormalizeVector(fViewDirection, fViewDirection);

	new Float:direction = GetVectorDotProduct(fVelocity, fViewDirection);
	if (ladder)
		direction = direction * -1;
	return direction;
}

public MenuTitleRefreshing(client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
		
	if (GetClientMenu(client) == MenuSource_None)
	{
		g_bMenuOpen[client] = false;
		g_bClimbersMenuOpen[client] = false;		
	}	

	//Timer Panel
	if (!g_bSayHook[client])
	{
		if (g_bTimeractivated[client])
		{
			if (g_bClimbersMenuOpen[client] == false)
				PlayerPanel(client);
		}
		
		//refresh ClimbersMenu when timer active
		if (g_bTimeractivated[client])
		{
			if (g_bClimbersMenuOpen[client] && !g_bMenuOpen[client])
				ClimbersMenu(client);
			else
				if (g_bClimbersMenuwasOpen[client]  && !g_bMenuOpen[client])
				{
					g_bClimbersMenuwasOpen[client]=false;
					ClimbersMenu(client);	
				}
			//Check Time
			if (g_fCurrentRunTime[client] > g_fPersonalRecordPro[client] && !g_bMissedProBest[client] && g_OverallTp[client] == 0 && !g_bPause[client])
			{					
				decl String:szTime[32];
				g_bMissedProBest[client]=true;
				FormatTimeFloat(client, g_fPersonalRecordPro[client], 3,szTime, sizeof(szTime));			
				if (g_fPersonalRecordPro[client] > 0.0)
					PrintToChat(client, "%t", "MissedProBest", MOSSGREEN,WHITE,GRAY,DARKBLUE,szTime,GRAY);
				EmitSoundToClient(client,"buttons/button18.wav",client);
			}
			else
				if (g_fCurrentRunTime[client] > g_fPersonalRecord[client] && !g_bMissedTpBest[client] && !g_bPause[client])
				{
					decl String:szTime[32];
					g_bMissedTpBest[client]=true;
					FormatTimeFloat(client, g_fPersonalRecord[client], 3, szTime, sizeof(szTime));
					if (g_fPersonalRecord[client] > 0.0)
						PrintToChat(client, "%t", "MissedTpBest", MOSSGREEN,WHITE,GRAY,YELLOW,szTime,GRAY);
					EmitSoundToClient(client,"buttons/button18.wav",client);
				}
		}
	}
}

public WjJumpPreCheck(client, &buttons)
{
	if(g_bOnGround[client] && g_js_bPlayerJumped[client] == false && g_js_GroundFrames[client] > 11)
	{
		if (buttons & IN_JUMP || buttons & IN_DUCK)
			g_bLastButtonJump[client] = true;
		else
			g_bLastButtonJump[client] = false;
	}		
}

public MovementCheck(client)
{
	if (StrEqual(g_szMapPrefix[0],"kz") || StrEqual(g_szMapPrefix[0],"xc")  || StrEqual(g_szMapPrefix[0],"kzpro") || StrEqual(g_szMapPrefix[0],"bkz") || StrEqual(g_szMapPrefix[0],"bhop"))
	{		
		new Float:LaggedMovementValue = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
		if (LaggedMovementValue != 1.0)
		{
			PrintToConsole(client,"[KZ] Timer stopped. Reason: LaggedMovementValue modified.")
			g_bTimeractivated[client] = false;
			if (g_js_bPlayerJumped[client])	
				ResetJump(client);
		}
	}
	decl MoveType:mt;
	mt = GetEntityMoveType(client); 
	if (mt == MOVETYPE_FLYGRAVITY)
	{
		PrintToConsole(client,"[KZ] Timer stopped. Reason: MOVETYPE 'FLYGRAVITY' detected.")
		g_bTimeractivated[client] = false;
		if (g_js_bPlayerJumped[client])	
			ResetJump(client);
	}
	if (g_bPause[client] && mt == MOVETYPE_WALK)
		SetEntityMoveType(client, MOVETYPE_NONE);
}

public TeleportCheck(client, Float: origin[3])
{
	if((StrEqual(g_szMapPrefix[0],"kz") || StrEqual(g_szMapPrefix[0],"xc") || StrEqual(g_szMapPrefix[0],"kzpro") || StrEqual(g_szMapPrefix[0],"bkz")) || g_bAutoBhop == false)
	{
		if (!IsFakeClient(client))
		{
			decl Float:sum;
			sum = FloatAbs(origin[0]) - FloatAbs(g_fLastPosition[client][0]);
			if (sum > 15.0 || sum < -15.0)
			{
					if (g_js_bPlayerJumped[client])	
					{
						ResetJump(client);
					}	
			}
			else
			{
				sum = FloatAbs(origin[1]) - FloatAbs(g_fLastPosition[client][1]);
				if (sum > 15.0 || sum < -15.0)
				{
					if (g_js_bPlayerJumped[client])
					{
						ResetJump(client);
					}			
				}
			}	
		}
	}
}

public NoClipCheck(client)
{
	decl MoveType:mt;
	mt = GetEntityMoveType(client); 
	if(!(g_bOnGround[client]))
	{	
		if (mt == MOVETYPE_NOCLIP)
			g_bNoClipUsed[client]=true;
	}
	else
	{		
		if (g_js_GroundFrames[client] > 10)
			g_bNoClipUsed[client]=false;
	}		  
	if(mt == MOVETYPE_NOCLIP && (g_js_bPlayerJumped[client] || g_bTimeractivated[client]))
	{
		if (g_js_bPlayerJumped[client])
			ResetJump(client);
		PrintToConsole(client, "[KZ] Timer stopped. Reason: MOVETYPE 'NOCLIP' detected");
		g_bTimeractivated[client] = false;
	}
}

public SpeedCap(client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;

	static bool:IsOnGround[MAXPLAYERS + 1]; 

	
	new Float:current_speed = GetSpeed(client)
	decl Float:CurVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", CurVelVec);	
	
	//cj addition
	if (!g_js_bPlayerJumped[client] && g_js_DuckCounter[client] > 0)
	{	
		/*if (g_js_DuckCounter[client] > 1)
		{
			if (current_speed > 325.0)
			{
				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, 325.0);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}			
		}
		else*/
		if (current_speed > 315.0)
		{
			NormalizeVector(CurVelVec, CurVelVec);
			ScaleVector(CurVelVec, 315.0);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
		}	
	}
		
	if (g_bOnGround[client])
	{
		if (!IsOnGround[client])
		{
			IsOnGround[client] = true;    
			if (GetVectorLength(CurVelVec) > g_fBhopSpeedCap)
			{
				
				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, g_fBhopSpeedCap);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}
		}
	}
	else
		IsOnGround[client] = false;	
}


public ButtonPressCheck(client, &buttons, Float: origin[3], Float:speed)
{
	if (IsValidClient(client) && !IsFakeClient(client) && g_LastButton[client] != IN_USE && buttons & IN_USE && ((g_fCurrentRunTime[client] > 0.1 || g_fCurrentRunTime[client] == -1.0)))
	{
		decl Float:diff; 
		diff = GetEngineTime() - g_fLastTimeButtonSound[client];
		if (diff > 0.1)
		{
			decl Float:dist; 
			dist=70.0;		
			decl  Float:distance1; 
			distance1 = GetVectorDistance(origin, g_fStartButtonPos); 
			decl  Float: distance2;
			distance2 = GetVectorDistance(origin, g_fEndButtonPos);
			if (distance1 < dist && speed < 251.0 && !g_bFirstStartButtonPush)
			{
				new Handle:trace;
				trace = TR_TraceRayFilterEx(origin, g_fStartButtonPos, MASK_SOLID,RayType_EndPoint,TraceFilterPlayers,client)
				if (!TR_DidHit(trace))
				{
					CL_OnStartTimerPress(client);
					g_fLastTimeButtonSound[client] = GetEngineTime();	
				}
				CloseHandle(trace);								
			}
			else
				if (distance2 < dist  && !g_bFirstEndButtonPush)
				{
					new Handle:trace;
					trace = TR_TraceRayFilterEx(origin, g_fEndButtonPos, MASK_SOLID,RayType_EndPoint,TraceFilterPlayers,client)
					if (!TR_DidHit(trace))
					{
						CL_OnEndTimerPress(client);	
						g_fLastTimeButtonSound[client] = GetEngineTime();
					}
					CloseHandle(trace);		
				}
		}
	}		
	else
	{
		if (IsValidClient(client) && IsFakeClient(client) && g_bTimeractivated[client] && g_LastButton[client] != IN_USE && buttons & IN_USE)
		{
			new Float: distance = GetVectorDistance(origin, g_fEndButtonPos);	
			if (distance < 75.0  && !g_bFirstEndButtonPush)
			{
				new Handle:trace;
				trace = TR_TraceRayFilterEx(origin, g_fEndButtonPos, MASK_SOLID,RayType_EndPoint,TraceFilterPlayers,client)
				if (!TR_DidHit(trace))
				{
					CL_OnEndTimerPress(client);	
					g_fLastTimeButtonSound[client] = GetEngineTime();
				}
				CloseHandle(trace);		
			}			
		}
	}
}

public CalcJumpMaxSpeed(client, Float: fspeed)
{
	if (g_js_bPlayerJumped[client])
		if (g_js_fMax_Speed[client] <= fspeed)
			g_js_fMax_Speed[client] = fspeed;
}

public CalcJumpHeight(client)
{
	if (g_js_bPlayerJumped[client])
	{	
		new Float:origin[3];
		GetClientAbsOrigin(client, origin);
		if (origin[2] > g_js_fMax_Height[client])
			g_js_fMax_Height[client] = origin[2];	
		if (origin[2] > g_js_fJump_JumpOff_Pos[client][2])
			g_fFailedLandingPos[client] = origin;
	}
}

public CalcLastJumpHeight(client, &buttons, Float: origin[3])
{
	if(g_bOnGround[client] && g_js_bPlayerJumped[client] == false && g_js_GroundFrames[client] > 11)
	{
		decl Float:flPos[3];
		GetClientAbsOrigin(client, flPos);	
		g_js_fJump_JumpOff_PosLastHeight[client] = flPos[2];
	}		
	decl Float:distance;
	distance = GetVectorDistance(g_fLastPosition[client], origin);
	
	//booster?
	if(distance > 25.0)
	{
		if(g_js_bPlayerJumped[client])
			g_js_bPlayerJumped[client] = false;
	}
}

public CalcJumpSync(client, Float: speed, Float: ang, &buttons)
{
	if (g_js_bPlayerJumped[client])
	{
		decl bool: turning_right;
		turning_right = false;
		decl bool: turning_left;
		turning_left = false;
		
		if( ang < g_fLastAngles[client][1])
			turning_right = true;
		else 
			if( ang > g_fLastAngles[client][1])
				turning_left = true;	
		
		//strafestats cccc
		if(turning_left || turning_right)
		{
			if( !g_js_Strafing_AW[client] && ((buttons & IN_FORWARD) || (buttons & IN_MOVELEFT)) && !(buttons & IN_MOVERIGHT) && !(buttons & IN_BACK) )
			{			
				g_js_Strafing_AW[client] = true;
				g_js_Strafing_SD[client] = false;					
				g_js_StrafeCount[client]++; 					
				new count = g_js_StrafeCount[client]-1;
				if (count < 100)
				{			
					g_js_Strafe_Good_Sync[client][g_js_StrafeCount[client]-1] = 0.0;
					g_js_Strafe_Frames[client][g_js_StrafeCount[client]-1] = 0.0;		
					g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] = speed;	
					g_js_Strafe_Air_Time[client][g_js_StrafeCount[client] - 1] = GetEngineTime();	
				}
				
			}
			else if( !g_js_Strafing_SD[client] && ((buttons & IN_BACK) || (buttons & IN_MOVERIGHT)) && !(buttons & IN_MOVELEFT) && !(buttons & IN_FORWARD) )
			{
				g_js_Strafing_AW[client] = false;
				g_js_Strafing_SD[client] = true;
				g_js_StrafeCount[client]++; 
				new count = g_js_StrafeCount[client]-1;
				if (count < 100)
				{	
					g_js_Strafe_Good_Sync[client][g_js_StrafeCount[client]-1] = 0.0;
					g_js_Strafe_Frames[client][g_js_StrafeCount[client]-1] = 0.0;		
					g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] = speed;	
					g_js_Strafe_Air_Time[client][g_js_StrafeCount[client] - 1] = GetEngineTime();						
				}
			}				
		}									
		//sync
		if( g_fLastSpeed[client] < speed )
		{
			g_js_Good_Sync_Frames[client]++;		
			if( 0 < g_js_StrafeCount[client] <= 100 )
			{
				g_js_Strafe_Good_Sync[client][g_js_StrafeCount[client] - 1]++;
				g_js_Strafe_Gained[client][g_js_StrafeCount[client] - 1] += (speed - g_fLastSpeed[client]);
			}
		}	
		else 
			if( g_fLastSpeed[client] > speed )
			{
				if( 0 < g_js_StrafeCount[client] <= 100 )
					g_js_Strafe_Lost[client][g_js_StrafeCount[client] - 1] += (g_fLastSpeed[client] - speed);
			}

		//strafe frames
		if( 0 < g_js_StrafeCount[client] <= 100 )
		{
			g_js_Strafe_Frames[client][g_js_StrafeCount[client] - 1]++;
			if( g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] < speed )
				g_js_Strafe_Max_Speed[client][g_js_StrafeCount[client] - 1] = speed;
		}
		//total frames
		g_js_Sync_Frames[client]++;
	}
}

public ServerSidedAutoBhop(client,&buttons)
{
	if (!IsValidClient(client))
		return;
	if (g_bAutoBhop && g_bAutoBhopClient[client])
	{
		if (buttons & IN_JUMP)
			if (!(g_bOnGround[client]))
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
						buttons &= ~IN_JUMP;
						
	}
}
	
public BoosterCheck(client)
{
	decl Float:flbaseVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", flbaseVelocity);
	if (flbaseVelocity[0] != 0.0 || flbaseVelocity[1] != 0.0 || flbaseVelocity[2] != 0.0 && g_js_bPlayerJumped[client])
	{
		g_bTouchedBooster[client]=true;
		ResetJump(client);
	}
}

public WaterCheck(client)
{
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 0 && g_js_bPlayerJumped[client])
		ResetJump(client);
}

public SurfCheck(client)
{	
	if (g_js_block_lj_valid[client]) return;
	if (g_js_bPlayerJumped[client] && WallCheck(client))
	{
		ResetJump(client);
	}
}

public ResetJump(client)
{
	Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>", g_js_fJump_Distance[client]);
	g_js_GroundFrames[client] = 0;
	g_bBeam[client] = false;
	g_js_bPerfJumpOff[client] = false;
	g_js_bPerfJumpOff2[client] = false;
	g_js_bPlayerJumped[client] = false;	
}

public SpecListMenuDead(client)
{
	decl String:szTick[32];
	Format(szTick, 32, "%i", g_Server_Tickrate);			
	decl ObservedUser;
	ObservedUser = -1;
	decl String:sSpecs[512];
	Format(sSpecs, 512, "");
	decl SpecMode;			
	ObservedUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");	
	SpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");	
	
	if (SpecMode == 4 || SpecMode == 5)
	{
		g_SpecTarget[client] = ObservedUser;
		decl count;
		count=0;
		//Speclist
		if (1 <= ObservedUser <= MaxClients)
		{
			decl x;
			decl String:szTime2[32];
			decl String:szTPBest[32];
			decl String:szProBest[32];	
			decl String:szPlayerRank[64];		
			Format(szPlayerRank,32,"");
			
			for(x = 1; x <= MaxClients; x++) 
			{					
				if (IsValidClient(x) && !IsFakeClient(client) && !IsPlayerAlive(x) && GetClientTeam(x) >= 1 && GetClientTeam(x) <= 3)
				{
				
					SpecMode = GetEntProp(x, Prop_Send, "m_iObserverMode");	
					if (SpecMode == 4 || SpecMode == 5)
					{				
						decl ObservedUser2;
						ObservedUser2 = GetEntPropEnt(x, Prop_Send, "m_hObserverTarget");
						if (ObservedUser == ObservedUser2)
						{
							count++;
							if (count < 6)
							Format(sSpecs, 512, "%s%N\n", sSpecs, x);									
						}	
						if (count ==6)
							Format(sSpecs, 512, "%s...", sSpecs);	
					}
				}					
			}
			
			//rank
			if (g_bPointSystem)
			{
				if (g_pr_points[ObservedUser] != 0)
				{
					decl String: szRank[32];
					if (g_PlayerRank[ObservedUser] > g_pr_RankedPlayers)
						Format(szRank,32,"-");
					else
						Format(szRank,32,"%i", g_PlayerRank[ObservedUser]);
					Format(szPlayerRank,32,"Rank: #%s/%i",szRank,g_pr_RankedPlayers);
				}
				else
					Format(szPlayerRank,32,"Rank: -/%i",g_pr_RankedPlayers);
			}
			
			if (g_fPersonalRecord[ObservedUser] > 0.0)
			{	
				FormatTimeFloat(client, g_fPersonalRecord[ObservedUser], 3, szTime2, sizeof(szTime2));
				Format(szTPBest, 32, "%s (#%i/%i)", szTime2,g_MapRankTp[ObservedUser],g_MapTimesCountTp);	
			}	
			else
				Format(szTPBest, 32, "None");	
			if (g_fPersonalRecordPro[ObservedUser] > 0.0)
			{
				FormatTimeFloat(client, g_fPersonalRecordPro[ObservedUser], 3, szTime2, sizeof(szTime2));
				Format(szProBest, 32, "%s (#%i/%i)", szTime2,g_MapRankPro[ObservedUser],g_MapTimesCountPro);		
			}
			else
				Format(szProBest, 32, "None");	
							
			if(!StrEqual(sSpecs,""))
			{
				decl String:szName[MAX_NAME_LENGTH];
				GetClientName(ObservedUser, szName, MAX_NAME_LENGTH);			
				if (g_bSpecInfo[client] && IsFakeClient(ObservedUser))
				{
					g_bSpecInfo[client]=false;
					PrintToChat(client, "%t", "SpecInfo",MOSSGREEN, WHITE,GREEN,WHITE);
				}
				if (g_bTimeractivated[ObservedUser])
				{			
					decl String:szTime[32];
					decl Float:Time;
					Time = GetEngineTime() - g_fStartTime[ObservedUser] - g_fPauseTime[ObservedUser];								
					FormatTimeFloat(client, Time, 4, szTime, sizeof(szTime)); 			
					if (!g_bPause[ObservedUser])
					{
						if (!IsFakeClient(ObservedUser))
						{
							switch(g_ShowSpecs[client])
							{	
								case 0: Format(g_szPlayerPanelText[client], 512, "Specs (%i):\n%s\n  \n%s\nTeleports: %i\n \n%s\nPro: %s\nTP: %s", count, sSpecs, szTime,g_OverallTp[ObservedUser],szPlayerRank,szProBest,szTPBest);
								case 1: Format(g_szPlayerPanelText[client], 512, "Specs (%i)\n \n%s\nTeleports: %i\n \n%s\nPro: %s\nTP: %s", count,szTime,g_OverallTp[ObservedUser],szPlayerRank,szProBest,szTPBest);
								case 2: Format(g_szPlayerPanelText[client], 512, "%s\nTeleports: %i\n \n%s\nPro: %s\nTP: %s", szTime,g_OverallTp[ObservedUser],szPlayerRank,szProBest,szTPBest);
							}
						}
						else
						{	
							if (ObservedUser == g_ProBot)
							{
								switch(g_ShowSpecs[client])
								{	
									case 0: Format(g_szPlayerPanelText[client], 512, "[PRO Replay]\n%s\nTickrate: %s\n \nSpecs (%i):\n%s",szTime,szTick,count, sSpecs);
									case 1: Format(g_szPlayerPanelText[client], 512, "[PRO Replay]\n%s\nTickrate: %s\nSpecs: %i",szTime,szTick,count);
									case 2: Format(g_szPlayerPanelText[client], 512, "[PRO Replay]\n%s\nTickrate: %s",szTime,szTick);		
								}																
							}
							else
							{
								switch(g_ShowSpecs[client])
								{	
									case 0: Format(g_szPlayerPanelText[client], 512, "[TP Replay]\n%s\nTeleports: %i\nTickrate: %s\n \nSpecs (%i):\n%s", szTime,g_ReplayRecordTps,szTick,count,sSpecs);	
									case 1: Format(g_szPlayerPanelText[client], 512, "[TP Replay]\n%s\nTeleports: %i\nTickrate: %s\nSpecs: %i", szTime,g_ReplayRecordTps,szTick,count);	
									case 2: Format(g_szPlayerPanelText[client], 512, "[TP Replay]\n%s\nTeleports: %i\nTickrate: %s", szTime,g_ReplayRecordTps,szTick);	
								}																							
							}
						}					
					}
					else
					{
						if (ObservedUser == g_ProBot)
						{
							switch(g_ShowSpecs[client])
							{	
								case 0: Format(g_szPlayerPanelText[client], 512, "[PRO Replay]\nTime: PAUSED\nTickrate: %s\n \nSpecs (%i):\n%s",szTick,count,sSpecs);	
								case 1: Format(g_szPlayerPanelText[client], 512, "[PRO Replay]\nTime: PAUSED\nTickrate: %s\nSpecs: %i",szTick,count);	
								case 2: Format(g_szPlayerPanelText[client], 512, "[PRO Replay]\nTime: PAUSED\nTickrate: %s",szTick);	
							}							
						}
						else
						{
						
							if (ObservedUser == g_TpBot)
							{
								switch(g_ShowSpecs[client])
								{	
									case 0: Format(g_szPlayerPanelText[client], 512, "[TP Replay]\nTime: PAUSED\nTeleports: %i\nTickrate: %s\n \nSpecs (%i):\n%s", g_ReplayRecordTps,szTick,count,sSpecs);
									case 1: Format(g_szPlayerPanelText[client], 512, "[TP Replay]\nTime: PAUSED\nTeleports: %i\nTickrate: %s\nSpecs: %i", g_ReplayRecordTps,szTick,count);
									case 2: Format(g_szPlayerPanelText[client], 512, "[TP Replay]\nTime: PAUSED\nTeleports: %i\nTickrate: %s", g_ReplayRecordTps,szTick);
								}
							}
							else
							{
								switch(g_ShowSpecs[client])
								{	
									case 0: Format(g_szPlayerPanelText[client], 512, "Specs (%i):\n%s\n  \nPAUSED", count, sSpecs);
									case 1: Format(g_szPlayerPanelText[client], 512, "Specs : %i\n  \nPAUSED", count);
									case 2: Format(g_szPlayerPanelText[client], 512, "PAUSED");
								}
								
							}
						}
					}
				}
				else
				{
					if (ObservedUser != g_ProBot && ObservedUser != g_TpBot) 
					{
						switch(g_ShowSpecs[client])
						{	
							case 0: Format(g_szPlayerPanelText[client], 512, "%Specs (%i):\n%s\n \n%s\nPro: %s\nTP: %s", count, sSpecs,szPlayerRank, szProBest,szTPBest);
							case 1: Format(g_szPlayerPanelText[client], 512, "Specs (%i)\n \n%s\nPro: %s\nTP: %s", count,szPlayerRank,szProBest,szTPBest);	
							case 2: Format(g_szPlayerPanelText[client], 512, "%s\nPro: %s\nTP: %s", szPlayerRank,szProBest,szTPBest);
						}					
					}
				}
			
				if (!g_bShowTime[client] && g_ShowSpecs[client] == 0)
				{
					if (ObservedUser != g_ProBot && ObservedUser != g_TpBot) 
						Format(g_szPlayerPanelText[client], 512,  "%Specs (%i):\n%s\n \n%s\nPro: %s\nTP: %s", count, sSpecs,szPlayerRank, szProBest,szTPBest);
					else
					{
						if (ObservedUser == g_ProBot)
							Format(g_szPlayerPanelText[client], 512, "PRO replay of\n%s\n \nTickrate: %s\n \nSpecs (%i):\n%s", g_szReplayName,szTick, count, sSpecs);	
						else
							Format(g_szPlayerPanelText[client], 512, "TP replay of\n%s\n \nTickrate: %s\n \nSpecs (%i):\n%s", g_szReplayNameTp,szTick, count, sSpecs);	
						
					}	
				}
				if (!g_bShowTime[client] && (g_ShowSpecs[client] == 2 || g_ShowSpecs[client] == 1))
				{
					if (ObservedUser != g_ProBot && ObservedUser != g_TpBot) 
						Format(g_szPlayerPanelText[client], 512, "%s\nPro: %s\nTP: %s", szPlayerRank,szProBest,szTPBest);	
					else
					{
						if (ObservedUser == g_ProBot)
							Format(g_szPlayerPanelText[client], 512, "PRO replay of\n%s\n \nTickrate: %s", g_szReplayName,szTick);	
						else
							Format(g_szPlayerPanelText[client], 512, "Tp replay of\n%s\n \nTickrate: %s", g_szReplayNameTp,szTick);	
						
					}	
				}
				g_bClimbersMenuOpen[client] = false;	
				
				SpecList(client);
			}
		}	
	}	
	else
		g_SpecTarget[client] = -1;
}

public SpecListMenuAlive(client)
{

	if (IsFakeClient(client))
		return;
	
	if (g_ShowSpecs[client] == 2)
	{
		Format(g_szPlayerPanelText[client], 512, "");
		return;
	}
	
	//Spec list for players
	Format(g_szPlayerPanelText[client], 512, "");
	decl String:sSpecs[512];
	decl SpecMode;
	Format(sSpecs, 512, "");
	decl count;
	count=0;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if (IsValidClient(i) && !IsFakeClient(client) && !IsPlayerAlive(i) && !g_bFirstTeamJoin[i] && g_bSpectate[i])
		{			
			SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			if (SpecMode == 4 || SpecMode == 5)
			{		
				decl Target;
				Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");	
				if (Target == client)
				{
					count++;
					if (count < 6)
					Format(sSpecs, 512, "%s%N\n", sSpecs, i);

				}	
				if (count == 6)
					Format(sSpecs, 512, "%s...", sSpecs);
			}					
		}		
	}	
	if (count > 0)
	{
		if (g_ShowSpecs[client] == 0)
			Format(g_szPlayerPanelText[client], 512, "Specs (%i):\n%s ", count, sSpecs);
		else
			if (g_ShowSpecs[client] == 1)
				Format(g_szPlayerPanelText[client], 512, "Specs (%i)\n ", count);			
		SpecList(client);
	}
	else
		Format(g_szPlayerPanelText[client], 512, "");	
}
	
//MACRODOX BHOP PROTECTION
//https://forums.alliedmods.net/showthread.php?p=1678026
public PerformStats(client, target,bool:console_only)
{
	if (IsValidClient(client) && !IsFakeClient(target))
	{
		decl String:banstats[512];
		GetClientStats(target, banstats, sizeof(banstats));
		if (!console_only)
			PrintToChat(client, "[%cKZ%c] %s",MOSSGREEN,WHITE,banstats);			
		PrintToConsole(client, "[KZ] %s, fps_max: %i, Tickrate: %i",banstats,g_fps_max[target],	g_Server_Tickrate);
		if (g_bAutoBhop)
		{
			PrintToChat(client, "[%cKZ%c] AutoBhop enabled",MOSSGREEN,WHITE);
			PrintToConsole(client, "[KZ] AutoBhop enabled");
		}
	}
}

//MACRODOX BHOP PROTECTION
//https://forums.alliedmods.net/showthread.php?p=1678026
public GetClientStats(client, String:string[], length)
{
	new Float:perf =  g_fafAvgPerfJumps[client] * 100;
	decl String:map[128];
	decl String:szName[64];
	GetClientName(client,szName,64);
	GetCurrentMap(map, 128);
	Format(string, 512, "%cPlayer%c: %c%s%c - %cScroll pattern%c: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %cAvg jumps/speed%c: %.1f/%.1f %cperfect jump ratio%c: %.2f%c",	
	LIMEGREEN,
	WHITE,
	GREEN,
	szName,
	WHITE,
	LIMEGREEN,
	WHITE,
	g_aaiLastJumps[client][0],
	g_aaiLastJumps[client][1],
	g_aaiLastJumps[client][2],
	g_aaiLastJumps[client][3],
	g_aaiLastJumps[client][4],
	g_aaiLastJumps[client][5],
	g_aaiLastJumps[client][6],
	g_aaiLastJumps[client][7],
	g_aaiLastJumps[client][8],
	g_aaiLastJumps[client][9],
	g_aaiLastJumps[client][10],
	g_aaiLastJumps[client][11],
	g_aaiLastJumps[client][12],
	g_aaiLastJumps[client][13],
	g_aaiLastJumps[client][14],
	g_aaiLastJumps[client][15],
	g_aaiLastJumps[client][16],
	g_aaiLastJumps[client][17],
	g_aaiLastJumps[client][18],
	g_aaiLastJumps[client][19],
	g_aaiLastJumps[client][20],
	g_aaiLastJumps[client][21],
	g_aaiLastJumps[client][22],
	g_aaiLastJumps[client][23],
	g_aaiLastJumps[client][24],
	g_aaiLastJumps[client][25],
	LIMEGREEN,
	WHITE,
	g_fafAvgJumps[client],
	g_fafAvgSpeed[client],
	LIMEGREEN,
	WHITE,
	perf,
	PERCENT);
}

//MACRODOX BHOP PROTECTION - modified by 1NutWunDeR
//https://forums.alliedmods.net/showthread.php?p=1678026
public GetClientStatsLog(client, String:string[], length)
{
	new Float:perf =  g_fafAvgPerfJumps[client] * 100;
	new Float:origin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
	decl String:map[128];
	GetCurrentMap(map, 128);
	Format(string, length, "%L Scroll pattern: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i, Avg scroll pattern: %f, Avg speed: %f, Perfect jump ratio: %.2f%c, fps_max: %i, Tickrate: %i",
	client,
	g_aaiLastJumps[client][0],
	g_aaiLastJumps[client][1],
	g_aaiLastJumps[client][2],
	g_aaiLastJumps[client][3],
	g_aaiLastJumps[client][4],
	g_aaiLastJumps[client][5],
	g_aaiLastJumps[client][6],
	g_aaiLastJumps[client][7],
	g_aaiLastJumps[client][8],
	g_aaiLastJumps[client][9],
	g_aaiLastJumps[client][10],
	g_aaiLastJumps[client][11],
	g_aaiLastJumps[client][12],
	g_aaiLastJumps[client][13],
	g_aaiLastJumps[client][14],
	g_aaiLastJumps[client][15],
	g_aaiLastJumps[client][16],
	g_aaiLastJumps[client][17],
	g_aaiLastJumps[client][18],
	g_aaiLastJumps[client][19],
	g_aaiLastJumps[client][20],
	g_aaiLastJumps[client][21],
	g_aaiLastJumps[client][22],
	g_aaiLastJumps[client][23],
	g_aaiLastJumps[client][24],
	g_aaiLastJumps[client][25],
	g_aaiLastJumps[client][26],
	g_aaiLastJumps[client][27],
	g_aaiLastJumps[client][28],
	g_aaiLastJumps[client][29],
	g_fafAvgJumps[client],
	g_fafAvgSpeed[client],
	perf,
	PERCENT,
	g_fps_max[client],
	g_Server_Tickrate);
}
public MacroBan(client)
{
	if (g_bAntiCheat && !g_bFlagged[client])
	{
		decl String:banstats[256];
		decl String:reason[256];
		Format(reason, 256, "bhop hack");
		GetClientStatsLog(client, banstats, sizeof(banstats));			
		decl String:sPath[512];
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
		if (g_bAutoBan)
		{
			LogToFile(sPath, "%s, Reason: bhop hack detected. (autoban)", banstats);	
		}
		else
			LogToFile(sPath, "%s, Reason: bhop hack detected.", banstats);	
		g_bFlagged[client] = true;
		if (g_bAutoBan)	
			PerformBan(client,"bhop hack");
	}
}

//macrodox addon by 1nut
public BhopPatternCheck(client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || IsFakeClient(client) || !g_bAntiCheat || g_bFlagged[client] || g_fafAvgPerfJumps[client] < 0.5 || g_fafAvgSpeed[client] < 290.0)
		return;

	//decl.
	new pattern_array[50];
	new pattern_sum;
	new jumps;
	
	//analyse the last jumps 
	for (new i = 0; i < 30; i++)
	{
		new value = g_aaiLastJumps[client][i];
		if ( 1 < value < 50)
		{
			pattern_sum+=value;
			jumps++;
			pattern_array[value]++;
		}
	}	
	
	//pattern check #1	
	new Float:avg_scroll_pattern = float(pattern_sum) / float(jumps);
	if (avg_scroll_pattern > 30.0)
	{
		MacroBan(client);
		return;
	}
	//pattern check #2
	for (new j = 2; j < 50; j++)
	{
		if (pattern_array[j] >= 20)		
		{
			MacroBan(client);
			return;
		}
	}	
}

//MultiPlayer Bunnyhop
//https://forums.alliedmods.net/showthread.php?p=808724
public Teleport(client, bhop,bool:mt)
{
	decl i;
	new tele = -1, ent = bhop;

	//search door trigger list
	for (i = 0; i < g_BhopDoorCount; i++) 
	{
		if(ent == g_BhopDoorList[i]) 
		{
			tele = g_BhopDoorTeleList[i];
			break;
		}
	}

	//no destination? search button trigger list
	if(tele == -1) 
	{
		for (i = 0; i < g_BhopButtonCount; i++) 
		{
			if(ent == g_BhopButtonList[i]) 
			{
				tele = g_BhopButtonTeleList[i];
				break;
			}
		}
	}
	
	//no destination? search multiple trigger list
	for (i = 0; i < g_BhopMultipleCount; i++) 
	{
		if(ent == g_BhopMultipleList[i]) 
		{		
			tele = g_BhopMultipleTeleList[i];
			break;
		}
	}
	
	//set teleport destination
	if(tele != -1 && IsValidEntity(tele)) 
	{
		decl String:targetName[64];
		decl String:destName[64];
		GetEntPropString(tele, Prop_Data, "m_target", targetName, sizeof(targetName));  
		new dest = -1;	
		while ((dest = FindEntityByClassname(dest, "info_teleport_destination")) != -1)
		{
			GetEntPropString(dest, Prop_Data, "m_iName", destName, sizeof(destName));    
			if (StrEqual(destName, targetName))
			{
				
				new Float: pos[3];
				new Float: ang[3];
				GetEntPropVector(dest, Prop_Data, "m_angRotation", ang); 
				GetEntPropVector(dest, Prop_Send, "m_vecOrigin", pos);
								
				//synergy fix
				if ((StrContains(g_szMapName,"kz_synergy_ez") != -1 || StrContains(g_szMapName,"kz_synergy_x") != -1) && StrEqual(targetName,"1-1"))
				{	
				}
				else
				{					
					DoValidTeleport(client, pos,ang,false);
				}
			}
		}
	}
}

//MultiPlayer Bunnyhop
//https://forums.alliedmods.net/showthread.php?p=808724
public FindBhopBlocks() 
{
	decl Float:startpos[3], Float:endpos[3], Float:mins[3], Float:maxs[3], tele;
	new ent = -1;
	new Float:flbaseVelocity[3];	
	while((ent = FindEntityByClassname(ent,"func_door")) != -1) 
	{
		if(g_DoorOffs_vecPosition1 == -1) 
		{
			g_DoorOffs_vecPosition1 = FindDataMapOffs(ent,"m_vecPosition1");
			g_DoorOffs_vecPosition2 = FindDataMapOffs(ent,"m_vecPosition2");
			g_DoorOffs_flSpeed = FindDataMapOffs(ent,"m_flSpeed");
			g_DoorOffs_spawnflags = FindDataMapOffs(ent,"m_spawnflags");
			g_DoorOffs_NoiseMoving = FindDataMapOffs(ent,"m_NoiseMoving");
			g_DoorOffs_sLockedSound = FindDataMapOffs(ent,"m_ls.sLockedSound");
			g_DoorOffs_bLocked = FindDataMapOffs(ent,"m_bLocked");		
		}

		GetEntDataVector(ent,g_DoorOffs_vecPosition1,startpos);
		GetEntDataVector(ent,g_DoorOffs_vecPosition2,endpos);
		
		
		if(startpos[2] > endpos[2]) 
		{
			GetEntDataVector(ent,g_Offs_vecMins,mins);
			GetEntDataVector(ent,g_Offs_vecMaxs,maxs);
			GetEntPropVector(ent, Prop_Data, "m_vecBaseVelocity", flbaseVelocity);
			new Float:speed = GetEntDataFloat(ent,g_DoorOffs_flSpeed);
			
			if((flbaseVelocity[0] != 1100.0 && flbaseVelocity[1] != 1100.0 && flbaseVelocity[2] != 1100.0) && (maxs[2] - mins[2]) < 80 && (startpos[2] > endpos[2] || speed > 100))
			{
				startpos[0] += (mins[0] + maxs[0]) * 0.5;
				startpos[1] += (mins[1] + maxs[1]) * 0.5;
				startpos[2] += maxs[2];
				
				if((tele = CustomTraceForTeleports(startpos,endpos[2] + maxs[2])) != -1 || (speed > 100 && startpos[2] < endpos[2]))
				{
					g_BhopDoorList[g_BhopDoorCount] = ent;
					g_BhopDoorTeleList[g_BhopDoorCount] = tele;

					if(++g_BhopDoorCount == sizeof g_BhopDoorList) 
					{
						break;
					}
				}
			}
		}
	}

	ent = -1;

	while((ent = FindEntityByClassname(ent,"func_button")) != -1) 
	{
		if(g_ButtonOffs_vecPosition1 == -1) 
		{
			g_ButtonOffs_vecPosition1 = FindDataMapOffs(ent,"m_vecPosition1");
			g_ButtonOffs_vecPosition2 = FindDataMapOffs(ent,"m_vecPosition2");
			g_ButtonOffs_flSpeed = FindDataMapOffs(ent,"m_flSpeed");
			g_ButtonOffs_spawnflags = FindDataMapOffs(ent,"m_spawnflags");
		}

		GetEntDataVector(ent,g_ButtonOffs_vecPosition1,startpos);
		GetEntDataVector(ent,g_ButtonOffs_vecPosition2,endpos);

		if(startpos[2] > endpos[2] && (GetEntData(ent,g_ButtonOffs_spawnflags,4) & SF_BUTTON_TOUCH_ACTIVATES)) 
		{
			GetEntDataVector(ent,g_Offs_vecMins,mins);
			GetEntDataVector(ent,g_Offs_vecMaxs,maxs);

			startpos[0] += (mins[0] + maxs[0]) * 0.5;
			startpos[1] += (mins[1] + maxs[1]) * 0.5;
			startpos[2] += maxs[2];

			if((tele = CustomTraceForTeleports(startpos,endpos[2] + maxs[2])) != -1) 
			{
				g_BhopButtonList[g_BhopButtonCount] = ent;
				g_BhopButtonTeleList[g_BhopButtonCount] = tele;

				if(++g_BhopButtonCount == sizeof g_BhopButtonList) 
				{
					break;
				}
			}
		}
	}
	
	AlterBhopBlocks(false);
}

public Entity_Touch3(bhop,client) 
{
	if(IsValidClient(client)) 		
		g_bOnBhopPlattform[client] = false;
}
	
public Entity_Touch2(bhop,client) 
{
	if(IsValidClient(client)) 
	{		
		g_bOnBhopPlattform[client]=true;	
		if (g_bSingleTouch)
		{
			if (bhop == g_LastGroundEnt[client] && (GetEngineTime() - g_fLastTimeBhopBlock[client]) <= 0.9)
			{
				g_LastGroundEnt[client] = -1;		
				Teleport(client, bhop,true);
			}
			else
			{
				g_fLastTimeBhopBlock[client] = GetEngineTime();
				g_LastGroundEnt[client] = bhop;
			}		
		}
	}
}


CustomTraceForTeleports2(const Float:pos[3]) 
{
	decl teleports[512];
	new tpcount, ent = -1;
	while((ent = FindEntityByClassname(ent,"trigger_teleport")) != -1 && tpcount != sizeof teleports)
		teleports[tpcount++] = ent;
	
	decl Float:mins[3], Float:maxs[3], Float:origin[3], Float: step, Float:endpos, i;
	origin[0] = pos[0];
	origin[1] = pos[1];
	origin[2] = pos[2];
	step = 1.0;
	endpos = origin[2] - 30;	
	do 
	{
		for(i = 0; i < tpcount; i++) 
		{
			ent = teleports[i];
			GetAbsBoundingBox(ent,mins,maxs);
			if(mins[0] <= origin[0] <= maxs[0] && mins[1] <= origin[1] <= maxs[1] && mins[2] <= origin[2] <= maxs[2]) 
				return ent;
		}
		origin[2] -= step;
	} 
	while(endpos <= origin[2]);
	return -1;
}

//MultiPlayer Bunnyhop
//https://forums.alliedmods.net/showthread.php?p=808724
public AlterBhopBlocks(bool:bRevertChanges) 
{
	static Float:vecDoorPosition2[sizeof g_BhopDoorList][3];
	static Float:flDoorSpeed[sizeof g_BhopDoorList];
	static iDoorSpawnflags[sizeof g_BhopDoorList];
	static bool:bDoorLocked[sizeof g_BhopDoorList];
	static Float:vecButtonPosition2[sizeof g_BhopButtonList][3];
	static Float:flButtonSpeed[sizeof g_BhopButtonList];
	static iButtonSpawnflags[sizeof g_BhopButtonList];
	decl ent, i;
	if(bRevertChanges) 
	{
		for(i = 0; i < g_BhopDoorCount; i++) 
		{
			ent = g_BhopDoorList[i];
			if(IsValidEntity(ent)) 
			{
				SetEntDataVector(ent,g_DoorOffs_vecPosition2,vecDoorPosition2[i]);
				SetEntDataFloat(ent,g_DoorOffs_flSpeed,flDoorSpeed[i]);
				SetEntData(ent,g_DoorOffs_spawnflags,iDoorSpawnflags[i],4);
				if(!bDoorLocked[i]) 
				{
					AcceptEntityInput(ent,"Unlock");
				}
				SDKUnhook(ent,SDKHook_Touch,Entity_Touch);
				SDKUnhook(ent,SDKHook_StartTouch,Entity_Touch2);
				SDKUnhook(ent,SDKHook_EndTouch,Entity_Touch3);
			}
		}

		for(i = 0; i < g_BhopButtonCount; i++) 
		{
			ent = g_BhopButtonList[i];
			if(IsValidEntity(ent)) 
			{
				SetEntDataVector(ent,g_ButtonOffs_vecPosition2,vecButtonPosition2[i]);
				SetEntDataFloat(ent,g_ButtonOffs_flSpeed,flButtonSpeed[i]);
				SetEntData(ent,g_ButtonOffs_spawnflags,iButtonSpawnflags[i],4);
				if(flDoorSpeed[i] <= 100)
				{
					SDKUnhook(ent,SDKHook_Touch,Entity_Touch);
					SDKUnhook(ent,SDKHook_StartTouch,Entity_Touch2);
				}
				else
				{
					SDKUnhook(ent,SDKHook_Touch,Entity_BoostTouch);
					SDKUnhook(ent,SDKHook_StartTouch,Entity_Touch2);
				}	
			}
		}
	}
	else 
	{	
		decl Float:startpos[3];
		for (i = 0; i < g_BhopDoorCount; i++)
		{
			ent = g_BhopDoorList[i];			
			GetEntDataVector(ent,g_DoorOffs_vecPosition2,vecDoorPosition2[i]);
			flDoorSpeed[i] = GetEntDataFloat(ent,g_DoorOffs_flSpeed);
			iDoorSpawnflags[i] = GetEntData(ent,g_DoorOffs_spawnflags,4);
			bDoorLocked[i] = GetEntData(ent,g_DoorOffs_bLocked,1) ? true : false;
			GetEntDataVector(ent,g_DoorOffs_vecPosition1,startpos);
			SetEntDataVector(ent,g_DoorOffs_vecPosition2,startpos);
			SetEntDataFloat(ent,g_DoorOffs_flSpeed,0.0);
			SetEntData(ent,g_DoorOffs_spawnflags,SF_DOOR_PTOUCH,4);
			AcceptEntityInput(ent,"Lock");
			SetEntData(ent,g_DoorOffs_sLockedSound,GetEntData(ent,g_DoorOffs_NoiseMoving,4),4);
			SDKHook(ent,SDKHook_Touch,Entity_Touch);
			SDKHook(ent,SDKHook_StartTouch,Entity_Touch2);
			SDKHook(ent,SDKHook_EndTouch,Entity_Touch3);
		}
		
		for (i = 0; i < g_BhopButtonCount; i++)
		{
			ent = g_BhopButtonList[i];
			GetEntDataVector(ent,g_ButtonOffs_vecPosition2,vecButtonPosition2[i]);
			flButtonSpeed[i] = GetEntDataFloat(ent,g_ButtonOffs_flSpeed);
			iButtonSpawnflags[i] = GetEntData(ent,g_ButtonOffs_spawnflags,4);
			GetEntDataVector(ent,g_ButtonOffs_vecPosition1,startpos);
			SetEntDataVector(ent,g_ButtonOffs_vecPosition2,startpos);
			SetEntDataFloat(ent,g_ButtonOffs_flSpeed,0.0);
			SetEntData(ent,g_ButtonOffs_spawnflags,SF_BUTTON_DONTMOVE|SF_BUTTON_TOUCH_ACTIVATES,4);			
			if(flDoorSpeed[i] <= 100)
			{
				SDKHook(ent,SDKHook_Touch,Entity_Touch);
				SDKHook(ent,SDKHook_StartTouch,Entity_Touch2);
			}
			else
			{
				g_fBhopDoorSp[i] = flDoorSpeed[i];
				SDKHook(ent,SDKHook_Touch,Entity_BoostTouch);
				SDKHook(ent,SDKHook_StartTouch,Entity_Touch2);
			}		
		}		
	}
}

//MultiPlayer Bunnyhop
//https://forums.alliedmods.net/showthread.php?p=808724
public Entity_BoostTouch(bhop,client) 
{
	if(0 < client <= MaxClients) 
	{
		new Float:speed = -1.0;		
		static i;
		for(i = 0; i < g_BhopDoorCount; i++) 
		{
			if(bhop == g_BhopDoorList[i]) 
			{
				speed = g_fBhopDoorSp[i]
				break
			}
		}		
		if(speed != -1 && speed) 
		{
			
			new Float:ovel[3]
			Entity_GetBaseVelocity(client, ovel)
			new Float:evel[3]
			Entity_GetLocalVelocity(client, evel)
			if(ovel[2] < speed && evel[2] < speed)
			{
				new Float:vel[3]
				vel[0] = Float:0
				vel[1] = Float:0
				vel[2] = speed * 1.8
				Entity_SetBaseVelocity(client, vel)
			}
		}
	}
}

//Credits: MultiPlayer Bunny Hops: Source by DaFox & petsku
//https://forums.alliedmods.net/showthread.php?p=808724
public Entity_Touch(bhop,client) 
{
	//bhop = entity
	if(IsValidClient(client)) 
	{	
	
		g_bOnBhopPlattform[client]=true;

		static Float:flPunishTime[MAXPLAYERS + 1], iLastBlock[MAXPLAYERS + 1] = { -1,... };		
		new Float:time = GetEngineTime();		
		new Float:diff = time - flPunishTime[client];		
		if(iLastBlock[client] != bhop || diff > 0.1) 
		{
			//reset cooldown
			iLastBlock[client] = bhop;
			flPunishTime[client] = time + 0.05;
			
		}
		else 
		{
			if(diff > 0.05) 
			{
				if(time - g_fLastJump[client] > (0.05 + 0.1))
				{
					Teleport(client, iLastBlock[client],false);
					iLastBlock[client] = -1;
				}
			}		
		}
	}
}


//MultiPlayer Bunnyhop
//https://forums.alliedmods.net/showthread.php?p=808724
CustomTraceForTeleports(const Float:startpos[3],Float:endheight,Float:step=1.0) 
{
	decl teleports[512];
	new tpcount, ent = -1;
	while((ent = FindEntityByClassname(ent,"trigger_teleport")) != -1 && tpcount != sizeof teleports)
	{
		teleports[tpcount++] = ent;
	}
	
	decl Float:mins[3], Float:maxs[3], Float:origin[3], i;
	origin[0] = startpos[0];
	origin[1] = startpos[1];
	origin[2] = startpos[2];
	do 
	{
		for(i = 0; i < tpcount; i++) 
		{
			ent = teleports[i];
			GetAbsBoundingBox(ent,mins,maxs);

			if(mins[0] <= origin[0] <= maxs[0] && mins[1] <= origin[1] <= maxs[1] && mins[2] <= origin[2] <= maxs[2]) 
			{
				return ent;
			}
		}
		origin[2] -= step;
	} 
	while(origin[2] >= endheight);
	return -1;
}

//MultiPlayer Bunnyhop
//https://forums.alliedmods.net/showthread.php?p=808724
public GetAbsBoundingBox(ent,Float:mins[3],Float:maxs[3]) 
{
	decl Float:origin[3];
	GetEntDataVector(ent,g_Offs_vecOrigin,origin);
	GetEntDataVector(ent,g_Offs_vecMins,mins);
	GetEntDataVector(ent,g_Offs_vecMaxs,maxs);
	mins[0] += origin[0];
	mins[1] += origin[1];
	mins[2] += origin[2];
	maxs[0] += origin[0];
	maxs[1] += origin[1];
	maxs[2] += origin[2];
}

public FindMultipleBlocks() 
{
	decl Float:pos[3], tele;
	new ent = -1;
	while((ent = FindEntityByClassname(ent,"trigger_multiple")) != -1) 
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		if((tele = CustomTraceForTeleports2(pos)) != -1) 
		{
			g_BhopMultipleList[g_BhopMultipleCount] = ent;
			g_BhopMultipleTeleList[g_BhopMultipleCount] = tele;		
			SDKHook(ent,SDKHook_StartTouch,Entity_Touch2);	
			if(++g_BhopMultipleCount == sizeof g_BhopMultipleList) 
				break;
		}
	}
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
GetPos(client,arg) 
{
	decl Float:origin[3],Float:angles[3]	
	GetClientEyePosition(client,origin)
	GetClientEyeAngles(client,angles)	
	new Handle:trace = TR_TraceRayFilterEx(origin,angles,MASK_SHOT,RayType_Infinite,TraceFilterPlayers,client)
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);
		PrintToChat(client, "%t", "Measure3",MOSSGREEN,WHITE);
		return;
	}
	TR_GetEndPosition(origin,trace);
	CloseHandle(trace);
	g_fvMeasurePos[client][arg][0] = origin[0];
	g_fvMeasurePos[client][arg][1] = origin[1];
	g_fvMeasurePos[client][arg][2] = origin[2];
	PrintToChat(client, "%t", "Measure4",MOSSGREEN,WHITE,arg+1,origin[0],origin[1],origin[2]);	
	if(arg == 0) 
	{
		if(g_hP2PRed[client] != INVALID_HANDLE) 
		{
			CloseHandle(g_hP2PRed[client]);
			g_hP2PRed[client] = INVALID_HANDLE;
		}
		g_bMeasurePosSet[client][0] = true;
		g_hP2PRed[client] = CreateTimer(1.0,Timer_P2PRed,client,TIMER_REPEAT);
		P2PXBeam(client,0);
	}
	else 
	{
		if(g_hP2PGreen[client] != INVALID_HANDLE) 
		{
			CloseHandle(g_hP2PGreen[client]);
			g_hP2PGreen[client] = INVALID_HANDLE;
		}
		g_bMeasurePosSet[client][1] = true;
		P2PXBeam(client,1);
		g_hP2PGreen[client] = CreateTimer(1.0,Timer_P2PGreen,client,TIMER_REPEAT);
	}
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
public Action:Timer_P2PRed(Handle:timer,any:client) 
{
	P2PXBeam(client,0);
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
public Action:Timer_P2PGreen(Handle:timer,any:client) 
{
	P2PXBeam(client,1);
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
P2PXBeam(client,arg) 
{
	decl Float:Origin0[3],Float:Origin1[3],Float:Origin2[3],Float:Origin3[3]	
	Origin0[0] = (g_fvMeasurePos[client][arg][0] + 8.0);
	Origin0[1] = (g_fvMeasurePos[client][arg][1] + 8.0);
	Origin0[2] = g_fvMeasurePos[client][arg][2];	
	Origin1[0] = (g_fvMeasurePos[client][arg][0] - 8.0);
	Origin1[1] = (g_fvMeasurePos[client][arg][1] - 8.0);
	Origin1[2] = g_fvMeasurePos[client][arg][2];	
	Origin2[0] = (g_fvMeasurePos[client][arg][0] + 8.0);
	Origin2[1] = (g_fvMeasurePos[client][arg][1] - 8.0);
	Origin2[2] = g_fvMeasurePos[client][arg][2];	
	Origin3[0] = (g_fvMeasurePos[client][arg][0] - 8.0);
	Origin3[1] = (g_fvMeasurePos[client][arg][1] + 8.0);
	Origin3[2] = g_fvMeasurePos[client][arg][2];	
	if(arg == 0) 
	{
		Beam(client,Origin0,Origin1,0.97,2.0,255,0,0);
		Beam(client,Origin2,Origin3,0.97,2.0,255,0,0);
	}
	else 
	{
		Beam(client,Origin0,Origin1,0.97,2.0,0,255,0);
		Beam(client,Origin2,Origin3,0.97,2.0,0,255,0);
	}
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
Beam(client,Float:vecStart[3],Float:vecEnd[3],Float:life,Float:width,r,g,b) 
{
	TE_Start("BeamPoints")
	TE_WriteNum("m_nModelIndex",g_Beam[2]);
	TE_WriteNum("m_nHaloIndex",0);
	TE_WriteNum("m_nStartFrame",0);
	TE_WriteNum("m_nFrameRate",0);
	TE_WriteFloat("m_fLife",life);
	TE_WriteFloat("m_fWidth",width);
	TE_WriteFloat("m_fEndWidth",width);
	TE_WriteNum("m_nFadeLength",0);
	TE_WriteFloat("m_fAmplitude",0.0);
	TE_WriteNum("m_nSpeed",0);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("a",255);
	TE_WriteNum("m_nFlags",0);
	TE_WriteVector("m_vecStartPoint",vecStart);
	TE_WriteVector("m_vecEndPoint",vecEnd);
	TE_SendToClient(client);
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
ResetPos(client) 
{
	if(g_hP2PRed[client] != INVALID_HANDLE) 
	{
		CloseHandle(g_hP2PRed[client]);
		g_hP2PRed[client] = INVALID_HANDLE;
	}
	if(g_hP2PGreen[client] != INVALID_HANDLE) 
	{
		CloseHandle(g_hP2PGreen[client]);
		g_hP2PGreen[client] = INVALID_HANDLE;
	}
	g_bMeasurePosSet[client][0] = false;
	g_bMeasurePosSet[client][1] = false;

	g_fvMeasurePos[client][0][0] = 0.0; //This is stupid.
	g_fvMeasurePos[client][0][1] = 0.0;
	g_fvMeasurePos[client][0][2] = 0.0;
	g_fvMeasurePos[client][1][0] = 0.0;
	g_fvMeasurePos[client][1][1] = 0.0;
	g_fvMeasurePos[client][1][2] = 0.0;
}

// Measure-Plugin by DaFox
//https://forums.alliedmods.net/showthread.php?t=88830?t=88830
public bool:TraceFilterPlayers(entity,contentsMask) 
{
	return (entity > MaxClients) ? true : false;
} //Thanks petsku

//jsfunction.inc
stock GetGroundOrigin(client, Float:pos[3])
{
	decl Float:fOrigin[3], Float:result[3];
	GetClientAbsOrigin(client, fOrigin);
	TraceClientGroundOrigin(client, result, 100.0);
	pos = fOrigin;
	pos[2] = result[2];
}

//jsfunction.inc
stock TraceClientGroundOrigin(client, Float:result[3], Float:offset)
{
	decl Float:temp[2][3];
	GetClientEyePosition(client, temp[0]);
	temp[1] = temp[0];
	temp[1][2] -= offset;
	new Float:mins[] ={-16.0, -16.0, 0.0};
	new Float:maxs[] =	{16.0, 16.0, 60.0};
	new Handle:trace = TR_TraceHullFilterEx(temp[0], temp[1], mins, maxs, MASK_SHOT, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

//jsfunction.inc
public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
    return entity > MaxClients;
}

public CreateNavFiles()
{
	decl String:DestFile[256];
	decl String:SourceFile[256];
	Format(SourceFile, sizeof(SourceFile), "maps/replay_bot.nav");
	if (!FileExists(SourceFile))
	{
		LogError("<KZTIMER> Failed to create .nav files. Reason: %s doesn't exist!", SourceFile);
		return;
	}
	decl String:map[256];
	new mapListSerial = -1;
	if (ReadMapList(g_MapList,	mapListSerial, "mapcyclefile", MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT) == INVALID_HANDLE)
		if (mapListSerial == -1)
			return;

	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{
		GetArrayString(g_MapList, i, map, sizeof(map));
		if (!StrEqual(map, "", false))
		{
			Format(DestFile, sizeof(DestFile), "maps/%s.nav", map);
			if (!FileExists(DestFile))
				File_Copy(SourceFile, DestFile);
		}
	}	
}

public LoadInfoBot()
{
	if (!g_bInfoBot)
		return;

	g_InfoBot = -1;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsFakeClient(i) || i == g_TpBot || i == g_ProBot)
			continue;
		g_InfoBot = i;
		break;
	}
	if(IsValidClient(g_InfoBot))
	{	
		Format(g_pr_rankname[g_InfoBot], 16, "BOT");
		CS_SetClientClanTag(g_InfoBot, "");
		SetEntProp(g_InfoBot, Prop_Send, "m_iAddonBits", 0);
		SetEntProp(g_InfoBot, Prop_Send, "m_iPrimaryAddon", 0);
		SetEntProp(g_InfoBot, Prop_Send, "m_iSecondaryAddon", 0); 		
		SetEntProp(g_InfoBot, Prop_Send, "m_iObserverMode", 1);
		SetInfoBotName(g_InfoBot);	
	}
	else
	{
		new count = 0;
		if (g_bTpReplay)
			count++;
		if (g_bProReplay)
			count++;
		if (g_bInfoBot)
			count++;
		if (count==0)
			return;
		decl String:szBuffer2[64];
		Format(szBuffer2, sizeof(szBuffer2), "bot_quota %i", count); 	
		ServerCommand(szBuffer2);		
		CreateTimer(0.5, RefreshInfoBot,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RefreshInfoBot(Handle:timer)
{
	LoadInfoBot();
}
	
	
public SetInfoBotName(ent)
{
	decl String:szBuffer[64];
	decl String:sNextMap[128];	
	if (!IsValidClient(g_InfoBot) || !g_bInfoBot)
		return;
	if(g_bMapChooser && EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished())
		Format(sNextMap, sizeof(sNextMap), "Pending Vote");
	else
	{
		GetNextMap(sNextMap, sizeof(sNextMap));
		new String:mapPieces[6][128];
		new lastPiece = ExplodeString(sNextMap, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
		Format(sNextMap, sizeof(sNextMap), "%s", mapPieces[lastPiece-1]); 			
	}			
	new timeleft;
	GetMapTimeLeft(timeleft);
	new Float:ftime = float(timeleft);
	decl String:szTime[32];
	FormatTimeFloat(g_InfoBot,ftime,5,szTime,sizeof(szTime));
	new Handle:hTmp;	
	hTmp = FindConVar("mp_timelimit");
	new iTimeLimit = GetConVarInt(hTmp);			
	if (hTmp != INVALID_HANDLE)
		CloseHandle(hTmp);	
	if (g_bMapEnd && iTimeLimit > 0)
		Format(szBuffer, sizeof(szBuffer), "%s (%s)",sNextMap, szTime);
	else
		Format(szBuffer, sizeof(szBuffer), "Pending Vote (no time limit)");
	CS_SetClientName(g_InfoBot, szBuffer);
	Client_SetScore(g_InfoBot,9999);
	CS_SetClientClanTag(g_InfoBot, "NEXTMAP");
}

public CenterHudDead(client)
{
	decl String:szTick[32];
	Format(szTick, 32, "%i", g_Server_Tickrate);			
	decl ObservedUser 
	ObservedUser = -1;
	decl SpecMode;			
	ObservedUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");	
	SpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");	
	if (SpecMode == 4 || SpecMode == 5)
	{
		g_SpecTarget[client] = ObservedUser;
		decl String:sResult[32];	
		decl Buttons;
		
		if (g_bInfoPanel[client] && IsValidClient(ObservedUser))
		{
			Buttons = g_LastButton[ObservedUser];					
			if (Buttons & IN_MOVELEFT)
				Format(sResult, sizeof(sResult), "<b>Keys</b>: A");
			else
				Format(sResult, sizeof(sResult), "<b>Keys</b>: _");
			if (Buttons & IN_FORWARD)
				Format(sResult, sizeof(sResult), "%s W", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			if (Buttons & IN_BACK)
				Format(sResult, sizeof(sResult), "%s S", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			if (Buttons & IN_MOVERIGHT)
				Format(sResult, sizeof(sResult), "%s D", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	
			if (Buttons & IN_DUCK || ((GetEngineTime() - g_fCrouchButtonLastTimeUsed[ObservedUser]) < 0.05))
				Format(sResult, sizeof(sResult), "%s - C", sResult);
			else
				Format(sResult, sizeof(sResult), "%s - _", sResult);			
			if (Buttons & IN_JUMP || ((GetEngineTime() - g_fJumpButtonLastTimeUsed[ObservedUser]) < 0.05))
				Format(sResult, sizeof(sResult), "%s J", sResult);
			else
				Format(sResult, sizeof(sResult), "%s _", sResult);	

			//infopanel		
			PrintCenterPanelToClient(client,ObservedUser,sResult);				
		}		
	}
	else
		g_SpecTarget[client] = -1;
	
}

public CenterHudAlive(client)
{
	if (!IsValidClient(client))
		return;
	
	//menu check
	if (!g_bTimeractivated[client])
	{
		if (g_bClimbersMenuOpen[client] && !g_bMenuOpen[client])
			ClimbersMenu(client);
		else
			if (g_bClimbersMenuwasOpen[client]  && !g_bMenuOpen[client])
			{
				g_bClimbersMenuwasOpen[client]=false;
				ClimbersMenu(client);	
			}
			else			
				PlayerPanel(client);			
	}
		
	if (g_bInfoPanel[client] && !g_bOverlay[client])
	{
		decl String:sResult[32];	
		decl Buttons;
		Buttons = g_LastButton[client];			
		if (Buttons & IN_MOVELEFT)
			Format(sResult, sizeof(sResult), "<b>Keys</b>: A");
		else
			Format(sResult, sizeof(sResult), "<b>Keys</b>: _");
		if (Buttons & IN_FORWARD)
			Format(sResult, sizeof(sResult), "%s W", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	
		if (Buttons & IN_BACK)
			Format(sResult, sizeof(sResult), "%s S", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	
		if (Buttons & IN_MOVERIGHT)
			Format(sResult, sizeof(sResult), "%s D", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	
		if (Buttons & IN_DUCK || ((GetEngineTime() - g_fCrouchButtonLastTimeUsed[client]) < 0.05))
			Format(sResult, sizeof(sResult), "%s - C", sResult);
		else
			Format(sResult, sizeof(sResult), "%s - _", sResult);			
		if (Buttons & IN_JUMP || ((GetEngineTime() - g_fJumpButtonLastTimeUsed[client]) < 0.05))
			Format(sResult, sizeof(sResult), "%s J", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	

		PrintCenterPanelToClient(client,client,sResult);
	}	
}


public PrintCenterPanelToClient(client,target, String:sKeys[32])
{
	if (!IsValidClient(client))
		return;
	
	decl String:sPreStrafe[128];
	if (g_bJumpStats)
	{		
		if (g_js_bPlayerJumped[target])
		{
			if (!g_bAdvInfoPanel[client])
				PrintHintText(client,"<font color='#948d8d'><b>Last</b>: %s\n<b>Speed</b>: %.1f u/s (%.0f)\n%s</font>",g_js_szLastJumpDistance[target],g_fLastSpeed[target],g_js_fPreStrafe[target],sKeys);	
			else
			{
				//LJ?
				if (!g_bLadderJump[target] && g_js_GroundFrames[target] > 11)
				{
					if (g_js_bPerfJumpOff[target])
					{
						if (g_js_bPerfJumpOff2[target])
							Format(sPreStrafe, sizeof(sPreStrafe), "%.0f, CJ <font color='#21982a'>✔</font> -W <font color='#21982a'>✔</font>", g_js_fPreStrafe[target]);
						else	
							Format(sPreStrafe, sizeof(sPreStrafe), "%.0f, CJ <font color='#21982a'>✔</font> -W <font color='#9a0909'>Х</font>", g_js_fPreStrafe[target]);	
					}
					else
					{
						if (g_js_bPerfJumpOff2[target])
							Format(sPreStrafe, sizeof(sPreStrafe), "%.0f, CJ <font color='#9a0909'>Х</font> -W <font color='#21982a'>✔</font>", g_js_fPreStrafe[target]);
						else
							Format(sPreStrafe, sizeof(sPreStrafe), "%.0f, CJ <font color='#9a0909'>Х</font> -W <font color='#9a0909'>Х</font>", g_js_fPreStrafe[target]);							
					}
					
					PrintHintText(client,"<b>Last</b>: %s\n<b>Speed</b>: %.0f u/s (%s)\n%s",g_js_szLastJumpDistance[target],g_fLastSpeed[target],sPreStrafe,sKeys);
				}
				else
					PrintHintText(client,"<b>Last</b>: %s\n<b>Speed</b>: %.1f u/s (%.0f)\n%s",g_js_szLastJumpDistance[target],g_fLastSpeed[target],g_js_fPreStrafe[target],sKeys);
			}
		}
		else
			PrintHintText(client,"<font color='#948d8d'><b>Last</b>: %s\n<b>Speed</b>: %.1f u/s\n%s</font>",g_js_szLastJumpDistance[target],g_fLastSpeed[target],sKeys);
	}
	else
		PrintHintText(client,"<font color='#948d8d'><b>Speed</b>: %.1f u/s\n<b>Velocity</b>: %.1f u/s\n%s</font>",g_fLastSpeed[target],GetVelocity(target),sKeys);			

}

// https://forums.alliedmods.net/showthread.php?t=178279
//  [ANY] RTLer - Support for Right-to-Left Languages
RTLify(String:dest[1024], String:original[1024])
{
	new rtledWords = 0;

	new String:tokens[96][96]; 
	new String:words[sizeof(tokens)][sizeof(tokens[])];

	new n = ExplodeString(original, " ", tokens, sizeof(tokens), sizeof(tokens[]));
	
	for (new word = 0; word < n; word++)
	{
		if (WordAnalysis(tokens[word]) >= 0.1)
		{
			ReverseString(tokens[word], sizeof(tokens[]), words[n-1-word]);
			rtledWords++;
		}
		else
		{
			new firstWord = word;
			new lastWord = word;
			
			while (WordAnalysis(tokens[lastWord]) < 0.1)
			{
				lastWord++;
			}
			
			for (new t = lastWord - 1; t >= firstWord; t--)
			{
				strcopy(words[n-1-word], sizeof(tokens[]), tokens[t]);
				
				if (t > firstWord)
					word++;
			}
		}
	}
	
	ImplodeStrings(words, n, " ", dest, sizeof(words[]));
	return rtledWords;
}

// https://forums.alliedmods.net/showthread.php?t=178279
//  [ANY] RTLer - Support for Right-to-Left Languages
ReverseString(String:str[], maxlength, String:buffer[])
{
	for (new character = strlen(str); character >= 0; character--)
	{
		if (str[character] >= 0xD6 && str[character] <= 0xDE)
			continue;
		
		if (character > 0 && str[character - 1] >= 0xD7 && str[character - 1] <= 0xD9)
			Format(buffer, maxlength, "%s%c%c", buffer, str[character - 1], str[character]);
		else
			Format(buffer, maxlength, "%s%c", buffer, str[character]);
	}
}

// https://forums.alliedmods.net/showthread.php?t=178279
//  [ANY] RTLer - Support for Right-to-Left Languages
Float:WordAnalysis(String:word[])
{
	new count = 0, length = strlen(word);
	
	for (new n = 0; n < length - 1; n++)
	{
		if (IsRTLCharacter(word, n))
		{	
			count++;
			n++;
		}
	}

	return float(count) * 2 / length;
}

// https://forums.alliedmods.net/showthread.php?t=178279
//  [ANY] RTLer - Support for Right-to-Left Languages
bool:IsRTLCharacter(String:str[], n)
{
	return (str[n] >= 0xD6 && str[n] <= 0xDE && str[n + 1] >= 0x80 && str[n + 1] <= 0xBF);
}


// https://forums.alliedmods.net/showpost.php?p=2308824&postcount=4
// by Mehis
public DoubleDuck(client,&buttons)
{
    if (!IsValidClient(client) || !IsPlayerAlive( client ) || (g_bTimeractivated[client] && !g_bDoubleDuckCvar)) 
		return;
   
    static int fFlags;
    fFlags = GetEntityFlags( client );
    
    if ( fFlags & FL_ONGROUND )
    {
        static bool bAllowDoubleDuck[MAXPLAYERS];
        
        if ( fFlags & FL_DUCKING )
        {
            bAllowDoubleDuck[client] = false;
            return;
        }
        
        if ( buttons & IN_DUCK )
        {
            bAllowDoubleDuck[client] = true;
            return;
        }
        
        if ( GetEntProp( client, Prop_Data, "m_bDucking" ) && bAllowDoubleDuck[client] )
        {
            float vecPos[3];
            GetClientAbsOrigin( client, vecPos );
            vecPos[2] += 40.0; 
            if (IsValidPlayerPos(client, vecPos))
			{
				g_js_GroundFrames[client] = 0;
				DoValidTeleport(client, vecPos,NULL_VECTOR,true);
				g_js_DuckCounter[client]++;
				g_fLastTimeDoubleDucked[client] = GetEngineTime();
			}
        }

    }
}


// https://forums.alliedmods.net/showpost.php?p=2308824&postcount=4
// by Mehis
public bool IsValidPlayerPos( int client, float vecPos[3] )
{
    static const float vecMins[] = { -16.0, -16.0, 0.0 };
    static const float vecMaxs[] = { 16.0, 16.0, 72.0 };
    
    TR_TraceHullFilter( vecPos, vecPos, vecMins, vecMaxs, MASK_SOLID, TraceFilter_IgnorePlayer, client );
    
    return ( !TR_DidHit( null ) );
}

// https://forums.alliedmods.net/showpost.php?p=2308824&postcount=4
// by Mehis
public bool TraceFilter_IgnorePlayer( int ent, int mask, any ignore_me )
{
    return ( ent != ignore_me );
} 

