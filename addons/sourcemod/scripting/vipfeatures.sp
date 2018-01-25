#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define VIP ADMFLAG_RESERVATION  //flag "a"
#define Prefix "\x4 \x6[SM] \x7";

public Plugin myinfo =
{
  name = "[CS:GO] VIP Features",
  author = "Javierko",
  description = "VIP Plugin - Features for VIP",
  version = "1.2 (Beta)",
  url = "github.com/Javierko"
}

public void OnPluginStart() 
{
  RegConsoleCmd("sm_rs", resetscore, "Reset score");
  HookEvent("round_start", round_start, EventHookMode_Pre);
  HookEvent("player_spawn", pspawn, EventHookMode_Pre);
  HookEvent("player_death", pdeath, EventHookMode_Pre);
}


public void OnClientPutInServer(int client) 
{
	if (IsValidClient(client)) 
  {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action round_start(Handle event, const char[] name, bool dontBroadcast) 
{
  ServerCommand("sm_reloadadmins");
}

public Action pspawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	PerformGravity(client);
	SetClientSpeed(client);
	HandleTag(client);
	if (IsClientVIP(client)) 
  {
		int health = 110;      //VIP Player
		SetEntityHealth(client, health);
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1 );
	}
 	else if (!IsClientVIP(client)) 
  {
		int health = 100;    //Normall player
		SetEntityHealth(client, health);
		SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1 );
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (IsClientVIP(attacker)) 
  {
		damage *= 1.2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action pdeath(Handle event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker != victim) 
  {
		if (IsClientVIP(attacker)) 
    {
			int health[MAXPLAYERS+1];
 			health[attacker] = GetEntProp(attacker, Prop_Send, "m_iHealth");
			SetEntityHealth(attacker, health[attacker] + 5);
		}
  }
}

public Action resetscore(int client, int args) 
{
 	if (IsClientVIP(client)) 
  {
		EditScore(client);
		PrintToChat(client, "You restarted your score.");  //Here you can change your message when VIP player write /rs
	}
	return Plugin_Handled;
}

void EditScore(int client) 
{
  SetEntProp(client, Prop_Data, "m_iFrags", 0);
  SetEntProp(client, Prop_Data, "m_iDeaths", 0);
}

public void SetClientSpeed(int client) 
{
	if (IsClientVIP(client)) 
  {
   	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.1); //VIP Player
	}
	else if (!IsClientVIP(client)) 
  {
   	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0); //Normal Player
  }
}

void PerformGravity(int client) 
{
 	if (IsClientVIP(client)) 
   {
    SetEntityGravity(client, 0.9);  //VIP Player
  }
 	else if (!IsClientVIP(client)) 
   {
    SetEntityGravity(client, 1.0); //Normal Player
  }
}

void HandleTag(int client) 
{
	if (IsClientVIP(client)) 
  {
  	CS_SetClientClanTag(client, "[VIP]");
  }
}

stock bool IsValidClient(int client) 
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) 
  {
		return false;
	}
	return true;
}

stock bool IsClientVIP(int client) 
{
	if (GetAdminFlag(GetUserAdmin(client), Admin_Reservation)) 
  {
		return true;
	}
	return false;
}