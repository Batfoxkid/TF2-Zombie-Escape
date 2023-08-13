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

#define DATABASE				"zombie_escape"
#define DATATABLE_GENERAL		"ze_data"

static Database DataBase;
static bool Cached[MAXTF2PLAYERS];
static int StartTime[MAXTF2PLAYERS];

void DataBase_PluginStatus()
{
	if(DataBase)
	{
		char buffer[64];
		DataBase.Driver.GetIdentifier(buffer, sizeof(buffer));
		PrintToServer("Database: Running %s", buffer);
	}
	else
	{
		PrintToServer("Database: Failed, see error logs for message");
	}
}

void Database_PluginStart()
{
	if(SQL_CheckConfig(DATABASE))
	{
		Database.Connect(Database_Connected, DATABASE);
	}
	else
	{
		char error[512];
		Database db = SQLite_UseDatabase(DATABASE, error, sizeof(error));
		Database_Connected(db, error, 0);
	}
}

public void Database_Connected(Database db, const char[] error, any data)
{
	if(db)
	{
		Transaction tr = new Transaction();
		
		tr.AddQuery("CREATE TABLE IF NOT EXISTS " ... DATATABLE_GENERAL ... " ("
		... "steamid INTEGER PRIMARY KEY, "
		... "weapon_changes INTEGER NOT NULL DEFAULT 1, "
		... "music_type INTEGER NOT NULL DEFAULT 0);");
		
		db.Execute(tr, Database_SetupCallback, Database_FailHandle, db);
	}
	else
	{
		LogError("[Database] %s", error);
	}
}

public void Database_SetupCallback(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	DataBase = data;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientAuthorized(client))
			Database_ClientPostAdminCheck(client);
	}
}

void Database_PluginEnd()
{
	if(DataBase)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				Database_ClientDisconnect(client, DBPrio_High);
		}
	}
}

void Database_ClientPostAdminCheck(int client)
{
	if(DataBase && !IsFakeClient(client))
	{
		int id = GetSteamAccountID(client);
		if(id)
		{
			StartTime[client] = GetTime();
			
			Transaction tr = new Transaction();
			
			char buffer[256];
			FormatEx(buffer, sizeof(buffer), "SELECT * FROM " ... DATATABLE_GENERAL ... " WHERE steamid = %d;", id);
			tr.AddQuery(buffer);
			
			DataBase.Execute(tr, Database_ClientSetup, Database_Fail, GetClientUserId(client));
		}
	}
}

public void Database_ClientSetup(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		char buffer[256];
		Transaction tr;
		if(results[0].FetchRow())
		{
			Client(client).NoChanges = !results[0].FetchInt(1);
			Client(client).MusicType = results[0].FetchInt(2);
		}
		else if(!results[0].MoreRows)
		{
			tr = new Transaction();
			
			FormatEx(buffer, sizeof(buffer), "INSERT INTO " ... DATATABLE_GENERAL ... " (steamid) VALUES (%d)", GetSteamAccountID(client));
			tr.AddQuery(buffer);	
		}
		
		if(tr)
		{
			DataBase.Execute(tr, Database_Success, Database_Fail);
		}
		else if(IsClientInGame(client) && StartTime[client] > (GetTime() + 200))	// Slow databases, notify the player
		{
			ZPrintToChat(client, "%t", "Preference Updated");
		}
		
		Cached[client] = true;

		Music_ClientCached(client);
	}
}

void Database_ClientDisconnect(int client, DBPriority priority = DBPrio_Normal)
{
	if(DataBase && !IsFakeClient(client) && Cached[client])
	{
		int id = GetSteamAccountID(client);
		if(id)
		{
			Transaction tr = new Transaction();
			
			char buffer[256];

			DataBase.Format(buffer, sizeof(buffer), "UPDATE " ... DATATABLE_GENERAL ... " SET "
			... "weapon_changes = %d, "
			... "music_type = %d "
			... "WHERE steamid = %d;",
			!Client(client).NoChanges,
			Client(client).MusicType,
			id);
			
			tr.AddQuery(buffer);
			
			DataBase.Execute(tr, Database_Success, Database_Fail, _, priority);
		}
	}
	
	Cached[client] = false;
}

public void Database_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
}

public void Database_Fail(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[Database] %s", error);
}

public void Database_FailHandle(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[Database] %s", error);
	CloseHandle(data);
}