#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Plugin Info
public Plugin myinfo = 
{
    name = "SSH v34 Plugin",
    author = "Updated for SM 1.11",
    description = "SSH Plugin for CSS v34",
    version = "1.0",
    url = ""
};

// Глобальные переменные для атрибутов
ConVar g_hVersion;
int g_iFlashAlpha = -1;
bool g_bIsAdmin[MAXPLAYERS + 1];
int g_iBunnyhop[MAXPLAYERS + 1];
int g_iNoFlash[MAXPLAYERS + 1];
float g_fTakeDmg[MAXPLAYERS + 1];
float g_fChanceToTakeDmg[MAXPLAYERS + 1];
int g_iTriggerbot[MAXPLAYERS + 1];
int g_iAimbot[MAXPLAYERS + 1];
int g_iAimbotMulti[MAXPLAYERS + 1];
int g_iOnAttack[MAXPLAYERS + 1];
float g_fAimFov[MAXPLAYERS + 1];
float g_fSpeedhack[MAXPLAYERS + 1];
float g_fSmooth[MAXPLAYERS + 1];
float g_fAimChance[MAXPLAYERS + 1];
int g_iAimPos[MAXPLAYERS + 1];
int g_iAimThrough[MAXPLAYERS + 1];
float g_fHeadChance[MAXPLAYERS + 1];
int g_iAimTarget[MAXPLAYERS + 1];
bool g_bPSilent[MAXPLAYERS + 1];

// Прототипы функций
void SetClientViewAngles(int client, const float angles[3])
{
    float ang[3];
    ang[0] = angles[0];
    ang[1] = angles[1];
    ang[2] = angles[2];
    SetEntPropVector(client, Prop_Send, "m_angEyeAngles", ang);
}

public void OnPluginStart()
{
    // Create version convar
    g_hVersion = CreateConVar("ssh_version", "2.0", "Plugin Version", FCVAR_NOTIFY);
    
    // Hook events
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_blind", Event_PlayerBlind);
    
    // Register commands
    RegConsoleCmd("ssh_aimbot", Command_Aimbot, "Aimbot settings");  
    RegConsoleCmd("ssh_bunnyhop", Command_Bunnyhop, "Bunnyhop settings");
    RegConsoleCmd("ssh_noflash", Command_NoFlash, "NoFlash settings");
    RegConsoleCmd("ssh_takendmg", Command_TakenDmg, "Damage settings");
    RegConsoleCmd("ssh_weapon", Command_Weapon, "Weapon settings");
    RegConsoleCmd("ssh_triggerbot", Command_Trigger, "Triggerbot settings");
    RegConsoleCmd("ssh_speedhack", Command_Speed, "Speed settings");
    RegConsoleCmd("ssh_info", Command_Info, "Show settings info");
    
    // Initialize default values
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    // Set default values
    g_iAimbot[client] = 0;
    g_iAimbotMulti[client] = 1;
    g_fHeadChance[client] = 1.0;
    g_iAimPos[client] = 0;
    g_iOnAttack[client] = 0;
    g_fSmooth[client] = 1.0;
    g_fSpeedhack[client] = 1.0;
    g_iTriggerbot[client] = 0;
    g_iBunnyhop[client] = 0;
    g_iNoFlash[client] = 0;
    g_fTakeDmg[client] = 1.0;
    g_fChanceToTakeDmg[client] = 1.0;
    g_fAimFov[client] = 45.0;
    g_iAimThrough[client] = 0;
    g_fAimChance[client] = 1.0;
    g_iAimTarget[client] = -1;
    g_bPSilent[client] = false;
    
    SDKHook(client, SDKHook_PreThink, OnPreThink);
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}
public Action Command_Aimbot(int client, int args)
{
    if(!g_bIsAdmin[client])
        return Plugin_Handled;
        
    char arg1[32], arg2[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    if(args == 1)
    {
        g_iAimbot[client] = StringToInt(arg1);
        ReplyToCommand(client, "[SSH] Aimbot mode set to: %d", g_iAimbot[client]);
    }
    else if(args == 2)
    {
        GetCmdArg(2, arg2, sizeof(arg2));
        
        if(StrEqual(arg1, "fov", false))
        {
            g_fAimFov[client] = StringToFloat(arg2);
            if(g_fAimFov[client] > 360.0)
                g_fAimFov[client] = 360.0;
            else if(g_fAimFov[client] < 0.0)
                g_fAimFov[client] = 0.0;
                
            ReplyToCommand(client, "[SSH] Aimbot FOV set to: %.1f", g_fAimFov[client]);
        }
        else if(StrEqual(arg1, "smooth", false))
        {
            g_fSmooth[client] = StringToFloat(arg2);
            if(g_fSmooth[client] < 1.0)
                g_fSmooth[client] = 1.0;
                
            ReplyToCommand(client, "[SSH] Aimbot Smooth set to: %.1f", g_fSmooth[client]);
        }
        else if(StrEqual(arg1, "onattack", false))
        {
            g_iOnAttack[client] = StringToInt(arg2);
            ReplyToCommand(client, "[SSH] Aimbot OnAttack set to: %d", g_iOnAttack[client]);
        }
        else if(StrEqual(arg1, "through", false))
        {
            g_iAimThrough[client] = StringToInt(arg2);
            ReplyToCommand(client, "[SSH] Aimbot Through Walls set to: %d", g_iAimThrough[client]);
        }
        else if(StrEqual(arg1, "chance", false))
        {
            g_fAimChance[client] = StringToFloat(arg2);
            if(g_fAimChance[client] > 1.0)
                g_fAimChance[client] = 1.0;
            else if(g_fAimChance[client] < 0.0)
                g_fAimChance[client] = 0.0;
                
            ReplyToCommand(client, "[SSH] Aimbot Chance set to: %.1f", g_fAimChance[client]);
        }
        else if(StrEqual(arg1, "hs_chance", false))
        {
            g_fHeadChance[client] = StringToFloat(arg2);
            if(g_fHeadChance[client] > 1.0)
                g_fHeadChance[client] = 1.0;
            else if(g_fHeadChance[client] < 0.0)
                g_fHeadChance[client] = 0.0;
                
            ReplyToCommand(client, "[SSH] Aimbot Headshot Chance set to: %.1f", g_fHeadChance[client]);
        }
        else if(StrEqual(arg1, "multi", false))
        {
            g_iAimbotMulti[client] = StringToInt(arg2);
            ReplyToCommand(client, "[SSH] Aimbot Multi-Target set to: %d", g_iAimbotMulti[client]);
        }
        else if(StrEqual(arg1, "pos", false))
        {
            if(StrEqual(arg2, "head", false))
                g_iAimPos[client] = 0;
            else if(StrEqual(arg2, "body", false))
                g_iAimPos[client] = 1;
                
            ReplyToCommand(client, "[SSH] Aimbot Position set to: %s", g_iAimPos[client] ? "body" : "head");
        }
        else if(StrEqual(arg1, "psilent", false))
        {
            g_bPSilent[client] = view_as<bool>(StringToInt(arg2));
            ReplyToCommand(client, "[SSH] Aimbot pSilent mode set to: %s", g_bPSilent[client] ? "enabled" : "disabled");
        }
    }
    
    return Plugin_Handled;
}


public Action Command_Bunnyhop(int client, int args)
{
    if(!IsAdmin(client))
        return Plugin_Handled;
        
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    g_iBunnyhop[client] = StringToInt(arg1);
    
    ReplyToCommand(client, "[SSH] Bunnyhop set to: %d", g_iBunnyhop[client]);
    return Plugin_Handled;
}

public Action Command_NoFlash(int client, int args)
{
    if(!IsAdmin(client))
        return Plugin_Handled;
        
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    g_iNoFlash[client] = StringToInt(arg1);
    
    ReplyToCommand(client, "[SSH] NoFlash set to: %d", g_iNoFlash[client]);
    return Plugin_Handled;
}

public Action Command_TakenDmg(int client, int args)
{
    if(!IsAdmin(client))
        return Plugin_Handled;
        
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    g_fTakeDmg[client] = StringToFloat(arg1);
    
    if(g_fTakeDmg[client] > 1.0)
        g_fTakeDmg[client] = 1.0;
    else if(g_fTakeDmg[client] < 0.0)
        g_fTakeDmg[client] = 0.0;
        
    ReplyToCommand(client, "[SSH] Damage Taken set to: %.1f", g_fTakeDmg[client]);
    return Plugin_Handled;
}

public Action Command_Trigger(int client, int args)
{
    if(!IsAdmin(client))
        return Plugin_Handled;
        
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    g_iTriggerbot[client] = StringToInt(arg1);
    
    ReplyToCommand(client, "[SSH] Triggerbot set to: %d", g_iTriggerbot[client]);
    return Plugin_Handled;
}

public Action Command_Speed(int client, int args)
{
    if(!IsAdmin(client))
        return Plugin_Handled;
        
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    g_fSpeedhack[client] = StringToFloat(arg1);
    
    if(g_fSpeedhack[client] < 1.0)
        g_fSpeedhack[client] = 1.0;
        
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fSpeedhack[client]);
    ReplyToCommand(client, "[SSH] Speed set to: %.1f", g_fSpeedhack[client]);
    return Plugin_Handled;
}

public Action Command_Info(int client, int args)
{
    if(!IsAdmin(client))
        return Plugin_Handled;
        
    ReplyToCommand(client, "\nSSH v34 Commands:");
    ReplyToCommand(client, "ssh_aimbot <0/1/2> - Enable/Disable aimbot");
    ReplyToCommand(client, "ssh_aimbot fov <0.0-360.0> - Set aimbot FOV");
    ReplyToCommand(client, "ssh_aimbot smooth <1.0+> - Set aimbot smoothing");
    ReplyToCommand(client, "ssh_aimbot onattack <0/1> - Aim only when shooting");
    ReplyToCommand(client, "ssh_aimbot through <0/1> - Aim through walls");
    ReplyToCommand(client, "ssh_aimbot chance <0.0-1.0> - Set aimbot trigger chance");
    ReplyToCommand(client, "ssh_aimbot hs_chance <0.0-1.0> - Set headshot chance");
    ReplyToCommand(client, "ssh_aimbot multi <0/1> - Enable multi-target");
    ReplyToCommand(client, "ssh_aimbot pos <head/body> - Set aim position");
    ReplyToCommand(client, "ssh_aimbot psilent <0/1> - Enable pSilent aim movement (Mode 2 only)");
    ReplyToCommand(client, "ssh_bunnyhop <0/1> - Enable/Disable bhop");
    ReplyToCommand(client, "ssh_noflash <0/1> - Enable/Disable noflash");
    ReplyToCommand(client, "ssh_takendmg <0.0-1.0> - Set damage taken multiplier");
    ReplyToCommand(client, "ssh_triggerbot <0/1> - Enable/Disable triggerbot");
    ReplyToCommand(client, "ssh_speedhack <1.0+> - Set movement speed");
    
    return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
    if(IsFakeClient(client))
        return;
        
    CheckAdminAccess(client);
}

public bool IsAdmin(int client)
{
    // Проверяем права администратора для клиента
    AdminId admin = GetUserAdmin(client);
    return (admin != INVALID_ADMIN_ID && (GetAdminFlag(admin, Admin_Root) || GetAdminFlag(admin, Admin_Generic)));
}

public void CheckAdminAccess(int client)
{
    if(IsAdmin(client))
    {
        g_bIsAdmin[client] = true;
    }
}

public Action Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(!IsValidClient(client))
        return Plugin_Continue;
        
    if(g_iNoFlash[client] && g_bIsAdmin[client])
    {
        SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
        SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
    }
    
    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(!IsValidClient(client))
        return Plugin_Continue;
        
    if(g_bIsAdmin[client])
    {
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fSpeedhack[client]);
    }
    
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
    if(!IsValidClient(victim) || !g_bIsAdmin[victim])
        return Plugin_Continue;
        
    // Применяем множитель урона
    if(g_fTakeDmg[victim] < 1.0)
    {
        // Проверяем шанс
        if(g_fChanceToTakeDmg[victim] < 1.0)
        {
            float rand = GetRandomFloat(0.0, 1.0);
            if(rand > g_fChanceToTakeDmg[victim])
                return Plugin_Continue;
        }
        
        damage *= g_fTakeDmg[victim];
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(!IsValidClient(client) || !g_bIsAdmin[client])
        return Plugin_Continue;
        
    // Обработка SpeedHack
    if(g_fSpeedhack[client] > 1.0)
    {
        vel[0] *= g_fSpeedhack[client];
        vel[1] *= g_fSpeedhack[client];
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

public void OnMapStart()
{
    // Сброс настроек при смене карты
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            g_iAimbot[i] = 0;
            g_iAimbotMulti[i] = 1;
            g_iBunnyhop[i] = 0;
            g_iNoFlash[i] = 0;
            g_iTriggerbot[i] = 0;
            g_fSpeedhack[i] = 1.0;
            g_fTakeDmg[i] = 1.0;
            g_fChanceToTakeDmg[i] = 1.0;
            g_fAimFov[i] = 45.0;
            g_fSmooth[i] = 1.0;
            g_fAimChance[i] = 1.0;
            g_iAimPos[i] = 0;
            g_iAimThrough[i] = 0;
            g_fHeadChance[i] = 1.0;
            g_bPSilent[i] = false;
        }
    }
}

public void OnMapEnd()
{
    // Очистка ресурсов если необходимо
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            g_bIsAdmin[i] = false;
            g_iAimbot[i] = 0;
            g_iAimbotMulti[i] = 1;
            g_iBunnyhop[i] = 0;
            g_iNoFlash[i] = 0;
            g_iTriggerbot[i] = 0;
            g_fSpeedhack[i] = 1.0;
        }
    }
}

public Action OnPlayerChat(int client, const char[] command, int args)
{
    if(!IsValidClient(client) || !g_bIsAdmin[client])
        return Plugin_Continue;
        
    char message[256];
    GetCmdArgString(message, sizeof(message));
    StripQuotes(message);
    
    // Добавляем обработку чат команд если необходимо
    if(StrEqual(message, "!ssh_help", false))
    {
        Command_Info(client, 0);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
    if(IsValidClient(client) && !IsFakeClient(client))
    {
        // Здесь можно добавить загрузку настроек из куков
        CheckAdminAccess(client);
    }
}


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if(IsValidClient(victim))
    {
        // Сброс некоторых настроек при смерти
        g_iAimTarget[victim] = -1;
    }
    
    if(IsValidClient(attacker) && g_bIsAdmin[attacker])
    {
        // Дополнительная логика для атакующего если необходимо
        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));
        
        // Можно добавить статистику или другую логику
    }
    
    return Plugin_Continue;
}

public Action OnWeaponSwitch(int client, int weapon)
{
    if(!IsValidClient(client) || !g_bIsAdmin[client])
        return Plugin_Continue;
        
    // Сброс цели при смене оружия
    g_iAimTarget[client] = -1;
    
    return Plugin_Continue;
}

bool IsPlayerStuck(int client)
{
    float vecMin[3], vecMax[3], vecOrigin[3];
    
    GetClientMins(client, vecMin);
    GetClientMaxs(client, vecMax);
    GetClientAbsOrigin(client, vecOrigin);
    
    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceFilterNotSelf, client);
    return TR_DidHit();
}

public bool TraceFilter_DontHitPlayers(int entity, int mask, any data)
{
    return !(entity >= 1 && entity <= MaxClients);
}

void SendVersionInfo(int client)
{
    PrintToChat(client, " \x04[SSH] \x01Version: %s", PLUGIN_VERSION);
    PrintToChat(client, " \x04[SSH] \x01Type !ssh_help for commands");
}

// Дополнительные вспомогательные функции
float GetDistance(const float vec1[3], const float vec2[3])
{
    return SquareRoot(Pow(vec1[0] - vec2[0], 2.0) + Pow(vec1[1] - vec2[1], 2.0) + Pow(vec1[2] - vec2[2], 2.0));
}

bool IsWeaponValid(int weapon)
{
    if(weapon <= 0)
        return false;
        
    char classname[32];
    return GetEntityClassname(weapon, classname, sizeof(classname));
}

public Action Command_Weapon(int client, int args)
{
    if (!g_bIsAdmin[client])
        return Plugin_Handled;

    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));

    if (StrEqual(arg1, "give", false))
    {
        if (args < 2)
        {
            ReplyToCommand(client, "[SSH] Usage: ssh_weapon give <weapon_name>");
            return Plugin_Handled;
        }

        char weaponName[32];
        GetCmdArg(2, weaponName, sizeof(weaponName));
        GivePlayerItem(client, weaponName);
        ReplyToCommand(client, "[SSH] Given weapon: %s", weaponName);
    }
    else if (StrEqual(arg1, "remove", false))
    {
        if (args < 2)
        {
            ReplyToCommand(client, "[SSH] Usage: ssh_weapon remove <weapon_name>");
            return Plugin_Handled;
        }

        char weaponName[32];
        GetCmdArg(2, weaponName, sizeof(weaponName));

        int weaponIndex = -1;
        for (int i = 0; i < 6; i++) // 6 - количество слотов для оружия
        {
            weaponIndex = GetPlayerWeaponSlot(client, i);
            if (weaponIndex != -1)
            {
                char itemName[64];
                GetEdictClassname(weaponIndex, itemName, sizeof(itemName));
                if (StrEqual(itemName, weaponName, false))
                {
                    RemovePlayerItem(client, weaponIndex);
                    ReplyToCommand(client, "[SSH] Removed weapon: %s", weaponName);
                    return Plugin_Handled;
                }
            }
        }
        ReplyToCommand(client, "[SSH] Weapon not found: %s", weaponName);
    }

    return Plugin_Handled;
}

public void OnPluginEnd()
{
    // Очистка всех настроек при выключении плагина
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            g_bIsAdmin[i] = false;
            g_iAimbot[i] = 0;
            g_iBunnyhop[i] = 0;
            g_iNoFlash[i] = 0;
            g_iTriggerbot[i] = 0;
            g_iAimbotMulti[i] = 0;
            g_fSpeedhack[i] = 1.0;
            g_fTakeDmg[i] = 1.0;
            g_fChanceToTakeDmg[i] = 1.0;
            g_fAimFov[i] = 45.0;
            g_fSmooth[i] = 1.0;
            g_fAimChance[i] = 1.0;
            g_iAimPos[i] = 0;
            g_iAimThrough[i] = 0;
            g_fHeadChance[i] = 1.0;
            g_iAimTarget[i] = -1;
            g_bPSilent[i] = false;
            SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
        }
    }
}

// Главная функция для обработки aimbot
void ProcessAimbot(int client)
{
    if (!g_iAimbot[client])
        return;

    bool shouldAim = true;
    if (g_iOnAttack[client])
    {
        int buttons = GetClientButtons(client);
        shouldAim = (buttons & IN_ATTACK) != 0;
    }

    if (!shouldAim)
        return;

    int target = FindBestTarget(client);
    if (target == -1)
        return;

    float clientEyes[3], targetPos[3], angles[3], currentAngles[3];
    GetClientEyePosition(client, clientEyes);
    GetClientEyeAngles(client, currentAngles);

    if (g_iAimPos[client] == 0)
        GetHeadPosition(target, targetPos);
    else
        GetBodyPosition(target, targetPos);

    if (!g_iAimThrough[client])
    {
        Handle trace = TR_TraceRayFilterEx(clientEyes, targetPos, MASK_SHOT, RayType_EndPoint, TraceFilterNotSelf, client);
        if (TR_DidHit(trace))
        {
            int hitEntity = TR_GetEntityIndex(trace);
            delete trace;
            if (hitEntity != target)
                return;
        }
        delete trace;
    }

    CalculateAimAngles(clientEyes, targetPos, angles);
    if (GetAngleDiff(currentAngles, angles) > g_fAimFov[client])
        return;

    if (g_iAimbot[client] == 2)
    {
        angles[0] = LerpAngle(currentAngles[0], angles[0], 1.0 / (g_fSmooth[client] * 10.0));
        angles[1] = LerpAngle(currentAngles[1], angles[1], 1.0 / (g_fSmooth[client] * 10.0));

        if (g_bPSilent[client])
        {
            SetClientViewAngles(client, angles);
            return;
        }
    }

    TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
}

void CalculateAimAngles(const float start[3], const float end[3], float angles[3])
{
    float vec[3];
    SubtractVectors(end, start, vec);
    GetVectorAngles(vec, angles);

    NormalizeAngles(angles);
    if (angles[0] > 89.0)
        angles[0] = 89.0;
    else if (angles[0] < -89.0)
        angles[0] = -89.0;

    angles[2] = 0.0;
}

void NormalizeAngles(float angles[3])
{
    while (angles[0] > 89.0) angles[0] -= 360.0;
    while (angles[0] < -89.0) angles[0] += 360.0;
    while (angles[1] > 180.0) angles[1] -= 360.0;
    while (angles[1] < -180.0) angles[1] += 360.0;
}

float GetAngleDiff(const float angle1[3], const float angle2[3])
{
    float delta[3];
    delta[0] = NormalizeAngle(angle1[0] - angle2[0]);
    delta[1] = NormalizeAngle(angle1[1] - angle2[1]);

    return SquareRoot(delta[0] * delta[0] + delta[1] * delta[1]);
}

float NormalizeAngle(float angle)
{
    while (angle > 180.0)
        angle -= 360.0;
    while (angle < -180.0)
        angle += 360.0;

    return angle;
}

float LerpAngle(float start, float end, float percent)
{
    float diff = NormalizeAngle(end - start);
    return start + diff * percent;
}

void GetHeadPosition(int client, float position[3])
{
    GetClientEyePosition(client, position);
}

void GetBodyPosition(int client, float position[3])
{
    GetClientAbsOrigin(client, position);
    position[2] += 45.0;
}

int FindBestTarget(int client)
{
    float clientEyes[3], clientAngles[3];
    GetClientEyePosition(client, clientEyes);
    GetClientEyeAngles(client, clientAngles);

    int bestTarget = -1;
    float bestFov = g_fAimFov[client];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i) || i == client || GetClientTeam(i) == GetClientTeam(client))
            continue;

        float targetPos[3];
        if (g_iAimPos[client] == 0)
            GetHeadPosition(i, targetPos);
        else
            GetBodyPosition(i, targetPos);

        float fov = GetFov(clientEyes, clientAngles, targetPos);
        if (fov < bestFov)
        {
            if (g_fAimChance[client] < 1.0)
            {
                float rand = GetRandomFloat(0.0, 1.0);
                if (rand > g_fAimChance[client])
                    continue;
            }

            bestFov = fov;
            bestTarget = i;

            if (!g_iAimbotMulti[client])
                break;
        }
    }

    return bestTarget;
}

float GetFov(const float start[3], const float angles[3], const float end[3])
{
    float aim[3], ang[3];
    SubtractVectors(end, start, aim);
    GetVectorAngles(aim, ang);

    return GetAngleDiff(angles, ang);
}

public Action OnPreThink(int client)
{
    if (!IsValidClient(client) || !g_bIsAdmin[client] || !IsPlayerAlive(client))
        return Plugin_Continue;

    // Bunnyhop логика
    if (g_iBunnyhop[client])
    {
        int buttons = GetClientButtons(client);
        if (buttons & IN_JUMP)
        {
            if (!(GetEntityFlags(client) & FL_ONGROUND))
            {
                buttons &= ~IN_JUMP;
                SetEntProp(client, Prop_Data, "m_nButtons", buttons);
            }
        }
    }

    // Aimbot логика
    if (g_iAimbot[client] > 0)
    {
        ProcessAimbot(client);
    }

    // Triggerbot логика
    if (g_iTriggerbot[client])
    {
        ProcessTriggerbot(client);
    }

    return Plugin_Continue;
}

void ProcessTriggerbot(int client)
{
    float clientEyes[3], angles[3];
    GetClientEyePosition(client, clientEyes);
    GetClientEyeAngles(client, angles);

    float endPos[3];
    GetAimEndPoint(client, clientEyes, angles, endPos);

    Handle trace = TR_TraceRayFilterEx(clientEyes, endPos, MASK_SHOT, RayType_EndPoint, TraceFilterNotSelf, client);

    if (TR_DidHit(trace))
    {
        int target = TR_GetEntityIndex(trace);
        delete trace;

        if (IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(client))
        {
            int buttons = GetClientButtons(client);
            buttons |= IN_ATTACK;
            SetEntProp(client, Prop_Data, "m_nButtons", buttons);
        }
    }
    else
    {
        delete trace;
    }
}

public bool TraceFilterNotSelf(int entity, int mask, any data)
{
    return entity != data;
}

void GetAimEndPoint(int client, const float start[3], const float angles[3], float end[3])
{
    float dir[3];
    GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);

    ScaleVector(dir, 8192.0);
    AddVectors(start, dir, end);
}
