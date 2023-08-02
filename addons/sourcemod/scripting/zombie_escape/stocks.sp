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

void RegZombieCmd(const char[] cmd, ConCmd callback, const char[] description = NULL_STRING, int flags = 0)
{
	static const char Prefixes[][] = { "ze_", "ze", "zom_", "zom", "zf_", "zf", "zombie_", "zombie" };
	
	int length = strlen(cmd)+6;
	char[] command = new char[length];
	for(int i; i < sizeof(Prefixes); i++)
	{
		Format(command, length, "%s%s", Prefixes[i], cmd);
		RegConsoleCmd(command, callback, description, i ? flags|FCVAR_HIDDEN : flags);
	}
}

stock TFClassType GetClassOfName(const char[] buffer)
{
	TFClassType class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
		class = TF2_GetClass(buffer);
	
	return class;
}

stock void GetClassWeaponClassname(TFClassType class, char[] name, int length)
{
	if(!StrContains(name, "saxxy"))
	{ 
		switch(class)
		{
			case TFClass_Scout:	strcopy(name, length, "tf_weapon_bat");
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_fireaxe");
			case TFClass_DemoMan:	strcopy(name, length, "tf_weapon_bottle");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_fists");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_wrench");
			case TFClass_Medic:	strcopy(name, length, "tf_weapon_bonesaw");
			case TFClass_Sniper:	strcopy(name, length, "tf_weapon_club");
			case TFClass_Spy:	strcopy(name, length, "tf_weapon_knife");
			default:		strcopy(name, length, "tf_weapon_shovel");
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun"))
	{
		switch(class)
		{
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_shotgun_pyro");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_shotgun_hwg");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_shotgun_primary");
			default:		strcopy(name, length, "tf_weapon_shotgun_soldier");
		}
	}
}

stock void ShowGameText(int client, const char[] icon = "leaderboard_streak", int color = 0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(client)
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	
	if(bf)
	{
		char message[512];
		SetGlobalTransTarget(client);
		VFormat(message, sizeof(message), buffer, 5);
		CRemoveTags(message, sizeof(message));
		
		bf.WriteString(message);
		bf.WriteString(icon);
		bf.WriteByte(color);
		EndMessage();
	}
}

void ApplyAllyHealEvent(int healer, int patient, int amount)
{
	Event event = CreateEvent("player_healed", true);

	event.SetInt("healer", healer);
	event.SetInt("patient", patient);
	event.SetInt("amount", amount);

	event.Fire();
}

void ApplySelfHealEvent(int entindex, int amount)
{
	Event event = CreateEvent("player_healonhit", true);

	event.SetInt("entindex", entindex);
	event.SetInt("amount", amount);

	event.Fire();
}

int DamageGoal(int goal, int current, int last)
{
	return (current / goal) - (last / goal);
}

bool TF2_GetItem(int client, int &weapon, int &pos)
{
	//TODO: Find out if we need to check m_bDisguiseWeapon
	
	static int maxWeapons;
	if(!maxWeapons)
		maxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(pos < 0)
		pos = 0;
	
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;
		
		if(weapon != -1)
			return true;
	}
	return false;
}

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

void TF2_RemoveAllItems(int client)
{
	int entity, i;
	while(TF2_GetItem(client, entity, i))
	{
		TF2_RemoveItem(client, entity);
	}
}

bool TF2_GetWearable(int client, int &entity, int &index)
{
	if(index >= -1 && index <= MaxClients)
		index = MaxClients + 1;
	
	if(index > -2)
	{
		while((index = FindEntityByClassname(index, "tf_wear*")) != -1)
		{
			if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client)
			{
				entity = index;
				return true;
			}
		}
		
		index = -(MaxClients + 1);
	}
	
	entity = -index;
	while((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			index = -entity;
			return true;
		}
	}

	return false;
}

bool IsInvuln(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock bool TF2_IsCritBoosted(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) ||
			TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) ||
			TF2_IsPlayerInCondition(client, TFCond_CritCanteen) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnWin) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnKill) ||
			TF2_IsPlayerInCondition(client, TFCond_CritMmmph) ||
			TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) ||
			TF2_IsPlayerInCondition(client, TFCond_CritRuneTemp));
}

int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
{
	if(StrContains(classname, "tf_weapon_"))
	{
		return -1;
	}
	else if(!StrContains(classname, "tf_weapon_scattergun") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_primary") ||
	  !StrContains(classname, "tf_weapon_soda_popper") ||
	  !StrContains(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	  !StrContains(classname, "tf_weapon_particle_cannon") ||
	  !StrContains(classname, "tf_weapon_flamethrower") ||
	  !StrContains(classname, "tf_weapon_grenadelauncher") ||
	  !StrContains(classname, "tf_weapon_cannon") ||
	  !StrContains(classname, "tf_weapon_minigun") ||
	  !StrContains(classname, "tf_weapon_shotgun_primary") ||
	  !StrContains(classname, "tf_weapon_sentry_revenge") ||
	  !StrContains(classname, "tf_weapon_drg_pomson") ||
	  !StrContains(classname, "tf_weapon_shotgun_building_rescue") ||
	  !StrContains(classname, "tf_weapon_syringegun_medic") ||
	  !StrContains(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	  !StrContains(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_secondary") ||
	  !StrContains(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	  !StrContains(classname, "tf_weapon_buff_item") ||
	  !StrContains(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	  !StrContains(classname, "tf_weapon_laser_pointer") ||
	  !StrContains(classname, "tf_weapon_mechanical_arm") ||
	  !StrContains(classname, "tf_weapon_medigun") ||
	  !StrContains(classname, "tf_weapon_smg") ||
	  !StrContains(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_re"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

void ScreenShake(const float pos[3], float amplitude, float frequency, float duration, float radius)
{
	int entity = CreateEntityByName("env_shake");
	if(entity != -1)
	{
		DispatchKeyValueFloat(entity, "amplitude", amplitude);
		DispatchKeyValueFloat(entity, "radius", radius);
		DispatchKeyValueFloat(entity, "duration", duration);
		DispatchKeyValueFloat(entity, "frequency", frequency);
		
		DispatchSpawn(entity);
		
		TeleportEntity(entity, pos);
		AcceptEntityInput(entity, "StartShake");
		
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1,0,1", duration + 0.1);
		SetVariantString(buffer);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

void ZPrintToChat(int client, const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	CReplaceColorCodes(buffer2);
	CSendMessage(client, buffer2);
}

stock void ZPrintToChatEx(int client, int author, const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2, author);
	CSendMessage(client, buffer2, author);
}

stock void ZPrintToChatAll(const char[] message, any ...)
{
	CCheckTrie();
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || CSkipList[i])
		{
			CSkipList[i] = false;
			continue;
		}
		
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%t%s", "Prefix", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 2);
		CReplaceColorCodes(buffer2);
		CSendMessage(i, buffer2);
	}
}

void ZReplyToCommand(int client, const char[] message, any ...)
{
	char buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "[ZE] %s", buffer);
	}
	else
	{
		ZPrintToChat(client, "%s", buffer);
	}
}

stock void ZShowActivity(int client, const char[] message, any ...)
{
	char tag[MAX_BUFFER_LENGTH], buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	Format(tag, sizeof(tag), "%t", "Prefix");
	CShowActivity2(client, tag, "%s", buffer);
}

void PrintSayText2(int client, int author, bool chat = true, const char[] message, const char[] param1 = NULL_STRING, const char[] param2 = NULL_STRING, const char[] param3 = NULL_STRING, const char[] param4 = NULL_STRING)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)); 
	
	bf.WriteByte(author);
	bf.WriteByte(chat);
	
	bf.WriteString(message); 
	
	bf.WriteString(param1); 
	bf.WriteString(param2); 
	bf.WriteString(param3);
	bf.WriteString(param4);
	
	EndMessage();
}

stock void Debug(const char[] buffer, any ...)
{
	if(Cvar[Debugging].BoolValue)
	{
		char message[192];
		VFormat(message, sizeof(message), buffer, 2);
		CPrintToChatAll("{olive}[ZE {darkorange}DEBUG{olive}]{default} %s", message);
		PrintToServer("[ZE DEBUG] %s", message);
	}
}

stock any Min(any value, any min)
{
	if(value < min)
		return min;
	
	return value;
}

stock any Max(any value, any max)
{
	if(value > max)
		return max;
	
	return value;
}

stock any Clamp(any value, any min, any max)
{
	if(value > max)
		return max;
	
	if(value < min)
		return min;
	
	return value;
}