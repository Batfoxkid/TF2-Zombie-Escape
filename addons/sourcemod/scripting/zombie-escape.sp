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

enum
{
	Version,
	Debugging,

	PointCommand,
	
	ZombieRatio,
	CrippleDecay,
	CrippleHuman,
	CrippleMax,
	ShieldMax,
	ShieldDecay,
	CrippleSpeed,

	ZombieHealth,
	ZombieUpward,
	ZombieStunStart,
	ZombieStunSpawn,
	ZombieSlots,
	
	AllowSpectators,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

int TFTeam_Human = TFTeam_Blue;
int TFTeam_Zombie = TFTeam_Red;

#include "zombie_escape/client.sp"
#include "zombie_escape/stocks.sp"

#include "zombie_escape/attributes.sp"
#include "zombie_escape/commands.sp"
#include "zombie_escape/convars.sp"
#include "zombie_escape/database.sp"
#include "zombie_escape/dhooks.sp"
#include "zombie_escape/econdata.sp"
#include "zombie_escape/events.sp"
#include "zombie_escape/filenetwork.sp"
#include "zombie_escape/gamemode.sp"
#include "zombie_escape/map.sp"
#include "zombie_escape/menu.sp"
#include "zombie_escape/music.sp"
#include "zombie_escape/sdkcalls.sp"
#include "zombie_escape/sdkhooks.sp"
#include "zombie_escape/steamworks.sp"
#include "zombie_escape/weapons.sp"

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
	
	Command_PluginStart();
	ConVar_PluginStart();
	Database_PluginStart();
	DHook_Setup();
	Events_PluginStart();
	FileNet_PluginStart();
	Gamemode_PluginStart();
	Map_PluginStart();
	Menu_PluginStart();
	Music_PluginStart();
	SDKCall_Setup();
	SDKHook_PluginStart();
	SteamWorks_PluginStart();
	TFED_PluginStart();
	Weapons_PluginStart();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));
	GetMapDisplayName(buffer, buffer, sizeof(buffer));
	if(!StrContains(buffer, "ze_", false))
	{
		// Zombie Escape maps are Red Zombies
		TFTeam_Human = TFTeam_Blue;
		TFTeam_Zombie = TFTeam_Red;
	}
	else
	{
		// Other maps will be Blue Zombies
		TFTeam_Human = TFTeam_Red;
		TFTeam_Zombie = TFTeam_Blue;
	}

	DHook_MapStart();
	Music_MapStart();
}

public void OnConfigsExecuted()
{
	ConVar_ConfigsExecuted();
	Weapons_ConfigsExecuted();
}

public void OnMapEnd()
{
	Attributes_MapEnd();
	FileNet_MapEnd();
	Map_MapEnd();
}

public void OnPluginEnd()
{
	ConVar_PluginEnd();
	Database_PluginEnd();
	DHook_PluginEnd();
	Music_PluginEnd();
}

public void OnLibraryAdded(const char[] name)
{
	FileNet_LibraryAdded(name);
	SDKHook_LibraryAdded(name);
	SteamWorks_LibraryAdded(name);
	TFED_LibraryAdded(name);
	Weapons_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	FileNet_LibraryRemoved(name);
	SDKHook_LibraryRemoved(name);
	SteamWorks_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	Weapons_LibraryRemoved(name);
}

public void OnClientPutInServer(int client)
{
	DHook_HookClient(client);
	FileNet_ClientPutInServer(client);
	SDKHook_HookClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	Database_ClientPostAdminCheck(client);
}

public void OnClientDisconnect(int client)
{
	Database_ClientDisconnect(client);
	Gamemode_ClientDisconnect(client);
	FileNet_ClientDisconnect(client);
	Map_ClientDisconnect(client);
	
	Client(client).ResetByAll();
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	Map_PlayerRunCmdPost(client, angles);
	Music_PlayerRunCmdPost(client);
}
