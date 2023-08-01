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

enum struct RawHooks
{
	int Ref;
	int Pre;
	int Post;
}

static DynamicHook ForceRespawn;
static DynamicHook RoundRespawn;
static DynamicHook ApplyOnInjured;
static DynamicHook HookItemIterateAttribute;

static ArrayList RawEntityHooks;
static int DamageTypeOffset = -1;
static int EconViewAttribsOffset;
static int EconItemOffset;

static int ForceRespawnPreHook[MAXTF2PLAYERS];
static int ReturningTeam;
static int KnifeWasChanged = -1;

void DHook_Setup()
{
	GameData gamedata = new GameData("zombie_escape");
	
	DamageTypeOffset = gamedata.GetOffset("m_bitsDamageType");
	if(DamageTypeOffset == -1)
		LogError("[Gamedata] Could not find m_bitsDamageType");
	
	CreateDetour(gamedata, "CTFPlayer::CanPickupDroppedWeapon", DHook_CanPickupDroppedWeaponPre);
	CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DHook_DropAmmoPackPre);
	CreateDetour(gamedata, "CTFPlayer::RegenThink", DHook_RegenThinkPre, DHook_RegenThinkPost);
	CreateDetour(gamedata, "CTFWeaponBaseMelee::DoSwingTraceInternal", DHook_DoSwingTracePre, DHook_DoSwingTracePost);
	
	ForceRespawn = CreateHook(gamedata, "CBasePlayer::ForceRespawn");
	HookItemIterateAttribute = CreateHook(gamedata, "CEconItemView::IterateAttributes");
	RoundRespawn = CreateHook(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
	ApplyOnInjured = CreateHook(gamedata, "CTFWeaponBase::ApplyOnInjuredAttributes");

	EconItemOffset = FindSendPropInfo("CEconEntity", "EconItemOffset");
	FindSendPropInfo("CEconEntity", "EconViewAttribsOffset", _, _, EconViewAttribsOffset);
	
	delete gamedata;
	
	RawEntityHooks = new ArrayList(sizeof(RawHooks));
}

static DynamicHook CreateHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if(!hook)
		LogError("[Gamedata] Could not find %s", name);
	
	return hook;
}

static void CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback != INVALID_FUNCTION && !detour.Enable(Hook_Pre, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback != INVALID_FUNCTION && !detour.Enable(Hook_Post, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);
		
		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

void DHook_MapStart()
{
	if(!RoundRespawn || RoundRespawn.HookGamerules(Hook_Pre, DHook_RoundRespawn) == INVALID_HOOK_ID)
		HookEvent("teamplay_round_start", DHook_RoundSetup, EventHookMode_PostNoCopy);
}

void DHook_HookClient(int client)
{
	if(ForceRespawn)
		ForceRespawnPreHook[client] = ForceRespawn.HookEntity(Hook_Pre, client, DHook_ForceRespawnPre);
}

void DHook_EntityCreated(int entity, const char[] classname)
{
	if(ApplyOnInjured && !StrContains(classname, "tf_weapon_knife"))
	{
		ApplyOnInjured.HookEntity(Hook_Pre, entity, DHook_KnifeInjuredPre);
		ApplyOnInjured.HookEntity(Hook_Post, entity, DHook_KnifeInjuredPost);
	}
}

void DHook_HookStripWeapon(int entity)
{
	if(EconItemOffset > 0 && EconViewAttribsOffset > 0)
	{
		Address econItemView = GetEntityAddress(entity) + view_as<Address>(EconItemOffset);
		
		RawHooks raw;
		
		raw.Ref = EntIndexToEntRef(entity);
		raw.Pre = HookItemIterateAttribute.HookRaw(Hook_Pre, econItemView, DHook_IterateAttributesPre);
		raw.Post = HookItemIterateAttribute.HookRaw(Hook_Post, econItemView, DHook_IterateAttributesPost);
		
		RawEntityHooks.PushArray(raw);
	}
}

void DHook_EntityDestoryed()
{
	RequestFrame(DHook_EntityDestoryedFrame);
}

public void DHook_EntityDestoryedFrame()
{
	int length = RawEntityHooks.Length;
	if(length)
	{
		RawHooks raw;
		for(int i; i < length; i++)
		{
			RawEntityHooks.GetArray(i, raw);
			if(!IsValidEntity(raw.Ref))
			{
				if(raw.Pre != INVALID_HOOK_ID)
					DynamicHook.RemoveHook(raw.Pre);
				
				if(raw.Post != INVALID_HOOK_ID)
					DynamicHook.RemoveHook(raw.Post);
				
				RawEntityHooks.Erase(i--);
				length--;
			}
		}
	}
}

void DHook_PluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			DHook_UnhookClient(client);
	}
}

void DHook_UnhookClient(int client)
{
	if(ForceRespawn)
		DynamicHook.RemoveHook(ForceRespawnPreHook[client]);
}

public void DHook_RoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	DHook_RoundRespawn();	// Back up plan
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > TFTeam_Spectator)
			TF2_RespawnPlayer(client);
	}
}

public MRESReturn DHook_CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
	if(Client(client).Zombie)
	{
		ret.Value = false;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DHook_DropAmmoPackPre(int client, DHookParam param)
{
	return Client(client).Zombie ? MRES_Supercede : MRES_Ignored;
}

public MRESReturn DHook_ForceRespawnPre(int client)
{
	Gamemode_ForceRespawn(client);
	
	return MRES_Ignored;
}

public MRESReturn DHook_RegenThinkPre(int client, DHookParam param)
{
	if(Client(client).Zombie && TF2_GetPlayerClass(client) == TFClass_Medic)
		TF2_SetPlayerClass(client, TFClass_Unknown, _, false);
	
	return MRES_Ignored;
}

public MRESReturn DHook_RegenThinkPost(int client, DHookParam param)
{
	if(Client(client).Zombie && TF2_GetPlayerClass(client) == TFClass_Unknown)
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
	
	return MRES_Ignored;
}

public MRESReturn DHook_DoSwingTracePre(int entity, DHookReturn ret, DHookParam param)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", true);

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int clientTeam = GetClientTeam(client);
	if(clientTeam != TFTeam_Blue)
	{
		ReturningTeam = clientTeam;

		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target))
			{
				int targetTeam = GetClientTeam(target);
				if(targetTeam == clientTeam)
				{
					SetEntProp(target, Prop_Send, "m_iTeamNum", TFTeam_Blue);
				}
				else if(targetTeam == TFTeam_Blue)
				{
					SetEntProp(target, Prop_Send, "m_iTeamNum", clientTeam);
				}
			}
		}
	}
	return MRES_Ignored;
}

public MRESReturn DHook_DoSwingTracePost(int entity, DHookReturn ret, DHookParam param)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", false);

	if(ReturningTeam != -1)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target))
			{
				int team = GetClientTeam(target);
				if(team == ReturningTeam)
				{
					SetEntProp(target, Prop_Send, "m_iTeamNum", TFTeam_Blue);
				}
				else if(team == TFTeam_Blue)
				{
					SetEntProp(target, Prop_Send, "m_iTeamNum", ReturningTeam);
				}
			}
		}

		ReturningTeam = -1;
	}
	return MRES_Ignored;
}

public MRESReturn DHook_RoundRespawn()
{
	Gamemode_RoundSetup();
	return MRES_Ignored;
}

public MRESReturn DHook_KnifeInjuredPre(int entity, DHookParam param)
{
	if(DamageTypeOffset != -1 && !param.IsNull(2) && Client(param.Get(2)).Zombie)
	{
		Address address = view_as<Address>(param.Get(3) + DamageTypeOffset);
		int damagetype = LoadFromAddress(address, NumberType_Int32);
		if(!(damagetype & DMG_BURN))
		{
			KnifeWasChanged = damagetype;
			StoreToAddress(address, damagetype | DMG_BURN, NumberType_Int32);
		}
	}

	return MRES_Ignored;
}

public MRESReturn DHook_KnifeInjuredPost(int entity, DHookParam param)
{
	if(KnifeWasChanged != -1)
	{
		StoreToAddress(view_as<Address>(param.Get(3) + DamageTypeOffset), KnifeWasChanged, NumberType_Int32);
		KnifeWasChanged = -1;
	}

	return MRES_Ignored;
}

public MRESReturn DHook_IterateAttributesPre(Address pThis, DHookParam hParams)
{
    StoreToAddress(pThis + view_as<Address>(EconViewAttribsOffset), true, NumberType_Int8);
    return MRES_Ignored;
}

public MRESReturn DHook_IterateAttributesPost(Address pThis, DHookParam hParams)
{
    StoreToAddress(pThis + view_as<Address>(EconViewAttribsOffset), false, NumberType_Int8);
    return MRES_Ignored;
} 
