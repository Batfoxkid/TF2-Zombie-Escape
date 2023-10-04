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

static float BackstabCooldown[MAXTF2PLAYERS];

void Attributes_MapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		BackstabCooldown[i] = 0.0;
	}
}

void Attributes_OnBackstabZombie(int victim, int attacker, float &damage, int &damagetype, int weapon)
{
	float gameTime = GetGameTime();
	if(BackstabCooldown[victim] > gameTime)
	{
		damage = 0.0;
		return;
	}

	if(Attributes_FindOnWeapon(attacker, weapon, 217))	// sanguisuge
	{
		int maxoverheal = SDKCall_GetMaxHealth(attacker) * 3;
		int health = GetClientHealth(attacker);
		if(health < maxoverheal)
		{
			SetEntityHealth(attacker, maxoverheal);
			ApplySelfHealEvent(attacker, maxoverheal - health);
			
			if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
				TF2_RemoveCondition(attacker, TFCond_OnFire);
			
			if(TF2_IsPlayerInCondition(attacker, TFCond_Bleeding))
				TF2_RemoveCondition(attacker, TFCond_Bleeding);
			
			if(TF2_IsPlayerInCondition(attacker, TFCond_Plague))
				TF2_RemoveCondition(attacker, TFCond_Plague);
		}
	}

	damage = 500.0;
	
	float value = Attributes_FindOnPlayer(attacker, 296);	// sapper kills collect crits
	if(value)
		SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits") + RoundFloat(value));
	
	value = Attributes_FindOnWeapon(attacker, weapon, 399, true, 1.0);	// armor piercing
	if(value != 1.0)
		damage *= value;
	
	if(Attributes_FindOnWeapon(attacker, weapon, 154))	// disguise on backstab
	{
		DataPack pack = new DataPack();
		RequestFrame(Attributes_RedisguiseFrame, pack);
		pack.WriteCell(GetClientUserId(attacker));

		if(TF2_IsPlayerInCondition(attacker, TFCond_Disguised))
		{
			pack.WriteCell(GetEntProp(attacker, Prop_Send, "m_nDisguiseTeam"));
			pack.WriteCell(GetEntProp(attacker, Prop_Send, "m_nDisguiseClass"));
			pack.WriteCell(GetEntPropEnt(attacker, Prop_Send, "m_hDisguiseTarget"));
			pack.WriteCell(GetEntProp(attacker, Prop_Send, "m_iDisguiseHealth"));
		}
		else
		{
			pack.WriteCell(GetClientTeam(victim));
			pack.WriteCell(TF2_GetPlayerClass(victim));
			pack.WriteCell(victim);
			pack.WriteCell(GetClientHealth(victim));
		}
	}

	float time = damage / 50.0;
	
	if(Attributes_FindOnWeapon(attacker, weapon, 156))	// silent killer
	{
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		time *= 0.75;
		TF2_AddCondition(victim, TFCond_HalloweenKartNoTurn, time, attacker);
	}
	else
	{
		TF2_StunPlayer(victim, time, 1.0, TF_STUNFLAGS_BIGBONK, attacker);
	}

	BackstabCooldown[victim] = gameTime + time + 1.0;
}

public void Attributes_RedisguiseFrame(DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		TF2_AddCondition(client, TFCond_Disguised, -1.0);
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", pack.ReadCell());
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", pack.ReadCell());
		SetEntPropEnt(client, Prop_Send, "m_hDisguiseTarget", pack.ReadCell());
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", pack.ReadCell());
	}

	delete pack;
}

void Attributes_OnHitZombiePre(float &damage, int &damagetype, int weapon, int &critType)
{
	if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		char classname[36];
		if(GetEntityClassname(weapon, classname, sizeof(classname)))
		{
			if(StrEqual(classname, "tf_weapon_stickbomb"))
			{
				// Ullapool Caber gets a critical explosion
				if(!GetEntProp(weapon, Prop_Send, "m_iDetonated"))
				{
					damage *= 10.0;
					damagetype |= DMG_CRIT;
					critType = 2;
				}
			}
		}
	}
}

void Attributes_OnHitZombie(int attacker, int victim, int inflictor, float fdamage, int weapon, int damagecustom)
{
	if(weapon != -1 && !HasEntProp(weapon, Prop_Send, "m_AttributeList"))
		weapon = -1;
	
	char classname[36];
	int slot = TFWeaponSlot_Building;
	if(weapon != -1)
	{
		if(GetEntityClassname(weapon, classname, sizeof(classname)))
		{
			slot = TF2_GetClassnameSlot(classname);
			if(slot > TFWeaponSlot_Grenade)
				slot = TFWeaponSlot_Grenade;
		}
	}
	
	int lastPlayerDamage = Client(attacker).Damage;
	int lastWeaponDamage = Client(attacker).GetDamage(slot);
	
	int idamage = damagecustom == TF_CUSTOM_BACKSTAB ? GetClientHealth(victim) : RoundFloat(fdamage);
	Client(attacker).Damage = lastPlayerDamage + idamage;
	Client(attacker).SetDamage(slot, lastWeaponDamage + idamage);
	
	float value = Attributes_FindOnPlayer(attacker, 203);	// drop health pack on kill
	if(value > 0.0)
	{
		int amount = DamageGoal(RoundFloat(270.0 / value), Client(attacker).Damage, lastPlayerDamage);
		if(amount)
		{
			float position[3];
			GetClientAbsOrigin(victim, position);
			position[2] += 20.0;
			
			float velocity[3];
			velocity[2] = 50.0;
			
			int team = GetClientTeam(attacker);  
			for(int i; i < amount; i++)
			{
				int entity = CreateEntityByName("item_healthkit_small");
				if(IsValidEntity(entity))
				{
					DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
					SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
					velocity[0] = GetRandomFloat(-10.0, 10.0);
					velocity[1] = GetRandomFloat(-10.0, 10.0);
					TeleportEntity(entity, position, _, velocity);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", attacker);
					
					SetVariantString("OnUser4 !self:Kill::30:1,0,1");
					AcceptEntityInput(entity, "AddOutput");
					AcceptEntityInput(entity, "FireUser4");
				}
			}
		}
	}
	
	if(Attributes_FindOnPlayer(attacker, 387))	// rage on kill
	{
		float rage = 33.34;
		if(slot != TFWeaponSlot_Primary)
			rage = fdamage / 3.8993;	// 33.34% every 130 damage
		
		rage += GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
		if(rage > 100.0)
			rage = 100.0;
		
		SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
	}
	
	if(Attributes_FindOnPlayer(attacker, 418) > 0.0)	// boost on damage
	{
		DataPack pack = new DataPack();
		CreateDataTimer(1.0, Attributes_BoostDrainStack, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(attacker));
		pack.WriteFloat(fdamage / 2.0);
	}
	
	if(damagecustom != TF_CUSTOM_BURNING && damagecustom != TF_CUSTOM_BLEEDING)
	{
		if(Attributes_FindOnWeapon(attacker, weapon, 30))	// fists have radial buff
		{
			int entity;
			int team = GetClientTeam(attacker);
			float pos1[3], pos2[3];
			GetClientAbsOrigin(attacker, pos1);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(attacker != target && IsClientInGame(target) && GetClientTeam(target) == team && IsPlayerAlive(target))
				{
					GetClientAbsOrigin(target, pos2);
					if(GetVectorDistance(pos1, pos2, true) < 160000)
					{
						int maxhealth = SDKCall_GetMaxHealth(attacker);
						int health = GetClientHealth(attacker);
						if(health < maxhealth)
						{
							if(health+50 > maxhealth)
							{
								SetEntityHealth(target, maxhealth);
								ApplyAllyHealEvent(attacker, target, maxhealth - health);
								ApplySelfHealEvent(target, maxhealth - health);
							}
							else
							{
								SetEntityHealth(target, health + 50);
								ApplyAllyHealEvent(attacker, target, 50);
								ApplySelfHealEvent(target, 50);
							}
						}
						
						int i;
						while(TF2_GetItem(target, entity, i))
						{
							Address attrib = TF2Attrib_GetByDefIndex(entity, 28);
							if(attrib != Address_Null)
							{
								TF2Attrib_SetByDefIndex(entity, 28, TF2Attrib_GetValue(attrib) * 1.1);
							}
							else
							{
								TF2Attrib_SetByDefIndex(entity, 28, 1.1);
							}
						}
					}
				}
			}
		}
	
		value = Attributes_FindOnWeapon(attacker, weapon, 31);	// critboost on kill
		if(value)
			TF2_AddCondition(attacker, TFCond_CritOnKill, value);
		
		value = Attributes_FindOnWeapon(attacker, weapon, 158);	// add cloak on kill
		if(value)
		{
			float cloak = GetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter") + value*100.0;
			if(cloak > 100)
			{
				cloak = 100.0;
			}
			else if(cloak < 0.0)
			{
				cloak = 0.0;
			}
			
			SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", cloak);
		}
		
		value = Attributes_FindOnWeapon(attacker, weapon, 180);	// heal on kill
		if(value)
		{
			int maxhealth = SDKCall_GetMaxHealth(attacker);
			int health = GetClientHealth(attacker);
			if(health < maxhealth)
			{
				int healing = RoundFloat(value);
				if(health + healing > maxhealth)
				{
					SetEntityHealth(attacker, maxhealth);
					ApplySelfHealEvent(attacker, maxhealth - health);
				}
				else
				{
					SetEntityHealth(attacker, health + healing);
					ApplySelfHealEvent(attacker, healing);
				}
			}
		}
		
		if(Attributes_FindOnWeapon(attacker, weapon, 219) && !StrContains(classname, "tf_weapon_sword"))	// Eyelander
		{
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
			TF2_AddCondition(attacker, TFCond_DemoBuff);
			SDKCall_SetSpeed(attacker);
			
			int maxhealth = SDKCall_GetMaxHealth(attacker);
			int health = GetClientHealth(attacker);
			if(health < maxhealth)
			{
				if(health + 15 > maxhealth)
				{
					SetEntityHealth(attacker, maxhealth);
					ApplySelfHealEvent(attacker, maxhealth - health);
				}
				else
				{
					SetEntityHealth(attacker, health + 15);
					ApplySelfHealEvent(attacker, 15);
				}
			}
		}
		
		value = Attributes_FindOnWeapon(attacker, weapon, 220);
		if(value)	// restore health on kill
		{
			int maxhealth = SDKCall_GetMaxHealth(attacker);
			int health = GetClientHealth(attacker);
			int maxoverheal = maxhealth * 2;

			if(health < maxoverheal)
			{
				int healing = RoundFloat(float(maxhealth) * value / 100.0);
				
				if(health + healing > maxoverheal)
				{
					SetEntityHealth(attacker, maxoverheal);
					ApplySelfHealEvent(attacker, maxoverheal - health);
				}
				else
				{
					SetEntityHealth(attacker, health + healing);
					ApplySelfHealEvent(attacker, healing);
				}
			}
		}
		
		if(weapon != -1 && Attributes_FindOnWeapon(attacker, weapon, 226))	// honorbound
		{
			SetEntProp(weapon, Prop_Send, "m_bIsBloody", true);
			SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")+1);
		}
		
		if(Attributes_FindOnWeapon(attacker, weapon, 409))	// kill forces attacker to laugh
			TF2_StunPlayer(attacker, 2.0, 1.0, TF_STUNFLAGS_NORMALBONK);
		
		value = Attributes_FindOnWeapon(attacker, weapon, 613);	// minicritboost on kill
		if(value)
			TF2_AddCondition(attacker, TFCond_MiniCritOnKill, value);
		
		if(Attributes_FindOnWeapon(attacker, weapon, 644))	// clipsize increase on kill
		{
			int amount = DamageGoal(450, Client(attacker).GetDamage(slot), lastWeaponDamage);
			if(amount)
				SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+amount);
		}
		
		value = Attributes_FindOnWeapon(attacker, weapon, 736);	// speed_boost_on_kill
		if(value)
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, value);
		
		if(Attributes_FindOnWeapon(attacker, weapon, 807))	// add_head_on_kill
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
		
		if(damagecustom == TF_CUSTOM_HEADSHOT && StrEqual(classname, "tf_weapon_sniperrifle_decap")) // Bazaar Bargain
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
	}
	
	if(slot == TFWeaponSlot_Building)
	{
		int amount = DamageGoal(450, Client(attacker).GetDamage(slot), lastWeaponDamage);
		if(amount)
		{
			if(inflictor != -1 && GetEntityClassname(inflictor, classname, sizeof(classname)) && !StrContains(classname, "obj_sentrygun"))
				SetEntProp(inflictor, Prop_Send, "m_iKills", GetEntProp(inflictor, Prop_Send, "m_iKills") + 1);
			
			weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Grenade);
			slot = TFWeaponSlot_Grenade;
		}
	}
}

float Attributes_FindOnPlayer(int client, int index, bool multi = false, float defaul = 0.0)
{
	float total = defaul;
	bool found = Attributes_GetByDefIndex(client, index, total);
	
	int i;
	int entity;
	float value;
	while(TF2_GetWearable(client, entity, i))
	{
		if(Attributes_GetByDefIndex(entity, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	while(TF2_GetItem(client, entity, i))
	{
		if(index != 128 && active != entity && Attributes_GetByDefIndex(entity, 128, value) && value)
			continue;
		
		if(Attributes_GetByDefIndex(entity, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

float Attributes_FindOnWeapon(int client, int entity, int index, bool multi = false, float defaul = 0.0)
{
	float total = defaul;
	bool found = Attributes_GetByDefIndex(client, index, total);
	
	int i;
	int wear;
	float value;
	while(TF2_GetWearable(client, wear, i))
	{
		if(Attributes_GetByDefIndex(wear, index, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	if(entity != -1)
	{
		if(Attributes_GetByDefIndex(entity, index, value))
		{
			if(!found)
			{
				total = value;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

bool Attributes_GetByDefIndex(int entity, int index, float &value)
{
	Address attrib = TF2Attrib_GetByDefIndex(entity, index);
	if(attrib != Address_Null)
	{
		value = TF2Attrib_GetValue(attrib);
		return true;
	}
	
	// Players
	if(entity <= MaxClients)
		return false;
	
	static int indexes[20];
	static float values[20];
	int count = TF2Attrib_GetSOCAttribs(entity, indexes, values, 20);
	for(int i; i < count; i++)
	{
		if(indexes[i] == index)
		{
			value = values[i];
			return true;
		}
	}
	
	if(!GetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", 1))
	{
		count = TF2Attrib_GetStaticAttribs(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), indexes, values, 20);
		for(int i; i < count; i++)
		{
			if(indexes[i] == index)
			{
				value = values[i];
				return true;
			}
		}
	}
	
	return false;
}

public Action Attributes_BoostDrainStack(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client && IsPlayerAlive(client) && Client(client).Human)
	{
		float hype = GetEntPropFloat(client, Prop_Send, "m_flHypeMeter") - pack.ReadFloat();
		if(hype < 0.0)
			hype = 0.0;
		
		SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", hype);
	}
	return Plugin_Stop;
}