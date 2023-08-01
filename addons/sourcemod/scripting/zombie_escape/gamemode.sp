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
#define SKIN_ZOMBIE_SPY	SKIN_ZOMBIE + 17

static Handle GameHud;
static Handle PlayerHud;
static bool LastMann;

void Gamemode_PluginStart()
{
	GameHud = CreateHudSynchronizer();
	PlayerHud = CreateHudSynchronizer();
}

void Gamemode_RoundSetup()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			Client(client).ResetByRound();
			
			ClearSyncHud(client, GameHud);
			ClearSyncHud(client, PlayerHud);

			ChangeClientTeam(client, TFTeam_Human);
		}
	}
}

void Gamemode_RoundStart()
{
	LastMann = false;
	
	int[] player = new int[MaxClients];
	int players;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			player[players++] = client;
		}
	}
	
	if(players > 2)
	{
		SortIntegers(player, players, Sort_Random);

		players = RoundFloat(players * ze_map_infect_ratio.FloatValue);
		if(!players)
			players = 1;

		for(int i; i < players; i++)
		{
			TF2_RemovePlayerDisguise(player[i]);
			SDKCall_ChangeClientTeam(player[i], TFTeam_Zombie);
			TF2_RegeneratePlayer(player[i]);
			TF2_StunPlayer(player[i], 15.0, 1.0, TF_STUNFLAGS_NORMALBONK);
			TF2_AddCondition(player[i], TFCond_UberchargedCanteen, 15.0);
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

void Gamemode_InventoryApplication(int client)
{
	if(Client(client).PendingStrip)
	{
		Client(client).PendingStrip = false;
		TF2_RemoveAllItems(client);

		int i, entity;
		while(TF2U_GetWearable(client, entity, i))
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
		while(TF2U_GetWearable(client, entity, i))
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

					TF2U_EquipPlayerWearable(client, entity);
					SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
					SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
				}
			}
		}

		SetEntProp(client, Prop_Send, "m_nForcedSkin", class == TFClass_Spy ? SKIN_ZOMBIE_SPY : SKIN_ZOMBIE);
		SetEntProp(client, Prop_Send, "m_bForcedSkin", true);
	}
	else
	{
		int i, entity;
		while(TF2U_GetWearable(client, entity, i))
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

		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 0);
	}

	if(!Client(client).NoChanges && GetClientMenu(client) == MenuSource_None)
		Weapons_ChangeMenu(client, 30);
}

void Gamemode_PlayerDeath(int client, int attacker)
{
	if(Client(client).Human && !GameRules_GetProp("m_bInSetup"))
	{
		ChangeClientTeam(client, TFTeam_Zombie);

		if(attacker > 0 && attacker <= MaxClients && Client(attacker).Zombie)
		{
			float pos[3], ang[3];
			GetClientAbsOrigin(client, pos);
			GetClientEyeAngles(client, ang);

			TF2_RespawnPlayer(client);
			TeleportEntity(client, pos, ang, NULL_VECTOR);
			TF2_StunPlayer(client, 5.0, 1.0, TF_STUNFLAGS_NORMALBONK);
		}

		Gamemode_ClientDisconnect(client);
	}
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
				SetEntityHealth(found, GetClientHealth(found) + 585);
				TF2_AddCondition(found, TFCond_Buffed);
				TF2_AddCondition(found, TFCond_UberchargedCanteen, 2.0);
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
	return false;
}

bool Gamemode_InLastman()
{
	return LastMann;
}