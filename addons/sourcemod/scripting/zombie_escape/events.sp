/**
 * Copyright (C) 2023 Batfoxkid
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 * 
**/

#pragma semicolon 1
#pragma newdecls required

void Events_PluginStart()
{
	HookEvent("player_death", Events_PlayerDeath, EventHookMode_Post);
	HookEvent("player_healed", Events_PlayerHealed, EventHookMode_Post);
	HookEvent("player_hurt", Events_PlayerHurt, EventHookMode_Pre);
	HookEvent("post_inventory_application", Events_InventoryApplication, EventHookMode_Pre);
	HookEvent("teamplay_broadcast_audio", Events_BroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_round_win", Events_RoundEnd, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", Events_RoundStart, EventHookMode_Post);
}

public void Events_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	if(victim)
	{
		Map_PlayerDeath(victim);
		
		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			Client(victim).ResetByDeath();
			Gamemode_PlayerDeath(victim, userid, GetClientOfUserId(event.GetInt("attacker")));
		}
	}
}

public void Events_PlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	int patient = event.GetInt("patient");
	if(patient > 0 && patient <= MaxClients && IsClientInGame(patient))
		Gamemode_TakeDamage(patient, float(-event.GetInt("amount")), DMG_CRIT);
}

public Action Events_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	if(victim && Client(victim).Zombie && Cvar[ZombieHealth].IntValue < 1)
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		if(attacker > 0 && attacker <= MaxClients)
		{
			SetEntityHealth(victim, 9999);
			event.SetInt("health", 9999);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action Events_InventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		Gamemode_InventoryApplication(client, userid);
	}
	return Plugin_Continue;
}

public Action Events_BroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	char sound[64];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public void Events_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundEnd();
	Music_RoundEnd(event.GetInt("team"), event.GetBool("full_round"));
}

public void Events_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundStart();
}