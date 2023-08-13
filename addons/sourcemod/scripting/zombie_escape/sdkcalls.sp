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

static Handle SDKEquipWearable;
static Handle SDKGetMaxHealth;
static Handle SDKTeamAddPlayer;
static Handle SDKTeamRemovePlayer;
static Handle SDKCheckBlockBackstab;
static Handle SDKSetSpeed;

static int FailWarning;
static int FailCritical;

void SDKCall_PluginStatus()
{
	PrintToServer("SDKCalls: %d warnings, %d errors", FailWarning, FailCritical);
}

void SDKCall_Setup()
{
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
	{
		LogError("[Gamedata] Could not find RemoveWearable");
		FailCritical++;
	}
	
	delete gamedata;
	
	
	gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
	{
		LogError("[Gamedata] Could not find GetMaxHealth");
		FailWarning++;
	}
	
	delete gamedata;
	
	
	gamedata = new GameData("zombie_escape");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamAddPlayer = EndPrepSDKCall();
	if(!SDKTeamAddPlayer)
	{
		LogError("[Gamedata] Could not find CTeam::AddPlayer");
		FailWarning++;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamRemovePlayer = EndPrepSDKCall();
	if(!SDKTeamRemovePlayer)
	{
		LogError("[Gamedata] Could not find CTeam::RemovePlayer");
		FailWarning++;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::CheckBlockBackstab");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	SDKCheckBlockBackstab = EndPrepSDKCall();
	if(!SDKCheckBlockBackstab)
	{
		LogError("[Gamedata] Could not find CTFPlayer::CheckBlockBackstab");
		FailCritical++;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	SDKSetSpeed = EndPrepSDKCall();
	if(!SDKSetSpeed)
	{
		LogError("[Gamedata] Could not find CTFPlayer::TeamFortress_SetSpeed");
		FailWarning++;
	}
	
	delete gamedata;
}

bool SDKCall_CheckBlockBackstab(int client, int attacker)
{
	if(SDKCheckBlockBackstab)
		return SDKCall(SDKCheckBlockBackstab, client, attacker);
	
	return false;
}

void SDKCall_EquipWearable(int client, int entity)
{
	if(SDKEquipWearable)
	{
		SDKCall(SDKEquipWearable, client, entity);
	}
	else
	{
		RemoveEntity(entity);
	}
}

int SDKCall_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

void SDKCall_SetSpeed(int client)
{
	if(SDKSetSpeed)
	{
		SDKCall(SDKSetSpeed, client);
	}
	else
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}

void SDKCall_ChangeClientTeam(int client, int newTeam)
{
	int clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	if(newTeam == clientTeam)
		return;
	
	if(SDKTeamAddPlayer && SDKTeamRemovePlayer)
	{
		int entity = MaxClients+1;
		while((entity = FindEntityByClassname(entity, "tf_team")) != -1)
		{
			int entityTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
			if(entityTeam == clientTeam)
			{
				SDKCall(SDKTeamRemovePlayer, entity, client);
			}
			else if(entityTeam == newTeam)
			{
				SDKCall(SDKTeamAddPlayer, entity, client);
			}
		}
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", newTeam);
	}
	else
	{
		if(newTeam < TFTeam_Red)
			newTeam += 2;
		
		int state = GetEntProp(client, Prop_Send, "m_lifeState");
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, newTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", state);
	}
}