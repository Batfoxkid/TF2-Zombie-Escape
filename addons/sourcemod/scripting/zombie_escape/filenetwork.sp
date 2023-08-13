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

#tryinclude <filenetwork>

#define FILENET_LIBRARY	"filenetwork"

#if defined _filenetwork_included
static bool Loaded;

static bool StartedQueue[MAXTF2PLAYERS];
static bool Downloading[MAXTF2PLAYERS];

static ArrayList SoundList;
#endif

void FileNet_PluginStatus()
{
	#if defined _filenetwork_included
	PrintToServer("File-Network: %s", Loaded ? "Running" : "Library not running");
	#else
	PrintToServer("File-Network: Compiled without include \"filenetwork\"");
	#endif
}

void FileNet_PluginStart()
{
	#if defined _filenetwork_included
	SoundList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	#endif
}

stock void FileNet_LibraryAdded(const char[] name)
{
	#if defined _filenetwork_included
	if(!Loaded && StrEqual(name, FILENET_LIBRARY))
	{
		Loaded = true;

		for(int client = 1; client <= MaxClients; client++)
		{
			if(StartedQueue[client] && !Downloading[client])
				SendNextFile(client);
		}
	}
	#endif
}

stock void FileNet_LibraryRemoved(const char[] name)
{
	#if defined _filenetwork_included
	if(Loaded && StrEqual(name, FILENET_LIBRARY))
		Loaded = false;
	#endif
}

void FileNet_MapEnd()
{
	#if defined _filenetwork_included
	delete SoundList;

	FileNet_PluginStart();
	#endif
}

void FileNet_ClientPutInServer(int client)
{
	#if defined _filenetwork_included
	FileNet_ClientDisconnect(client);
	SendNextFile(client);
	#else
	QueryClientConVar(client, "cl_allowdownload", FileNet_QueryAllowDownload);
	#endif
}

stock void FileNet_ClientDisconnect(int client)
{
	#if defined _filenetwork_included
	StartedQueue[client] = false;
	Downloading[client] = false;
	#endif
}

int FileNet_PrecacheSound(const char[] sound)
{
	#if defined _filenetwork_included
	PrecacheSound(sound);
	return AddSoundFile(sound);
	#else
	char download[PLATFORM_MAX_PATH];
	FormatEx(download, sizeof(download), "sound/%s", sound[sound[0] == '#' ? 1 : 0]);
	AddFileToDownloadsTable(download);
	return 0;
	#endif
}

#if defined _filenetwork_included
static int AddSoundFile(const char[] sound)
{
	int index = SoundList.FindString(sound);
	if(index == -1)
	{
		index = SoundList.PushString(sound);

		for(int client = 1; client <= MaxClients; client++)
		{
			if(StartedQueue[client] && !Downloading[client])
				SendNextFile(client);
		}
	}

	return index;
}

static void FormatFileCheck(const char[] file, int client, char[] output, int length)
{
	strcopy(output, length, file);
	ReplaceString(output, length, ".", "");
	Format(output, length, "%s_%d.txt", output, GetSteamAccountID(client, false));
}

static void SendNextFile(int client)
{
	// First, request a dummy file to see if they have it downloaded before

	StartedQueue[client] = true;
	
	if(Loaded)
	{
		static char download[PLATFORM_MAX_PATH];
		DataPack pack;

		if(Client(client).SoundLevel < SoundList.Length)
		{
			SoundList.GetString(Client(client).SoundLevel, download, sizeof(download));
			Format(download, sizeof(download), "sound/%s", download[download[0] == '#' ? 1 : 0]);
			
			pack = new DataPack();
		}

		if(pack)
		{
			Downloading[client] = true;

			pack.WriteString(download);
			
			static char filecheck[PLATFORM_MAX_PATH];
			FormatFileCheck(download, client, filecheck, sizeof(filecheck));
			FileNet_RequestFile(client, filecheck, FileNet_RequestResults, pack);

			if(!DeleteFile(filecheck, true))	// There has been some cases where we still have a file (Eg. plugin unload)
			{
				Format(filecheck, sizeof(filecheck), "download/%s", filecheck);
				DeleteFile(filecheck);
			}
		}
		else
		{
			Downloading[client] = false;
		}
	}
}

public void FileNet_RequestResults(int client, const char[] file, int id, bool success, DataPack pack)
{
	// If not found, send the actual file

	if(success)
	{
		if(!DeleteFile(file, true))
		{
			static char filecheck[PLATFORM_MAX_PATH];
			Format(filecheck, sizeof(filecheck), "download/%s", file);
			if(!DeleteFile(filecheck))
				LogError("Failed to delete file \"%s\"", file);
		}
	}

	if(StartedQueue[client])
	{
		static char download[PLATFORM_MAX_PATH];
		pack.Reset();
		pack.ReadString(download, sizeof(download));

		if(success)
		{
			Client(client).SoundLevel++;
			SendNextFile(client);
		}
		else
		{
			// So the client doesn't freak out about existing CreateFragmentsFromFile spam
			PrintToConsole(client, "[ZE] Downloading '%s'", download);
			if(FileNet_SendFile(client, download, FileNet_SendResults, pack))
				return;
			
			LogError("Failed to queue file \"%s\" to client", download);
		}
	}

	delete pack;
}

public void FileNet_SendResults(int client, const char[] file, bool success, DataPack pack)
{
	// When done, send a dummy file and the next file in queue
	
	if(StartedQueue[client])
	{
		if(success)
		{
			static char filecheck[PLATFORM_MAX_PATH];
			FormatFileCheck(file, client, filecheck, sizeof(filecheck));

			File filec = OpenFile(filecheck, "wt");
			filec.WriteLine("Used for file checks for ZR/RPG/ZE");
			filec.Close();

			if(!FileNet_SendFile(client, filecheck, FileNet_SendFileCheck))
			{
				LogError("Failed to queue file \"%s\" to client", filecheck);
				if(!DeleteFile(filecheck))
					LogError("Failed to delete file \"%s\"", filecheck);
			}

			Client(client).SoundLevel++;
			SendNextFile(client);
		}
		else
		{
			LogError("Failed to send file \"%s\" to client", file);
		}
	}

	delete pack;
}

public void FileNet_SendFileCheck(int client, const char[] file, bool success)
{
	// Delete the dummy file left over

	if(StartedQueue[client] && !success)
		LogError("Failed to send file \"%s\" to client", file);
	
	if(!DeleteFile(file))
		LogError("Failed to delete file \"%s\"", file);
}

#else

public void FileNet_QueryAllowDownload(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if(IsClientInGame(client) && result == ConVarQuery_Okay && !StringToInt(cvarValue))
	{
		QueryClientConVar(client, "sv_allowupload", FileNet_QueryAllowUpload);
	}
}

public void FileNet_QueryAllowUpload(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if(IsClientInGame(client) && result == ConVarQuery_Okay && !StringToInt(cvarValue))
	{
		QueryClientConVar(client, "cl_downloadfilter", FileNet_QueryFilter);
	}
}

public void FileNet_QueryFilter(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if(IsClientInGame(client) && result == ConVarQuery_Okay && StrContains("all", cvarValue) != -1)
	{
		Client(client).SoundLevel = 1;
	}
}
#endif
