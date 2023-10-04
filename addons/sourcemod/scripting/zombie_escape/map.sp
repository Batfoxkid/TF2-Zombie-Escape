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

static Handle HudSync;
static Handle MapTimer;
static float MapTimerEnd;
static int HeldPropRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

void Map_PluginStart()
{
	HudSync = CreateHudSynchronizer();

	RegServerCmd("ze_map_say", Map_CommandSay, "ZE Old Map Support", FCVAR_HIDDEN);
	RegServerCmd("ze_map_timer", Map_CommandTimer, "ZE Old Map Support", FCVAR_HIDDEN);
}

void Map_RoundSetup()
{
	delete MapTimer;
}

void Map_MapEnd()
{
	delete MapTimer;
}

public Action Map_CommandSay(int args)
{
	char buffer[PLATFORM_MAX_PATH];
	GetCmdArgString(buffer, sizeof(buffer));
	ZPrintToChatAll(buffer);
	return Plugin_Handled;
}

public Action Map_CommandTimer(int args)
{
	MapTimerEnd = GetGameTime() + GetCmdArgFloat(1);

	if(!MapTimer)
		MapTimer = CreateTimer(0.2, Map_HudTimer, _, TIMER_REPEAT);
	
	return Plugin_Handled;
}

public Action Map_HudTimer(Handle timer)
{
	float time = MapTimerEnd - GetGameTime();
	if(time > 0.0)
	{
		SetHudTextParams(-1.0, 0.2, 0.2, 0, 255, 0, 255);
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && !Client(client).Zombie)
			{
				ShowSyncHudText(client, HudSync, "Defend for %d", RoundToCeil(time));
			}
		}
		return Plugin_Continue;
	}

	SetHudTextParams(-1.0, 0.2, 2.0, 0, 255, 0, 255, _, _, _, 2.0);
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !Client(client).Zombie)
		{
			ShowSyncHudText(client, HudSync, "Go Go Go");
		}
	}

	MapTimer = null;
	return Plugin_Stop;
}

bool Map_CallForMedic(int client)
{
	if(DropItem(client, false))
		return true;
	
	if(GetClientTeam(client) == TFTeam_Human)
	{
		float pos[3], vec[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, vec);

		Handle trace = TR_TraceRayFilterEx(pos, vec, MASK_ALL, RayType_Infinite, Trace_DontHitSelf, client);
		if(TR_DidHit(trace))
		{
			int entity = TR_GetEntityIndex(trace);
			if(entity > MaxClients)
			{
				char buffer[64];
				if(GetEntityClassname(entity, buffer, sizeof(buffer)) && !StrContains(buffer, "prop_physics"))
				{
					GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
					if(StrEqual(buffer, "gascan") ||
						StrContains(buffer, "szf_carry", false) != -1 ||
						StrContains(buffer, "szf_pick", false) != -1)
					{
						TR_GetEndPosition(vec, trace);
						if(GetVectorDistance(pos, vec, true) < 10000.0)	// 100 HU
						{
							HeldPropRef[client] = EntIndexToEntRef(entity);

							AcceptEntityInput(entity, "DisableMotion");
							SetEntProp(entity, Prop_Send, "m_nSolidType", 0);

							AcceptEntityInput(entity, "FireUser1", client, client);
							
							EmitSoundToClient(client, "ui/item_paint_can_pickup.wav");

							delete trace;
							return true;
						}
					}
				}
			}
		}

		delete trace;
	}
	return false;
}

void Map_ClientDisconnect(int client)
{
	DropItem(client, true);
}

void Map_PlayerDeath(int victim)
{
	DropItem(victim, true);
}

void Map_PlayerRunCmdPost(int client, const float angles[3])
{
	if(HeldPropRef[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(HeldPropRef[client]);
		if(entity != -1)
		{
			float pos[3];
			GetClientEyePosition(client, pos);
			
			pos[2] -= 20.0;
			
			float ang[3];
			ang[0] = 5.0;
			ang[1] = angles[1];
			ang[2] = angles[2] + 35.0;
			
			float vec[3];
			vec[0] = Cosine(DegToRad(ang[1]));
			vec[1] = Sine(DegToRad(ang[1]));
			vec[2] = -Sine(DegToRad(ang[0]));
			NormalizeVector(vec, vec);
			ScaleVector(vec, 60.0);

			AddVectors(pos, vec, pos);
			TeleportEntity(entity, pos, ang, NULL_VECTOR);
		}
	}
}

static bool DropItem(int client, bool death)
{
	if(HeldPropRef[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(HeldPropRef[client]);
		HeldPropRef[client] = INVALID_ENT_REFERENCE;

		if(entity != -1)
		{
			SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
			AcceptEntityInput(entity, "EnableMotion");

			AcceptEntityInput(entity, "FireUser2", client, client);

			if(!death)
			{
				float eyePos[3], mins[3], maxs[3], entityPos[3];
				GetClientEyePosition(client, eyePos);
				GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
				GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
				
				// Make sure the item isn't stuck in a wall
				Handle trace = TR_TraceHullFilterEx(entityPos, entityPos, mins, maxs, MASK_SOLID, Trace_DontHitSelf, entity);
				bool hit = TR_DidHit(trace);
				delete trace;

				if(!hit)
				{
					// Make sure there's nothing between the player and the item
					trace = TR_TraceRayFilterEx(eyePos, entityPos, MASK_ALL, RayType_EndPoint, Trace_DontHitSelf, client);
					
					if(TR_DidHit(trace) && TR_GetEntityIndex(trace) == entity)
					{
						// Put the item where it would be via carrying
						eyePos[0] += 20.0;
						eyePos[2] -= 30.0;
					}

					delete trace;
				}

				TeleportEntity(entity, eyePos, NULL_VECTOR, NULL_VECTOR);
			}
			return true;
		}
	}
	return false;
}