 public PlVers:__version =
{
	version = 5,
	filevers = "1.3.6",
	date = "03/20/2011",
	time = "16:50:00"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "sdkhooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new Float:PreviousPunchAngle[65][3];
new BurstShotsFired[65];
new ModeStateArray[65][2];
new ProcessArray[65][4];
new bool:IsAdmin[65];
new g_iBunnyhop[65];
new g_iNoFlash[65];
new g_iFlashAlpha = -1;
new Float:TakeDmg[65];
new Float:ChanceToTakeDmg[65];
new Triggerbot[65];
new Aimbot[65];
new AimbotMulti[65];
new OnAttack[65];
new NoFallDmg[65];
new Float:aFov[65];
new Float:Speedhack[65];
new Float:Smooth[65];
new Float:AimChance[65];
new Handle:WeaponTypeTrie;
new Handle:WeaponZoomSpeedTrie;
new AimPos[65];
new AimT[65];
new All[65][14];
new Float:HeadChance[65];
new HeadChanceF[65];
new Float:view_angles[65][3];
new aimbot_event;
public Plugin:myinfo =
{
	name = "Basic Chat",
	description = "",
	author = "AlliedModders LLC",
	version = "1.3.61",
	url = ""
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

Float:operator-(Float:)(Float:oper)
{
	return oper ^ 0;
}

Float:operator*(Float:,_:)(Float:oper1, oper2)
{
	return oper1 * float(oper2);
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) == 0;
}

bool:operator!=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) != 0;
}

bool:operator!=(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) != 0;
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) > 0;
}

bool:operator>=(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) >= 0;
}

bool:operator>=(Float:,_:)(Float:oper1, oper2)
{
	return FloatCompare(oper1, float(oper2)) >= 0;
}

bool:operator<(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) < 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

StrCat(String:buffer[], maxlength, String:source[])
{
	new len = strlen(buffer);
	if (len >= maxlength)
	{
		return 0;
	}
	return Format(buffer[len], maxlength - len, "%s", source);
}

GetEntDataArray(entity, offset, array[], arraySize, dataSize)
{
	new i;
	while (i < arraySize)
	{
		array[i] = GetEntData(entity, dataSize * i + offset, dataSize);
		i++;
	}
	return 0;
}

SetEntDataArray(entity, offset, array[], arraySize, dataSize, bool:changeState)
{
	new i;
	while (i < arraySize)
	{
		SetEntData(entity, dataSize * i + offset, array[i], dataSize, changeState);
		i++;
	}
	return 0;
}

GetEntityFlags(entity)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_fFlags", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_fFlags");
		}
		gotconfig = true;
	}
	return GetEntProp(entity, PropType:1, datamap, 4);
}

GetClientButtons(client)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nButtons", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_nButtons");
		}
		gotconfig = true;
	}
	return GetEntProp(client, PropType:1, datamap, 4);
}

EmitSoundToAll(String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[MaxClients];
	new total;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			total++;
			clients[total] = i;
		}
		i++;
	}
	if (!total)
	{
		return 0;
	}
	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}

public OnPluginStart()
{
	WeaponTypeTrie = CreateTrie();
	WeaponZoomSpeedTrie = CreateTrie();
	CreateConVar("ssh_version", "2.0", "Current Version", 0, false, 0.0, false, 0.0);
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	HookEvent("player_blind", EventPlayerBlind, EventHookMode:1);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode:1);
	HookEventEx("player_death", EventPlayerDeath, EventHookMode:0);
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode:1);
	RegConsoleCmd("ssh_weapon", ModAttribute, "", 0);
	RegConsoleCmd("ssh_bunnyhop", ModBunnyhop, "", 0);
	RegConsoleCmd("ssh_noflash", ModNoFlash, "", 0);
	RegConsoleCmd("ssh_takendmg", ModLag, "", 0);
	RegConsoleCmd("ssh_lag", ModChance, "", 0);
	RegConsoleCmd("ssh_triggerbot", ModTrigger, "", 0);
	RegConsoleCmd("ssh_speedhack", ModSpeed, "", 0);
	RegConsoleCmd("ssh_aimbot", ModAim, "", 0);
	RegConsoleCmd("ssh_nofalldmg", ModFallDmg, "", 0);
	RegConsoleCmd("ssh_info", ModInfo, "", 0);
	RegConsoleCmd("say", Command_Say, "", 0);
	RegConsoleCmd("say_team", Command_Say, "", 0);
	new cnt;
	while (cnt <= 64)
	{
		Aimbot[cnt] = 0;
		AimbotMulti[cnt] = 1;
		HeadChance[cnt] = 1065353216;
		AimPos[cnt] = 0;
		OnAttack[cnt] = 0;
		Smooth[cnt] = 1065353216;
		Speedhack[cnt] = 1065353216;
		Triggerbot[cnt] = 0;
		TakeDmg[cnt] = 1065353216;
		ChanceToTakeDmg[cnt] = 1065353216;
		AimT[cnt] = 0;
		All[cnt][0] = 1065353216;
		All[cnt][1] = -1082130432;
		All[cnt][2] = 1065353216;
		All[cnt][3] = -1;
		All[cnt][4] = 1065353216;
		All[cnt][5] = 1065353216;
		All[cnt][6] = 1065353216;
		All[cnt][7] = 1065353216;
		All[cnt][8] = 1065353216;
		All[cnt][9] = 1065353216;
		All[cnt][10] = 1065353216;
		All[cnt][11] = -1;
		All[cnt][12] = 0;
		All[cnt][13] = 0;
		AimChance[cnt] = 1065353216;
		SetTrieArray(WeaponTypeTrie, "all", All[cnt], 14, true);
		cnt++;
	}
	SetTrieValue(WeaponZoomSpeedTrie, "scout", any:1066878417, true);
	SetTrieValue(WeaponZoomSpeedTrie, "sg552", any:1066821222, true);
	SetTrieValue(WeaponZoomSpeedTrie, "awp", any:1068708659, true);
	SetTrieValue(WeaponZoomSpeedTrie, "sg550", any:1068708659, true);
	new client = 1;
	while (client <= MaxClients)
	{
		new AdminId:aid = GetUserAdmin(client);
		if (aid != AdminId:-1)
		{
			if (GetAdminFlag(aid, AdminFlag:15, AdmAccessMode:1))
			{
				IsAdmin[client] = 1;
			}
		}
		if (IsClientInGame(client))
		{
			SDKHook(client, SDKHookType:5, OnPostThink);
			SDKHook(client, SDKHookType:20, OnPostThinkPost);
			SDKHook(client, SDKHookType:11, OnTraceAttack);
			SDKHook(client, SDKHookType:16, OnWeaponEquip);
			SDKHook(client, SDKHookType:2, OnTakeDamage);
			SDKHook(client, SDKHookType:17, OnWeaponSwitch);
			SDKHook(client, SDKHookType:1, OnFireBullets);
		}
		client++;
	}
	return 0;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHookType:5, OnPostThink);
	SDKHook(client, SDKHookType:20, OnPostThinkPost);
	SDKHook(client, SDKHookType:11, OnTraceAttack);
	SDKHook(client, SDKHookType:16, OnWeaponEquip);
	SDKHook(client, SDKHookType:2, OnTakeDamage);
	SDKHook(client, SDKHookType:17, OnWeaponSwitch);
	SDKHook(client, SDKHookType:1, OnFireBullets);
	Smooth[client] = 1065353216;
	return 0;
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		Aimbot[client] = 0;
		AimbotMulti[client] = 1;
		HeadChance[client] = 1065353216;
		IsAdmin[client] = 0;
		AimPos[client] = 0;
		Smooth[client] = 1065353216;
		OnAttack[client] = 0;
		Speedhack[client] = 1065353216;
		Triggerbot[client] = 0;
		g_iBunnyhop[client] = 0;
		g_iNoFlash[client] = 0;
		TakeDmg[client] = 1065353216;
		ChanceToTakeDmg[client] = 1065353216;
		All[client][0] = 1065353216;
		All[client][1] = -1082130432;
		All[client][2] = 1065353216;
		All[client][3] = -1;
		All[client][4] = 1065353216;
		All[client][5] = 1065353216;
		All[client][6] = 1065353216;
		All[client][7] = 1065353216;
		All[client][8] = 1065353216;
		All[client][9] = 1065353216;
		All[client][10] = 1065353216;
		All[client][11] = -1;
		All[client][12] = 0;
		All[client][13] = 0;
		AimT[client] = 0;
		AimChance[client] = 1065353216;
	}
	return 0;
}

public Action:EventPlayerBlind(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsAdmin[client])
	{
		return Action:0;
	}
	return Action:0;
}

public Action:EventPlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client2 = GetClientOfUserId(GetEventInt(event, "attacker"));
	new var1;
	if (aimbot_event == client && HeadChanceF[client2] == 1)
	{
		EmitSoundToAll("player/headshot1.wav", client, 2, 326, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		SetEventBool(event, "headshot", true);
		aimbot_event = -1;
		HeadChanceF[client2] = 0;
	}
	return Action:0;
}

public OnClientPostAdminCheck(client)
{
	new var1;
	if (IsFakeClient(client) || !IsClientConnected(client))
	{
		return 0;
	}
	new AdminId:aid = GetUserAdmin(client);
	if (aid != AdminId:-1)
	{
		if (GetAdminFlag(aid, AdminFlag:15, AdmAccessMode:1))
		{
			IsAdmin[client] = 1;
		}
	}
	return 0;
}

public OnPluginEnd()
{
	CloseHandle(WeaponTypeTrie);
	CloseHandle(WeaponZoomSpeedTrie);
	return 0;
}

public Action:ModBunnyhop(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:0;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	g_iBunnyhop[client] = StringToInt(AttributeValue, 10);
	return Action:3;
}

public Action:Command_Say(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:0;
	}
	new String:AttributeValue[128];
	new String:final[256];
	BuildPath(PathType:0, final, 256, "ssh/");
	GetCmdArg(1, AttributeValue, 128);
	StrCat(final, 256, AttributeValue);
	StrCat(final, 256, ".cfg");
	new Handle:userfile = OpenFile(final, "r+");
	if (FileExists(final, false))
	{
		while (!IsEndOfFile(userfile))
		{
			new String:line[256];
			ReadFileLine(userfile, line, 256);
			FakeClientCommand(client, line);
		}
	}
	return Action:0;
}

public Action:ModFallDmg(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	NoFallDmg[client] = StringToInt(AttributeValue, 10);
	return Action:3;
}

public Action:ModSpoof(client, args)
{
	PrintToConsole(client, "Unknown Command");
	return Action:3;
}

public Action:ModAim(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue1[20];
	new String:AttributeValue2[20];
	GetCmdArg(1, AttributeValue1, 20);
	if (GetCmdArgs() != 2)
	{
		Aimbot[client] = StringToInt(AttributeValue1, 10);
	}
	else
	{
		GetCmdArg(2, AttributeValue2, 20);
		if (StrEqual("fov", AttributeValue1, false))
		{
			aFov[client] = StringToFloat(AttributeValue2);
		}
		if (StrEqual("smooth", AttributeValue1, false))
		{
			if (StringToFloat(AttributeValue2) >= 1)
			{
				Smooth[client] = StringToFloat(AttributeValue2);
			}
		}
		if (StrEqual("onattack", AttributeValue1, false))
		{
			OnAttack[client] = StringToInt(AttributeValue2, 10);
		}
		if (StrEqual("through", AttributeValue1, false))
		{
			AimT[client] = StringToInt(AttributeValue2, 10);
		}
		if (StrEqual("chance", AttributeValue1, false))
		{
			AimChance[client] = StringToFloat(AttributeValue2);
		}
		if (StrEqual("hs_chance", AttributeValue1, false))
		{
			HeadChance[client] = StringToFloat(AttributeValue2);
		}
		if (StrEqual("multi", AttributeValue1, false))
		{
			AimbotMulti[client] = StringToInt(AttributeValue2, 10);
		}
		if (StrEqual("pos", AttributeValue1, false))
		{
			if (StrEqual("head", AttributeValue2, false))
			{
				AimPos[client] = 0;
			}
			if (StrEqual("normal", AttributeValue2, false))
			{
				AimPos[client] = 1;
			}
		}
	}
	return Action:3;
}

public Action:ModInfo(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	PrintToConsole(client, "\n");
	PrintToConsole(client, "ssh_aimbot 1");
	PrintToConsole(client, "ssh_bunnyhop 0-1");
	PrintToConsole(client, "ssh_noflash 0-1");
	PrintToConsole(client, "ssh_lag 0.0-1.0");
	PrintToConsole(client, "ssh_takendmg 0.0-1.0");
	PrintToConsole(client, "ssh_weapon <sub> <value>");
	PrintToConsole(client, "ssh_triggerbot 0-1");
	PrintToConsole(client, "ssh_speedhack 0.0-50.0");
	PrintToConsole(client, "ssh_nofalldmg 0-1");
	PrintToConsole(client, "\n");
	PrintToConsole(client, "Aimbot Subkeys:");
	PrintToConsole(client, "fov 0.0-360.0");
	PrintToConsole(client, "onattack 0-1");
	PrintToConsole(client, "\n");
	PrintToConsole(client, "Weapon Subkeys:");
	PrintToConsole(client, "\n");
	PrintToConsole(client, "recoil 0.0-1.0");
	PrintToConsole(client, "firerate 0-25");
	PrintToConsole(client, "dmg 0-30");
	PrintToConsole(client, "dmg_head 0-30");
	PrintToConsole(client, "dmg_leg 0-30");
	PrintToConsole(client, "dmg_arm 0-30");
	PrintToConsole(client, "dmg_chest 0-30");
	PrintToConsole(client, "ammo 0-1");
	PrintToConsole(client, "fastswitch");
	return Action:3;
}

public Action:ModSpeed(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	Speedhack[client] = StringToFloat(AttributeValue);
	SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", Speedhack[client]);
	return Action:3;
}

public Action:ModTrigger(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	Triggerbot[client] = StringToInt(AttributeValue, 10);
	return Action:3;
}

public Action:ModNoFlash(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	g_iNoFlash[client] = StringToInt(AttributeValue, 10);
	return Action:3;
}

public Action:ModLag(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	TakeDmg[client] = StringToFloat(AttributeValue);
	return Action:3;
}

public Action:ModChance(client, args)
{
	if (!IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeValue, 20);
	ChanceToTakeDmg[client] = StringToFloat(AttributeValue);
	return Action:3;
}

public Action:ModAttribute(client, args)
{
	new var1;
	if (GetCmdArgs() == 2 && !IsAdmin[client])
	{
		return Action:3;
	}
	new String:AttributeName[32];
	new String:AttributeValue[20];
	GetCmdArg(1, AttributeName, 30);
	GetCmdArg(2, AttributeValue, 20);
	new Float:FloatVal = 0.0;
	new IntVal;
	decl String:FloatString[20];
	if (StrEqual("recoil", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 10.0)
		{
			FloatVal = 10.0;
		}
		else
		{
			if (FloatVal < 0.0)
			{
				FloatVal = 0.0;
			}
		}
		FloatToString(FloatVal, FloatString, 20);
		if (-1082130432 != All[client][0])
		{
			All[client][0] = FloatVal;
		}
		else
		{
			if (-1082130432 != All[client][1])
			{
				All[client][1] = FloatVal;
			}
		}
	}
	else
	{
		if (StrEqual("firerate", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 50.0)
			{
				FloatVal = 50.0;
			}
			else
			{
				if (FloatVal < 0.1)
				{
					FloatVal = 0.1;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][2])
			{
				All[client][2] = 1.0 / FloatVal;
			}
		}
		if (StrEqual("speed", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 5.0)
			{
				FloatVal = 5.0;
			}
			else
			{
				if (FloatVal < 0.5)
				{
					FloatVal = 0.5;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][4])
			{
				All[client][4] = FloatVal;
			}
		}
		if (StrEqual("dmg", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 1000.0)
			{
				FloatVal = 1000.0;
			}
			else
			{
				if (FloatVal < 0.0)
				{
					FloatVal = 0.0;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][5])
			{
				All[client][5] = FloatVal;
			}
		}
		if (StrEqual("dmg_head", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 1000.0)
			{
				FloatVal = 1000.0;
			}
			else
			{
				if (FloatVal < 0.0)
				{
					FloatVal = 0.0;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][6])
			{
				All[client][6] = FloatVal;
			}
		}
		if (StrEqual("dmg_chest", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 1000.0)
			{
				FloatVal = 1000.0;
			}
			else
			{
				if (FloatVal < 0.0)
				{
					FloatVal = 0.0;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][7])
			{
				All[client][7] = FloatVal;
			}
		}
		if (StrEqual("dmg_stomache", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 1000.0)
			{
				FloatVal = 1000.0;
			}
			else
			{
				if (FloatVal < 0.0)
				{
					FloatVal = 0.0;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][8])
			{
				All[client][8] = FloatVal;
			}
		}
		if (StrEqual("dmg_arm", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 1000.0)
			{
				FloatVal = 1000.0;
			}
			else
			{
				if (FloatVal < 0.0)
				{
					FloatVal = 0.0;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][9])
			{
				All[client][9] = FloatVal;
			}
		}
		if (StrEqual("dmg_leg", AttributeName, false))
		{
			FloatVal = StringToFloat(AttributeValue);
			if (FloatVal > 1000.0)
			{
				FloatVal = 1000.0;
			}
			else
			{
				if (FloatVal < 0.0)
				{
					FloatVal = 0.0;
				}
			}
			FloatToString(FloatVal, FloatString, 20);
			if (-1082130432 != All[client][10])
			{
				All[client][10] = FloatVal;
			}
		}
		if (StrEqual("burst", AttributeName, false))
		{
			IntVal = StringToInt(AttributeValue, 10);
			new var2;
			if (IntVal != 1 && IntVal)
			{
				IntVal = 0;
			}
			if (All[client][11] != -1)
			{
				All[client][11] = IntVal;
			}
		}
		if (StrEqual("ammo", AttributeName, false))
		{
			IntVal = StringToInt(AttributeValue, 10);
			new var3;
			if (IntVal != 1 && IntVal)
			{
				IntVal = 0;
			}
			if (All[client][12] != -1)
			{
				All[client][12] = IntVal;
			}
		}
		if (StrEqual("fastswitch", AttributeName, false))
		{
			IntVal = StringToInt(AttributeValue, 10);
			new var4;
			if (IntVal != 1 && IntVal)
			{
				IntVal = 0;
			}
			if (All[client][13] != -1)
			{
				All[client][13] = IntVal;
			}
		}
	}
	return Action:3;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if (data == entity)
	{
		return false;
	}
	return true;
}

public Action:EventPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", Speedhack[client]);
	return Action:0;
}

public MakeVector(Float:angle[3], Float:vector[3])
{
	new Float:pitch = 0.0;
	new Float:yaw = 0.0;
	new Float:tmp = 0.0;
	pitch = angle[0] * 3.14159 / 180;
	yaw = angle[1] * 3.14159 / 180;
	tmp = Cosine(pitch);
	vector[0] = -tmp * -Cosine(yaw);
	vector[1] = Sine(yaw) * tmp;
	vector[2] = -Sine(pitch);
	return 0;
}

public CalcAngle(Float:src[3], Float:dst[3], Float:angles[3])
{
	new Float:delta[3] = 0.0;
	delta[0] = src[0] - dst[0];
	delta[1] = src[1] - dst[1];
	delta[2] = src[2] - dst[2];
	new Float:hyp = SquareRoot(delta[0] * delta[0] + delta[1] * delta[1]);
	angles[0] = ArcTangent(delta[2] / hyp) * 3.14159;
	angles[1] = ArcTangent(delta[1] / delta[0]) * 3.14159;
	angles[2] = 0.0;
	if (delta[0] >= 0.0)
	{
		angles[1] += 180.0;
	}
	return 0;
}

public Float:GetDmg(client, cnt)
{
	new String:buf[256];
	GetClientWeapon(client, buf, 256);
	new Float:ret = 0.0;
	if (strcmp(buf, "weapon_glock", true))
	{
		if (strcmp(buf, "weapon_usp", true))
		{
			if (strcmp(buf, "weapon_p228", true))
			{
				if (strcmp(buf, "weapon_deagle", true))
				{
					if (strcmp(buf, "weapon_elite", true))
					{
						if (strcmp(buf, "weapon_fiveseven", true))
						{
							if (strcmp(buf, "weapon_m3", true))
							{
								if (strcmp(buf, "weapon_xm1014", true))
								{
									if (strcmp(buf, "weapon_galil", true))
									{
										if (strcmp(buf, "weapon_ak47", true))
										{
											if (strcmp(buf, "weapon_scout", true))
											{
												if (strcmp(buf, "weapon_sg552", true))
												{
													if (strcmp(buf, "weapon_awp", true))
													{
														if (strcmp(buf, "weapon_g3sg1", true))
														{
															if (strcmp(buf, "weapon_famas", true))
															{
																if (strcmp(buf, "weapon_m4a1", true))
																{
																	if (strcmp(buf, "weapon_aug", true))
																	{
																		if (strcmp(buf, "weapon_sg550", true))
																		{
																			if (strcmp(buf, "weapon_mac10", true))
																			{
																				if (strcmp(buf, "weapon_tmp", true))
																				{
																					if (strcmp(buf, "weapon_mp5navy", true))
																					{
																						if (strcmp(buf, "weapon_ump45", true))
																						{
																							if (strcmp(buf, "weapon_p90", true))
																							{
																								if (!(strcmp(buf, "weapon_m249", true)))
																								{
																									ret = GetRandomFloat(1.0, 25.0) + 100.0;
																								}
																							}
																							ret = GetRandomFloat(1.0, 30.0) + 65.0;
																						}
																						ret = GetRandomFloat(1.0, 20.0) + 60.0;
																					}
																					ret = GetRandomFloat(1.0, 30.0) + 70.0;
																				}
																				ret = GetRandomFloat(1.0, 25.0) + 70.0;
																			}
																			ret = GetRandomFloat(1.0, 30.0) + 70.0;
																		}
																		ret = GetRandomFloat(1.0, 100.0) + 200.0;
																	}
																	ret = GetRandomFloat(1.0, 30.0) + 110.0;
																}
																ret = GetRandomFloat(1.0, 40.0) + 100.0;
															}
															ret = GetRandomFloat(1.0, 25.0) + 90.0;
														}
														ret = GetRandomFloat(1.0, 100.0) + 200.0;
													}
													ret = GetRandomFloat(1.0, 160.0) + 250.0;
												}
												ret = GetRandomFloat(1.0, 30.0) + 90.0;
											}
											ret = GetRandomFloat(1.0, 100.0) + 150.0;
										}
										ret = GetRandomFloat(1.0, 40.0) + 125.0;
									}
									ret = GetRandomFloat(1.0, 40.0) + 100.0;
								}
								ret = GetRandomFloat(1.0, 40.0) + 65.0;
							}
							ret = GetRandomFloat(1.0, 15.0) + 70.0;
						}
						ret = GetRandomFloat(1.0, 15.0) + 80.0;
					}
					ret = GetRandomFloat(1.0, 15.0) + 70.0;
				}
				ret = GetRandomFloat(1.0, 40.0) + 100.0;
			}
			ret = GetRandomFloat(1.0, 15.0) + 90.0;
		}
		ret = GetRandomFloat(1.0, 15.0) + 85.0;
	}
	else
	{
		ret = GetRandomFloat(0.0, 15.0) + 50.0;
	}
	ret *= GetRandomFloat(0.9, 1.1);
	new helmet = GetEntProp(cnt, PropType:0, "m_bHasHelmet", 4);
	if (helmet)
	{
		ret *= 0.9;
	}
	if (!HeadChanceF[client])
	{
		ret *= GetRandomFloat(0.3, 0.65);
	}
	return ret;
}

public Action:EventWeaponFire(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (IsAdmin[client] && g_iNoFlash[client])
	{
		SetEntDataFloat(client, g_iFlashAlpha, 0.5, false);
	}
	new m_Offset = FindSendPropOffs("CCSPlayer", "m_iTeamNum");
	new Float:angles[3] = 0.0;
	new var5 = view_angles[client];
	angles = var5;
	if (Aimbot[client])
	{
		new i;
		while (AimbotMulti[client] >= i)
		{
			new cnt = 1;
			while (cnt <= MaxClients)
			{
				new t1;
				new t2;
				if (IsClientInGame(cnt))
				{
					t1 = GetEntData(client, m_Offset, 4);
					t2 = GetEntData(cnt, m_Offset, 4);
					if (!(IsClientObserver(cnt)))
					{
						if (IsPlayerAlive(cnt))
						{
							if (!(t2 == t1))
							{
								new var2;
								if (!(t2 == 2 || t2 == 3))
								{
									if (!(client == cnt))
									{
										new Float:p1[3] = 0.0;
										new Float:p2[3] = 0.0;
										new Float:p3[3] = 0.0;
										GetClientEyePosition(client, p1);
										GetClientEyePosition(cnt, p2);
										TR_TraceRayFilter(p1, p2, 33636363, RayType:0, TraceRayDontHitSelf, client);
										new var3;
										if (!(TR_GetFraction(Handle:0) < 1064682127 && cnt != TR_GetEntityIndex(Handle:0) && AimT[client]))
										{
											new Float:delta[3] = 0.0;
											delta[0] = p1[0] - p2[0];
											delta[1] = p1[1] - p2[1];
											delta[2] = p1[2] - p2[2];
											new Float:hyp = SquareRoot(delta[0] * delta[0] + delta[1] * delta[1]);
											p3[0] = ArcTangent(delta[2] / hyp) * 180 / 3.141;
											p3[1] = ArcTangent(delta[1] / delta[0]) * 180 / 3.141;
											p3[2] = 0.0;
											if (delta[0] >= 0.0)
											{
												p3[1] += 180.0;
											}
											new var4;
											if (!(FloatAbs(p3[0] - angles[0]) > aFov[client] || FloatAbs(p3[1] - angles[1]) > aFov[client]))
											{
												if (Aimbot[client] == 2)
												{
													new int:dmgt = 2;
													aimbot_event = cnt;
													if (GetRandomFloat(0.0, 1.0) > HeadChance[client])
													{
														HeadChanceF[client] = 0;
													}
													else
													{
														HeadChanceF[client] = 1;
													}
													if (!(AimChance[client] < GetRandomFloat(0.0, 1.0)))
													{
														SDKHooks_TakeDamage(cnt, client, client, GetDmg(client, cnt), dmgt, -1, NULL_VECTOR, NULL_VECTOR);
														i++;
													}
													cnt++;
												}
											}
											cnt++;
										}
										cnt++;
									}
									cnt++;
								}
								cnt++;
							}
							cnt++;
						}
						cnt++;
					}
					cnt++;
				}
				cnt++;
			}
			i++;
		}
	}
	return Action:0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bool:RightClicking[65];
	new var1;
	if (!IsPlayerAlive(client) || !IsAdmin[client])
	{
		return Action:0;
	}
	new WeaponIndex = GetEntPropEnt(client, PropType:0, "m_hActiveWeapon");
	if (WeaponIndex == -1)
	{
		return Action:0;
	}
	new var2;
	if (All[client][11] == 1 && BurstShotsFired[client] && ModeStateArray[client][1])
	{
		if (GetEntProp(WeaponIndex, PropType:0, "m_iClip1", 4))
		{
			buttons = buttons | 1;
		}
		BurstShotsFired[client] = 0;
	}
	if (buttons & 2048)
	{
		if (All[client][11] == 1)
		{
			if (!RightClicking[client])
			{
				RightClicking[client] = 1;
				if (!ModeStateArray[client][1])
				{
					ModeStateArray[client][1] = 1;
					PrintCenterText(client, "switched to burst-fire mode");
				}
				ModeStateArray[client][1] = 0;
				PrintCenterText(client, "switched to normal mode");
				BurstShotsFired[client] = 0;
			}
			buttons = buttons & -2049;
		}
	}
	else
	{
		RightClicking[client] = 0;
	}
	new m_Offset = FindSendPropOffs("CCSPlayer", "m_iTeamNum");
	if (Aimbot[client])
	{
		new cnt = 1;
		while (cnt <= MaxClients)
		{
			new t1;
			new t2;
			if (IsClientInGame(cnt))
			{
				t1 = GetEntData(client, m_Offset, 4);
				t2 = GetEntData(cnt, m_Offset, 4);
				if (!(IsClientObserver(cnt)))
				{
					if (IsPlayerAlive(cnt))
					{
						if (!(t2 == t1))
						{
							new var3;
							if (!(t2 == 2 || t2 == 3))
							{
								if (!(client == cnt))
								{
									new Float:p1[3] = 0.0;
									new Float:p2[3] = 0.0;
									new Float:p3[3] = 0.0;
									GetClientEyePosition(client, p1);
									GetClientEyePosition(cnt, p2);
									TR_TraceRayFilter(p1, p2, 33636363, RayType:0, TraceRayDontHitSelf, client);
									new var4;
									if (!(TR_GetFraction(Handle:0) < 1064682127 && cnt != TR_GetEntityIndex(Handle:0) && AimT[client]))
									{
										new Float:delta[3] = 0.0;
										delta[0] = p1[0] - p2[0];
										delta[1] = p1[1] - p2[1];
										delta[2] = p1[2] - p2[2];
										new Float:hyp = SquareRoot(delta[0] * delta[0] + delta[1] * delta[1]);
										p3[0] = ArcTangent(delta[2] / hyp) * 180 / 3.141;
										p3[1] = ArcTangent(delta[1] / delta[0]) * 180 / 3.141;
										p3[2] = 0.0;
										if (delta[0] >= 0.0)
										{
											p3[1] += 180.0;
										}
										new var5;
										if (!(FloatAbs(p3[0] - angles[0]) > aFov[client] || FloatAbs(p3[1] - angles[1]) > aFov[client]))
										{
											new var8;
											if (Aimbot[client] == 1 && (OnAttack[client] && (OnAttack[client] == 1 && buttons & 1)))
											{
												angles[0] = p3[0];
												angles[1] = p3[1];
											}
										}
										cnt++;
									}
									cnt++;
								}
								cnt++;
							}
							cnt++;
						}
						cnt++;
					}
					cnt++;
				}
				cnt++;
			}
			cnt++;
		}
	}
	if (Triggerbot[client])
	{
		new t1;
		new t2;
		new Float:Pos[3] = 0.0;
		new Float:Ang[3] = 0.0;
		GetClientEyePosition(client, Pos);
		GetClientEyeAngles(client, Ang);
		TR_TraceRayFilter(Pos, Ang, 33636363, RayType:1, TraceRayDontHitSelf, client);
		if (TR_DidHit(Handle:0))
		{
			new TRIndex = TR_GetEntityIndex(Handle:0);
			t1 = GetEntData(client, m_Offset, 4);
			t2 = GetEntData(TRIndex, m_Offset, 4);
			new var10;
			if (TRIndex && t2 != t1 && (t2 == 2 || t2 == 3))
			{
				buttons = buttons | 1;
			}
		}
	}
	new flags = GetEntityFlags(client);
	new var11;
	if (buttons & 2 && !flags & 1 && g_iBunnyhop[client])
	{
		buttons = buttons & -3;
	}
	return Action:0;
}

public OnPreThinkPost(client)
{
	new var1;
	if (!IsPlayerAlive(client) || !IsAdmin[client])
	{
		return 0;
	}
	new WeaponIndex = GetEntPropEnt(client, PropType:0, "m_hActiveWeapon");
	decl String:WeaponName[32];
	if (WeaponIndex != -1)
	{
		GetEdictClassname(WeaponIndex, WeaponName, 30);
		ReplaceString(WeaponName, 30, "weapon_", "", false);
	}
	else
	{
		WeaponName = "none";
	}
	new var2;
	if (1065353216 != All[client][4] && -1082130432 != All[client][4])
	{
		All[client][4] *= GetEntPropFloat(client, PropType:1, "m_flMaxspeed");
		new Float:WeaponZoomSpeed = 0.0;
		if (GetTrieValue(WeaponZoomSpeedTrie, WeaponName, WeaponZoomSpeed))
		{
			new Fov = GetEntProp(client, PropType:1, "m_iFOV", 4);
			new var3;
			if (Fov != 90 && Fov)
			{
				All[client][4] /= WeaponZoomSpeed;
			}
		}
		SetEntPropFloat(client, PropType:1, "m_flMaxspeed", All[client][4]);
	}
	return 0;
}

public OnPostThink(client)
{
	new var1;
	if (!IsPlayerAlive(client) || !IsAdmin[client])
	{
		return 0;
	}
	new Buttons = GetClientButtons(client);
	if (Buttons & 1)
	{
		new WeaponIndex = GetEntPropEnt(client, PropType:0, "m_hActiveWeapon");
		if (WeaponIndex == -1)
		{
			return 0;
		}
		if (GetGameTime() < GetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack"))
		{
			return 0;
		}
		if (GetGameTime() < GetEntPropFloat(client, PropType:0, "m_flNextAttack"))
		{
			return 0;
		}
		new ClipAmmo = GetEntProp(WeaponIndex, PropType:0, "m_iClip1", 4);
		if (ClipAmmo)
		{
			decl String:WeaponName[32];
			GetEdictClassname(WeaponIndex, WeaponName, 30);
			ReplaceString(WeaponName, 30, "weapon_", "", false);
			new var2;
			if (All[client][3] != -1 && GetEntProp(client, PropType:0, "m_iShotsFired", 4))
			{
				return 0;
			}
			if (All[client][12] == 1)
			{
				if (ClipAmmo != -1)
				{
					SetEntProp(WeaponIndex, PropType:0, "m_iClip1", any:5, 4);
				}
				new AmmoOffset = FindSendPropOffs("CCSPlayer", "m_iAmmo");
				decl AmmoArray[32];
				GetEntDataArray(client, AmmoOffset, AmmoArray, 32, 4);
				if (StrEqual("hegrenade", WeaponName, false))
				{
					AmmoArray[11] = 2;
				}
				else
				{
					if (StrEqual("flashbang", WeaponName, false))
					{
						AmmoArray[12] = 2;
					}
					if (StrEqual("smokegrenade", WeaponName, false))
					{
						AmmoArray[13] = 2;
					}
				}
				SetEntDataArray(client, AmmoOffset, AmmoArray, 32, 4, false);
			}
			new var3;
			if (StrEqual("glock", WeaponName, false) || StrEqual("famas", WeaponName, false))
			{
				new var4;
				if (GetEntProp(WeaponIndex, PropType:0, "m_bBurstMode", 4) && All[client][3] != 1)
				{
					return 0;
				}
			}
			if (All[client][11] == 1)
			{
				if (ModeStateArray[client][1])
				{
					ProcessArray[client][2] = 2;
					return 0;
				}
			}
			else
			{
				new var5;
				if (All[client][11] && ModeStateArray[client][1])
				{
					ModeStateArray[client][1] = 0;
				}
			}
			new var6;
			if (-1082130432 != All[client][0] && 1065353216 != All[client][0])
			{
				ProcessArray[client][0] = 1;
			}
			else
			{
				new var7;
				if (-1082130432 != All[client][1] && 1065353216 != All[client][1])
				{
					GetEntPropVector(client, PropType:0, "m_vecPunchAngle", PreviousPunchAngle[client]);
					ProcessArray[client][0] = 1;
				}
			}
			if (All[client][3] == 1)
			{
				if (StrEqual("glock", WeaponName, false))
				{
					SetEntProp(WeaponIndex, PropType:0, "m_bBurstMode", any:0, 4);
					SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack", GetGameTime() + 999999.0);
				}
				else
				{
					if (StrEqual("usp", WeaponName, false))
					{
						SetEntProp(WeaponIndex, PropType:0, "m_bSilencerOn", any:0, 4);
						SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack", GetGameTime() + 999999.0);
					}
				}
				if (ModeStateArray[client][0])
				{
					ProcessArray[client][2] = 1;
					return 0;
				}
			}
			else
			{
				new var8;
				if (All[client][3] && ModeStateArray[client][0])
				{
					ModeStateArray[client][0] = 0;
				}
			}
			new var9;
			if (-1082130432 != All[client][2] && 1065353216 != All[client][2])
			{
				ProcessArray[client][1] = 1;
			}
		}
		return 0;
	}
	else
	{
		if (Buttons & 2048)
		{
			new WeaponIndex = GetEntPropEnt(client, PropType:0, "m_hActiveWeapon");
			decl String:WeaponName[32];
			if (WeaponIndex != -1)
			{
				GetEdictClassname(WeaponIndex, WeaponName, 30);
				ReplaceString(WeaponName, 30, "weapon_", "", false);
			}
			else
			{
				WeaponName = "none";
			}
			if (StrEqual("knife", WeaponName, false))
			{
				if (GetGameTime() < GetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack"))
				{
					return 0;
				}
				if (GetGameTime() < GetEntPropFloat(client, PropType:0, "m_flNextAttack"))
				{
					return 0;
				}
				if (1065353216 != All[client][2])
				{
					ProcessArray[client][1] = 2;
				}
			}
		}
	}
	return 0;
}

public OnPostThinkPost(client)
{
	new var1;
	if (!IsPlayerAlive(client) || !IsAdmin[client])
	{
		return 0;
	}
	new WeaponIndex = GetEntPropEnt(client, PropType:0, "m_hActiveWeapon");
	if (WeaponIndex == -1)
	{
		return 0;
	}
	decl String:WeaponName[32];
	GetEdictClassname(WeaponIndex, WeaponName, 30);
	ReplaceString(WeaponName, 30, "weapon_", "", false);
	if (ProcessArray[client][1] == 1)
	{
		ProcessArray[client][1] = 0;
		if (All[client][2] != 50)
		{
			new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack");
			NextAttackTime -= GetGameTime();
			NextAttackTime *= All[client][2];
			NextAttackTime += GetGameTime();
			SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack", NextAttackTime);
		}
		else
		{
			SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack", GetGameTime());
		}
	}
	else
	{
		if (ProcessArray[client][1] == 2)
		{
			ProcessArray[client][1] = 0;
			if (All[client][2] != 50)
			{
				new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack");
				NextAttackTime -= GetGameTime();
				NextAttackTime *= All[client][2];
				NextAttackTime += GetGameTime();
				SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack", NextAttackTime);
			}
			SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack", GetGameTime());
		}
	}
	if (ProcessArray[client][2] == 1)
	{
		ProcessArray[client][2] = 0;
		SetEntProp(client, PropType:0, "m_iShotsFired", any:0, 4);
		SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack", GetGameTime() + 0.05);
	}
	else
	{
		if (ProcessArray[client][2] == 2)
		{
			ProcessArray[client][2] = 0;
			new var2 = BurstShotsFired[client];
			var2++;
			if (var2 == 3)
			{
				SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack", GetGameTime() + 0.75);
				BurstShotsFired[client] = 0;
			}
			SetEntProp(client, PropType:0, "m_iShotsFired", any:0, 4);
			new Float:NoRecoil[3] = 0.0;
			SetEntPropVector(client, PropType:0, "m_vecPunchAngle", NoRecoil);
			SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextPrimaryAttack", GetGameTime() + 0.05);
		}
	}
	if (ProcessArray[client][0] == 1)
	{
		ProcessArray[client][0] = 0;
		decl Float:CurrentPunchAngle[3];
		GetEntPropVector(client, PropType:0, "m_vecPunchAngle", CurrentPunchAngle);
		if (-1082130432 != All[client][0])
		{
			if (0 != All[client][0])
			{
				CurrentPunchAngle[0] = CurrentPunchAngle[0] * All[client][0];
			}
			else
			{
				SetEntProp(client, PropType:0, "m_iShotsFired", any:0, 4);
				CurrentPunchAngle[0] = 0.0;
				CurrentPunchAngle[1] = 0.0;
			}
		}
		else
		{
			if (-1082130432 != All[client][1])
			{
				if (0 != All[client][1])
				{
					CurrentPunchAngle[0] = CurrentPunchAngle[0] - PreviousPunchAngle[client][0];
					CurrentPunchAngle[0] = CurrentPunchAngle[0] * All[client][1];
					CurrentPunchAngle[0] = CurrentPunchAngle[0] + PreviousPunchAngle[client][0];
				}
				CurrentPunchAngle[0] = 0.0;
			}
		}
		if (CurrentPunchAngle[0] < -90.0)
		{
			CurrentPunchAngle[0] = -90.0;
		}
		SetEntPropVector(client, PropType:0, "m_vecPunchAngle", CurrentPunchAngle);
	}
	if (All[client][3] == 1)
	{
		if (StrEqual("glock", WeaponName, false))
		{
			SetEntProp(WeaponIndex, PropType:0, "m_bBurstMode", any:0, 4);
			SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack", GetGameTime() + 999999.0);
		}
		if (StrEqual("usp", WeaponName, false))
		{
			SetEntProp(WeaponIndex, PropType:0, "m_bSilencerOn", any:0, 4);
			SetEntPropFloat(WeaponIndex, PropType:0, "m_flNextSecondaryAttack", GetGameTime() + 999999.0);
		}
	}
	if (ProcessArray[client][3] == 1)
	{
		ProcessArray[client][3] = 0;
		SetEntPropFloat(client, PropType:0, "m_flNextAttack", GetGameTime());
		if (StrEqual("usp", WeaponName, false))
		{
			if (!(GetEntProp(WeaponIndex, PropType:0, "m_bSilencerOn", 4)))
			{
				SetEntProp(GetEntPropEnt(client, PropType:0, "m_hViewModel"), PropType:0, "m_nSequence", any:8, 4);
				return 0;
			}
		}
		else
		{
			if (StrEqual("m4a1", WeaponName, false))
			{
				if (!(GetEntProp(WeaponIndex, PropType:0, "m_bSilencerOn", 4)))
				{
					SetEntProp(GetEntPropEnt(client, PropType:0, "m_hViewModel"), PropType:0, "m_nSequence", any:7, 4);
					return 0;
				}
			}
		}
		SetEntProp(GetEntPropEnt(client, PropType:0, "m_hViewModel"), PropType:0, "m_nSequence", any:0, 4);
	}
	return 0;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new var1;
	if (!IsAdmin[attacker] && !IsAdmin[victim])
	{
		return Action:0;
	}
	new var2;
	if (attacker > 0 && attacker <= MaxClients && inflictor == attacker)
	{
		new WeaponIndex = GetEntPropEnt(attacker, PropType:0, "m_hActiveWeapon");
		if (WeaponIndex == -1)
		{
			return Action:0;
		}
		decl String:WeaponName[32];
		GetEdictClassname(WeaponIndex, WeaponName, 30);
		ReplaceString(WeaponName, 30, "weapon_", "", false);
		new GetWeaponInfo[14];
		GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo, 14, 0);
		new var3;
		if (1.0 != ChanceToTakeDmg[victim] || 1.0 != TakeDmg[victim])
		{
			new Float:rande = GetRandomFloat(0.0, 1.0);
			if (rande > ChanceToTakeDmg[victim])
			{
				damage = 0;
			}
			else
			{
				damage = damage * TakeDmg[victim];
			}
			return Action:1;
		}
		new var5;
		if (1065353216 != All[attacker][5] && (hitgroup == 1 || hitgroup == 2 || hitgroup == 3 || hitgroup == 4 || hitgroup == 5 || hitgroup == 6 || hitgroup == 7))
		{
			if (0 == All[attacker][5])
			{
				return Action:3;
			}
			damage = damage * All[attacker][5];
			return Action:1;
		}
		new var6;
		if (1065353216 != All[attacker][6] && hitgroup == 1)
		{
			if (0 == All[attacker][6])
			{
				return Action:3;
			}
			damage = damage * All[attacker][6];
			return Action:1;
		}
		new var7;
		if (1065353216 != All[attacker][7] && hitgroup == 2)
		{
			if (0 == All[attacker][7])
			{
				return Action:3;
			}
			damage = damage * All[attacker][7];
			return Action:1;
		}
		new var8;
		if (1065353216 != All[attacker][8] && hitgroup == 3)
		{
			if (0 == All[attacker][8])
			{
				return Action:3;
			}
			damage = damage * All[attacker][8];
			return Action:1;
		}
		new var10;
		if (1065353216 != All[attacker][9] && (hitgroup == 4 || hitgroup == 5))
		{
			if (0 == All[attacker][9])
			{
				return Action:3;
			}
			damage = damage * All[attacker][9];
			return Action:1;
		}
		new var12;
		if (1065353216 != All[attacker][10] && (hitgroup == 6 || hitgroup == 7))
		{
			if (0 == All[attacker][10])
			{
				return Action:3;
			}
			damage = damage * All[attacker][10];
			return Action:1;
		}
		if (StrEqual("knife", WeaponName, false))
		{
			if (0 == All[attacker][5])
			{
				return Action:3;
			}
			damage = damage * All[attacker][5];
			return Action:1;
		}
	}
	return Action:0;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new var1;
	if (attacker > 0 && attacker <= MaxClients && inflictor != attacker)
	{
		decl String:WeaponName[32];
		GetEdictClassname(inflictor, WeaponName, 30);
		ReplaceString(WeaponName, 30, "_projectile", "", false);
		new GetWeaponInfo[14];
		new var2;
		if (IsAdmin[victim] && NoFallDmg[victim] == 1 && damagetype & 32 == 32)
		{
			damage = 0;
			return Action:3;
		}
		if (GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo, 14, 0))
		{
			if (0 == All[attacker][5])
			{
				return Action:3;
			}
			damage = damage * All[attacker][5];
			return Action:1;
		}
	}
	return Action:0;
}

public OnFireBullets(client, shots, String:weaponname[])
{
	return 0;
}

public Action:OnWeaponEquip(client, weapon)
{
	decl String:WeaponName[32];
	GetEdictClassname(weapon, WeaponName, 30);
	ReplaceString(WeaponName, 30, "weapon_", "", false);
	new GetWeaponInfo[14];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo, 14, 0);
	if (All[client][3] != -1)
	{
		ModeStateArray[client][0] = 0;
	}
	if (All[client][11] != -1)
	{
		ModeStateArray[client][1] = 0;
	}
	return Action:0;
}

public Action:OnWeaponSwitch(client, weapon)
{
	BurstShotsFired[client] = 0;
	decl String:WeaponName[32];
	GetEdictClassname(weapon, WeaponName, 30);
	ReplaceString(WeaponName, 30, "weapon_", "", false);
	new GetWeaponInfo[14];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo, 14, 0);
	if (All[client][13] == 1)
	{
		ProcessArray[client][3] = 1;
	}
	return Action:0;
}

 