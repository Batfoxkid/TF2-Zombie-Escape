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