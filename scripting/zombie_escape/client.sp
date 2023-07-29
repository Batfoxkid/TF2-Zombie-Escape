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

static bool PendingStrip[MAXTF2PLAYERS];

methodmap Client
{
	public Client(int client)
	{
		return view_as<Client>(client);
	}

	property bool Zombie
	{
		public get()
		{
			return GetClientTeam(view_as<int>(this)) == TFTeam_Zombie;
		}
	}

	property bool Human
	{
		public get()
		{
			return GetClientTeam(view_as<int>(this)) == TFTeam_Human;
		}
	}
	
	property bool PendingStrip
	{
		public get()
		{
			return PendingStrip[view_as<int>(this)];
		}
		public set(bool value)
		{
			PendingStrip[view_as<int>(this)] = value;
		}
	}
	
	public void ResetByDeath()
	{
		this.GlowFor = 0.0;
		this.Minion = false;
	}
	
	public void ResetByRound()
	{
		this.Damage = 0;
		this.Assist = 0;
		this.TotalDamage = 0;
		this.SetDamage(TFWeaponSlot_Primary, 0);
		this.SetDamage(TFWeaponSlot_Secondary, 0);
		this.SetDamage(TFWeaponSlot_Melee, 0);
		this.SetDamage(TFWeaponSlot_Grenade, 0);
		this.SetDamage(TFWeaponSlot_Building, 0);
		
		this.ResetByDeath();
	}
	
	public void ResetByAll()
	{
		this.Queue = 0;
		this.NoMusic = false;
		this.MusicShuffle = false;
		this.NoVoice = false;
		this.NoDmgHud = false;
		this.NoHud = false;
		this.SetLastPlayed(NULL_STRING);
		this.OverlayFor = 0.0;
		this.GlowFor = 0.0;
		this.Glowing = false;
		
		this.ResetByRound();
	}
}