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

#tryinclude <cwx>
#tryinclude <tf_custom_attributes>

#pragma semicolon 1
#pragma newdecls required

#define CWX_LIBRARY		"cwx"
#define TCA_LIBRARY		"tf2custattr"
#define FILE_WEAPONS	"configs/zombie_escape/weapons.cfg"

#if defined __cwx_included
static bool CWXLoaded;
#endif

#if defined __tf_custom_attributes_included
static bool TCALoaded;
#endif

static KeyValues WeaponKv;

void Weapons_PluginStatus()
{
	#if defined __tf_econ_data_included
	PrintToServer("SM-TFCustomWeaponsX: %s", CWXLoaded ? "Running" : "Library not running");
	#else
	PrintToServer("SM-TFCustomWeaponsX: Compiled without include \"cwx\"");
	#endif

	#if defined __tf_custom_attributes_included
	PrintToServer("SM-TFCustAttr: %s", TCALoaded ? "Running" : "Library not running");
	#else
	PrintToServer("SM-TFCustAttr: Compiled without include \"tf2custattr\"");
	#endif
}

void Weapons_PluginLoad()
{
	#if defined __tf_custom_attributes_included
	MarkNativeAsOptional("TF2CustAttr_GetAttributeKeyValues");
	MarkNativeAsOptional("TF2CustAttr_GetFloat");
	MarkNativeAsOptional("TF2CustAttr_GetInt");
	MarkNativeAsOptional("TF2CustAttr_SetString");
	#endif
}

void Weapons_PluginStart()
{
	RegZombieCmd("classinfo", Weapons_ChangeMenuCmd, "View Weapon Changes", FCVAR_HIDDEN);
	RegZombieCmd("weapons", Weapons_ChangeMenuCmd, "View Weapon Changes");
	RegZombieCmd("weapon", Weapons_ChangeMenuCmd, "View Weapon Changes", FCVAR_HIDDEN);
	RegAdminCmd("ze_refresh", Weapons_DebugRefresh, ADMFLAG_CHEATS, "Refreshes weapons and attributes");
	RegAdminCmd("ze_reloadweapons", Weapons_DebugReload, ADMFLAG_RCON, "Reloads the weapons config");
	
	#if defined __cwx_included
	CWXLoaded = LibraryExists(CWX_LIBRARY);
	#endif
	
	#if defined __tf_custom_attributes_included
	TCALoaded = LibraryExists(TCA_LIBRARY);
	#endif
}

stock void Weapons_LibraryAdded(const char[] name)
{
	#if defined __cwx_included
	if(!CWXLoaded && StrEqual(name, CWX_LIBRARY))
		CWXLoaded = true;
	#endif
	
	#if defined __tf_custom_attributes_included
	if(!TCALoaded && StrEqual(name, TCA_LIBRARY))
		TCALoaded = true;
	#endif
}

stock void Weapons_LibraryRemoved(const char[] name)
{
	#if defined __cwx_included
	if(CWXLoaded && StrEqual(name, CWX_LIBRARY))
		CWXLoaded = false;
	#endif
	
	#if defined __tf_custom_attributes_included
	if(TCALoaded && StrEqual(name, TCA_LIBRARY))
		TCALoaded = false;
	#endif
}

public Action Weapons_DebugRefresh(int client, int args)
{
	TF2_RemoveAllItems(client);
	
	int entity, i;
	while(TF2_GetWearable(client, entity, i))
	{
		TF2_RemoveWearable(client, entity);
	}
	
	TF2_RegeneratePlayer(client);
	return Plugin_Handled;
}

public Action Weapons_DebugReload(int client, int args)
{
	Weapons_ConfigsExecuted();
	ZReplyToCommand(client, "Reloaded");
	return Plugin_Handled;
}

public Action Weapons_ChangeMenuCmd(int client, int args)
{
	if(client)
	{
		Menu_Command(client);
		Weapons_ChangeMenu(client);
	}
	return Plugin_Handled;
}

void Weapons_ConfigsExecuted()
{
	delete WeaponKv;

	WeaponKv = new KeyValues("Weapons");

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), FILE_WEAPONS);
	WeaponKv.ImportFromFile(buffer);
}

void Weapons_ChangeMenu(int client, int time = MENU_TIME_FOREVER)
{
	if(WeaponKv)
	{
		SetGlobalTransTarget(client);
		
		Menu menu = new Menu(Weapons_ChangeMenuH);
		menu.SetTitle("%t", "Weapon Menu");
		
		static const char SlotNames[][] = { "Primary", "Secondary", "Melee", "PDA", "Utility", "Building", "Action" };
		
		char buffer1[12], buffer2[32];
		for(int i; i < sizeof(SlotNames); i++)
		{
			FormatEx(buffer2, sizeof(buffer2), "%t", SlotNames[i]);
			
			int entity = GetPlayerWeaponSlot(client, i);
			if(entity != -1 && FindWeaponSection(entity, Client(client).Zombie))
			{
				IntToString(EntIndexToEntRef(entity), buffer1, sizeof(buffer1));
				menu.AddItem(buffer1, SlotNames[i]);
			}
			else
			{
				menu.AddItem(buffer1, SlotNames[i], ITEMDRAW_DISABLED);
			}
		}
		
		if(time == MENU_TIME_FOREVER && Menu_BackButton(client))
		{
			FormatEx(buffer2, sizeof(buffer2), "%t", "Back");
			menu.AddItem(buffer1, buffer2);
		}
		else
		{
			menu.AddItem(buffer1, buffer1, ITEMDRAW_SPACER);
		}
		
		FormatEx(buffer2, sizeof(buffer2), "%t", Client(client).NoChanges ? "Enable Weapon Changes" : "Disable Weapon Changes");
		menu.AddItem(buffer1, buffer2);
		
		menu.Pagination = 0;
		menu.ExitButton = true;
		menu.Display(client, time);
	}
}

public int Weapons_ChangeMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
				Menu_MainMenu(client);
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 7:
				{
					Menu_MainMenu(client);
				}
				case 8:
				{
					Client(client).NoChanges = !Client(client).NoChanges;
					Weapons_ChangeMenu(client);
				}
				default:
				{
					char buffer[12];
					menu.GetItem(choice, buffer, sizeof(buffer));
					int entity = EntRefToEntIndex(StringToInt(buffer));
					if(entity != INVALID_ENT_REFERENCE)
						Weapons_ShowChanges(client, entity);
					
					Weapons_ChangeMenu(client);
				}
			}
		}
	}
	return 0;
}

void Weapons_ShowChanges(int client, int entity)
{
	if(!WeaponKv)
		return;
	
	if(!FindWeaponSection(entity, Client(client).Zombie))
		return;

	int itemDefIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

	char localizedWeaponName[64];
	GetEntityClassname(entity, localizedWeaponName, sizeof(localizedWeaponName));

	if(!TF2ED_GetLocalizedItemName(itemDefIndex, localizedWeaponName, sizeof(localizedWeaponName), localizedWeaponName))
		return;

	SetGlobalTransTarget(client);
	
	char buffer2[64];
	
	if(WeaponKv.GetNum("strip"))
	{
		Format(buffer2, sizeof(buffer2), "%t%%s3 (%t):", "Prefix", "Weapon Stripped");
		CReplaceColorCodes(buffer2, client, _, sizeof(buffer2));
		PrintSayText2(client, client, true, buffer2, _, _, localizedWeaponName);
	}
	else
	{
		Format(buffer2, sizeof(buffer2), "%t%%s3:", "Prefix");
		CReplaceColorCodes(buffer2, client, _, sizeof(buffer2));
		PrintSayText2(client, client, true, buffer2, _, _, localizedWeaponName);
	}

	char value[16];
	char description[64];
	char type[32];

	if(WeaponKv.JumpToKey("attributes"))
	{
		if(WeaponKv.GotoFirstSubKey(false))
		{
			do
			{
				WeaponKv.GetSectionName(description, sizeof(description));
				WeaponKv.GetString(NULL_STRING, value, sizeof(value));

				int attrib = TF2ED_TranslateAttributeNameToDefinitionIndex(description);
				if(attrib != -1)
				{
					bool isHidden = (TF2ED_GetAttributeDefinitionString(attrib, "hidden", type, sizeof(type)) && StringToInt(type));
					bool doesDescriptionExist = TF2ED_GetAttributeDefinitionString(attrib, "description_string", description, sizeof(description));

					if(value[0] != 'R' && !isHidden && doesDescriptionExist)
					{
						TF2ED_GetAttributeDefinitionString(attrib, "description_format", type, sizeof(type));
						FormatValue(value, value, sizeof(value), type);
						PrintSayText2(client, client, true, description, value);
					}
				}
			}
			while(WeaponKv.GotoNextKey(false));
			
			WeaponKv.GoBack();
		}

		if(WeaponKv.JumpToKey("custom") && WeaponKv.GotoFirstSubKey(false))
		{
			char key[64], data[256];
			do
			{
				WeaponKv.GetSectionName(key, sizeof(key));
				if(TranslationPhraseExists(key))
				{
					WeaponKv.GetString(NULL_STRING, data, sizeof(data));
					FormatValue(data, value, sizeof(value), "value_is_percentage");
					FormatValue(data, description, sizeof(description), "value_is_inverted_percentage");
					FormatValue(data, type, sizeof(type), "value_is_additive_percentage");
					PrintToChat(client, "%t", key, value, description, type, data);
				}
			}
			while(WeaponKv.GotoNextKey(false));
		}
	}
}

static void FormatValue(const char[] value, char[] buffer, int length, const char[] type)
{
	if(StrEqual(type, "value_is_percentage"))
	{
		float val = StringToFloat(value);
		if(val < 1.0 && val > -1.0)
		{
			Format(buffer, length, "%.0f", -(100.0 - (val * 100.0)));
		}
		else
		{
			Format(buffer, length, "%.0f", val * 100.0 - 100.0);
		}
	}
	else if(StrEqual(type, "value_is_inverted_percentage"))
	{
		float val = StringToFloat(value);
		if(val < 1.0 && val > -1.0)
		{
			Format(buffer, length, "%.0f", (100.0 - (val * 100.0)));
		}
		else
		{
			Format(buffer, length, "%.0f", val * 100.0 - 100.0);
		}
	}
	else if(StrEqual(type, "value_is_additive_percentage"))
	{
		float val = StringToFloat(value);
		Format(buffer, length, "%.0f", val * 100.0);
	}
	else if(StrEqual(type, "value_is_particle_index") || StrEqual(type, "value_is_from_lookup_table"))
	{
		buffer[0] = 0;
	}
	else
	{
		strcopy(buffer, length, value);
	}
}

#if defined __tf_custom_attributes_included
static void ApplyCustomAttributes(int entity)
{
	if(TCALoaded && WeaponKv.GotoFirstSubKey(false))
	{
		char key[64], value[256];
		do
		{
			WeaponKv.GetSectionName(key, sizeof(key));
			WeaponKv.GetString(NULL_STRING, value, sizeof(value));
			TF2CustAttr_SetString(entity, key, value);
		}
		while(WeaponKv.GotoNextKey(false));

		WeaponKv.GoBack();
	}
}
#endif

void Weapons_EntityCreated(int entity, const char[] classname)
{
	if(WeaponKv && (!StrContains(classname, "tf_wea") || !StrContains(classname, "tf_powerup_bottle")))
		SDKHook(entity, SDKHook_SpawnPost, Weapons_Spawn);
}

public void Weapons_Spawn(int entity)
{
	RequestFrame(Weapons_SpawnFrame, EntIndexToEntRef(entity));
}

public void Weapons_SpawnFrame(int ref)
{
	if(!WeaponKv)
		return;
	
	int entity = EntRefToEntIndex(ref);
	if(entity == INVALID_ENT_REFERENCE)
		return;
	
	if((HasEntProp(entity, Prop_Send, "m_bDisguiseWearable") && GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")) ||
		(HasEntProp(entity, Prop_Send, "m_bDisguiseWeapon") && GetEntProp(entity, Prop_Send, "m_bDisguiseWeapon")))
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client < 1 || client > MaxClients)
		return;
	
	if(!FindWeaponSection(entity, Client(client).Zombie))
		return;
	
	if(WeaponKv.GetNum("strip"))
		DHook_HookStripWeapon(entity);
	
	int current = WeaponKv.GetNum("clip", -1);
	if(current >= 0)
	{
		if(HasEntProp(entity, Prop_Data, "m_iClip1"))
			SetEntProp(entity, Prop_Data, "m_iClip1", current);
	}
	
	current = WeaponKv.GetNum("ammo", -1);
	if(current >= 0)
	{
		if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
		{
			int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
			if(type >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", current, _, type);
		}
	}
	
	char name[64];

	if(WeaponKv.JumpToKey("attributes"))
	{
		if(WeaponKv.GotoFirstSubKey(false))
		{
			do
			{
				WeaponKv.GetSectionName(name, sizeof(name));
				TF2Attrib_SetByName(entity, name, WeaponKv.GetFloat(NULL_STRING));
			}
			while(WeaponKv.GotoNextKey(false));
			WeaponKv.GoBack();
		}
	
		#if defined __tf_custom_attributes_included
		if(WeaponKv.JumpToKey("custom"))
			ApplyCustomAttributes(entity);
		#endif
	}
}

static bool FindWeaponSection(int entity, bool zombie)
{
	WeaponKv.Rewind();
	WeaponKv.JumpToKey(zombie ? "Zombie" : "Human");

	char buffer1[64];
	
	#if defined __cwx_included
	if(CWXLoaded && CWX_GetItemUIDFromEntity(entity, buffer1, sizeof(buffer1)) && CWX_IsItemUIDValid(buffer1))
	{
		return (WeaponKv.JumpToKey("CWX") && WeaponKv.JumpToKey(buffer1));
	}
	#endif
	
	if(WeaponKv.JumpToKey("Indexes"))
	{
		if(WeaponKv.GotoFirstSubKey())
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			char buffer2[12];

			do
			{
				WeaponKv.GetSectionName(buffer1, sizeof(buffer1));
				
				bool found;
				int current;
				do
				{
					int add = SplitString(buffer1[current], " ", buffer2, sizeof(buffer2));
					found = add != -1;
					if(found)
					{
						current += add;
					}
					else
					{
						strcopy(buffer2, sizeof(buffer2), buffer1[current]);
					}
					
					if(StringToInt(buffer2) == index)
						return true;
				}
				while(found);
			}
			while(WeaponKv.GotoNextKey());

			WeaponKv.GoBack();
		}

		WeaponKv.GoBack();
	}
	
	if(WeaponKv.JumpToKey("Classnames"))
	{
		GetEntityClassname(entity, buffer1, sizeof(buffer1));
		if(WeaponKv.JumpToKey(buffer1))
			return true;
	}

	return false;
}