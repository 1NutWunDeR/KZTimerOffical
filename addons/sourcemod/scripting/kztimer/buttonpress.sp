// buttonpress.sp
public ButtonPress(const String:name[], caller, activator, Float:delay)
{
	if(!IsValidEntity(caller) || !IsValidClient(activator))
		return;		
	g_bLJBlock[activator] = false;
	decl String:targetname[128];
	GetEdictClassname(activator,targetname, sizeof(targetname));
	if(!StrEqual(targetname,"player"))
		return;
	GetEntPropString(caller, Prop_Data, "m_iName", targetname, sizeof(targetname));
	if(StrEqual(targetname,"climb_startbutton"))
	{
		g_bLegitButtons[activator] = true;
		Call_StartForward(hStartPress);
		Call_PushCell(activator);
		Call_Finish();
	} 
	else if(StrEqual(targetname,"climb_endbutton")) 
	{
		Call_StartForward(hEndPress);
		Call_PushCell(activator);
		Call_Finish();
	}
}

// - builded Climb buttons -
public OnUsePost(entity, activator, caller, UseType:type, Float:value)
{
	if(!IsValidEntity(entity) || !IsValidClient(activator))
		return;	
	decl String:targetname[128];
	GetEdictClassname(activator,targetname, sizeof(targetname));
	if(!StrEqual(targetname,"player"))
		return;
	GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
	new Float: speed = GetSpeed(activator);
	if(StrEqual(targetname,"climb_startbuttonx") && speed < 251.0)
	{		
		g_bLegitButtons[activator] = false;
		Call_StartForward(hStartPress);
		Call_PushCell(activator);
		Call_Finish();
	} 
	else if(StrEqual(targetname,"climb_endbuttonx")) 
	{
		g_bLegitButtons[activator] = false;
		Call_StartForward(hEndPress);
		Call_PushCell(activator);
		Call_Finish();
	}
}  

// - Climb Button OnStartPress -
public CL_OnStartTimerPress(client)
{	
	if (!IsFakeClient(client))
	{	
		if (g_bNewReplay[client] || g_bSaving[client])
			return;
		if (!(g_bOnGround[client]) && g_bLegitButtons[client])
			return;	
	
		//timer pos
		if (g_bFirstStartButtonPush)
		{
			GetClientAbsOrigin(client,g_fStartButtonPos);
			g_bFirstStartButtonPush=false;
		}	

		if (!IsPlayerAlive(client) || GetClientTeam(client) == 1)
		{
			if(g_hRecording[client] != INVALID_HANDLE)
				StopRecording(client);
		}
		else
		{	
			if(g_hRecording[client] != INVALID_HANDLE)
				StopRecording(client);
			StartRecording(client);
		}		
	}
	
	//noclip check
	new Float:time;
	time = GetEngineTime() - g_fLastTimeNoClipUsed[client];
			
	if ((!g_bSpectate[client] && !g_bNoClip[client] && time > 2.0) || IsFakeClient(client))
	{	
	
		g_fPlayerCordsUndoTp[client][0] = 0.0;
		g_fPlayerCordsUndoTp[client][1] = 0.0;
		g_fPlayerCordsUndoTp[client][2] = 0.0;		
		g_CurrentCp[client] = -1;
		g_CounterCp[client] = 0;	
		g_OverallCp[client] = 0;
		g_OverallTp[client] = 0;
		g_fPauseTime[client] = 0.0;
		g_JumpCheck2[client] = 0;
		g_JumpCheck1[client] = 0;
		g_fStartPauseTime[client] = 0.0;
		g_bRespawnAtTimer[client] = true;
		g_bPause[client] = false;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderMode(client, RENDER_NORMAL);
		g_fStartTime[client] = GetEngineTime();	
		g_bMenuOpen[client] = false;		
		g_bTopMenuOpen[client] = false;	
		g_bPositionRestored[client] = false;
		g_bMissedTpBest[client] = true;
		g_bMissedProBest[client] = true;
		new bool: act = g_bTimeractivated[client];
		g_bTimeractivated[client] = true;		
		decl String:szTime[32];
		
		//valid players
		if (!IsFakeClient(client))
		{	
			//Get start position
			GetClientAbsOrigin(client, g_fPlayerCordsRestart[client]);
			GetClientEyeAngles(client, g_fPlayerAnglesRestart[client]);		

			//star message
			decl String:szTpTime[32];
			decl String:szProTime[32];
			if (g_fPersonalRecord[client]<=0.0)
			{
				Format(szTpTime, 32, "NONE");
			}
			else
			{
				g_bMissedTpBest[client] = false;
				FormatTimeFloat(client, g_fPersonalRecord[client], 3, szTime, sizeof(szTime));
				Format(szTpTime, 32, "%s (#%i/%i)", szTime,g_MapRankTp[client],g_MapTimesCountTp);
			}
			if (g_fPersonalRecordPro[client]<=0.0)
					Format(szProTime, 32, "NONE");
			else
			{
				g_bMissedProBest[client] = false;
				FormatTimeFloat(client, g_fPersonalRecordPro[client], 3, szTime, sizeof(szTime));
				Format(szProTime, 32, "%s (#%i/%i)", szTime,g_MapRankPro[client],g_MapTimesCountPro);
			}
			g_bOverlay[client]=true;
			g_fLastOverlay[client] = GetEngineTime()-2.5;
			if (act)
				PrintHintText(client,"%t", "TimerStarted1", szProTime,szTpTime);
			else
				PrintHintText(client,"%t", "TimerStarted2", szProTime,szTpTime);		

			if (g_bFirstButtonTouch[client])
			{
				g_bFirstButtonTouch[client]=false;
				Client_Avg(client, 0);
			}
		}	
	}
	
	//sound
	PlayButtonSound(client);	
}

// - Climb Button OnEndPress -
public CL_OnEndTimerPress(client)
{	
	//Format Final Time
	if (IsFakeClient(client) && g_bTimeractivated[client])
	{
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
						if (Target == g_TpBot)
							PrintToChat(i, "%t", "ReplayFinishingMsg", MOSSGREEN,WHITE,LIMEGREEN,g_szReplayNameTp,GRAY,LIMEGREEN,g_szReplayTimeTp,GRAY);
						else
						if (Target == g_ProBot)
							PrintToChat(i, "%t", "ReplayFinishingMsg", MOSSGREEN,WHITE,LIMEGREEN,g_szReplayName,GRAY,LIMEGREEN,g_szReplayTime,GRAY);
					}
				}					
			}		
		}	
		PlayButtonSound(client);
		g_bTimeractivated[client] = false;	
		return;
	}
	if (!g_bTimeractivated[client]) 
		return;	
			
	//Final time
	g_fFinalTime[client] = GetEngineTime() - g_fStartTime[client] - g_fPauseTime[client];			
	g_Tp_Final[client] = g_OverallTp[client];	
	g_bTimeractivated[client] = false;

	//timer pos
	if (g_bFirstEndButtonPush && !IsFakeClient(client))
	{
		GetClientAbsOrigin(client,g_fEndButtonPos);
		g_bFirstEndButtonPush=false;
	}				
	
	//slay others
	if (!IsFakeClient(client) && g_bSlayPlayers)
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if (IsValidClient(client) && i != client)
				ForcePlayerSuicide(i);
		}	
	}
	
	//button sound
	PlayButtonSound(client);	
	
	//decl
	new String:szName[MAX_NAME_LENGTH];	
	new String:szNameOpponent[MAX_NAME_LENGTH];	
	new String:szTime[32];
	new bool:hasRecord=false;
	new Float: difference;
	new String:mapname[128];
	Format(mapname, 128, "%s", g_szMapName);	
	
	//g_bSaving[client] = true;
	g_FinishingType[client] = -1;
	g_Sound_Type[client] = -1;
	g_bMapRankToChat[client] = true;
	if (!IsValidClient(client))
		return;	
	GetClientName(client, szName, MAX_NAME_LENGTH);	
	FormatTimeFloat(client, g_fFinalTime[client], 3, szTime, sizeof(szTime));
	Format(g_szFinalTime[client], 32, "%s", szTime);
	g_bOverlay[client]=true;
	g_fLastOverlay[client] = GetEngineTime();
	PrintHintText(client,"%t", "TimerStopped", g_szFinalTime[client]);
	
	//calc difference
	if (g_Tp_Final[client]==0)
	{
		if (g_fPersonalRecordPro[client] > 0.0)
		{
			hasRecord=true;
			difference = g_fPersonalRecordPro[client] - g_fFinalTime[client];
			FormatTimeFloat(client, difference, 3, szTime, sizeof(szTime));
		}
		else
		{
			g_pr_finishedmaps_pro[client]++;
		}
		
	}
	else
	{
		if (g_fPersonalRecord[client] > 0.0 && g_Tp_Final[client] > 0)
		{		
			hasRecord=true;
			difference = g_fPersonalRecord[client]-g_fFinalTime[client];
			FormatTimeFloat(client, difference, 3,szTime,sizeof(szTime));
		}	
		else
		{
			g_pr_finishedmaps_tp[client]++;
		}
	}
	new bool: newbest;
	if (hasRecord)
	{
		if (difference > 0.0)
		{
			if (g_ExtraPoints > 0)
				g_pr_multiplier[client]+=1;
			Format(g_szTimeDifference[client], 32, "-%s", szTime);
			newbest=true;
		}
		else
			Format(g_szTimeDifference[client], 32, "+%s", szTime);
	}
	
	//Type of time
	if (!hasRecord)
	{
		if (g_Tp_Final[client]>0)
		{
			g_Time_Type[client] = 0;
			g_MapTimesCountTp++;
		}
		else
		{
			g_Time_Type[client] = 1;
			g_MapTimesCountPro++;
		}
	}
	else
	{
		if (difference> 0.0)
		{
			if (g_Tp_Final[client]>0)
				g_Time_Type[client] = 2;
			else
				g_Time_Type[client] = 3;
		}
		else
		{
			if (g_Tp_Final[client]>0)
				g_Time_Type[client] = 4;
			else
				g_Time_Type[client] = 5;
		}
	}

	//NEW PRO RECORD
	if((g_fFinalTime[client] < g_fRecordTimePro) && g_Tp_Final[client] <= 0)
	{
		if (g_FinishingType[client] != 3 && g_FinishingType[client] != 4 && g_FinishingType[client] != 5)
			g_FinishingType[client] = 2;
		g_fRecordTimePro = g_fFinalTime[client]; 
		Format(g_szRecordPlayerPro, MAX_NAME_LENGTH, "%s", szName);
		if (g_Sound_Type[client] != 1)
			g_Sound_Type[client] = 2;
			
		//save replay	
		if (g_bReplayBot && !g_bPositionRestored[client])
		{
			g_bNewReplay[client]=true;
			CreateTimer(3.0, ProReplayTimer, client,TIMER_FLAG_NO_MAPCHANGE);
		}
		db_InsertLatestRecords(g_szSteamID[client], szName, g_fFinalTime[client], g_Tp_Final[client]);	
	} 
	
	//NEW TP RECORD
	if((g_fFinalTime[client] < g_fRecordTime) && g_Tp_Final[client] > 0)
	{
		if (g_FinishingType[client] != 3 && g_FinishingType[client] != 4 && g_FinishingType[client] != 5)
			g_FinishingType[client] = 1;
		g_fRecordTime = g_fFinalTime[client];
		Format(g_szRecordPlayer, MAX_NAME_LENGTH, "%s", szName);
		if (g_Sound_Type[client] != 1)
			g_Sound_Type[client] = 3;
		//save replay	
		if (g_bReplayBot && !g_bPositionRestored[client])
		{
			g_bNewReplay[client]=true;
			CreateTimer(3.0, TpReplayTimer, client,TIMER_FLAG_NO_MAPCHANGE);
		}
		db_InsertLatestRecords(g_szSteamID[client], szName, g_fFinalTime[client], g_Tp_Final[client]);	
	}
		
	if (newbest && g_Sound_Type[client] == -1)
		g_Sound_Type[client] = 5;
		
	//Challenge
	if (g_bChallenge[client])
	{
		SetEntityRenderColor(client, 255,255,255,255);		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != client && i != g_ProBot && i != g_TpBot)
			{				
				if (StrEqual(g_szSteamID[i],g_szChallenge_OpponentID[client]))
				{	
					g_bChallenge[client]=false;
					g_bChallenge[i]=false;
					SetEntityRenderColor(i, 255,255,255,255);
					db_insertPlayerChallenge(client);
					GetClientName(i, szNameOpponent, MAX_NAME_LENGTH);	
					for (new k = 1; k <= MaxClients; k++)
						if (IsValidClient(k))
							PrintToChat(k, "%t", "ChallengeW", RED,WHITE,MOSSGREEN,szName,WHITE,MOSSGREEN,szNameOpponent,WHITE); 			
					if (g_Challenge_Bet[client]>0)
					{										
						new lostpoints = g_Challenge_Bet[client] * g_pr_PointUnit;
						for (new j = 1; j <= MaxClients; j++)
							if (IsValidClient(j))
								PrintToChat(j, "%t", "ChallengeL", MOSSGREEN, WHITE, PURPLE,szNameOpponent, GRAY, RED, lostpoints,GRAY);		
						CreateTimer(0.5, UpdatePlayerProfile, i,TIMER_FLAG_NO_MAPCHANGE);
						g_pr_showmsg[client] = true;
					}					
					break;
				}
			}
		}		
	}
	
	//set mvp star
	g_MVPStars[client] += 1;
	CS_SetMVPCount(client,g_MVPStars[client]);		
	
	//local db update
	if ((g_fFinalTime[client] < g_fPersonalRecord[client] && g_Tp_Final[client] > 0 || g_fPersonalRecord[client] <= 0.0 && g_Tp_Final[client] > 0) || (g_fFinalTime[client] < g_fPersonalRecordPro[client] && g_Tp_Final[client] == 0 || g_fPersonalRecordPro[client] <= 0.0 && g_Tp_Final[client] == 0))
	{
		g_pr_showmsg[client] = true;
		db_selectRecord(client, mapname);
	}
	else
	{
		if (g_Tp_Final[client] > 0)
			db_viewMapRankTp(client);
		else
			db_viewMapRankPro(client);
	}
	
	//delete tmp
	db_deleteTmp(client);
}