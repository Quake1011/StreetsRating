#pragma semicolon 1
#pragma newdecls required

#include <csgo_colors>
#include "streets/streets.sp"

//команды тут
#define MY "sm_mystreet"
#define STAT "sm_streetstat"
#define DELETE "sm_delstreet"
#define TIME 120.0

public Plugin myInfo = 
{ 
	name = "StreetsRating", 
	author = "Palonez", 
	description = "StreetsRating", 
	version = "1.0", 
	url = "https://github.com/Quake1011"
};

Database db;
char TOP3[3][256];
float TOP3VAR[3];

public void OnPluginStart()
{
	Database.Connect(SQLConnectCallback, "streets");

	RegConsoleCmd(MY, mystreet);
	RegConsoleCmd(STAT, streetstat);
	RegConsoleCmd(DELETE, delstreet);
	
	CreateTimer(TIME, Announcer, _, TIMER_REPEAT);
}

public Action mystreet(int client, int args)
{
	if(0 < client <= MaxClients)
	{
		char sQuery[256], sAuth[22];
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
		Format(sQuery, sizeof(sQuery), "SELECT * FROM `streets` WHERE `steam` = '%s'", sAuth);
		DBResultSet result = SQL_Query(db, sQuery);
		if(result != null && result.HasResults)
		{
			if(result.RowCount)
			{
				result.FetchRow();
				char street[128], del[128];
				result.FetchString(1, street, sizeof(street));
				strcopy(del, sizeof(del), DELETE);
				ReplaceString(del, sizeof(del), "sm_", "!", false);
				CGOPrintToChat(client, "Вы уже выбрали улицу - %s. Напишите %s, чтобы удалить улицу.", street, del);
				return Plugin_Handled;
			}
		}

		Menu hMenu = CreateMenu(MainMenu);
		hMenu.SetTitle("Выбери улицу на которой живешь");
		for(int i = 0; i < sizeof(StreetList); i++) 
			hMenu.AddItem(StreetList[i], StreetList[i]);
			
		hMenu.ExitBackButton = true;
		hMenu.ExitButton = true;
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public Action streetstat(int client, int args)
{
	if(0 < client <= MaxClients)
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT `street` FROM `streets` GROUP BY `street` ORDER BY COUNT(*) DESC , `street` DESC LIMIT 3");
		DBResultSet result = SQL_Query(db, sQuery);
		if(result != null && result.HasResults)
		{
			if(result.RowCount)
			{
				int i = 0;
				result.FetchRow();
				do
				{
					result.FetchString(0, TOP3[i], sizeof(TOP3[]));
					i++;
				}while(result.FetchRow());
			}
		}
		
		Transaction TXN = new Transaction();
		for(int i = 0; i < sizeof(TOP3); i++) 
		{
			Format(sQuery, sizeof(sQuery), "SELECT * FROM `streets` WHERE `street` = '%s'", TOP3[i]);
			TXN.AddQuery(sQuery);
		}
		TXN.AddQuery("SELECT * FROM `streets`");
		db.Execute(TXN, onSuccess, onError, client, DBPrio_High);
	}
	
	return Plugin_Handled;
}

public Action delstreet(int client, int args)
{
	if(0 < client <= MaxClients)
	{
		char sQuery[256], sAuth[22];
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
		Format(sQuery, sizeof(sQuery), "SELECT * FROM `streets` WHERE `steam` = '%s'", sAuth);
		DBResultSet result = SQL_Query(db, sQuery);	
		if(result != null && result.HasResults)
		{
			if(result.RowCount)
			{
				Format(sQuery, sizeof(sQuery), "DELETE FROM `streets` WHERE `steam` = '%s'", sAuth);
				result = SQL_Query(db, sQuery);	
				if(result != null)
					CGOPrintToChat(client, "Улица успешно удалена!");
			}
			else
			{
				char str[128];
				strcopy(str, sizeof(str), MY);
				ReplaceString(str, sizeof(str), "sm_", "!", false);
				CGOPrintToChat(client, "Улица не указана, введите %s", str);
			}
		}
	}

	return Plugin_Handled;
}

public Action Announcer(Handle hTimer)
{
	char fmt[3][128];
	fmt[0] = MY;
	fmt[1] = STAT;
	fmt[2] = DELETE;
	
	for(int i = 0; i < sizeof(fmt); i++)
		ReplaceString(fmt[i], sizeof(fmt), "sm_", "!", false);
	
	CGOPrintToChatAll("Указать свою улицу - %s\nПосмотреть топ-3 улиц - %s\nУдалить улицу - %s", fmt[0], fmt[1], fmt[2]);
	return Plugin_Continue;
}

public void SQLConnectCallback(Database hdb, const char[] error, any data)
{
	if(hdb != INVALID_HANDLE && !error[0])
	{
		db = hdb;
		
		char sQuery[256];
		db.SetCharset("utf8");
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `streets` (`steam` VARCHAR(22) PRIMARY KEY, `street` VARCHAR(256))");
		SQL_FastQuery(db, sQuery);
	}
}

public void onSuccess(Database hdb, int client, int numQueries, DBResultSet[] results, any[] queryData)
{
	for(int i = 0; i < numQueries-1; i++)
		if(results[i] != null && results[i].HasResults)
			if(results[i].RowCount)
				TOP3VAR[i] = 100*(float(results[i].RowCount)/float(results[numQueries-1].RowCount)); 
	
	for(int i = 0; i < sizeof(TOP3VAR); i++) 
		if(TOP3[i][0]) 
			CGOPrintToChat(client, "%d. %s - %.2f%%", i+1, TOP3[i], TOP3VAR[i]);
}

public void onError(Database hdb, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	if(!error[0]) return;
	else SetFailState("Txn error: %s", error);
}

public int MainMenu(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char info[256], sQuery[256], sAuth[22];
			hMenu.GetItem(item, info, sizeof(info));
			GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
			Format(sQuery, sizeof(sQuery), "INSERT INTO `streets` (`steam`, `street`) VALUES ('%s', '%s')", sAuth, info);
			SQL_FastQuery(db, sQuery);
			CGOPrintToChat(client, "Улица выбрана: %s", info);
		}
	}
	return 0;
}