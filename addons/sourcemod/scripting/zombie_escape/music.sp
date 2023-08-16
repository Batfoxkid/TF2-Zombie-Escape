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

#define NO_MUSIC_TIME	-999999

#define DRUM_FILE	"#szf/music/zembat/horde/drums%s.mp3"
static const char DrumSuffix[][] =
{
	"01b",
	"01c",
	"01d",
	"02c",
	"02d",
	"03a",
	"03b",
	"3c",
	"3d",
	"3f",
	"5b",
	"5c",
	"5d",
	"5e",
	"7a",
	"7b",
	"7c",
	"08a",
	"08b",
	"08e",
	"08f",
	"8b",
	"8c",
	"09c",
	"09d",
	"10b",
	"10c",
	"11c",
	"11d"
};

#define VIOLIN_FILE	"#szf/music/zembat/slayer/fiddle/violin_slayer_%s.mp3"
static const char ViolinSuffix[][] =
{
	"01_01a",
	"01_01b",
	"01_01c",
	"01_01d",
	"02_01a",
	"02_01b",
	"02_01c",
	"02_01d",
	"02_01e"
};

#define BANJO_FILE	"#szf/music/zembat/danger/banjo/banjo_%s.mp3"
static const char BanjoSuffix[][] =
{
	"01a_01",
	"01a_02",
	"01a_03",
	"01a_04",
	"01a_05",
	"01a_06",
	"01b_01",
	"01b_03",
	"01b_04",
	"02_01",
	"02_02",
	"02_03",
	"02_04",
	"02_05",
	"02_06",
	"02_07",
	"02_08",
	"02_09",
	"02_10",
	"02_13",
	"02_14",
	"02_15"
};

#define TRUMPET_FILE	"#szf/music/zembat/danger/trumpet/trumpet_danger_02_%02d.mp3"

enum
{
	Theme_ZombieRiot = 1,
	Theme_ZombieFortress
}

static int MusicLevelZombieRiot;
static int MusicLevelZombieFortress;

static int RoundRNG;
static bool NewFullRound = true;
static char CurrentTheme[MAXTF2PLAYERS][PLATFORM_MAX_PATH];
static int NextThemeAt[MAXTF2PLAYERS];
static int NextRabiesAt[MAXTF2PLAYERS];

void Music_PluginStart()
{
	RegZombieCmd("music", Music_Command, "Zombie Escape Music Menu");
}

void Music_MapStart()
{
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/1.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/2.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/3.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/4.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/5.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/6.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/7.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/8.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaulthuman/9.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/1.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/2.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/3.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/4.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/5.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/6.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/7.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/8.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/9.mp3");
	FileNet_PrecacheSound("#zombiesurvival/beats/defaultzombiev2/10.mp3");
	MusicLevelZombieRiot = FileNet_PrecacheSound("#zombiesurvival/lasthuman.mp3");
	
	
	char buffer[PLATFORM_MAX_PATH];
	for(int i; i < sizeof(DrumSuffix); i++)
	{
		FormatEx(buffer, sizeof(buffer), DRUM_FILE, DrumSuffix[i]);
		FileNet_PrecacheSound(buffer);
	}
	for(int i; i < sizeof(ViolinSuffix); i++)
	{
		FormatEx(buffer, sizeof(buffer), VIOLIN_FILE, ViolinSuffix[i]);
		FileNet_PrecacheSound(buffer);
	}
	for(int i; i < sizeof(BanjoSuffix); i++)
	{
		FormatEx(buffer, sizeof(buffer), BANJO_FILE, BanjoSuffix[i]);
		FileNet_PrecacheSound(buffer);
	}
	for(int i = 1; i < 16; i++)
	{
		FormatEx(buffer, sizeof(buffer), TRUMPET_FILE, i);
		FileNet_PrecacheSound(buffer);
	}

	FileNet_PrecacheSound("#szf/music/zembat/slayer/lectric/slayer_01a.mp3");
	FileNet_PrecacheSound("#szf/music/zembat/snare_horde_01_01a.mp3");
	FileNet_PrecacheSound("#szf/music/zembat/snare_horde_01_01b.mp3");
	FileNet_PrecacheSound("#szf/music/contagion/l4d2_rabies_01.mp3");
	FileNet_PrecacheSound("#szf/music/contagion/l4d2_rabies_02.mp3");
	FileNet_PrecacheSound("#szf/music/contagion/l4d2_rabies_03.mp3");
	FileNet_PrecacheSound("#szf/music/contagion/l4d2_rabies_04.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/deadeasy.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/deadlightdistrict.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/deathisacarousel.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/diedonthebayou.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/osweetdeath.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/southofhuman.mp3");
	FileNet_PrecacheSound("#szf/music/stmusic/thesacrifice.mp3");
	FileNet_PrecacheSound("#szf/music/cpmusic/bloodharvestor.mp3");
	FileNet_PrecacheSound("#szf/music/cpmusic/deadairtime.mp3");
	FileNet_PrecacheSound("#szf/music/cpmusic/deathtollcollector.mp3");
	FileNet_PrecacheSound("#szf/music/cpmusic/nomercyforyou.mp3");
	FileNet_PrecacheSound("#szf/music/cpmusic/prayfordeath.mp3");
	FileNet_PrecacheSound("#szf/music/terror/theend.mp3");
	FileNet_PrecacheSound("#szf/music/the_end/skinonourteeth.mp3");
	FileNet_PrecacheSound("#szf/music/undeath/death.mp3");
	MusicLevelZombieFortress = FileNet_PrecacheSound("#szf/music/safe/themonsterswithout.mp3");

	NewFullRound = true;
}

void Music_PluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			StopMusic(client);
	}
}

void Music_RoundSetup()
{
	if(NewFullRound)
		RoundRNG = GetURandomInt();
	
	Music_ForceNextSong(1);
}

// Note: Must be below Gamemode_RoundEnd()
void Music_RoundEnd(int team, bool full_round)
{
	NewFullRound = full_round;
	Music_ForceNextSong(team == TFTeam_Human ? 2 : 3);
}

void Music_PlayerRunCmd(int client)
{
	if(NextThemeAt[client] != NO_MUSIC_TIME && NextThemeAt[client] <= GetTime())
		Music_PlayNextSong(client);
}

void Music_PlayerDeath(int client)
{
	if(!Gamemode_InLastman())
	{
		StopMusic(client);

		if(Client(client).MusicType == Theme_ZombieFortress && Client(client).SoundLevel > MusicLevelZombieFortress)
			PlayMusic(client, "#szf/music/terror/theend.mp3", 1);
	}
}

void Music_ForceNextSong(int type = 0)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		NextThemeAt[client] = (type > 1) ? NO_MUSIC_TIME : 0;
		NextRabiesAt[client] = 0;

		if(IsClientInGame(client))
		{
			StopMusic(client);

			// Zombie Fortress has starting/ending music
			if(Client(client).MusicType == Theme_ZombieFortress && Client(client).SoundLevel > MusicLevelZombieFortress)
			{
				switch(type)
				{
					case 1:	// Round Start
					{
						if(NewFullRound)
						{
							switch(RoundRNG % 7)
							{
								case 0:
									PlayMusic(client, "#szf/music/stmusic/deadeasy.mp3", 94);
								
								case 1:
									PlayMusic(client, "#szf/music/stmusic/deadlightdistrict.mp3", 81);
								
								case 2:
									PlayMusic(client, "#szf/music/stmusic/deathisacarousel.mp3", 84);
								
								case 3:
									PlayMusic(client, "#szf/music/stmusic/diedonthebayou.mp3", 81);
								
								case 4:
									PlayMusic(client, "#szf/music/stmusic/osweetdeath.mp3", 78);
								
								case 5:
									PlayMusic(client, "#szf/music/stmusic/southofhuman.mp3", 118);
								
								default:
									PlayMusic(client, "#szf/music/stmusic/thesacrifice.mp3", 109);
							}
						}
						else	// Multi-stage maps have a "safe room" theme
						{
							switch(RoundRNG % 5)
							{
								case 0:
									PlayMusic(client, "#szf/music/cpmusic/bloodharvestor.mp3", 62);
								
								case 1:
									PlayMusic(client, "#szf/music/cpmusic/deadairtime.mp3", 62);
								
								case 2:
									PlayMusic(client, "#szf/music/cpmusic/deathtollcollector.mp3", 62);
								
								case 3:
									PlayMusic(client, "#szf/music/cpmusic/nomercyforyou.mp3", 62);
								
								default:
									PlayMusic(client, "#szf/music/cpmusic/prayfordeath.mp3", 62);
							}
						}
					}
					case 2:	// Humans Win
					{
						PlayMusic(client, "#szf/music/safe/themonsterswithout.mp3", NO_MUSIC_TIME);
					}
					case 3:	// Humans Lose
					{
						PlayMusic(client, "#szf/music/undeath/death.mp3", NO_MUSIC_TIME);
					}
				}
			}
		}
	}
}

void Music_PlayNextSong(int client)
{
	switch(Client(client).MusicType)
	{
		case Theme_ZombieRiot:
		{
			if(Client(client).SoundLevel <= MusicLevelZombieRiot)
			{
				NextThemeAt[client] = GetTime() + 10;
			}
			else if(Gamemode_InLastman())
			{
				PlayMusic(client, "#zombiesurvival/lasthuman.mp3", 120);
			}
			else if(!IsPlayerAlive(client))
			{
				NextThemeAt[client] = GetTime() + 5;
			}
			else if(AreHumansLosing())
			{
				switch(GetIntensity(client))
				{
					case 0:
					{
						NextThemeAt[client] = GetTime() + 2;
					}
					case 1, 2:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/1.mp3", 6);
					}
					case 3, 4:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/2.mp3", 8);
					}
					case 5, 6:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/3.mp3", 8);
					}
					case 7, 8:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/4.mp3", 8);
					}
					case 9, 10:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/5.mp3", 8);
					}
					case 11, 12:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/6.mp3", 6);
					}
					case 13, 14:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/7.mp3", 6);
					}
					case 15, 16:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/8.mp3", 6);
					}
					case 17, 18:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/9.mp3", 6);
					}
					default:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaultzombiev2/10.mp3", 6);
					}
				}
			}
			else
			{
				switch(GetIntensity(client))
				{
					case 0:
					{
						NextThemeAt[client] = GetTime() + 3;
					}
					case 1, 2:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/1.mp3", 7);
					}
					case 3, 4:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/2.mp3", 7);
					}
					case 5, 6:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/3.mp3", 7);
					}
					case 7, 8:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/4.mp3", 7);
					}
					case 9, 10:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/5.mp3", 6);
					}
					case 11, 12:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/6.mp3", 14);
					}
					case 13, 14:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/7.mp3", 14);
					}
					case 15, 16:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/8.mp3", 7);
					}
					default:
					{
						PlayMusic(client, "#zombiesurvival/beats/defaulthuman/9.mp3", 14);
					}
				}
			}
		}
		case Theme_ZombieFortress:
		{
			if(Client(client).SoundLevel <= MusicLevelZombieFortress)
			{
				NextThemeAt[client] = GetTime() + 10;
			}
			else if(Gamemode_InLastman())
			{
				StopRabies(client);
				PlayMusic(client, "#szf/music/the_end/skinonourteeth.mp3", 96);
			}
			else if(IsPlayerAlive(client))
			{
				TFClassType class;
				if(InCloseCombat(client, class))
				{
					StopRabies(client);

					char buffer[PLATFORM_MAX_PATH];

					switch(class)
					{
						case TFClass_Scout, TFClass_Medic, TFClass_Sniper:
						{
							if(AreHumansLosing())
							{
								FormatEx(buffer, sizeof(buffer), DRUM_FILE, DrumSuffix[GetURandomInt() % sizeof(DrumSuffix)]);
								PlayMusic(client, buffer, 6);
							}
							else
							{
								FormatEx(buffer, sizeof(buffer), TRUMPET_FILE, 1 + (GetURandomInt() % 15));
								PlayMusic(client, buffer, 1);
							}
						}
						case TFClass_Pyro, TFClass_Engineer, TFClass_Spy:
						{
							if(AreHumansLosing())
							{
								FormatEx(buffer, sizeof(buffer), VIOLIN_FILE, ViolinSuffix[GetURandomInt() % sizeof(ViolinSuffix)]);
								PlayMusic(client, buffer, 3);
							}
							else
							{
								PlayMusic(client, "#szf/music/zembat/slayer/lectric/slayer_01a.mp3", 6);
							}
						}
						default:
						{
							if(AreHumansLosing())
							{
								FormatEx(buffer, sizeof(buffer), BANJO_FILE, BanjoSuffix[GetURandomInt() % sizeof(BanjoSuffix)]);
								PlayMusic(client, buffer, 6);
							}
							else if(GetURandomInt() % 2)
							{
								PlayMusic(client, "#szf/music/zembat/snare_horde_01_01a.mp3", 6);
							}
							else
							{
								PlayMusic(client, "#szf/music/zembat/snare_horde_01_01b.mp3", 6);
							}
						}
					}
				}
				else
				{
					int time = GetTime();
					if(NextRabiesAt[client] <= time)
					{
						switch(GetURandomInt() % 4)
						{
							case 0:
								PlayRabies(client, "#szf/music/contagion/l4d2_rabies_01.mp3", 35);
							
							case 1:
								PlayRabies(client, "#szf/music/contagion/l4d2_rabies_02.mp3", 39);
							
							case 2:
								PlayRabies(client, "#szf/music/contagion/l4d2_rabies_03.mp3", 42);
							
							default:
								PlayRabies(client, "#szf/music/contagion/l4d2_rabies_04.mp3", 45);
						}
					}

					NextThemeAt[client] = time + 1;
				}
			}
			else
			{
				NextThemeAt[client] = GetTime() + 5;
			}
		}
		default:
		{
			NextThemeAt[client] = GetTime() + 10;
		}
	}
}

static void PlayMusic(int client, const char[] sound, int time)
{
	strcopy(CurrentTheme[client], sizeof(CurrentTheme[]), sound);
	EmitSoundToClient(client, CurrentTheme[client], _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	NextThemeAt[client] = time == NO_MUSIC_TIME ? NO_MUSIC_TIME : (GetTime() + time);
}

static void PlayRabies(int client, const char[] sound, int time)
{
	strcopy(CurrentTheme[client], sizeof(CurrentTheme[]), sound);
	EmitSoundToClient(client, CurrentTheme[client], _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	NextRabiesAt[client] = time == NO_MUSIC_TIME ? NO_MUSIC_TIME : (GetTime() + time);
}

static void StopMusic(int client)
{
	if(CurrentTheme[client][0])
	{
		StopSound(client, SNDCHAN_STATIC, CurrentTheme[client]);
		StopSound(client, SNDCHAN_STATIC, CurrentTheme[client]);
		CurrentTheme[client][0] = 0;
	}
}

static void StopRabies(int client)
{
	if(CurrentTheme[client][0] && StrContains(CurrentTheme[client], "contagion"))
	{
		StopSound(client, SNDCHAN_STATIC, CurrentTheme[client]);
		StopSound(client, SNDCHAN_STATIC, CurrentTheme[client]);
		CurrentTheme[client][0] = 0;
	}
}

static int GetIntensity(int client)
{
	int intensity;

	float pos1[3], pos2[3];
	GetClientEyePosition(client, pos1);

	for(int target = 1; target <= MaxClients; target++)
	{
		if(target != client && IsClientInGame(target) && GetClientTeam(target) == TFTeam_Zombie && IsPlayerAlive(target))
		{
			GetClientAbsOrigin(target, pos2);

			float distance = GetVectorDistance(pos1, pos2, true);
			if(distance < 1000000.0)	// 1000 HU
			{
				intensity += 2;
			}
			else if(distance < 6250000.0)	// 2500 HU
			{
				intensity++;
			}
		}
	}

	return intensity;
}

static bool InCloseCombat(int client, TFClassType &class)
{
	float pos1[3], pos2[3];
	GetClientEyePosition(client, pos1);
	int team = GetClientTeam(client);

	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && GetClientTeam(target) != team && IsPlayerAlive(target))
		{
			GetClientAbsOrigin(target, pos2);

			if(GetVectorDistance(pos1, pos2, true) < 250000.0)	// 500 HU
			{
				class = TF2_GetPlayerClass(team == TFTeam_Human ? target : client);
				return true;
			}
		}
	}

	return false;
}

static bool AreHumansLosing()
{
	int humans, total;
	
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			switch(GetClientTeam(target))
			{
				case TFTeam_Human:
				{
					total++;

					if(IsPlayerAlive(target))
						humans++;
				}
				case TFTeam_Zombie:
				{
					total++;
				}
			}
		}
	}

	return humans < (total / 2);
}

public Action Music_Command(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	}
	else if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		SetGlobalTransTarget(client);

		char buffer[16];
		GetCmdArg(1, buffer, sizeof(buffer));
		if(buffer[0] == 'o' || buffer[0] == 'O' || buffer[0] == '0')
		{
			Client(client).MusicType = 0;

			StopMusic(client);

			PrintToConsole(client, "[ZE] %t", "Music Turned Off");
		}
		else if(buffer[0] == 'r' || buffer[0] == 'R' || buffer[0] == '1')
		{
			Client(client).MusicType = 1;
			
			StopMusic(client);
			NextThemeAt[client] = 0;
			NextRabiesAt[client] = 0;
			
			PrintToConsole(client, "[ZE] %t", "Music Set", "Music Riot");
		}
		else if(buffer[0] == 's' || buffer[0] == 'S' || buffer[0] == '2')
		{
			Client(client).MusicType = 2;
			
			StopMusic(client);
			NextThemeAt[client] = 0;
			NextRabiesAt[client] = 0;
			
			PrintToConsole(client, "[ZE] %t", "Music Set", "Music Fortress");
		}
		else
		{
			PrintToConsole(client, "[ZE] %t", "Music Unknown Arg", buffer);
		}
	}
	else
	{
		Menu_Command(client);
		Music_Menu(client);
	}
	return Plugin_Handled;
}

void Music_Menu(int client)
{
	Menu menu = new Menu(Music_MenuH);

	SetGlobalTransTarget(client);
	menu.SetTitle("%t", (Client(client).SoundLevel < 1) ? "Music Menu Disabled" : "Music Menu Normal");

	char buffer[64];
	int style = ITEMDRAW_DEFAULT;

	if(Client(client).SoundLevel < 1)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Music Disable");
		style = ITEMDRAW_DISABLED;
	}
	else if(Client(client).MusicType == 0)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "Music Disable", "Music Selected");
		style = ITEMDRAW_DISABLED;
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Music Disable");
	}

	menu.AddItem(NULL_STRING, buffer, style);

	if(Client(client).SoundLevel < 1 || !MusicLevelZombieRiot)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Music Riot");
		style = ITEMDRAW_DISABLED;
	}
	else if(Client(client).SoundLevel <= MusicLevelZombieRiot)
	{
		float progress = float(Client(client).SoundLevel * 100) / float(MusicLevelZombieRiot);
		FormatEx(buffer, sizeof(buffer), "%t %t", "Music Riot", "Music Downloading", progress);
		style = ITEMDRAW_DISABLED;
	}
	else if(Client(client).MusicType == Theme_ZombieRiot)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "Music Riot", "Music Selected");
		style = ITEMDRAW_DISABLED;
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Music Riot");
		style = ITEMDRAW_DEFAULT;
	}

	menu.AddItem(NULL_STRING, buffer, style);

	if(Client(client).SoundLevel < 1 || !MusicLevelZombieFortress)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Music Fortress");
		style = ITEMDRAW_DISABLED;
	}
	else if(Client(client).SoundLevel <= MusicLevelZombieFortress)
	{
		float progress = float((Client(client).SoundLevel - MusicLevelZombieRiot) * 100) / float(MusicLevelZombieFortress - MusicLevelZombieRiot);
		if(progress < 0.0)
			progress = 0.0;
		
		FormatEx(buffer, sizeof(buffer), "%t %t", "Music Fortress", "Music Downloading", progress);
		style = ITEMDRAW_DISABLED;
	}
	else if(Client(client).MusicType == Theme_ZombieFortress)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "Music Fortress", "Music Selected");
		style = ITEMDRAW_DISABLED;
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Music Fortress");
		style = ITEMDRAW_DEFAULT;
	}

	menu.AddItem(NULL_STRING, buffer, style);

	menu.ExitBackButton = Menu_BackButton(client);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Music_MenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			Client(client).MusicType = choice;
			
			StopMusic(client);
			NextThemeAt[client] = 0;
			NextRabiesAt[client] = 0;
			
			Music_Menu(client);
		}
	}
	return 0;
}