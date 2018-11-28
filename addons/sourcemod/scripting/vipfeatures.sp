#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <scp>

#pragma newdecls required

//Definitions
#define VIP ADMFLAG_RESERVATION  //flag "a"
#define Prefix "\x4 \x6[SM] \x7";
#define MAXLENGTH_NAME 32

//ConVars
ConVar g_cvTag;

public Plugin myinfo =
{
	name = "[CS:GO] VIP Features",
	author = "Javierko",
	description = "VIP Plugin - Features for VIP",
	version = "1.1.0",
	url = "http://github.com/javierko"
}

public void OnPluginStart() 
{
	//Commands
	RegConsoleCmd("sm_rs", Cmd_ResetScore, "Reset score");
	
	//Events
	HookEvent("round_start", Event_RoundStartPre, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	//ConVars
	g_cvTag = CreateConVar("sm_vipf_chattag", "0", "1 - Chat tag is enabled, 0 - chat tag is disabled", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "j_VipFeatures");
}

/*
    > Connect <
*/

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, SDKEvent_OnTakeDamage);
	}
}

/*
	> Events <
*/

public void Event_RoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("sm_reloadadmins");
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		PerformGravity(client);
		SetClientSpeed(client);
		HandleTag(client);
		
		if(IsClientVIP(client))
		{
			int iHealth = 110;
			SetEntityHealth(client, iHealth);
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
		}
		else
		{
			int iHealth = 100;
			SetEntityHealth(client, iHealth);
			SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1 );
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (attacker != victim) 
	{
		if(IsValidClient(attacker))
		{
			if(IsClientVIP(attacker)) 
	    	{
				int iHealth[MAXPLAYERS+1];
	 			iHealth[attacker] = GetEntProp(attacker, Prop_Send, "m_iHealth");
				SetEntityHealth(attacker, iHealth[attacker] + 5);
			}
		}
	}
}

/*
	> SDK <
*/

public Action SDKEvent_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(IsValidClient(attacker))
	{
		if (IsClientVIP(attacker)) 
		{
			damage *= 1.2;
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

/*
	> Chat <
*/

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message)
{
	if(g_cvTag.BoolValue)
	{
		if(IsValidClient(author))
		{
			if(IsClientVIP(author))
			{
				Format(name, MAXLENGTH_NAME, "\x02[VIP] \x03%s", name);
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

/*
	> Commands <
*/

public Action Cmd_ResetScore(int client, int args) 
{
	if(IsValidClient(client))
	{
	 	if(IsClientVIP(client)) 
	  	{
			EditScore(client);
			PrintToChat(client, "You reseted your score.");
		}
	}
	
	return Plugin_Handled;
}

/*
	> Voids <
*/

void EditScore(int client) 
{
	SetEntProp(client, Prop_Data, "m_iFrags", 0);
	SetEntProp(client, Prop_Data, "m_iDeaths", 0);
	CS_SetMVPCount(client, 0);
	CS_SetClientAssists(client, 0);
	CS_SetClientContributionScore(client, 0);
}

void SetClientSpeed(int client) 
{
	if(IsValidClient(client))
	{
		if(IsClientVIP(client)) 
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.1);
		}
		else if(!IsClientVIP(client)) 
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		}
	}		
}

void PerformGravity(int client) 
{
	if(IsValidClient(client))
	{
	 	if(IsClientVIP(client)) 
		{
			SetEntityGravity(client, 0.9);
		}
		else if(!IsClientVIP(client)) 
		{
			SetEntityGravity(client, 1.0);
		}
	}
}

void HandleTag(int client) 
{
	if(IsValidClient(client))
	{
		if(IsClientVIP(client)) 
		{
	  		CS_SetClientClanTag(client, "[VIP]");
		}
	}
}

/*
	> Booleans <
*/

stock bool IsValidClient(int client, bool alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}

stock bool IsClientVIP(int client) 
{
	if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation)) 
	{
		return true;
	}
	return false;
}