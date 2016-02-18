#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Replay bot fixer",
	author = "1NutWunDeR",
	description = "Fixes the replay bots on KZTimer",
	version = "1.0",
	url = ""
}

public OnMapStart()
{
	CreateTimer(5.0, ConvarOff);
	CreateTimer(10.0, ConvarOn);
}

public Action:ConvarOff(Handle:timer)
	ServerCommand("kz_replay_bot 0");


public Action:ConvarOn(Handle:timer)
	ServerCommand("kz_replay_bot 1");