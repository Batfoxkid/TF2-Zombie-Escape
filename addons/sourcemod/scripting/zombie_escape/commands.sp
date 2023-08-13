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

void Command_PluginStart()
{
	AddCommandListener(Command_Voicemenu, "voicemenu");
	AddCommandListener(Command_Spectate, "spectate");
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_AutoTeam, "autoteam");
	AddCommandListener(Command_EurekaTeleport, "eureka_teleport");
}

public Action Command_Voicemenu(int client, const char[] command, int args)
{
	if(client && args == 2 && Client(client).Zombie && IsPlayerAlive(client))
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		if(arg[0] == '0')
		{
			GetCmdArg(2, arg, sizeof(arg));
			if(arg[0] == '0')
			{
				// TODO: Rage
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action Command_Spectate(int client, const char[] command, int args)
{
	return SwapTeam(client, TFTeam_Spectator);
}

public Action Command_AutoTeam(int client, const char[] command, int args)
{
	return SwapTeam(client, TFTeam_Red);
}

public Action Command_JoinTeam(int client, const char[] command, int args)
{
	char buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	int team = TFTeam_Unassigned;
	if(StrEqual(buffer, "red", false))
	{
		team = TFTeam_Red;
	}
	else if(StrEqual(buffer, "blue", false))
	{
		team = TFTeam_Blue;
	}
	else if(StrEqual(buffer, "auto", false))
	{
		return Command_AutoTeam(client, command, args);
	}
	else if(StrEqual(buffer, "spectate", false))
	{
		team = TFTeam_Spectator;
	}
	else
	{
		team = GetClientTeam(client);
	}
	
	return SwapTeam(client, team);
}

static Action SwapTeam(int client, int wantTeam)
{
	Debug("SwapTeam::%N::%d", client, wantTeam);
	
	int newTeam = wantTeam;

	// Prevent going to spectate with cvar disabled
	if(newTeam <= TFTeam_Spectator && !Cvar[AllowSpectators].BoolValue)
		return Plugin_Handled;
	
	if(GameRules_GetRoundState() == RoundState_RoundRunning && !GameRules_GetProp("m_bInSetup"))
	{
		if(IsPlayerAlive(client))
		{
			// Prevent swapping to a different team unless to spec
			if(newTeam > TFTeam_Spectator)
				return Plugin_Handled;
		}
		else
		{
			// Prevent swapping to a different team unless in spec or going to spec
			if(GetClientTeam(client) > TFTeam_Spectator && newTeam > TFTeam_Spectator)
				return Plugin_Handled;
			
			// Manage which team we should assign
			if(newTeam > TFTeam_Spectator)
				newTeam = TFTeam_Zombie;
		}
	}
	else if(newTeam > TFTeam_Spectator)
	{
		newTeam = TFTeam_Human;
	}
	
	ForcePlayerSuicide(client);

	ChangeClientTeam(client, newTeam);
	if(newTeam > TFTeam_Spectator)
		ShowVGUIPanel(client, newTeam == TFTeam_Red ? "class_red" : "class_blue");
	
	Gamemode_PlayerTeam(client);
	return Plugin_Handled;
}

public Action Command_EurekaTeleport(int client, const char[] command, int args)
{
	return Plugin_Handled;
}
