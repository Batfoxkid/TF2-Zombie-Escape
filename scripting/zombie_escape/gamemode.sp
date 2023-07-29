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

static Handle GameHud;
static Handle PlayerHud;

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
	int[] player = new int[MaxClients];
	int players;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			player[players++] = client;
		}
	}
	
	SortIntegers(player, players, Sort_Random);

	for(int i; i < players; i++)
	{
		TF2_RemovePlayerDisguise(player[i]);
		SDKCall_ChangeClientTeam(player[i], TFTeam_Zombie);
		TF2_RegeneratePlayer(player[i]);
		TF2_StunPlayer(player[i], 15.0, 1.0, TF_STUNFLAGS_NORMALBONK);
	}
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
		bool clean = (SDKHook_GetEdictCount() > (MAXENTITIES - 300))	// Reduce cosmetic count
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

		if(!hasVoodoo)
		{
			int entity = CreateEntityByName(classname);
			if(IsValidEntity(entity))
			{
				SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
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
	}

	if(!Client(client).NoChanges && GetClientMenu(client) == MenuSource_None)
		Weapons_ChangeMenu(client, 30);
}