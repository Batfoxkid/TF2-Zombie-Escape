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

static bool InMainMenu[MAXTF2PLAYERS];

void Menu_PluginStart()
{
	RegConsoleCmd("ze", Menu_MainMenuCmd, "Zombie Escape Main Menu");
	RegConsoleCmd("zom", Menu_MainMenuCmd, "Zombie Escape Main Menu", FCVAR_HIDDEN);
	RegConsoleCmd("zf", Menu_MainMenuCmd, "Zombie Escape Main Menu", FCVAR_HIDDEN);
	RegConsoleCmd("zombie", Menu_MainMenuCmd, "Zombie Escape Main Menu", FCVAR_HIDDEN);
}

void Menu_Command(int client)
{
	InMainMenu[client] = false;
}

bool Menu_BackButton(int client)
{
	return InMainMenu[client];
}

public Action Menu_MainMenuCmd(int client, int args)
{
	if(!client)
	{
		PrintToServer("Zombie Escape: Open Source (" ... PLUGIN_VERSION_FULL ... ")");
		
		if(Cvar[Debugging].BoolValue)
			PrintToServer("Debug Mode Enabled");
	}
	else if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		PrintToConsole(client, "Zombie Escape: Open Source (" ... PLUGIN_VERSION_FULL ... ")");
		PrintToConsole(client, "%T", "Available Commands", client);
	}
	else
	{
		InMainMenu[client] = true;
		Menu_MainMenu(client);
	}
	return Plugin_Handled;
}

void Menu_MainMenu(int client)
{
	Menu menu = new Menu(Menu_MainMenuH);
	menu.SetTitle("Zombie Escape: Open Source (" ... PLUGIN_VERSION_FULL ... ")\n" ... GITHUB_URL ... "\n ");
	
	char buffer[64];
	SetGlobalTransTarget(client);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Weapon");
	menu.AddItem(NULL_STRING, buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "Command Music");
	menu.AddItem(NULL_STRING, buffer);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_MainMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 0:
				{
					Weapons_ChangeMenu(client);
				}
				case 1:
				{
					//Music_MainMenu(client);
				}
			}
		}
	}
	return 0;
}
