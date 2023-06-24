# StreetsRating
**Print rating of local streets**

## Description
The plugin is more suitable for servers with a local audience located within the same region. The plugin collects voluntarily specified streets by players into a common database, which determines the rating of the most playing streets in a city or village, or region. You can also edit it for yourself and specify, for example, countries or regions of countries(but there is already a GeoIP extension for this)
<img src="https://github.com/Quake1011/StreetsRating/assets/58555031/46a610a6-34e1-479a-8fb2-ab6647bdc74e" width="500vw">
<img src="https://github.com/Quake1011/StreetsRating/assets/58555031/db9ef3c4-e95a-4eb1-9c73-9050664db145" width="500vw">
## Settings
The list itself is configured in the **streets/streets.sp** file, where a list of the necessary streets is prescribed for display in the menu.
There are also 4 variables that can be used to regulate commands and the time of advertising commands in the chat. They are located in the source file in defines like that:
```c++
#define MY "sm_mystreet"          -  Street Selection command
#define STAT "sm_streetstat"      -  Command to display the rating of the top 3 streets
#define DELETE "sm_delstreet"     -  Command to delete the specified street
#define TIME 120.0                -  The time of repeating the hint in the chat
```
Specify this section to connect to the database in the **databases.cfg** file
```c++
"streets"
{
      "driver"            "mysql" 
      "host"              "host" 
      "database"          "db_name"
      "user"              "db_user" 
      "pass"              "password"
}
```

## Requirements
- [CSGO Colors](https://hlmod.net/resources/inc-cs-go-colors.1009/)
- [SourceMod](https://www.sourcemod.net/downloads.php?branch=stable)
- **MYSQL**