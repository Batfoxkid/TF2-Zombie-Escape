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

enum struct CvarInfo
{
	ConVar cvar;
	char value[16];
	char defaul[16];
	bool enforce;
}

static ArrayList CvarList;
static bool CvarHooked;

void ConVar_PluginStart()
{
	Cvar[Version] = CreateConVar("ze_version", PLUGIN_VERSION_FULL, "Zombie Escape Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar[Debugging] = CreateConVar("ze_debug", "0", "If to display debug outputs", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
	Cvar[ZombieRatio] = CreateConVar("zr_game_ratio", "0.2", "Zombies to total players at the start of a round", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(false, "ZombieEscape");
	
	Cvar[AllowSpectators] = FindConVar("mp_allowspectators");
	Cvar[MovementFreeze] = FindConVar("tf_player_movement_restart_freeze");
	Cvar[PreroundTime] = FindConVar("tf_arena_preround_time");
	//Cvar[BonusRoundTime] = FindConVar("mp_bonusroundtime");
	Cvar[Tournament] = FindConVar("mp_tournament");
	Cvar[WaitingTime] = FindConVar("mp_waitingforplayers_time");
	
	CvarList = new ArrayList(sizeof(CvarInfo));
	
	ConVar_Add("mp_forcecamera", "0");
	ConVar_Add("mp_humans_must_join_team", "any");
	ConVar_Add("mp_teams_unbalance_limit", "0");
	ConVar_Add("mp_waitingforplayers_time", "60.0", false);
	ConVar_Add("tf_weapon_criticals_melee", "0");
}

void ConVar_ConfigsExecuted()
{
	bool generate = !FileExists("cfg/sourcemod/ZombieEscape.cfg");
	
	if(!generate)
	{
		char buffer[512];
		Cvar[Version].GetString(buffer, sizeof(buffer));
		if(!StrEqual(buffer, PLUGIN_VERSION_FULL))
		{
			if(buffer[0])
				generate = true;
			
			Cvar[Version].SetString(PLUGIN_VERSION_FULL);
		}
	}
	
	if(generate)
		GenerateConfig();
	
	ConVar_Enable();
	SteamWorks_SetGameTitle();
}

static void GenerateConfig()
{
	File file = OpenFile("cfg/sourcemod/ZombieEscape.cfg", "wt");
	if(file)
	{
		file.WriteLine("// Settings present are for Zombie Escape: Open Source (" ... PLUGIN_VERSION_FULL ... ")");
		file.WriteLine("// Updating the plugin version will generate new cvars and any non-ZE commands will be lost");
		file.WriteLine("ze_version \"" ... PLUGIN_VERSION_FULL ... "\"");
		file.WriteLine(NULL_STRING);
		
		char buffer1[512], buffer2[256];
		for(int i; i < AllowSpectators; i++)
		{
			if(Cvar[i].Flags & FCVAR_DONTRECORD)
				continue;
			
			Cvar[i].GetDescription(buffer1, sizeof(buffer1));
			
			int current, split;
			do
			{
				split = SplitString(buffer1[current], "\n", buffer2, sizeof(buffer2));
				if(split == -1)
				{
					file.WriteLine("// %s", buffer1[current]);
					break;
				}
				
				file.WriteLine("// %s", buffer2);
				current += split;
			}
			while(split != -1);
			
			file.WriteLine("// -");
			
			Cvar[i].GetDefault(buffer2, sizeof(buffer2));
			file.WriteLine("// Default: \"%s\"", buffer2);
			
			float value;
			if(Cvar[i].GetBounds(ConVarBound_Lower, value))
				file.WriteLine("// Minimum: \"%.2f\"", value);
			
			if(Cvar[i].GetBounds(ConVarBound_Upper, value))
				file.WriteLine("// Maximum: \"%.2f\"", value);
			
			Cvar[i].GetName(buffer2, sizeof(buffer2));
			Cvar[i].GetString(buffer1, sizeof(buffer1));
			file.WriteLine("%s \"%s\"", buffer2, buffer1);
			file.WriteLine(NULL_STRING);
		}
		
		delete file;
	}
}

static void ConVar_Add(const char[] name, const char[] value, bool enforce = true)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	strcopy(info.value, sizeof(info.value), value);
	info.enforce = enforce;

	if(CvarHooked)
	{
		info.cvar.GetString(info.defaul, sizeof(info.defaul));

		bool setValue = true;
		if(!info.enforce)
		{
			char buffer[sizeof(info.defaul)];
			info.cvar.GetDefault(buffer, sizeof(buffer));
			if(!StrEqual(buffer, info.defaul))
				setValue = false;
		}

		if(setValue)
			info.cvar.SetString(info.value);
		
		info.cvar.AddChangeHook(ConVar_OnChanged);
	}

	CvarList.PushArray(info);
}

public void ConVar_OnlyChangeOnEmpty(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			cvar.SetString(oldValue);
			break;
		}
	}
}

stock void ConVar_Remove(const char[] name)
{
	ConVar cvar = FindConVar(name);
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);
		CvarList.Erase(index);

		if(CvarHooked)
		{
			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
		}
	}
}

void ConVar_Enable()
{
	if(!CvarHooked)
	{
		int length = CvarList.Length;
		for(int i; i < length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);
			info.cvar.GetString(info.defaul, sizeof(info.defaul));
			CvarList.SetArray(i, info);

			bool setValue = true;
			if(!info.enforce)
			{
				char buffer[sizeof(info.defaul)];
				info.cvar.GetDefault(buffer, sizeof(buffer));
				if(!StrEqual(buffer, info.defaul))
					setValue = false;
			}

			if(setValue)
				info.cvar.SetString(info.value);
			
			info.cvar.AddChangeHook(ConVar_OnChanged);
		}

		Cvar[Tournament].Flags &= ~(FCVAR_NOTIFY|FCVAR_REPLICATED);
		CvarHooked = true;
	}
}

void ConVar_Disable()
{
	if(CvarHooked)
	{
		int length = CvarList.Length;
		for(int i; i < length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);

			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
		}

		Cvar[Tournament].Flags |= (FCVAR_NOTIFY|FCVAR_REPLICATED);
		CvarHooked = false;
	}
}

public void ConVar_OnChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);

		if(!StrEqual(info.value, newValue))
		{
			strcopy(info.defaul, sizeof(info.defaul), newValue);
			CvarList.SetArray(index, info);

			if(info.enforce)
				info.cvar.SetString(info.value);
		}
	}
}
