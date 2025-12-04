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

#define SKIN_ZOMBIE		4
#define SKIN_ZOMBIE_SPY	SKIN_ZOMBIE + 18

static Handle GameHud;
static Handle PlayerHud;
static bool LastMann;
static bool InRespawn;

static Handle CrippleTimer[MAXTF2PLAYERS];

void Gamemode_PluginStart()
{
	GameHud = CreateHudSynchronizer();
	PlayerHud = CreateHudSynchronizer();
}

void Gamemode_RoundSetup()
{
	Debug("Gamemode_RoundSetup");

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
		{
			Client(client).ResetByRound();
			
			ClearSyncHud(client, GameHud);
			ClearSyncHud(client, PlayerHud);

			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, TFTeam_Human);
			SetEntProp(client, Prop_Send, "m_lifeState", 0);

			TF2_RespawnPlayer(client);
		}
	}

	Map_RoundSetup();
	Music_RoundSetup();
}

void Gamemode_RoundStart()
{
	Debug("Gamemode_RoundStart");

	LastMann = false;
	
	int[] player = new int[MaxClients];
	int players;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) > TFTeam_Spectator)
		{
			player[players++] = client;
		}
	}
	
	if(players > 2)
	{
		SortIntegers(player, players, Sort_Random);

		int zombies = RoundFloat(players * Cvar[ZombieRatio].FloatValue);
		if(!zombies)
			zombies = 1;
		
		float stun = Cvar[ZombieStunStart].FloatValue;
		
		int i;
		for(; i < zombies; i++)
		{
			if(!IsPlayerAlive(player[i]))
				TF2_RespawnPlayer(player[i]);
			
			TF2_RemovePlayerDisguise(player[i]);
			SDKCall_ChangeClientTeam(player[i], TFTeam_Zombie);
			TF2_RegeneratePlayer(player[i]);
			if(stun > 0.0)
			{
				TF2_StunPlayer(player[i], stun, 1.0, TF_STUNFLAGS_NORMALBONK);
				TF2_AddCondition(player[i], TFCond_UberchargedCanteen, stun);
			}
		}

		for(; i < players; i++)
		{
			if(GetClientTeam(player[i]) != TFTeam_Human)
			{
				SDKCall_ChangeClientTeam(player[i], TFTeam_Human);
				TF2_RespawnPlayer(player[i]);
			}
			else if(!IsPlayerAlive(player[i]))
			{
				TF2_RespawnPlayer(player[i]);
			}
		}
	}

	int entity = -1;
	while((entity = FindEntityByClassname(entity, "func_respawnroom")) != -1)
	{
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == TFTeam_Human)
			RemoveEntity(entity);
	}

	entity = -1;
	while((entity = FindEntityByClassname(entity, "func_regenerate")) != -1)
	{
		AcceptEntityInput(entity, "Disable");
	}
}

void Gamemode_RoundEnd()
{
	LastMann = false;
}

void Gamemode_InventoryApplication(int client, int userid)
{
	if(Client(client).PendingStrip)
	{
		Client(client).PendingStrip = false;
		TF2_RemoveAllItems(client);

		int i, entity;
		while(TF2_GetWearable(client, entity, i))
		{
			TF2_RemoveWearable(client, entity);
		}

		TF2_RegeneratePlayer(client);
		return;
	}

	Client(client).PendingStrip = true;

	if(Client(client).Zombie)
	{
		bool clean = (SDKHook_GetEdictCount() > (MAXENTITIES - 300));	// Reduce cosmetic count
		bool hasVoodoo;

		int i, entity;
		while(TF2_GetWearable(client, entity, i))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:
				{
					// Action slot items
				}
				case 131, 133, 405, 406, 444, 608, 1099, 1144:
				{
					// Wearable weapons
				}
				case 5617, 5618, 5619, 5620, 5621, 5622, 5623, 5624, 5625:
				{
					// Voo-doo cosmetics
					hasVoodoo = true;
				}
				default:
				{
					// Wearable cosmetics
					if(clean)
						TF2_RemoveWearable(client, entity);
				}
			}
		}

		TFClassType class = TF2_GetPlayerClass(client);
		
		if(!hasVoodoo)
		{
			static const int VoodooIndex[] =  {-1, 5617, 5625, 5618, 5620, 5622, 5619, 5624, 5623, 5621};
			if(class > TFClass_Unknown && class < view_as<TFClassType>(sizeof(VoodooIndex)))
			{
				entity = CreateEntityByName("tf_wearable");
				if(entity != -1)
				{
					SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", VoodooIndex[class]);
					SetEntProp(entity, Prop_Send, "m_bInitialized", true);
					SetEntProp(entity, Prop_Send, "m_iEntityQuality", 0);
					SetEntProp(entity, Prop_Send, "m_iEntityLevel", 1);
					
					DispatchSpawn(entity);

					SDKCall_EquipWearable(client, entity);
					SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
					SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
				}
			}
		}

		SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", true);
	}
	else
	{
		int i, entity;
		while(TF2_GetWearable(client, entity, i))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:
				{
					// Action slot items
				}
				case 131, 133, 405, 406, 444, 608, 1099, 1144:
				{
					// Wearable weapons
				}
				case 5617, 5618, 5619, 5620, 5621, 5622, 5623, 5624, 5625:
				{
					// Voo-doo cosmetics
					TF2_RemoveWearable(client, entity);
				}
				default:
				{
					// Wearable cosmetics
				}
			}
		}

		SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", 0);
	}

	CreateTimer(0.1, Timer_RestoreHealth, userid, TIMER_FLAG_NO_MAPCHANGE);

	if(!Client(client).NoChanges && GetClientMenu(client) == MenuSource_None)
		Weapons_ChangeMenu(client, 30);
}

public Action Timer_RestoreHealth(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsPlayerAlive(client))
	{
		if(!Client(client).Zombie || Cvar[ZombieHealth].IntValue > 0)
			SetEntityHealth(client, SDKCall_GetMaxHealth(client));
	}
	
	return Plugin_Continue;
}

void Gamemode_PlayerDeath(int client, int userid, int attacker)
{
	Debug("Gamemode_PlayerDeath::%N::%d", client, attacker);

	if(Client(client).Human && GameRules_GetRoundState() == RoundState_RoundRunning && !GameRules_GetProp("m_bInSetup"))
	{
		Debug("IsHuman & Not In Setup");

		if(!LastMann)
		{
			if(attacker > 0 && attacker <= MaxClients && Client(attacker).Zombie)
			{
				float pos[3], ang[3];
				GetClientAbsOrigin(client, pos);
				GetClientEyeAngles(client, ang);

				// Respawn as the class you died as
				SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetPlayerClass(client));

				DataPack pack = new DataPack();
				RequestFrame(Gamemode_PlayerDeathFrame, pack);
				pack.WriteCell(userid);
				
				for(int i; i < 3; i++)
				{
					pack.WriteFloat(pos[i]);
					pack.WriteFloat(ang[i]);
				}
			}

			ChangeClientTeam(client, TFTeam_Zombie);
		}

		Music_PlayerDeath(client);
		Gamemode_ClientDisconnect(client);
	}
}

public void Gamemode_PlayerDeathFrame(DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		float pos[3], ang[3];
		for(int i; i < 3; i++)
		{
			pos[i] = pack.ReadFloat();
			ang[i] = pack.ReadFloat();
		}

		int entity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(entity))
			AcceptEntityInput(entity, "Kill");
		
		InRespawn = true;
		TF2_RespawnPlayer(client);
		InRespawn = false;

		TeleportEntity(client, pos, ang, NULL_VECTOR);
		TF2_StunPlayer(client, Cvar[ZombieStunSpawn].FloatValue, 1.0, TF_STUNFLAGS_NORMALBONK);
	}

	delete pack;
}

void Gamemode_PlayerTeam(int client)
{
	Gamemode_ClientDisconnect(client);
}

void Gamemode_ClientDisconnect(int client)
{
	if(FindEntityByClassname(-1, "tf_gamerules") != -1 && GameRules_GetRoundState() == RoundState_RoundRunning && !GameRules_GetProp("m_bInSetup"))
	{
		int found;

		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && IsClientInGame(target) && Client(target).Human && IsPlayerAlive(target))
			{
				if(found)
					return;
				
				found = target;
			}
		}

		if(found)
		{
			if(!LastMann)
			{
				LastMann = true;
				SetEntityHealth(found, GetClientHealth(found) + 585);
				TF2_AddCondition(found, TFCond_Buffed);
				TF2_AddCondition(found, TFCond_UberchargedCanteen, 2.0);
				Music_ForceNextSong();
			}
		}
		else
		{
			int entity = CreateEntityByName("game_round_win");
			DispatchKeyValue(entity, "force_map_reset", "1");
			DispatchSpawn(entity);
			
			SetVariantInt(TFTeam_Zombie);
			AcceptEntityInput(entity, "SetTeam");
			AcceptEntityInput(entity, "RoundWin");
		}
	}
}

bool Gamemode_ForceRespawn(int client)
{
	Debug("Gamemode_ForceRespawn::%d", InRespawn);

	if(!InRespawn && GetClientTeam(client) == TFTeam_Zombie && !IsPlayerAlive(client))
	{
		float pos[3], ang[3];

		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if(target > 0 && target <= MaxClients && GetClientTeam(target) == TFTeam_Zombie && IsPlayerAlive(target) && Client(target).Cripple < 1.0)
		{
			GetClientAbsOrigin(target, pos);
			GetClientEyeAngles(target, ang);
		}

		if(!pos[0])
		{
			for(target = 1; target <= MaxClients; target++)
			{
				if(client != target && IsClientInGame(target) && GetClientTeam(target) == TFTeam_Zombie && IsPlayerAlive(target))
				{
					if(Client(target).Cripple < 1.0)
					{
						GetClientAbsOrigin(target, pos);
						GetClientEyeAngles(target, ang);
						break;
					}

					ang[0] = 1.0;	// We have someone alive, prevent spawning at spawn points
				}
			}
		}

		if(!pos[0])
		{
			PrintCenterText(client, "No safe spawn location...");
			return view_as<bool>(ang[0]);
		}
		
		DataPack pack = new DataPack();
		RequestFrame(Gamemode_SpawnFrame, pack);
		pack.WriteCell(GetClientUserId(client));
		
		for(int i; i < 3; i++)
		{
			pack.WriteFloat(pos[i]);
			pack.WriteFloat(ang[i]);
		}
	}
	return false;
}

public void Gamemode_SpawnFrame(DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		float pos[3], ang[3];
		for(int i; i < 3; i++)
		{
			pos[i] = pack.ReadFloat();
			ang[i] = pack.ReadFloat();
		}

		TeleportEntity(client, pos, ang);
		Gamemode_TakeDamage(client, Cvar[CrippleMax].FloatValue, 0);
	}

	delete pack;
}

bool Gamemode_InLastman()
{
	return LastMann;
}

void Gamemode_TakeDamage(int victim, float damage, int damagetype)
{
	if(damagetype & DMG_CRIT)
		damage *= 3.0;
	
	if(GetClientTeam(victim) == TFTeam_Human)
	{
		if(!Cvar[CrippleHuman].BoolValue)
			return;
		
		Client(victim).Cripple += damage * 3.0;
	}
	else
	{
		Client(victim).Cripple += damage;
	}

	if(!CrippleTimer[victim])
		CrippleTimer[victim] = CreateTimer(0.1, Timer_CrippleUpdate, victim, TIMER_REPEAT);
}

public Action Timer_CrippleUpdate(Handle timer, int client)
{
	if(Client(client).Cripple == 0.0)
	{
		CrippleTimer[client] = null;
		return Plugin_Stop;
	}

	if(Client(client).Cripple < 0.0)
	{
		if(Client(client).Cripple < -Cvar[ShieldMax].FloatValue)
			Client(client).Cripple = -Cvar[ShieldMax].FloatValue;
		
		Client(client).Cripple += Cvar[ShieldDecay].FloatValue * 0.1;
		if(Client(client).Cripple > 0.0)
			Client(client).Cripple = 0.0;
	}
	else
	{
		if(Client(client).Cripple > Cvar[CrippleMax].FloatValue)
			Client(client).Cripple = Cvar[CrippleMax].FloatValue;
		
		if(!TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
		{
			Client(client).Cripple -= Cvar[CrippleDecay].FloatValue * 0.1;
			if(Client(client).Cripple < 0.0)
				Client(client).Cripple = 0.0;
		}
	}
	
	UpdateCrippleSpeed(client);
	return Plugin_Continue;
}

static void UpdateCrippleSpeed(int client)
{
	if(Client(client).Cripple > 0.0)
	{
		float slowdown = Client(client).Cripple / Cvar[CrippleMax].FloatValue;
		if(slowdown > 1.0)
			slowdown = 1.0;
		
		if(slowdown > 0.4)
			TF2_StunPlayer(client, 0.22, slowdown, TF_STUNFLAG_SLOWDOWN);
	}
}