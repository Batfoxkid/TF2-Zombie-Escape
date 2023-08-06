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
static bool NoChanges[MAXTF2PLAYERS];
static int MusicType[MAXTF2PLAYERS];
static int SoundLevel[MAXTF2PLAYERS];
static int Damage[MAXTF2PLAYERS][6];
static float Cripple[MAXTF2PLAYERS];

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

	property int SoundLevel
	{
		public get()
		{
			return SoundLevel[view_as<int>(this)];
		}
		public set(int value)
		{
			SoundLevel[view_as<int>(this)] = value;
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

	property int MusicType
	{
		public get()
		{
			return MusicType[view_as<int>(this)];
		}
		public set(int value)
		{
			MusicType[view_as<int>(this)] = value;
		}
	}
	
	property int Damage
	{
		public get()
		{
			return Damage[view_as<int>(this)][0];
		}
		public set(int amount)
		{
			Damage[view_as<int>(this)][0] = amount;
		}
	}
	
	public int GetDamage(int slot)
	{
		return Damage[view_as<int>(this)][slot + 1];
	}
	
	public void SetDamage(int slot, int damage)
	{
		Damage[view_as<int>(this)][slot + 1] = damage;
	}
	
	property float Cripple
	{
		public get()
		{
			return Cripple[view_as<int>(this)];
		}
		public set(float amount)
		{
			Cripple[view_as<int>(this)] = amount;
		}
	}
	
	public void ResetByDeath()
	{
		this.Cripple = 0.0;
	}
	
	public void ResetByRound()
	{
		this.Damage = 0;
		this.SetDamage(TFWeaponSlot_Primary, 0);
		this.SetDamage(TFWeaponSlot_Secondary, 0);
		this.SetDamage(TFWeaponSlot_Melee, 0);
		this.SetDamage(TFWeaponSlot_Grenade, 0);
		this.SetDamage(TFWeaponSlot_Building, 0);
		
		this.ResetByDeath();
	}
	
	public void ResetByAll()
	{
		this.PendingStrip = false;
		this.SoundLevel = 0;
		this.NoChanges = false;
		this.MusicType = 0;
		
		this.ResetByRound();
	}
}