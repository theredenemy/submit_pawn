#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1
char g_playername[MAX_NAME_LENGTH];
char g_playersteamid[256];

ConVar g_triggername;
public Plugin myinfo =
{
	name = "submit_pawn",
	author = "TheRedEnemy",
	description = "",
	version = "1.0.2",
	url = "https://github.com/theredenemy/submit_pawn"
};

public void clearVars()
{
	g_playername = "\0";
	SetConVarString(g_triggername, "\0");
	PrintToServer("Vars Cleared");
}

public void SendData(const char[] player, const char[] trigger)
{
	// PlaceHolder code
	PrintHintTextToAll("Player : %s Trigger : %s", player, trigger);
}

public void OnPluginStart()
{
	g_triggername = CreateConVar("pawn_trigger", "\0");
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
	RegServerCmd("pawn_submit", pawn_submit_cmd);
	PrintToServer("Submit_Pawn Has Loaded");
}


public void OnTrigger(const char[] output, int caller, int activator, float delay)
{
	if (activator >= 1 && activator <= MaxClients && IsClientInGame(activator))
	{
		char callerClass[64];
		GetEntityClassname(caller, callerClass, sizeof(callerClass)); 
		GetClientName(activator, g_playername, sizeof(g_playername));
		GetClientAuthId(activator, AuthId_Steam2, g_playersteamid, sizeof(g_playersteamid));
		PrintToServer("Player %s With SteamID %s Has Hit A %s", g_playername, g_playersteamid, callerClass);


	}
}

public void OnMapStart()
{
	clearVars();
	HookEntityOutput("trigger_hurt", "OnHurtPlayer", OnTrigger);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	clearVars();
	return Plugin_Continue;
}

public Action pawn_submit_cmd(int args)
{
	char arg[256];
    char full[256];
	char cmd[256];
	char triggername[256];
	int cmd_len;
	if (args < 1)
	{
		PrintToServer("[SM] Usage: pawn_submit '<cmd>' '<arg>'");
		return Plugin_Handled;
	}
	GetCmdArgString(full, sizeof(full));
	for (int i = 1; i <= args; i++)
	{
		
		GetCmdArg(i, arg, sizeof(arg));
		cmd_len = strlen(cmd);
		if (cmd_len > 0)
		{
			StrCat(cmd, sizeof(cmd), " ");
		}
		
		
		ReplaceString(arg, sizeof(arg), "(name)", g_playername);
		ReplaceString(arg, sizeof(arg), "(steamid)", g_playersteamid);
		

		StrCat(cmd, sizeof(cmd), arg);
	}
	ServerCommand("%s", cmd);
	g_triggername.GetString(triggername, sizeof(triggername));
	SendData(g_playername, triggername);

	return Plugin_Handled;
}