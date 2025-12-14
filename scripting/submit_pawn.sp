#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1
#define PLAYER_PAWN_FILE "player_pawn.txt"
char g_playername[MAX_NAME_LENGTH];
char g_playersteamid[256];

ConVar g_triggername;
ConVar g_autokick;
public Plugin myinfo =
{
	name = "submit_pawn",
	author = "TheRedEnemy",
	description = "",
	version = "1.1.0",
	url = "https://github.com/theredenemy/submit_pawn"
};

void clearVars()
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

void makeConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/%s", PLAYER_PAWN_FILE);
	if (!FileExists(path))
	{
		PrintToServer(path);
		KeyValues kv = new KeyValues("Player_Pawn");
		kv.SetString("playername", "SERVICE MANAGER");
		kv.Rewind();
		kv.ExportToFile(path);
		delete kv;
	}
}

public void set_pawn(const char[] player)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/%s", PLAYER_PAWN_FILE);
	KeyValues kv = new KeyValues("Player_Pawn");
	kv.SetString("playername", player);
	kv.Rewind();
	kv.ExportToFile(path);
	delete kv;
}

public void OnPluginStart()
{
	g_triggername = CreateConVar("pawn_trigger", "\0");
	g_autokick = CreateConVar("pawn_autokick", "0");
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
	RegServerCmd("pawn_submit", pawn_submit_cmd);
	RegServerCmd("pawn_check", pawn_check_cmd);
	makeConfig();
	PrintToServer("Submit_Pawn Has Loaded");
}

public void OnTriggerHurt(const char[] output, int caller, int activator, float delay)
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
	HookEntityOutput("trigger_hurt", "OnHurtPlayer", OnTriggerHurt);
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
	
	set_pawn(g_playername);
	SendData(g_playername, triggername);

	return Plugin_Handled;
}
public Action pawn_check_cmd(int args)
{
	char playername[MAX_NAME_LENGTH];
	char path[PLATFORM_MAX_PATH];
	char reason[256] = "YOU ARE IN THE MACHINE NOW";
	int autokick = GetConVarInt(g_autokick);
	char pawn_name[MAX_NAME_LENGTH];
	if (autokick != 1)
	{
		PrintToServer("autokick off");
		return Plugin_Handled;
	}
	BuildPath(Path_SM, path, sizeof(path), "configs/%s", PLAYER_PAWN_FILE);
	KeyValues kv = new KeyValues("Player_Pawn");

	if (!kv.ImportFromFile(path))
	{
		PrintToServer("NO FILE");
		delete kv;
		return Plugin_Handled;
	}

	if (kv.JumpToKey("playername", false))
	{
		kv.GetString(NULL_STRING, pawn_name, sizeof(pawn_name));
		delete kv;
	}
	PrintToServer(pawn_name);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, playername, sizeof(playername));
			PrintToServer(playername);
			if (StrEqual(playername, pawn_name))
			{
				KickClient(i, reason);
			}
		}
	}
	return Plugin_Handled;

}