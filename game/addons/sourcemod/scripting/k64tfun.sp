/*
Feature 1. Bomber gets a bonus equipment: grenades, armor
1 Бомба взрывается при попадании в бомбера с вероятностью
2 Если игрок заработал 16000, всем дарит броники
3 Падает оружие при попадании в правую руку
4 При ранении следы крови
5 При ранении в голову красное затемнение
6 Бомбер получает обмундирование, грены
*/
#define nDEBUG 1
#define PLUGIN_NAME  "k64t-fun"
#define PLUGIN_VERSION "0.4"
#define USE_WEAPON true
#define USE_PLAYER true
#define GAME_CSS true
#include <k64t>

#include <sdkhooks>
#define SOUND_FOLDER "k64t"
#define DOWNLOAD_SOUND_FOLDER "sound/k64t"
#define knife_kill_sound    "kaban4eg.mp3"
#define knife_tm_kill_sound "knife_tm_kill_sound.mp3"

#define Feature_1 1//Bomber gets a bonus equipment: grenades, armor


int g_iAccount = -1; 
//********************************************************12*********************
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Make some fun",
	version = PLUGIN_VERSION,
	url = "https://github.com/k64t34/k64t-fun"};
//*****************************************************************************
char fknife_kill_sound[PLATFORM_MAX_PATH];
char fknife_tm_kill_sound[PLATFORM_MAX_PATH];
float HeGrenadeOrigin[3]; //координаты детонации гранаты
float vClientOrigin[3];
float Vec[3];
float Vel[3];
float Angs[3];
float Slap[3];
char strWeapon[MAX_WEAPON_NAME];
int vClientId,aClientId,demage;
float ttimer;
#if defined DEBUG 
char PName[MAX_CLIENT_NAME];
#endif
//int g_iAccount = -1;
Handle cvar_mp_startmoney  = INVALID_HANDLE;
int g_mp_startmoney=800;
#define MAX_STRING 32
int g_iFlashDuration = -1;
//*****************************************************************************
public void OnMapStart(){
//*****************************************************************************
PrecacheSound(fknife_kill_sound, true);	
PrecacheSound(fknife_tm_kill_sound, true);	
char buffer[PLATFORM_MAX_PATH];
Format(buffer, PLATFORM_MAX_PATH, "%s/%s\0",DOWNLOAD_SOUND_FOLDER,knife_kill_sound);	
AddFileToDownloadsTable(buffer);
Format(buffer, PLATFORM_MAX_PATH, "%s/%s\0",DOWNLOAD_SOUND_FOLDER,knife_tm_kill_sound);	
AddFileToDownloadsTable(buffer);

}
//*****************************************************************************
public void OnPluginStart(){	
//*****************************************************************************
#if defined DEBUG 
	PrintToServer("%s %s",PLUGIN_NAME,PLUGIN_VERSION);	
#endif
HookEvent("hegrenade_detonate", eHerenade_detonate);
HookEvent("player_hurt", ePlayer_hurt);
HookEvent("flashbang_detonate", Event_FlashBangDetonate);
HookEvent("player_blind",Event_Flashed);
HookEvent("player_death", EventPlayerDeath);
HookEvent("player_team", EventPlayerTeam);
g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
if (g_iAccount == -1) SetFailState("Could not find m_iAccount");
HookEvent("round_start",	EventRoundStart,	EventHookMode_PostNoCopy);
cvar_mp_startmoney = FindConVar("mp_startmoney");
if ( cvar_mp_startmoney != INVALID_HANDLE )
	g_mp_startmoney	=GetConVarInt(cvar_mp_startmoney);
g_iFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
Format(fknife_tm_kill_sound, PLATFORM_MAX_PATH, "%s\\%s",SOUND_FOLDER,knife_tm_kill_sound);	
Format(fknife_kill_sound,    PLATFORM_MAX_PATH, "%s\\%s",SOUND_FOLDER,knife_kill_sound);	
}
//***********************************************
public void  EventRoundStart(Handle event, const char[] name ,bool dontBroadcast){
//***********************************************
bool BombPresent=false;
if (FindEntityByClassname(-1,"weapon_c4")!=-1) BombPresent=true; 
for (int i = 1; i <= MaxClients; i++)
        {      
		if (IsClientInGame(i) && IsPlayerAlive(i))
			{
			if (IsValidClient(i)) if (!IsFakeClient(i))
				{
				int plr_money=GetEntData(i, g_iAccount, 4);
				#if defined Feature_1				
				 if (GetClientTeam(i)==CS_TEAM_T && GetPlayerWeaponSlot(i, Slot_Explosive) != -1)
					{
					SponsorGiveItem(i,i_assaultsuit);
					SponsorGiveItem(i,i_vest);					
					SponsorGiveItem(i,i_nvgs);
					SponsorGiveItem(i,i_hegrenade);
					SponsorGiveItem(i,i_flashbang);
					SponsorGiveItem(i,i_flashbang);
					SponsorGiveItem(i,i_smokegrenade);					
					}
				#endif	
				 
				if (plr_money==16000)
					{
					//SetEntProp(i, Prop_Send, "m_ArmorValue", 127);
					//SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);
					/*int b_team=GetClientTeam(i);
					for (int j = 1; j <= MaxClients; j++)
						{
						if (i!=j)if (GetClientTeam(j)==b_team) 
							{
							//SponsorGiveWeapon(j, "weapon_hegrenade");
							}
						}	
					
					*/	
					}
				else	
					{
					#if defined DEBUG
					DebugPrint("Begin sponsore %d",i);
					if (true)					
					#else
					if (GetRandomInt(0,plr_money)<=g_mp_startmoney)					
					#endif					
						{
						int iItem=GetRandomInt(i_vest,i_nvgs);
						#if defined DEBUG
						DebugPrint("iItem=%d %s",iItem,g_WeaponItemNames[iItem]);				
						#endif
						if (iItem==i_defuser)
							{
							if (GetClientTeam(i)==CS_TEAM_T) iItem++;
							else if (GetClientTeam(i)==CS_TEAM_CT && !BombPresent) iItem++;													
							}
						SponsorGiveItem(i,iItem);	
						}	
					//if (BombPresent	&& GetClientTeam(i)==CS_TEAM_CT) if (GetRandomInt(0,plr_money)<=g_mp_startmoney) SponsorGiveItem(i, "item_defuser");		

					//else if (GetRandomInt(0,plr_money)<=g_mp_startmoney)SponsorGiveItem(i, "item_assaultsuit");
					//else if (GetRandomInt(0,plr_money)<=g_mp_startmoney)SponsorGiveItem(i, "item_kevlar");
					
					//else if (GetRandomInt(0,plr_money)<=g_mp_startmoney)SponsorGiveItem(i, "item_nvgs");*/

					
					//			else if (GetRandomInt(0,plr_money)<=g_mp_startmoney)GivePlayerItem(i, "weapon_c4");	


					
				
					// On Map Start Function:
					// public OnMapStart() 
					// {
					// int ent = -1;
					// int ent2 = -1;
					// while((ent = FindEntityByClassname(ent,"func_buyzone")) != -1) 
					// {
					// if (IsValidEdict(ent))
					// { 
					// PrintToServer("Disabled a func_buyzone with an entid of %i",ent);
					// AcceptEntityInput(ent,"Disable");
					// }
					// }
					// if((FindEntityByClassname( ent2, "func_bomb_target" )) != -1)
					// {
					// g_HasBombZone = true;
					// PrintToChatAll("This map has a Bomb Zone");
					// }
					// else
					// {
					// g_HasBombZone = false;
					// PrintToChatAll("This map doesnt have a bomb Zone");
					// }
					// }	
					}
				}
			}
		}
}
//***********************************************
bool SponsorGiveWeapon(int client,const char[] weapon){
//***********************************************
#if defined DEBUG
DebugPrint("SponsorGiveWeapon %s to %d",weapon,client);
#endif
bool SponsorGiveWeapon=!WeaponsClientHasWeapon(client,weapon);
if (SponsorGiveWeapon) 	
	if (!SponsorGivePlayerItem(client,weapon))
		SponsorGiveWeapon=false;		
return SponsorGiveWeapon;	
}
//***********************************************
bool SponsorGiveItem(int client, int iItem){
//***********************************************
bool  SponsorGiveItem=false;
if (g_WeaponItemType[iItem]==1)		
	SponsorGiveItem=SponsorGiveWeapon(client,g_WeaponItemNames[iItem]);	
else if (g_WeaponItemType[iItem]==0)
	{	
	if (strcmp(g_WeaponItemNames[iItem],"item_nvgs") == 0)
		{
		SponsorGiveItem=(GetEntProp(client, Prop_Send, "m_bHasNightVision")==0);
		if(SponsorGiveItem)
			if (!SponsorGivePlayerItem(client,g_WeaponItemNames[iItem]))
				SponsorGiveItem=false;
		}
	else if (strcmp(g_WeaponItemNames[iItem],g_WeaponItemNames[i_vest]) == 0)
		{
		SponsorGiveItem=(GetEntProp(client, Prop_Send, "m_ArmorValue") <100);
		if(SponsorGiveItem)
			if (!SponsorGivePlayerItem(client,g_WeaponItemNames[iItem]))
				SponsorGiveItem=false;
		}
	else if (strcmp(g_WeaponItemNames[iItem],"item_assaultsuit") == 0)
		{
		SponsorGiveItem=(GetEntProp(client, Prop_Send, "m_bHasHelmet") == 0);
		if(SponsorGiveItem)
			if (!SponsorGivePlayerItem(client,g_WeaponItemNames[iItem]))
				SponsorGiveItem=false;
		}
	else if (strcmp(g_WeaponItemNames[iItem],"item_defuser") == 0)
		{
		SponsorGiveItem=(GetEntProp(client, Prop_Send, "m_bHasDefuser") == 0);
		if(SponsorGiveItem)
			if (!SponsorGivePlayerItem(client,g_WeaponItemNames[iItem]))
				SponsorGiveItem=false;
		}
	}	
return SponsorGiveItem;
}
//***********************************************
int SponsorGivePlayerItem(int client,const char[] item){
//***********************************************
#if defined DEBUG
DebugPrint("SponsorGivePlayer %d Item %s",client,item);
#endif
int SponsorGivePlayerItem=true;
if (GivePlayerItem(client,item)==-1)
	SponsorGivePlayerItem=false;	
else		
	PrintToChat(client,"Unknown sponsor give you %s",item);	
return SponsorGivePlayerItem;
}


//*****************************************************************************
public Action eHerenade_detonate(Handle event, const char[] name, bool dontBroadcast){
//*****************************************************************************
HeGrenadeOrigin[0]=GetEventFloat(event, "x");
HeGrenadeOrigin[1]=GetEventFloat(event, "y");
HeGrenadeOrigin[2]=GetEventFloat(event, "z");
#if defined DEBUG2 
int Plrid;
Plrid=GetClientOfUserId(GetEventInt(event, "userid"));
GivePlayerItem(Plrid, "weapon_hegrenade");
//PrintToChatAll("%s %s Give hegrenade to %d",PLUGIN_NAME,PLUGIN_VERSION,Plrid);	
#endif
}

//*****************************************************************************
public Action Event_Flashed(Handle event, const char[] name, bool dontBroadcast){
//*****************************************************************************
int Client = GetClientOfUserId(GetEventInt(event, "userid"));
if (Client!=0){
	float Angs[3];
	GetClientEyeAngles(Client, Angs);
	float duration = GetEntDataFloat(Client, g_iFlashDuration);
	Angs[0]+=GetRandomFloat(-duration,duration);
	if (Angs[0]<-90.0) Angs[0]+=180.0;else if (Angs[0]>90.0) Angs[0]-=180.0;
	Angs[1]+=GetRandomFloat(-duration,duration);
	if (Angs[1]<-180.0) Angs[1]+=360.0;else if (Angs[1]>180.0) Angs[1]-=360.0;
	TeleportEntity(Client,NULL_VECTOR,Angs,NULL_VECTOR);
	}
}

/*

Пыталсч сдетонировать гранату
public Action Timer_OnStartDetonate(Handle:timer, any:ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != INVALID_ENT_REFERENCE)
		{
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
		SetEntProp( entity, Prop_Data, "m_takedamage", 2 );
		SetEntProp( entity, Prop_Data, "m_iHealth", 1 );	
		SDKHooks_TakeDamage(entity, 0, 0, 1.0);
        
		}
}
*/
//*****************************************************************************
public Action Timer_KillAfterFlashEffect(Handle timer, any ref){
//*****************************************************************************
int entity = EntRefToEntIndex(ref);
if(entity != INVALID_ENT_REFERENCE)AcceptEntityInput(entity, "kill");
}
//*****************************************************************************
public Action Event_FlashBangDetonate(Handle event, const char[] name, bool dontBroadcast){
//*****************************************************************************
//Работает
#if defined DEBUG 
SetEntPropFloat(GetClientOfUserId(GetEventInt(event, "userid")), Prop_Send, "m_flFlashDuration", 0.0);
//Время ослепление - расчетное движком
//float Time = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");	  
#endif
//int index = CreateEntityByName("smokegrenade_projectile"); 
//int index = CreateEntityByName("hegrenade_projectile"); 
//int index = CreateEntityByName("flashbang_projectile"); 

int index = CreateEntityByName("env_steam");
if (index>=0) 
	{
	float GrenadeOrigin[3]; //координаты детонации гранаты
	GrenadeOrigin[0]=GetEventFloat(event, "x");
	GrenadeOrigin[1]=GetEventFloat(event, "y");
	GrenadeOrigin[2]=GetEventFloat(event, "z");
	DispatchKeyValueVector(index, "origin", GrenadeOrigin); 
	char tName[128];
	Format(tName, sizeof(tName), "target");
	char flame_name2[128];
	Format(flame_name2, sizeof(flame_name2), "Flame2");
	int flame2 = CreateEntityByName("env_steam");
						DispatchKeyValue(flame2,"targetname", flame_name2);
						DispatchKeyValue(flame2, "parentname", tName);
						DispatchKeyValue(flame2,"SpawnFlags", "1");
						DispatchKeyValue(flame2,"Type", "1");
						DispatchKeyValue(flame2,"InitialState", "1");
						DispatchKeyValue(flame2,"Spreadspeed", "10");
						DispatchKeyValue(flame2,"Speed", "600");
						DispatchKeyValue(flame2,"Startsize", "50");
						DispatchKeyValue(flame2,"EndSize", "400");
						DispatchKeyValue(flame2,"Rate", "10");
						DispatchKeyValue(flame2,"JetLength", "500");
						DispatchSpawn(flame2);
						TeleportEntity(flame2, GrenadeOrigin, NULL_VECTOR, NULL_VECTOR);
						SetVariantString(tName);
						AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
						
						SetVariantString("forward");
						
						AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
						AcceptEntityInput(flame2, "TurnOn");
						CreateTimer(1.5, Timer_KillAfterFlashEffect, flame2);
						
						//return;
	TeleportEntity(index, GrenadeOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(index, "rendercolor", "0 0 0");
	
	DispatchKeyValue(index, "StartSize", "15");
	DispatchKeyValue(index, "EndSize", "45");
	DispatchKeyValue(index, "Rate", "26");
	DispatchKeyValue(index, "JetLength", "150");
	DispatchKeyValue(index, "renderamt", "255");
	
	
	DispatchKeyValue(index, "InitialState", "1");
	
	
	DispatchKeyValue(index,"SpawnFlags", "1");
		DispatchKeyValue(index,"Type", "0");
		DispatchKeyValue(index,"InitialState", "1");
		DispatchKeyValue(index,"Spreadspeed", "10");
		DispatchKeyValue(index,"Speed", "800");
		DispatchKeyValue(index,"Startsize", "10");
		DispatchKeyValue(index,"EndSize", "250");
		DispatchKeyValue(index,"Rate", "15");
		DispatchKeyValue(index,"JetLength", "400");
		DispatchKeyValue(index,"RenderColor", "180 71 8");
		DispatchKeyValue(index,"RenderAmt", "180");
	
	SetEntPropFloat(index, Prop_Data, "m_flLaggedMovementValue", 1.10);
	
	DispatchSpawn(index); 
	AcceptEntityInput(index, "TurnOn");
	
	#if defined DEBUG
	DebugPrint("Active steem");
	#endif
	//ActivateEntity(index);	

	//CreateTimer(0.1, Timer_OnStartDetonate, index);
    	
	//SDKHook(index, SDKHook_StartTouch, GrenadeTouchHook);
	//SDKHook(index, SDKHook_OnTakeDamage, GrenadeDamageHook);   
	
	//SetEntProp(index, Prop_Data, "m_takedamage", 2);
	
	
	/*//Insta Detonate stickies
	Handle g_hDetonate;
	GameConf = LoadGameConfigFile("rtd");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "Detonate");
	g_hDetonate = EndPrepSDKCall();
		
	
	SDKCall(g_hDetonate, index);*/
	
	
    //DispatchKeyValue(index, "spawnflags", "1"); 	
	
    
	//ActivateEntity(index);	
	//AcceptEntityInput(index, "TurnOn");
	
	}
}
//*****************************************************************************
public Action ePlayer_hurt(Handle event, const char[] name, bool dontBroadcast){
//*****************************************************************************
GetEventString(event,"weapon",strWeapon,MAX_WEAPON_NAME);
vClientId = GetClientOfUserId(GetEventInt(event, "userid"));
if (vClientId==0) return;
if (StrEqual(strWeapon,"hegrenade",false))	
	{		
	if (IsFakeClient(vClientId) || !IsValidAliveClient(vClientId) ) return;
	demage = GetEventInt(event, "dmg_health");
	#if defined DEBUG 
		GetClientName(vClientId, PName, MAX_CLIENT_NAME);
		SetClientHealth(vClientId,200);
		//PrintToChatAll("%s %s victim id=%d %s demage=%d" ,PLUGIN_NAME,PLUGIN_VERSION,vClientId,PName,demage);		
	#endif	
	GetClientAbsOrigin(vClientId, vClientOrigin);vClientOrigin[2]+50.0;		
	GetClientEyeAngles(vClientId, Angs);
	Angs[0]=Angs[0]+GetRandomFloat(-15.0,15.0);
	if (Angs[0]<-89.0) Angs[0]= -89.0;else if (Angs[0]>89.0) Angs[0]=89.0;
	Angs[1]=Angs[1]+GetRandomFloat(-15.0,15.0);
	if (Angs[1]<-180.0) Angs[1]= -180.0;else if (Angs[1]>180.0) Angs[1]=180.0;
	/*/Angs[2]=Angs[2]+GetRandomFloat(-demage/5.0,demage/5.0);
	if (Angs[2]<-45.0) Angs[2]= -45.0;else if (Angs[2]>45.0) Angs[2]=45.0;
	if (FloatAbs(Angs[2])>5.0)
		{
		ttimer=float(demage)/10.0;if (ttimer<1.0)ttimer=1.0;
		CreateTimer(ttimer,Set0Angle,vClientId,TIMER_DATA_HNDL_CLOSE);
		}
	*/	
	
	#if defined DEBUG 
	//PrintToChatAll("ANG %s %f %f %f" ,PName,Angs[0],Angs[1],Angs[2]);		
	#endif	
	
	
	MakeVectorFromPoints(HeGrenadeOrigin,vClientOrigin,Vec);
	GetEntPropVector( vClientId, Prop_Data, "m_vecVelocity", Vel );
	 /*Vec[0]=0.0;
	Vec[1]=0.0;
	Vec[2]=500.0;*/
	ScaleVector(Vec,demage/50.0);
	AddVectors(Vec,Vel,Slap);
	//if (Slap[2]<100.0)Slap[2]=100.0;	
	#if defined DEBUG 
	//PrintToChatAll("%s %s TELEPORT demage=%d",PLUGIN_NAME,PLUGIN_VERSION,demage);		
	//PrintToChatAll("%s %s TELEPORT Vec=%f %f %f",PLUGIN_NAME,PLUGIN_VERSION,Vec[0],Vec[1],Vec[2]);		
	#endif	
	
	TeleportEntity(vClientId,NULL_VECTOR,Angs,Slap);	
	}

aClientId = GetClientOfUserId(GetEventInt(event, "attacker"));
if (aClientId==0) return;
if (GetClientTeam(vClientId) == GetClientTeam(aClientId))	
	if (TestFirearms(strWeapon))
		{
		#if defined DEBUG 
		PrintToChatAll("[%s] %s ",PLUGIN_NAME,"TeamateAttack");		
		#endif	
		GetClientEyeAngles(aClientId, Angs);
		Angs[1]=Angs[1]+GetRandomFloat(-5.0,5.0);
		if (Angs[1]<-180.0) Angs[1]= -180.0;else if (Angs[1]>180.0) Angs[1]=180.0;		
		TeleportEntity(aClientId,NULL_VECTOR,Angs,NULL_VECTOR);
		}
		
}
//*****************************************************************************
stock bool TestFirearms(char[] w){
//*****************************************************************************
if (StrEqual(w,"hegrenade",		false)) return false;
if (StrEqual(w,"flashbang",		false)) return false;
if (StrEqual(w,"smokegrenade",	false)) return false;
if (StrEqual(w,"knife",			false)) return false;
return true;
}
//*****************************************************************************
public  Action Set0Angle(Handle AngleTimer,any client){
//*****************************************************************************
if (IsFakeClient(client) || !IsValidAliveClient(client) ) return;
float Angs0[3];
GetClientEyeAngles(client, Angs0);
Angs0[2]=0;
TeleportEntity(client,NULL_VECTOR,Angs0,NULL_VECTOR);	
}

//*****************************************************************************
public Action EventPlayerTeam(Handle event, const char[] name, bool dontBroadcast){
//*****************************************************************************
//if (GetEventBool(event, "disconnect")) return;
//int Client = GetClientOfUserId(GetEventInt(event, "userid"));
//if (Client==0) return;
//if (GetClientTeam(Client)<=CS_TEAM_SPECTATOR) SetClientListeningFlags(Client, VOICE_LISTENALL);
}	
//*****************************************************************************
public void EventPlayerDeath(Handle event, const char[] name, bool dontBroadcast){
//*****************************************************************************
#if defined DEBUG
DebugPrint("EventPlayerDeath");
#endif 
char weapon[64];
GetEventString(event, "weapon", weapon, sizeof(weapon));
#if defined DEBUG
DebugPrint("%s",weapon);
#endif 

if (StrEqual("knife",weapon))	
	{	
	int iv,ia;//,vt,at;
	iv=GetClientOfUserId(GetEventInt(event, "userid"));
	if (iv==0) return;
	if (IsFakeClient(iv)) return;
	ia=GetClientOfUserId(GetEventInt(event, "attacker"));
	if (iv==ia) return;
	int  vt,at;
	at=GetClientTeam(ia);
	vt=GetClientTeam(iv);
	if (at==vt) 
		{
		PrecacheSound(fknife_tm_kill_sound, true);	
		EmitSoundToAll(fknife_tm_kill_sound);			
		}
	else
		{
		PrecacheSound(fknife_kill_sound, true);	
		EmitSoundToAll(fknife_kill_sound);
		}
	}
}	
	
#endinput
//*****************************************************************************


