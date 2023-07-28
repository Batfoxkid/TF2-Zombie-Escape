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

static ConfigMap BossMap[MAXTF2PLAYERS] = {null, ...};
static int Queue[MAXTF2PLAYERS];
static bool NoMusic[MAXTF2PLAYERS];
static bool MusicShuffle[MAXTF2PLAYERS];
static bool NoVoice[MAXTF2PLAYERS];
static bool NoChanges[MAXTF2PLAYERS];
static bool NoDmgHud[MAXTF2PLAYERS];
static bool NoHud[MAXTF2PLAYERS];
static char LastPlayed[MAXTF2PLAYERS][64];
static bool Minion[MAXTF2PLAYERS];
static bool Glowing[MAXTF2PLAYERS];
static float GlowFor[MAXTF2PLAYERS];
static float OverlayFor[MAXTF2PLAYERS];
static float RefreshAt[MAXTF2PLAYERS];
static int Damage[MAXTF2PLAYERS][6];
static int TotalDamage[MAXTF2PLAYERS];
static int Assist[MAXTF2PLAYERS];
static int Index[MAXTF2PLAYERS];

methodmap Client
{
	public Client(int client)
	{
		return view_as<Client>(client);
	}
	
	property int Queue
	{
		public get()
		{
			return Queue[view_as<int>(this)];
		}
		public set(int amount)
		{
			Queue[view_as<int>(this)] = amount;
		}
	}
	
	property bool NoMusic
	{
		public get()
		{
			return NoMusic[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoMusic[view_as<int>(this)] = value;
		}
	}
	
	property bool MusicShuffle
	{
		public get()
		{
			return MusicShuffle[view_as<int>(this)];
		}
		public set(bool value)
		{
			MusicShuffle[view_as<int>(this)] = value;
		}
	}
	
	property bool NoVoice
	{
		public get()
		{
			return NoVoice[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoVoice[view_as<int>(this)] = value;
		}
	}
	
	property bool NoChanges
	{
		public get()
		{
			return NoChanges[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoChanges[view_as<int>(this)] = value;
		}
	}
	
	property bool NoDmgHud
	{
		public get()
		{
			return NoDmgHud[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoDmgHud[view_as<int>(this)] = value;
		}
	}
	
	property bool NoHud
	{
		public get()
		{
			return NoHud[view_as<int>(this)];
		}
		public set(bool value)
		{
			NoHud[view_as<int>(this)] = value;
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