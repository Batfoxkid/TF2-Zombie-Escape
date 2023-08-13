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

#tryinclude <SteamWorks> 

#pragma semicolon 1
#pragma newdecls required

#define STEAMWORKS_LIBRARY	"SteamWorks"

#if defined _SteamWorks_Included
static bool Loaded;
#endif

void SteamWorks_PluginStatus()
{
	#if defined __tf_econ_data_included
	PrintToServer("SteamWorks: %s", Loaded ? "Running" : "Library not running");
	#else
	PrintToServer("SteamWorks: Compiled without include \"SteamWorks\"");
	#endif
}

void SteamWorks_PluginStart()
{
	#if defined _SteamWorks_Included
	Loaded = LibraryExists(STEAMWORKS_LIBRARY);
	#endif
}

stock void SteamWorks_LibraryAdded(const char[] name)
{
	#if defined _SteamWorks_Included
	if(!Loaded && StrEqual(name, STEAMWORKS_LIBRARY))
	{
		Loaded = true;
		SteamWorks_SetGameTitle();
	}
	#endif
}

stock void SteamWorks_LibraryRemoved(const char[] name)
{
	#if defined _SteamWorks_Included
	if(Loaded && StrEqual(name, STEAMWORKS_LIBRARY))
		Loaded = false;
	#endif
}

stock void SteamWorks_SetGameTitle()
{
	#if defined _SteamWorks_Included
	if(Loaded)
		SteamWorks_SetGameDescription("Zombie Escape: Open Source (" ... PLUGIN_VERSION_FULL ... ")");
	#endif
}