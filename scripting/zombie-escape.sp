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
#define PLUGIN_VERSION_FULL		"Riot " ... PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION

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
	NextCharset,
	Debugging,
	
	AggressiveOverlay,
	AggressiveSwap,

	SubpluginFolder,
	FileCheck,
	
	SoundType,
	BossTriple,
	BossCrits,
	BossHealing,
	BossKnockback,
	
	BossVsBoss,
	SpecTeam,
	CaptureTime,
	CaptureAlive,
	HealthBar,
	RefreshDmg,
	RefreshTime,
	DisguiseModels,
	PlayerGlow,
	BossSewer,
	Telefrags,
	
	PrefBlacklist,
	PrefToggle,
	PrefSpecial,
	
	AllowSpectators,
	MovementFreeze,
	PreroundTime,
	//BonusRoundTime,
	Tournament,
	WaitingTime,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

int PlayersAlive[TFTeam_MAX];
int MaxPlayersAlive[TFTeam_MAX];
int Charset;
bool Enabled;
int RoundStatus;
bool PluginsEnabled;
Handle PlayerHud;
Handle ThisPlugin;

#include "zombie_escape/client.sp"
#include "zombie_escape/stocks.sp"

#include "freak_fortress_2/attributes.sp"
#include "freak_fortress_2/bosses.sp"
#include "freak_fortress_2/commands.sp"
#include "freak_fortress_2/configs.sp"
#include "freak_fortress_2/convars.sp"
#include "freak_fortress_2/database.sp"
#include "freak_fortress_2/dhooks.sp"
#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/events.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/forwards.sp"
#include "freak_fortress_2/forwards_old.sp"
#include "freak_fortress_2/gamemode.sp"
#include "freak_fortress_2/goomba.sp"
#include "freak_fortress_2/menu.sp"
#include "freak_fortress_2/music.sp"
#include "freak_fortress_2/natives.sp"
#include "freak_fortress_2/natives_old.sp"
#include "freak_fortress_2/preference.sp"
#include "freak_fortress_2/sdkcalls.sp"
#include "freak_fortress_2/sdkhooks.sp"
#include "freak_fortress_2/steamworks.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/weapons.sp"

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
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if(Configs_SetMap(mapname))
	{
		Charset = Cvar[NextCharset].IntValue;
	}
	else
	{
		Charset = -1;
	}
	
	Bosses_BuildPacks(Charset, mapname);
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