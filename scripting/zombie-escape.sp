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

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <dhooks>
#include <tf2items>
#include <tf2attributes>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION			"1.0"
#define PLUGIN_VERSION_REVISION	"custom"
#define PLUGIN_VERSION_FULL		PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION

#define FOLDER_CONFIGS	"configs/zombie_escape"

#define GITHUB_URL	"github.com/Batfoxkid/TF2-Zombie-Escape"

#define FAR_FUTURE		100000000.0
#define MAXENTITIES		2048
#define MAXTF2PLAYERS	101

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Red			2
#define TFTeam_Blue			3
#define TFTeam_MAX			4

#define TFTeam_Human	TFTeam_Blue
#define TFTeam_Zombie	TFTeam_Red

enum
{
	Version,
	Debugging,
	
	ZombieRatio,
	
	AllowSpectators,
	MovementFreeze,
	PreroundTime,
	//BonusRoundTime,
	Tournament,
	WaitingTime,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

#include "zombie_escape/client.sp"
#include "zombie_escape/stocks.sp"

//#include "zombie_escape/attributes.sp"
#include "zombie_escape/commands.sp"
#include "zombie_escape/configs.sp"
#include "zombie_escape/convars.sp"
//#include "zombie_escape/database.sp"
//#include "zombie_escape/dhooks.sp"
//#include "zombie_escape/econdata.sp"
#include "zombie_escape/events.sp"
#include "zombie_escape/forwards.sp"
#include "zombie_escape/gamemode.sp"
#include "zombie_escape/menu.sp"
#include "zombie_escape/preference.sp"
#include "zombie_escape/sdkcalls.sp"
#include "zombie_escape/sdkhooks.sp"
#include "zombie_escape/steamworks.sp"
//#include "zombie_escape/tf2utils.sp"
//#include "zombie_escape/weapons.sp"

public Plugin myinfo =
{
	name		=	"Zombie Escape: Open Source",
	author		=	"Batfoxkid",
	description	=	"99% less server wars",
	version		=	PLUGIN_VERSION_FULL,
	url			=	GITHUB_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	TF2U_PluginLoad();
	TFED_PluginLoad();
	Weapons_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("zombie_escape.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	if(!TranslationPhraseExists("Prefix"))
		SetFailState("Translation file \"zombie_escape.phrases\" is outdated");
	
	PlayerHud = CreateHudSynchronizer();
	
	Attributes_PluginStart();
	Bosses_PluginStart();
	Command_PluginStart();
	ConVar_PluginStart();
	Database_PluginStart();
	DHook_Setup();
	Events_PluginStart();
	Gamemode_PluginStart();
	Menu_PluginStart();
	Music_PluginStart();
	Preference_PluginStart();
	SDKCall_Setup();
	SDKHook_PluginStart();
	SteamWorks_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	Weapons_PluginStart();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnAllPluginsLoaded()
{
	Configs_AllPluginsLoaded();
}

public void OnMapInit()
{
	Gamemode_MapInit();
}

public void OnMapStart()
{
	Configs_MapStart();
	DHook_MapStart();
	Gamemode_MapStart();
}

public void OnConfigsExecuted()
{
	ConVar_ConfigsExecuted();
	Preference_ConfigsExecuted();
	Weapons_ConfigsExecuted();
}

public void OnMapEnd()
{
	Bosses_MapEnd();
	Gamemode_MapEnd();
	Preference_MapEnd();
}

public void OnPluginEnd()
{
	Bosses_PluginEnd();
	ConVar_Disable();
	Database_PluginEnd();
	DHook_PluginEnd();
	Gamemode_PluginEnd();
	Music_PlaySongToAll();
}

public void OnLibraryAdded(const char[] name)
{
	SDKHook_LibraryAdded(name);
	SteamWorks_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	Weapons_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	SDKHook_LibraryRemoved(name);
	SteamWorks_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	Weapons_LibraryRemoved(name);
}

public void OnClientPutInServer(int client)
{
	DHook_HookClient(client);
	SDKHook_HookClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	Database_ClientPostAdminCheck(client);
}

public void OnClientDisconnect(int client)
{
	Bosses_ClientDisconnect(client);
	Database_ClientDisconnect(client);
	Events_CheckAlivePlayers(client);
	Preference_ClientDisconnect(client);
	
	Client(client).ResetByAll();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	Bosses_PlayerRunCmd(client, buttons);
	Gamemode_PlayerRunCmd(client, buttons);
	Music_PlayerRunCmd(client);
	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(!Client(client).IsBoss || Client(client).Crits || TF2_IsCritBoosted(client))
		return Plugin_Continue;
	
	result = false;
	return Plugin_Changed;
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	Gamemode_ConditionAdded(client, cond);
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	Gamemode_ConditionRemoved(client, cond);
}