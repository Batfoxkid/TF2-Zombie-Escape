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

#tryinclude <tf_ontakedamage>

#define OTD_LIBRARY		"tf_ontakedamage"

#if !defined __tf_ontakedamage_included
enum CritType
{
	CritType_None = 0,
	CritType_MiniCrit,
	CritType_Crit
};
#endif

static bool OTDLoaded;

static int CurrentEntities;

void SDKHook_PluginStart()
{
	OTDLoaded = LibraryExists(OTD_LIBRARY);
}

void SDKHook_LibraryAdded(const char[] name)
{
	if(!OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = true;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKUnhook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
		}
	}
}

void SDKHook_LibraryRemoved(const char[] name)
{
	if(OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = false;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
		}
	}
}

void SDKHook_HookClient(int client)
{
	if(!OTDLoaded)
		SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
	
	SDKHook(client, SDKHook_OnTakeDamagePost, SDKHook_TakeDamagePost);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > CurrentEntities)
		CurrentEntities = entity;
	
	if(StrContains(classname, "item_healthkit") != -1 || StrContains(classname, "item_ammopack") != -1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_StartTouch, SDKHook_PickupTouch);
		SDKHook(entity, SDKHook_Touch, SDKHook_PickupTouch);
	}
	else if(StrEqual(classname, "team_round_timer"))
	{
		SDKHook(entity, SDKHook_Spawn, SDKHook_TimerSpawn);
	}
	else
	{
		DHook_EntityCreated(entity, classname);
		Weapons_EntityCreated(entity, classname);
	}
}

public void OnEntityDestroyed(int entity)
{
	DHook_EntityDestoryed();
	CreateTimer(1.01, Timer_FreeEdict);
}

public Action Timer_FreeEdict(Handle timer, bool render)
{
	CurrentEntities--;
	return Plugin_Continue;
}

int SDKHook_GetEdictCount()
{
	return CurrentEntities;
}

public Action SDKHook_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CritType crit = (damagetype & DMG_CRIT) ? CritType_Crit : CritType_None;
	return TF2_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, crit);
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(Client(victim).Zombie)
	{
		if(!attacker)
		{
			if(damagetype & DMG_FALL)
			{
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if(victim == attacker)
		{
			return Plugin_Continue;
		}
		else if(attacker > 0 && attacker <= MaxClients)
		{
			if(IsInvuln(victim))
				return Plugin_Continue;
			
			switch(damagecustom)
			{
				case TF_CUSTOM_BACKSTAB:
				{
					damage *= 0.4;
					damagetype |= DMG_CRIT;
					critType = CritType_Crit;

					return Plugin_Changed;
				}
				case TF_CUSTOM_TELEFRAG:
				{
					damage = GetClientHealth(victim) * 0.65;
					damagetype |= DMG_CRIT;
					critType = CritType_Crit;
					
					return Plugin_Changed;
				}
			}
			
			if(critType == CritType_None && (damagetype & DMG_CRIT))
				critType = CritType_Crit;
			
			Attributes_OnHitZombiePre(damage, damagetype, weapon, view_as<int>(critType));
			return Plugin_Changed;
		}
		else
		{
			damage *= 10.0;
			
			if(critType == CritType_None && (damagetype & DMG_CRIT))
				critType = CritType_Crit;
			
			return Plugin_Changed;
		}
	}
	else if(attacker > 0 && attacker <= MaxClients && Client(attacker).Zombie)
	{
		if(!IsInvuln(victim))
		{
			bool changed;
			bool melee = ((damagetype & DMG_CLUB) || (damagetype & DMG_SLASH)) && damagecustom != TF_CUSTOM_BASEBALL;
			if(melee && SDKCall_CheckBlockBackstab(victim, attacker))
			{
				if(TF2_IsPlayerInCondition(victim, TFCond_RuneResist))
					TF2_RemoveCondition(victim, TFCond_RuneResist);
				
				float pos[3];
				GetClientAbsOrigin(victim, pos);
				ScreenShake(pos, 25.0, 150.0, 1.0, 50.0);
				
				EmitGameSoundToAll("Player.Spy_Shield_Break", victim, _, victim, pos);
				
				TF2_RemoveCondition(victim, TFCond_Zoomed);
				
				damage = 0.0;
				return Plugin_Handled;
			}
			
			if(!Attributes_FindOnWeapon(attacker, weapon, 797))
			{
				if(TF2_IsPlayerInCondition(victim, TFCond_Disguised))
				{
					damage *= 0.75;
					changed = true;
				}
				
				if(melee)
				{
					// Vaccinator conditions
					for(TFCond cond = TFCond_UberBulletResist; cond <= TFCond_UberFireResist; cond++)
					{
						if(TF2_IsPlayerInCondition(victim, cond))
						{
							// Uber Variant
							damage *= 0.5;
							critType = CritType_None;
							damagetype &= ~DMG_CRIT;
							changed = true;
						}
						
						// TODO: Figure out if uber and passive of the same type is or can be applied at the same time
						if(TF2_IsPlayerInCondition(victim, cond + view_as<TFCond>(3)))
						{
							// Passive Variant
							damage *= 0.9;
							changed = true;
						}
					}
				}
			}
			
			if(changed && critType == CritType_None && (damagetype & DMG_CRIT))
				critType = CritType_Crit;
			
			return changed ? Plugin_Changed : Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void SDKHook_TakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(Client(victim).Zombie)
	{
		if(victim != attacker && attacker > 0 && attacker <= MaxClients && !IsInvuln(victim))
			Attributes_OnHitZombie(attacker, victim, inflictor, damage, weapon, damagecustom);
	}
}

public Action SDKHook_PickupTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients && Client(client).Zombie)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHook_TimerSpawn(int entity)
{
	DispatchKeyValue(entity, "auto_countdown", "0");
	return Plugin_Continue;
}
