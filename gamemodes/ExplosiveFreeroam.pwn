/*
    Created for Unique Gaming Community 

    Created By: _oMa37
    Started Scripting: 20th February 2016
    Gamemode: Freeroam
    Saving System: MySQL
    Website: UN-GAMING.COM
*/

//-------: INCLUDEs :-------//

    #include <a_samp>
    #include <a_mysql>
    #include <streamer>
    #include <ColAndreas>
    #include <callbacks>
    #include <sscanf2>

    #include <regex>
    #include <mSelection>
    #include <foreach>
    #include <CMD>
    #include <AntiBot>
    #include <OPA>
    #include <antiad>

    #include "./includes/ZonesInteriors.pwn"
    #include "./includes/Objects.pwn"

//-------------: MySQL Configurations :---------------//

    #define    MYSQL_HOST        "localhost"
    #define    MYSQL_USER        "root"
    #define    MYSQL_DATABASE    "efbase"
    #define    MYSQL_PASSWORD    ""

//--------------------: DEFINE :--------------------//

  //GameMode
    #define                         strcpy(%0,%1)                       strcat((%0[0] = '\0', %0), %1)
    #define                         PRESSED(%0)                         (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
    #define                         GRAVITY                             0.008
    #define                         NAMETAG_DRAW_DISTANCE               70.0
    #define                         SCM                                 SendClientMessage
    #define                         DelayKick(%0)                       SetTimerEx("DelayedKick", 300, 0, "d", %0)
    #define                         IsPlayerAFK(%0)                     IsPaused[(%0)]
    #define                         IsValidEmail(%1)                    regex_match(%1, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}")

  //Administration
    #define                         MAX_CAR_SPAWNS                      100
    #define                         MAX_TELEPORTS                       3000
    #if !defined                    FLOAT_INFINITY 
    #define                         FLOAT_INFINITY                      (Float:0x7F800000)
    #endif

  //Timers
    #define                         Minutes(%0)                         %0 * 60
    #define                         Hours(%0)                           %0 * 3600
    #define                         Days(%0)                            %0 * 86400
    #define                         Weeks(%0)                           %0 * 604800
    #define                         Month(%0)                           %0 * 2592000 

  //Colors
    #define                         red                                 0xFF0000FF
    #define                         NOTIF                               0xFF0066FF
    #define                         lighterblue                         0x09F7DFC8
    #define                         green                               0x1AFF00C8
    #define                         GREY                                0xAFAFAF8
    #define                         blue                                0x0080C0C8
    #define                         yellow                              0xFF0000C8
    #define                         orange                              0xFF8000C8
    #define                         pink                                0xFF00FFC8
    #define                         purple                              0x8000FFC8
    #define                         black                               0x000000C8
    #define                         WHITE                               0xFFFFFFC8
    #define                         brown                               0x800000C8
    #define                         cream                               0xFFFF80C8
    #define                         lightblue                           "{33CCFF}"

  //Settings
    native                          WP_Hash(buffer[], len, const str[]);
    #define                         SETTING_PATH                        "eFData/Settings/%s.ini"
    #define                         PRESSING(%0,%1)                     (%0 & (%1))
    #define                         HOLDING(%0)                         ((newkeys & (%0)) == (%0))
    #define                         RELEASED(%0)                        (((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
    #define                         MAX_TEAMS                           9
    new attempts[MAX_PLAYERS];
    new Cooldown[MAX_PLAYERS][11];
    new ReportText[MAX_PLAYERS][150];
    new CreatedReport[MAX_PLAYERS];
    new Possaved[MAX_PLAYERS];
  //Hacks
    new pTickWarnings[MAX_PLAYERS];
    new HackWarnings[MAX_PLAYERS];
    new p_CarWarpTime[MAX_PLAYERS];
    new p_CarWarpVehicleID[MAX_PLAYERS];
  //Anti Money Hack
    #define                         ResetMoneyBar                       ResetPlayerMoney
    #define                         UpdateMoneyBar                      GivePlayerMoney
    new Cash[MAX_PLAYERS];
  //Anti Weapon Hack
    new OnPlayerAntiCheat[MAX_PLAYERS];
    new bool:gPlayerWeaponData[MAX_PLAYERS][47];
  //Anti Fake Kill
    new CountDeaths[MAX_PLAYERS], StartDeathTick[MAX_PLAYERS];
  //Anti Armour/Health Hack
    new bool:AntiHealth[MAX_PLAYERS], bool:AntiArmour[MAX_PLAYERS];
  //Clocks
    new Text:ServerTime;
  //Animations
    new animation[MAX_PLAYERS];
    new PlayerUsingLoopingAnim[MAX_PLAYERS];
  //Money Bag
    #define                         MoneyBagDelay(%1,%2,%3,%4) (%1*3600000)+(%2*60000)+(%3*1000)+%4
    #define                         MB_DELAY MoneyBagDelay(0, 30, 0, 0)
  //Reaction System
    #define                         Loop(%0,%1) for(new %0 = 0; %0 != %1; %0++)
    #define                         function%0(%1) forward%0(%1); public%0(%1)
    #define                         TIME                                900000
  //Vehicle Spawner
    new playerCar[MAX_PLAYERS];
    new Airplanes = mS_INVALID_LISTID;
    new Bikes = mS_INVALID_LISTID;
    new Boats = mS_INVALID_LISTID;
    new Convertible = mS_INVALID_LISTID;
    new Helicopters = mS_INVALID_LISTID;
    new Industrials = mS_INVALID_LISTID;
    new Lowrider = mS_INVALID_LISTID;
    new OffRoad = mS_INVALID_LISTID;
    new PublicService = mS_INVALID_LISTID;
    new Saloon = mS_INVALID_LISTID;
    new Sports = mS_INVALID_LISTID;
    new StationWagon = mS_INVALID_LISTID;
    new Unique = mS_INVALID_LISTID;

//---------------------------------------------------//

//----------------: FORWARDs :----------------//
forward SpawnVehicle(playerid,vehicleid);
forward Unjail(playerid);
forward GiveVehicle(playerid,vehicleid);
forward Specoff(playerid);
forward Usedrugs(playerid);
forward DelayedKick(playerid);
forward Listen(playerid, Link[]);
forward CustomR(playerid);
forward UpdateTimeAndWeather();
forward LoadTeleports();
forward UnmutePlayer(playerid);
forward MoneyBag();
forward HideText();
forward HidePayout(playerid);
forward CancelVote();
forward OnAccountCheck(playerid);
forward OnAccountLoad(playerid, type);
forward OnAccountRegister(playerid);
forward HideInfoBox(playerid);
forward OnBanLoad(playerid);
forward OnTurfwarEnd(turfid);
forward CountDownTimer(turfid);
forward DerbyStart();
forward FallingChecker(playerid, Float:maxz);
forward StartTDM();
forward AntiHacks(playerid);
forward DerbyCountDown();
forward TDMCountDown();
forward OnAttachmentLoad(playerid);
forward OnAttachmentSave(playerid, index, modelid, boneid);
forward OnWeaponLoad(playerid);
forward OnBanCheck(playerid);
forward CancelDuel(playerid);
forward JailPlayer(playerid);
forward JailCountDown(playerid);
forward Float:Currency(playerid);
forward PropertyTimer(playerid);
forward LoadProperties();
forward OnPropertyCreated(propertyid);
forward PlantGrow();
forward PlantMarijuana(playerid);
forward OnMarketLoad(playerid);
forward StartEvent();
forward LoadHouses();
forward GiveHouseKeys(playerid);
forward ShowInfoBox(playerid, box_color, shown_for, text[]);
forward OnAutoPickupDestroy(pickupid);
forward UpdateRadar();
forward LoadDealerVehicles();
forward LoadPlayerVehicles(playerid);
forward ExpireStuff();
forward OnDealerVehicleCreated(vehicleid);
forward OnAutoPickupDestroy(pickupid);
forward OnPlayerEnterGangZone(playerid, zone);
forward OnPlayerLeaveGangZone(playerid, zone);
//----------------: NEWs :----------------//
  //Mute System
    new
       MuteTimer[MAX_PLAYERS],
       MuteCounter[MAX_PLAYERS];
  //Private Messages
    new LastPm[MAX_PLAYERS];
    new PMEnabled[MAX_PLAYERS];
  //AFK/Paused System
    new IsPaused[MAX_PLAYERS],
        pTick[MAX_PLAYERS],
        pauseTimer[MAX_PLAYERS],
        StartTimer[MAX_PLAYERS];
  //Anti-Spawn Kill
    new pProtectTick[MAX_PLAYERS];
  //Anti-Car Abuse
    new AbuseTick[MAX_PLAYERS];
  //Drive By Weapons
    new DriveBy_Weps[] ={25,28,29,30,31,32};
  //Textdraws
    new tmInfoBox[MAX_PLAYERS];
    new Text:BBox;
    new Text:BBounty;
    new Text:BText;
    new Text:WebsiteTD;
    new Text:Textdraw0;
    new Text:Textdraw1;
    new Text:Textdraw2;
    new Text:Textdraw3;
    new Text:Textdraw4;
    new Text:Textdraw5;
    new Text:Textdraw6;
    new Text:Textdraw7;
    new Text:Textdraw8;
    new Text:Textdraw9;
    new Text:Textdraw10;
    new Text:Textdraw11;
    new Text:Textdraw12;
    new Text:Textdraw13;
    new Text:Textdraw14;
    new Text:Textdraw15;
    new PlayerText:TimeLeft[MAX_PLAYERS];
    new PlayerText:BPayout[MAX_PLAYERS];
    new PlayerText:SpectateTextDraw[MAX_PLAYERS];
    new PlayerText:Notif[MAX_PLAYERS];
    new PlayerText:JailTime[MAX_PLAYERS];
    new PlayerText:ptInfoBox[MAX_PLAYERS];
    new PlayerText:Background;
    new PlayerText:Middle;
    new PlayerText:ServerName;
    new PlayerText:ServerTitle;
    new PlayerText:Bottom;
    new PlayerText:Middle2;
    new PlayerText:VehicleSpeedo;
  //VehicleSpeed
    new VehicleTimer[MAX_PLAYERS];
  //Vehicles
    new g_Engine, g_Lights,
        g_Alarm, g_Doors,
        g_Bonnet, g_Boot,
        g_Objective;
  //Selfie
    new InSelfie[MAX_PLAYERS];
    new Float:Degree[MAX_PLAYERS];
    const Float: Radius = 1.4;
    const Float: Speed  = 1.25;
    const Float: Height = 1.0;
    new Float:SelfieX[MAX_PLAYERS];
    new Float:SelfieY[MAX_PLAYERS];
    new Float:SelfieZ[MAX_PLAYERS];
  //Animation Library
    new AnimationLibraries[][] = 
    {
        "AIRPORT", "Attractors", "BAR", "BASEBALL", "BD_FIRE", "BEACH", "benchpress", "BF_injection", "BIKED", "BIKEH", "BIKELEAP",
        "BIKES", "BIKEV", "BIKE_DBZ", "BLOWJOBZ", "BMX", "BOMBER", "BOX", "BSKTBALL", "BUDDY", "BUS", "CAMERA", "CAR", "CARRY", "CAR_CHAT",
        "CASINO", "CHAINSAW", "CHOPPA", "CLOTHES", "COACH", "COLT45", "COP_AMBIENT", "COP_DVBYZ", "CRACK", "CRIB", "DAM_JUMP", "DANCING",
        "DEALER", "DILDO", "DODGE", "DOZER", "DRIVEBYS", "FAT", "FIGHT_B", "FIGHT_C", "FIGHT_D", "FIGHT_E", "FINALE", "FINALE2", "FLAME",
        "Flowers", "FOOD", "Freeweights", "GANGS", "GHANDS", "GHETTO_DB", "goggles", "GRAFFITI", "GRAVEYARD", "GRENADE", "GYMNASIUM", "HAIRCUTS",
        "HEIST9", "INT_HOUSE", "INT_OFFICE", "INT_SHOP", "JST_BUISNESS", "KART", "KISSING", "KNIFE", "LAPDAN1", "LAPDAN2", "LAPDAN3", "LOWRIDER",
        "MD_CHASE", "MD_END", "MEDIC", "MISC", "MTB", "MUSCULAR", "NEVADA", "ON_LOOKERS", "OTB", "PARACHUTE", "PARK", "PAULNMAC", "ped", "PLAYER_DVBYS",
        "PLAYIDLES", "POLICE", "POOL", "POOR", "PYTHON", "QUAD", "QUAD_DBZ", "RAPPING", "RIFLE", "RIOT", "ROB_BANK", "ROCKET", "RUSTLER", "RYDER",
        "SCRATCHING", "SHAMAL", "SHOP", "SHOTGUN", "SILENCED", "SKATE", "SMOKING", "SNIPER", "SPRAYCAN", "STRIP", "SUNBATHE", "SWAT", "SWEET", "SWIM",
        "SWORD", "TANK", "TATTOOS", "TEC", "TRAIN", "TRUCK", "UZI", "VAN", "VENDING", "VORTEX", "WAYFARER", "WEAPONS", "WUZI", "SAMP"
    };
  //Vehicles Stuff
    new Float: vEnterPos[MAX_PLAYERS][4];
    new VehicleNames[212][] =
    {
        "Landstalker", "Bravura", "Buffalo", "Linerunner", "Pereniel", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus","Voodoo", "Pony",
        "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Mr Whoopee", "BF Injection", "Hunter", "Premier", "Enforcer",
        "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero",
        "Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer 2", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy",
        "Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad",
        "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR3 50", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick",
        "News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa",
        "RC Goblin", "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropdust",
        "Stunt", "Tanker", "RoadTrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune",
        "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent", "Bullet",
        "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster A",
        "Monster B", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight", "Trailer", "Kart", "Mower",
        "Duneride", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "Newsvan", "Tug", "Trailer A", "Emperor", "Wayfarer", "Euros",
        "Hotdog", "Club", "Trailer B", "Trailer C", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car (LSPD)", "Police Car (SFPD)", "Police Car (LVPD)", "Police Ranger",
        "Picador", "S.W.A.T. Van", "Alpha", "Phoenix", "Glendale", "Sadler", "Luggage Trailer A", "Luggage Trailer B", "Stair Trailer", "Boxville", "Farm Plow", "Utility Trailer"
    };

    new MaxVehicleSeats[] = 
    {
        4, 1, 1, 1, 4, 4, 1, 1, 1, 4, 1, 1, 1, 4, 1, 1, 4, 1, 4, 1, 4, 4, 1, 1, 1, 1, 4, 4, 4, 1,
        1, 7, 1, 1, 1, 0, 1, 7, 4, 1, 4, 1, 1, 1, 1, 4, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 4,
        4, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 4, 3, 1, 1, 1, 4, 1,
        1, 4, 1, 4, 1, 1, 1, 1, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 7, 7, 1, 4, 1, 1, 1, 1, 1, 4, 4,
        1, 1, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 1, 1, 4, 4, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,
        4, 4, 1, 4, 1, 0, 4, 1, 1, 1, 1, 0, 0, 7, 1, 1, 1, 4, 4, 4, 1, 1, 1, 1, 1, 4, 1, 0, 0, 0,
        4, 0, 0
    };

    new s_TopSpeed[212] = 
    {
        157, 147, 186, 110, 133, 164, 110, 148, 100, 158, 129, 221, 168, 110, 105, 192, 154, 270,
        115, 149, 145, 154, 140, 99, 135, 270, 173, 165, 157, 201, 190, 130, 94, 110, 167, 0, 149,
        158, 142, 168, 136, 145, 139, 126, 110, 164, 270, 270, 111, 0, 0, 193, 270, 60, 135, 157,
        106, 95, 157, 136, 270, 160, 111, 142, 145, 145, 147, 140, 144, 270, 157, 110, 190, 190,
        149, 173, 270, 186, 117, 140, 184, 73, 156, 122, 190, 99, 64, 270, 270, 139, 157, 149, 140,
        270, 214, 176, 162, 270, 108, 123, 140, 145, 216, 216, 173, 140, 179, 166, 108, 79, 101, 270,
        270, 270, 120, 142, 157, 157, 164, 270, 270, 160, 176, 151, 130, 160, 158, 149, 176, 149, 60,
        70, 110, 167, 168, 158, 173, 0, 0, 270, 149, 203, 164, 151, 150, 147, 149, 142, 270, 153, 145,
        157, 121, 270, 144, 158, 113, 113, 156, 178, 169, 154, 178, 270, 145, 165, 160, 173, 146, 0, 0,
        93, 60, 110, 60, 158, 158, 270, 130, 158, 153, 151, 136, 85, 0, 153, 142, 165, 108, 162, 0, 0,
        270, 270, 130, 190, 175, 175, 175, 158, 151, 110, 169, 171, 148, 152, 0, 0, 0, 108, 0, 0
    };
  //TimeStamp
    new MonthTimes[12][4] =
    {
        { 31, 31, 2678400, 2678400 },
        { 28, 29, 2419200, 2505600 },
        { 31, 31, 2678400, 2678400 },
        { 30, 30, 2592000, 2592000 },
        { 31, 31, 2678400, 2678400 },
        { 30, 30, 2592000, 2592000 },
        { 31, 31, 2678400, 2678400 },
        { 31, 31, 2678400, 2678400 },
        { 30, 30, 2592000, 2592000 },
        { 31, 31, 2678400, 2678400 },
        { 30, 30, 2592000, 2592000 },
        { 31, 31, 2678400, 2678400 }
    };
  //DM System
    new Float:RandomSpawnsDE[][] =
    {
        {242.5503,176.5623,1003.0300,93.6148},
        {240.5619,195.8680,1008.1719,91.7114},
        {253.4729,190.7446,1008.1719,115.2117},
        {288.745971, 169.350997, 1007.171875}
    };

    new Float:RandomSpawnsMicro[][] =
    {
        {1413.8528,4.3052,1000.9261,117.9037},
        {1362.8478,-45.5788,1000.9182,308.0989},
        {1360.2490,3.6216,1000.9219,226.0048},
        {1416.9810,-46.5704,1000.9282,48.3664}
    };

    new Float:RandomSpawnsMinigun[][] =
    {
        {-1053.9221,1022.5436,1343.1633,286.6894},
        {-975.975708,1060.983032,1345.671875},
        {-1131.4167,1042.4703,1345.7369,230.2888}
    };


    new Float:RandomSpawnsM4[][] =
    {
        {-2640.762939, 1406.682006, 906.460937},
        {-2664.6062,1392.3625,912.4063,60.4372},
        {-2670.5549,1425.4402,912.4063,179.1681}
    };


    new Float:RandomSpawnsSawns[][] =
    {
        {1322.2629,2753.8525,10.8203,67.4993},
        {1197.6454,2795.0579,10.8203,13.2921},
        {1365.6454,2809.0579,10.8203,13.2921}
    };

    new Float:RandomSpawnsSniper[][] =
    {
        {2209.0427,1063.0984,71.3284,328.9798 },
        {2217.0649,1091.5931,29.5850,346.5500 },
        {2286.3674,1171.7701,85.9375,151.3414 },
        {2289.5737,1054.5160,26.7031,240.9556 }
    };

    new Float:RandomSpawnsCombat[][] =
    {
        {2205.2983,1553.3098,1008.3852,275.1326},
        {2172.6226,1577.2854,999.9670,186.4819},
        {2188.4739,1619.3770,999.9766,0.0467},
        {2218.1841,1615.2228,999.9827,334.6665}
    };

    new GotJetpack[MAX_PLAYERS];
    new Float:RandomSpawnsJetpack[][] =
    {
        {-207.7397,1900.9238,128.3978,54.6579},
        {-323.2241,1946.8711,132.4128,238.8525},
        {-348.7285,1929.0078,84.3901,205.0124},
        {-221.7463,1804.0217,103.6206,41.4508}
    };
  //Hospital Spawns
    new Float:Hospitalcoor[][4] =
    {
        {2027.4375,-1421.0703,16.9922,137.2809}, // Los Santos Hospital
        {1177.9089,-1323.9611,14.0939,269.8222},  // Los Santos Hospital #2
        {1579.6106,1769.0625,10.8203,90.7178},  // Las Venturas Hospital
        {-321.8259,1056.7279,19.7422,316.0064}, // Fort Carson Hospital
        {-1514.8807,2527.8003,55.7315,358.6234},  // El Quebrados Hospital
        {-2662.0439,630.5056,14.4531,177.8114}, // San Fierro Hospital
        {-2199.2495,-2311.0444,30.6250,321.2772}, // Angel Pine Hospital
        {1244.1959,332.2817,19.5547,338.3063} // Montgomery Hospital
    };

//---------------: ENUMs :---------------//

#define DIALOG_SELL_MONEY   2000
#define DIALOG_VEHICLES     3500
#define DIALOG_OPMS         4000
#define DIALOG_SHOP         4500
#define DIALOG_EVENTS       5000
#define DIALOGS             5500
#define DIALOG_AMMU         6000

enum _:dialogOne {

    DIALOG_PROPERTIES = 1,
    DIALOG_HOUSES,
    DIALOG_COLORS,
    DIALOG_HELP,
    DIALOG_CMDS,
    DIALOG_INV,
    DIALOG_RADIOS,
    CRADIO,
    DIALOG_SHOW_INFO,
    WEAP_DIALOG,
    N,
    DIALOG_LOGIN,
    DIALOG_REGISTER,
    DIALOG_EMAIL,
    DIALOG_PASS,
    DIALOG_STATS,
    WARN,
    DIALOG_DM,
    DIALOG_GANGLIST,
    DIALOG_GANGSLIST,
    DIALOG_PARKOURS,
    DIALOG_SKYDIVE,
    DIALOG_DERBY,
    DIALOG_TDM,
    DIALOG_SKIN_TAKE,
    DIALOG_SKIN_BUY,
    DIALOG_BUY_PROPERTY,
    DIALOG_BUY_HOUSE,
    DIALOG_HOUSE_MENU,
    DIALOG_HOUSE_LOCK,
    DIALOG_SAFE_MENU,
    DIALOG_SAFE_TAKE,
    DIALOG_SAFE_PUT,
    DIALOG_GUNS_MENU,
    DIALOG_GUNS_TAKE,
    DIALOG_VISITORS_MENU,
    DIALOG_VISITORS,
    DIALOG_KEYS_MENU,
    DIALOG_KEYS,
    DIALOG_SAFE_HISTORY,
    DIALOG_MY_KEYS,
    DIALOG_FRIENDS,
    DIALOG_SEEDS,
    DIALOG_BUY_VEHICLE,
    DIALOG_TITLES,
    DIALOG_ATTACHMENTS,
    DIALOG_ATTACHMENTS_EDIT,
    DIALOG_ATTACHMENTS_SAVE,
}

enum PlayerData
{
    //MySQL
    Logged,
    Registered,
    AutoLogin,
    ID,
    PlayerName[MAX_PLAYER_NAME],
    Password[129],
    IP[16],
    Email[35],
    Level,
    Money,
    Kills,
    Deaths,
    Suicides,
    Hours,
    Minutes,
    Seconds,
    Marijuana,
    Seeds,
    Cocaine,
    Premium,
    PremiumExpires,
    NameChange,
    FightStyle,
    xLevel,
    XP,
    WantedLevel,
    Muted,
    Jailed,
    Hitman,
    MapHide,
    Skin,
    Float:PosX,
    Float:PosY,
    Float:PosZ,
    Interior,
    Float:pHealth,
    Float:pArmour,
    UGC,
    PlayerTeam,
    Skills[MAX_TEAMS],
    MoneyBags,
    Jetpack,
    JetpackExpire,
    Jump,
    JumpExpire,
    Friends,
    vehLimit,
    playerColor[16],
    textColor[16],

    //Non-MySQL
    InDM,
    Duty,
    Frozen,
    SpawnedCars,
    Cars[MAX_CAR_SPAWNS],
    VGod,
    DMZone,
    Spec,
    NameTagHidden,
    LastSpawnedCar,
    bool:ReadPM,
    bool:ReadCMD,
    Move,
    WeaponTeleport,
}

new mysql;

new Info[MAX_PLAYERS][PlayerData],SpecID[MAX_PLAYERS],
    TextColor[MAX_PLAYERS],PlayedSound[MAX_PLAYERS],
    KillStreak[MAX_PLAYERS], pLastMsg[MAX_PLAYERS][129 char],
    VLstring[850], JetPickups[3], CountTimer[MAX_PLAYERS],
    OldSkin[MAX_PLAYERS], SpecTimer[MAX_PLAYERS], IsBanned[MAX_PLAYERS];

new Float:LastPosX[MAX_PLAYERS], 
    Float:LastPosY[MAX_PLAYERS], 
    Float:LastPosZ[MAX_PLAYERS],
    Float:LastHealth[MAX_PLAYERS],
    Float:LastArmour[MAX_PLAYERS],
    LastInterior[MAX_PLAYERS];

new Float:TeleCoords[MAX_TELEPORTS][3],
    Teleinfo[MAX_TELEPORTS][2],
    TeleName[MAX_TELEPORTS][30],
    TeleCount = 0;

new JTimer[MAX_PLAYERS], JPlayer[MAX_PLAYERS], JailCountDownFromAmount = 0,
	JailTimer[MAX_PLAYERS];

new ClassVehicles[3];

new Text3D:PlayerTag[MAX_PLAYERS] = Text3D:INVALID_3DTEXT_ID,
    Text3D:PlayerTitle[MAX_PLAYERS] = Text3D:INVALID_3DTEXT_ID;

new HideTexts[MAX_PLAYERS] = 0;

new Jumping[MAX_PLAYERS],
    JumpStatus[MAX_PLAYERS];

//Event System

#define TEAM_ONE    55
#define TEAM_TWO    56

enum _:EventTypes
{
    EVENT_NONE,
    EVENT_TDM,
    EVENT_DM
};

enum EventData
{
    eName[24],
    Type,
    Price,
    Prize,
    eWeapon1,
    eWeapon2,
    eInterior,
    Float:eSpawnX,
    Float:eSpawnY,
    Float:eSpawnZ,
    Float:eSX,
    Float:eSY,
    Float:eSZ,
    bool:EventStarted,
    Headshot
};

new eInfo[EventData],
    InEvent[MAX_PLAYERS],
    ePlayerTeamOne = 0,
    ePlayerTeamTwo = 0,
    ePlayers = 0;

new EventBalance = 0;

// Object System
#define         MAX_SEARCH_OBJECT           200

new msg[128];
new objects[MAX_OBJECTS];
new objectmodel[MAX_OBJECTS];
new objectmatinfo[MAX_OBJECTS][3][80];
new Attached[MAX_OBJECTS];
new MaterialApplied[MAX_PLAYERS];

new PlayerText:objinfo[MAX_PLAYERS][34];
new PlayerText:ObjTextdraw[MAX_PLAYERS];

// Money bag

enum MBInfo
{
    Float:XPOS,
    Float:YPOS,
    Float:ZPOS,
    Position[50]
};

new Float:MBSPAWN[][MBInfo] =
{
    {2200.3606,1388.0264,16.4786, "Royal Casino"},
    {1990.2629,1377.2076,9.2578, "The High Roller"},
    {1995.4104,2194.5781,10.8203, "Redsands East"},
    {215.2933,1467.1355,23.7344, "Green Palms"},
    {-176.9021,1084.4481,26.1092, "Fort Carson"},
    {-638.5738,1448.8306,13.6172, "Tierra Robada"},
    {-611.4902,1809.6287,1.2656, "Sherman Reservoir"},
    {195.3332,-93.9829,4.8965, "Blueberry"},
    {263.3521,-163.6365,5.0786, "Blueberry"},
    {-47.4641,30.5201,6.4844, "Blueberry Acres"},
    {288.6500,-1604.2822,17.8593, "Rodeo"},
    {383.9704,-1884.9417,2.1284, "Santa Maria Beach"},
    {950.3672,-1817.3920,19.0938, "Verona Beach"},
    {854.7498,-1631.6343,13.5547, "Verona Beach"},
    {1489.5364,-1721.9207,8.2092, "Pershing Square"},
    {1296.1239,-786.0019,88.3125, "Mulholland"},
    {1297.8717,-978.5743,32.6953, "Temple"},
    {1083.6853,-1269.7341,21.5469, "Market"},
    {1494.1096,-1771.9613,18.7958, "Commerce"},
    {1806.4161,-2334.6162,-2.6500, "Los Santos International"},
    {1874.6698,-1957.3591,20.0703, "El Corona"},
    {2547.0732,-2049.3398,13.5500, "Willowfield"},
    {2373.8606,-1542.9045,23.9957, "East Los Santos"},
    {537.8293,-1436.5613,24.0000, "East Los Santos"},
    {2196.8708,-1158.8765,33.5313, "Jefferson"},
    {1814.4707,-1029.2872,24.0781, "Glen Park"},
    {1682.5186,-937.6871,45.8539, "Mulholland Intersection"},
    {664.7849,-1379.5664,21.8391, "Vinewood"},
    {-2135.2925,169.9322,42.2500, "Doherty"},
    {-2496.0503,294.0747,35.1355, "Queens"},
    {1995.4104, 2194.5781,10.8203, "Redsands East"}
};

new Float:MoneyBagPos[3], MoneyBagFound=1, MoneyBagLocation[50], MoneyBagPickup, Timer[2];

//Vote System

new OnVote;
new Voted[MAX_PLAYERS];

enum VOTES
{
    Vote[50],
    VoteY,
    VoteN,
}
new Voting[VOTES];

//Reaction System
new
    xCharacters[][] =
    {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    },
    xChars[16] = "",
    xReactionTimer,
    xCash,
    bool: xTestBusy
;

//Gangs

#define     GROVE       		    1
#define     BALLAS      		    2
#define     VAGOS       		    3
#define     AZTECAS     		    4
#define     BIKERS        		    5
#define     TRIADS      		    6
#define     MAFIA       		    7
#define     NANG        		    8

#define     COLOR_NULL              0xFFFFFFFF
#define     COLOR_GROVE             0x009900FF
#define     COLOR_BALLAS            0xCC00CCFF
#define     COLOR_VAGOS             0xFFCC00FF
#define     COLOR_AZTECAS           0x00FFFFFF
#define     COLOR_BIKERS            0x595959FF
#define     COLOR_TRIADS            0x6600FFFF
#define     COLOR_MAFIA             0xE69500FF
#define     COLOR_NANG              0x996633FF

#define TURF_STATE_NORMAL           (0)
#define TURF_STATE_ATTACKED         (1)

#define TURF_REQUIRED_PLAYERS       (1)
#define TURF_REQUIRED_CAPTURETIME   (3 * 60 * 1000)
#define COLOR_CHANGE_ALPHA(%1)      ((%1 & ~0xFF) | (clamp(100, 0x00, 0xFF)))

enum eTeam 
{
    teamName[35],
    teamColor
};

enum eTurf 
{
    turfName[35],
    turfOwner,
    turfAttacker,
    Float:turfPos[4],
    turfState,
    turfTimer,
    turfAttackTimer,
    turfCountDown,
    turfId,
    areaId
};

new const g_Team[][eTeam] = {
    {"Freeroam", 0xFFFFFFFF},
    {"Grove Street", 0x009900FF},
    {"Ballas", 0xCC66FFFF},
    {"Los Santos Vagos", 0xFFCC00FF},
    {"Varrios Los Aztecas", 0x00FFFFFF},
    {"Bikers", 0x595959FF},
    {"Triads", 0x6600FFFF},
    {"Mafia", 0xE69500FF},
    {"Da Nang Boys", 0x996633FF}
};

new const g_Turf[][eTurf] = {
    { "Error",  0, NO_TEAM, {2708, -2065.5, 2961, -1872.5}},

    { "Playa Del Seville",  1, NO_TEAM, {2708.0, -2065.5, 2961.0, -1872.5}},
    { "East Beach", 1, NO_TEAM, {2633.0, -1872.5, 2961.0, -1730.5}},
    { "East Beach", 1, NO_TEAM, {2750.0, -1730.5, 2961.0, -1595.5}},
    { "East Beach", 1, NO_TEAM, {2750.0, -1595.5, 2961.0, -1189.5}},
    { "Las Colinas", 1, NO_TEAM, {2750.0, -1189.5, 2961.0, -1023.5}},

    { "East Beach", 2, NO_TEAM, {2633.0, -1730.5, 2750.0, -1524.5}},
    { "East Beach", 2, NO_TEAM, {2573.0, -1525.5, 2750.0, -1279.5}},
    { "East Beach", 2, NO_TEAM, {2573.0, -1583.5, 2633.0, -1524.5}},
    { "Las Colinas", 2, NO_TEAM, {2573.0, -1279.5, 2750.0, -1023.5}},
    { "Las Colinas", 2, NO_TEAM, {2185.0, -1180.5, 2573.0, -1023.5}},

    { "Las Colinas", 3, NO_TEAM, {2112.0, -1180.5, 2185.0, -956.5}},
    { "Las Colinas", 3, NO_TEAM, {2065.0, -1097.5, 2112.0, -941.5}},
    { "Las Colinas", 3, NO_TEAM, {2016.0, -1097.5, 2065.0, -921.5}},
    { "Las Colinas", 3, NO_TEAM, {1949.0, -1097.5, 2016.0, -921.5}},
    { "Glen Park", 3, NO_TEAM, {1851.0, -1264.5, 2112.0, -1097.5}},

    { "East Los Santos", 4, NO_TEAM, {2488.0, -1583.5, 2573.0, -1180.5}},
    { "East Los Santos", 4, NO_TEAM, {2414.0, -1583.5, 2488.0, -1180.5}},
    { "Ganton", 4, NO_TEAM, {2352.0, -1730.5, 2633.0, -1582.5}},
    { "Willowfield", 4, NO_TEAM, {2313.0, -1933.5, 2633.0, -1730.5}},
    { "East Los Santos", 4, NO_TEAM, {2313.0, -1321.5, 2414.0, -1180.5}},

    { "Jefferson", 5, NO_TEAM, {2180.0, -1494.5, 2313.0, -1180.5}},
    { "East Los Santos", 5, NO_TEAM, {2313.0, -1582.5, 2414.0, -1320.5}},
    { "Jefferson", 5, NO_TEAM, {1812.0, -1535.5, 2180.0, -1264.5}},
    { "Jefferson", 5, NO_TEAM, {2112.0, -1264.5, 2181.0, -1180.5}},
    { "Idlewood", 5, NO_TEAM, {1996.0, -1764.5, 2313.0, -1535.5}},

    { "Jefferson", 6, NO_TEAM, {2180.0, -1535.5, 2313.0, -1494.5}},
    { "Ganton", 6, NO_TEAM, {2313.0, -1730.5, 2352.0, -1582.5}},
    { "Santa Maria Beach", 6, NO_TEAM, {84.0, -2161.5, 347.0, -1712.5}},
    { "Santa Maria Beach", 6, NO_TEAM, {347.0, -2161.5, 652.0, -1712.5}},
    { "Santa Maria Beach", 6, NO_TEAM, {652.0, -2161.5, 937.0, -1792.5}},

    { "Verona Beach", 7, NO_TEAM, {937.0, -1977.5, 1068.0, -1792.5}},
    { "Verona Beach", 7, NO_TEAM, {879.0, -1792.5, 1043.0, -1571.5}},
    { "Verona Beach", 7, NO_TEAM, {1043.0, -1717.5, 1152.0, -1571.5}},
    { "Verona Beach", 7, NO_TEAM, {1152.0, -1717.5, 1305.0, -1571.5}},
    { "Vinewood", 7, NO_TEAM, {798.0, -1134.5, 963.0, -971.5}},

    { "Temple", 8, NO_TEAM, {963.0, -1134.5, 1091.0, -953.5}},
    { "Temple", 8, NO_TEAM, {1091.0, -1134.5, 1238.0, -1048.5}},
    { "Temple", 8, NO_TEAM, {1238.0, -1134.5, 1367.0, -1048.5}},
    { "Temple", 8, NO_TEAM, {1238.0, -1048.5, 1378.0, -944.5}},
    { "Temple", 8, NO_TEAM, {1238.0, -944.5, 1322.0, -917.5}}
};

new g_MembersInTurf[sizeof(g_Turf)][sizeof(g_Team)],
    pTeam[MAX_PLAYERS],
    gTeamCount[MAX_TEAMS],
    Text3D:TeamsLabel[MAX_TEAMS],
    PlayerText:CountDownAttack[MAX_PLAYERS];

//Duel System
new Bet[MAX_PLAYERS],
	Opponent[MAX_PLAYERS],
	Invited[MAX_PLAYERS],
	Weapon1[MAX_PLAYERS],
	Weapon2[MAX_PLAYERS],
	InDuel[MAX_PLAYERS],
	Dtimer[MAX_PLAYERS];

//Parkour Minigames

new InParkour[MAX_PLAYERS],
    pPickups[3], pCheckpoints[6],
    pVehicles[MAX_PLAYERS];

//Skydive Minigames

new InSkydive[MAX_PLAYERS], sCheckpoints[3];

//Derby Minigames

#define MAX_DERBY_PLAYERS 20

new Float:RanchersDerby[][4] = // 6
{
    {264.2905, 2292.8694, 359.4299, 0.9344},
    {343.2427, 2367.0752, 359.2970, 1.3177},
    {435.8522, 2489.9319, 359.2966, 66.4891},
    {471.8872, 2334.1023, 359.2991, 90.3060},
    {602.2872, 2296.4844, 359.4274, 178.3068},
    {457.2483, 2234.0857, 359.2168, 0.6003}
};

new Float:BulletsDerby[][4] = // 12
{
    {366.7861,5263.6182,9.6985,1.2533},
    {365.3138,5337.7349,9.6986,0.9814},{391.5584,5346.0146,9.6987,272.7215},{448.8389,5347.4287,9.6987,90.8422},
    {365.4517,5417.5117,12.6339,357.5184},{365.9466,5438.1099,25.5051,178.1719},{339.8329,5411.1133,9.6988,88.4133},
    {438.5025,5411.1763,9.6985,91.0744},{359.0959,5352.5674,25.4713,270.6688},{463.6161,5354.2051,25.4713,89.9672},
    {470.7661,5300.1846,25.4712,178.9496}
};

new Float:HotringsDerby[][4] = // 9
{
    {3582.1506,-2045.5038,451.0152,270.1664},{3600.6216,-2045.3131,451.0154,269.7167},{3623.7219,-2045.3839,451.0166,270.1424},
    {3617.1204,-2053.3733,451.0190,179.2603},{3625.3601,-2072.1628,451.0186,315.0384},{3659.0806,-2062.7686,451.0139,270.8217},
    {3720.9290,-2045.2946,451.0143,89.7567},{3701.7119,-2045.2976,451.0139,90.2672},{3680.8796,-2045.2488,451.0164,89.5181}
};

new Float:InfernusDerby[][4] = // 7
{
    {-2180.6416,-2393.6860,813.1984,182.5601},{-2164.2717,-2395.5850,813.1985,181.2086},{-2164.8987,-2540.7427,813.2039,358.3727},
    {-2178.5198,-2541.8076,813.2037,358.3727},{-2143.4695,-2532.3459,813.2565,270.5792},{-2103.1384,-2506.9592,813.2532,358.5311},
    {-2164.6770,-2469.1477,827.3145,93.5716}
};

enum
{
    NON_DERBY = 1,
    RANCHERS_DERBY,
    BULLETS_DERBY,
    HOTRINGS_DERBY,
    INFERNUS_DERBY
};

new InDerby[MAX_PLAYERS],
    DerbyGame = 1,
    DerbyVehicles[MAX_PLAYERS],
    PlayersInDerby = 0,
    bool:DerbyStarted = false,
    Text:DerbyInfo;

new DerbyCountDownFromAmount = 0,
    DerbyTimer, DerbyTDTimer;

//TDM Minigames

#define MAX_TDM_PLAYERS 20
#define TDMTeamOne 137
#define TDMTeamTwo 138

enum _:TDMs
{
    NON_TDM,
    TDM_ONE,
    TDM_TWO
};

new InTDM[MAX_PLAYERS],
    TDMGame,
    PlayersInTDM = 0,
    PlayerTeamOne = 0,
    PlayerTeamTwo = 0,
    bool:TDMStarted,
    Text:TDMInfo;

new TDMCountDownFromAmount = 0,
    TDMTimer, TDTimer;

new TeamBalance = 0;

//Inventory


new PervSkin[MAX_PLAYERS],
	BuySkin[MAX_PLAYERS];

//Property System

#define     MAX_PROPERTY        (1000)
#define     MAX_PROPERTY_NAME	(32) 
#define     PROPERTY_REVENUE    (60) // Minutes
#define     PROPERTY_DAYS  		(4)

enum PropertyData
{
	//MySQL
	prName[MAX_PROPERTY_NAME],
	Owner[MAX_PLAYER_NAME],
	Float:PropertyX,
	Float:PropertyY,
	Float:PropertyZ,
	Price,
	Earning,
	PropertyExpire,

	//Non-MySQL
	bool:PropertySave,
	Text3D: PropertyLabel,
	PropertyMapIcon,
	PropertyPickup
}

new pInfo[MAX_PROPERTY][PropertyData],
 	Iterator:Property<MAX_PROPERTY>,
 	AvailablePID[MAX_PLAYERS],
 	pTimer[MAX_PLAYERS];

new PlayerItem[MAX_PLAYERS], CompleteLoop[MAX_PLAYERS];

//House System

#define     MAX_HOUSES          (1000)
#define     HOUSE_DAYS          (5)
#define     MAX_INT_NAME        (32)
#define     INVALID_HOUSE_ID    (-1)
#define     HOUSE_COOLDOWN      (4)

enum    _:e_lockmodes
{
    STATUS_LOCK,
    STATUS_NOLOCK,
    STATUS_KEYS
}

enum    _:e_selectmodes
{
    SELECT_MODE_NONE,
    SELECT_MODE_EDIT,
    SELECT_MODE_SELL
}

enum    e_house
{
    Owner[MAX_PLAYER_NAME],
    Float: houseX,
    Float: houseY,
    Float: houseZ,
    Price,
    SalePrice,
    Interior,
    LockMode,
    SafeMoney,
    HouseExpire,
    Text3D: HouseLabel,
    HousePickup,
    HouseIcon,
    bool:HouseSave
};

enum    e_interior
{
    InteriorName[MAX_INT_NAME],
    Float: intX,
    Float: intY,
    Float: intZ,
    intID,
    intPickup
};

enum    e_sazone
{
    SAZONE_NAME[28],
    Float: SAZONE_AREA[6]
};

new
    HouseData[MAX_HOUSES][e_house],
    Iterator: Houses<MAX_HOUSES>,
    Iterator: HouseKeys[MAX_PLAYERS]<MAX_HOUSES>,
    InHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...},
    SelectMode[MAX_PLAYERS] = {SELECT_MODE_NONE, ...},
    LastVisitedHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...},
    ListPage[MAX_PLAYERS] = {0, ...};

new HouseInteriors[][e_interior] = 
{
    {"Small 1", 2283.04, -1140.28, 1050.90, 11},
    {"Medium 1", 2237.59, -1081.64, 1049.02, 2},
    {"Medium 2", 2308.77, -1212.94, 1049.02, 6},
    {"Large 1", 2365.2690, -1135.5980, 1050.8826, 8},
    {"Large 2", 2270.38, -1210.35, 1047.56, 10},
    {"Large 3", -68.81, 1351.21, 1080.21, 6},
    {"Large 4", 2317.8020, -1026.7559, 1050.2178, 9},
    {"Large 5", 2196.85, -1204.25, 1049.02, 6},
    {"Large 6", 2323.6753, -1149.5475, 1050.7101, 12}
};

new LockNames[3][32] = {"{FF0000}Locked", "{00FF00}Unlocked", "{FF0000}Requires Keys"},
    TransactionNames[2][16] = {"{E74C3C}Taken", "{2ECC71}Added"};

//Marijuana System

#define MAX_FARMS 1
#define MAX_MARIJUANA 500
#define GROW_TIME (60) // Minutes

enum mInfo
{
	Owner[MAX_PLAYER_NAME],
	Time,
	Float: pX,
	Float: pY,
	Float: pZ,
	ID,
	Text3D:Label,
	Status,
};

new PlantInfo[MAX_MARIJUANA][mInfo];

enum fInfo
{
	Float: fx,
	Float: fy,
	Float: fx1,
	Float: fy1
};

new FarmInfo[MAX_FARMS][fInfo], FarmActor;

//UGC System

new SelectedUGC[MAX_PLAYERS];

//Weapon Shop

enum WeaponsData
{
    WeaponName[34],
    WeaponID,
    WeaponAmmo,
    WeaponPrice
};

new WeaponShop[][WeaponsData] = 
{
    {"Brass knuckles", WEAPON_BRASSKNUCKLE, 1, 25},
    {"Golf club", WEAPON_GOLFCLUB, 1, 25},
    {"Nite stick", WEAPON_NITESTICK, 1, 25},
    {"Baseball bat", WEAPON_BAT, 1, 25},
    {"Pool cue", WEAPON_POOLSTICK, 1, 25},
    {"Katana", WEAPON_KATANA, 1, 25},
    {"Shovel", WEAPON_SHOVEL, 1, 25},
    {"Chainsaw", WEAPON_CHAINSAW, 1, 25},
    {"Cane", WEAPON_CANE, 1, 25},
    {"Flowers", WEAPON_FLOWER, 1, 25},
    {"Dildo", WEAPON_DILDO, 1, 25},
    {"9mm", WEAPON_COLT45, 3000, 25},
    {"Silenced Pistol", WEAPON_SILENCED, 3000, 25},
    {"Desert Eagle", WEAPON_DEAGLE, 500, 25},
    {"Desert Eagle", WEAPON_DEAGLE, 1500, 50},
    {"Shotgun", WEAPON_SHOTGUN, 500, 25},
    {"Shotgun", WEAPON_SHOTGUN, 1500, 50},
    {"Sawn-off Shotgun", WEAPON_SAWEDOFF, 500, 25},
    {"Sawn-off Shotgun", WEAPON_SAWEDOFF, 1500, 50},
    {"Combat Shotgun", WEAPON_SHOTGSPA, 500, 25},
    {"Combat Shotgun", WEAPON_SHOTGSPA, 1500, 50},
    {"Tec 9", WEAPON_TEC9, 1500, 25},
    {"Tec 9", WEAPON_TEC9, 6000, 50},
    {"Micro SMG", WEAPON_UZI, 1500, 25},
    {"Micro SMG", WEAPON_UZI, 6000, 50},
    {"SMG", WEAPON_MP5, 1500, 25},
    {"SMG", WEAPON_MP5, 6000, 50},
    {"AK-47", WEAPON_AK47, 1500, 25},
    {"AK-47", WEAPON_AK47, 6000, 50},
    {"M4", WEAPON_M4, 1500, 25},
    {"M4", WEAPON_M4, 6000, 50},
    {"Rifle", WEAPON_RIFLE, 200, 25},
    {"Rifle", WEAPON_RIFLE, 500, 50},
    {"Sniper rifle", WEAPON_SNIPER, 200, 25},
    {"Sniper rifle", WEAPON_SNIPER, 500, 50},
    {"Rocket launcher", WEAPON_ROCKETLAUNCHER, 5, 25},
    {"Rocket launcher", WEAPON_ROCKETLAUNCHER, 20, 50},
    {"Rocket launcher", WEAPON_ROCKETLAUNCHER, 100, 200},
    {"Flame trhower", WEAPON_FLAMETHROWER, 200, 25},
    {"Flame trhower", WEAPON_FLAMETHROWER, 500, 50},
    {"Minigun", WEAPON_MINIGUN, 20, 25},
    {"Minigun", WEAPON_MINIGUN, 100, 50},
    {"Minigun", WEAPON_MINIGUN, 500, 200},
    {"Grenade", WEAPON_GRENADE, 100, 25},
    {"Grenade", WEAPON_GRENADE, 300, 50},
    {"Molotov", WEAPON_MOLTOV, 100, 25},
    {"Molotov", WEAPON_MOLTOV, 300, 50},
    {"Camera", WEAPON_CAMERA, 3000, 25},
    {"Fire extinguisher", WEAPON_FIREEXTINGUISHER, 5000, 25},
    {"Spray", WEAPON_SPRAYCAN, 5000, 25},
    {"Parachute", WEAPON_PARACHUTE, 1, 25}
};

//Jobs

enum
{
    NOJOB,
    PARAMEDIC,
    ICECREAM,
    HOTDOG
};

new InJob[MAX_PLAYERS], JobCoolDown[MAX_PLAYERS][3],
    LeaveVehTimer[MAX_PLAYERS];

//Private Vehicle System

#define MAX_SERVER_VEHICLES     2000

enum _:vehLockMods
{
    MODE_NOLOCK = 0,
    MODE_LOCK = 1,
};

enum VehiclesData
{
    vehID,
    vehSessionID,
    vehModel,
    vehName[25],
    vehOwner[26],
    vehPlate[16],
    vehPrice,
    vehLock,
    vehMod[14],
    vehColorOne,
    vehColorTwo,
    vehHydraulics,
    vehNitro,
    Text3D:vehLabel,
    Float:vehX,
    Float:vehY,
    Float:vehZ,
    Float:vehA
};

new vInfo[MAX_VEHICLES][VehiclesData],
    Iterator: ServerVehicles<MAX_VEHICLES>,
    Iterator: PrivateVehicles[MAX_PLAYERS]<MAX_SERVER_VEHICLES>;

enum VehiclesMods
{
    compmod,
    compprice
};

new VehicleMods[][VehiclesMods] =
{
    {1000, 400 },
    {1001, 550 },
    {1002, 200 },
    {1003, 250 },
    {1004, 100 },
    {1005, 150 },
    {1006, 80  },
    {1007, 500 },
    {1011, 220 },
    {1012, 250 },
    {1013, 100 },
    {1014, 400 },
    {1015, 500 },
    {1016, 200 },
    {1018, 400 },
    {1019, 300 },
    {1020, 250 },
    {1021, 200 },
    {1022, 150 },
    {1023, 350 },
    {1024, 50  },
    {1025, 1000},
    {1027, 480 },
    {1028, 770 },
    {1029, 680 },
    {1030, 370 },
    {1032, 170 },
    {1033, 120 },
    {1034, 790 },
    {1035, 150 },
    {1037, 690 },
    {1038, 190 },
    {1039, 390 },
    {1040, 500 },
    {1043, 500 },
    {1044, 500 },
    {1045, 510 },
    {1046, 710 },
    {1049, 810 },
    {1050, 620 },
    {1051, 670 },
    {1052, 530 },
    {1053, 130 },
    {1054, 210 },
    {1055, 230 },
    {1058, 620 },
    {1059, 720 },
    {1060, 530 },
    {1061, 180 },
    {1062, 520 },
    {1063, 430 },
    {1064, 830 },
    {1065, 850 },
    {1066, 750 },
    {1067, 250 },
    {1068, 200 },
    {1071, 550 },
    {1072, 450 },
    {1073, 1100 },   
    {1074, 1030 },   
    {1075, 980 },
    {1076, 1560 },   
    {1077, 1620 },   
    {1078, 1200 },   
    {1079, 1030 },   
    {1080, 900 },
    {1081, 1230 },   
    {1082, 820 },
    {1083, 1560 },   
    {1084, 1350 },   
    {1085, 770 },
    {1087, 1500 },   
    {1088, 150 },
    {1089, 650 },
    {1091, 100 },
    {1092, 750 },
    {1094, 450 },
    {1096, 1000 },   
    {1097, 620 },
    {1098, 1140 },   
    {1099, 1000 },   
    {1100, 940 },
    {1101, 780 },
    {1102, 830 },
    {1103, 3250  },  
    {1104, 1610  },  
    {1105, 1540  },  
    {1107, 780 },
    {1109, 1610  },  
    {1110, 1540  },  
    {1113, 3340  },  
    {1114, 3250  },  
    {1115, 2130  },  
    {1116, 2050  },  
    {1117, 2040  },  
    {1120, 780 },
    {1121, 940 },
    {1123, 860 },
    {1124, 780 },
    {1125, 1120  },  
    {1126, 3340  },  
    {1127, 3250  },  
    {1128, 3340  },  
    {1129, 1650  },  
    {1130, 3380  },  
    {1131, 3290  },  
    {1132, 1590  },  
    {1135, 1500  },  
    {1136, 1000  },  
    {1137, 800 },
    {1138, 580 },
    {1139, 470 },
    {1140, 870 },
    {1141, 980 },
    {1143, 150 },
    {1145, 100 },
    {1146, 490 },
    {1147, 600 },
    {1148, 890 },
    {1149, 1000 },  
    {1150, 1090 },  
    {1151, 840 },
    {1152, 910 },
    {1153, 1200 },  
    {1154, 1030 },  
    {1155, 1030 },  
    {1156, 920 },
    {1157, 930 },
    {1158, 550 },
    {1159, 1050 },  
    {1160, 1050 },  
    {1161, 950 },
    {1162, 650 },
    {1163, 450 },
    {1164, 550 },
    {1165, 850 },
    {1166, 950 },
    {1167, 850 },
    {1168, 950 },
    {1169, 970 },
    {1170, 880 },
    {1171, 990 },
    {1172, 900 },
    {1173, 950 },
    {1174, 1000 },  
    {1175, 1000 },  
    {1176, 900 },
    {1177, 900 },
    {1178, 2050 },  
    {1179, 2150 },  
    {1180, 2130 },  
    {1181, 2050 },  
    {1182, 2130 },  
    {1183, 2040 },  
    {1184, 2150 },  
    {1185, 2040 },  
    {1186, 2095 },  
    {1187, 2175 },  
    {1188, 2080 },  
    {1189, 2200 },  
    {1190, 1200 },  
    {1191, 1040 },  
    {1192, 940 },
    {1193, 1100 }
};

enum VehicleWheelsData
{
    WheelName[16],
    WheelID,
    WheelPrice
};

new VehicleWheels[][VehicleWheelsData] = 
{
    {"Offroad", 1025, 25},
    {"Shadow", 1073, 50},
    {"Mega", 1074, 50},
    {"Rimshine", 1075, 50},
    {"Wires", 1076, 50},
    {"Classic", 1077, 50},
    {"Twist", 1078, 50},
    {"Cutter", 1079, 50},
    {"Switch", 1080, 50},
    {"Grove", 1081, 50},
    {"Import", 1082, 25},
    {"Dollar", 1083, 50},
    {"Trance", 1084, 25},
    {"Attomic", 1085, 25},
    {"Ahab", 1096, 25},
    {"Virtual", 1097, 25},
    {"Access", 1098, 25}
};

enum VehicleSpoilerData
{
    SpoilerName[16],
    SpoilerID,
    SpoilerPrice
};

new VehicleSpoiler[][VehicleSpoilerData] =
{
    {"Pro", 1000, 25},
    {"Win", 1001, 25},
    {"Drag", 1002, 25},
    {"Alpha", 1003, 25},
    {"Champ", 1014, 25},
    {"Race", 1015, 25},
    {"Worx", 1016, 25},
    {"Fury", 1023, 25}
};

//Weapon Drops

#define MAX_DROPS               1000

#define PICKUP_MODEL_WEAPONS    331,333..341,321..326,342..355,372,356..371
#define PICKUP_MODEL_CASH       1274

enum e_STATIC_PICKUP 
{
    pickupModel,
    pickupAmount,
    pickupPickupid,
    pickupTimer
};
new g_StaticPickup[MAX_DROPS][e_STATIC_PICKUP];

//Ammu Nations

#define AMMU_COOLDOWN       4

#define COST_FLOWERS        18
#define COST_STICK          28
#define COST_9MM            120
#define COST_SILENCED       120
#define COST_DEAGLE         400
#define COST_TEC9           120
#define COST_MICRO          120
#define COST_SMG            2200
#define COST_GRENADE        3000
#define COST_SHOTGUN        600
#define COST_SAWNOFF        800
#define COST_COMBAT         1000
#define COST_ARMOR          200
#define COST_RIFLE          1900
#define COST_SNIPER         3800
#define COST_AK47           2500
#define COST_M4             3500

#define AMMO_FLOWERS        1
#define AMMO_STICK          1
#define AMMO_9MM            80
#define AMMO_SILENCED       80
#define AMMO_DEAGLE         45
#define AMMO_TEC9           120
#define AMMO_MICRO          120
#define AMMO_SMG            340
#define AMMO_GRENADE        5
#define AMMO_SHOTGUN        60
#define AMMO_SAWNOFF        20
#define AMMO_COMBAT         40
#define AMMO_ARMOR          100
#define AMMO_RIFLE          20
#define AMMO_SNIPER         10
#define AMMO_AK47           350
#define AMMO_M4             450

enum InteriorsData
{
    Float: iAmmuX,
    Float: iAmmuY,
    Float: iAmmuZ,
    
    AmmuIntID,
    iAmmuPickup
};

new InteriorAmmu[][InteriorsData] =
{
    {286.1017, -41.8042, 1001.5156, 1, -1},
    {296.8799, -112.0711, 1001.5156, 6, -1},
    {286.4948, -86.7819, 1001.5229, 4, -1},
    {316.3775, -170.2922, 999.5938, 6, -1}
};

enum ExteriorsData
{
    Location[19],

    Float: eAmmuX,
    Float: eAmmuY,
    Float: eAmmuZ,

    iAmmuShop,
    eAmmuPickup
};

new ExteriorAmmu[][ExteriorsData] =
{
    {"Market", 1368.5946, -1280.5732, 13.5469, 0, -1},
    {"Willowfield", 2400.5205, -1981.7527, 13.5469, 1, -1},
    {"Palomino Creek", 2333.0850, 61.5750, 26.7058, 2, -1},
    {"Blueberry", 243.2952, -178.3947, 1.5822, 2, -1},
    {"Fort Carson", -316.1610, 829.8505, 14.2422, 1, -1},
    {"Tierra Robada", -1508.8743, 2610.7014, 55.8359, 3, -1},
    {"Old Venturas Strip", 2539.5388, 2084.0107, 10.8203, 2, -1},
    {"Come-A-Lot", 2159.5447, 943.1822, 10.8203, 2, -1},
    {"San Fierro", -2625.8245, 208.2347, 4.8125, 0, -1},
    {"Angel Pine", -2093.6526, -2464.9526, 30.6250, 1, -1},
    {"Bone County", 776.7206, 1871.3811, 4.9065, 1, -1}
};

new AmmuActorsID[4], ammuCP[4];
new InAmmu[MAX_PLAYERS];
new gPlayer_Ammunation[MAX_PLAYERS char], gPlayer_AmmuCoolDown[MAX_PLAYERS];

//Attachment System

#define MAX_ATTACHMENTS 5

new objectlist = mS_INVALID_LISTID;
enum oData 
{ 
    bool:used1, 
    index1, 
    modelid1, 
    bone1, 
    Float:fOffsetX1, 
    Float:fOffsetY1, 
    Float:fOffsetZ1, 
    Float:fRotX1, 
    Float:fRotY1, 
    Float:fRotZ1, 
    Float:fScaleX1, 
    Float:fScaleY1, 
    Float:fScaleZ1 
}
new oInfo[MAX_PLAYERS][MAX_ATTACHMENTS][oData];
new inindex[MAX_PLAYERS], inmodel[MAX_PLAYERS];

// Stunt Maps

enum StuntData
{
    Float:MinX,
    Float:MinY,
    Float:MaxX,
    Float:MaxY,
    MapID
};

new StuntMaps[][StuntData] =
{
    {-115.0, 2390.5, 475.0, 2570.5},
    {1237.0, 1230.5, 1560.0, 1881.5},
    {1560.0, 1286.5, 1710.0, 1702.5},
    {1455.0, 1147.5, 1635.0, 1230.5},
    {1355.0, -2657.5, 2158.0, -2386.5},
    {1850.0, -2386.5, 2088.0, -2232.5},
    {-1769.0, -697.5, -1223.0, -207.5},
    {-1223.0, -440.5, -1092.0, -207.5},
    {-1223.0, -549.5, -1125.0, -440.5},
    {-1724.0, -207.5, -1092.0, -162.5},
    {-1453.0, -162.5, -1099.0, 123.5},
    {-1617.0, -162.5, -1453.0, 16.5}
};

InArea(Float:X, Float:Y, Float:areaMinX, Float:areaMinY, Float:areaMaxX, Float:areaMaxY)
{
    if (X >= areaMinX && X <= areaMaxX && Y >= areaMinY && Y <= areaMaxY) return 1;
    return 0;
}

IsPlayerInStunt(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    for(new i; i < sizeof(StuntMaps); i++)
    {
        if (InArea(x, y, StuntMaps[i][MinX], StuntMaps[i][MinY], StuntMaps[i][MaxX], StuntMaps[i][MaxY]))
        {
           return 1;
        }
    }
    return 0;
}

//XP System

enum LevelData
{
    titleLevel,
    Title[36]
};

new LevelArray[][LevelData] = 
{
    {1, "Upstanding Citizen"},
    {1, "Nobody Special"},
    {1, "Litterer"},
    {1, "Vandal"},
    {4, "Pickpocket"},
    {8, "Tricktster"},
    {12, "Scam Artist"},
    {16, "Thief"},
    {20, "Bully"},
    {24, "Thug"},
    {28, "Fighter"},
    {32, "Criminal"},
    {36, "Robber"},
    {40, "Cut Throat"},
    {44, "Jailbird"},
    {48, "Pimp"},
    {52, "Criminal"},
    {56, "Head Hunter"},
    {60, "Enforcer"},
    {64, "Assassin"},
    {68, "Killer"},
    {72, "The Insidious Killer"},
    {76, "The right hand"},
    {80, "Hangman"},
    {84, "Capo"},
    {88, "Boss"},
    {92, "The Underworld Boss"},
    {96, "Don"},
    {100, "Godfather"}
};

//Real Time

new worldtime_override = 0;
new worldtime_overridehour = 0;
new worldtime_overridemin  = 0;
new serverhour, serverminute;
new timestr[32];

//---------------------------------------//

//------------------------------------: MAIN :------------------------------------//
main()
{
    print("\n\n||=========================================================||");
    print("||                   Explosive Freeroam                    ||");
    print("||                   Developer: _oMa37                     ||");
    print("||=========================================================||\n\n");
}
//--------------------------------------------------------------------------------//

AntiDeAMX()
{
    new a[][] =
    {
        "Unarmed (Fist)",
        "Brass K"
    };
    #pragma unused a
}

public OnGameModeInit()
{
    mysql_log(LOG_ALL);
    mysql = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE, MYSQL_PASSWORD);
    if(mysql_errno() != 0)
    {
        print("[MySQL] Failed Connection");
    }
    else
    {
        print("[MySQL] Successfully Connected");
    }

    objectlist = LoadModelSelectionMenu("objects.txt");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `playersdata` (\
        `ID` int(11) NOT NULL AUTO_INCREMENT,\
        `PlayerName` varchar(25) NOT NULL,\
        `Password` varchar(129) NOT NULL,\
        `IP` varchar(17) NOT NULL,\
        `Email` varchar(35) NOT NULL,\
        `Online` int(5) NOT NULL,\
        `LastSeen` TIMESTAMP NOT NULL,\
        `RegisteredOn` varchar(26) NOT NULL,\
        `AutoLogin` int(11) NOT NULL default 0,\
        `Level` int(11) NOT NULL,\
        `Money` int(11) NOT NULL,\
        `UGC` int(11) NOT NULL,\
        `Kills` int(11) NOT NULL,\
        `Deaths` int(11) NOT NULL,\
        `Suicides` int(11) NOT NULL,\
        `Hours` int(11) NOT NULL,\
        `Minutes` int(11) NOT NULL,\
        `Seconds` int(11) NOT NULL,\
        `Marijuana` int(11) NOT NULL,\
        `Seeds` int(11) NOT NULL,\
        `Cocaine` int(11) NOT NULL,\
        `Premium` int(11) NOT NULL,\
        `PremiumExpires` int(11) NOT NULL,\
        `NameChange` int(11) NOT NULL,\
        `FightStyle` int(11) NOT NULL,\
        `xLevel` int(11) NOT NULL default 1,\
        `XP` int(11) NOT NULL,\
        `Muted` int(11) NOT NULL,\
        `Hitman` int(11) NOT NULL,\
        `gSkills` int(11) NOT NULL,\
        `bSkills` int(11) NOT NULL,\
        `vSkills` int(11) NOT NULL,\
        `aSkills` int(11) NOT NULL,\
        `rSkills` int(11) NOT NULL,\
        `tSkills` int(11) NOT NULL,\
        `mSkills` int(11) NOT NULL,\
        `dSkills` int(11) NOT NULL,\
        `PlayerTeam` int(11) NOT NULL default 225,\
        `MoneyBags` int(11) NOT NULL,\
        `Skin` int(11) NOT NULL,\
        `PosX` float NOT NULL,\
        `PosY` float NOT NULL,\
        `PosZ` float NOT NULL,\
        `Interior` int(11) NOT NULL,\
        `Health` float NOT NULL,\
        `Armour` float NOT NULL,\
        `Jetpack` int(11) NOT NULL,\
        `JetpackExpire` int(11) NOT NULL,\
        `Jump` int(11) NOT NULL,\
        `JumpExpire` int(11) NOT NULL,\
        `Friends` int(11) NOT NULL,\
        `Vehicles` int(11) NOT NULL,\
        `InHouse` int(11) NOT NULL,\
        `PlayerColor` varchar(16) NOT NULL default '0xFFFFFFFF',\
        `TextColor` varchar(16) NOT NULL default 'FFFFFF',\
        `MapHide` int(11) NOT NULL,\
        PRIMARY KEY (`ID`))");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `Maps` (\
        `MapName` varchar(68) NOT NULL,\
        `objectID` int(11) NOT NULL,\
        `objectX` float NOT NULL,\
        `objectY` float NOT NULL,\
        `objectZ` float NOT NULL,\
        `objectRX` float NOT NULL,\
        `objectRY` float NOT NULL,\
        `objectRZ` float NOT NULL,\
        `objectMatInfo1` varchar(64) NOT NULL,\
        `objectMatInfo2` varchar(64) NOT NULL,\
        `objectMatInfo3` varchar(64) NOT NULL)");

   	mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `Property` (\
	    `ID` int(11) NOT NULL default '0',\
	    `Name` varchar(34) default NULL,\
	    `Owner` varchar(24) default '-',\
	    `PropertyX` float default NULL,\
	    `PropertyY` float default NULL,\
	    `PropertyZ` float default NULL,\
	    `Price` int(11) default NULL,\
        `Earning` int(11) default NULL,\
        `Expire` int(11) default NULL,\
        PRIMARY KEY  (`ID`),\
	    UNIQUE KEY `ID` (`ID`)\
	    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

    new query[1024];
    strcat(query, "CREATE TABLE IF NOT EXISTS `Houses` (\
        `ID` int(11) NOT NULL,\
        `HouseOwner` varchar(24) NOT NULL default '-',\
        `HouseX` float NOT NULL,\
        `HouseY` float NOT NULL,\
        `HouseZ` float NOT NULL,\
        `HousePrice` int(11) NOT NULL,\
        `HouseInterior` tinyint(4) NOT NULL default '0',\
        `HouseLock` tinyint(4) NOT NULL default '0',\
        `HouseMoney` int(11) NOT NULL default '0',");

    strcat(query, "`HouseExpire` int(11) NOT NULL, PRIMARY KEY  (`ID`),UNIQUE KEY `ID_2` (`ID`),KEY `ID` (`ID`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

    mysql_tquery(mysql, query);

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `HouseGuns` (\
      `HouseID` int(11) NOT NULL,\
      `WeaponID` tinyint(4) NOT NULL,\
      `Ammo` int(11) NOT NULL,\
      UNIQUE KEY `HouseID_2` (`HouseID`,`WeaponID`),\
      KEY `HouseID` (`HouseID`),\
      CONSTRAINT `houseguns_ibfk_1` FOREIGN KEY (`HouseID`) REFERENCES `Houses` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE\
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `HouseVisitors` (\
      `HouseID` int(11) NOT NULL,\
      `Visitor` varchar(24) NOT NULL,\
      `Date` int(11) NOT NULL\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `HouseKeys` (\
      `HouseID` int(11) NOT NULL,\
      `Player` varchar(24) NOT NULL,\
      `Date` int(11) NOT NULL\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `HouseSafeLogs` (\
      `HouseID` int(11) NOT NULL,\
      `Type` int(11) NOT NULL,\
      `Amount` int(11) NOT NULL,\
      `Date` int(11) NOT NULL\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `Vehicles` (\
      `vehID` int(11) NOT NULL,\
      `vehModel` int(11) NOT NULL,\
      `vehName` varchar(25) NOT NULL,\
      `vehOwner` varchar(25) NOT NULL default '-',\
      `vehPlate` varchar(16) NOT NULL default 'UG',\
      `vehPrice` int(11) NOT NULL,\
      `vehLock` int(11) NOT NULL,\
      `vehMod_1` int(11) NOT NULL,\
      `vehMod_2` int(11) NOT NULL,\
      `vehMod_3` int(11) NOT NULL,\
      `vehMod_4` int(11) NOT NULL,\
      `vehMod_5` int(11) NOT NULL,\
      `vehMod_6` int(11) NOT NULL,\
      `vehMod_7` int(11) NOT NULL,\
      `vehMod_8` int(11) NOT NULL,\
      `vehMod_9` int(11) NOT NULL,\
      `vehMod_10` int(11) NOT NULL,\
      `vehMod_11` int(11) NOT NULL,\
      `vehMod_12` int(11) NOT NULL,\
      `vehMod_13` int(11) NOT NULL,\
      `vehMod_14` int(11) NOT NULL,\
      `vehColorOne` int(11) NOT NULL,\
      `vehColorTwo` int(11) NOT NULL,\
      `vehHydraulics` int(11) NOT NULL,\
      `vehNitro` int(11) NOT NULL,\
      `vehX` float NOT NULL,\
      `vehY` float NOT NULL,\
      `vehZ` float NOT NULL,\
      `vehA` float NOT NULL,\
      UNIQUE KEY `vehID` (`vehID`))");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `Attachments` (`ID` int(5) NOT NULL,`Index` int(2) NOT NULL,`Model` int(7) NOT NULL,`Bone` int(2) NOT NULL,`OffsetX` float NOT NULL,`OffsetY` float NOT NULL,`OffsetZ` float NOT NULL,`RotX` float NOT NULL,`RotY` float NOT NULL,`RotZ` float NOT NULL,`ScaleX` float NOT NULL,`ScaleY` float NOT NULL,`ScaleZ` float NOT NULL)");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `BannedPlayers` (`PlayerName` varchar(24) NOT NULL, `BannedBy` varchar(24) NOT NULL, `BanOn` varchar(24) NOT NULL, `BanReason` varchar(24) NOT NULL, `BanExpire` int(18) NOT NULL, `IP` varchar(17) NOT NULL, PRIMARY KEY (`PlayerName`))");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `Weapons` (`ID` int(5) NOT NULL, `Weapon` tinyint(3) NOT NULL, `Ammo` int(10) NOT NULL, UNIQUE KEY `ID_2` (`ID`, `Weapon`) ) ENGINE=InnoDB;");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `SkinData` ( `ID` int(5) NOT NULL, `SkinID` int(4) NOT NULL)");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `FriendsData` ( `ID` int(5) NOT NULL, `FriendID` int(5) NOT NULL)");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `OfflinePMs` ( `PlayerName` varchar(24) NOT NULL, `SenderName` varchar(24) NOT NULL, `Message` varchar(84) NOT NULL, `Status` int(11) NOT NULL, `Date` TIMESTAMP NOT NULL)");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `Market` (`Seller` varchar(25) NOT NULL, `Amount` int(11) NOT NULL, `Price` int(11) NOT NULL, PRIMARY KEY (`Seller`), UNIQUE KEY `Seller` (`Seller`))");

    mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `PlayerLogs` (`PlayerName` varchar(25) NOT NULL, `Text` varchar(60) NOT NULL, `Date` int(11) NOT NULL)");

    for(new i; i < MAX_PROPERTY; ++i)
    {
        format(pInfo[i][prName], MAX_PLAYER_NAME, "Property");
        format(pInfo[i][Owner], MAX_PLAYER_NAME, "-");
        pInfo[i][PropertyLabel] = Text3D: INVALID_3DTEXT_ID;
        pInfo[i][PropertyPickup] = -1;
    }

    for(new i; i < MAX_HOUSES; ++i)
    {
        HouseData[i][HouseLabel] = Text3D: INVALID_3DTEXT_ID;
        HouseData[i][HousePickup] = -1;
        HouseData[i][HouseIcon] = -1;
        HouseData[i][HouseSave] = false;
    }

    for(new i; i < sizeof(HouseInteriors); ++i)
    {
        HouseInteriors[i][intPickup] = CreateDynamicPickup(1318, 1, HouseInteriors[i][intX], HouseInteriors[i][intY], HouseInteriors[i][intZ], .interiorid = HouseInteriors[i][intID]);
    }

    for(new i = 0; i < MAX_OBJECTS; i ++)
    objects[i] = -1;

    for(new i = 0; i < 300; i++)
    {
        if(i != 74)
        {
            AddPlayerClass(i, 1095.6807, 1079.3359, 10.8359, 311.4607, 0, 0, 0, 0, 0, 0);
        }
    }

    new iTeamTurfs[sizeof(g_Team)];
    for (new i, j = sizeof(g_Turf); i < j; i++) 
    {
        g_Turf[i][turfId] = GangZoneCreate(g_Turf[i][turfPos][0], g_Turf[i][turfPos][1], g_Turf[i][turfPos][2], g_Turf[i][turfPos][3]);
        g_Turf[i][areaId] = CreateDynamicRectangle(g_Turf[i][turfPos][0], g_Turf[i][turfPos][1], g_Turf[i][turfPos][2], g_Turf[i][turfPos][3], 0, 0, -1);

        g_Turf[i][turfTimer] = -1;
        
        for (new k, l = sizeof(g_Team); k < l; k++) 
        {
            g_MembersInTurf[i][k] = 0;
        }
        
        iTeamTurfs[g_Turf[i][turfOwner]]++;
    }
    for (new i, j = sizeof(g_Team); i < j; i++) 
    {
        printf("Loaded %i turfs for team %s", iTeamTurfs[i], g_Team[i][teamName]);
    }
    printf("Total %i turfs loaded", sizeof(g_Turf));
    

    CreateDynamicPickup(1274, 0, 2501.6370, -1686.3329, 13.5024, -1, -1, -1, 100.0); // Grove
    CreateDynamicPickup(1274, 0, 2165.7722, -1676.3916, 15.0859, -1, -1, -1, 100.0); // Ballas
    CreateDynamicPickup(1274, 0, 2347.2505, -1169.4064, 28.0195, -1, -1, -1, 100.0); // Vagos
    CreateDynamicPickup(1274, 0, 1952.5033, -2038.0951, 13.5469, -1, -1, -1, 100.0); // Aztecas
    CreateDynamicPickup(1274, 0, 1153.8942, -1768.5330, 16.5938, -1, -1, -1, 100.0); // Bikers 
    CreateDynamicPickup(1274, 0, 690.3701, -1275.8894, 13.5599, -1, -1, -1, 100.0); // Triads
    CreateDynamicPickup(1274, 0, 1126.2686, -2037.0341, 69.8836, -1, -1, -1, 100.0); // Mafia
    CreateDynamicPickup(1274, 0, 401.5297, -1801.8387, 7.8281, -1, -1, -1, 100.0); // Nang
    
    TeamsLabel[GROVE] = CreateDynamic3DTextLabel("Gang: Grove Street\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 2501.6370, -1686.3329, 13.5024, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[BALLAS] = CreateDynamic3DTextLabel("Gang: Ballas\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 2165.7722, -1676.3916, 15.0859, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[VAGOS] = CreateDynamic3DTextLabel("Gang: Los Santos Vagos\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 2347.2505, -1169.4064, 28.0195, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[AZTECAS] = CreateDynamic3DTextLabel("Gang: Varrios Los Aztecas\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 1952.5033, -2038.0951, 13.5469, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[BIKERS] = CreateDynamic3DTextLabel("Gang: Bikers\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 1153.8942, -1768.5330, 16.5938, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[TRIADS] = CreateDynamic3DTextLabel("Gang: Triads\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 690.3701, -1275.8894, 13.5599, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[MAFIA] = CreateDynamic3DTextLabel("Gang: Mafia\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 1126.2686, -2037.0341, 69.8836, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);
    TeamsLabel[NANG] = CreateDynamic3DTextLabel("Gang: Da Nang Boys\nMembers: 0\nPress LALT to join the gang", 0xFFFF00FF, 401.5297, -1801.8387, 7.8281, 15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, -1, -1, -1, 100.0);


    pPickups[0] = CreateDynamicPickup(1318, 1, 2616.3792, -1774.3635, 673.8264, -1, -1, -1, 100.0); // Parkour #1
    pPickups[1] = CreateDynamicPickup(1318, 1, 2551.7505, -1443.2358, 356.3383, -1, -1, -1, 100.0); // Parkour #2
    pPickups[2] = CreateDynamicPickup(1318, 1, 1991.7462, 1371.0575, 125.9518, -1, -1, -1, 100.0); // Parkour #6

    pCheckpoints[0] = CreateDynamicCP(-8.3860 ,-2759.0767, 40.5662, 5.0, -1, -1, -1, 100.0); // Parkour #3
    pCheckpoints[1] = CreateDynamicCP(3228.0828, -400.2931, 563.0695, 5.0, -1, -1, -1, 100.0); // Parkour #4 - Switch BMX
    pCheckpoints[2] = CreateDynamicCP(3344.2551, -31.8631, 596.3174, 5.0, -1, -1, -1, 100.0); // Parkour #4 - Switch NRG
    pCheckpoints[3] = CreateDynamicCP(4356.5444, -126.5376, 540.3953, 5.0, -1, -1, -1, 100.0); // Parkour #4 - Finish
    pCheckpoints[4] = CreateDynamicCP(3020.4238, -1887.6017, 26.1592, 5.0, -1, -1, -1, 100.0); // Parkour #5 - BMX
 
    sCheckpoints[0] = CreateDynamicCP(3567.9790, 619.4030, 1.7450, 5.0, -1, -1, -1, 100.0);
    sCheckpoints[1] = CreateDynamicCP(-151.4400, 7715.9692, 1115.9143, 5.0, -1, -1, -1, 100.0);
    sCheckpoints[2] = CreateDynamicCP(1789.0128, 2868.5483, 180.2221, 5.0, -1, -1, -1, 100.0);

    ClassVehicles[0] = CreateVehicle(541, 1093.4780, 1077.6095, 10.4596, 308.1884, 211,1, -1, 0); // BulletClass
    ClassVehicles[1] = CreateVehicle(425, 1081.6802, 1079.4536, 11.4037, 284.6955, 43, 0, -1, 0); // HunterClass #1
    ClassVehicles[2] = CreateVehicle(425, 1090.8882, 1065.5909, 11.4080, 322.1225, 43, -1, 0); // HunterClass #2

    SetVehicleVirtualWorld(ClassVehicles[0], 99);
    SetVehicleVirtualWorld(ClassVehicles[1], 99);
    SetVehicleVirtualWorld(ClassVehicles[2], 99);

    SetVehicleParamsEx(ClassVehicles[0], VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF);
    SetVehicleParamsEx(ClassVehicles[1], VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF);
    SetVehicleParamsEx(ClassVehicles[2], VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF);

    // Load Properties
    mysql_tquery(mysql, "SELECT * FROM Property", "LoadProperties", "");
    // Load Houses
    Iter_Init(HouseKeys);
    mysql_tquery(mysql, "SELECT * FROM Houses", "LoadHouses", "");
    foreach(new i : Player) House_PlayerInit(i);
    // Load Vehicles
    Iter_Init(PrivateVehicles);
    mysql_tquery(mysql, "SELECT * FROM `Vehicles` WHERE `vehOwner` = '-'", "LoadDealerVehicles", "");

    //HP Pickups
    AddStaticPickup(1240,2,2029.1514,-1411.8231,16.9989,0); //LS
    AddStaticPickup(1240,2,1172.8368,-1323.5652,15.4000,0); //LS
    AddStaticPickup(1242,2,-2115.4956,-2406.3103,31.3005,0); //Angel Pine
    AddStaticPickup(1240,2,-2197.2693,-2302.8850,30.6250,0); //Angel Pine
    AddStaticPickup(1240,2,-2656.391845,635.540161,14.453125,0); //SF
    AddStaticPickup(1240,2,-314.7559,1056.3252,19.7422,0); //Fort Carson
    AddStaticPickup(1240,2,1606.9604,1818.5217,10.8203,0); //LV
    AddStaticPickup(1240,2,1243.1571,329.7328,19.7578,0); //Montogemory
    AddStaticPickup(1240,2,-1514.8082,2523.7813,55.8071,0); //El Quebrados

    //Marijuana Farms
    CreateFarm(-1194.8500,-1006.9475,-1064.4344,-916.0088);
    FarmActor = CreateActor(158, -1061.2837, -1195.5339, 129.7724, 266.7850);
    ApplyActorAnimation(FarmActor, "DEALER", "DEALER_IDLE", 4.1, true, false, false, false, 0);
    CreateDynamic3DTextLabel("{00FF00}Marijuana Seeds\n{FFFFFF}Type /buyseeds to buy it!", -1, -1061.2837, -1195.5339, 129.7724, 10.0);
    CreateDynamicMapIcon(-1061.2837, -1195.5339, 129.7724, 16, 0, 0, 0);

    //Jetpacks
    JetPickups[0] = CreateDynamicPickup(370, 1, -1540.1964, -438.0461, 6.0000, 0, 0);
    JetPickups[1] = CreateDynamicPickup(370, 1, 1710.2638, 1617.7842, 10.0288, 0, 0);
    JetPickups[2] = CreateDynamicPickup(370, 1, 1953.3990, -2178.2686, 13.5469, 0, 0);

    //Ammu-Nations
    for(new i; i < sizeof(InteriorAmmu); ++i)
    {
        InteriorAmmu[i][iAmmuPickup] = CreateDynamicPickup(1318, 1, InteriorAmmu[i][iAmmuX], InteriorAmmu[i][iAmmuY], InteriorAmmu[i][iAmmuZ], .interiorid = InteriorAmmu[i][AmmuIntID]);
    }

    for(new i; i < sizeof(ExteriorAmmu); ++i)
    {
        ExteriorAmmu[i][eAmmuPickup] = CreateDynamicPickup(1318, 1, ExteriorAmmu[i][eAmmuX], ExteriorAmmu[i][eAmmuY], ExteriorAmmu[i][eAmmuZ], 0, 0);
        Streamer_SetIntData(STREAMER_TYPE_PICKUP, ExteriorAmmu[i][eAmmuPickup], E_STREAMER_EXTRA_ID, sizeof ExteriorAmmu + i);

        CreateDynamicMapIcon(ExteriorAmmu[i][eAmmuX], ExteriorAmmu[i][eAmmuY], ExteriorAmmu[i][eAmmuZ], 6, 0, 0, 0);
    }

    AmmuActorsID[0] = CreateActor(179, 296.6111, -40.2154, 1001.5156, 359.7729);
    ApplyActorAnimation(AmmuActorsID[0], "FOOD", "SHP_Tray_Pose", 4.1, 1, 1, 1, 0, 0); 

    AmmuActorsID[1] = CreateActor(179, 290.0341, -111.5130, 1001.5156, 0.4230);
    ApplyActorAnimation(AmmuActorsID[1], "FOOD", "SHP_Tray_Pose", 4.1, 1, 1, 1, 0, 0); 

    AmmuActorsID[2] = CreateActor(179, 295.6153, -82.5280, 1001.5156, 359.1696);
    ApplyActorAnimation(AmmuActorsID[2], "FOOD", "SHP_Tray_Pose", 4.1, 1, 1, 1, 0, 0); 

    AmmuActorsID[3] = CreateActor(179, 312.3922, -167.7643, 999.5938, 359.7964);
    ApplyActorAnimation(AmmuActorsID[3], "FOOD", "SHP_Tray_Pose", 4.1, 1, 1, 1, 0, 0);

    ammuCP[0] = CreateDynamicCP(296.6505, -38.2682, 1001.5156, 1.0);
    ammuCP[1] = CreateDynamicCP(312.4412, -166.1412, 999.6010, 1.0);
    ammuCP[2] = CreateDynamicCP(290.0348, -109.7822, 1001.5156, 1.0);
    ammuCP[3] = CreateDynamicCP(295.6606, -80.8118, 1001.5156, 1.0);


    /*===========================Hospitals Map Icons===============================*/
    CreateDynamicMapIcon(2027.4375, -1421.0703, 16.9922, 22, 0);
    CreateDynamicMapIcon(1177.9089, -1323.9611, 14.0939, 22, 0);
    CreateDynamicMapIcon(1579.6106, 1769.0625, 10.8203, 22, 0);
    CreateDynamicMapIcon(-321.8259, 1056.7279, 19.7422, 22, 0);
    CreateDynamicMapIcon(-1514.8807, 2527.8003, 55.7315, 22, 0);
    CreateDynamicMapIcon(-2662.0439, 630.5056, 14.4531, 22, 0);
    CreateDynamicMapIcon(-2199.2495, -2311.0444, 30.6250, 22, 0);
    CreateDynamicMapIcon(1244.1959, 332.2817, 19.5547, 22, 0);
    /*==============================Gangs Map Icons================================*/
    CreateDynamicMapIcon(2501.6370, -1686.3329, 13.5024, 62, 0); // Grove
    CreateDynamicMapIcon(2165.7722, -1676.3916, 15.0859, 59, 0); // Ballas
    CreateDynamicMapIcon( 2347.2505, -1169.4064, 28.0195, 60, 0); // Vagos
    CreateDynamicMapIcon( 1952.5033, -2038.0951, 13.5469, 58, 0); // Aztecas
    CreateDynamicMapIcon(1153.8942, -1768.5330, 16.5938, 46, 0); // Bikers
    CreateDynamicMapIcon(690.3701, -1275.8894, 13.5599, 43, 0); // Triad
    CreateDynamicMapIcon(1126.2686, -2037.0341, 69.8836, 26, 0); // Mafia
    CreateDynamicMapIcon(401.5297, -1801.8387, 7.8281, 9, 0); // Nang

    // Vehicle Spawner
    Airplanes = LoadModelSelectionMenu("eFData/Vehicles/Airplane.txt");
    Bikes = LoadModelSelectionMenu("eFData/Vehicles/Bike.txt");
    Boats = LoadModelSelectionMenu("eFData/Vehicles/Boat.txt");
    Convertible = LoadModelSelectionMenu("eFData/Vehicles/Convertible.txt");
    Helicopters = LoadModelSelectionMenu("eFData/Vehicles/Helicopter.txt");
    Industrials = LoadModelSelectionMenu("eFData/Vehicles/Industrial.txt");
    Lowrider = LoadModelSelectionMenu("eFData/Vehicles/Lowrider.txt");
    OffRoad = LoadModelSelectionMenu("eFData/Vehicles/OffRoad.txt");
    PublicService = LoadModelSelectionMenu("eFData/Vehicles/PublicService.txt");
    Saloon = LoadModelSelectionMenu("eFData/Vehicles/Saloon.txt");
    Sports = LoadModelSelectionMenu("eFData/Vehicles/Sport.txt");
    StationWagon = LoadModelSelectionMenu("eFData/Vehicles/StationWagon.txt");
    Unique = LoadModelSelectionMenu("eFData/Vehicles/Unique.txt");


    AntiDeAMX();
    CA_Init();
    DisableInteriorEnterExits();
    UsePlayerPedAnims();
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    EnableStuntBonusForAll(0);
    ShowNameTags(true);
    SetNameTagDrawDistance(NAMETAG_DRAW_DISTANCE);
    SetGravity(GRAVITY);
    LoadDynamicObjects();
    UpdateTimeAndWeather();
    SetGameModeText("Freeroam/Gang/DM");
    Timer[1] = SetTimer("MoneyBag", MB_DELAY, true);
    xReactionTimer = SetTimer("xReactionTest", TIME, 1);
    SetTimer("UpdateTimeAndWeather",1000 * 60,1);
    SetTimer("ExpireStuff", 10000, true);
	SetTimer("PlantGrow", GROW_TIME * 1000,1);
    SetTimer("PausedCheck", 5000, 1);
    SendRconCommand("hostname [ --> uG Explosive Freeroam - Los Santos <-- ]");
    LoadTeleports();

    Textdraw0 = TextDrawCreate(0.000000, 437.000000, "~g~]~g~ ]~g~ ]");
    TextDrawBackgroundColor(Textdraw0, 255);
    TextDrawFont(Textdraw0, 2);
    TextDrawLetterSize(Textdraw0, 0.500000, 1.000000);
    TextDrawColor(Textdraw0, -1);
    TextDrawSetOutline(Textdraw0, 0);
    TextDrawSetProportional(Textdraw0, 1);
    TextDrawSetShadow(Textdraw0, 1);
    TextDrawUseBox(Textdraw0, 1);
    TextDrawBoxColor(Textdraw0, 102);
    TextDrawTextSize(Textdraw0, 642.000000, 51.000000);
    TextDrawSetSelectable(Textdraw0, 0);

    Textdraw1 = TextDrawCreate(578.000000, 437.000000, "~g~]~g~ ]~g~ ]");
    TextDrawBackgroundColor(Textdraw1, 255);
    TextDrawFont(Textdraw1, 2);
    TextDrawLetterSize(Textdraw1, 0.500000, 1.000000);
    TextDrawColor(Textdraw1, -1);
    TextDrawSetOutline(Textdraw1, 0);
    TextDrawSetProportional(Textdraw1, 1);
    TextDrawSetShadow(Textdraw1, 1);
    TextDrawSetSelectable(Textdraw1, 0);

    Textdraw2 = TextDrawCreate(136.000000, 437.000000, "/HELP     /SHOP     UN-GAMING.COM     /GANGHELP     /CAR");
    TextDrawBackgroundColor(Textdraw2, 255);
    TextDrawFont(Textdraw2, 1);
    TextDrawLetterSize(Textdraw2, 0.379999, 1.000000);
    TextDrawColor(Textdraw2, -1);
    TextDrawSetOutline(Textdraw2, 0);
    TextDrawSetProportional(Textdraw2, 1);
    TextDrawSetShadow(Textdraw2, 1);
    TextDrawSetSelectable(Textdraw2, 0);

    Textdraw3 = TextDrawCreate(215.000000, 412.000000, "~y~Freeroam ~r~- ~b~GangWars ~r~ - ~w~DM ~r~ - ~p~Minigames");
    TextDrawBackgroundColor(Textdraw3, 255);
    TextDrawFont(Textdraw3, 1);
    TextDrawLetterSize(Textdraw3, 0.300000, 1.899999);
    TextDrawColor(Textdraw3, -1);
    TextDrawSetOutline(Textdraw3, 0);
    TextDrawSetProportional(Textdraw3, 1);
    TextDrawSetShadow(Textdraw3, 1);
    TextDrawSetSelectable(Textdraw3, 0);

    Textdraw4 = TextDrawCreate(200.000000, 371.000000, "New Textdraw");
    TextDrawBackgroundColor(Textdraw4, 0xFFFFFF00);
    TextDrawFont(Textdraw4, 5);
    TextDrawLetterSize(Textdraw4, 0.500000, 1.000000);
    TextDrawColor(Textdraw4, -1);
    TextDrawSetOutline(Textdraw4, 0);
    TextDrawSetProportional(Textdraw4, 1);
    TextDrawSetShadow(Textdraw4, 1);
    TextDrawUseBox(Textdraw4, 1);
    TextDrawBoxColor(Textdraw4, 255);
    TextDrawTextSize(Textdraw4, 80.000000, 61.000000);
    TextDrawSetPreviewModel(Textdraw4, 451);
    TextDrawSetPreviewRot(Textdraw4, 130.000000, 130.000000, 250.000000, 1.000000);
    TextDrawSetSelectable(Textdraw4, 0);
    TextDrawSetPreviewVehCol(Textdraw4, 1, 1);

    Textdraw5 = TextDrawCreate(355.000000, 371.000000, "New Textdraw");
    TextDrawBackgroundColor(Textdraw5, 0xFFFFFF00);
    TextDrawFont(Textdraw5, 5);
    TextDrawLetterSize(Textdraw5, 0.500000, 1.000000);
    TextDrawColor(Textdraw5, -1);
    TextDrawSetOutline(Textdraw5, 0);
    TextDrawSetProportional(Textdraw5, 1);
    TextDrawSetShadow(Textdraw5, 1);
    TextDrawUseBox(Textdraw5, 1);
    TextDrawBoxColor(Textdraw5, 255);
    TextDrawTextSize(Textdraw5, 80.000000, 61.000000);
    TextDrawSetPreviewModel(Textdraw5, 411);
    TextDrawSetPreviewRot(Textdraw5, 130.000000, -130.000000, -250.000000, 1.000000);
    TextDrawSetSelectable(Textdraw5, 0);
    TextDrawSetPreviewVehCol(Textdraw5, 1, 1);
    
    Textdraw6 = TextDrawCreate(320.000000, 367.000000, "New Textdraw");
    TextDrawBackgroundColor(Textdraw6, 0xFFFFFF00);
    TextDrawFont(Textdraw6, 5);
    TextDrawLetterSize(Textdraw6, 0.500000, 1.000000);
    TextDrawColor(Textdraw6, -1);
    TextDrawSetOutline(Textdraw6, 0);
    TextDrawSetProportional(Textdraw6, 1);
    TextDrawSetShadow(Textdraw6, 1);
    TextDrawUseBox(Textdraw6, 1);
    TextDrawBoxColor(Textdraw6, 255);
    TextDrawTextSize(Textdraw6, 50.000000, 51.000000);
    TextDrawSetPreviewModel(Textdraw6, 115);
    TextDrawSetPreviewRot(Textdraw6, -16.000000, 0.000000, -55.000000, 1.000000);
    TextDrawSetSelectable(Textdraw6, 0);

    Textdraw7 = TextDrawCreate(260.000000, 367.000000, "New Textdraw");
    TextDrawBackgroundColor(Textdraw7, 0xFFFFFF00);
    TextDrawFont(Textdraw7, 5);
    TextDrawLetterSize(Textdraw7, 0.500000, 1.000000);
    TextDrawColor(Textdraw7, -1);
    TextDrawSetOutline(Textdraw7, 0);
    TextDrawSetProportional(Textdraw7, 1);
    TextDrawSetShadow(Textdraw7, 1);
    TextDrawUseBox(Textdraw7, 1);
    TextDrawBoxColor(Textdraw7, 255);
    TextDrawTextSize(Textdraw7, 50.000000, 51.000000);
    TextDrawSetPreviewModel(Textdraw7, 299);
    TextDrawSetPreviewRot(Textdraw7, -16.000000, 0.000000, 55.000000, 1.000000);
    TextDrawSetSelectable(Textdraw7, 0);
    
    Textdraw8 = TextDrawCreate(294.000000, 385.000000, "~g~] ~w~UG ~g~]");
    TextDrawBackgroundColor(Textdraw8, 255);
    TextDrawFont(Textdraw8, 2);
    TextDrawLetterSize(Textdraw8, 0.300000, 2.300000);
    TextDrawColor(Textdraw8, -1);
    TextDrawSetOutline(Textdraw8, 0);
    TextDrawSetProportional(Textdraw8, 1);
    TextDrawSetShadow(Textdraw8, 1);
    TextDrawSetSelectable(Textdraw8, 0);
    
    Textdraw9 = TextDrawCreate(643.000000, 351.700012, "~n~~n~~n~~n~~n~~n~~n~~n~~n~");
    TextDrawBackgroundColor(Textdraw9, 255);
    TextDrawFont(Textdraw9, 1);
    TextDrawLetterSize(Textdraw9, 0.500000, 1.000000);
    TextDrawColor(Textdraw9, -1);
    TextDrawSetOutline(Textdraw9, 0);
    TextDrawSetProportional(Textdraw9, 1);
    TextDrawSetShadow(Textdraw9, 1);
    TextDrawUseBox(Textdraw9, 1);
    TextDrawBoxColor(Textdraw9, 102);
    TextDrawTextSize(Textdraw9, 500.000000, 90.000000);
    TextDrawSetSelectable(Textdraw9, 0);

    Textdraw10 = TextDrawCreate(510.000000, 354.000000, "");
    TextDrawBackgroundColor(Textdraw10, 255);
    TextDrawFont(Textdraw10, 1);
    TextDrawLetterSize(Textdraw10, 0.219999, 1.000000);
    TextDrawColor(Textdraw10, -1);
    TextDrawSetOutline(Textdraw10, 0);
    TextDrawSetProportional(Textdraw10, 1);
    TextDrawSetShadow(Textdraw10, 1);
    TextDrawSetSelectable(Textdraw10, 0);

    Textdraw11 = TextDrawCreate(303.000000, 397.000000, "-");
    TextDrawBackgroundColor(Textdraw11, 255);
    TextDrawFont(Textdraw11, 2);
    TextDrawLetterSize(Textdraw11, 2.079999, 1.500000);
    TextDrawColor(Textdraw11, -1);
    TextDrawSetOutline(Textdraw11, 0);
    TextDrawSetProportional(Textdraw11, 1);
    TextDrawSetShadow(Textdraw11, 1);
    TextDrawSetSelectable(Textdraw11, 0);

    Textdraw12 = TextDrawCreate(495.000000, 344.000000, "-");
    TextDrawBackgroundColor(Textdraw12, 255);
    TextDrawFont(Textdraw12, 1);
    TextDrawLetterSize(Textdraw12, 11.260004, 1.000000);
    TextDrawColor(Textdraw12, -1);
    TextDrawSetOutline(Textdraw12, 0);
    TextDrawSetProportional(Textdraw12, 1);
    TextDrawSetShadow(Textdraw12, 1);
    TextDrawSetSelectable(Textdraw12, 0);

    Textdraw13 = TextDrawCreate(501.000000, 328.000000, "I");
    TextDrawBackgroundColor(Textdraw13, 255);
    TextDrawFont(Textdraw13, 1);
    TextDrawLetterSize(Textdraw13, 0.100000, 13.500000);
    TextDrawColor(Textdraw13, -1);
    TextDrawSetOutline(Textdraw13, 0);
    TextDrawSetProportional(Textdraw13, 1);
    TextDrawSetShadow(Textdraw13, 1);
    TextDrawSetSelectable(Textdraw13, 0);
    
    Textdraw14 = TextDrawCreate(0.700000, 432.000000, "-");
    TextDrawBackgroundColor(Textdraw14, 255);
    TextDrawFont(Textdraw14, 1);
    TextDrawLetterSize(Textdraw14, 46.909969, 0.400000);
    TextDrawColor(Textdraw14, -1);
    TextDrawSetOutline(Textdraw14, 0);
    TextDrawSetProportional(Textdraw14, 1);
    TextDrawSetShadow(Textdraw14, 1);
    TextDrawSetSelectable(Textdraw14, 0);

    Textdraw15 = TextDrawCreate(0.700000, 445.000000, "-");
    TextDrawBackgroundColor(Textdraw15, 255);
    TextDrawFont(Textdraw15, 1);
    TextDrawLetterSize(Textdraw15, 46.909969, 0.400000);
    TextDrawColor(Textdraw15, -1);
    TextDrawSetOutline(Textdraw15, 0);
    TextDrawSetProportional(Textdraw15, 1);
    TextDrawSetShadow(Textdraw15, 1);
    TextDrawSetSelectable(Textdraw15, 0);

    BBox = TextDrawCreate(649.000000, 148.500000, "usebox");
    TextDrawLetterSize(BBox, 1.052500, 9.041995);
    TextDrawTextSize(BBox, -1.000000, 0.000000);
    TextDrawAlignment(BBox, 1);
    TextDrawColor(BBox, 0);
    TextDrawUseBox(BBox, true);
    TextDrawBoxColor(BBox, 0x00000055);
    TextDrawSetShadow(BBox, 0);
    TextDrawSetOutline(BBox, 0);
    TextDrawFont(BBox, 0);

    BBounty = TextDrawCreate(259.100036, 144.783294, "Bounty");
    TextDrawLetterSize(BBounty, 1.152400, 4.434296);
    TextDrawAlignment(BBounty, 1);
    TextDrawColor(BBounty, -1);
    TextDrawSetShadow(BBounty, 0);
    TextDrawSetOutline(BBounty, 2);
    TextDrawBackgroundColor(BBounty, 51);
    TextDrawFont(BBounty, 1);
    TextDrawSetProportional(BBounty, 1);

    BText = TextDrawCreate(247.900009, 194.430770, "");
    TextDrawLetterSize(BText, 0.222196, 1.698114);
    TextDrawAlignment(BText, 1);
    TextDrawColor(BText, 0xFF0000AA);
    TextDrawSetShadow(BText, 0);
    TextDrawSetOutline(BText, -1);
    TextDrawBackgroundColor(BText, 51);
    TextDrawFont(BText, 1);
    TextDrawSetProportional(BText, 1);

    ServerTime = TextDrawCreate(550.100036, 20.486669, "");
    TextDrawLetterSize(ServerTime, 0.537997, 2.398931);
    TextDrawTextSize(ServerTime, 72.000038, 26.880025);
    TextDrawAlignment(ServerTime, 1);
    TextDrawColor(ServerTime, -1);
    TextDrawSetShadow(ServerTime, 0);
    TextDrawSetOutline(ServerTime, 2);
    TextDrawBackgroundColor(ServerTime, 255);
    TextDrawFont(ServerTime, 3);
    TextDrawSetProportional(ServerTime, 1);

    WebsiteTD = TextDrawCreate(501.600128, 5.226745, "~g~UN-GAMING.COM");
    TextDrawLetterSize(WebsiteTD, 0.366798, 1.704532);
    TextDrawAlignment(WebsiteTD, 1);
    TextDrawColor(WebsiteTD, 0xFF6600FF);
    TextDrawSetShadow(WebsiteTD, 0);
    TextDrawSetOutline(WebsiteTD, 1);
    TextDrawBackgroundColor(WebsiteTD, 51);
    TextDrawFont(WebsiteTD, 1);
    TextDrawSetProportional(WebsiteTD, 1);

    TDMInfo = TextDrawCreate(36.250000, 293.416809, "");
    TextDrawLetterSize(TDMInfo, 0.215624, 1.279165);
    TextDrawAlignment(TDMInfo, 1);
    TextDrawColor(TDMInfo, -1);
    TextDrawSetShadow(TDMInfo, 0);
    TextDrawSetOutline(TDMInfo, 1);
    TextDrawBackgroundColor(TDMInfo, 51);
    TextDrawFont(TDMInfo, 1);
    TextDrawSetProportional(TDMInfo, 1);

    DerbyInfo = TextDrawCreate(36.250000, 293.416809, "");
    TextDrawLetterSize(DerbyInfo, 0.215624, 1.279165);
    TextDrawAlignment(DerbyInfo, 1);
    TextDrawColor(DerbyInfo, -1);
    TextDrawSetShadow(DerbyInfo, 0);
    TextDrawSetOutline(DerbyInfo, 1);
    TextDrawBackgroundColor(DerbyInfo, 51);
    TextDrawFont(DerbyInfo, 1);
    TextDrawSetProportional(DerbyInfo, 1);
    return 1;
}

public OnGameModeExit()
{
    foreach(new i : ServerVehicles) 
    {
        if(!strcmp(vInfo[i][vehOwner], "-") || strcmp(vInfo[i][vehOwner], "-"))
        {
            SaveVehicle(i);
            DestroyVehicle(vInfo[i][vehSessionID]);
            DestroyDynamic3DTextLabel(vInfo[i][vehLabel]);
        }
    }
    foreach(new i : Player) SavePlayerData(i, 0, 0, 1);

    mysql_tquery(mysql, "UPDATE `playersdata` SET `Online` = 0");
    
    KillTimer(xReactionTimer);
    TextDrawDestroy(ServerTime);
    TextDrawDestroy(WebsiteTD);
    TextDrawDestroy(Textdraw0);
    TextDrawDestroy(Textdraw1);
    TextDrawDestroy(Textdraw2);
    TextDrawDestroy(Textdraw3);
    TextDrawDestroy(Textdraw4);
    TextDrawDestroy(Textdraw5);
    TextDrawDestroy(Textdraw6);
    TextDrawDestroy(Textdraw7);
    TextDrawDestroy(Textdraw8);
    TextDrawDestroy(Textdraw9);
    TextDrawDestroy(Textdraw10);
    TextDrawDestroy(Textdraw11);
    TextDrawDestroy(Textdraw12);
    TextDrawDestroy(Textdraw13);
    TextDrawDestroy(Textdraw14);
    TextDrawDestroy(Textdraw15);
    Streamer_DestroyAllItems(STREAMER_TYPE_PICKUP, 0);
    DestroyAllDynamicAreas();
    Iter_Clear(ServerVehicles);

    foreach(new i : Player) InSelfie[i] = 0;
    for(new i; i < sizeof(AmmuActorsID); i++)
    {
        DestroyActor(AmmuActorsID[i]);
    }
    for(new i; i < MAX_DROPS; i++) 
    {
        if(IsValidStaticPickup(i)) 
        {
            DestroyStaticPickup(i);
        }
    }
    for(new i = 0; i < MAX_OBJECTS; i ++)
    {
        if(objects[i] != -1)
        {
            if(Attached[i] == 0 || Attached[i] == 1)
            DestroyDynamicObject(objects[i]);
            else if(Attached[i] == 2)
            {
                foreach(new a : Player)
                {
                    if(!IsPlayerConnected(a)) continue;
                    RemovePlayerAttachedObject(a,objects[i]-99999);
                }
            }
            objects[i] = -1;
            Attached[i] = -1;
        }
    }
    for (new i, j = sizeof(g_Turf); i < j; i++) 
    {
        GangZoneDestroy(g_Turf[i][turfId]);

        if (g_Turf[i][turfTimer] != -1) 
        {
            KillTimer(g_Turf[i][turfTimer]);
        }
        g_Turf[i][turfTimer] = -1;
        g_Turf[i][turfState] = TURF_STATE_NORMAL;
    }
    foreach(new i : Property)
	{
	    if(pInfo[i][PropertySave]) pSave(i);
	}
	for(new i = 0; i < sizeof(PlantInfo); i++)
	{
	    CA_DestroyObject_DC(PlantInfo[i][ID]);
	    Delete3DTextLabel(PlantInfo[i][Label]);
	}
    foreach(new i : Houses) if(HouseData[i][HouseSave]) SaveHouse(i);
    return 1;
}

public OnPlayerConnect(playerid)
{
    new query[180], pip[16];
    GetPlayerIp(playerid, pip, sizeof(pip));

    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `BannedPlayers` WHERE `PlayerName` = '%e' OR `IP` = '%e'", GetName(playerid), pip);
    mysql_tquery(mysql, query, "OnBanCheck", "i", playerid);

    mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `Online` = 1 WHERE `PlayerName` = '%e'", GetName(playerid));
    mysql_tquery(mysql, query);

    OnAkaConnect(playerid);
    TogglePlayerSpectating(playerid, true);
    ResetPlayerWeaponsEx(playerid);
    ResetPlayerCash(playerid);
    SetPlayerColor(playerid, COLOR_NULL);
    House_PlayerInit(playerid);
    Iter_Clear(PrivateVehicles[playerid]);
    gettime(serverhour,serverminute);
    SetPlayerTime(playerid, serverhour, serverminute);

    Info[playerid][AutoLogin] = 0;
    Info[playerid][Level] = 0;
    Info[playerid][Kills] = 0;
    Info[playerid][Deaths] = 0;
    Info[playerid][Suicides] = 0;
    Info[playerid][Hours] = 0;
    Info[playerid][Minutes] = 0;
    Info[playerid][Seconds] = 0;
    Info[playerid][UGC] = 0;
    Info[playerid][Marijuana] = 0;
    Info[playerid][Seeds] = 0;
    Info[playerid][Cocaine] = 0;
    Info[playerid][Premium] = 0;
    Info[playerid][PremiumExpires] = 0;
    Info[playerid][NameChange] = 0;
    Info[playerid][FightStyle] = 0;
    Info[playerid][xLevel] = 0;
    Info[playerid][XP] = 0;
    Info[playerid][WantedLevel] = 0;
    Info[playerid][Muted] = 0;
    Info[playerid][Jailed] = 0;
    Info[playerid][Hitman] = 0;
    Info[playerid][Jetpack] = 0;
    Info[playerid][JetpackExpire] = 0;
    Info[playerid][Jump] = 0;
    Info[playerid][JumpExpire] = 0;
    Info[playerid][Logged] = 0;
    Info[playerid][Registered] = 0;
    Info[playerid][Duty] = 0;
    Info[playerid][Frozen] = 0;
    Info[playerid][VGod] = 0;
    Info[playerid][DMZone] = 0;
    Info[playerid][Spec] = 0;
    Info[playerid][NameTagHidden] = 0;
    Info[playerid][ReadPM] = false;
    Info[playerid][ReadCMD] = false;
    Info[playerid][MoneyBags] = 0;
    Info[playerid][Move] = 0;
    Info[playerid][WeaponTeleport] = 0;
    Info[playerid][Friends] = 0;
    Info[playerid][vehLimit] = 0;

    pLastMsg[playerid] = !"fghsfhdf";
    pProtectTick[playerid] = 0;
    AbuseTick[playerid] = 0;
    IsPaused[playerid] = 0;
    pTick[playerid] = 0;
    StartTimer[playerid] = 0;
    playerCar[playerid] = INVALID_VEHICLE_ID;
    SpecID[playerid] = INVALID_PLAYER_ID;
    JumpStatus[playerid] = 0;
    AntiHealth[playerid] = false;
    AntiArmour[playerid] = false;
    pTickWarnings[playerid] = 0;
    HackWarnings[playerid] = 0;
    MuteCounter[playerid] = 0;
    HideTexts[playerid] = 0;
    InAmmu[playerid] = 0;
    gPlayer_AmmuCoolDown[playerid] = 0;
    gPlayer_Ammunation{playerid} = 255;
    Info[playerid][NameTagHidden] = 0;
    Info[playerid][MapHide] = 0;
    CountDeaths[playerid] = 0;
    StartDeathTick[playerid] = 0;
    InSelfie[playerid] = 0;
    GotJetpack[playerid] = 0;
    TextColor[playerid] = 0;
    attempts[playerid] = 0;
    LastPm[playerid] = -1;
    PMEnabled[playerid] = 0;
    KillStreak[playerid] = 0;
    Info[playerid][InDM] = 0;
    InEvent[playerid] = 0;
    InDerby[playerid] = 0;
    InTDM[playerid] = 0;
    InParkour[playerid] = 0; 
    InSkydive[playerid] = 0;
    Invited[playerid] = 0; //not invited
    Weapon1[playerid] = -1; //setting weapon1 to invalid
    Weapon2[playerid] = -1; //setting weapon2 to invalid
    Opponent[playerid] = -1; //setting Opponent to invalid
    Bet[playerid] = -1; // setting bet to -1
    InDuel[playerid] = 0; // not in any duel
    for(new i, j = MAX_ATTACHMENTS; i < j; i++) oInfo[playerid][i][used1] = false;

    pTimer[playerid] = SetTimerEx("PropertyTimer", PROPERTY_REVENUE * 60000, true, "i", playerid);
    CountTimer[playerid] = SetTimerEx("PlayerTimer", 1000, 1, "i", playerid);
    OnPlayerAntiCheat[playerid] = SetTimerEx("AntiHacks", 3000, true, "i", playerid);

    ptInfoBox[playerid] = CreatePlayerTextDraw(playerid, 38.600063, 145.722549, "");
    PlayerTextDrawLetterSize(playerid, ptInfoBox[playerid], 0.567299, 2.686157);
    PlayerTextDrawTextSize(playerid, ptInfoBox[playerid], 251.500274, 163.910614);
    PlayerTextDrawAlignment(playerid, ptInfoBox[playerid], 1);
    PlayerTextDrawColor(playerid, ptInfoBox[playerid], -2139062017);
    PlayerTextDrawUseBox(playerid, ptInfoBox[playerid], true);
    PlayerTextDrawBoxColor(playerid, ptInfoBox[playerid], 136);
    PlayerTextDrawSetShadow(playerid, ptInfoBox[playerid], 0);
    PlayerTextDrawSetOutline(playerid, ptInfoBox[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, ptInfoBox[playerid], 51);
    PlayerTextDrawFont(playerid, ptInfoBox[playerid], 1);
    PlayerTextDrawSetProportional(playerid, ptInfoBox[playerid], 1);

    TimeLeft[playerid] = CreatePlayerTextDraw(playerid, 483.200042, 253.119995, "");
    PlayerTextDrawLetterSize(playerid, TimeLeft[playerid], 0.625998, 2.122663);
    PlayerTextDrawAlignment(playerid, TimeLeft[playerid], 1);
    PlayerTextDrawColor(playerid, TimeLeft[playerid], -1);
    PlayerTextDrawSetShadow(playerid, TimeLeft[playerid], 0);
    PlayerTextDrawSetOutline(playerid, TimeLeft[playerid], 2);
    PlayerTextDrawBackgroundColor(playerid, TimeLeft[playerid], 51);
    PlayerTextDrawFont(playerid, TimeLeft[playerid], 1);
    PlayerTextDrawSetProportional(playerid, TimeLeft[playerid], 1);

    BPayout[playerid] = CreatePlayerTextDraw(playerid, 40.500000, 225.244445, "Payout");
    PlayerTextDrawLetterSize(playerid, BPayout[playerid], 0.228500, 1.375999);
    PlayerTextDrawAlignment(playerid, BPayout[playerid], 1);
    PlayerTextDrawColor(playerid, BPayout[playerid], 0xFF0000FF);
    PlayerTextDrawSetShadow(playerid, BPayout[playerid], 0);
    PlayerTextDrawSetOutline(playerid, BPayout[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, BPayout[playerid], 51);
    PlayerTextDrawFont(playerid, BPayout[playerid], 1);
    PlayerTextDrawSetProportional(playerid, BPayout[playerid], 1);

    JailTime[playerid] = CreatePlayerTextDraw(playerid, 465.900207, 303.613281, "");
    PlayerTextDrawLetterSize(playerid, JailTime[playerid], 0.552499, 2.509999);
    PlayerTextDrawAlignment(playerid, JailTime[playerid], 1);
    PlayerTextDrawColor(playerid, JailTime[playerid], -1);
    PlayerTextDrawSetShadow(playerid, JailTime[playerid], 0);
    PlayerTextDrawSetOutline(playerid, JailTime[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, JailTime[playerid], 51);
    PlayerTextDrawFont(playerid, JailTime[playerid], 1);
    PlayerTextDrawSetProportional(playerid, JailTime[playerid], 1);

    SpectateTextDraw[playerid] = CreatePlayerTextDraw(playerid, 20.614887, 134.750000, "Name:");
    PlayerTextDrawLetterSize(playerid, SpectateTextDraw[playerid], 0.252752, 1.185832);
    PlayerTextDrawAlignment(playerid, SpectateTextDraw[playerid], 1);
    PlayerTextDrawColor(playerid, SpectateTextDraw[playerid], -1);
    PlayerTextDrawSetShadow(playerid, SpectateTextDraw[playerid], 0);
    PlayerTextDrawSetOutline(playerid, SpectateTextDraw[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, SpectateTextDraw[playerid], 51);
    PlayerTextDrawFont(playerid, SpectateTextDraw[playerid], 1);
    PlayerTextDrawSetProportional(playerid, SpectateTextDraw[playerid], 1);

    Notif[playerid] = CreatePlayerTextDraw(playerid, 224.000137, 367.359863, "You have left the deathmatch");
    PlayerTextDrawLetterSize(playerid, Notif[playerid], 0.449999, 1.600000);
    PlayerTextDrawAlignment(playerid, Notif[playerid], 1);
    PlayerTextDrawColor(playerid, Notif[playerid], -16776961);
    PlayerTextDrawSetShadow(playerid, Notif[playerid], 2);
    PlayerTextDrawSetOutline(playerid, Notif[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, Notif[playerid], 51);
    PlayerTextDrawFont(playerid, Notif[playerid], 1);
    PlayerTextDrawSetProportional(playerid, Notif[playerid], 1);

    CountDownAttack[playerid] = CreatePlayerTextDraw(playerid,510.000000, 420.000000, "");
    PlayerTextDrawBackgroundColor(playerid,CountDownAttack[playerid], 255);
    PlayerTextDrawFont(playerid,CountDownAttack[playerid], 1);
    PlayerTextDrawLetterSize(playerid,CountDownAttack[playerid], 0.260000, 1.000000);
    PlayerTextDrawColor(playerid,CountDownAttack[playerid], -1);
    PlayerTextDrawSetOutline(playerid,CountDownAttack[playerid], 0);
    PlayerTextDrawSetProportional(playerid,CountDownAttack[playerid], 1);
    PlayerTextDrawSetShadow(playerid,CountDownAttack[playerid], 1);
    PlayerTextDrawSetSelectable(playerid,CountDownAttack[playerid], 0);

    Background = CreatePlayerTextDraw(playerid,0.000000, 0.000000, "BACKGROUND --- TOP");
    PlayerTextDrawBackgroundColor(playerid,Background, 255);
    PlayerTextDrawFont(playerid,Background, 1);
    PlayerTextDrawLetterSize(playerid,Background, 0.500000, 14.000000);
    PlayerTextDrawColor(playerid,Background, 255);
    PlayerTextDrawSetOutline(playerid,Background, 0);
    PlayerTextDrawSetProportional(playerid,Background, 1);
    PlayerTextDrawSetShadow(playerid,Background, 1);
    PlayerTextDrawUseBox(playerid,Background, 1);
    PlayerTextDrawBoxColor(playerid,Background, 255);
    PlayerTextDrawTextSize(playerid,Background, 650.000000, 30.000000);
    PlayerTextDrawSetSelectable(playerid,Background, 0);
 
    Middle = CreatePlayerTextDraw(playerid,-197.000000, 113.000000, "BACKGROUND --- Middle");
    PlayerTextDrawBackgroundColor(playerid,Middle, 255);
    PlayerTextDrawFont(playerid,Middle, 3);
    PlayerTextDrawLetterSize(playerid,Middle, 0.500000, 1.000000);
    PlayerTextDrawColor(playerid,Middle, 16777215);
    PlayerTextDrawSetOutline(playerid,Middle, 0);
    PlayerTextDrawSetProportional(playerid,Middle, 1);
    PlayerTextDrawSetShadow(playerid,Middle, 1);
    PlayerTextDrawUseBox(playerid,Middle, 1);
    PlayerTextDrawBoxColor(playerid,Middle, 16777215);
    PlayerTextDrawTextSize(playerid,Middle, 660.000000, 0.000000);
    PlayerTextDrawSetSelectable(playerid,Middle, 0);
 
    ServerName = CreatePlayerTextDraw(playerid,310.000000, 20.000000, "Explosive Freeroam");
    PlayerTextDrawAlignment(playerid,ServerName, 2);
    PlayerTextDrawBackgroundColor(playerid,ServerName, 255);
    PlayerTextDrawFont(playerid,ServerName, 1);
    PlayerTextDrawLetterSize(playerid,ServerName, 0.910000, 5.099999);
    PlayerTextDrawColor(playerid,ServerName, 881831423);
    PlayerTextDrawSetOutline(playerid,ServerName, 0);
    PlayerTextDrawSetProportional(playerid,ServerName, 1);
    PlayerTextDrawSetShadow(playerid,ServerName, 1);
    PlayerTextDrawSetSelectable(playerid,ServerName, 0);
 
    ServerTitle = CreatePlayerTextDraw(playerid,310.000000, 66.000000, "Freeroam/GangWars");
    PlayerTextDrawAlignment(playerid,ServerTitle, 2);
    PlayerTextDrawBackgroundColor(playerid,ServerTitle, 255);
    PlayerTextDrawFont(playerid,ServerTitle, 1);
    PlayerTextDrawLetterSize(playerid,ServerTitle, 0.610000, 3.099999);
    PlayerTextDrawColor(playerid,ServerTitle, -1);
    PlayerTextDrawSetOutline(playerid,ServerTitle, 0);
    PlayerTextDrawSetProportional(playerid,ServerTitle, 1);
    PlayerTextDrawSetShadow(playerid,ServerTitle, 1);
    PlayerTextDrawSetSelectable(playerid,ServerTitle, 0);
 
    Bottom = CreatePlayerTextDraw(playerid,0.000000, 324.000000, "BACKGROUND --- BOTTOM");
    PlayerTextDrawBackgroundColor(playerid,Bottom, 255);
    PlayerTextDrawFont(playerid,Bottom, 1);
    PlayerTextDrawLetterSize(playerid,Bottom, 0.500000, 14.000000);
    PlayerTextDrawColor(playerid,Bottom, 255);
    PlayerTextDrawSetOutline(playerid,Bottom, 0);
    PlayerTextDrawSetProportional(playerid,Bottom, 1);
    PlayerTextDrawSetShadow(playerid,Bottom, 1);
    PlayerTextDrawUseBox(playerid,Bottom, 1);
    PlayerTextDrawBoxColor(playerid,Bottom, 255);
    PlayerTextDrawTextSize(playerid,Bottom, 650.000000, 30.000000);
    PlayerTextDrawSetSelectable(playerid,Bottom, 0);
 
    Middle2 = CreatePlayerTextDraw(playerid,-197.000000, 329.000000, "BACKGROUND --- Middle");
    PlayerTextDrawBackgroundColor(playerid,Middle2, 255);
    PlayerTextDrawFont(playerid,Middle2, 3);
    PlayerTextDrawLetterSize(playerid,Middle2, 0.500000, 1.000000);
    PlayerTextDrawColor(playerid,Middle2, 16777215);
    PlayerTextDrawSetOutline(playerid,Middle2, 0);
    PlayerTextDrawSetProportional(playerid,Middle2, 1);
    PlayerTextDrawSetShadow(playerid,Middle2, 1);
    PlayerTextDrawUseBox(playerid,Middle2, 1);
    PlayerTextDrawBoxColor(playerid,Middle2, 16777215);
    PlayerTextDrawTextSize(playerid,Middle2, 660.000000, 0.000000);
    PlayerTextDrawSetSelectable(playerid,Middle2, 0);

    VehicleSpeedo = CreatePlayerTextDraw(playerid,510.000000, 406.000000, "~g~KM/H: ~w~120   ~r~Health");
    PlayerTextDrawBackgroundColor(playerid,VehicleSpeedo, 255);
    PlayerTextDrawFont(playerid,VehicleSpeedo, 1);
    PlayerTextDrawLetterSize(playerid,VehicleSpeedo, 0.260000, 1.000000);
    PlayerTextDrawColor(playerid,VehicleSpeedo, -1);
    PlayerTextDrawSetOutline(playerid,VehicleSpeedo, 0);
    PlayerTextDrawSetProportional(playerid,VehicleSpeedo, 1);
    PlayerTextDrawSetShadow(playerid,VehicleSpeedo, 1);
    PlayerTextDrawSetSelectable(playerid,VehicleSpeedo, 0);

    PlayAudioStreamForPlayer(playerid, "http://www.youtubeinmp3.com/fetch/?video=https://www.youtube.com/watch?v=nPW5nfoIYf8");

    RemoveBuildingForPlayer(playerid, 10763, -1255.8984, 47.1797, 45.9063, 0.25);
    RemoveBuildingForPlayer(playerid, 10884, -1255.8984, 47.1797, 45.9063, 0.25);

    PlayerTextDrawShow(playerid, Background);
    PlayerTextDrawShow(playerid, Middle);
    PlayerTextDrawShow(playerid, ServerName);
    PlayerTextDrawShow(playerid, ServerTitle);
    PlayerTextDrawShow(playerid, Bottom);
    PlayerTextDrawShow(playerid, Middle2);

    SetPVarInt(playerid, "SelectedObject",-1);
    SetPVarString(playerid, "SettingTxt", "Click_to_set");
    SetPVarString(playerid, "SettingTxd", "Click_to_set");
    SetPVarInt(playerid, "SettingIdx", 0);
    SetPVarInt(playerid, "SettingModel", 11111);
    ObjTextdraw[playerid] = PlayerText:INVALID_TEXT_DRAW;
    for(new i = 0; i < sizeof(objinfo[]); i ++) objinfo[playerid][i] = PlayerText:INVALID_TEXT_DRAW;

    if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        SetPlayerCameraPos(playerid, 1871.7205, -1165.4304, 46.8275);
        SetPlayerCameraLookAt(playerid, 1920.8401, -1179.3284, 28.9088);
    }

    for (new i; i < sizeof(AnimationLibraries); i++) {

        ApplyAnimation(playerid, AnimationLibraries[i], "null", 0.0, 0, 0, 0, 0, 0);
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new string[128];
	if(Info[playerid][Logged] == 1)
	{
        SavePlayerData(playerid, 0, 0);
    }

    foreach(new i : PrivateVehicles[playerid])
    {
        if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
        {
            SaveVehicle(i);
            DestroyVehicle(vInfo[i][vehSessionID]);
            Iter_Remove(ServerVehicles, i);
        }
    }

    if(IsBanned[playerid] == 0)
    {
        new szDisconnectReason[3][] =
        {
            "[Timeout]",
            "",
            "[Kicked]"
        };
     
        format(string, sizeof string, "%s has left the server %s", GetName(playerid), szDisconnectReason[reason]);
        SendClientMessageToAll(0x999999FF, string);
    }

    foreach (new i : Player)
    {
        if(Info[i][Spec] == 1)
        {
            if(SpecID[i] == playerid && SpecID[i] != INVALID_PLAYER_ID)
            {
                cmd_specoff(i, "");
            }
        }
    }

    mysql_format(mysql, string, sizeof(string), "UPDATE `playersdata` SET `Online` = 0 WHERE `PlayerName` = '%e'", GetName(playerid));
    mysql_tquery(mysql, string);

    ResetPlayerWeaponsEx(playerid);
    TextDrawHideForPlayer(playerid, ServerTime);
    TextDrawHideForPlayer(playerid, WebsiteTD);
    PlayerTextDrawDestroy(playerid, VehicleSpeedo);
    PlayerTextDrawDestroy(playerid, CountDownAttack[playerid]);
    DestroyDynamic3DTextLabel(PlayerTag[playerid]);
    DestroyDynamic3DTextLabel(PlayerTitle[playerid]);
    DestroyVehicle(playerCar[playerid]);
    KillTimer(OnPlayerAntiCheat[playerid]);
    KillTimer(LeaveVehTimer[playerid]);
    KillTimer(pTimer[playerid]);
    KillTimer(VehicleTimer[playerid]);
    KillTimer(CountTimer[playerid]);
    KillTimer(MuteTimer[playerid]);
    KillTimer(SpecTimer[playerid]);
    KillTimer(pauseTimer[playerid]);

    Info[playerid][AutoLogin] = 0;
    Info[playerid][Level] = 0;
    Info[playerid][Kills] = 0;
    Info[playerid][Deaths] = 0;
    Info[playerid][Suicides] = 0;
    Info[playerid][Hours] = 0;
    Info[playerid][Minutes] = 0;
    Info[playerid][Seconds] = 0;
    Info[playerid][UGC] = 0;
    Info[playerid][Marijuana] = 0;
    Info[playerid][Seeds] = 0;
    Info[playerid][Cocaine] = 0;
    Info[playerid][Premium] = 0;
    Info[playerid][PremiumExpires] = 0;
    Info[playerid][NameChange] = 0;
    Info[playerid][FightStyle] = 0;
    Info[playerid][xLevel] = 0;
    Info[playerid][XP] = 0;
    Info[playerid][WantedLevel] = 0;
    Info[playerid][Muted] = 0;
    Info[playerid][Jailed] = 0;
    Info[playerid][Hitman] = 0;
    Info[playerid][Jetpack] = 0;
    Info[playerid][JetpackExpire] = 0;
    Info[playerid][Jump] = 0;
    Info[playerid][JumpExpire] = 0;
    Info[playerid][Logged] = 0;
    Info[playerid][Registered] = 0;
    Info[playerid][Duty] = 0;
    Info[playerid][Frozen] = 0;
    Info[playerid][VGod] = 0;
    Info[playerid][DMZone] = 0;
    Info[playerid][Spec] = 0;
    Info[playerid][NameTagHidden] = 0;
    Info[playerid][ReadPM] = false;
    Info[playerid][ReadCMD] = false;
    Info[playerid][MoneyBags] = 0;
    Info[playerid][Move] = 0;
    Info[playerid][WeaponTeleport] = 0;
    Info[playerid][Friends] = 0;
    Info[playerid][vehLimit] = 0;

    pProtectTick[playerid] = 0;
    AbuseTick[playerid] = 0;
    IsPaused[playerid] = 0;
    pTick[playerid] = 0;
    StartTimer[playerid] = 0;
    IsBanned[playerid] = 0;
    SpecID[playerid] = INVALID_PLAYER_ID;
    JumpStatus[playerid] = 0;
    AntiHealth[playerid] = false;
    AntiArmour[playerid] = false;
    pTickWarnings[playerid] = 0;
    HackWarnings[playerid] = 0;
    HideTexts[playerid] = 0;
    InAmmu[playerid] = 0;
    gPlayer_AmmuCoolDown[playerid] = 0;
    gPlayer_Ammunation{playerid} = 255;
    Info[playerid][NameTagHidden] = 0;
    Info[playerid][MapHide] = 0;
    CountDeaths[playerid] = 0;
    StartDeathTick[playerid] = 0;
    InSelfie[playerid] = 0;
    GotJetpack[playerid] = 0;
    TextColor[playerid] = 0;
    attempts[playerid] = 0;
    LastPm[playerid] = -1;
    PMEnabled[playerid] = 0;
    KillStreak[playerid] = 0;
    Info[playerid][InDM] = 0;
    InParkour[playerid] = 0; 
    InSkydive[playerid] = 0;
    for(new i; i < 10; i++) Cooldown[playerid][i] = 0;
    for(new i; i < 2; i++) JobCoolDown[playerid][i] = 0;

    if(pTeam[playerid] != NO_TEAM)
    {
        gTeamCount[pTeam[playerid]] --;
        UpdateTeamLabel(pTeam[playerid]);
    }

   	if(InDuel[playerid] == 1)
 	{
	  	new id = Opponent[playerid];
	  	new w1 = Weapon1[playerid];
	  	new w2 = Weapon2[playerid];
	  	new c = Bet[playerid];

	  	new wname1[34], wname2[34];
	  	GetWeaponName(w1, wname1, 34);
	  	GetWeaponName(w2, wname2, 34);
	  	SetPlayerVirtualWorld(id, 0);
	  	ResetPlayerWeaponsEx(id);
        SpawnPlayerEx(id);
	  	GivePlayerCash(id, c);
	  	GivePlayerCash(playerid, -c);

	  	format(string, 124, "[DUEL] %s (%d) have won the duel against %s (%d) and won $%s", GetName(id), id, GetName(playerid), playerid, cNumber(c));
	  	SendClientMessageToAll(0x00CDFFFF, string);

	  	InDuel[id] = 0;
	  	Weapon1[id] = 0;
	  	Weapon2[id] = 0;
	  	Bet[id] = 0;
	  	Opponent[id] = -1;

        InDuel[playerid] = 0;
        Weapon1[playerid] = 0;
        Weapon2[playerid] = 0;
        Bet[playerid] = 0;
        Opponent[playerid] = -1;
  	}
    if(InEvent[playerid] == 1 && eInfo[EventStarted] == true)
    {
        InEvent[playerid] = 0;
        switch(eInfo[Type])
        {
            case EVENT_TDM:
            {
                if(GetPlayerTeam(playerid) == TEAM_ONE)
                {
                    ePlayerTeamOne--;
                    if(ePlayerTeamOne == 0)
                    {
                        foreach(new i : Player)
                        {
                            if(InEvent[i] == 1 && GetPlayerTeam(i) == TEAM_TWO && GetPlayerState(i) != PLAYER_STATE_WASTED)
                            {
                                format(string, sizeof(string), "%s has won the event", GetName(i));
                                SendClientMessageToAll(0x00FFFFFF, string);

                                Info[i][XP] += 100;
                                GivePlayerCash(i, eInfo[Prize]);

                                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                                WinnerText(i, string);

                                InEvent[i] = 0;

                                ResetPlayerWeaponsEx(i);
                                SpawnPlayerEx(i);
                                SetPlayerHealthEx(i, 100);
                                SetPlayerArmourEx(i, 100);
                            }
                        }

                        ePlayers = 0;
                        ePlayerTeamTwo = 0;
                        ePlayerTeamOne = 0;
                        eInfo[Type] = EVENT_NONE;
                        eInfo[EventStarted] = false;
                    }
                }
                if(GetPlayerTeam(playerid) == TEAM_TWO)
                {
                    ePlayerTeamTwo--;
                    if(ePlayerTeamTwo == 0)
                    {
                        foreach(new i : Player)
                        {
                            if(InEvent[i] == 1 && GetPlayerTeam(i) == TEAM_ONE && GetPlayerState(i) != PLAYER_STATE_WASTED)
                            {
                                format(string, sizeof(string), "%s has won the event", GetName(i));
                                SendClientMessageToAll(0x00FFFFFF, string);

                                Info[i][XP] += 100;
                                GivePlayerCash(i, eInfo[Prize]);

                                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                                WinnerText(i, string);

                                InEvent[i] = 0;

                                ResetPlayerWeaponsEx(i);
                                SpawnPlayerEx(i);
                                SetPlayerHealthEx(i, 100);
                                SetPlayerArmourEx(i, 100);
                            }
                        }

                        ePlayers = 0;
                        ePlayerTeamTwo = 0;
                        ePlayerTeamOne = 0;
                        eInfo[Type] = EVENT_NONE;
                        eInfo[EventStarted] = false;
                    }
                }
            }
            case EVENT_DM:
            {
                ePlayers--;
                if(ePlayers == 1)
                {
                    foreach(new i : Player)
                    {
                        if(InEvent[i] == 1 && GetPlayerState(i) != PLAYER_STATE_WASTED)
                        {
                            format(string, sizeof(string), "%s has won the event", GetName(i));
                            SendClientMessageToAll(0x00FFFFFF, string);

                            Info[i][XP] += 100;
                            GivePlayerCash(i, eInfo[Prize]);

                            format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                            WinnerText(i, string);

                            InEvent[i] = 0;
                        
                            ResetPlayerWeaponsEx(i);
                            SpawnPlayerEx(i);
                            SetPlayerHealthEx(i, 100);
                            SetPlayerArmourEx(i, 100);
                        }
                    }

                    ePlayers = 0;
                    ePlayerTeamTwo = 0;
                    ePlayerTeamOne = 0;
                    eInfo[Type] = EVENT_NONE;
                    eInfo[EventStarted] = false;
                }
            }
        }
    }
    if(InDerby[playerid] == 1) 
    {
        PlayersInDerby -= 1;
        InDerby[playerid] = 0;
        DestroyVehicle(GetPlayerVehicleID(playerid));
    }
    if(InTDM[playerid] == 1)
    {
        PlayersInTDM -= 1;
        InTDM[playerid] = 0;
        if(GetPlayerTeam(playerid) == TDMTeamOne) PlayerTeamOne -= 1;
        if(GetPlayerTeam(playerid) == TDMTeamTwo) PlayerTeamTwo -= 1;
    }
    if(PlayerTeamOne == 0)
    {
        foreach(new i : Player)
        {
            if(InTDM[i] == 1 && GetPlayerTeam(i) == TDMTeamTwo)
            {
                InTDM[i] = 0;
                format(string, sizeof(string), "%s has won the TDM", GetName(i));
                SendClientMessageToAll(0x00FFFFFF, string);
                Info[i][XP] += 100;
                GivePlayerCash(i, randomEx(10000,30000));
                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                WinnerText(i, string);
                ResetPlayerWeaponsEx(i);
                SpawnPlayerEx(i);
                SetPlayerHealthEx(i, 100);
                SetPlayerArmourEx(i, 100);
                TextDrawHideForPlayer(i, TDMInfo);
            }
            if(InTDM[i] == 1)
            {
                InTDM[i] = 0;
                TextDrawHideForPlayer(i, TDMInfo);
                ResetPlayerWeaponsEx(i);
                SpawnPlayerEx(i);
                SetPlayerHealthEx(i, 100);
                SetPlayerArmourEx(i, 100);
            }
        }
        KillTimer(TDTimer);
        TDMGame = NON_TDM;
        TDMStarted = false;
        PlayersInTDM = 0;
        PlayerTeamOne = 0;
        PlayerTeamTwo = 0;
    }
    if(PlayerTeamTwo == 0)
    {
        foreach(new i : Player)
        {
            if(InTDM[i] == 1 && GetPlayerTeam(i) == TDMTeamOne)
            {
                InTDM[i] = 0;
                format(string, sizeof(string), "%s has won the TDM", GetName(i));
                SendClientMessageToAll(0x00FFFFFF, string);
                Info[i][XP] += 100;
                GivePlayerCash(i, randomEx(10000,30000));
                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                WinnerText(i, string);
                SpawnPlayerEx(i);
                TextDrawHideForPlayer(i, TDMInfo);
            }
            if(InTDM[i] == 1)
            {
                InTDM[i] = 0;
                SpawnPlayerEx(i);
                TextDrawHideForPlayer(i, TDMInfo);
            }
        }
        KillTimer(TDTimer);
        TDMGame = NON_TDM;
        TDMStarted = false;
        PlayersInTDM = 0;
        PlayerTeamOne = 0;
        PlayerTeamTwo = 0;
    }
    if(PlayersInDerby == 1)
    {
        foreach(new i : Player)
        {
            for(new x; x < DerbyVehicles[i]; x++)
            {
                DestroyVehicle(DerbyVehicles[i]);
            }

            if(InDerby[i] == 1)
            {
                InDerby[i] = 0;
                format(string, sizeof(string), "%s has won the derby", GetName(i));
                SendClientMessageToAll(0x00FFFFFF, string);
                Info[i][XP] += 100;
                GivePlayerCash(i, randomEx(10000,30000));
                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                WinnerText(i, string);
                SpawnPlayerEx(i);
                TextDrawHideForPlayer(i, DerbyInfo);
            }
        }
        KillTimer(DerbyTDTimer);
        DerbyGame = NON_DERBY;
        DerbyStarted = false;
        PlayersInDerby = 0;
    }
    if(Info[playerid][SpawnedCars] > 0)
    {
       for(new i = 0; i < Info[playerid][SpawnedCars]; i++)
       {
           DestroyVehicle(Info[playerid][Cars][i]);
       }
       Info[playerid][SpawnedCars] = 0;
    }
    if(pTeam[playerid] != NO_TEAM) 
    {
        for(new i, j = sizeof(g_Turf); i < j; i++) 
        {
            if(IsPlayerInGangZone(playerid, i)) 
            {
                if(g_Turf[i][turfState] == TURF_STATE_NORMAL && pTeam[playerid] != g_Turf[i][turfOwner]) 
                {
                    g_MembersInTurf[i][pTeam[playerid]]--;
                }

                if(pTeam[playerid] != g_Turf[i][turfOwner] && pTeam[playerid] == g_Turf[i][turfAttacker]) 
                {
                    g_MembersInTurf[i][pTeam[playerid]]--;
                    
                    if(g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                    {
                        PlayerTextDrawHide(playerid, CountDownAttack[playerid]);

                        if(g_MembersInTurf[i][pTeam[playerid]] < TURF_REQUIRED_PLAYERS) 
                        {
                            KillTimer(g_Turf[i][turfTimer]);
                            KillTimer(g_Turf[i][turfAttackTimer]);

                            g_Turf[i][turfCountDown] = 0;
                            g_Turf[i][turfTimer] = -1;
                            g_Turf[i][turfState] = TURF_STATE_NORMAL;
                            g_Turf[i][turfAttacker] = NO_TEAM;

                            foreach(new x : Player)
                            {
                                if(pTeam[x] != NO_TEAM)
                                {
                                    GangZoneStopFlashForPlayer(x, g_Turf[i][turfId]);
                                    GangZoneShowForPlayer(x, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));
                                }

                                if(IsPlayerInGangZone(x, i)) 
                                {
                                    PlayerTextDrawHide(x, CountDownAttack[playerid]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 1;
}

public OnPlayerUpdate(playerid)
{
    switch(DerbyGame)
    {
        case RANCHERS_DERBY: FallingChecker(playerid, 355);
        case BULLETS_DERBY: FallingChecker(playerid, 9);
        case HOTRINGS_DERBY: FallingChecker(playerid, 449);
        case INFERNUS_DERBY: FallingChecker(playerid, 810);
    }

    pTick[playerid] = GetTickCount();

    new Float:Health;
    GetPlayerHealth(playerid, Health);
    if(Health > 100.0) SetPlayerHealthEx(playerid, 100.0);
    if(GetPlayerCash(playerid) < 0) SetPlayerCash(playerid, 0);
    SetPlayerScore(playerid, Info[playerid][Kills]);
    if(Info[playerid][UGC] < 0) Info[playerid][UGC] = 0;
    if(Info[playerid][Move] == 1) GetPlayerHoldingKey(playerid);
    return 1;
}

stock GetPlayerHoldingKey(playerid)
{
    if(Info[playerid][Move] == 1)
    {
        new Float:MX, Float:MY, Float:MZ, Float:MA, MKeys, Mupdown, Mleftright;
        GetPlayerKeys(playerid, MKeys, Mupdown, Mleftright);
        GetPlayerPos(playerid,MX,MY,MZ);
        GetPlayerFacingAngle(playerid, MA);
        if(MKeys == KEY_SPRINT)
        {
            SetPlayerPos(playerid,MX,MY,MZ-3);
            if(IsPlayerInAnyVehicle(playerid)) 
            {
                GetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ);
                SetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ-3);
                PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
            }
        }
        if(MKeys == KEY_JUMP)
        {
            SetPlayerPos(playerid,MX,MY,MZ+3);
            if(IsPlayerInAnyVehicle(playerid)) 
            {
                GetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ);
                SetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ+3);
                PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
            }
        }
        if(Mupdown == KEY_UP)
        {
            GetPlayerPos(playerid,MX,MY,MZ);
            MX += (5 * floatsin(-MA, degrees));
            MY += (5 * floatcos(-MA, degrees));
            SetPlayerPos(playerid,MX,MY,MZ);

            if(IsPlayerInAnyVehicle(playerid)) 
            {
                GetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ);
                MX += (5 * floatsin(-MA, degrees));
                MY += (5 * floatcos(-MA, degrees));
                SetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ);
                PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
            }
        }
        if(Mupdown == KEY_DOWN)
        {
            GetPlayerPos(playerid,MX,MY,MZ);
            MX -= (5 * floatsin(-MA, degrees));
            MY -= (5 * floatcos(-MA, degrees));
            SetPlayerPos(playerid,MX,MY,MZ);

            if(IsPlayerInAnyVehicle(playerid)) 
            {
                GetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ);
                MX -= (5 * floatsin(-MA, degrees));
                MY -= (5 * floatcos(-MA, degrees));
                SetVehiclePos(GetPlayerVehicleID(playerid), MX,MY,MZ);
                PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
            }
        }
        if(Mleftright == KEY_RIGHT)
        {
            SetPlayerFacingAngle(playerid, MA - 5);
            SetCameraBehindPlayer(playerid);

            if(IsPlayerInAnyVehicle(playerid)) 
            {
                SetVehicleZAngle(GetPlayerVehicleID(playerid), MA - 5);
            }
        }
        if(Mleftright == KEY_LEFT)
        {
            SetPlayerFacingAngle(playerid, MA + 5);
            SetCameraBehindPlayer(playerid);

            if(IsPlayerInAnyVehicle(playerid)) 
            {
                SetVehicleZAngle(GetPlayerVehicleID(playerid), MA + 5);
            }
        }   
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    new Float:X, Float:Y, Float:Z, string[128];
    new Float:distance = 99999.0,
        Float:tmp_distance, closest = -1;

    GetPlayerPos(playerid, X, Y, Z);
    SetPlayerWantedLevel(playerid, 0);
    GivePlayerCash(playerid, -1000);
    SendDeathMessage(killerid, playerid, reason);
    PlayerTextDrawHide(playerid, VehicleSpeedo);
    OldSkin[playerid] = GetPlayerSkin(playerid);
    pProtectTick[playerid] = 0;

    new Float:hp;
    GetPlayerHealth(playerid, hp);
    if(hp < 1.0) return SetPlayerHealth(playerid, -1.0);

    if(gettime() - StartDeathTick[playerid] < 5) //5 seconds
    {
        CountDeaths[playerid] ++;
        if(CountDeaths[playerid] == 7) 
        {
            format(string, sizeof(string), "%s has been kicked for fake kill", GetName(playerid));
            SendClientMessageToAll(red, string);
            DelayKick(playerid);
            return CountDeaths[playerid] = 0;  
        }
    }
    else CountDeaths[playerid] = 1;
    StartDeathTick[playerid] = gettime();

    if(Info[playerid][MapHide] == 1) {

        foreach(new i : Player) SetPlayerMarkerForPlayer(i, playerid, (GetPlayerColor(playerid) & 0xFFFFFF00));
    }

    if(killerid != INVALID_PLAYER_ID)
    {
        GameTextForPlayer(killerid, "~g~+$1,000", 3000, 1);
        GivePlayerCash(killerid, 1000);

        KillStreak[killerid]++;
        Info[killerid][Kills]++;
        if(!(KillStreak[killerid] % 10))
        {
            SetPlayerWantedLevel(killerid, GetPlayerWantedLevel(killerid)+1);
            format(string, sizeof(string), "{FF0000}<!> {CC6699}%s is on %d kill spree!", GetName(killerid), KillStreak[killerid]);
            SendClientMessageToAll(red, string);

            GivePlayerCash(killerid, 5000);
            Info[killerid][XP] += 150;
            LevelUp(killerid);
            WinnerText(killerid, "+$5,000~n~+150 XP");
        }
        if(Info[playerid][Hitman] > 0)
        {
            if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
            {
                GivePlayerCash(killerid, Info[playerid][Hitman]);
                format(string, sizeof(string), "Bounty $%s", cNumber(Info[playerid][Hitman]));
                PlayerTextDrawSetString(killerid, BPayout[playerid], string);
                PlayerTextDrawShow(killerid, BPayout[playerid]);
                PlayerPlaySound(killerid,1057,0.0,0.0,0.0);
                SetTimerEx("HidePayout", 3000, 0, "i", killerid);
                Info[playerid][Hitman] = 0;
            }
        }
        if(InDuel[playerid] == 1)
        {
            new id = Opponent[playerid];
            new w1 = Weapon1[playerid];
            new w2 = Weapon2[playerid];
            new c = Bet[playerid];

            new wname1[34], wname2[34];
            GetWeaponName(w1, wname1, 34);
            GetWeaponName(w2, wname2, 34);
            SetPlayerVirtualWorld(playerid, 0);
            SetPlayerVirtualWorld(id, 0);
            ResetPlayerWeaponsEx(id);
            GivePlayerCash(id, c);
            GivePlayerCash(playerid, -c);
            TeamColorFP(playerid);
            TeamColorFP(killerid);
            SpawnPlayer(killerid);

            format(string, 124, "[DUEL] %s have won the duel against %s and won $%s", GetName(id), GetName(playerid), cNumber(c));
            SendClientMessageToAll(0x00CDFFFF, string);

            Weapon1[id] = -1;
            Weapon2[id] = -1;
            Bet[id] = 0;
            Opponent[id] = -1;
            Invited[id] = -1;

            Weapon1[playerid] = -1;
            Weapon2[playerid] = -1;
            Bet[playerid] = 0;
            Opponent[playerid] = -1;
            Invited[playerid] = -1;
        }
    }

    Info[playerid][Deaths]++;
    KillStreak[playerid] = 0;

    if(InTDM[playerid] == 1)
    {
        TextDrawHideForPlayer(playerid, TDMInfo);
        PlayersInTDM --;
        if(GetPlayerTeam(playerid) == TDMTeamOne)
        {
            PlayerTeamOne --;
            if(PlayerTeamOne == 0)
            {
                foreach(new i : Player)
                {
                    if(InTDM[i] == 1 && GetPlayerTeam(i) == TDMTeamTwo && GetPlayerState(i) != PLAYER_STATE_WASTED)
                    {
                        TextDrawHideForPlayer(i, TDMInfo);
                        format(string, sizeof(string), "%s has won the TDM", GetName(i));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        Info[i][XP] += 100;
                        GivePlayerCash(i, randomEx(10000,30000));
                        format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                        WinnerText(i, string);
                        ResetPlayerWeaponsEx(i);
                        SpawnPlayerEx(i);
                        TextDrawHideForPlayer(i, TDMInfo);
                        InTDM[i] = 0;
                        TDMGame = NON_TDM;
                        TDMStarted = false;
                        PlayersInTDM = 0;
                        PlayerTeamOne = 0;
                        PlayerTeamTwo = 0;
                    }
                }
            }
        }
        if(GetPlayerTeam(playerid) == TDMTeamTwo)
        {
            PlayerTeamTwo --;
            if(PlayerTeamTwo == 0)
            {
                foreach(new i : Player)
                {
                    if(InTDM[i] == 1 && GetPlayerTeam(i) == TDMTeamOne && GetPlayerState(i) != PLAYER_STATE_WASTED)
                    {
                        TextDrawHideForPlayer(i, TDMInfo);
                        format(string, sizeof(string), "%s has won the TDM", GetName(i));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        Info[i][XP] += 100;
                        GivePlayerCash(i, randomEx(10000,30000));
                        format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                        WinnerText(i, string);
                        ResetPlayerWeaponsEx(i);
                        SpawnPlayerEx(i);
                        TextDrawHideForPlayer(i, TDMInfo);
                        InTDM[i] = 0;
                        TDMGame = NON_TDM;
                        TDMStarted = false;
                        PlayersInTDM = 0;
                        PlayerTeamOne = 0;
                        PlayerTeamTwo = 0;
                    }
                }
            }
        }
        KillTimer(TDTimer);
    }
    if(InEvent[playerid] == 1 && eInfo[EventStarted] == true)
    {
        switch(eInfo[Type])
        {
            case EVENT_TDM:
            {
                if(GetPlayerTeam(playerid) == TEAM_ONE)
                {
                    ePlayerTeamOne--;
                    if(ePlayerTeamOne == 0)
                    {
                        foreach(new i : Player)
                        {
                            if(InEvent[i] == 1 && GetPlayerTeam(i) == TEAM_TWO && GetPlayerState(i) != PLAYER_STATE_WASTED)
                            {
                                format(string, sizeof(string), "%s has won the event", GetName(i));
                                SendClientMessageToAll(0x00FFFFFF, string);
                                Info[i][XP] += 100;
                                GivePlayerCash(i, eInfo[Prize]);
                                ResetPlayerWeaponsEx(i);
                                SpawnPlayerEx(i);

                                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                                WinnerText(i, string);

                                InEvent[i] = 0;
                            }
                        }

                        ePlayers = 0;
                        ePlayerTeamTwo = 0;
                        ePlayerTeamOne = 0;
                        eInfo[Type] = EVENT_NONE;
                        eInfo[EventStarted] = false;
                    }
                }
                if(GetPlayerTeam(playerid) == TEAM_TWO)
                {
                    ePlayerTeamTwo--;
                    if(ePlayerTeamTwo == 0)
                    {
                        foreach(new i : Player)
                        {
                            if(InEvent[i] == 1 && GetPlayerTeam(i) == TEAM_ONE && GetPlayerState(i) != PLAYER_STATE_WASTED)
                            {
                                format(string, sizeof(string), "%s has won the event", GetName(i));
                                SendClientMessageToAll(0x00FFFFFF, string);

                                Info[i][XP] += 100;
                                GivePlayerCash(i, eInfo[Prize]);

                                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                                WinnerText(i, string);

                                ResetPlayerWeaponsEx(i);
                                SpawnPlayerEx(i);

                                InEvent[i] = 0;
                            }
                        }

                        ePlayers = 0;
                        ePlayerTeamTwo = 0;
                        ePlayerTeamOne = 0;
                        eInfo[Type] = EVENT_NONE;
                        eInfo[EventStarted] = false;
                    }
                }
            }
            case EVENT_DM:
            {
                ePlayers--;
                if(ePlayers == 1)
                {
                    foreach(new i : Player)
                    {
                        if(InEvent[i] == 1 && GetPlayerState(i) != PLAYER_STATE_WASTED)
                        {
                            format(string, sizeof(string), "%s has won the event", GetName(i));
                            SendClientMessageToAll(0x00FFFFFF, string);
                            Info[i][XP] += 100;
                            GivePlayerCash(i, eInfo[Prize]);
                            ResetPlayerWeaponsEx(i);
                            SpawnPlayerEx(i);

                            format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                            WinnerText(i, string);

                            InEvent[i] = 0;
                        }
                    }

                    ePlayers = 0;
                    ePlayerTeamTwo = 0;
                    ePlayerTeamOne = 0;
                    eInfo[Type] = EVENT_NONE;
                    eInfo[EventStarted] = false;
                }
            }
        }
    }
    if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
    {
        new query[74];
        mysql_format(mysql, query, sizeof(query), "DELETE FROM `Weapons` WHERE `ID` = %d", Info[playerid][ID]);
        mysql_tquery(mysql, query);

        if(killerid != INVALID_PLAYER_ID) SetPlayerWantedLevel(killerid, GetPlayerWantedLevel(killerid)+1);

        new weapon, ammo;
        for (new i; i <= 12; i++)
        {
            GetPlayerWeaponData(playerid, i, weapon, ammo);

            switch (weapon)
            {
                case 22 .. 32: ammo = 150;
            }

            switch (weapon) 
            {
                case 1 .. 43: 
                {
                    if (weapon != 0) CreateStaticPickup(GetWeaponModelID(weapon), ammo, 19, X + random(4), Y + random(4), Z, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid));
                }
            }
        }

        ResetPlayerWeapons(playerid);

        for (new i, j = sizeof(Hospitalcoor); i < j; i++)
        {
            tmp_distance = GetPlayerDistanceFromPoint(playerid, Hospitalcoor[i][0], Hospitalcoor[i][1], Hospitalcoor[i][2]);
            if (tmp_distance < distance)
            {
                distance = tmp_distance;
                closest = i;
            }
        }
        SetSpawnInfo(playerid, NO_TEAM, GetPlayerSkin(playerid), Hospitalcoor[closest][0], Hospitalcoor[closest][1], Hospitalcoor[closest][2], Hospitalcoor[closest][3], 0, 0, 0, 0, 0, 0);
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{
    InHouse[playerid] = INVALID_HOUSE_ID;
    TeamColorFP(playerid);
    TextDrawShowForPlayer(playerid, ServerTime);
    SetPlayerTime(playerid, serverhour, serverminute);
    SetPlayerSkin(playerid, OldSkin[playerid]);
    OldSkin[playerid] = GetPlayerSkin(playerid);

    new Float:X, Float:Y, Float:Z;
    GetPlayerPos(playerid, X, Y, Z);
    SetPlayerPos(playerid, X, Y, Z+1);

    if(pTeam[playerid] != NO_TEAM)
    {
        for (new i, j = sizeof(g_Turf); i < j; i++)
        {
            GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

            if (g_Turf[i][turfState] == TURF_STATE_ATTACKED)
            {
                GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
            }
        }
    }

    if(PlayerUsingLoopingAnim[playerid])
    {
        PlayerUsingLoopingAnim[playerid] = 0;
    }

    if(!worldtime_override)
    {
        gettime(serverhour, serverminute);
    }
    else
    {
        serverhour = worldtime_overridehour;
        serverminute = worldtime_overridemin;
    }

    if(Info[playerid][Logged] == 0)
    {
        Info[playerid][Logged] = 1;
        Info[playerid][Registered] = 0;
    
        SetPlayerPos(playerid, Info[playerid][PosX], Info[playerid][PosY], Info[playerid][PosZ]);
        SetPlayerSkin(playerid, Info[playerid][Skin]);
        SetPlayerInterior(playerid, Info[playerid][Interior]);
        SetPlayerHealthEx(playerid, Info[playerid][pHealth]);
        SetPlayerArmourEx(playerid, Info[playerid][pArmour]);

        TextDrawShowForPlayer(playerid, Textdraw0);
        TextDrawShowForPlayer(playerid, Textdraw1);
        TextDrawShowForPlayer(playerid, Textdraw2);
        TextDrawShowForPlayer(playerid, Textdraw3);
        TextDrawShowForPlayer(playerid, Textdraw4);
        TextDrawShowForPlayer(playerid, Textdraw5);
        TextDrawShowForPlayer(playerid, Textdraw6);
        TextDrawShowForPlayer(playerid, Textdraw7);
        TextDrawShowForPlayer(playerid, Textdraw8);
        TextDrawShowForPlayer(playerid, Textdraw9);
        TextDrawShowForPlayer(playerid, Textdraw10);
        TextDrawShowForPlayer(playerid, Textdraw11);
        TextDrawShowForPlayer(playerid, Textdraw12);
        TextDrawShowForPlayer(playerid, Textdraw13);
        TextDrawShowForPlayer(playerid, Textdraw14);
        TextDrawShowForPlayer(playerid, Textdraw15);
    }

    if(InEvent[playerid] == 1 || InDerby[playerid] == 1 || InTDM[playerid] == 1 || InParkour[playerid] == 1 || InSkydive[playerid] == 1 || InDuel[playerid] == 1)
    {
        SetPlayerVirtualWorld(playerid, 0);
        SetPlayerInterior(playerid, 0);
        SpawnPlayerEx(playerid);
        InEvent[playerid] = 0;
        InDerby[playerid] = 0;
        InTDM[playerid] = 0;
        InParkour[playerid] = 0;
        InSkydive[playerid] = 0;
        InDuel[playerid] = 0;
    }

    for(new i, j = MAX_ATTACHMENTS; i < j; i++) 
    { 
        if(oInfo[playerid][i][used1] == true)
        {
            SetPlayerAttachedObject(playerid, oInfo[playerid][i][index1], oInfo[playerid][i][modelid1], oInfo[playerid][i][bone1], oInfo[playerid][i][fOffsetX1], oInfo[playerid][i][fOffsetY1], oInfo[playerid][i][fOffsetZ1], oInfo[playerid][i][fRotX1], oInfo[playerid][i][fRotY1], oInfo[playerid][i][fRotZ1], oInfo[playerid][i][fScaleX1], oInfo[playerid][i][fScaleY1], oInfo[playerid][i][fScaleZ1]);
        }
    }

    if(Info[playerid][InDM] == 1) 
    {
        RespawnInDM(playerid);
    }

    if(Info[playerid][Jailed] == 1)
    {
        SetPlayerPos(playerid, 264.6288,77.5742, 1001.0391);
        SetPlayerInterior(playerid, 6);
    }

    if(PlayedSound[playerid] == 1)
    {
        StopAudioStreamForPlayer(playerid);
        PlayedSound[playerid] = 0;
    }

    if(Info[playerid][Spec] == 1)
    {
        SpawnPlayerEx(playerid);
        Info[playerid][Spec] = 0;
    }

    if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
    {
        pProtectTick[playerid] = 10;
        SetPlayerHealthEx(playerid, FLOAT_INFINITY);
    }

    if(Info[playerid][MapHide] == 1) {

        foreach(new i : Player) SetPlayerMarkerForPlayer(i, playerid, (GetPlayerColor(playerid) & 0xFFFFFF00));
    }
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    if(Info[playerid][Registered] == 1)
    {
        TogglePlayerSpectating(playerid, false);
        SetPlayerVirtualWorld(playerid, 99);

        PutPlayerInVehicle(playerid, ClassVehicles[0], 1);
        PutPlayerInVehicle(playerid, ClassVehicles[1], 1);
        PutPlayerInVehicle(playerid, ClassVehicles[2], 1);

        RemovePlayerFromVehicle(playerid);

        SetPlayerPos(playerid, 1095.6807, 1079.3359, 10.8359);
        SetPlayerFacingAngle(playerid, 311.4607);
        SetPlayerCameraPos(playerid, 1102.4128, 1084.3353, 13.2434);
        SetPlayerCameraLookAt(playerid, 1095.6807, 1079.3359, 10.8359);

        switch(random(5)) 
        { 
            case 0: ApplyAnimation(playerid, "DANCING", "dnce_M_a", 4.1, 1, 0, 0, 0, 0); 
            case 1: ApplyAnimation(playerid, "DANCING", "dnce_M_b", 4.1, 1, 0, 0, 0, 0); 
            case 2: ApplyAnimation(playerid, "DANCING", "dnce_M_c", 4.1, 1, 0, 0, 0, 0); 
            case 3: ApplyAnimation(playerid, "DANCING", "dnce_M_d", 4.1, 1, 0, 0, 0, 0); 
            case 4: ApplyAnimation(playerid, "DANCING", "dnce_M_e", 4.1, 1, 0, 0, 0, 0); 
        }

        PlayerTextDrawDestroy(playerid, Background);
        PlayerTextDrawDestroy(playerid, Middle);
        PlayerTextDrawDestroy(playerid, ServerName);
        PlayerTextDrawDestroy(playerid, ServerTitle);
        PlayerTextDrawDestroy(playerid, Bottom);
        PlayerTextDrawDestroy(playerid, Middle2);
        TextDrawShowForPlayer(playerid, WebsiteTD);
        TextDrawShowForPlayer(playerid, ServerTime);
        OldSkin[playerid] = GetPlayerSkin(playerid);
        return 1;
    }
    else if(Info[playerid][Registered] == 0)
    {
        SetTimerEx("SpawnHim", 1, 0, "i", playerid);
        return 1;
    }
    return 0;
}

public OnPlayerRequestSpawn(playerid)
{
    if(Info[playerid][Registered] == 1)
    {
        SetTimerEx("SpawnHim2", 10, 0, "i", playerid);
        return 1;
    }
    return 0;
}

public OnPlayerText(playerid, text[])
{
    new string[128];
    new len = strlen(text), firstsign = -1;
    if(!IsPlayerSpawned(playerid) && Info[playerid][Level] < 2) 
    {    
        SCM(playerid, red, "You must be spawned to be able to talk");
        return 0;
    }
    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }
    if(Info[playerid][Level] < 2)
    {
        if(!strcmp(text, pLastMsg[playerid], true))
        {
    	   SCM(playerid, red, "Your message has been blocked as spam");
    	   return 0;
        }
        strpack(pLastMsg[playerid], text, sizeof(pLastMsg[]));
    }
    for(new i = 0; i < len; i ++) if(text[i] != ' ')
    {
        firstsign = i;
        break;
    }
    if(firstsign == -1 || firstsign > 3) return false;
    if(text[0] == '@' && Info[playerid][Level] >= 2)
    {
        format(string, sizeof(string),"%s (%d) [STAFF]: {FFFFFF}%s", GetName(playerid), playerid, text[1]);
        SendToAdmins(GetPlayerColor(playerid), string);
        return 0;
    }
    if(Info[playerid][Level] < 2)
    {
        if(stringContainsIP(text))
        {
            format(string, sizeof(string), "%s has been kicked for advertising", GetName(playerid));
            SendClientMessageToAll(red, string);
            DelayKick(playerid);
            return 0;
        }
    }
    if(Info[playerid][Logged] == 0) return 0;

    switch(xTestBusy)
    {
        case true:
        {
            if(!strcmp(xChars, text, false))
            {
                format(string, sizeof(string), "[{FF0000}REACTION{FFFFFF}] {3399FF}%s has won the reaction test", GetName(playerid));
                SendClientMessageToAll(-1, string);

                format(string, sizeof(string), "[{FF0000}REACTION{FFFFFF}] {3399FF}You have earned $%s", cNumber(xCash));
                SendClientMessage(playerid, -1, string);

                GivePlayerCash(playerid, xCash);
                xReactionTimer = SetTimer("xReactionTest", TIME, 1);
                xTestBusy = false;
                return 0;
            }
        }
    }

    format(string, sizeof(string), "%s (%d): {FFFFFF}%s", GetName(playerid), playerid, text);
    SendMessage(GetPlayerColor(playerid), string);
    return 0;
}

stock Float:GetAngleToPoint(Float:fDestX, Float:fDestY, Float:fPointX, Float:fPointY)
    return atan2((fDestY - fPointY), (fDestX - fPointX)) + 180.0;

public OnPlayerCommandPerformed(playerid, cmd[], params[], success)
{ 
    if(!success) return SCM(playerid, red, "Unknown command! Type /commands"); 

    foreach(new i : Player)
    {
        if(Info[i][Level] >= 2)
        {
            if(Info[i][ReadCMD] == true && Info[playerid][Level] < Info[i][Level])
            {
                new str[128];
                format(str, sizeof(str), "{FF0000}<!> {CC6699}%s has used command '/%s'", GetName(playerid), cmd);
                SendClientMessage(i, red, str);
            }
        }
    }
    return 1; 
}

public OnPlayerCommandReceived(playerid, cmd[], params[])
{
    if(Info[playerid][Logged] == 0) return 0;
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    new string[128];
    if (newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) 
    {
        foreach (new i : Player)
        {
            if(Info[i][Spec] == 1)
            {
                if(SpecID[i] == playerid && SpecID[i] != INVALID_PLAYER_ID)
                {
                    PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
                }
            }
        }
    }
    else if (newstate == PLAYER_STATE_ONFOOT)
    {
        foreach (new i : Player)
        {
            if(Info[i][Spec] == 1)
            {
                if(SpecID[i] == playerid && SpecID[i] != INVALID_PLAYER_ID)
                {
                    PlayerSpectatePlayer(i, playerid);
                }
            }
        }
    }
    if (newstate == PLAYER_STATE_ONFOOT)
    {
        if(InDerby[playerid] == 1)
        {
            SCM(playerid, red, "You have left the derby [LEFT VEHICLE]");
            DestroyVehicle(GetPlayerVehicleID(playerid));
            SpawnPlayerEx(playerid);
            TextDrawHideForPlayer(playerid, DerbyInfo);
            InDerby[playerid] = 0;
            PlayersInDerby -= 1;
            if(PlayersInDerby == 1)
            {
                foreach(new i : Player)
                {
                    for(new x; x < DerbyVehicles[i]; x++)
                    {
                        DestroyVehicle(DerbyVehicles[i]);
                    }

                    if(InDerby[i] == 1)
                    {
                        InDerby[i] = 0;
                        format(string, sizeof(string), "%s has won the derby", GetName(i));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        Info[i][XP] += 100;
                        GivePlayerCash(i, randomEx(10000,30000));
                        format(string, sizeof(string), "Winner $%s ~n~+100 XP", randomEx(10000,30000));
                        WinnerText(i, string);
                        SpawnPlayerEx(i);
                        TextDrawHideForPlayer(i, DerbyInfo);
                    }
                }
                KillTimer(DerbyTDTimer);
                DerbyGame = NON_DERBY;
                DerbyStarted = false;
                PlayersInDerby = 0;
            }
        }
    }

    //Ice Cream Job
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 423 && InJob[playerid] != ICECREAM)
    {
        if(newstate == PLAYER_STATE_DRIVER)
        {
            ShowInfoBox(playerid, 0x00000088, 5, "Press 2 to work on the ice cream job");
        }
    }
    if(InJob[playerid] == ICECREAM)
    {
        if(oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT)
        {
            InJob[playerid] = NOJOB;
            SCM(playerid, red, "You have left the ice cream seller job");
        }
    }

    //Hotdog Job
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 588 && InJob[playerid] != HOTDOG)
    {
        if(newstate == PLAYER_STATE_DRIVER)
        {
            ShowInfoBox(playerid, 0x00000088, 5, "Press 2 to work on the ice cream job");
        }
    }
    if(InJob[playerid] == HOTDOG)
    {
        if(oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT)
        {
            InJob[playerid] = NOJOB;
            SCM(playerid, red, "You have left the hotdog seller job");
        }
    }

    //Paramedic Job
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 416 && InJob[playerid] != PARAMEDIC)
    {
        if(newstate == PLAYER_STATE_DRIVER)
        {
            ShowInfoBox(playerid, 0x00000088, 5, "Press 2 to work as a paramedic");
        }
    }
    if(InJob[playerid] == PARAMEDIC)
    {
        if(oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT)
        {
            LeaveVehTimer[playerid] = SetTimerEx("LeaveVehicleJob", 60000, false, "i", playerid);
        }
    }
    if(newstate == PLAYER_STATE_DRIVER && InJob[playerid] == PARAMEDIC)
    {
        if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 416)
        {
            KillTimer(LeaveVehTimer[playerid]);
        }
    }

    if(newstate == PLAYER_STATE_PASSENGER)
    {
        new
            bool:DBWep = false;
        for(new i = 0; i< sizeof(DriveBy_Weps); i++)
        {
            if(GetPlayerWeapon(playerid) == DriveBy_Weps[i])
            {
                SetPlayerArmedWeapon(playerid, DriveBy_Weps[i]);
                DBWep = true;
                break;
            }
        }
        if(DBWep) return 1;
        else if(!DBWep)
        {
            new
                bool:DBWep2 = false,
                p_WepData[13][2];
            for(new i = 0; i< 13; i++)
            {
                GetPlayerWeaponData(playerid, i, p_WepData[i][0], p_WepData[i][1]);
                for(new a; a< sizeof(DriveBy_Weps); a++) 
                {
                    if(p_WepData[i][0] == DriveBy_Weps[a] && p_WepData[i][0] >= 1)
                    {
                        SetPlayerArmedWeapon(playerid, DriveBy_Weps[a]);
                        DBWep2 = true;
                        break;
                    }
                }
                if(DBWep2) break;
            }
        }
        if(!DBWep2) return SetPlayerArmedWeapon(playerid, 0), 1;
    }

    if(newstate != PLAYER_STATE_DRIVER) 
    {
        PlayerTextDrawHide(playerid, VehicleSpeedo);
        KillTimer(VehicleTimer[playerid]);
    }
    else if(newstate == PLAYER_STATE_DRIVER) 
    {
        PlayerTextDrawShow(playerid, VehicleSpeedo);
        VehicleTimer[playerid] = SetTimerEx("VehicleSpeedoMeter", 500, true, "i", playerid);
    }

    if(newstate == PLAYER_STATE_PASSENGER)
    {
        if(MaxVehicleSeats[(GetVehicleModel(GetPlayerVehicleID(playerid)) - 400)] < GetPlayerVehicleSeat(playerid))
        {
            ClearAnimations(playerid);

            SetPlayerPos(playerid, vEnterPos[playerid][0], vEnterPos[playerid][1], vEnterPos[playerid][2]);
            SetPlayerFacingAngle(playerid, vEnterPos[playerid][3]);
        }
    }

    if(newstate == PLAYER_STATE_DRIVER)
    {
        if(GetPlayerVehicleID(playerid) != p_CarWarpVehicleID[playerid])
        {
            if(p_CarWarpTime[ playerid ] > gettime())
            {
                format(string, sizeof(string), "%s has been kicked for vehicle teleport hack", GetName(playerid));
                SendClientMessageToAll(red, string);
                return DelayKick(playerid);
            }
            p_CarWarpTime[playerid] = gettime() + 1;
            p_CarWarpVehicleID[playerid] = GetPlayerVehicleID(playerid);
        }
    }
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if(issuerid != INVALID_PLAYER_ID)
	{
        if(InEvent[playerid] == 1 && InEvent[issuerid] == 1)
        {
            if(eInfo[Headshot] == 1)
            {
                if(bodypart == 9) SetPlayerHealthEx(playerid, 0);
            }
        }
        if(InAmmu[playerid] == 1)
        {
            new Float:issuerHP, Float:playerHP;
            GetPlayerHealth(issuerid, issuerHP);
            GetPlayerHealth(playerid, playerHP);

            GameTextForPlayer(issuerid, "NO KILLING!", 3000, 3);

            SetPlayerHealth(issuerid, issuerHP-20);
            SetPlayerHealth(playerid, playerHP+20);
        }

        AbuseTick[playerid] = gettime();
	}
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    if(hittype == BULLET_HIT_TYPE_PLAYER)
    {
        if(hitid != INVALID_PLAYER_ID)
        {
            if(InEvent[hitid] == 1 && InEvent[playerid] == 0 || InEvent[hitid] == 0 && InEvent[playerid] == 1)
            {
                GameTextForPlayer(playerid, "NO KILLING!", 3000, 3);
                return 0;
            }
            if(InTDM[hitid] == 1 && InTDM[playerid] == 0 || InTDM[hitid] == 0 && InTDM[playerid] == 1)
            {
                GameTextForPlayer(playerid, "NO KILLING!", 3000, 3);
                return 0;
            }
            if(InParkour[hitid] == 1 && InParkour[playerid] == 0 || InParkour[hitid] == 0 && InParkour[playerid] == 1)
            {
                GameTextForPlayer(playerid, "NO KILLING!", 3000, 3);
                return 0;
            }
            if(InSkydive[hitid] == 1 && InSkydive[playerid] == 0 || InSkydive[hitid] == 0 && InSkydive[playerid] == 1)
            {
                GameTextForPlayer(playerid, "NO KILLING!", 3000, 3);
                return 0;
            }
            if(InDerby[hitid] == 1 && InDerby[playerid] == 0)
            {
                GameTextForPlayer(playerid, "NO KILLING!", 3000, 3);
                return 0;
            }
            if(InAmmu[hitid] == 1 && InAmmu[playerid] == 1)
            {
                GameTextForPlayer(playerid, "NO KILLING!", 5000, 3);
                return 0;
            }
            if(pProtectTick[hitid] > 0)
            {
                GameTextForPlayer(playerid, "NO SPAWN KILLING!", 5000, 3);
                return 0;
            }
        }
    }

    if(Info[playerid][WeaponTeleport] == 1)
    {
        if(hittype != BULLET_HIT_TYPE_PLAYER)
        {
            CA_FindZ_For2DCoord(fX, fY, fZ);
            SetPlayerPos(playerid, fX, fY, fZ+1);
        }
    }

    if(weaponid != 0 && weaponid != 46)
    {
        if(GetPlayerAmmo(playerid) <= 1) gPlayerWeaponData[playerid][weaponid] = false;
    }

    if(pProtectTick[playerid] > 0)
    {
        SetPlayerHealthEx(playerid, 100.0);
    }
    return 1;
}

stock IsPlayerNearVehicle(playerid, vehicleid, Float:range)
{
    if(!GetVehicleModel(vehicleid)) return 0;
    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);
    return IsPlayerInRangeOfPoint(playerid, range, x, y, z);
}

IsPlayerNearPlayer(playerid, n_playerid, Float:radius)
{
    new Float:npx, Float:npy, Float:npz;
    GetPlayerPos(n_playerid, npx, npy, npz);
    if(IsPlayerInRangeOfPoint(playerid, radius, npx, npy, npz)) return true;
    else return false;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_WALK) { cmd_buyhouse(playerid, ""), cmd_buyproperty(playerid, ""); }
    if(newkeys & KEY_SECONDARY_ATTACK) { cmd_enterexit(playerid, ""); }
    if(animation[playerid] != 0)
    {
        if(newkeys & KEY_SECONDARY_ATTACK)
        {
            StopLoopingAnim(playerid);
            animation[playerid] = 0;
        }
    }
    if(HOLDING(KEY_JUMP))
    {
        if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
        {
            if(!IsPlayerInAnyVehicle(playerid))
            {
                if(Info[playerid][Jump] == 1 && JumpStatus[playerid] == 1)
                {
                    new Float:x,Float:y,Float:z;
                    GetPlayerVelocity(playerid,x,y,z);
                    if(!CA_IsPlayerOnSurface(playerid, 1.5))
                    {
                        SetPlayerVelocity(playerid,x,y,z+4);
                    }
                    Jumping[playerid] = 1;
                }   
            }
        }
    }
    if(RELEASED(KEY_JUMP))
    {
        if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
        {
            if(!IsPlayerInAnyVehicle(playerid))
            {
                if(Info[playerid][Jump] == 1 && JumpStatus[playerid] == 1)
                {
                    Jumping[playerid] = 0;
                }   
            }
        }
    }
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 416 && InJob[playerid] != PARAMEDIC)
    {
        if(newkeys & KEY_LOOK_BEHIND)
        {
            InJob[playerid] = PARAMEDIC;
            ShowInfoBox(playerid, 0x00000088, 5, "You have to heal the players that marked as a red mark in your minimap to earn money");
            foreach(new i : Player)
            {
                new Float:getHP;
                GetPlayerHealth(i, getHP);
                if(i != playerid && getHP < 100.0)
                {
                    SetPlayerMarkerForPlayer(playerid, i, 0xFF0000FF);
                }
            }
        }
    }
    if(InJob[playerid] == PARAMEDIC)
    {
        foreach(new i : Player)
        {
            new Float:getHP;
            GetPlayerHealth(i, getHP);
            if(i != playerid && getHP < 100.0)
            {
                if(IsPlayerNearPlayer(playerid, i, 7.0))
                {
                    if(newkeys & KEY_WALK)
                    {    
                        new currenttime = gettime();

                        if(currenttime < (JobCoolDown[i][2] + 120)) return 0;
                        JobCoolDown[i][2] = gettime();

                        SetPlayerHealthEx(i, 100.0);
                        SetPlayerMarkerForPlayer(playerid, i, GetPlayerColor(playerid));
                        GivePlayerCash(playerid, 970);
                        ShowInfoBox(i, 0x00000088, 3, "You have been healed by the paramedic");
                        WinnerText(playerid, "Payout $970");
                    }
                }
            }
        }
    }
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 588 && InJob[playerid] != HOTDOG)
    {
        if(newkeys & KEY_LOOK_BEHIND)
        {
            InJob[playerid] = HOTDOG;
            ShowInfoBox(playerid, 0x00000088, 5, "You have to sell the hotdog for other players to earn money");
        }
    }
    foreach(new i : Player)
    {
        if(InJob[i] == HOTDOG && GetVehicleModel(GetPlayerVehicleID(i)) == 588)
        {
            if(IsPlayerNearPlayer(playerid, i, 3.0))
            {
                if(newkeys & KEY_WALK)
                {
                    new Float:HP;
                    new currenttime = gettime();

                    if(currenttime < (JobCoolDown[playerid][0] + 120)) return 0;
                    JobCoolDown[playerid][0] = gettime();

                    if(GetPlayerCash(playerid) < 380) return SCM(playerid, red, "You don't have enough money");

                    GetPlayerHealth(playerid, HP);
                    SetPlayerHealthEx(playerid, HP+70.0);

                    GivePlayerCash(playerid, -380);
                    GivePlayerCash(i, 1200);
                    WinnerText(i, "Payout $1,200");
                    ApplyAnimation(playerid, "VENDING", "VEND_EAT_P", 4.1, false, false, false, false, 0, false);
                    SetVehicleParamsForPlayer(GetPlayerVehicleID(i), playerid, 0, 0);
                }
            }
        }
    }
    if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 423 && InJob[playerid] != ICECREAM)
    {
        if(newkeys & KEY_LOOK_BEHIND)
        {
            InJob[playerid] = ICECREAM;
            ShowInfoBox(playerid, 0x00000088, 5, "You have to sell the ice cream for other players to earn money");
        }
    }
    foreach(new i : Player)
    {
        if(InJob[i] == ICECREAM && GetVehicleModel(GetPlayerVehicleID(i)) == 423)
        {
            if(IsPlayerNearPlayer(playerid, i, 3.0))
            {
                if(newkeys & KEY_WALK)
                {
                    new Float:HP;
                    new currenttime = gettime();

                    if(currenttime < (JobCoolDown[playerid][1] + 120)) return 0;
                    JobCoolDown[playerid][1] = gettime();

                    if(GetPlayerCash(playerid) < 180) return SCM(playerid, red, "You don't have enough money");

                    GetPlayerHealth(playerid, HP);
                    SetPlayerHealthEx(playerid, HP+50.0);

                    GivePlayerCash(playerid, -180);
                    GivePlayerCash(i, 1200);
                    WinnerText(i, "Payout $1,200");
                    ApplyAnimation(playerid, "VENDING", "VEND_EAT_P", 4.1, false, false, false, false, 0, false);
                    SetVehicleParamsForPlayer(GetPlayerVehicleID(i), playerid, 0, 0);
                }
            }
        }
    }
    if(InSelfie[playerid] == 1)
    {
        if(newkeys & KEY_RIGHT)
        {
            GetPlayerPos(playerid,SelfieX[playerid],SelfieY[playerid],SelfieZ[playerid]);
            new Float: n1X, Float: n1Y;
            if(Degree[playerid] >= 360) Degree[playerid] = 0;
            Degree[playerid] += Speed;
            n1X = SelfieX[playerid] + Radius * floatcos(Degree[playerid], degrees);
            n1Y = SelfieY[playerid] + Radius * floatsin(Degree[playerid], degrees);
            SetPlayerCameraPos(playerid, n1X, n1Y, SelfieZ[playerid] + Height);
            SetPlayerCameraLookAt(playerid, SelfieX[playerid], SelfieY[playerid], SelfieZ[playerid]+1);
            SetPlayerFacingAngle(playerid, Degree[playerid] - 90.0);
        }
        if(newkeys & KEY_LEFT)
        {
            GetPlayerPos(playerid,SelfieX[playerid],SelfieY[playerid],SelfieZ[playerid]);
            new Float: n1X, Float: n1Y;
            if(Degree[playerid] >= 360) Degree[playerid] = 0;
            Degree[playerid] -= Speed;
            n1X = SelfieX[playerid] + Radius * floatcos(Degree[playerid], degrees);
            n1Y = SelfieY[playerid] + Radius * floatsin(Degree[playerid], degrees);
            SetPlayerCameraPos(playerid, n1X, n1Y, SelfieZ[playerid] + Height);
            SetPlayerCameraLookAt(playerid, SelfieX[playerid], SelfieY[playerid], SelfieZ[playerid]+1);
            SetPlayerFacingAngle(playerid, Degree[playerid] - 90.0);
        }
    }
    if(GotJetpack[playerid] == 1)
    {
        if((newkeys & KEY_YES) || (newkeys & KEY_SECONDARY_ATTACK))
        {
            GotJetpack[playerid] = 0;
            Info[playerid][InDM] = 0;
            Info[playerid][DMZone] = 0;
            ResetPlayerWeaponsEx(playerid);
            SpawnPlayerEx(playerid);
            SetPlayerVirtualWorld(playerid, 0);
            StopAudioStreamForPlayer(playerid);
            SetCameraBehindPlayer(playerid);
        }
    }
    if((newkeys & KEY_YES))
	{
	    new near = IsNearPlant(playerid);
	    if(near != -1)
	    {
	        if(PlantInfo[near][Status] == 2)
	        {
		        if(!strcmp(GetName(playerid), PlantInfo[near][Owner], true))
		        {
	  	  			ShowInfoBox(playerid, 0x00000088, 5, "You have picked up your marijuana plant and earned 10 grams of marijuana");
	  	  			Info[playerid][Marijuana] += 10;
	  	  			DestroyPlant(near);
	  	  			return 1;
				}
				else return ShowInfoBox(playerid, 0x00000088, 5, "You are not the owner of this marijuana plant");
			}
			else return ShowInfoBox(playerid, 0x00000088, 5, "Marijuana plant has not grown yet");
		}
	}
    if((newkeys & KEY_WALK))
    {
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 2501.6370, -1686.3329, 13.5024)) {
            if(pTeam[playerid] == GROVE) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_GROVE);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Grove Street, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, GROVE);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 2165.7722, -1676.3916, 15.0859)) {
            if(pTeam[playerid] == BALLAS) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_BALLAS);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Ballas, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, BALLAS);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 2347.2505, -1169.4064, 28.0195)) {
            if(pTeam[playerid] == VAGOS) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_VAGOS);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Los Santos Vagos, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, VAGOS);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 1952.5033, -2038.0951, 13.5469)) {
            if(pTeam[playerid] == AZTECAS) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_AZTECAS);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Varrios Los Aztecas, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, AZTECAS);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 1153.8942, -1768.5330, 16.5938)) {
            if(pTeam[playerid] == BIKERS) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_BIKERS);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Bikers, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, BIKERS);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 690.3701, -1275.8894, 13.5599)) {
            if(pTeam[playerid] == TRIADS) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_TRIADS);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Triads, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, TRIADS);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 1126.2686, -2037.0341, 69.8836)) {  
            if(pTeam[playerid] == MAFIA) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_MAFIA);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Mafia, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, MAFIA);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 401.5297, -1801.8387, 7.8281)) {
            if(pTeam[playerid] == NANG) return SendClientMessage(playerid, red, "You're already in this gang");
            SetPlayerColor(playerid, COLOR_NANG);
            ShowInfoBox(playerid, 0x00000088, 5, "You have joined gang Da Nang Boys, Kill the enemies and attack the gang hoods to earn money.");
            TeamCount(playerid, NANG);
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                {
                    GangZoneFlashForPlayer(playerid, g_Turf[i][turfId], 0xFF0000AA);
                }
            }
        }
    }
    if(IsPlayerInStunt(playerid))
    {
        if(newkeys & KEY_YES) // Flip
        {
            if (IsPlayerInAnyVehicle(playerid))
            {
                new vehicle2,
                    Float:zangle;

                vehicle2 = GetPlayerVehicleID(playerid);
                GetVehicleZAngle(vehicle2,zangle);
                SetVehicleZAngle(vehicle2,zangle);
            }
        }
        if(newkeys & KEY_SUBMISSION) // Fix
        {
            if (IsPlayerInAnyVehicle(playerid))
            {
                RepairVehicle(GetPlayerVehicleID(playerid));
                SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
            }
        }
        if(newkeys & KEY_FIRE) // Turbo
        {
            if (IsPlayerInAnyVehicle(playerid))
            {
                new Float:vx, Float:vy, Float:vz;
                AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
                GetVehicleVelocity(GetPlayerVehicleID(playerid), vx, vy, vz);
                SetVehicleVelocity(GetPlayerVehicleID(playerid) ,vx * 1.5,vy * 1.5 ,vz * 1.5);
            }
        }
        if(newkeys & KEY_CROUCH) // Horn Jump
        {
            if(IsPlayerInAnyVehicle(playerid))
            {
                new Float:x, Float:y, Float:z;
                GetVehicleVelocity(GetPlayerVehicleID(playerid), x, y, z);
                SetVehicleVelocity(GetPlayerVehicleID(playerid) ,x ,y ,z+0.15);
            }
        }
    }
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
    if(Info[playerid][Level] >= 2)
    {
        CA_FindZ_For2DCoord(fX, fY, fZ);
        if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            SetVehiclePos(GetPlayerVehicleID(playerid), fX, fY, fZ+1);
            PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), PLAYER_STATE_DRIVER);
        }
        else if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
        {
            SetPlayerPos(playerid, fX, fY, fZ+1);
        }
    }
    return 1;
}

public OnPlayerEnterVehicle(playerid,vehicleid,ispassenger)
{
    if(ispassenger)
    {
        GetPlayerPos(playerid, vEnterPos[playerid][0], vEnterPos[playerid][1], vEnterPos[playerid][2]);
        GetPlayerFacingAngle(playerid, vEnterPos[playerid][3]);
    }
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
    if(InJob[playerid] == ICECREAM || InJob[playerid] == HOTDOG)
    {
       foreach(new i : Player) if(i != playerid) SetVehicleParamsForPlayer(GetPlayerVehicleID(playerid), i, 0, 0); 
    } 
    if(InDerby[playerid] == 1 || InTDM[playerid] == 1 || InParkour[playerid] == 1 || InEvent[playerid] == 1) DestroyVehicle(GetPlayerVehicleID(playerid));
    return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
    if(GetPlayerInterior(playerid) == 0)
    {
        new str[84];
        format(str, sizeof(str), "%s has been kicked for vehicle tune cheats", GetName(playerid));
        DelayKick(playerid);
        return 0;
    }
    if(GetPlayerInterior(playerid) != 0)
    {
        for(new i; i < sizeof(VehicleMods); i++)
        {
            if(componentid == VehicleMods[i][compmod]) GivePlayerCash(playerid, -VehicleMods[i][compprice]);
        }
    }
    foreach(new i : PrivateVehicles[playerid])
    {
        if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
        {
            if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
            {
                for(new x; x < 14; x++)
                {
                    if(GetVehicleComponentType(componentid) == x)
                    {
                        vInfo[i][vehMod][x] = componentid;
                    }
                }
                SaveVehicle(i);
            }
        }
    }
    return 1;
}

public OnVehicleSpawn(vehicleid)
{
    foreach(new playerid : Player)
    {
        foreach(new i : PrivateVehicles[playerid])
        {
            for(new x = 0; x < 14; x++) 
            {
                if(!strcmp(vInfo[i][vehOwner], GetName(playerid))) 
                {
                    if(vInfo[i][vehMod][x] > 0) AddVehicleComponent(vInfo[i][vehSessionID], vInfo[i][vehMod][x]);
                }
            }
        }
    }
    return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
    foreach(new i : PrivateVehicles[playerid])
    {
        if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
        {
            if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
            {
                if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
                {
                    vInfo[i][vehColorOne] = color1;
                    vInfo[i][vehColorTwo] = color2;
                    ChangeVehicleColor(vInfo[i][vehSessionID], vInfo[i][vehColorOne], vInfo[i][vehColorTwo]);
                    SaveVehicle(i);
                }
            }
        }
    }
    return 0;
}

public OnVehicleStreamIn(vehicleid,forplayerid)
{
    foreach(new i : Player)
    {
        if(InJob[i] == ICECREAM || InJob[i] == HOTDOG)
        {
            if(IsPlayerInAnyVehicle(i) && GetVehicleModel(GetPlayerVehicleID(i)) == 423 || GetVehicleModel(GetPlayerVehicleID(i)) == 588)
            {
                new engine, lights, alarm, doors, bonnet, boot, objective;
                GetVehicleParamsEx(GetPlayerVehicleID(i), engine, lights, alarm, doors, bonnet, boot, objective);
                SetVehicleParamsEx(GetPlayerVehicleID(i), engine, lights, alarm, doors, bonnet, boot, 1);
            }
        }
    }
    return 1;
}

public OnVehicleStreamOut(vehicleid)
{
    foreach(new i : Player)
    {
        if(InJob[i] == ICECREAM || InJob[i] == HOTDOG)
        {
            if(IsPlayerInAnyVehicle(i) && GetVehicleModel(GetPlayerVehicleID(i)) == 423 || GetVehicleModel(GetPlayerVehicleID(i)) == 588)
            {
                new engine, lights, alarm, doors, bonnet, boot, objective;
                GetVehicleParamsEx(GetPlayerVehicleID(i), engine, lights, alarm, doors, bonnet, boot, objective);
                SetVehicleParamsEx(GetPlayerVehicleID(i), engine, lights, alarm, doors, bonnet, boot, 0);
            }
        }
    }
    return 1;
}

public OnPlayerFloodControl(playerid, iCount, iTimeSpan) 
{
    if(iCount > 3 && iTimeSpan < 8000) 
    {
        IsBanned[playerid] = 1;
        Ban(playerid);
    }
}

public OnPlayerAntiReload(playerid, weaponid)
{
    new string[128];
    switch(weaponid)
    {
        case 22 .. 38:
        {
            format(string, sizeof(string), "{FF0000}<!> {CC6699}AntiCheat suspected %s (%d) using Infinite Ammo", GetName(playerid), playerid);
            SendToAdmins(red, string);

            if(gettime() - pTickWarnings[playerid] < 20)
            {
                HackWarnings[playerid]++;

                if(HackWarnings[playerid] == 5)
                {
                    RemovePlayerWeapon(playerid, weaponid);
                    format(string, sizeof(string), "%s has been kicked for infinite ammo", GetName(playerid));
                    SendClientMessageToAll(red, string);
                    DelayKick(playerid);
                    HackWarnings[playerid] = 0;
                }
            }
            else HackWarnings[playerid] = 0;
            pTickWarnings[playerid] = gettime();
        }
    }
    return 1;
}

public OnPlayerAirbreak(playerid)
{
    if(Info[playerid][Level] != 5)
    {
        new string[60];
        format(string, sizeof(string), "%s has been kicked for airbreak", GetName(playerid));
        SendClientMessageToAll(red, string);
        DelayKick(playerid);
    }
    return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
    foreach(new i : Player)
    {
        new pppIP[16];
        GetPlayerIp(i, pppIP, 16);
        if(!strcmp(pppIP, ip, true))
        {
            if(success && strcmp(GetName(i), "_oMa37") )
            {
                SCM(i, -1, "RCON: You have entered a wrong rcon password.");
                DelayKick(i);
                return 0;
            }
        }
    }
    return 1;
}

public OnPlayerUseVending(playerid, type)
{
    if(type == VENDING_TYPE_SPRUNK) GivePlayerCash(playerid, -6);
    else if(type == VENDING_TYPE_CANDY) GivePlayerCash(playerid, -8);
    return 1;
}

public OnPlayerUseGarage(playerid, vehicleid, type)
{
    if(type == GARAGE_PAYNSPRAY) 
    {
        GivePlayerCash(playerid, -100);
        foreach(new i : PrivateVehicles[playerid])
        {
            if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
            {
                if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
                {
                    ChangeVehicleColor(vInfo[i][vehSessionID], vInfo[i][vehColorOne], vInfo[i][vehColorTwo]);
                }
            }
        }
    }
    return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
    if(clickedplayerid == playerid) return SCM(playerid, red, "You cannot send a pm to yourself");
    if(PMEnabled[clickedplayerid] == 1 && Info[playerid][Level] < 2) return SCM(playerid, red, "Player has blocked private messages");
    if(clickedplayerid == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");
    if(!IsPlayerConnected(clickedplayerid)) return SCM(playerid, red, "Player is not connected");

    SetPVarInt(playerid,"ClickedPlayer",clickedplayerid);
    ShowPlayerDialog(playerid, DIALOGS+811, DIALOG_STYLE_INPUT, "Private Message", "Enter your message below:", "Send", "Cancel");
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    new string[128];
    if(InParkour[playerid] == 1)
    {
        if(pickupid == pPickups[0])
        {
            format(string, sizeof(string), "%s has finished Parkour #1 and won $8,000 + 25 XP",GetName(playerid));
            SendClientMessageToAll(0x00FFFFFF, string);

            InParkour[playerid] = 0;
            WinnerText(playerid, "Winner $8,000 ~n~+25 XP");
            GivePlayerCash(playerid, 8000);
            Info[playerid][XP] += 25;
            LevelUp(playerid);
            SpawnPlayerEx(playerid);
        }
        if(pickupid == pPickups[1])
        {
            format(string, sizeof(string), "%s has finished Parkour #3 and won $18,000 + 100 XP",GetName(playerid));
            SendClientMessageToAll(0x00FFFFFF, string);

            InParkour[playerid] = 0;
            WinnerText(playerid, "Winner $18,000 ~n~+100 XP");
            GivePlayerCash(playerid, 18000);
            Info[playerid][XP] += 100;
            LevelUp(playerid);
            SpawnPlayerEx(playerid);
        }
        if(pickupid == pPickups[2])
        {
            format(string, sizeof(string), "%s has finished Parkour #6 and won $5,000 + 25 XP", GetName(playerid));
            SendClientMessageToAll(0x00FFFFFF, string);
            GivePlayerCash(playerid, 8000);
            Info[playerid][XP] += 25;
            LevelUp(playerid);
            InParkour[playerid] = 0;
            WinnerText(playerid, "Winner $5,000 ~n~+25XP");
            SpawnPlayerEx(playerid);
        }
    }
    if(pickupid == MoneyBagPickup)
    {
        if(MoneyBagFound == 0)
        {
            new money = randomEx(20000, 100000);
            MoneyBagFound = 1;
            DestroyDynamicPickup(MoneyBagPickup);

            format(string, sizeof(string), "~w~Moneybag: $%s", cNumber(money));
            GameTextForPlayer(playerid, string, 5000, 3);

            GivePlayerCash(playerid, money);

            format(string, sizeof(string), "Money bag has been found by %s", GetName(playerid));
            SendClientMessageToAll(0x0073E6FF, string);
            Info[playerid][MoneyBags]++;
        }
    }
    if(gPlayer_AmmuCoolDown[playerid] < gettime())
    {
        if (Streamer_GetIntData(STREAMER_TYPE_PICKUP, pickupid, E_STREAMER_MODEL_ID) == 1318)
        {
            new ammuid;
            if (gPlayer_Ammunation{playerid} == 255)
            {
                if ((ammuid = Streamer_GetIntData(STREAMER_TYPE_PICKUP, pickupid, E_STREAMER_EXTRA_ID) - sizeof ExteriorAmmu) < 0) return 1;
              
                gPlayer_Ammunation{playerid} = ammuid;
                ammuid = ExteriorAmmu[gPlayer_Ammunation{playerid}][iAmmuShop];

                SetPlayerPos(playerid, InteriorAmmu[ammuid][iAmmuX], InteriorAmmu[ammuid][iAmmuY], InteriorAmmu[ammuid][iAmmuZ]);
                SetPlayerInterior(playerid, InteriorAmmu[ammuid][AmmuIntID]);
                InAmmu[playerid] = 1;

                gPlayer_AmmuCoolDown[playerid] = gettime() + AMMU_COOLDOWN;
            }
            else
            {
                ammuid = gPlayer_Ammunation{playerid};
                
                SetPlayerPos(playerid, ExteriorAmmu[ammuid][eAmmuX], ExteriorAmmu[ammuid][eAmmuY], ExteriorAmmu[ammuid][eAmmuZ]);
                SetPlayerInterior(playerid, 0);

                InAmmu[playerid] = 0;
                
                gPlayer_AmmuCoolDown[playerid] = gettime() + AMMU_COOLDOWN;
                gPlayer_Ammunation{playerid} = 255;
            }
        }
    }
    for (new i; i < sizeof(JetPickups); i++)
    {
        if (pickupid == JetPickups[i] && Info[playerid][Jetpack] == 1)
        {
            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
        }
    }
    for (new i; i < MAX_DROPS; i++) 
    {
        if(pickupid == g_StaticPickup[i][pickupPickupid]) 
        {
            switch (g_StaticPickup[i][pickupModel]) 
            {
                case PICKUP_MODEL_WEAPONS: 
                {
                    GivePlayerWeaponEx(playerid, GetModelWeaponID(g_StaticPickup[i][pickupModel]), g_StaticPickup[i][pickupAmount]);
                }
            }
            DestroyStaticPickup(i);
        }
    }
    if(InHouse[playerid] == INVALID_HOUSE_ID) 
    {
        foreach(new i : Houses)
        {
            if(pickupid == HouseData[i][HousePickup])
            {
                SetPVarInt(playerid, "PickupHouseID", i);
            }
        }
    }
    foreach(new i : Property)
    {
		if(pickupid == pInfo[i][PropertyPickup])
		{
			AvailablePID[playerid] = i;
		}
    }
    return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
    new string[128];
    for(new i; i < sizeof(ammuCP); i++)
    {
        if(checkpointid == ammuCP[i])
        {
            ShowPlayerDialog(playerid, DIALOG_AMMU, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation", "Category\tItems\nMelee\t2\nPistols\t3\nMicro SMGs\t3\nShotguns\t3\nThrown\t1\nArmour\t1\nRifles\t2\nAssault\t2\n", "Select", "Close");
        }
    }
    if(checkpointid == sCheckpoints[0])
    {
        if(InSkydive[playerid] == 1)
        {
            
            format(string, sizeof(string), "%s has finished Skydive #1 and won $27,000 + 100 XP", GetName(playerid));
            SendClientMessageToAll(0x00FFFFFF, string);

            GivePlayerCash(playerid, 27000);
            Info[playerid][XP] += 100;
            LevelUp(playerid);
            WinnerText(playerid, "Winner $27,000 ~n~+100 XP");
            SpawnPlayerEx(playerid);
            InSkydive[playerid] = 0;
        }
    }
    if(checkpointid == sCheckpoints[1])
    {
        if(InSkydive[playerid] == 1)
        {
            format(string, sizeof(string), "%s has finished Skydive #2 and won $25,000 + 100 XP", GetName(playerid));
            SendClientMessageToAll(0x00FFFFFF, string);

            GivePlayerCash(playerid, 25000);
            Info[playerid][XP] += 100;
            LevelUp(playerid);
            WinnerText(playerid, "Winner $25,000 ~n~+100 XP");
            SpawnPlayerEx(playerid);
            InSkydive[playerid] = 0;
        }
    }
    if(checkpointid == sCheckpoints[2])
    {
        if(InSkydive[playerid] == 1)
        {
            format(string, sizeof(string), "%s has finished Skydive #3 and won $12,000 + 50 XP", GetName(playerid));
            SendClientMessageToAll(0x00FFFFFF, string);

            GivePlayerCash(playerid, 12000);
            Info[playerid][XP] += 50;
            LevelUp(playerid);
            WinnerText(playerid, "Winner $12,000 ~n~+50 XP");
            SpawnPlayerEx(playerid);
            InSkydive[playerid] = 0;
        }
    }
    if(checkpointid == pCheckpoints[0])
    {
        if(InParkour[playerid] == 1)
        {
            if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 556)
            {
                format(string, sizeof(string), "%s has finished Parkour #2 and won $12,000 + 50 XP",GetName(playerid));
                SendClientMessageToAll(0x00FFFFFF, string);

                DestroyVehicle(GetPlayerVehicleID(playerid));
                InParkour[playerid] = 0;
                WinnerText(playerid, "Winner $12,000 ~n~+50 XP");
                GivePlayerCash(playerid, 12000);
                Info[playerid][XP] += 50;
                LevelUp(playerid);
                SpawnPlayerEx(playerid);
            }
        }
    }
    if(checkpointid == pCheckpoints[1])
    {
        if(InParkour[playerid] == 1)
        {
            if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 522)
            {
                new Float:x, Float:y, Float:z, Float:a;
                GetPlayerPos(playerid, x, y, z);
                GetPlayerFacingAngle(playerid, a);
                DestroyVehicle(GetPlayerVehicleID(playerid));
                new veh = CreateVehicle(481, x, y, z, a, 211, 211, 1, 0);
                PutPlayerInVehicle(playerid, veh, 0);
            }
        }
    }
    if(checkpointid == pCheckpoints[2])
    {
        if(InParkour[playerid] == 1)
        {
            if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 481)
            {
                new Float:x, Float:y, Float:z, Float:a;
                GetPlayerPos(playerid, x, y, z);
                GetPlayerFacingAngle(playerid, a);
                DestroyVehicle(GetPlayerVehicleID(playerid));
                new veh = CreateVehicle(522, x, y, z, a, 211, 1, 1, 0);
                PutPlayerInVehicle(playerid, veh, 0);
            }
        }
    }   
    if(checkpointid == pCheckpoints[3])
    {
        if(InParkour[playerid] == 1)
        {
            if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 522)
            {
                format(string, sizeof(string), "%s has finished Parkour #4 and won $16,000 + 100 XP", GetName(playerid));
                SendClientMessageToAll(0x00FFFFFF, string);
                GivePlayerCash(playerid, 16000);
                DestroyVehicle(GetPlayerVehicleID(playerid));
                Info[playerid][XP] += 100;
                LevelUp(playerid);
                InParkour[playerid] = 0;
                WinnerText(playerid, "Winner $16,000 ~n~+100XP");
                SpawnPlayerEx(playerid);
            }
        }
    }
    if(checkpointid == pCheckpoints[4])
    {
        if(InParkour[playerid] == 1)
        {
            if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 481)
            {
                format(string, sizeof(string), "%s has finished Parkour #5 and won $8,000 + 25 XP", GetName(playerid));
                SendClientMessageToAll(0x00FFFFFF, string);
                GivePlayerCash(playerid, 8000);
                DestroyVehicle(GetPlayerVehicleID(playerid));
                Info[playerid][XP] += 25;
                LevelUp(playerid);
                InParkour[playerid] = 0;
                WinnerText(playerid, "Winner $8,000 ~n~+25XP");
                SpawnPlayerEx(playerid);
            }
        }
    }
    return 1;
}

public OnActorStreamIn(actorid, forplayerid)
{
    if(actorid == FarmActor)
    {
        ApplyActorAnimation(FarmActor, "DEALER", "DEALER_IDLE", 4.1, true, false, false, false, 0);
    }
    return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
    if(pTeam[playerid] != NO_TEAM)
    {
        if(newinteriorid == 0)
        { 
            for (new i, j = sizeof(g_Turf); i < j; i++) 
            {
                GangZoneShowForPlayer(playerid, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));
            }
        }
    }

    foreach (new i : Player)
    {
        if(Info[i][Spec] == 1)
        {
            if(SpecID[i] == playerid && SpecID[i] != INVALID_PLAYER_ID)
            {
                SetPlayerInterior(i, newinteriorid);
            }
        }
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_LOGIN:
        {
            if(!response) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "{FFFFFF}Welcome back to {9966FF}Explosive Freeroam\n\n{FF0066}Type your password below to login to your game account", "Login", "Quit");
            else if(response)
            {
                new hashpass[129],query[280];
                WP_Hash(hashpass, sizeof(hashpass), inputtext);
                if(!strcmp(hashpass, Info[playerid][Password], false))
                {
                    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `playersdata` WHERE `PlayerName` = '%e' LIMIT 1", GetName(playerid));
                    mysql_tquery(mysql, query, "OnAccountLoad", "i", playerid);
                }
                else
                {
                    attempts[playerid]++;
                    if(attempts[playerid] == 3)
                    {
                        format(query, sizeof(query), "%s has been kicked for 3 failed login attempts", GetName(playerid));
                        SendClientMessageToAll(red, query);
                        DelayKick(playerid);
                        return 0;
                    }
                    else
                    {
                        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "{FF0000}You have entered an incorrect password\n\n{FFFFFF}Type your password below to login", "Login", "Quit");
                    }
                }
            }
        }
        case DIALOG_REGISTER:
        {
            if(!response) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "{FFFFFF}Welcome to {9966FF}Explosive Freeroam\n\n{FF0066}Type your password below to register game account", "Register", "Quit");
            else if(response)
            {
                GetPlayerIp(playerid, Info[playerid][IP], 16);
                WP_Hash(Info[playerid][Password], 129, inputtext);

                ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Email", "{FFFFFF}Enter your email below:", "Register", "");
            }
        }
        case DIALOG_EMAIL: 
        {
            if(!response) return ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Email", "{FFFFFF}Please enter your email address below:", "Register", "");
            else if(response) 
            {
                if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Email", "{FFFFFF}Please enter your email address below:", "Register", "");
                if(!IsValidEmail(inputtext)) return ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, "Email", "{FF0000}Invalid email address!\n\n{FFFFFF}Please enter your email address below:", "Register", "");

                format(Info[playerid][Email], 35, inputtext);

                new query[680], year, c_month, day;
                getdate(year, c_month, day);

                new month[15];
                switch (c_month)
                {
                    case 1: month = "January";
                    case 2: month = "Feburary";
                    case 3: month = "March";
                    case 4: month = "April";
                    case 5: month = "May";
                    case 6: month = "June";
                    case 7: month = "July";
                    case 8: month = "August";
                    case 9: month = "September";
                    case 10: month = "October";
                    case 11: month = "November";
                    case 12: month = "December";
                }

                new register_on[25];                //Ex: 13 July, 2017
                format(register_on, sizeof(register_on), "%02d %s, %d", day, month, year);

                mysql_format(mysql, query, sizeof(query), 
                "INSERT INTO `playersdata` (PlayerName, Password, IP, RegisteredOn, Email, AutoLogin, Level, Money, UGC, Kills, Deaths, Hours, Minutes, \
                Seconds, Marijuana, Cocaine, Premium, PremiumExpires, NameChange, xLevel, XP, Hitman, PlayerTeam, Jetpack, JetpackExpire) \
                VALUES ('%e', '%e', '%e', '%e', '%e', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 255, 0, 0)",
                GetName(playerid), Info[playerid][Password], Info[playerid][IP], register_on, Info[playerid][Email]);
                mysql_tquery(mysql, query, "OnAccountRegister", "i", playerid);
            }
        }
        case DIALOGS+65:
        {
            if(response)
            {
                new string[128];
                GetPVarString(playerid, "SpamMsg", string, 128);

                switch(listitem)
                {
                    case 0: SendClientMessageToAll(yellow, string);
                    case 1: SendClientMessageToAll(WHITE, string);
                    case 2: SendClientMessageToAll(blue, string);
                    case 3: SendClientMessageToAll(red, string);
                    case 4: SendClientMessageToAll(green, string);
                    case 5: SendClientMessageToAll(orange, string);
                    case 6: SendClientMessageToAll(purple, string);
                    case 7: SendClientMessageToAll(pink, string);
                    case 8: SendClientMessageToAll(brown, string);
                    case 9: SendClientMessageToAll(black, string);
                }
            }
        }
        case DIALOG_ATTACHMENTS:
        {
            if(response)
            {
                new string1[10], string2[75]; inindex[playerid] = listitem;
                if(oInfo[playerid][listitem][used1] == false) return ShowModelSelectionMenu(playerid, objectlist, "Select An Object");
                format(string1, sizeof(string1), "Slot %d", listitem+1);
                format(string2, sizeof(string2), "{FFFFFF}You have selected slot %d\n{FFFFFF}Do you wanna remove or edit it?", listitem+1);
                ShowPlayerDialog(playerid, DIALOG_ATTACHMENTS_EDIT, DIALOG_STYLE_MSGBOX, string1, string2, "Edit", "Remove");
            }
        }
        case DIALOG_ATTACHMENTS_EDIT:
        {
            if(response) return EditAttachedObject(playerid, inindex[playerid]);

            RemovePlayerAttachedObject(playerid, inindex[playerid]);
            oInfo[playerid][inindex[playerid]][used1] = false;

            new query[100];

            format(query, sizeof(query), "You have removed object slot %d", inindex[playerid]+1);
            SendClientMessage(playerid, red, query);

            mysql_format(mysql, query, sizeof(query), "DELETE FROM `Attachments` WHERE `ID` = %d AND `Index` = %d", Info[playerid][ID], inindex[playerid]);
            mysql_tquery(mysql, query);
        }
        case DIALOG_ATTACHMENTS_SAVE:
        {
            if(response) 
            {
                SetPlayerAttachedObject(playerid, inindex[playerid], inmodel[playerid], listitem+1);
                oInfo[playerid][inindex[playerid]][index1] = inindex[playerid];
                oInfo[playerid][inindex[playerid]][modelid1] = inmodel[playerid];
                oInfo[playerid][inindex[playerid]][bone1] = listitem+1;
                oInfo[playerid][inindex[playerid]][used1] = true;
                EditAttachedObject(playerid, inindex[playerid]); 
            }
        }
        case DIALOG_RADIOS:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: StopAudioStreamForPlayer(playerid);
                    case 1: CustomR(playerid);
                    case 2: return Listen(playerid,"http://www.surfmusic.de/m3u/pulse-87-ny,12667.m3u");
                    case 3: return Listen(playerid,"http://streaming.radionomy.com/FroZzenRadioStation");
                    case 4: return Listen(playerid,"http://108.61.30.179:4010");
                    case 5: return Listen(playerid,"http://playerservoces.streamtheworld.com/pls/JACK_FM.pls");
                }
            }
        }
        case DIALOGS+114:
        {
           if(response)
           {
               for(new i = 0; i <= TeleCount; i++)
               {
                   if(listitem == i)
                   {
                        if(IsPlayerInAnyVehicle(playerid))
                        {
                            
                            SetVehiclePos(GetPlayerVehicleID(playerid), TeleCoords[i][0], TeleCoords[i][1], TeleCoords[i][2]);
                            LinkVehicleToInterior(GetPlayerVehicleID(playerid), Teleinfo[i][1]);
                            SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), Teleinfo[i][0]);
                            SetPlayerVirtualWorld(playerid, Teleinfo[i][0]);
                            SetPlayerInterior(playerid, Teleinfo[i][1]);
                        }
                        else
                        {
                            SetPlayerPos(playerid, TeleCoords[i][0], TeleCoords[i][1], TeleCoords[i][2]);
                            SetPlayerInterior(playerid, Teleinfo[i][1]);
                            SetPlayerVirtualWorld(playerid, Teleinfo[i][0]);
                        }
                        break;
                   }
               }
           }
        }
        case DIALOGS+115:
        {
           if(response)
           {
                if(strlen(inputtext) < 3 || strlen(inputtext) > 20) return ShowPlayerDialog(playerid, DIALOGS+115, DIALOG_STYLE_INPUT, "Create Teleport","Enter the new teleport name\n{FF0000}*Name length must be between 3 - 20 characters", "Create", "Close");
                new file[100],name[30],SName[40], string[140];
                if(sscanf(inputtext, "s[30]",name)) return ShowPlayerDialog(playerid, DIALOGS+115, DIALOG_STYLE_INPUT, "Create Teleport","Enter the new teleport name\n{FF0000}*Name length must be between 3 - 20 characters", "Create", "Close");
                new Float:X, Float:Y, Float:Z;
                GetPlayerPos(playerid, X, Y, Z);
                SName = name;
                if(strfind(SName," ",true) != -1 )
                {
                    new i = 0;
                    while (SName[i])
                    {
                        if (SName[i] == ' ')
                        SName[i] = '_';
                        i++;
                    }
                }
                format(string,sizeof(string),"%s %f %f %f %d %d\r\n",SName, X, Y, Z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
                format(file, 100, SETTING_PATH, "Teleports");
                new File:JLlog = fopen(file,io_append);
                fwrite(JLlog,string);
                fclose(JLlog);
                TeleName[TeleCount]      = name;
                TeleCoords[TeleCount][0] = X;
                TeleCoords[TeleCount][1] = Y;
                TeleCoords[TeleCount][2] = Z;
                Teleinfo[TeleCount][0]   = GetPlayerVirtualWorld(playerid);
                Teleinfo[TeleCount][1]   = GetPlayerInterior(playerid);
                TeleCount++;
                format(string,sizeof(string),"Teleport created | Name: %s | Positon - X:%0.3f Y: %0.3f Z: %0.3f | Virtual World: %d | Interior: %d",name, X, Y, Z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
                SendClientMessage(playerid,red,string);
           }
        }
        case DIALOG_EVENTS:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: ShowPlayerDialog(playerid, DIALOG_EVENTS+8, DIALOG_STYLE_INPUT, "Event Name", "{FFFFFF}Enter the event name below", "Next", "Close");
                    case 1:
                    {
                        new Float:x, Float:y, Float:z;
                        GetPlayerPos(playerid, x, y, z);

                        eInfo[eSpawnX] = x;
                        eInfo[eSpawnY] = y;
                        eInfo[eSpawnZ] = z;

                        eInfo[eInterior] = GetPlayerInterior(playerid);

                        cmd_cdm(playerid, "");
                    }
                    case 2: ShowPlayerDialog(playerid, DIALOG_EVENTS+9, DIALOG_STYLE_INPUT, "Event Weapon 1", "{FFFFFF}Enter the weapon ID below", "Next", "Close");
                    case 3: ShowPlayerDialog(playerid, DIALOG_EVENTS+10, DIALOG_STYLE_INPUT, "Event Weapon 2", "{FFFFFF}Enter the weapon ID below", "Next", "Close");
                    case 4: ShowPlayerDialog(playerid, DIALOG_EVENTS+11, DIALOG_STYLE_INPUT, "Event Price", "{FFFFFF}Enter the event price below", "Next", "Close");
                    case 5: ShowPlayerDialog(playerid, DIALOG_EVENTS+12, DIALOG_STYLE_INPUT, "Event Prize", "{FFFFFF}Enter the event prize below", "Next", "Close");
                    case 6: 
                    {
                        if(eInfo[Headshot] == 0)
                        {
                            eInfo[Headshot] = 1;
                            cmd_cdm(playerid, "");
                        }
                        else if(eInfo[Headshot] == 1)
                        {
                            eInfo[Headshot] = 0;
                            cmd_cdm(playerid, "");
                        }
                    }
                    case 7:
                    {
                        new string[128];
                        format(string, sizeof(string), "Type /event to join event %s for $%s", eInfo[eName], cNumber(eInfo[Price]));
                        SendClientMessageToAll(0x00FFFFFF, string);

                        eInfo[Type] = EVENT_DM;
                    }
                    case 8:
                    {
                        format(eInfo[eName], 15, "");
                        eInfo[Type] = EVENT_NONE;

                        eInfo[EventStarted] = false;

                        eInfo[Price] = 0;
                        eInfo[Prize] = 0;

                        eInfo[eWeapon1] = 0;
                        eInfo[eWeapon2] = 0;
                        eInfo[eInterior] = 0;
                        eInfo[Headshot] = 0;

                        eInfo[eSpawnX] = 0;
                        eInfo[eSpawnY] = 0;
                        eInfo[eSpawnZ] = 0;

                        eInfo[eSX] = 0;
                        eInfo[eSY] = 0;
                        eInfo[eSZ] = 0;

                        EventBalance = 0;
                    }
                }
            }
        }
        case DIALOG_EVENTS+8:
        {
            if(response)
            {
                format(eInfo[eName], 24, inputtext);

                cmd_cdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+9:
        {
            if(response)
            {
                if(strval(inputtext) == -1) return eInfo[eWeapon1] = 0;
                if(strval(inputtext) <0 || strval(inputtext)>46) return SCM(playerid,red, "Invalid ID");
                eInfo[eWeapon1] = strval(inputtext);

                cmd_cdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+10:
        {
            if(response)
            {
                if(strval(inputtext) == -1) return eInfo[eWeapon2] = 0;
                if(strval(inputtext) < 0 || strval(inputtext) > 46) return SCM(playerid,red, "Invalid ID");
                eInfo[eWeapon2] = strval(inputtext);

                cmd_cdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+11:
        {
            if(response)
            {
                eInfo[Price] = strval(inputtext);

                cmd_cdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+12:
        {
            if(response)
            {
                eInfo[Prize] = strval(inputtext);

                cmd_cdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+1:
        {
            if(response)
            {
                new Float:x, Float:y, Float:z;
                GetPlayerPos(playerid, x, y, z);

                switch(listitem)
                {
                    case 0: ShowPlayerDialog(playerid, DIALOG_EVENTS+2, DIALOG_STYLE_INPUT, "Event Name", "{FFFFFF}Enter the event name below", "Next", "Close");
                    case 1:
                    {
                        eInfo[eInterior] = GetPlayerInterior(playerid);
                        eInfo[eSpawnX] = x;
                        eInfo[eSpawnY] = y;
                        eInfo[eSpawnZ] = z;

                        cmd_ctdm(playerid, "");
                    }
                    case 2:
                    {
                        eInfo[eInterior] = GetPlayerInterior(playerid);
                        eInfo[eSX] = x;
                        eInfo[eSY] = y;
                        eInfo[eSZ] = z;

                        cmd_ctdm(playerid, "");
                    }
                    case 3: ShowPlayerDialog(playerid, DIALOG_EVENTS+3, DIALOG_STYLE_INPUT, "Event Weapon 1", "{FFFFFF}Enter the weapon ID below", "Next", "Close");
                    case 4: ShowPlayerDialog(playerid, DIALOG_EVENTS+4, DIALOG_STYLE_INPUT, "Event Weapon 2", "{FFFFFF}Enter the weapon ID below", "Next", "Close");
                    case 5: ShowPlayerDialog(playerid, DIALOG_EVENTS+5, DIALOG_STYLE_INPUT, "Event Price", "{FFFFFF}Enter the event price below", "Next", "Close");
                    case 6: ShowPlayerDialog(playerid, DIALOG_EVENTS+6, DIALOG_STYLE_INPUT, "Event Prize", "{FFFFFF}Enter the event prize below", "Next", "Close");
                    case 7: 
                    {
                        if(eInfo[Headshot] == 0)
                        {
                            eInfo[Headshot] = 1;
                            cmd_ctdm(playerid, "");
                        }
                        else if(eInfo[Headshot] == 1)
                        {
                            eInfo[Headshot] = 0;
                            cmd_ctdm(playerid, "");
                        }
                    }
                    case 8:
                    {
                        new string[128];
                        format(string, sizeof(string), "Type /event to join event %s for $%s", eInfo[eName], cNumber(eInfo[Price]));
                        SendClientMessageToAll(0x00FFFFFF, string);

                        eInfo[Type] = EVENT_TDM;
                    }
                    case 9:
                    {
                        format(eInfo[eName], 15, "");
                        eInfo[Type] = EVENT_NONE;

                        eInfo[EventStarted] = false;

                        eInfo[Price] = 0;
                        eInfo[Prize] = 0;

                        eInfo[eWeapon1] = 0;
                        eInfo[eWeapon2] = 0;
                        eInfo[Headshot] = 0;

                        eInfo[eSpawnX] = 0;
                        eInfo[eSpawnY] = 0;
                        eInfo[eSpawnZ] = 0;

                        eInfo[eSX] = 0;
                        eInfo[eSY] = 0;
                        eInfo[eSZ] = 0;

                        EventBalance = 0;
                    }
                }
            }
        }
        case DIALOG_EVENTS+2:
        {
            if(response)
            {
                format(eInfo[eName], 24, inputtext);

                cmd_ctdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+3:
        {
            if(response)
            {
                if(strval(inputtext) == -1) return eInfo[eWeapon1] = 0;
                if(strval(inputtext) <0 || strval(inputtext)>46) return SCM(playerid,red, "Invalid ID");
                eInfo[eWeapon1] = strval(inputtext);

                cmd_ctdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+4:
        {
            if(response)
            { 
                if(strval(inputtext) == -1) return eInfo[eWeapon2] = 0;
                if(strval(inputtext) < 0 || strval(inputtext) > 46) return SCM(playerid,red, "Invalid ID");
                eInfo[eWeapon2] = strval(inputtext);

                cmd_ctdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+5:
        {
            if(response)
            {
                eInfo[Price] = strval(inputtext);

                cmd_ctdm(playerid, "");
            }
        }
        case DIALOG_EVENTS+6:
        {
            if(response)
            {
                eInfo[Prize] = strval(inputtext);

                cmd_ctdm(playerid, "");
            }
        }
        case DIALOG_DM:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: return cmd_deagledm(playerid);
                    case 1: return cmd_microdm(playerid);
                    case 2: return cmd_minigundm(playerid);
                    case 3: return cmd_m4dm(playerid);
                    case 4: return cmd_sawndm(playerid);
                    case 5: return cmd_sniperdm(playerid);
                    case 6: return cmd_combatdm(playerid);
                    case 7: return cmd_jetpackdm(playerid);
                }
            }
        }
        case DIALOGS+811:
        {
            if(response)
            {
                new str[80];
                new id = GetPVarInt(playerid,"ClickedPlayer");
                format(str, sizeof(str), "%d %s", id, inputtext);
                cmd_pm(playerid, str);
            }
        }
        case DIALOG_PARKOURS:
        {
            if(response)
            {
                if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the parkour while you are in a gang zone");
                if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
                if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
                if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InParkour[playerid] == 1) return SCM(playerid, red, "You are already in parkour");

                GetPlayerSpawnEx(playerid);
                SetPlayerHealthEx(playerid, 100.0);
                if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

                switch(listitem)
                {
                    case 0: 
                    {
                        InParkour[playerid] = 1;
                        SetPlayerPosition(playerid, 2986.40820312, -1845.10839844, 601.70886230, 0);
                        GameTextForPlayer(playerid,"~w~PARKOUR 1", 2000, 3);

                        UpdateTeleportInfo(playerid, "has joined Parkour #1");
                    }
                    case 1: 
                    {
                        InParkour[playerid] = 1;

                        new veh[MAX_PLAYERS];
                        veh[playerid] = CreateVehicle(556, 495.557922, -1883.191895, 3.198795+2, 166, -1, -1, 5);
                        PutPlayerInVehicle(playerid, veh[playerid], 0);

                        GameTextForPlayer(playerid,"~w~PARKOUR 2", 2000, 3);

                        UpdateTeleportInfo(playerid, "has joined Parkour #2");
                    }
                    case 2: 
                    {
                        InParkour[playerid] = 1;
                        SetPlayerPosition(playerid, 2588.4602, -1348.2028, 232.2472, 181.5854); 
                        GameTextForPlayer(playerid,"~w~PARKOUR 3", 2000, 3);

                        UpdateTeleportInfo(playerid, "has joined Parkour #3");
                    }
                    case 3: 
                    {
                        InParkour[playerid] = 1;
                        SetPlayerPosition(playerid, 2826.1584, -30.1166, 577.8858, 266.0881);
                        pVehicles[playerid] = CreateVehicle(522, 2826.1584, -30.1166, 577.8858, 266.0881, 211, 1, 10, 0);
                        PutPlayerInVehicle(playerid, pVehicles[playerid], 0);
                        GameTextForPlayer(playerid,"~w~PARKOUR 4", 2000, 3);

                        UpdateTeleportInfo(playerid, "has joined Parkour #4");
                    }
                    case 4:
                    {
                        InParkour[playerid] = 1;
                        SetPlayerPosition(playerid, 2859.4858, -1877.4391, 11.1124, 269.1422);
                        pVehicles[playerid] = CreateVehicle(481, 2859.4858, -1877.4391, 11.1124, 269.1422, 211, 1, 10, 0);
                        PutPlayerInVehicle(playerid, pVehicles[playerid], 0);
                        GameTextForPlayer(playerid,"~w~PARKOUR 5", 2000, 3);

                        UpdateTeleportInfo(playerid, "has joined Parkour #5");
                    }
                    case 5:
                    {
                        InParkour[playerid] = 1;
                        SetPlayerPosition(playerid, 2011.4167, 1387.4583, 9.2578, 90.5639);
                        GameTextForPlayer(playerid,"~w~PARKOUR 6", 2000, 3);

                        UpdateTeleportInfo(playerid, "has joined Parkour #6");
                    }
                }
                SCM(playerid, red, "Type /leaveparkour to leave the parkour");
            }
        }
        case DIALOG_SKYDIVE:
        {
            if(response)
            {
                if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the skydive while you are in a gang zone");
                if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
                if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
                if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InSkydive[playerid] == 1) return SCM(playerid, red, "You are already in the skydive");

                GetPlayerSpawnEx(playerid);
                SetPlayerHealthEx(playerid, 100.0);
                if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

                switch(listitem)
                {
                    case 0:
                    {
                        InSkydive[playerid] = 1;
                        SetPlayerPosition(playerid, 3501.5151, 492.8157, 1964.7841, 3.0303);
                        SetCameraBehindPlayer(playerid);
                        ResetPlayerWeaponsEx(playerid);
                        GivePlayerWeaponEx(playerid, 46, 1);
                        SetPlayerHealthEx(playerid, 100);
                        GameTextForPlayer(playerid, "~w~Skydive 1", 3000, 3);

                        UpdateTeleportInfo(playerid, "has joined Skydive #1");
                    }
                    case 1:
                    {
                        InSkydive[playerid] = 1;
                        SetPlayerPosition(playerid, -7.1330, 7532.6973, 3044.9700, 319.1928);
                        SetCameraBehindPlayer(playerid);
                        ResetPlayerWeaponsEx(playerid);
                        GivePlayerWeaponEx(playerid, 46, 1);
                        SetPlayerHealthEx(playerid, 100);
                        GameTextForPlayer(playerid, "~w~Skydive 2", 3000, 3);

                        UpdateTeleportInfo(playerid, "has joined Skydive #2");
                    }
                    case 2:
                    {
                        InSkydive[playerid] = 1;
                        SetPlayerPosition(playerid, 1432.0454, 2918.2788, 1090.3348, 269.1366);
                        SetCameraBehindPlayer(playerid);
                        ResetPlayerWeaponsEx(playerid);
                        GivePlayerWeaponEx(playerid, 46, 1);
                        SetPlayerHealthEx(playerid, 100);
                        GameTextForPlayer(playerid, "~w~Skydive 3", 3000, 3);

                        UpdateTeleportInfo(playerid, "has joined Skydive #3");
                    }
                }
                SCM(playerid, red, "Type /leaveskydive to leave the skydive");
            }
        }
        case DIALOG_DERBY:
        {
            if(response)
            {
                if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't start the derby while you are in a gang zone");
                if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
                if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(DerbyGame != NON_DERBY) return SCM(playerid, red, "There is already derby in progress");
                if(DerbyStarted == true) return SCM(playerid, red, "There is already derby in progress");
                if(InDerby[playerid] == 1) return SCM(playerid, red, "You are already in derby");

                GetPlayerSpawnEx(playerid);
                if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

                new string[128];
                switch(listitem)
                {
                    case 0:
                    {
                        ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
                        DerbyGame = RANCHERS_DERBY;
                        InDerby[playerid] = 1;
                        PlayersInDerby += 1;

                        SpawnPlayerInDerby(playerid, 489, RanchersDerby, 6);
                        PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
                        SetVehicleHealth(DerbyVehicles[playerid],20000);
                        TogglePlayerControllable(playerid, false);

                        
                        format(string, sizeof(string), "%s has started Ranchers Derby - Type /joinderby to join it!", GetName(playerid));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        SendClientMessage(playerid, green, "Derby will start in 30 seconds");
                        SetTimer("DerbyStart", 30 * 1000, false);

                        DerbyCountDownFromAmount = 30;
                        DerbyTimer = SetTimer("DerbyCountDown", 999, true);
                    }
                    case 1:
                    {
                        ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
                        DerbyGame = BULLETS_DERBY;
                        InDerby[playerid] = 1;
                        PlayersInDerby += 1;

                        SpawnPlayerInDerby(playerid, 541, BulletsDerby, 12);
                        PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
                        SetVehicleHealth(DerbyVehicles[playerid],20000);
                        TogglePlayerControllable(playerid, false);

                        format(string, sizeof(string), "%s has started Bullets Derby - Type /joinderby to join it!", GetName(playerid));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        SendClientMessage(playerid, green, "Derby will start in 30 seconds");
                        SetTimer("DerbyStart", 30 * 1000, false);

                        DerbyCountDownFromAmount = 30;
                        DerbyTimer = SetTimer("DerbyCountDown", 999, true);
                    }
                    case 2:
                    {
                        ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
                        DerbyGame = HOTRINGS_DERBY;
                        InDerby[playerid] = 1;
                        PlayersInDerby += 1;

                        SpawnPlayerInDerby(playerid, 503, HotringsDerby, 9);
                        PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
                        SetVehicleHealth(DerbyVehicles[playerid],20000);
                        TogglePlayerControllable(playerid, false);

                        format(string, sizeof(string), "%s has started Hotrings Derby - Type /joinderby to join it!", GetName(playerid));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        SendClientMessage(playerid, green, "Derby will start in 30 seconds");
                        SetTimer("DerbyStart", 30 * 1000, false);

                        DerbyCountDownFromAmount = 30;
                        DerbyTimer = SetTimer("DerbyCountDown", 999, true);
                    }
                    case 3:
                    {
                        ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
                        DerbyGame = INFERNUS_DERBY;
                        InDerby[playerid] = 1;
                        PlayersInDerby += 1;

                        SpawnPlayerInDerby(playerid, 411, RanchersDerby, 7);
                        PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
                        SetVehicleHealth(DerbyVehicles[playerid],20000);
                        TogglePlayerControllable(playerid, false);

                        format(string, sizeof(string), "%s has started Infernus Derby - Type /joinderby to join it!", GetName(playerid));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        SendClientMessage(playerid, green, "Derby will start in 30 seconds");
                        SetTimer("DerbyStart", 30 * 1000, false);

                        DerbyCountDownFromAmount = 30;
                        DerbyTimer = SetTimer("DerbyCountDown", 999, true);
                    }
                }
                DerbyTDTimer = SetTimer("DerbyTextDraws", 999, 1);
                SCM(playerid, red, "Type /leavederby to leave the derby");
            }
        }
        case DIALOG_TDM:
        {
            if(response)
            {
                if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't start the TDM while you are in a gang zone");
                if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
                if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
                if(InTDM[playerid] == 1) return SCM(playerid, red, "You are already in the TDM");
                if(TDMStarted == true) return SCM(playerid, red, "There is already TDM in progress");

                TDMStarted = true;
                GetPlayerSpawnEx(playerid);
                if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

                new string[128];
                switch(listitem)
                {
                    case 0:
                    {
                        ShowInfoBox(playerid, 0x00000088, 7, "In this TDM you have to kill the enemy team to win the match");
                        TDMGame = TDM_ONE;
                        InTDM[playerid] = 1;
                        PlayersInTDM += 1;

                        TDMCountDownFromAmount = 30;
                        TDMTimer = SetTimer("TDMCountDown", 999, true);

                        ResetPlayerWeaponsEx(playerid);
                        SetPlayerHealthEx(playerid, 100);
                        SetPlayerArmourEx(playerid, 100);
                        switch(TeamBalance)
                        {
                            case 0:
                            {
                                PlayerTeamOne += 1;
                                TeamBalance = 1;
                                SetPlayerTeam(playerid, TDMTeamOne);
                                SetPlayerPosition(playerid,970.3297, -2708.9780, 19.7077, 266.6773);
                                ResetPlayerWeaponsEx(playerid);
                                TogglePlayerControllable(playerid, false);
                            }
                            case 1:
                            {
                                PlayerTeamTwo += 1;
                                TeamBalance = 0;
                                SetPlayerTeam(playerid, TDMTeamTwo);
                                SetPlayerPosition(playerid, 1047.9230, -2708.3545, 19.7077, 92.1489);
                                ResetPlayerWeaponsEx(playerid);
                                TogglePlayerControllable(playerid, false);
                            }
                        }
                        
                        format(string, sizeof(string), "%s has started Team Deathmatch #1 - Type /jointdm to join it!", GetName(playerid));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        SendClientMessage(playerid, green, "TDM will start in 30 seconds");
                        SetTimer("StartTDM", 30 * 1000, false);
                    }
                    case 1:
                    {
                        ShowInfoBox(playerid, 0x00000088, 7, "In this TDM you have to kill the enemy team to win the match");
                        TDMGame = TDM_TWO;
                        InTDM[playerid] = 1;
                        PlayersInTDM += 1;

                        TDMCountDownFromAmount = 30;
                        TDMTimer = SetTimer("TDMCountDown", 999, true);

                        ResetPlayerWeaponsEx(playerid);
                        SetPlayerHealthEx(playerid, 100);
                        SetPlayerArmourEx(playerid, 100);
                        switch(TeamBalance)
                        {
                            case 0:
                            {
                                PlayerTeamOne += 1;
                                TeamBalance = 1;
                                SetPlayerTeam(playerid, TDMTeamOne);
                                SetPlayerPosition(playerid, 172.1281, 1886.1561, 1101.2722, 0.3179);
                                ResetPlayerWeaponsEx(playerid);
                                TogglePlayerControllable(playerid, false);
                            }
                            case 1:
                            {
                                PlayerTeamTwo += 1;
                                TeamBalance = 0;
                                SetPlayerTeam(playerid, TDMTeamTwo);
                                SetPlayerPosition(playerid, 185.7635, 1981.8048, 1101.2722, 179.5225);
                                ResetPlayerWeaponsEx(playerid);
                                TogglePlayerControllable(playerid, false);
                            }
                        }

                        format(string, sizeof(string), "%s has started Team Deathmatch #2 - Type /jointdm to join it!", GetName(playerid));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        SendClientMessage(playerid, green, "TDM will start in 30 seconds");
                        SetTimer("StartTDM", 30 * 1000, false);
                    }
                }
                TDTimer = SetTimer("TDMTextDraws", 999, 1);
                SCM(playerid, red, "Type /leavetdm to leave the TDM");
            }
        }
		case DIALOG_SKIN_TAKE:
		{
			if(response)
			{
				new query[128], Cache:skin;
		    	mysql_format(mysql, query, sizeof(query), "SELECT * FROM `SkinData` WHERE `ID` = %d ORDER BY `SkinID` ASC", Info[playerid][ID]);
				skin = mysql_query(mysql, query);
				new rows = cache_num_rows();
				if(rows) 
				{
		  			new skinid;
		  			skinid = cache_get_field_content_int(listitem, "SkinID");
		  			SetPlayerSkin(playerid, skinid);

		  			new Float:X, Float:Y, Float:Z;
		  			GetPlayerPos(playerid, X, Y, Z);

		  			SetPlayerPos(playerid, X, Y, Z+1);

					format(query, sizeof(query), "You've selected skin %d (%s) from your inventory", skinid, GetSkinName(skinid));
					SendClientMessage(playerid, red, query);
				}
				else SendClientMessage(playerid, red, "Can not find that skin");
				cache_delete(skin);
			}
		}
        case DIALOG_CMDS:
        {
            if(response)
            {
                new string[700];
                strcat(string, "{00FF00}Friends\n");
                strcat(string, "{FFFFFF}/friend /unfriend /friendchat /friends\n\n");
                strcat(string, "{00FF00}Animations & Items\n");
                strcat(string, "{FFFFFF}/animations /attachments\n\n");
                strcat(string, "{00FF00}Gangs\n");
                strcat(string, "{FFFFFF}/attack /gangs /gang /boss /gangkick /gangbackup\n\n");
                strcat(string, "{00FF00}Houses\n");
                strcat(string, "{FFFFFF}/buyhouse(LALT) /house /houses /houseinfo /housekick /mykeys\n{FFFFFF}/givehousekeys /takehousekeys\n\n");
                strcat(string, "{00FF00}Properties\n");
                strcat(string, "{FFFFFF}/buyproperty(LALT) /propertyinfo /properties");
                ShowPlayerDialog(playerid, DIALOG_CMDS+1, DIALOG_STYLE_MSGBOX, "Server Commands", string, "Close", "");
            }
        }
		case DIALOG_SHOP:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
					{
						ShowPlayerDialog(playerid, DIALOG_SHOP+1, DIALOG_STYLE_LIST, "Premium Account", "{FFFFFF}Premium account for 5 days {FF0066}1.50 UGC\n\
																										 {FFFFFF}Premium account for 30 days + $1,000,000 {FF0066}5.00 UGC\n\
																										 {FFFFFF}Premium account for 90 days + $5,000,000 {FF0066}10.0 UGC", "Buy", "Close");
					}
					case 1:
					{
						ShowPlayerDialog(playerid, DIALOG_SHOP+2, DIALOG_STYLE_LIST, "Game Money", "{FFFFFF}Game money - $100,000 {FF0066}0.25 UGC\n\
																									{FFFFFF}Game money - $225,000 {FF0066}0.50 UGC\n\
																									{FFFFFF}Game money - $500,000 {FF0066}1.00 UGC\n\
																									{FFFFFF}Game money - $825,000 {FF0066}1.50 UGC\n\
																									{FFFFFF}Game money - $1,500,000 {FF0066}2.50 UGC\n\
																									{FFFFFF}Game money - $3,255,000 {FF0066}5.00 UGC\n\
																									{FFFFFF}Game money - $7,000,000 {FF0066}10.00 UGC\n\
																									{FFFFFF}Game money - $15,000,000 {FF0066}20.00 UGC\n\
																									{FFFFFF}Game money - $24,000,000 {FF0066}30.00 UGC\n", "Buy", "Close");
					}
					case 2:
					{
						ShowPlayerDialog(playerid, DIALOG_SHOP+3, DIALOG_STYLE_LIST, "Name Change", "{FFFFFF}Name change {FF0066}1.50 UGC", "Buy", "Close");
					}
					case 3:
					{
						ShowPlayerDialog(playerid, DIALOG_SHOP+4, DIALOG_STYLE_LIST, "Fight Styles", "{FFFFFF}Fight style - Normal {FF0066}Free\n\
																									  {FFFFFF}Fight style - Box {FF0066}0.25 UGC\n\
																									  {FFFFFF}Fight style - Kung Fu {FF0066}0.25 UGC\n\
																									  {FFFFFF}Fight style - Knee {FF0066}0.25 UGC\n", "Buy", "Close");
					}
					case 4:
					{
						ShowPlayerDialog(playerid, DIALOG_SHOP+5, DIALOG_STYLE_LIST, "Health & Armour", "{FFFFFF}Full health {FF0066}0.25 UGC\n{FFFFFF}Full armour {FF0066}0.25 UGC", "Buy", "Close");
					}
                    case 5:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+6, DIALOG_STYLE_LIST, "Marijuana", "{FFFFFF}100 grams of marijuana {FF0066}0.25 UGC\n\
                                                                                                   {FFFFFF}250 grams of marijuana {FF0066}0.50 UGC\n\
                                                                                                   {FFFFFF}1000 grams of marijuana {FF0066}1.50 UGC\n\
                                                                                                   {FFFFFF}2500 grams of marijuana {FF0066}3.00 UGC", "Buy", "Close");
                    }
                    case 6:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+7, DIALOG_STYLE_LIST, "Cocaine", "{FFFFFF}50 grams of cocaine {FF0066}0.25 UGC\n\
                                                                                                   {FFFFFF}125 grams of cocaine {FF0066}0.50 UGC\n\
                                                                                                   {FFFFFF}500 grams of cocaine {FF0066}1.50 UGC\n\
                                                                                                   {FFFFFF}1250 grams of cocaine {FF0066}3.00 UGC", "Buy", "Close");
                    }
                    case 7:
                    {
                        new MAIN[1800];
                
                        MAIN = "Weapon\tAmmo\tUGC\n";
                        
                        for(new i; i < sizeof(WeaponShop); i++)
                        {
                            new Float:value = float(WeaponShop[i][WeaponPrice]) / 100;
                            format(MAIN, sizeof(MAIN), "%s{FFFFFF}%s\t%i\t{FF0066}%0.2f\n", MAIN, WeaponShop[i][WeaponName], WeaponShop[i][WeaponAmmo], value);
                        } 

                        ShowPlayerDialog(playerid, DIALOG_SHOP+8, DIALOG_STYLE_TABLIST_HEADERS, "Weapons", MAIN, "Buy", "Close");
                    }
					case 8:
					{
						if(Info[playerid][UGC] < 5) return SCM(playerid, red, "You don't have enough UGC (0.50 UGC)");

						ShowPlayerDialog(playerid, DIALOG_SHOP+9, DIALOG_STYLE_INPUT, "Choose Skin", "Please enter the skin ID you want to buy", "Next", "Close");
					}
                    case 9:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+10, DIALOG_STYLE_LIST, "Jetpack", "{FFFFFF}Jetpack for 5 days {FF0066}1.00 UGC\n\
                                                                                                  {FFFFFF}Jetpack for 30 days {FF0066}3.00 UGC\n\
                                                                                                  {FFFFFF}Jetpack for 90 days {FF0066}5.00 UGC", "Buy", "Close");
                    }
                    case 10:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+11, DIALOG_STYLE_LIST, "Property Renew", "{FFFFFF}Property renew for 5 days {FF0066}0.50 UGC\n\
                                                                                                         {FFFFFF}Property renew for 30 days {FF0066}1.50 UGC\n\
                                                                                                         {FFFFFF}Property renew for 90 days {FF0066}3.00 UGC", "Buy", "Close");
                    }
                    case 11:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+12, DIALOG_STYLE_LIST, "House Renew", "{FFFFFF}House renew for 5 days {FF0066}0.50 UGC\n\
                                                                                                      {FFFFFF}House renew for 30 days {FF0066}1.50 UGC\n\
                                                                                                      {FFFFFF}House renew for 90 days {FF0066}3.00 UGC", "Buy", "Close");
                    }
                    case 12:
                    {
                        new string[84], str[800];
                        for(new i; i < sizeof(VehicleWheels); i++)
                        {
                            new Float:value = float(VehicleWheels[i][WheelPrice]) / 100;

                            format(string, sizeof(string), "{FFFFFF}%s {FF0066}%0.2f UGC\n", VehicleWheels[i][WheelName], value);
                            strcat(str, string);
                        }
                        ShowPlayerDialog(playerid, DIALOG_SHOP+13, DIALOG_STYLE_LIST, "Wheels", str, "Buy", "Close");
                    }
                    case 13:
                    {
                        new string[84], str[500];
                        for(new i; i < sizeof(VehicleSpoiler); i++)
                        {
                            new Float:value = float(VehicleSpoiler[i][SpoilerPrice]) / 100;

                            format(string, sizeof(string), "{FFFFFF}%s {FF0066}%0.2f UGC\n", VehicleSpoiler[i][SpoilerName], value);
                            strcat(str, string);
                        }
                        ShowPlayerDialog(playerid, DIALOG_SHOP+14, DIALOG_STYLE_LIST, "Spoilers", str, "Buy", "Close");
                    }
                    case 14:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+15, DIALOG_STYLE_LIST, "Nitro", "{FFFFFF}Nitro 2x {FF0066}0.25 UGC\n{FFFFFF}Nitro 5x {FF0066} 0.50 UGC\n\
                        {FFFFFF}Nitro 10x {FF0066}0.75 UGC", "Buy", "Close");
                    }
                    case 15:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+16, DIALOG_STYLE_LIST, "Nitro", "{FFFFFF}Hydraulics {FF0066}0.25 UGC", "Buy", "Close");
                    }
                    case 16:
                    {
                        ShowPlayerDialog(playerid, DIALOG_SHOP+17, DIALOG_STYLE_LIST, "Double Jump", "Double jump for 5 days {FF0066}0.50 UGC\n\
                                                                                                      Double jump for 30 days {FF0066}1.50 UGC\n\
                                                                                                      Double jump for 90 days {FF0066}3.00 UGC", "Buy", "Close");   
                    }
				}
			}
		}
		case DIALOG_SHOP+1:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
					{
						if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][PremiumExpires] == 0) Info[playerid][PremiumExpires] = gettime() + 5*86400;
						else Info[playerid][PremiumExpires] = Info[playerid][PremiumExpires] + (5*86400);

						Info[playerid][Premium] = 1;
						Info[playerid][UGC] -= 150;
                        
                        SaveLog(playerid, "has bought premium for 5 days");

                        SavePlayerData(playerid, 0, 1);
						ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations!", "{FF0066}Congratulations! {FFFFFF}You have purchased Premium Account for 5 days", "Close", "");
					}
					case 1:
					{
						if(Info[playerid][UGC] < 500) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						if(Info[playerid][PremiumExpires] == 0) Info[playerid][PremiumExpires] = gettime() + 30*86400;
                        else Info[playerid][PremiumExpires] = Info[playerid][PremiumExpires] + (30*86400);

						Info[playerid][Premium] = 1;
						Info[playerid][UGC] -= 500;
                        GivePlayerCash(playerid, 1000000);

                        SaveLog(playerid, "has bought premium for 30 days");

                        SavePlayerData(playerid, 0, 1);
						ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations!", "{FF0066}Congratulations! {FFFFFF}You have purchased Premium Account for 30 days", "Close", "");
					}
					case 2:
					{
						if(Info[playerid][UGC] < 1000) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						if(Info[playerid][PremiumExpires] == 0) Info[playerid][PremiumExpires] = gettime() + 90*86400;
                        else Info[playerid][PremiumExpires] = Info[playerid][PremiumExpires] + (90*86400);

						Info[playerid][Premium] = 1;
						Info[playerid][UGC] -= 1000;
                        GivePlayerCash(playerid, 5000000);

                        SaveLog(playerid, "has bought premium for 90 days");

                        SavePlayerData(playerid, 0, 1);
						ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations!", "{FF0066}Congratulations! {FFFFFF}You have purchased Premium Account for 90 days", "Close", "");
						
					}
				}
			}
		}
		case DIALOG_SHOP+2:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
					{
						if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 25;
						GivePlayerCash(playerid, 100000);
						WinnerText(playerid, "+ $100,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 0.25 UGC");
					}
					case 1:
					{
						if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 50;
						GivePlayerCash(playerid, 225000);
						WinnerText(playerid, "+ $255,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 0.50 UGC");
					}
					case 2:
					{
						if(Info[playerid][UGC] < 100) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 100;
						GivePlayerCash(playerid, 500000);
						WinnerText(playerid, "+ $500,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 1.00 UGC");
					}
					case 3:
					{
						if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 150;
						GivePlayerCash(playerid, 825000);
						WinnerText(playerid, "+ $825,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 1.50 UGC");
					}
					case 4:
					{
						if(Info[playerid][UGC] < 250) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 250;
						GivePlayerCash(playerid, 1500000);
						WinnerText(playerid, "+ $1,500,000");
                        SavePlayerData(playerid, 0, 1);
					}
					case 5:
					{
						if(Info[playerid][UGC] < 500) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 500;
						GivePlayerCash(playerid, 3255000);
						WinnerText(playerid, "+ $3,255,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 5.00 UGC");
					}
					case 6:
					{
						if(Info[playerid][UGC] < 1000) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 1000;
						GivePlayerCash(playerid, 7000000);
						WinnerText(playerid, "+ $7,000,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 10.00 UGC");
					}
					case 7:
					{
						if(Info[playerid][UGC] < 2000) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 2000;
						GivePlayerCash(playerid, 15000000);
						WinnerText(playerid, "+ $15,000,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 20.00 UGC");
					}
					case 8:
					{
						if(Info[playerid][UGC] < 3000) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						Info[playerid][UGC] -= 3000;
						GivePlayerCash(playerid, 24000000);
						WinnerText(playerid, "+ $24,000,000");
                        SavePlayerData(playerid, 0, 1);

                        SaveLog(playerid, "has bought in-game money with 30.00 UGC");
					}
				}
			}
		}
		case DIALOG_SHOP+3:
		{
			if(response)
			{
                if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

				Info[playerid][NameChange] = 1;
				Info[playerid][UGC] -= 150;

                SaveLog(playerid, "has bought name change");

                SavePlayerData(playerid, 0, 1);
				ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Name Change", "Close", "");
			}
		}
		case DIALOG_SHOP+4:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
					{
						if(GetPlayerFightingStyle(playerid) == 4) return SCM(playerid, red, "You already have that fight style");

						SetPlayerFightingStyle(playerid, 4);
						Info[playerid][FightStyle] = 4;
                        SavePlayerData(playerid, 0, 1);

					    ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Fight Style - Normal", "Close", "");
                    }
					case 1:
					{
						if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
						if(GetPlayerFightingStyle(playerid) == 5) return SCM(playerid, red, "You already have that fight style");

						SetPlayerFightingStyle(playerid, 5);
						Info[playerid][FightStyle] = 5;
						Info[playerid][UGC] -= 25;
                        SavePlayerData(playerid, 0, 1);

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Fight Style - Box", "Close", "");
					}
					case 2:
					{
						if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
						if(GetPlayerFightingStyle(playerid) == 6) return SCM(playerid, red, "You already have that fight style");

						SetPlayerFightingStyle(playerid, 6);
						Info[playerid][FightStyle] = 6;
						Info[playerid][UGC] -= 25;
                        SavePlayerData(playerid, 0, 1);

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Fight Style - Kung Fu", "Close", "");
					}
					case 3:
					{
						if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
						if(GetPlayerFightingStyle(playerid) == 7) return SCM(playerid, red, "You already have that fight style");

						SetPlayerFightingStyle(playerid, 7);
						Info[playerid][FightStyle] = 7;
						Info[playerid][UGC] -= 25;
                        SavePlayerData(playerid, 0, 1);

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Fight Style - Knee", "Close", "");
					}
				}
                SaveLog(playerid, "has bought fight style");
			}
		}
		case DIALOG_SHOP+5:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0:
					{
						if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						SetPlayerHealthEx(playerid, 100.0);
						Info[playerid][UGC] -= 25;
                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought full health from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Full Health", "Close", "");
					}
					case 1:
					{
						if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

						SetPlayerArmourEx(playerid, 100.0);
						Info[playerid][UGC] -= 25;
                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought full armour from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Full Armour", "Close", "");
					}
				}
			}
		}
        case DIALOG_SHOP+6:
        {
            if(response)
            {
                switch(listitem)
                { 
                    case 0: 
                    {
                        if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Marijuana] += 100;
                        Info[playerid][UGC] -= 25;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 100 grams of marijuana from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}100 grams of marijuana", "Close", "");
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Marijuana] += 250;
                        Info[playerid][UGC] -= 50;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 250 grams of marijuana from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}250 grams of marijuana", "Close", "");
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Marijuana] += 1000;
                        Info[playerid][UGC] -= 150;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 1000 grams of marijuana from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}1000 grams of marijuana", "Close", "");
                    }
                    case 3: 
                    {
                        if(Info[playerid][UGC] < 300) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Marijuana] += 2500;
                        Info[playerid][UGC] -= 300;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 2500 grams of marijuana from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}2500 grams of marijuana", "Close", "");
                    }
                }
            }
        }
        case DIALOG_SHOP+7:
        {
            if(response)
            {
                switch(listitem)
                { 
                    case 0: 
                    {
                        if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Cocaine] += 50;
                        Info[playerid][UGC] -= 25;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 50 grams of cocaine from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}50 grams of cocaine", "Close", "");
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Cocaine] += 125;
                        Info[playerid][UGC] -= 50;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 125 grams of cocaine from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}125 grams of cocaine", "Close", "");
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Cocaine] += 500;
                        Info[playerid][UGC] -= 150;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 500 grams of cocaine from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}500 grams of cocaine", "Close", "");
                    }
                    case 3: 
                    {
                        if(Info[playerid][UGC] < 300) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        Info[playerid][Cocaine] += 1250;
                        Info[playerid][UGC] -= 300;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought 1250 grams of cocaine from /shop");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}1250 grams of cocaine", "Close", "");
                    }
                }
            }
        }
        case DIALOG_SHOP+8:
        {
            if(response)
            {
                if(Info[playerid][UGC] < WeaponShop[listitem][WeaponPrice]) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                GivePlayerWeaponEx(playerid, WeaponShop[listitem][WeaponID], WeaponShop[listitem][WeaponAmmo]);
                Info[playerid][UGC] -= WeaponShop[listitem][WeaponPrice];

                new string[128];
                format(string, sizeof(string), "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}%s with %d ammo", WeaponShop[listitem][WeaponName], WeaponShop[listitem][WeaponAmmo]);
                ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", string, "Close", "");

                SavePlayerData(playerid, 0, 1);

                format(string, sizeof(string), "has bought %s with %d ammo from /shop", WeaponShop[listitem][WeaponName], WeaponShop[listitem][WeaponAmmo]);
                SaveLog(playerid, string);
            }
        }
		case DIALOG_SHOP+9:
		{
			if(response)
			{
				new string[128];
				PervSkin[playerid] = GetPlayerSkin(playerid);

				BuySkin[playerid] = strval(inputtext);

                if(BuySkin[playerid] == 74) return SCM(playerid, red, "Invalid skin ID");
				if(BuySkin[playerid] < 0 || BuySkin[playerid] > 299) return SCM(playerid, red, "Invalid skin ID (0 - 299)");

				SetPlayerSkin(playerid, BuySkin[playerid]);

				format(string, sizeof(string), "Do you want to buy the skin?\nSkin ID: %d - Price: 0.50 UGC", BuySkin[playerid]);
				ShowPlayerDialog(playerid, DIALOG_SKIN_BUY, DIALOG_STYLE_MSGBOX, "Buy Skin", string, "Buy", "Close");
			}
		}
        case DIALOG_SHOP+10:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(Info[playerid][UGC] < 100) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][JetpackExpire] == 0) Info[playerid][JetpackExpire] = gettime() + 5*86400;
                        else Info[playerid][JetpackExpire] = Info[playerid][JetpackExpire] + (5*86400);

                        Info[playerid][Jetpack] = 1;
                        Info[playerid][UGC] -= 100;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought jetpack for 5 days");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Jetpack for 5 days", "Close", "");
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 300) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][JetpackExpire] == 0) Info[playerid][JetpackExpire] = gettime() + 30*86400;
                        else Info[playerid][JetpackExpire] = Info[playerid][JetpackExpire] + (30*86400);

                        Info[playerid][Jetpack] = 1;
                        Info[playerid][UGC] -= 300;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought jetpack for 30 days");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Jetpack for 30 days", "Close", "");
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 500) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][JetpackExpire] == 0) Info[playerid][JetpackExpire] = gettime() + 90*86400;
                        else Info[playerid][JetpackExpire] = Info[playerid][JetpackExpire] + (90*86400);

                        Info[playerid][Jetpack] = 1;
                        Info[playerid][UGC] -= 500;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought jetpack for 90 days");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Jetpack for 90 days", "Close", "");
                    }
                }
            }
        }
        case DIALOG_SHOP+11:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        foreach(new i : Property)
                        {
                            if(IsPlayerInRangeOfPoint(playerid, 2.0, pInfo[i][PropertyX], pInfo[i][PropertyY], pInfo[i][PropertyZ]))
                            {
                                if(!strcmp(pInfo[i][Owner], "-")) return SCM(playerid, red, "You can not renew this property");

                                pInfo[i][PropertyExpire] = pInfo[i][PropertyExpire] + (5*86400);
                                Info[playerid][UGC] -= 50;

                                pSave(i);
                                SaveLog(playerid, "has bought property renew for 5 days");

                                ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Property Renew - 5 days", "Close", "");
                            }
                            else return SCM(playerid, red, "You are not near any property");
                        }
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        foreach(new i : Property)
                        {
                            if(IsPlayerInRangeOfPoint(playerid, 2.0, pInfo[i][PropertyX], pInfo[i][PropertyY], pInfo[i][PropertyZ]))
                            {
                                if(!strcmp(pInfo[i][Owner], "-")) return SCM(playerid, red, "You can not renew this property");

                                pInfo[i][PropertyExpire] = pInfo[i][PropertyExpire] + (30*86400);
                                Info[playerid][UGC] -= 150;

                                pSave(i);
                                SaveLog(playerid, "has bought property renew for 30 days");

                                ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Property Renew - 30 days", "Close", "");
                            }
                            else return SCM(playerid, red, "You are not near any property");
                        }
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 300) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        foreach(new i : Property)
                        {
                            if(IsPlayerInRangeOfPoint(playerid, 2.0, pInfo[i][PropertyX], pInfo[i][PropertyY], pInfo[i][PropertyZ]))
                            {
                                if(!strcmp(pInfo[i][Owner], "-")) return SCM(playerid, red, "You can not renew this property");

                                pInfo[i][PropertyExpire] = pInfo[i][PropertyExpire] + (90*86400);
                                Info[playerid][UGC] -= 300;

                                pSave(i);
                                SaveLog(playerid, "has bought property renew for 90 days");

                                ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Property Renew - 90 days", "Close", "");
                            }
                            else return SCM(playerid, red, "You are not near any property");
                        }
                    }
                }
            }
        }
        case DIALOG_SHOP+12:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        new i = GetPVarInt(playerid, "PickupHouseID");
                        if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[i][houseX], HouseData[i][houseY], HouseData[i][houseZ]))
                        {
                            if(!strcmp(HouseData[i][Owner], "-")) return SCM(playerid, red, "You can not renew this house");

                            HouseData[i][HouseExpire] = HouseData[i][HouseExpire] + (5*86400);
                            Info[playerid][UGC] -= 50;

                            SaveHouse(i);
                            SaveLog(playerid, "has bought house renew for 5 days");

                            ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}House Renew - 5 days", "Close", "");
                        }
                        else return SCM(playerid, red, "You are not near any house");
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        new i = GetPVarInt(playerid, "PickupHouseID");
                        if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[i][houseX], HouseData[i][houseY], HouseData[i][houseZ]))
                        {
                            if(!strcmp(HouseData[i][Owner], "-")) return SCM(playerid, red, "You can not renew this house");
                            
                            HouseData[i][HouseExpire] = HouseData[i][HouseExpire] + (30*86400);
                            Info[playerid][UGC] -= 150;

                            SaveHouse(i);
                            SaveLog(playerid, "has bought house renew for 30 days");

                            ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}House Renew - 30 days", "Close", "");
                        }
                        else return SCM(playerid, red, "You are not near any house");
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 300) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        new i = GetPVarInt(playerid, "PickupHouseID");
                        if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[i][houseX], HouseData[i][houseY], HouseData[i][houseZ]))
                        {
                            if(!strcmp(HouseData[i][Owner], "-")) return SCM(playerid, red, "You can not renew this house");
                            
                            HouseData[i][HouseExpire] = HouseData[i][HouseExpire] + (90*86400);
                            Info[playerid][UGC] -= 300;

                            SaveHouse(i);
                            SaveLog(playerid, "has bought house renew for 90 days");

                            ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}House Renew - 90 days", "Close", "");
                        }
                        else return SCM(playerid, red, "You are not near any house");
                    }
                }
            }
        }
        case DIALOG_SHOP+13:
        {
            if(response)
            {
                if(Info[playerid][UGC] < VehicleWheels[listitem][WheelPrice]) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
                if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not in any vehicle");
               
                Info[playerid][UGC] -= VehicleWheels[listitem][WheelPrice];
                
                foreach(new vehicleid : PrivateVehicles[playerid]) {

                    if(IsPlayerInVehicle(playerid, vInfo[vehicleid][vehSessionID])) {

                        if(!strcmp(vInfo[vehicleid][vehOwner], GetName(playerid))) {

                            AddVehicleComponent(vInfo[vehicleid][vehSessionID], VehicleWheels[listitem][WheelID]);
                            new componentType = GetVehicleComponentType(VehicleWheels[listitem][WheelID]);

                            for(new x; x < 14; x++) {

                                if(componentType == x) {

                                    vInfo[vehicleid][vehMod][x] = VehicleWheels[listitem][WheelID];
                                }
                            }
                        }
                        else AddVehicleComponent(GetPlayerVehicleID(playerid), VehicleWheels[listitem][WheelID]);
                    }
                }

                new Float:x, Float:y, Float:z;
                GetPlayerPos(playerid, x, y, z);
                PlayerPlaySound(playerid, 1133, x, y, z);

                new Float:value = float(VehicleWheels[listitem][WheelPrice]) / 100;

                new str[80];
                format(str, sizeof(str), "has bought wheel %s for %0.2f", VehicleWheels[listitem][WheelName], value);
                SaveLog(playerid, str);

                format(str, sizeof(str), "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Wheel - %s", VehicleWheels[listitem][WheelName]);
                ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", str, "Close", "");
            }
        }
        case DIALOG_SHOP+14:
        {
            if(response)
            {
                if(Info[playerid][UGC] < VehicleSpoiler[listitem][SpoilerPrice]) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
                if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not in any vehicle");
               
                Info[playerid][UGC] -= VehicleSpoiler[listitem][SpoilerPrice];
                
                foreach(new vehicleid : PrivateVehicles[playerid]) {

                    if(IsPlayerInVehicle(playerid, vInfo[vehicleid][vehSessionID])) {

                        if(!strcmp(vInfo[vehicleid][vehOwner], GetName(playerid))) AddVehicleComponent(vInfo[vehicleid][vehSessionID], VehicleSpoiler[listitem][SpoilerID]);
                        else AddVehicleComponent(GetPlayerVehicleID(playerid), VehicleSpoiler[listitem][SpoilerID]);
                    }
                }

                new Float:x, Float:y, Float:z;
                GetPlayerPos(playerid, x, y, z);
                PlayerPlaySound(playerid, 1133, x, y, z);
                
                new Float:value = float(VehicleSpoiler[listitem][SpoilerPrice]) / 100;

                new str[80];
                format(str, sizeof(str), "has bought spoiler %s for %0.2f", VehicleSpoiler[listitem][SpoilerName], value);
                SaveLog(playerid, str);

                format(str, sizeof(str), "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Spoiler - %s", VehicleSpoiler[listitem][SpoilerName]);
                ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", str, "Close", "");
            }
        }
        case DIALOG_SHOP+15:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
                        if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not in any vehicle");
                       
                        Info[playerid][UGC] -= 25;
                        
                        foreach(new vehicleid : PrivateVehicles[playerid]) {

                            if(IsPlayerInVehicle(playerid, vInfo[vehicleid][vehSessionID])) {

                                if(!strcmp(vInfo[vehicleid][vehOwner], GetName(playerid))) {

                                    AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1009);
                                    vInfo[vehicleid][vehNitro] = 1;
                                }
                                else AddVehicleComponent(GetPlayerVehicleID(playerid), 1009);
                            }
                        }

                        new Float:x, Float:y, Float:z;
                        GetPlayerPos(playerid, x, y, z);
                        PlayerPlaySound(playerid, 1133, x, y, z);

                        SaveLog(playerid, "has bought nitro 2x from /shop");
                        
                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Nitro 2x", "Close", "");
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
                        if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not in any vehicle");
                       
                        Info[playerid][UGC] -= 50;
                        
                        foreach(new vehicleid : PrivateVehicles[playerid]) {

                            if(IsPlayerInVehicle(playerid, vInfo[vehicleid][vehSessionID])) {

                                if(!strcmp(vInfo[vehicleid][vehOwner], GetName(playerid))) {

                                    AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1008);
                                    vInfo[vehicleid][vehNitro] = 2;
                                }
                                else AddVehicleComponent(GetPlayerVehicleID(playerid), 1008);
                            }
                        }

                        new Float:x, Float:y, Float:z;
                        GetPlayerPos(playerid, x, y, z);
                        PlayerPlaySound(playerid, 1133, x, y, z);

                        SaveLog(playerid, "has bought nitro 5x from /shop");
                        
                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Nitro 5x", "Close", "");
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 75) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
                        if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not in any vehicle");
                       
                        Info[playerid][UGC] -= 75;
                        
                        foreach(new vehicleid : PrivateVehicles[playerid]) {

                            if(IsPlayerInVehicle(playerid, vInfo[vehicleid][vehSessionID])) {

                                if(!strcmp(vInfo[vehicleid][vehOwner], GetName(playerid))) {

                                    AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1010);
                                    vInfo[vehicleid][vehNitro] = 3;
                                }
                                else AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
                            }
                        }

                        new Float:x, Float:y, Float:z;
                        GetPlayerPos(playerid, x, y, z);
                        PlayerPlaySound(playerid, 1133, x, y, z);

                        SaveLog(playerid, "has bought nitro 10x from /shop");
                        
                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Nitro 10x", "Close", "");
                    }
                }
            }
        }
        case DIALOG_SHOP+16:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(Info[playerid][UGC] < 25) return SCM(playerid, red, "You don't have enough UGC to purchase this item");
                        if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not in any vehicle");

                        Info[playerid][UGC] -= 25;
                        
                        foreach(new vehicleid : PrivateVehicles[playerid]) {

                            if(IsPlayerInVehicle(playerid, vInfo[vehicleid][vehSessionID])) {

                                if(!strcmp(vInfo[vehicleid][vehOwner], GetName(playerid))) {
                                 
                                    AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1087);
                                    vInfo[vehicleid][vehHydraulics] = 1;
                                }
                                else AddVehicleComponent(GetPlayerVehicleID(playerid), 1087);
                            }
                        }

                        new Float:x, Float:y, Float:z;
                        GetPlayerPos(playerid, x, y, z);
                        PlayerPlaySound(playerid, 1133, x, y, z);

                        SaveLog(playerid, "has bought hydraulics from /shop");
                        
                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Hydraulics", "Close", "");
                    }
                }
            }
        }
        case DIALOG_SHOP+17:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][JumpExpire] == 0) Info[playerid][JumpExpire] = gettime() + 5*86400;
                        else Info[playerid][JumpExpire] = Info[playerid][JumpExpire] + (90*86400);

                        Info[playerid][UGC] -= 50;
                        Info[playerid][Jump] = 1;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought double jump for 5 days");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Double jump for 5 days", "Close", "");
                    }
                    case 1:
                    {
                        if(Info[playerid][UGC] < 150) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][JumpExpire] == 0) Info[playerid][JumpExpire] = gettime() + 30*86400;
                        else Info[playerid][JumpExpire] = Info[playerid][JumpExpire] + (90*86400);

                        Info[playerid][UGC] -= 150;
                        Info[playerid][Jump] = 1;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought double jump for 30 days");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Double jump for 30 days", "Close", "");
                    }
                    case 2:
                    {
                        if(Info[playerid][UGC] < 300) return SCM(playerid, red, "You don't have enough UGC to purchase this item");

                        if(Info[playerid][JumpExpire] == 0) Info[playerid][JumpExpire] = gettime() + 90*86400;
                        else Info[playerid][JumpExpire] = Info[playerid][JumpExpire] + (90*86400);

                        Info[playerid][UGC] -= 300;
                        Info[playerid][Jump] = 1;

                        SavePlayerData(playerid, 0, 1);
                        SaveLog(playerid, "has bought double jump for 90 days");

                        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Congratulations", "{FF0066}You have purchased a new item from the game shop!\n{FFFFFF}Double jump for 90 days", "Close", "");
                    }
                }
            }
        }
		case DIALOG_SKIN_BUY:
		{
			if(response)
			{
				if(Info[playerid][UGC] < 50) return SCM(playerid, red, "You don't have enough UGC");

				new query[128];
				mysql_format(mysql, query, sizeof(query), "INSERT INTO `SkinData` (ID, SkinID) VALUES (%d, %d) ON DUPLICATE KEY UPDATE `SkinID` = %d", Info[playerid][ID], BuySkin[playerid], BuySkin[playerid]);
				mysql_query(mysql, query);

				format(query, sizeof(query), "You have bought skin %d (%s) for 0.50 UGC", BuySkin[playerid], GetSkinName(BuySkin[playerid]));
				SCM(playerid, green, query);

				new Float:X, Float:Y, Float:Z;
				GetPlayerPos(playerid, X, Y, Z);

				SetPlayerSkin(playerid, BuySkin[playerid]);
				SetPlayerPos(playerid, X, Y, Z+1);

				Info[playerid][UGC] -= 50;
                SavePlayerData(playerid, 0, 1);
			}
			else SetPlayerSkin(playerid, PervSkin[playerid]);
		}
		case DIALOG_HELP:
		{
			if(response)
			{
                new string[280];
				switch(listitem)
				{
					case 0: cmd_commands(playerid, "");
					case 1: cmd_rules(playerid, "");
					case 2: cmd_earn(playerid, "");
					case 3: ShowPlayerDialog(playerid, DIALOG_HELP+1, DIALOG_STYLE_MSGBOX, "Vehicles", "{FFFFFF}You can find vehicles on the streets all around Los Santos.", "Close", "");
					case 4: cmd_ganghelp(playerid, "");
                    case 5: cmd_animations(playerid, "");
					case 6: 
					{
						strcat(string, "{FFFFFF}You can buy skins from /shop with your in game money (UGC).\n");
						strcat(string, "{FFFFFF}Skins will be immediately saved in your inventory.\n");
						strcat(string, "{FFFFFF}Use /skins or /inventory to load it whenever you would like.\n");
						ShowPlayerDialog(playerid, DIALOG_HELP+2, DIALOG_STYLE_MSGBOX, "Skins", string, "Close", "");
					}
					case 7: cmd_wl(playerid, "");
                    case 8:
                    {
                        strcat(string, "{FFFFFF}You can get Marijuana either by buying it from /shop with UGC\n");
                        strcat(string, "{FFFFFF}or by buying seeds at the Farm and plant your own Marijuana.\n");
                        ShowPlayerDialog(playerid, DIALOG_HELP+2, DIALOG_STYLE_MSGBOX, "Marijuana", string, "Close", "");
                    }
                    case 9:
                    {
                        strcat(string, "{FFFFFF}You can get Cocaine either by buying it from /shop with UGC.\n");
                        ShowPlayerDialog(playerid, DIALOG_HELP+2, DIALOG_STYLE_MSGBOX, "Cocaine", string, "Close", "");
                    }
					case 10: ShowPlayerDialog(playerid, DIALOG_HELP+5, DIALOG_STYLE_MSGBOX, "XP", "{FFFFFF}You can earn XP by playing minigames, killing players, doing jobs\n{FFFFFF}or buying stuff.", "Close", "");
					case 11: cmd_benefits(playerid, "");
                    case 12:
                    {
                        strcat(string, "{FFFFFF}You can buy weapons from the ammu nations all around LS.\n");
                        ShowPlayerDialog(playerid, DIALOG_HELP+2, DIALOG_STYLE_MSGBOX, "Weapons", string, "Close", "");
                    }
                    case 13:
                    {
                        strcat(string, "{FFFFFF}You can buy houses all around LS, the purchasable houses are\n");
                        strcat(string, "{FFFFFF}marked as a green house icon in your minimap.\n");
                        strcat(string, "{FFFFFF}With houses you can save money or guns, and load it whenever you want.\n");
                        ShowPlayerDialog(playerid, DIALOG_HELP+2, DIALOG_STYLE_MSGBOX, "Houses", string, "Close", "");
                    }
                    case 14:
                    {
                        strcat(string, "{FFFFFF}You can buy properties all around LS, the purchasable properties are\n");
                        strcat(string, "{FFFFFF}marked as a green property icon in your minimap. With properties you\n");
                        strcat(string, "{FFFFFF}earn money each 1 hour while you are online in the server.\n");
                        ShowPlayerDialog(playerid, DIALOG_HELP+2, DIALOG_STYLE_MSGBOX, "Properties", string, "Close", "");
                    }
				}
			}
		}
		case DIALOG_COLORS:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: SetPlayerColor(playerid, 0xFFFFFFFF), format(Info[playerid][playerColor], 16, "0xFFFFFFFF"), format(Info[playerid][textColor], 16, "FFFFFF");
                    case 1: SetPlayerColor(playerid, 0xFF6666FF), format(Info[playerid][playerColor], 16, "0xFF6666FF"), format(Info[playerid][textColor], 16, "FF6666");
                    case 2: SetPlayerColor(playerid, 0xFFFF33FF), format(Info[playerid][playerColor], 16, "0xFFFF33FF"), format(Info[playerid][textColor], 16, "FFFF33");
                    case 3: SetPlayerColor(playerid, 0x99FF66FF), format(Info[playerid][playerColor], 16, "0x99FF66FF"), format(Info[playerid][textColor], 16, "99FF66");
                    case 4: SetPlayerColor(playerid, 0x3366FFFF), format(Info[playerid][playerColor], 16, "0x3366FFFF"), format(Info[playerid][textColor], 16, "3366FF");
                    case 5: SetPlayerColor(playerid, 0x9966FFFF), format(Info[playerid][playerColor], 16, "0x9966FFFF"), format(Info[playerid][textColor], 16, "9966FF");
                    case 6: SetPlayerColor(playerid, 0xFF0099FF), format(Info[playerid][playerColor], 16, "0xFF0099FF"), format(Info[playerid][textColor], 16, "FF0099");
                }
            }
        }
		case DIALOG_BUY_PROPERTY:
		{
			if(response)
			{
				new id = AvailablePID[playerid];
				if(!IsPlayerInRangeOfPoint(playerid, 2.0, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ])) return SCM(playerid, red, "You are not near the property");
				if(pInfo[id][Price] > GetPlayerCash(playerid)) return SCM(playerid, red, "You don't have enough money to buy this property");
				if(strcmp(pInfo[id][Owner], "-")) return SCM(playerid, red, "Property is already owned");

                KillTimer(pTimer[playerid]);

				GivePlayerCash(playerid, -pInfo[id][Price]);
				GetPlayerName(playerid, pInfo[id][Owner], MAX_PLAYER_NAME);

				pInfo[id][PropertyExpire] = gettime() + HOUSE_DAYS*86400;
				pInfo[id][PropertySave] = true;

                pTimer[playerid] = SetTimerEx("PropertyTimer", PROPERTY_REVENUE * 60000, true, "i", playerid);

                new string[74];
                format(string, sizeof(string), "has bought property for $%s", cNumber(pInfo[id][Price]));
                SaveLog(playerid, string);

				pUpdateLabel(id);
                pSave(id);
			}
		}
        case DIALOG_BUY_HOUSE:
        {
            if(!response) return 1;

            new id = GetPVarInt(playerid, "PickupHouseID");
            if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, red, "You're not near any house");
            if(HouseData[id][Price] > GetPlayerCash(playerid)) return SendClientMessage(playerid, red, "You can't afford this house");
            if(strcmp(HouseData[id][Owner], "-")) return SendClientMessage(playerid, red, "Someone already owns this house");

            GivePlayerCash(playerid, -HouseData[id][Price]);
            GetPlayerName(playerid, HouseData[id][Owner], MAX_PLAYER_NAME);

            HouseData[id][HouseExpire] = gettime()+HOUSE_DAYS*86400;
            HouseData[id][HouseSave] = true;

            ShowInfoBox(playerid, 0x00000088, 8, "Press RETURN to get into the house, use /house to toggle the house settings");

            new string[74];
            format(string, sizeof(string), "has bought house for $%s", cNumber(HouseData[id][Price]));
            SaveLog(playerid, string);

            UpdateHouseLabel(id);
            Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1272);
            Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
            SaveHouse(id);
            return 1;
        }
        case DIALOG_HOUSE_MENU:
        {
            if(!response) return 1;
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

            switch(listitem)
            {
                case 0: ShowPlayerDialog(playerid, DIALOG_HOUSE_LOCK, DIALOG_STYLE_LIST, "House Lock", "Lock\nUnlock\nKeys", "Change", "Back");
                case 1:
                {
                    new string[144];
                    format(string, sizeof(string), "Take Money From Safe {00FF00}($%s)\nPut Money To Safe {00FF00}($%s)\nView Safe History\nClear Safe History", cNumber(HouseData[id][SafeMoney]), cNumber(GetPlayerCash(playerid)));
                    ShowPlayerDialog(playerid, DIALOG_SAFE_MENU, DIALOG_STYLE_LIST, "House Safe", string, "Choose", "Back");
                }
                
                case 2: ShowPlayerDialog(playerid, DIALOG_GUNS_MENU, DIALOG_STYLE_LIST, "Guns", "Put Gun\nTake Gun", "Choose", "Back");
                case 3:
                {
                    ListPage[playerid] = 0;
                    ShowPlayerDialog(playerid, DIALOG_VISITORS_MENU, DIALOG_STYLE_LIST, "Visitors", "Look Visitor History\nClear Visitor History", "Choose", "Back");
                }

                case 4:
                {
                    ListPage[playerid] = 0;
                    ShowPlayerDialog(playerid, DIALOG_KEYS_MENU, DIALOG_STYLE_LIST, "Keys", "View Key Owners\nChange Locks", "Choose", "Back");
                }

                case 5:
                {
                    SCM(playerid, red, "You have kicked all the players from your house");
                    foreach(new i : Player)
                    {
                        if(i == playerid) continue;
                        if(InHouse[i] == id)
                        {
                            SetPlayerVirtualWorld(i, 0);
                            SetPlayerInterior(i, 0);
                            SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
                            InHouse[i] = INVALID_HOUSE_ID;
                            ShowInfoBox(i, 0x00000088, 7, "You have been kicked from the house");
                        }
                    }
                }
            }
            return 1;
        }
        case DIALOG_HOUSE_LOCK:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

            HouseData[id][LockMode] = listitem;
            HouseData[id][HouseSave] = true;

            UpdateHouseLabel(id);
            ShowHouseMenu(playerid);
            return 1;
        }
        case DIALOG_SAFE_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            switch(listitem)
            {
                case 0: ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "Safe: Take Money", "Write the amount you want to take from safe:", "Take", "Back");
                case 1: ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "Safe: Put Money", "Write the amount you want to put to safe:", "Put", "Back");
                case 2:
                {
                    ListPage[playerid] = 0;

                    new query[200], Cache: safelog;
                    mysql_format(mysql, query, sizeof(query), "SELECT `Type`, `Amount`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as `TransactionDate` FROM `HouseSafeLogs` WHERE `HouseID` = %d ORDER BY `Date` DESC LIMIT 0, 15", id);
                    safelog = mysql_query(mysql, query);
                    new rows = cache_num_rows();
                    if(rows) 
                    {
                        new list[1024], date[20];
                        format(list, sizeof(list), "Action\tDate\n");
                        for(new i; i < rows; ++i)
                        {
                            cache_get_field_content(i, "TransactionDate", date);
                            format(list, sizeof(list), "%s%s $%s\t{FFFFFF}%s\n", list, TransactionNames[ cache_get_field_content_int(i, "Type") ], cNumber(cache_get_field_content_int(i, "Amount")), date);
                        }

                        ShowPlayerDialog(playerid, DIALOG_SAFE_HISTORY, DIALOG_STYLE_TABLIST_HEADERS, "Safe History (Page 1)", list, "Next", "Previous");
                    }
                    else SendClientMessage(playerid, red, "Can't find any safe history");
                    cache_delete(safelog);
                }

                case 3:
                {
                    new query[64];
                    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseSafeLogs` WHERE `HouseID` = %d", id);
                    mysql_tquery(mysql, query);
                    ShowHouseMenu(playerid);
                }
            }
            return 1;
        }
        case DIALOG_SAFE_TAKE:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            new amount = strval(inputtext);
            if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "Safe: Take Money", "Write the amount you want to take from safe:\n\n{FF0000}Invalid amount. You can take between $1 - $10,000,000 at a time", "Take", "Back");
            if(amount > HouseData[id][SafeMoney]) return ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "Safe: Take Money", "Write the amount you want to take from safe:\n\n{FF0000}You don't have that much money in your safe", "Take", "Back");
            
            new query[128];
            mysql_format(mysql, query, sizeof(query), "INSERT INTO `HouseSafeLogs` SET `HouseID` = %d, `Type` = 0, `Amount` = %d, `Date` = UNIX_TIMESTAMP()", id, amount);
            mysql_tquery(mysql, query);

            GivePlayerCash(playerid, amount);
            HouseData[id][SafeMoney] -= amount;
            HouseData[id][HouseSave] = true;
            ShowHouseMenu(playerid);
            return 1;
        }
        case DIALOG_SAFE_PUT:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            new amount = strval(inputtext);
            if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "Safe: Put Money", "Write the amount you want to put to safe:\n\n{FF0000}Invalid amount. You can put between $1 - $10,000,000 at a time", "Put", "Back");
            if(amount > GetPlayerCash(playerid)) return ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "Safe: Put Money", "Write the amount you want to put to safe:\n\n{FF0000}You don't have that much money on you", "Put", "Back");
            
            new query[128];
            mysql_format(mysql, query, sizeof(query), "INSERT INTO `HouseSafeLogs` SET `HouseID` = %d, `Type` = 1, `Amount` = %d, `Date` = UNIX_TIMESTAMP()", id, amount);
            mysql_tquery(mysql, query);

            GivePlayerCash(playerid, -amount);
            HouseData[id][SafeMoney] += amount;
            HouseData[id][HouseSave] = true;
            ShowHouseMenu(playerid);
            return 1;
        }
        case DIALOG_GUNS_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

            switch(listitem)
            {
                case 0:
                {
                    if(GetPlayerWeapon(playerid) == 0) return SendClientMessage(playerid, red, "You can't put your fists in your house");

                    ShowPlayerDialog(playerid, DIALOG_GUNS_MENU+100, DIALOG_STYLE_INPUT, "House Guns", "{FFFFFF}Please put the amount you want to put", "Next", "Close");
                }

                case 1:
                {
                    new query[110], Cache: weapons;
                    mysql_format(mysql, query, sizeof(query), "SELECT `WeaponID`, `Ammo` FROM `HouseGuns` WHERE `HouseID` = %d ORDER BY `WeaponID` ASC", id);
                    weapons = mysql_query(mysql, query);
                    new rows = cache_num_rows();
                    if(rows) 
                    {
                        new list[512], weapname[32];
                        format(list, sizeof(list), "#\tWeapon Name\tAmmo\n");
                        for(new i; i < rows; ++i)
                        {
                            GetWeaponName(cache_get_field_content_int(i, "WeaponID"), weapname, sizeof(weapname));
                            format(list, sizeof(list), "%s%d\t%s\t%s\n", list, i+1, weapname, cNumber(cache_get_field_content_int(i, "Ammo")));
                        }

                        ShowPlayerDialog(playerid, DIALOG_GUNS_TAKE, DIALOG_STYLE_TABLIST_HEADERS, "House Guns", list, "Take", "Back");
                    }
                    else SendClientMessage(playerid, red, "You don't have any guns in your house");
                    cache_delete(weapons);
                }
            }
            return 1;
        }
        case DIALOG_GUNS_MENU+100:
        {
            if(!response) return ShowHouseMenu(playerid);

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            
            new query[128], weapon = GetPlayerWeapon(playerid), ammo = GetPlayerAmmo(playerid);
            if(weapon == 0) return SendClientMessage(playerid, red, "You can't put your fists in your house");
            if(strval(inputtext) > ammo) return SCM(playerid, red, "You don't have enough ammo");

            SetPlayerAmmo(playerid, weapon, ammo-strval(inputtext));
            mysql_format(mysql, query, sizeof(query), "INSERT INTO `HouseGuns` VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE `Ammo` = `Ammo`+%d", id, weapon, strval(inputtext), strval(inputtext));
            mysql_tquery(mysql, query);
            ShowHouseMenu(playerid);

        }
        case DIALOG_GUNS_TAKE:
        {
            if(!response) return ShowHouseMenu(playerid);

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

            new query[110], Cache: weapon;
            mysql_format(mysql, query, sizeof(query), "SELECT `WeaponID`, `Ammo` FROM `HouseGuns` WHERE `HouseID` = %d ORDER BY `WeaponID` ASC LIMIT %d, 1", id, listitem);
            weapon = mysql_query(mysql, query);
            new rows = cache_num_rows();

            if(rows) 
            {
                new weapname[32], weaponid = cache_get_field_content_int(0, "WeaponID");
                GetWeaponName(weaponid, weapname, sizeof(weapname));
                GivePlayerWeaponEx(playerid, weaponid, cache_get_field_content_int(0, "Ammo"));

                format(query, sizeof(query), "You've taken a %s from your house", weapname);
                SendClientMessage(playerid, green, query);

                mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseGuns` WHERE `HouseID` = %d AND `WeaponID` = %d", id, weaponid);
                mysql_tquery(mysql, query);
            }
            else SendClientMessage(playerid, red, "Can't find that weapon");

            cache_delete(weapon);
            return 1;
        }
        case DIALOG_VISITORS_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

            switch(listitem)
            {
                case 0:
                {
                    new query[200], Cache: visitors;
                    mysql_format(mysql, query, sizeof(query), "SELECT `Visitor`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `VisitDate` FROM `HouseVisitors` WHERE `HouseID` = %d ORDER BY `Date` DESC LIMIT 0, 15", id);
                    visitors = mysql_query(mysql, query);
                    new rows = cache_num_rows();
                    if(rows) 
                    {
                        new list[1024], visitor_name[MAX_PLAYER_NAME], visit_date[20];
                        format(list, sizeof(list), "Visitor Name\tDate\n");
                        for(new i; i < rows; ++i)
                        {
                            cache_get_field_content(i, "Visitor", visitor_name);
                            cache_get_field_content(i, "VisitDate", visit_date);
                            format(list, sizeof(list), "%s%s\t%s\n", list, visitor_name, visit_date);
                        }

                        ShowPlayerDialog(playerid, DIALOG_VISITORS, DIALOG_STYLE_TABLIST_HEADERS, "House Visitors (Page 1)", list, "Next", "Previous");
                    }
                    else SendClientMessage(playerid, red, "You had not any visitors");
                    cache_delete(visitors);
                }

                case 1:
                {
                    new query[64];
                    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseVisitors` WHERE `HouseID` = %d", id);
                    mysql_tquery(mysql, query);
                    ShowHouseMenu(playerid);
                }
            }
            return 1;
        }
        case DIALOG_VISITORS:
        {
            if(!response) 
            {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    ShowHouseMenu(playerid);
                    return 1;
                }
            }
            else
            {
                ListPage[playerid]++;
            }

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            new query[200], Cache: visitors;
            mysql_format(mysql, query, sizeof(query), "SELECT `Visitor`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `VisitDate` FROM `HouseVisitors` WHERE `HouseID` = %d ORDER BY `Date` DESC LIMIT %d, 15", id, ListPage[playerid]*15);
            visitors = mysql_query(mysql, query);
            new rows = cache_num_rows();
            if(rows) 
            {
                new list[1024], visitor_name[MAX_PLAYER_NAME], visit_date[20];
                format(list, sizeof(list), "Visitor Name\tDate\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_field_content(i, "Visitor", visitor_name);
                    cache_get_field_content(i, "VisitDate", visit_date);
                    format(list, sizeof(list), "%s%s\t%s\n", list, visitor_name, visit_date);
                }

                new title[32];
                format(title, sizeof(title), "House Visitors (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_VISITORS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }
            else
            {
                SendClientMessage(playerid, red, "Can't find any more visitors");
                ListPage[playerid] = 0;
                ShowHouseMenu(playerid);
            }

            cache_delete(visitors);
            return 1;
        }
        case DIALOG_KEYS_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

            switch(listitem)
            {
                case 0:
                {
                    new query[200], Cache: keyowners;
                    mysql_format(mysql, query, sizeof(query), "SELECT `Player`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `KeyDate` FROM `HouseKeys` WHERE `HouseID` = %d ORDER BY `Date` DESC LIMIT %d, 15", id, ListPage[playerid]*15);
                    keyowners = mysql_query(mysql, query);
                    new rows = cache_num_rows();
                    if(rows) 
                    {
                        new list[1024], key_name[MAX_PLAYER_NAME], key_date[20];
                        format(list, sizeof(list), "Key Owner\tKey Given On\n");
                        for(new i; i < rows; ++i)
                        {
                            cache_get_field_content(i, "Player", key_name);
                            cache_get_field_content(i, "KeyDate", key_date);
                            format(list, sizeof(list), "%s%s\t%s\n", list, key_name, key_date);
                        }

                        ShowPlayerDialog(playerid, DIALOG_KEYS, DIALOG_STYLE_TABLIST_HEADERS, "Key Owners (Page 1)", list, "Next", "Previous");
                    }
                    else SendClientMessage(playerid, red, "Can't find any key owners");

                    cache_delete(keyowners);
                }

                case 1:
                {
                    foreach(new i : Player)
                    {
                        if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
                    }

                    new query[64];
                    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseKeys` WHERE `HouseID` = %d", id);
                    mysql_tquery(mysql, query);
                    ShowHouseMenu(playerid);
                }
            }
            return 1;
        }
        case DIALOG_KEYS:
        {
            if(!response) 
            {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    ShowHouseMenu(playerid);
                    return 1;
                }
            }
            else
            {
                ListPage[playerid]++;
            }

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            new query[200], Cache: keyowners;
            mysql_format(mysql, query, sizeof(query), "SELECT `Player`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `KeyDate` FROM `HouseKeys` WHERE `HouseID` = %d ORDER BY `Date` DESC LIMIT %d, 15", id, ListPage[playerid]*15);
            keyowners = mysql_query(mysql, query);
            new rows = cache_num_rows();
            if(rows) 
            {
                new list[1024], key_name[MAX_PLAYER_NAME], key_date[20];
                format(list, sizeof(list), "Key Owner\tKey Given On\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_field_content(i, "Player", key_name);
                    cache_get_field_content(i, "KeyDate", key_date);
                    format(list, sizeof(list), "%s%s\t%s\n", list, key_name, key_date);
                }

                new title[32];
                format(title, sizeof(title), "Key Owners (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_KEYS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }
            else
            {
                ListPage[playerid] = 0;
                ShowHouseMenu(playerid);
                SendClientMessage(playerid, red, "Can't find any more key owners");
            }

            cache_delete(keyowners);
            return 1;
        }
        case DIALOG_SAFE_HISTORY:
        {
            if(!response) 
            {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    ShowHouseMenu(playerid);
                    return 1;
                }
            }
            else
            {
                ListPage[playerid]++;
            }

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
            if(strcmp(HouseData[id][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
            new query[200], Cache: safelog;
            mysql_format(mysql, query, sizeof(query), "SELECT `Type`, `Amount`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `TransactionDate` FROM `HouseSafeLogs` WHERE `HouseID` = %d ORDER BY `Date` DESC LIMIT %d, 15", id, ListPage[playerid]*15);
            safelog = mysql_query(mysql, query);
            new rows = cache_num_rows();
            if(rows) 
            {
                new list[1024], date[20];
                format(list, sizeof(list), "Action\tDate\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_field_content(i, "TransactionDate", date);
                    format(list, sizeof(list), "%s%s $%s\t{FFFFFF}%s\n", list, TransactionNames[ cache_get_field_content_int(i, "Type") ], cNumber(cache_get_field_content_int(i, "Amount")), date);
                }

                new title[32];
                format(title, sizeof(title), "Safe History (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_SAFE_HISTORY, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }
            else SendClientMessage(playerid, red, "Can't find any more safe history");
            cache_delete(safelog);
            return 1;
        }
        case DIALOG_MY_KEYS:
        {
            if(!response) 
            {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    return 1;
                }
            }
            else
            {
                ListPage[playerid]++;
            }

            new query[200], Cache: mykeys;
            mysql_format(mysql, query, sizeof(query), "SELECT `HouseID`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `KeyDate` FROM `HouseKeys` WHERE `Player` = '%e' ORDER BY `Date` DESC LIMIT %d, 15", GetName(playerid), ListPage[playerid]*15);
            mykeys = mysql_query(mysql, query);

            new rows = cache_num_rows();
            if(rows) 
            {
                new list[1024], id, key_date[20];
                format(list, sizeof(list), "House Info\tKey Given On\n");
                for(new i; i < rows; ++i)
                {
                    id = cache_get_field_content_int(i, "HouseID");
                    cache_get_field_content(i, "KeyDate", key_date);
                    format(list, sizeof(list), "%s%s \t%s\n", list, HouseData[id][Owner], key_date);
                }

                new title[32];
                format(title, sizeof(title), "My Keys (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_MY_KEYS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }
            else
            {
                ListPage[playerid] = 0;
                SendClientMessage(playerid, red, "Can't find any more keys");
            }

            cache_delete(mykeys);
            return 1;
        }
		case DIALOG_SELL_MONEY:
		{
			if(response)
			{
				SelectedUGC[playerid] = floatround(floatstr(inputtext) * 100, floatround_floor);

				ShowPlayerDialog(playerid, DIALOG_SELL_MONEY+1, DIALOG_STYLE_INPUT, "Sell UGC", "{FF0066}Enter the price you want to sell the item for", "Sell", "Cancel");
			}
		}
		case DIALOG_SELL_MONEY+1:
		{
			if(response)
			{
                new string[180],
                    currenttime = gettime();

                new cooldown = (Cooldown[playerid][10] + 120) - currenttime;
                format(string, sizeof(string),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
                if(currenttime < (Cooldown[playerid][10] + 120)) return SCM(playerid,red,string);
                Cooldown[playerid][10] = gettime();

				new Float:value = float(SelectedUGC[playerid]) / 100;
				new price = strval(inputtext);

                format(string, sizeof(string), "has added %0.2f UGC to the marketplace", value);
                SaveLog(playerid, string);

				mysql_format(mysql, string, sizeof(string), "INSERT INTO `Market` (Seller, Amount, Price) VALUES ('%e', %i, %i) ON DUPLICATE KEY UPDATE `Amount` = %i AND `Price` = %i", GetName(playerid), SelectedUGC[playerid], price, SelectedUGC[playerid], price);
				mysql_tquery(mysql, string);

				format(string, sizeof(string), "%s has added item to the marketplace: %0.2f UGC for $%s", GetName(playerid), value, cNumber(price));
				SendClientMessageToAll(0xFF0066FF, string);
			}
		}
		case DIALOG_SELL_MONEY+3:
		{
			if(response)
			{
				new query[140], Cache: market;
				market = mysql_query(mysql, "SELECT * FROM `Market`");
				new rows = cache_num_rows();

				if(rows) 
				{
		  			new pName[MAX_PLAYER_NAME], Amount, pPrice;

		  			cache_get_field_content(listitem, "Seller", pName);
		        	Amount = cache_get_field_content_int(listitem, "Amount");
		        	pPrice = cache_get_field_content_int(listitem, "Price");

			        new pID = GetID(pName);
			        new Float:value = float(Amount) / 100;

			        if(GetPlayerCash(playerid) < pPrice) return SCM(playerid, red, "You don't have enough money");
			        if(!IsPlayerConnected(pID)) return SCM(playerid, red, "Player is not connected");

			        Info[playerid][UGC] += Amount;
			        Info[pID][UGC] -= Amount;

			        GivePlayerCash(playerid, -pPrice);
			        GivePlayerCash(pID, pPrice);

			        mysql_format(mysql, query, sizeof(query), "DELETE FROM `Market` WHERE `Seller` = '%e'", GetName(pID));
					mysql_tquery(mysql, query);

			        format(query, sizeof(query), "You have purchased %0.2f UGC for $%s from %s", value, cNumber(pPrice), pName);
			        SCM(playerid, 0xFF0066FF, query);

			        format(query, sizeof(query), "%s has purchased your item from the marketplace: %0.2f for $%s", GetName(playerid), value, cNumber(pPrice));
			        SCM(pID, 0xFF0066FF, query);

                    format(query, sizeof(query), "has purchased %0.2f UGC for $%s from %s", value, cNumber(pPrice), pName);
                    SaveLog(playerid, query);
				}
				else SendClientMessage(playerid, red, "Can not find the item");
				cache_delete(market);
			}
		}
        case DIALOG_OPMS:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        new query[180], Cache:opms;
                        mysql_format(mysql, query, sizeof(query), "SELECT `PlayerName`, `Status`, `SenderName`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `Date` FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                        opms = mysql_query(mysql, query);
                        new rows = cache_num_rows();

                        if(rows) 
                        {
                            new list[512];
                            format(list, sizeof(list), "Player Name\tStatus\tDate\n");
                            for(new i; i < rows; ++i)
                            {
                                new sName[MAX_PLAYER_NAME],
                                    sts, date[20];

                                cache_get_field_content(i, "SenderName", sName);
                                cache_get_field_content(i, "Date", date);
                                sts = cache_get_field_content_int(i, "Status");

                                format(list, sizeof(list), "%s%s\t%s\t%s\n", list, sName, sts == 1 ? ("{00FF00}Read"):("{FF0000}Unread"), date);
                            }
                            ShowPlayerDialog(playerid, DIALOG_OPMS+1, DIALOG_STYLE_TABLIST_HEADERS, "Show All Messages", list, "Select", "Close");
                        }
                        else SendClientMessage(playerid, red, "No offline PMs found");
                        cache_delete(opms);
                    }
                    case 1:
                    {
                        new query[180], Cache:opms;
                        mysql_format(mysql, query, sizeof(query), "SELECT `PlayerName`, `Status`, `SenderName`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `Date` FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                        opms = mysql_query(mysql, query);
                        new rows = cache_num_rows();

                        if(rows) 
                        {
                            new list[512];
                            format(list, sizeof(list), "Player Name\tDate\n");
                            for(new i; i < rows; ++i)
                            {
                                if(cache_get_field_content_int(i, "Status") == 1)
                                {
                                    new sName[MAX_PLAYER_NAME],
                                        date[20];

                                    cache_get_field_content(i, "SenderName", sName);
                                    cache_get_field_content(i, "Date", date);

                                    format(list, sizeof(list), "%s%s\t%s\n", list, sName, date);
                                }
                                else return SCM(playerid, red, "You don't have messages");
                            }
                            ShowPlayerDialog(playerid, DIALOG_OPMS+2, DIALOG_STYLE_TABLIST_HEADERS, "Show Read Messages", list, "Select", "Close");
                        }
                        else SendClientMessage(playerid, red, "No offline PMs found");
                        cache_delete(opms);
                    }
                    case 2:
                    {
                        new query[180], Cache:opms;
                        mysql_format(mysql, query, sizeof(query), "SELECT `PlayerName`, `Status`, `SenderName`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `Date` FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                        opms = mysql_query(mysql, query);
                        new rows = cache_num_rows();

                        if(rows) 
                        {
                            new list[512];
                            format(list, sizeof(list), "Player Name\tDate\n");
                            for(new i; i < rows; ++i)
                            {
                                if(cache_get_field_content_int(i, "Status") == 0)
                                {
                                    new sName[MAX_PLAYER_NAME], date[20];

                                    cache_get_field_content(i, "SenderName", sName);
                                    cache_get_field_content(i, "Date", date);

                                    format(list, sizeof(list), "%s%s\t%s\n", list, sName, date);
                                }
                                else return SCM(playerid, red, "You don't have unread messages");
                            }
                            ShowPlayerDialog(playerid, DIALOG_OPMS+3, DIALOG_STYLE_TABLIST_HEADERS, "Show Unread Messages", list, "Select", "Close");
                        }
                        else SendClientMessage(playerid, red, "No offline PMs found");
                        cache_delete(opms);
                    }
                    case 3:
                    {
                        new query[180], Cache:opms;
                        mysql_format(mysql, query, sizeof(query), "SELECT * FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                        opms = mysql_query(mysql, query);
                        new rows = cache_num_rows();

                        if(rows) 
                        {
                            mysql_format(mysql, query, sizeof(query), "DELETE FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                            mysql_tquery(mysql, query);

                            SCM(playerid, red, "You have deleted all of your offline PMs");
                        }
                        else SendClientMessage(playerid, red, "No offline PMs found");
                        cache_delete(opms);
                    }
                }
            }
        }
        case DIALOG_OPMS+1:
        {
            if(response)
            {
                new query[180], Cache: pms;
                mysql_format(mysql, query, sizeof(query), "SELECT * FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                pms = mysql_query(mysql, query);
                new rows = cache_num_rows();

                if(rows) 
                {
                    new sName[MAX_PLAYER_NAME], Message[84];

                    cache_get_field_content(listitem, "SenderName", sName);
                    cache_get_field_content(listitem, "Message", Message);

                    if(cache_get_field_content_int(listitem, "Status") == 0)
                    {
                        mysql_format(mysql, query, sizeof(query), "UPDATE `OfflinePMs` SET `Status` = 1 WHERE `PlayerName` = '%e' AND `Message` = '%e'", GetName(playerid), Message);
                        mysql_tquery(mysql, query);
                    }

                    format(query, 84, "{FFFFFF}%s", Message);
                    ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, sName, query, "Close", "");
                }
                cache_delete(pms);
            }
        }
        case DIALOG_OPMS+2:
        {
            if(response)
            { 
                new query[140], Cache: pms;
                mysql_format(mysql, query, sizeof(query), "SELECT * FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                pms = mysql_query(mysql, query);
                new rows = cache_num_rows();

                if(rows) 
                {
                    new sName[MAX_PLAYER_NAME], Message[84];

                    cache_get_field_content(listitem, "SenderName", sName);
                    cache_get_field_content(listitem, "Message", Message);

                    format(query, 84, "{FFFFFF}%s", Message);
                    ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, sName, query, "Close", "");
                }
                cache_delete(pms);
            }
        }
        case DIALOG_OPMS+3:
        {
            if(response)
            { 
                new query[140], Cache: pms;
                mysql_format(mysql, query, sizeof(query), "SELECT * FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
                pms = mysql_query(mysql, query);
                new rows = cache_num_rows();

                if(rows) 
                {
                    new sName[MAX_PLAYER_NAME], Message[84];

                    cache_get_field_content(listitem, "SenderName", sName);
                    cache_get_field_content(listitem, "Message", Message);

                    mysql_format(mysql, query, sizeof(query), "UPDATE `OfflinePMs` SET `Status` = 1 WHERE `PlayerName` = '%e' AND `Message` = '%e'", GetName(playerid), Message);
                    mysql_tquery(mysql, query);
         
                    format(query, 84, "{FFFFFF}%s", Message);
                    ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, sName, query, "Close", "");
                }
                cache_delete(pms);
            }  
        }
        case DIALOG_SEEDS:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < 60000) return SCM(playerid, red, "You don't have enough money");

                        Info[playerid][Seeds] += 25;
                        GivePlayerCash(playerid, -60000);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < 90000) return SCM(playerid, red, "You don't have enough money");

                        Info[playerid][Seeds] += 50;
                        GivePlayerCash(playerid, -90000);
                    }
                    case 2:
                    {
                        if(GetPlayerCash(playerid) < 150000) return SCM(playerid, red, "You don't have enough money");

                        Info[playerid][Seeds] += 100;
                        GivePlayerCash(playerid, -150000);
                    }
                }
            }
        }
        case DIALOG_INV:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 3: return cmd_skins(playerid, "");
                }
            }
        }
        case DIALOG_BUY_VEHICLE:
        {
            if(response)
            {
                new i = GetPVarInt(playerid, "buyVehicle");
                if(GetPlayerCash(playerid) < vInfo[i][vehPrice]) return SCM(playerid, red, "You don't have enough money");
                if(strcmp(vInfo[i][vehOwner], "-")) return SCM(playerid, red, "Vehicle is already owned by a player");

                new index = Iter_Free(ServerVehicles);

                vInfo[index][vehModel] = vInfo[i][vehModel];
                vInfo[index][vehX] = vInfo[i][vehX];
                vInfo[index][vehY] = vInfo[i][vehY];
                vInfo[index][vehZ] = vInfo[i][vehZ];
                vInfo[index][vehA] = vInfo[i][vehA];
                vInfo[index][vehPrice] = vInfo[i][vehPrice];

                format(vInfo[index][vehName], MAX_PLAYER_NAME, vInfo[i][vehName]);
                format(vInfo[index][vehPlate], MAX_PLAYER_NAME, vInfo[i][vehPlate]);

                vInfo[index][vehColorOne] = vInfo[i][vehColorOne];
                vInfo[index][vehColorTwo] = vInfo[i][vehColorTwo];

                for(new x; x < 14; x++) 
                    vInfo[index][vehMod][x] = 0;

                new query[360];
                mysql_format(mysql, query, sizeof(query),
                "INSERT INTO `Vehicles` (vehModel, vehPrice, vehName, vehOwner, vehPlate, vehColorOne, vehColorTwo, vehX, vehY, vehZ, vehA) VALUES (%d, %d, '%e', '-', '%e', %d, %d, %f, %f, %f, %f)",
                vInfo[index][vehModel], vInfo[index][vehPrice], vInfo[i][vehName], vInfo[index][vehPlate], vInfo[index][vehColorOne], vInfo[index][vehColorTwo], vInfo[index][vehX], 
                vInfo[index][vehY], vInfo[index][vehZ], vInfo[index][vehA]);
                mysql_tquery(mysql, query, "OnDealerVehicleCreated", "i", index);

                DestroyDynamic3DTextLabel(vInfo[i][vehLabel]);

                GivePlayerCash(playerid, -vInfo[i][vehPrice]);
                GetPlayerName(playerid, vInfo[i][vehOwner], MAX_PLAYER_NAME);

                SetVehicleParamsForPlayer(vInfo[i][vehSessionID], playerid, 0, 0);
                vInfo[i][vehLock] = MODE_NOLOCK;

                format(vInfo[i][vehOwner], MAX_PLAYER_NAME, GetName(playerid));

                Iter_Add(PrivateVehicles[playerid], i);
                Info[playerid][vehLimit]++;
                SaveVehicle(i);

                format(query, sizeof(query), "has bought %s for $%s", vInfo[i][vehName], cNumber(vInfo[i][vehPrice]));
                SaveLog(playerid, query);
            }
        }
        case DIALOG_VEHICLES:
        {
            if(response)
            {
                new count = 0;
                foreach(new i : PrivateVehicles[playerid])
                {
                    if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
                    {
                        if(count == listitem)
                        {
                            SetPVarInt(playerid, "playerVehID", i);
                            ShowPlayerDialog(playerid, DIALOG_VEHICLES+1, DIALOG_STYLE_LIST, "Vehicles", "Spawn Car\nChange Number Plate\nLock\nUnlock\nEmpty", "Select", "Close");
                            break;
                        }
                        else count++;
                    }
                }
            }
        }
        case DIALOG_VEHICLES+1:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        new i = GetPVarInt(playerid, "playerVehID");

                        GetPlayerPos(playerid, vInfo[i][vehX], vInfo[i][vehY], vInfo[i][vehZ]);
                        GetPlayerFacingAngle(playerid, vInfo[i][vehA]);
                        GivePlayerCash(playerid, -1000);

                        createVehicle(i, vInfo[i][vehX]+3, vInfo[i][vehY], vInfo[i][vehZ], vInfo[i][vehA], true);
                        SaveVehicle(i);
                    }
                    case 1: ShowPlayerDialog(playerid, DIALOG_VEHICLES+2, DIALOG_STYLE_INPUT, "Vehicle Plate", "{FFFFFF}Enter the new vehicle number plate below", "Next", "Close");
                    case 2:
                    {
                        new i = GetPVarInt(playerid, "playerVehID");

                        foreach(new x : Player) if(x != playerid) SetVehicleParamsForPlayer(vInfo[i][vehSessionID], x, 0, 1);

                        vInfo[i][vehLock] = MODE_LOCK;
                        SaveVehicle(i);
                        SCM(playerid, green, "You have locked your vehicle");
                    }
                    case 3:
                    {
                        new i = GetPVarInt(playerid, "playerVehID");

                        foreach(new x : Player) if(x != playerid) SetVehicleParamsForPlayer(vInfo[i][vehSessionID], x, 0, 0);
                        vInfo[i][vehLock] = MODE_NOLOCK;
                        SaveVehicle(i);
                        SCM(playerid, green, "You have unlocked your vehicle");
                    }
                    case 4:
                    {
                        new i = GetPVarInt(playerid, "playerVehID");

                        foreach(new x : Player)
                        {
                            if(IsPlayerInVehicle(x, vInfo[i][vehSessionID]))
                            {
                                RemovePlayerFromVehicle(x);
                            }
                        }
                        SCM(playerid, green, "You have ejected all the players from your vehicle");
                    }
                }
            }
        }
        case DIALOG_VEHICLES+2:
        {
            if(response)
            {
                new i = GetPVarInt(playerid, "playerVehID");

                SetVehicleNumberPlate(vInfo[i][vehSessionID], inputtext);
                format(vInfo[i][vehPlate], 16, inputtext);

                SetVehicleToRespawn(vInfo[i][vehSessionID]);
                GivePlayerCash(playerid, -1000);

                if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
                {
                    new Float:playerX, Float:playerY, Float:playerZ;
                    GetPlayerPos(playerid, playerX, playerY, playerZ);

                    SetVehiclePos(vInfo[i][vehSessionID], playerX, playerY, playerZ);
                    PutPlayerInVehicle(playerid, vInfo[i][vehSessionID], 0);
                }

                SaveVehicle(i);
            }
        }
        case DIALOG_AMMU:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: ShowPlayerDialog(playerid, DIALOG_AMMU+1, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Melee", "Weapon\tPrice\nFlowers\t$"#COST_FLOWERS"\nNightstick\t$"#COST_STICK"", "Buy", "Back");
                    case 1: ShowPlayerDialog(playerid, DIALOG_AMMU+2, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Pistols", "Weapon\tPrice\n9MM\t$"#COST_9MM"\nSilenced 9MM\t$"#COST_SILENCED"\nDesert Eagle\t$"#COST_DEAGLE"", "Buy", "Back");
                    case 2: ShowPlayerDialog(playerid, DIALOG_AMMU+3, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Micro SMGs", "Weapon\tPrice\nTec9\t$"#COST_TEC9"\nMicro SMG\t$"#COST_MICRO"\nSMG\t$"#COST_SMG"", "Buy", "Back");
                    case 3: ShowPlayerDialog(playerid, DIALOG_AMMU+4, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Shotguns", "Weapon\tPrice\nShotgun\t$"#COST_SHOTGUN"\nSawnoff Shotgun\t$"#COST_SAWNOFF"\nCombat Shotgun\t$"#COST_COMBAT"", "Buy", "Back");
                    case 4: ShowPlayerDialog(playerid, DIALOG_AMMU+5, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Thrown", "Weapon\tPrice\nGrenade\t$"#COST_GRENADE"", "Buy", "Back");
                    case 5: ShowPlayerDialog(playerid, DIALOG_AMMU+6, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Armour", "Weapon\tPrice\nBody Armour\t$"#COST_ARMOR"", "Buy", "Back");
                    case 6: ShowPlayerDialog(playerid, DIALOG_AMMU+7, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Rifles", "Weapon\tPrice\nRifle\t$"#COST_RIFLE"\nSniper Rifle\t$"#COST_SNIPER"", "Buy", "Back");
                    case 7: ShowPlayerDialog(playerid, DIALOG_AMMU+8, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Assault", "Weapon\tPrice\nAK47\t$"#COST_AK47"\nM4\t$"#COST_M4"", "Buy", "Back");
                }
            }
        }
        case DIALOG_AMMU+1:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_FLOWERS) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_FLOWER, 1), GivePlayerCash(playerid, -COST_FLOWERS);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < COST_STICK) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_NITESTICK, 1), GivePlayerCash(playerid, -COST_STICK);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+1, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Melee", "Weapon\tPrice\nFlowers\t$"#COST_FLOWERS"\nNightstick\t$"#COST_STICK"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+2:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_9MM) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_COLT45, AMMO_9MM), GivePlayerCash(playerid, -COST_9MM);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < COST_SILENCED) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_SILENCED, AMMO_SILENCED), GivePlayerCash(playerid, -COST_SILENCED);
                    }
                    case 2:
                    {
                        if(GetPlayerCash(playerid) < COST_DEAGLE) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_DEAGLE, AMMO_DEAGLE), GivePlayerCash(playerid, -COST_DEAGLE);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+2, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Pistols", "Weapon\tPrice\n9MM\t$"#COST_9MM"\nSilenced 9MM\t$"#COST_SILENCED"\nDesert Eagle\t$"#COST_DEAGLE"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+3:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_TEC9) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_TEC9, AMMO_TEC9), GivePlayerCash(playerid, -COST_TEC9);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < COST_MICRO) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_UZI, AMMO_MICRO), GivePlayerCash(playerid, -COST_MICRO);
                    
                    }
                    case 2:
                    {
                        if(GetPlayerCash(playerid) < COST_SMG) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_MP5, AMMO_SMG), GivePlayerCash(playerid, -COST_SMG);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+3, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Micro SMGs", "Weapon\tPrice\nTec9\t$"#COST_TEC9"\nMicro SMG\t$"#COST_MICRO"\nSMG\t$"#COST_SMG"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+4:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_SHOTGUN) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_SHOTGUN, AMMO_SHOTGUN), GivePlayerCash(playerid, -COST_SHOTGUN);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < COST_SAWNOFF) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_SAWEDOFF, AMMO_SAWNOFF), GivePlayerCash(playerid, -COST_SAWNOFF);
                    }
                    case 2:
                    {
                        if(GetPlayerCash(playerid) < COST_COMBAT) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_SHOTGSPA, AMMO_COMBAT), GivePlayerCash(playerid, -COST_COMBAT);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+4, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Shotguns", "Weapon\tPrice\nShotgun\t$"#COST_SHOTGUN"\nSawnoff Shotgun\t$"#COST_SAWNOFF"\nCombat Shotgun\t$"#COST_COMBAT"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+5:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_GRENADE) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_GRENADE, AMMO_GRENADE), GivePlayerCash(playerid, -COST_GRENADE);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+5, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Thrown", "Weapon\tPrice\nGrenade\t$"#COST_GRENADE"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+6:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_ARMOR) return SCM(playerid, red, "You don't have enough money");
                        SetPlayerArmourEx(playerid, 100.0), GivePlayerCash(playerid, -COST_ARMOR);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+6, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Armour", "Weapon\tPrice\nBody Armour\t$"#COST_ARMOR"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+7:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_RIFLE) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_RIFLE, AMMO_RIFLE), GivePlayerCash(playerid, -COST_RIFLE);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < COST_SNIPER) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_SNIPER, AMMO_SNIPER), GivePlayerCash(playerid, -COST_SNIPER);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+7, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Rifles", "Weapon\tPrice\nRifle\t$"#COST_RIFLE"\nSniper Rifle\t$"#COST_SNIPER"", "Buy", "Back");
            }
        }
        case DIALOG_AMMU+8:
        {
            if(!response) OnPlayerEnterDynamicCP(playerid, ammuCP[0]);
            else
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(GetPlayerCash(playerid) < COST_AK47) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_AK47, AMMO_AK47), GivePlayerCash(playerid, -COST_AK47);
                    }
                    case 1:
                    {
                        if(GetPlayerCash(playerid) < COST_M4) return SCM(playerid, red, "You don't have enough money");
                        GivePlayerWeaponEx(playerid, WEAPON_M4, AMMO_M4), GivePlayerCash(playerid, -COST_M4);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_AMMU+8, DIALOG_STYLE_TABLIST_HEADERS, "Ammu Nation - Assault", "Weapon\tPrice\nAK47\t$"#COST_AK47"\nM4\t$"#COST_M4"", "Buy", "Back");
            }
        }
        case DIALOG_TITLES:
        {
            if(response)
            {
                new string[84], Float:x, Float:y, Float:z;
                format(string, sizeof(string), "%s (Level %i)", LevelArray[listitem][Title], Info[playerid][xLevel]);
            
                GetPlayerPos(playerid, x, y, z);

                if(IsValidDynamic3DTextLabel(PlayerTag[playerid])) DestroyDynamic3DTextLabel(PlayerTag[playerid]);
                if(IsValidDynamic3DTextLabel(PlayerTitle[playerid])) DestroyDynamic3DTextLabel(PlayerTitle[playerid]);

                PlayerTitle[playerid] = CreateDynamic3DTextLabel(string, 0x9999FFFF, x, y, (z + 0.8) + z, 15.0, playerid);

                format(string, sizeof(string), "You have changed your title to: %s", LevelArray[listitem][Title]);
                SCM(playerid, 0x9999FFFF, string);
            }
        }
        case DIALOGS+374:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                    {
                        if(!IsPlayerInStunt(playerid)) return SCM(playerid, red, "You must be in an open area to spawn an airplane");

                        ShowModelSelectionMenu(playerid, Airplanes, "Airplanes");
                    }
                    case 1: ShowModelSelectionMenu(playerid, Bikes, "Bikes");
                    case 2: ShowModelSelectionMenu(playerid, Boats, "Boats");
                    case 3: ShowModelSelectionMenu(playerid, Convertible, "Convertible");
                    case 4: ShowModelSelectionMenu(playerid, Helicopters, "Helicopters");
                    case 5: ShowModelSelectionMenu(playerid, Industrials, "Industrials");
                    case 6: ShowModelSelectionMenu(playerid, Lowrider, "Lowrider");
                    case 7: ShowModelSelectionMenu(playerid, OffRoad, "OffRoad Vehicle");
                    case 8: ShowModelSelectionMenu(playerid, PublicService, "Public Service");
                    case 9: ShowModelSelectionMenu(playerid, Saloon, "Saloons");
                    case 10: ShowModelSelectionMenu(playerid, Sports, "Sport Cars");
                    case 11: ShowModelSelectionMenu(playerid, StationWagon, "StationWagon");
                    case 12: ShowModelSelectionMenu(playerid, Unique, "Unique Vehicles");
                }
            }
        }
        case DIALOG_PROPERTIES: {

            if(listitem == PlayerItem[playerid])
            {
                if(strfind(inputtext, "Back", true, 0) != -1)
                {
                    cmd_properties(playerid, "");
                }
                else
                {
                    new string[128], cstring[128 * 10], cnt = 0;
                    for(new i; i < 1000; i++)
                    {
                        if(i == 0)
                        {
                            i = CompleteLoop[playerid];
                        }
                        if(cnt > 9)
                        {
                            strcat(cstring, "Next\n");
                            break;
                        }
                        else
                        {
                            if(pOwns(playerid, i))
                            {
                                new diff_secs = ( pInfo[i][PropertyExpire] - gettime() );
                                new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
                                diff_secs -= remain_months * 60 * 60 * 24 * 30;
                                new remain_days = ( diff_secs / (60 * 60 * 24) );
                                diff_secs -= remain_days * 60 * 60 * 24;
                                new remain_hours = ( diff_secs / (60 * 60) );
                                diff_secs -= remain_hours * 60 * 60;
                                new remain_minutes = ( diff_secs / 60 );

                                format(string, sizeof(string), "{FFFFFF}Property: {00FF00}%s {FFFFFF}Location: {00FF00}%s (%d months %d days %d hours %d minutes)\n", pInfo[i][prName], GetZoneName(pInfo[i][PropertyX], pInfo[i][PropertyY], pInfo[i][PropertyZ]),
                                remain_months, remain_days, remain_hours, remain_minutes);
                                strcat(cstring, string);

                                cnt++;
                                CompleteLoop[playerid] += 1;
                                PlayerItem[playerid] = cnt;
                            }
                        }
                    }
                    if(cnt <= 9)
                    {
                        strcat(cstring, "Back\n");
                    }
                    if(cnt == 0) ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Properties", "{FF0000}No properties found", "Close", "");
                    else ShowPlayerDialog(playerid, DIALOG_PROPERTIES, DIALOG_STYLE_LIST, "Properties", cstring, "Close", "");
                }
            }
        }
        case DIALOG_HOUSES: {

            if(listitem == PlayerItem[playerid])
            {
                if(strfind(inputtext, "Back", true, 0) != -1)
                {
                    cmd_houses(playerid, "");
                }
                else
                {
                    new string[128], cstring[128 * 10], cnt = 0;
                    for(new i; i < 1000; i++)
                    {
                        if(i == 0)
                        {
                            i = CompleteLoop[playerid];
                        }
                        if(cnt > 9)
                        {
                            strcat(cstring, "Next\n");
                            break;
                        }
                        else
                        {
                            if(!strcmp(HouseData[i][Owner], GetName(playerid)))
                            {
                                new diff_secs = ( HouseData[i][HouseExpire] - gettime() );
                                new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
                                diff_secs -= remain_months * 60 * 60 * 24 * 30;
                                new remain_days = ( diff_secs / (60 * 60 * 24) );
                                diff_secs -= remain_days * 60 * 60 * 24;
                                new remain_hours = ( diff_secs / (60 * 60) );
                                diff_secs -= remain_hours * 60 * 60;
                                new remain_minutes = ( diff_secs / 60 );

                                format(string, sizeof(string), "{FFFFFF}House: {00FF00}%d {FFFFFF}Location: {00FF00}%s {FFFFFF}(%d months %d days %d hours %d minutes)\n", i, GetZoneName(HouseData[i][houseX], HouseData[i][houseY],
                                HouseData[i][houseZ]), remain_months, remain_days, remain_hours, remain_minutes);
                                strcat(cstring, string);

                                cnt++;
                                CompleteLoop[playerid] += 1;
                                PlayerItem[playerid] = cnt;
                            }
                        }
                    }
                    if(cnt <= 9)
                    {
                        strcat(cstring, "Back\n");
                    }
                    if(cnt == 0) ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Houses", "{FF0000}No houses found", "Close", "");
                    else ShowPlayerDialog(playerid, DIALOG_HOUSES, DIALOG_STYLE_LIST, "Houses", cstring, "Close", "");
                }
            }
        }
    }
    return 0;
}

/*----------------------------------------------------------------------------*/
/*--------------------------Commands of the Server----------------------------*/
/*----------------------------------------------------------------------------*/

CMD:commands(playerid, params[])
{
	new string[700];
	strcat(string, "{00FF00}Game Account\n");
	strcat(string, "{FFFFFF}/password /name /stats /inventory /autologin\n\n");
	strcat(string, "{00FF00}Game Shop\n");
	strcat(string, "{FFFFFF}/shop /sellmoney /sellcancel /market /playersmoney\n\n");
	strcat(string, "{00FF00}Game Server\n");
	strcat(string, "{FFFFFF}/admins /helpers /credits /rules /report /news /help\n\n");
	strcat(string, "{00FF00}Messages & Chat\n");
	strcat(string, "{FFFFFF}/pm /re /team /local /global /me /opm /myopms\n\n");
    strcat(string, "{00FF00}Premium Account\n");
    strcat(string, "{FFFFFF}/premium /premiumchat /tag /untag /hide /color /vote /flip /timer\n\n");
    strcat(string, "{00FF00}Minigames\n");
    strcat(string, "{FFFFFF}/parkour /skydive /dm /tdm /derby\n\n");
    strcat(string, "{00FF00}Vehicles\n");
    strcat(string, "{FFFFFF}/eject /lock /unlock /hood /trunk /lights /engine\n/buyvehicle /vehicles /changeplate\n\n");
    strcat(string, "{00FF00}Misc Commands\n");
    strcat(string, "{FFFFFF}/kill /radio /hit /bounty /selfie /position\n\n");
	ShowPlayerDialog(playerid, DIALOG_CMDS, DIALOG_STYLE_MSGBOX, "Server Commands", string, "Next", "Close");
	return 1;
}
CMD:cmds(playerid, params[]) return cmd_commands(playerid, params);

CMD:help(playerid, params[])
{
	new string[800];
	strcat(string, "{FFFFFF}Commands\n");
	strcat(string, "{FFFFFF}Rules\n");
	strcat(string, "{FFFFFF}How to earn money?\n");
	strcat(string, "{FFFFFF}Vehicles\n");
	strcat(string, "{FFFFFF}Gangs\n");
	strcat(string, "{FFFFFF}Animations\n");
	strcat(string, "{FFFFFF}Skins\n");
	strcat(string, "{FFFFFF}Wanted stars\n");
	strcat(string, "{FFFFFF}Marijuana\n");
	strcat(string, "{FFFFFF}Cocaine\n");
	strcat(string, "{FFFFFF}XP\n");
	strcat(string, "{FFFFFF}Premium account\n");
    strcat(string, "{FFFFFF}Weapons\n");
    strcat(string, "{FFFFFF}Houses\n");
    strcat(string, "{FFFFFF}Properties\n");
	ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_LIST, "Help", string, "Select", "Close");
	return 1;
}

CMD:wl(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_HELP+3, DIALOG_STYLE_MSGBOX, "Wanted Stars", "{FFFFFF}You can evade your wanted stars by using Pay'N'Spray\n{FFFFFF}while you are in the vehicle.", "Close", "");
	return 1;
}

CMD:earn(playerid, params[])
{
	new string[580];
	strcat(string, "{FFFFFF}There are multiple ways how to earn money in this server. You can try\n");
	strcat(string, "{FFFFFF}one of the side activites to earn some money.\n\n");
	strcat(string, "{00FF00}How to earn money?\n");
	strcat(string, "{FFFFFF}- Purchase a property and collect the revenue.\n");
    strcat(string, "{FFFFFF}- Attack enemy's gang hoods.\n");
	strcat(string, "{FFFFFF}- Win minigames.\n");
	strcat(string, "{FFFFFF}- Kill players.\n");
    ShowPlayerDialog(playerid, DIALOG_HELP+4, DIALOG_STYLE_MSGBOX, "How to earn money?", string, "Close", "");
	return 1;
}

CMD:rules(playerid, params[])
{
    new string[800];
    strcat(string, "{00FF00}1. {FFFFFF}Using cheats, mods, bugs and glitches is forbidden.\n");
    strcat(string, "{00FF00}2. {FFFFFF}You must not spam, defame, harass, threaten, intimidate or impersonate other players.\n");
    strcat(string, "{00FF00}3. {FFFFFF}You must not advertise other game servers or web pages.\n");
    strcat(string, "{00FF00}4. {FFFFFF}Spawn killing, killing players on minigames and killing players on events is forbidden.\n");
    strcat(string, "{00FF00}5. {FFFFFF}Bug abuse is forbidden, you are obliged to report any bug on our forums.\n");
    strcat(string, "{00FF00}6. {FFFFFF}Registering multiple accounts and boosting stats is forbidden.\n");
    strcat(string, "{00FF00}7. {FFFFFF}Giving away / trading / selling accounts are forbidden.\n");
    strcat(string, "{00FF00}8. {FFFFFF}You are allowed to speak only English.\n");
    strcat(string, "{00FF00}9. {FFFFFF}Scamming players is forbidden.\n");
    strcat(string, "{00FF00}10. {FFFFFF}You must obey Administrators, Moderators.");
    ShowPlayerDialog(playerid, N, DIALOG_STYLE_MSGBOX, "{FFFFFF}Server Rules", string, "Close", "");
    return 1;
}

CMD:credits(playerid, params[])
{
    new string[240];
    strcat(string, "{FFFFFF}Explosive Freeroam\nv0.1 by _oMa37\n\n");
    strcat(string, "{FFFFFF}Founder/Developer: _oMa37\nOwner: YoUnG_MoNeY\n");
    strcat(string, "{FFFFFF}Special Thanks: Konstantinos, IwAn, Frank\n\n");
    strcat(string, "{FFFFFF}Visit our website: UN-GAMING.COM\nThank you for playing on our game server!");
    ShowPlayerDialog(playerid, DIALOG_HELP+6, DIALOG_STYLE_MSGBOX, "Credits", string, "Close", "");
    return 1;
}

CMD:about(playerid, params[])
{
    new string[920];
    strcat(string, "{00FF00}Why should you play on our server?\n");
    strcat(string, "{FFFFFF}- Unique features and unlimited fun!\n");
    strcat(string, "{FFFFFF}- Professional and friendly staff members.\n");
    strcat(string, "{FFFFFF}- We do not allow cheats/hacks on our server!\n\n");
    strcat(string, "{00FF00}What features we have in this server?\n");
    strcat(string, "{FFFFFF}- Minigames: A lot of minigames where you can play with your friends!\n");
    strcat(string, "{FFFFFF}- Gang Wars: You can join gangs and attack enemies territories!\n");
    strcat(string, "{FFFFFF}- Properties: You can purchase properties and earn money by collecting revenue!\n");
    strcat(string, "{FFFFFF}- Houses: You can purchase houses and make parties or even save your guns/money in it!\n");
    strcat(string, "{FFFFFF}- Vehicles: You can buy vehicles from the vehicle dealers around LS and spawn it whenever you want!\n");
    strcat(string, "{FFFFFF}- Clubs, Ammu-Nations, Stunts and much more to explore!\n");
    ShowPlayerDialog(playerid, DIALOG_HELP+7, DIALOG_STYLE_MSGBOX, "About", string, "Close", "");
    return 1;
}

CMD:stats(playerid, params[])
{
    new id, string[580];
    new deaths = Info[playerid][Deaths];
    if(!deaths) deaths = 1;
    new Float:kd =  floatdiv(Info[playerid][Kills], deaths);

    if(isnull(params))
    {
        format(string, sizeof(string), 
        "{FFFFFF}Account ID: {00FF00}%i\n{FFFFFF}Playing time: {00FF00}%i hours and %i minute\n{FFFFFF}Money: {00FF00}$%s\n{FFFFFF}Level: {00FF00}%i\n{FFFFFF}XP: {00FF00}%i/%i\n{FFFFFF}Players killed: {00FF00}%i\n\
        {FFFFFF}Times died: {00FF00}%i\n{FFFFFF}Suicides: {00FF00}%i\n{FFFFFF}Kills/Deaths ratio: {00FF00}%.2f\n{FFFFFF}Moneybags collected: {00FF00}%i", 
        Info[playerid][ID], Info[playerid][Hours], Info[playerid][Minutes], cNumber(GetPlayerCash(playerid)), Info[playerid][xLevel], Info[playerid][XP], 
        2000 + (Info[playerid][xLevel] - 2) * 400 + 400, Info[playerid][Kills], Info[playerid][Deaths], Info[playerid][Suicides], kd, Info[playerid][MoneyBags]);
        ShowPlayerDialog(playerid, DIALOGS+1133, DIALOG_STYLE_MSGBOX, "Statistics", string, "Close", "");
        return 1;
    }

    if(sscanf(params, "u", id)) return SCM(playerid, red, "Player's stats: /stats <PlayerID>");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

    kd =  floatdiv(Info[id][Kills], deaths);

    format(string, sizeof(string), 
    "{FFFFFF}Account ID: {00FF00}%i\n{FFFFFF}Player: {00FF00}%s\n{FFFFFF}Playing time: {00FF00}%i hours and %i minute\n{FFFFFF}Money: {00FF00}$%s\n{FFFFFF}Level: {00FF00}%i\n{FFFFFF}XP: {00FF00}%i/%i\n\
    {FFFFFF}Players killed: {00FF00}%i\n{FFFFFF}Times died: {00FF00}%i\n{FFFFFF}Suicides: {00FF00}%i\n{FFFFFF}Kills/Deaths ratio: {00FF00}%.2f\n{FFFFFF}Moneybags collected: {00FF00}%i",
    Info[id][ID], GetName(id), Info[id][Hours], Info[id][Minutes], cNumber(GetPlayerCash(id)), Info[id][xLevel], Info[id][XP], 2000 + (Info[id][xLevel] - 2) * 400 + 400, Info[id][Kills],
    Info[id][Deaths], Info[id][Suicides], kd, Info[id][MoneyBags]);
    ShowPlayerDialog(playerid, DIALOGS+1133, DIALOG_STYLE_MSGBOX, "Statistics", string, "Close", "");
    return 1;
}

CMD:inventory(playerid, params[])
{
    new string[128];
    format(string, sizeof(string), "{FFFFFF}Marijuana: {00FF00}%i\n{FFFFFF}Cocaine: {00FF00}%i\n{FFFFFF}Seeds: {00FF00}%i\nSkins", Info[playerid][Marijuana], Info[playerid][Cocaine], Info[playerid][Seeds]);
    ShowPlayerDialog(playerid, DIALOG_INV, DIALOG_STYLE_LIST, "Inventory", string, "Select", "Close");
    return 1;
}

CMD:hidetexts(playerid, params[])
{
    if(HideTexts[playerid] == 0)
    {
        HideTexts[playerid] = 1;
        TextDrawHideForPlayer(playerid, Textdraw0);
        TextDrawHideForPlayer(playerid, Textdraw1);
        TextDrawHideForPlayer(playerid, Textdraw2);
        TextDrawHideForPlayer(playerid, Textdraw3);
        TextDrawHideForPlayer(playerid, Textdraw4);
        TextDrawHideForPlayer(playerid, Textdraw5);
        TextDrawHideForPlayer(playerid, Textdraw6);
        TextDrawHideForPlayer(playerid, Textdraw7);
        TextDrawHideForPlayer(playerid, Textdraw8);
        TextDrawHideForPlayer(playerid, Textdraw9);
        TextDrawHideForPlayer(playerid, Textdraw10);
        TextDrawHideForPlayer(playerid, Textdraw11);
        TextDrawHideForPlayer(playerid, Textdraw12);
        TextDrawHideForPlayer(playerid, Textdraw13);
        TextDrawHideForPlayer(playerid, Textdraw14);
        TextDrawHideForPlayer(playerid, Textdraw15);
    }
    else if(HideTexts[playerid] == 1)
    {
        HideTexts[playerid] = 0;
        TextDrawShowForPlayer(playerid, Textdraw0);
        TextDrawShowForPlayer(playerid, Textdraw1);
        TextDrawShowForPlayer(playerid, Textdraw2);
        TextDrawShowForPlayer(playerid, Textdraw3);
        TextDrawShowForPlayer(playerid, Textdraw4);
        TextDrawShowForPlayer(playerid, Textdraw5);
        TextDrawShowForPlayer(playerid, Textdraw6);
        TextDrawShowForPlayer(playerid, Textdraw7);
        TextDrawShowForPlayer(playerid, Textdraw8);
        TextDrawShowForPlayer(playerid, Textdraw9);
        TextDrawShowForPlayer(playerid, Textdraw10);
        TextDrawShowForPlayer(playerid, Textdraw11);
        TextDrawShowForPlayer(playerid, Textdraw12);
        TextDrawShowForPlayer(playerid, Textdraw13);
        TextDrawShowForPlayer(playerid, Textdraw14);
        TextDrawShowForPlayer(playerid, Textdraw15);
    }
    return 1;
}

CMD:autologin(playerid, params[])
{
    if(Info[playerid][AutoLogin] == 1)
    {
        Info[playerid][AutoLogin] = 0;
        SCM(playerid, red, "You have turned off your auto login");
    }
    else
    {
        SCM(playerid, green, "You have turned on your auto login");
        Info[playerid][AutoLogin] = 1;
    }
    SavePlayerData(playerid, 0, 1);
    return 1;
}

CMD:savestats(playerid, params[])
{
    SavePlayerData(playerid, 0, 1);
    SCM(playerid, green, "You have saved your stats");
    return 1;
}

CMD:changepassword(playerid, params[])
{
    new query[320], hash[129];
    if(isnull(params)) return SCM(playerid, red, "Change password: /changepassword <NewPassword>");
    if(strlen(params) > 129 || strlen(params) < 3) return SCM(playerid, red, "Invalid password length");

    WP_Hash(hash, 129, params);
    mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `Password` = '%e', `AutoLogin` = 0  WHERE `ID` = %d", hash, Info[playerid][ID]);
    mysql_tquery(mysql, query);

    format(query, sizeof(query), "You have changed your password to %s", params);
    SCM(playerid, green, query);
    return 1;
}

CMD:selfie(playerid,params[])
{
    if(InSelfie[playerid] == 0)
    {
        GetPlayerPos(playerid,SelfieX[playerid],SelfieY[playerid],SelfieZ[playerid]);
        new Float: n1X, Float: n1Y;
        if(Degree[playerid] >= 360) Degree[playerid] = 0;
        Degree[playerid] += Speed;
        n1X = SelfieX[playerid] + Radius * floatcos(Degree[playerid], degrees);
        n1Y = SelfieY[playerid] + Radius * floatsin(Degree[playerid], degrees);
        SetPlayerCameraPos(playerid, n1X, n1Y, SelfieZ[playerid] + Height);
        SetPlayerCameraLookAt(playerid, SelfieX[playerid], SelfieY[playerid], SelfieZ[playerid]+1);
        SetPlayerFacingAngle(playerid, Degree[playerid] - 90.0);
        TogglePlayerControllable(playerid, 0);
        InSelfie[playerid] = 1;
        ApplyAnimation(playerid, "PED", "gang_gunstand", 4.1, 1, 1, 1, 1, 1, 1);
        return 1;
    }
    if(InSelfie[playerid] == 1)
    {
        TogglePlayerControllable(playerid, 1);
        SetCameraBehindPlayer(playerid);
        InSelfie[playerid] = 0;
        ClearAnimations(playerid);
        return 1;
    }
    return 1;
}

CMD:animations(playerid, params[])
{
    new string[600];
    strcat(string,"{FFFFFF}/basket /drunk /bomb /laugh /lookout /robman /lay /wave /shout /knife /deal /pee\n");
    strcat(string,"{FFFFFF}/chat /fu /taichi /kiss /injured /sup /rap /push /medic /koface /cop /chant /finger\n");
    strcat(string,"{FFFFFF}/jump /strip /dance /bed /lean /aim /sit /fallback /crossarms /blowjob /kneekick\n");
    strcat(string,"{FFFFFF}/punch /elbow /spank /airkick /carlock /box \n");
    ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Animations", string, "Close", "");
    return 1;
}
CMD:anims(playerid, params[]) return cmd_animations(playerid, params);

CMD:fallback(playerid, params[])
{
    LoopingAnim(playerid,"PED","FLOOR_hit_f", 4.0, 1, 0, 0, 0, 0);
    return 1;
}

CMD:drunk(playerid, params[])
{
    LoopingAnim(playerid,"PED","WALK_DRUNK",4.1,1,1,1,1,1);
    return 1;
}

CMD:bomb(playerid, params[])
{
    LoopingAnim(playerid, "BOMBER","BOM_Plant_Loop",4.0,1,0,0,1,0);
    return 1;
}

CMD:laugh(playerid, params[])
{
    OnePlayAnim(playerid, "RAPPING", "Laugh_01", 4.0, 0, 0, 0, 0, 0);
    return 1;
}

CMD:lookout(playerid, params[])
{
    OnePlayAnim(playerid, "SHOP", "ROB_Shifty", 4.0, 0, 0, 0, 0, 0);
    return 1;
}

CMD:robman(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Robman animation: /robman <1-2>");

    new id = strval(params);

    if(id < 1 || id > 2) return SCM(playerid, red, "Robman animation: /robman <1-2>");

    switch(id)
    {
        case 1: LoopingAnim(playerid, "COP_AMBIENT", "Coplook_loop", 4.0, 0, 1, 1, 1, -1);
        case 2: LoopingAnim(playerid, "SHOP", "ROB_Loop_Threat", 4.0, 1, 0, 0, 0, 0);
    }
    return 1;
}

CMD:wave(playerid, params[])
{
    LoopingAnim(playerid, "ON_LOOKERS", "wave_loop", 4.0, 1, 0, 0, 0, 0);
    return 1;
}

CMD:slapa(playerid, params[])
{
    OnePlayAnim(playerid, "SWEET", "sweet_ass_slap", 4.0, 0, 0, 0, 0, 0);
    return 1;
}

CMD:deal(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Deal animation: /deal <1-2>");

    new id = strval(params);

    if(id < 1 || id > 2) return SCM(playerid, red, "Deal animation: /deal <1-2>");

    switch(id)
    {
        case 1: LoopingAnim(playerid,"DEALER","DEALER_IDLE",4.0,1,0,0,0,0);
        case 2: OnePlayAnim(playerid, "DEALER", "DEALER_DEAL", 4.0, 0, 0, 0, 0, 0);
    }
    return 1;
}

CMD:chat(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Chat animation: /chat <1-2>");

    new id = strval(params);

    if(id < 1 || id > 2) return SCM(playerid, red, "Chat animation: /chat <1-2>");

    switch(id)
    {
        case 1: LoopingAnim(playerid,"PED","IDLE_CHAT",4.0,1,0,0,1,1);
        case 2: LoopingAnim(playerid,"MISC","Idle_Chat_02",4.0,1,0,0,1,1);
    }
    return 1;
}

CMD:fu(playerid, params[])
{
    OnePlayAnim(playerid,"PED","fucku",4.0,0,0,0,0,0);
    return 1;
}

CMD:taichi(playerid, params[])
{
    LoopingAnim(playerid,"PARK","Tai_Chi_Loop",4.0,1,0,0,0,0);
    return 1;
}

CMD:kiss(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Kiss animation: /kiss <1-2>");

    new id = strval(params);

    if(id < 1 || id > 2) return SCM(playerid, red, "Kiss animation: /kiss <1-2>");

    switch(id)
    {
        case 1: OnePlayAnim(playerid, "KISSING", "Playa_Kiss_02", 3.0, 0, 0, 0, 0, 0);
        case 2: OnePlayAnim(playerid, "BD_Fire", "grlfrd_kiss_03", 2.0, 0, 0, 0, 0, 0);
    }
    return 1;
}

CMD:injured(playerid, params[])
{
    LoopingAnim(playerid, "SWEET", "Sweet_injuredloop", 4.0, 1, 0, 0, 0, 0);
    return 1;
}

CMD:sup(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Sup animation: /sup <1-3>");

    new id = strval(params);

    if(id < 1 || id > 3) return SCM(playerid, red, "Sup animation: /sup <1-3>");

    switch(id)
    {
        case 1: OnePlayAnim(playerid,"GANGS","hndshkba",4.0,0,0,0,0,0);
        case 2: OnePlayAnim(playerid,"GANGS","hndshkda",4.0,0,0,0,0,0);
        case 3: OnePlayAnim(playerid,"GANGS","hndshkfa_swt",4.0,0,0,0,0,0);
    }
    return 1;
}

CMD:blowjob(playerid, params[])
{
    LoopingAnim(playerid, "BLOWJOBZ", "BJ_STAND_LOOP_P", 4.1, 1, 0, 0, 0, 0);
    return 1;
}

CMD:spank(playerid, params[])
{
    LoopingAnim(playerid, "SNM", "SPANKINGW", 4.1, 1, 0, 0, 0, 0);
    return 1;
}

CMD:push(playerid, params[])
{
    OnePlayAnim(playerid,"GANGS","shake_cara",4.0,0,0,0,0,0);
    return 1;
}

CMD:medic(playerid, params[])
{
    OnePlayAnim(playerid,"MEDIC","CPR",4.0,0,0,0,0,0);
    return 1;
}

CMD:koface(playerid, params[])
{
    LoopingAnim(playerid,"PED","KO_shot_face",4.0,0,1,1,1,0);
    return 1;
}

CMD:jump(playerid, params[])
{
    LoopingAnim(playerid,"PED","EV_dive",4.0,0,1,1,1,0);
    return 1;
}

CMD:fall(playerid, params[])
{
    LoopingAnim(playerid,"PED", "KO_skid_front",4.1,0,1,1,1,0);
    return 1;
}

CMD:dance(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Dance animation: /dance <1-4>");

    new id = strval(params);

    if(id < 1 || id > 4) return SCM(playerid, red, "Dance animation: /dance <1-4>");

    switch(id)
    {
        case 1: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE1);
        case 2: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE2);
        case 3: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE3);
        case 4: SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE4);
    }
    return 1;
}

CMD:bed(playerid, params[])
{
    LoopingAnim(playerid,"INT_HOUSE","BED_Loop_R",4.0,1,0,0,0,0);
    return 1;
}

CMD:lean(playerid, params[])
{
    LoopingAnim(playerid,"GANGS","leanIDLE",4.0,0,1,1,1,0);
    return 1;
}

CMD:kneekick(playerid, params[])
{
    OnePlayAnim(playerid,"FIGHT_D","FightD_2",4.0,0,1,1,0,0);
    return 1;
}

CMD:punch(playerid, params[])
{
    OnePlayAnim(playerid,"FIGHT_B","FightB_G",4.0,0,0,0,0,0);
    return 1;
}

CMD:elbow(playerid, params[])
{
    OnePlayAnim(playerid,"FIGHT_D","FightD_3",4.0,0,1,1,0,0);
    return 1;
}

CMD:airkick(playerid, params[])
{
    OnePlayAnim(playerid,"FIGHT_C","FightC_M",4.0,0,1,1,0,0);
    return 1;
}

CMD:carlock(playerid, params[])
{
    OnePlayAnim(playerid,"PED","CAR_doorlocked_LHS",4.0,0,0,0,0,0);
    return 1;
}

CMD:box(playerid, params[])
{
    LoopingAnim(playerid,"GYMNASIUM","GYMshadowbox",4.0,1,1,1,1,0);
    return 1;
}

CMD:chant(playerid, params[])
{
    LoopingAnim(playerid,"RIOT","RIOT_CHANT",4.0,1,1,1,1,0);
    return 1;
}

CMD:finger(playerid, params[])
{
    OnePlayAnim(playerid,"RIOT","RIOT_FUKU",2.0,0,0,0,0,0);
    return 1;
}

CMD:shout(playerid, params[])
{
    LoopingAnim(playerid,"RIOT","RIOT_shout",4.0,1,0,0,0,0);
    return 1;
}

CMD:knife(playerid, params[])
{
    OnePlayAnim(playerid,"KNIFE","KILL_Knife_Player",4.0,0,0,0,0,0);
    return 1;
}

CMD:cop(playerid, params[])
{
    OnePlayAnim(playerid,"SWORD","sword_block",50.0,0,1,1,1,1);
    return 1;
}

CMD:pee(playerid, params[])
{
    SetPlayerSpecialAction(playerid, 68);
    return 1;
}

CMD:basket(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Basket animation: /basket <1-4>");

    new id = strval(params);

    if(id < 1 || id > 4) return SCM(playerid, red, "Basket animation: /basket <1-4>");

    switch(id)
    {
        case 1: LoopingAnim(playerid,"BSKTBALL","BBALL_idleloop",4.0,1,0,0,0,0);
        case 2: OnePlayAnim(playerid,"BSKTBALL","BBALL_Jump_Shot",4.0,0,0,0,0,0);
        case 3: OnePlayAnim(playerid,"BSKTBALL","BBALL_pickup",4.0,0,0,0,0,0);
        case 4: LoopingAnim(playerid,"BSKTBALL","BBALL_run",4.1,1,1,1,1,1);
    }
    return 1;
}

CMD:sit(playerid, params[])
{
    if(isnull(params)) return SCM(playerid, red, "Sit animation: /sit <1-6>");

    new id = strval(params);

    if(id < 1 || id > 6) return SCM(playerid, red, "Sit animation: /sit <1-6>");

    switch(id)
    {
        case 1: LoopingAnim(playerid,"BEACH", "bather", 4.0, 1, 0, 0, 0, 0);
        case 2: LoopingAnim(playerid,"SUNBATHE","Lay_Bac_in",3.0,0,1,1,1,0);
        case 3: LoopingAnim(playerid,"MISC","seat_lr",2.0,1,0,0,0,0);
        case 4: LoopingAnim(playerid,"MISC","seat_talk_01",2.0,1,0,0,0,0);
        case 5: LoopingAnim(playerid,"MISC","seat_talk_02",2.0,1,0,0,0,0);
        case 6: LoopingAnim(playerid,"BEACH", "ParkSit_M_loop", 4.0, 1, 0, 0, 0, 0);
    }
    return 1;
}

CMD:kill(playerid, params[])
{
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");

    new string[128],
        currenttime = gettime();

    new cooldown = (Cooldown[playerid][0] + 120) - currenttime;
    format(string, sizeof(string),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][0] + 120)) return SCM(playerid,red,string);
    Cooldown[playerid][0] = gettime();

    SetPlayerHealthEx(playerid, 0.0);
    SCM(playerid, red, "You have committed suicide");
    Info[playerid][Suicides]++;
    return 1;
}

CMD:car(playerid, params[])
{
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(GetPlayerInterior(playerid) != 0) return SCM(playerid, red, "You can't spawn a vehicle in interior");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    ShowPlayerDialog(playerid, DIALOGS+374, DIALOG_STYLE_LIST, "Vehicles", "Airplane\nBike\nBoat\nConvertible\nHelicopter\nIndustrial\nLowrider\nOff Road\nPublic Service\nSaloon\nSport\nStation Wagon\nUnique", "Select", "Close");
    return 1;
}

CMD:djump(playerid, params[])
{
    if(JumpStatus[playerid] == 0)
    {
        JumpStatus[playerid] = 1;
        SCM(playerid, green, "You have enabled the double jump");
    }
    else
    {
        JumpStatus[playerid] = 0;
        SCM(playerid, green, "You have disabled the double jump");
    }
    return 1;
}

CMD:title(playerid, params[])
{
    new string[40], lvlstring[300];
    for(new i; i < sizeof(LevelArray); i++)
    {
        if(Info[playerid][xLevel] >= LevelArray[i][titleLevel])
        {
            format(string, sizeof(string), "%s\n", LevelArray[i][Title]);
            strcat(lvlstring, string);
        }
    }
    ShowPlayerDialog(playerid, DIALOG_TITLES, DIALOG_STYLE_LIST, "Titles", lvlstring, "Select", "Close");
    return 1;
}

CMD:removetitle(playerid, params[])
{
    if(IsValidDynamic3DTextLabel(PlayerTitle[playerid]))
    {
        DestroyDynamic3DTextLabel(PlayerTitle[playerid]);
    }
    SCM(playerid, 0x9999FFFF, "You have removed your title");
    return 1;
}

CMD:color(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        if(pTeam[playerid] != NO_TEAM) return SendClientMessage(playerid, red, "You can't use this command while you are in the gang");

        ShowPlayerDialog(playerid, DIALOG_COLORS, DIALOG_STYLE_LIST, "Name Color", "{FFFFFF}White\n{FF6666}Red\n{FFFF33}Yellow\n{99FF66}Green\n{3366FF}Blue\n{9966FF}Purple\n{FF0099}Pink", "Select", "Close");
        return 1;
    }
    else return cmd_benefits(playerid, params);
}

CMD:tag(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        new string[128], text[50];
        if(sscanf(params, "s[50]", text)) return SCM(playerid, red, "Attach tag on your skin: /tag <Text>");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        if(IsValidDynamic3DTextLabel(PlayerTitle[playerid])) DestroyDynamic3DTextLabel(PlayerTitle[playerid]);

        if(IsValidDynamic3DTextLabel(PlayerTag[playerid])) UpdateDynamic3DTextLabelText(PlayerTag[playerid], 0x00FF00FF, text);
        else PlayerTag[playerid] = CreateDynamic3DTextLabel(text, 0x00FF00FF, x, y, (z+0.8) + z, 20.0, playerid);

        format(string, sizeof(string), "You have changed your tag to: %s", text);
        SCM(playerid, green, string);
        return 1;
    }
    else return cmd_benefits(playerid, params);
}

CMD:untag(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        DestroyDynamic3DTextLabel(PlayerTag[playerid]);
        SCM(playerid, green, "You have removed your tag");
        return 1;
    }
    else return cmd_benefits(playerid, params);
}

CMD:vote(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        if(isnull(params)) return SCM(playerid, red, "Make a vote: /vote <Text>");
        if(OnVote == 1) return SCM(playerid, red, "There is already vote started");

        new cmdstring[128],
            currenttime = gettime();

        new cooldown = (Cooldown[playerid][1] + 600) - currenttime;
        format(cmdstring, sizeof(cmdstring),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
        if(currenttime < (Cooldown[playerid][1] + 600)) return SCM(playerid,red,cmdstring);
        Cooldown[playerid][1] = gettime();

        strcpy(Voting[Vote], params, 50);
	    format(cmdstring, sizeof(cmdstring), "%s has started a vote: %s", GetName(playerid), params);
	    SendClientMessageToAll(green, cmdstring);
	    SendClientMessageToAll(green, "Vote: /yes or /no");
        OnVote = 1;

	    SetTimer("CancelVote", 30000, 0);
        return 1;
    }
    else return cmd_benefits(playerid, params);
}

CMD:yes(playerid, params[])
{
    new str[128];
    if(OnVote == 1)
    {
        if(Voted[playerid] == 1) return SCM(playerid, red, "You have already voted, You can't vote again!");

        Voted[playerid] = 1;
        Voting[VoteY]++;
        format(str, sizeof(str), "Vote: %s - Yes: %d No: %d", Voting[Vote], Voting[VoteY], Voting[VoteN]);
        SCM(playerid, yellow, str);
        return 1;
    }
    else return SCM(playerid, red, "There is no vote currently");
}

CMD:no(playerid, params[])
{
    new str[128];
    if(OnVote == 1)
    {
        if(Voted[playerid] == 1) return SCM(playerid, red, "You have already voted, You can't vote again!");

        Voted[playerid] = 1;
        Voting[VoteN]++;
        format(str, sizeof(str), "Vote: %s | Yes: %d No: %d", Voting[Vote], Voting[VoteY], Voting[VoteN]);
        SCM(playerid, yellow, str);
        return 1;
    }
    else return SCM(playerid, red, "There is no vote currently");
}

CMD:hide(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        if(Info[playerid][MapHide] == 0)
        {
            Info[playerid][MapHide] = 1;
            SCM(playerid, 0xCCCC00FF, "Hide on map: ON");
            foreach(new i : Player) SetPlayerMarkerForPlayer(i, playerid, (GetPlayerColor(playerid) & 0xFFFFFF00));
        }
        else if(Info[playerid][MapHide] == 1)
        {
            Info[playerid][MapHide] = 0;
            SCM(playerid, 0xCCCC00FF, "Hide on map: OFF");
            foreach(new i : Player) SetPlayerMarkerForPlayer(i, playerid, GetPlayerColor(playerid));
        }
        return 1;
    }
    else return cmd_benefits(playerid, params);
}

CMD:premiumchat(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        new str[128];
        if(!isnull(params)) return SCM(playerid, red, "Premium chat: /premiumchat <Text>");
    	foreach(new i : Player)
    	{
            if(Info[i][Premium] >= 1)
            {
	            format(str, sizeof(str), "%s (%d) [PREMIUM]: %s", GetName(playerid), playerid, params);
	            SCM(i, GetPlayerColor(playerid), str);
	        }
        }
        return 1; 
    }
    else return cmd_benefits(playerid, params);
}
CMD:p(playerid, params[]) return cmd_premiumchat(playerid, params);

CMD:premium(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        new string[128];

        new diff_secs = ( Info[playerid][PremiumExpires] - gettime() );
        new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
        diff_secs -= remain_months * 60 * 60 * 24 * 30;
        new remain_days = ( diff_secs / (60 * 60 * 24) );
        diff_secs -= remain_days * 60 * 60 * 24;
        new remain_hours = ( diff_secs / (60 * 60) );
        diff_secs -= remain_hours * 60 * 60;
        new remain_minutes = ( diff_secs / 60 );

        format(string, sizeof(string), "{FFFFFF}%i months %i days %i hours %i minutes left for your premium", remain_months, remain_days, remain_hours, remain_minutes);
        ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Premium Account", string, "Close", "");
        return 1;
    }
    else return cmd_benefits(playerid, params);
}
 
CMD:flip(playerid,params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        new Veh, Float:X, Float:Y, Float:Z, Float:A;
        if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid,red,"You need to be inside a vehicle to use this command");
        GetPlayerPos(playerid, X, Y, Z);
        Veh = GetPlayerVehicleID(playerid);
        GetVehicleZAngle(Veh, A);
        SetVehiclePos(Veh, X, Y, Z);
        SetVehicleZAngle(Veh, A);
        return SCM(playerid, red, "You have fliped your vehicle");
    }
    else return cmd_benefits(playerid, params);
}

CMD:attachments(playerid, params[])
{
    if(Info[playerid][Premium] >= 1)
    {
        new string[300], s[40];
        format(string, sizeof(string), "{FFFFFF}Slot 1\t%s\n", oInfo[playerid][0][used1] == true ? ("{FF0000}Used") : ("{00FF00}Empty"));
        for(new i = 1, j = MAX_ATTACHMENTS; i < j; i++) 
        {
            format(s, sizeof(s), "{FFFFFF}Slot %d\t%s\n", i+1, oInfo[playerid][i][used1] == true ? ("{FF0000}Used") : ("{00FF00}Empty"));
            strcat(string, s); 
        }
        ShowPlayerDialog(playerid, DIALOG_ATTACHMENTS, DIALOG_STYLE_TABLIST, "Attachments", string, "Select", "Cancel");
        return 1;
    }
    else return cmd_benefits(playerid, params);
}
CMD:att(playerid, params[]) return cmd_attachments(playerid, params);

CMD:jailed(playerid,params[])
{
    new IsFrozen = 0;
    new string[128], cstring[220];
    foreach(new i : Player)
    {
        if (Info[i][Jailed] == 1)
        {
            format(string, 128, "%s (%d)\n",GetName(i),i);
            strcat(cstring, cstring);
            IsFrozen++;
        }
    }
    if (IsFrozen == 0)
    ShowPlayerDialog(playerid,DIALOGS+47,DIALOG_STYLE_MSGBOX,"{FFFFFF}Note","{FFFFFF}No jailed players found" ,"Close","");
    else ShowPlayerDialog(playerid,DIALOGS+47,DIALOG_STYLE_LIST,"Jailed players",cstring ,"Close","");
    return 1;
}

CMD:muted(playerid, params[])
{
    new IsMuted = 0;
    new string[128], cstring[220];
    foreach(new i : Player)
    {
        if (Info[i][Muted] == 1)
        {
            format(string, 128, "{FFFFFF}%s (%d) {FF0000}%d minutes\n", GetName(i), i, MuteCounter[i] / 60);
            strcat(cstring, string);
            IsMuted++;
        }
    }
    if (IsMuted == 0) ShowPlayerDialog(playerid, DIALOGS+47, DIALOG_STYLE_MSGBOX, "{FFFFFF}Note", "{FFFFFF}No muted players found", "Close","");
    else ShowPlayerDialog(playerid, DIALOGS+47, DIALOG_STYLE_LIST, "Muted players", cstring , "Close", "");
    return 1;
}

CMD:radio(playerid, params[])
{
    ShowPlayerDialog(playerid, DIALOG_RADIOS, DIALOG_STYLE_LIST, "Radio Stations", "- No Radio -\n- Custom Radio -\nPulse 87 NY\nFroZzen Radio Station\nHot 108 Jamz\n106 Jack FM", "Play", "Close");
    return 1;
}

CMD:stopaudio(playerid, params[])
{
    StopAudioStreamForPlayer(playerid);
    return 1;
}

CMD:sendmoney(playerid, params[])
{
    new id, amount;
    if(sscanf(params, "ui", id, amount)) return SCM(playerid, 0xFF0000FF, "Send money to player: /sendmoney <PlayerID> <Amount>");
    if(id == playerid) return SCM(playerid, 0xFF0000FF, "You cannot send money to yourself");
    if(!IsPlayerConnected(id)) return SCM(playerid, 0xFF0000FF, "Invalid player ID");
    if(amount > 10000000 || amount < 1) return SCM(playerid, 0xFF0000FF, "Please enter a valid amount between $1 - $10,000,000");
    if(GetPlayerCash(playerid) < amount) return SCM(playerid, 0xFF0000FF, "You don't have enough money");

    new cmdstring[128],
        currenttime = gettime();

    new cooldown = (Cooldown[playerid][2] + 120) - currenttime;
    format(cmdstring, sizeof(cmdstring),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][2] + 120)) return SCM(playerid,red,cmdstring);
    Cooldown[playerid][2] = gettime();

    format(cmdstring, 128, "You have received $%s from %s", cNumber(amount), GetName(playerid));
    SCM(id, green, cmdstring);

    format(cmdstring, 128, "You have sent $%s to %s", cNumber(amount), GetName(id));
    SCM(playerid, green, cmdstring);

    GivePlayerCash(id, amount), GivePlayerCash(playerid, -amount);

    format(cmdstring, 128, "has sent $%s to %s", cNumber(amount), GetName(id));
    SaveLog(playerid, cmdstring);
    return 1;
}
CMD:cash(playerid, params[]) return cmd_sendmoney(playerid, params);

CMD:report(playerid,params[])
{
    new id,reason[80],string[128];
    if(sscanf(params, "us[80]", id ,reason)) return SCM(playerid,red,"Report player: /report <PlayerID> <Reason>");
    if(strlen(reason) < 2 || strlen(reason) > 80) return SCM(playerid,red,"Please enter a valid reason");
    if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);

    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }

    new currenttime = gettime();

    new cooldown = (Cooldown[playerid][3] + 120) - currenttime;
    format(string, sizeof(string),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][3] + 120)) return SCM(playerid,red,string);
    Cooldown[playerid][3] = gettime();

    format(string, sizeof(string),"You have reported %s (%d): %s",GetName(id),id,reason);
    SCM(playerid, red, string);

    format(string, sizeof(string),"{FF0000}<!> {CC6699}%s (%d) has reported %s (%d): %s",GetName(playerid),playerid,GetName(id),id,reason);
    SendToAdmins(red,string);

    SendToAdmins(red, "Type /accept to accept the report or /reject to reject the report");

    strcpy(ReportText[playerid],string,150);
    CreatedReport[playerid] = 1;

    format(string, sizeof(string), "has reported %s: %s", GetName(id), reason);
    SaveLog(playerid, string);
    return 1;
}

CMD:pm(playerid, params[])
{
    new id, string[128], message[128];
    if(sscanf(params, "us[128]", id, message)) return SCM(playerid, red, "Private Message: /pm <ID> <Message>");
    if(id == playerid) return SCM(playerid, red, "You cannot send a pm to yourself");
    if(PMEnabled[id] == 1 && Info[playerid][Level] < 2) return SCM(playerid, red, "Player has blocked private messages");
    if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }

    if(Info[playerid][Level] < 2)
    {
        if(stringContainsIP(message))
        {
            format(string, sizeof(string), "%s has been kicked for advertising", GetName(playerid));
            SendClientMessageToAll(red, string);
            DelayKick(playerid);
            return 0;
        }
    }

    format(string, sizeof(string), "Message to %s (%d): %s", GetName(id), id, message);
    SCM(playerid, 0xFFD633FF, string);

    format(string, sizeof(string), "Message from %s (%d): %s", GetName(playerid), playerid, message);
    SCM(id, 0xFFD633FF, string);

    LastPm[id] = playerid;
    return 1;
}

CMD:reply(playerid, params[])
{
    new string[128], message[128];
    if(sscanf(params,"s[128]",message)) return SCM(playerid, red, "Reply on message: /re <Message>");
    if(LastPm[playerid] == -1) return SCM(playerid, red, "Last player messaged you has quit the server");
    if(PMEnabled[LastPm[playerid]] == 1 && Info[playerid][Level] < 2) return SCM(playerid, red, "Player has blocked private messages");

    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }

    if(Info[playerid][Level] < 2)
    {
        if(stringContainsIP(message))
        {
            format(string, sizeof(string), "%s has been kicked for advertising", GetName(playerid));
            SendClientMessageToAll(red, string);
            DelayKick(playerid);
            return 0;
        }
    }

    format(string, 128, "Message to %s (%d): %s", GetName(LastPm[playerid]), LastPm[playerid], message);
    SCM(playerid, 0xFFD633FF, string);

    format(string, 128, "Message from %s (%d): %s", GetName(playerid), playerid, message);
    SCM(LastPm[playerid], 0xFFD633FF, string);

    LastPm[LastPm[playerid]] = playerid;
    return 1;
}
CMD:re(playerid, params[]) return cmd_reply(playerid, params);

CMD:togpm(playerid, params[])
{
    if(PMEnabled[playerid] == 0)
    {
        PMEnabled[playerid] = 1;
        SCM(playerid, red, "Block private messages from other players: ON");
    }
    else if(PMEnabled[playerid] == 1)
    {
        PMEnabled[playerid] = 0;
        SCM(playerid, red, "Block private messages from other players: OFF");
    }
    return 1;
}

CMD:local(playerid, params[])
{
    new string[128];
    if(isnull(params)) return SCM(playerid, red, "Local chat: /local <Message>");
    new pColor = GetPlayerColor(playerid);
    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }
    format(string, sizeof(string), "{%06x}%s (%d) [LOCAL]:{FFFFFF} %s", GetPlayerColor(playerid) >>> 8, GetName(playerid), playerid, params);
    ProxDetector(20.0, playerid, string, pColor);
    return 1;
}
CMD:l(playerid, params[]) return cmd_local(playerid, params);

CMD:global(playerid, params[])
{
    new string[128];
    if(isnull(params)) return SCM(playerid, red, "Global Chat: /global <Message>");
    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }
    format(string, sizeof(string), "%s (%d) [GLOBAL]:{FFFFFF} %s", GetName(playerid), playerid, params);
    SendClientMessageToAll(GetPlayerColor(playerid), string);
    return 1;
}
CMD:g(playerid, params[]) return cmd_global(playerid, params);

CMD:givemarijuana(playerid,params[])
{
    new targetid,amount;
    if(sscanf(params, "ud", targetid, amount)) return SCM(playerid, red, "Give Marijuana to player: /givemarijuana <PlayerID> <Amount>");
    if(amount > Info[playerid][Marijuana])return SCM(playerid,red,"You don't have enough Marijuana");
    if(targetid == playerid) return SCM(playerid,red,"You can not send Marijuana to yourself");

    new cmdstring[128],
        currenttime = gettime();

    new cooldown = (Cooldown[playerid][4] + 120) - currenttime;
    format(cmdstring, sizeof(cmdstring),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][4] + 120)) return SCM(playerid,red,cmdstring);
    Cooldown[playerid][4] = gettime();

    format(cmdstring, sizeof(cmdstring), "You have sent %d grams of Marijuana to %s", amount, GetName(targetid));
    SendClientMessage(playerid, green, cmdstring);

    format(cmdstring, sizeof(cmdstring), "%s has sent you %d grams of Marijuana", GetName(playerid), amount);
    SendClientMessage(targetid, green, cmdstring);

    Info[playerid][Marijuana] -= amount;
    Info[targetid][Marijuana] += amount;

    format(cmdstring, sizeof(cmdstring), "has sent %i grams of marijuana to %s", amount, GetName(targetid));
    SaveLog(playerid, cmdstring);
    return 1;
}

CMD:smoke(playerid,params[])
{
    if(Info[playerid][Marijuana] > 5)
    {
        new Float:Health;
        if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");

        SetPlayerSpecialAction(playerid,SPECIAL_ACTION_SMOKE_CIGGY);

        SetPlayerDrunkLevel(playerid, 4000);
        GetPlayerHealth(playerid, Health);
        SetPlayerHealthEx(playerid, Health+20);
        SetPlayerWeather(playerid, -30);
        SetTimerEx("Usedrugs", 5000, false, "d", playerid);
        Info[playerid][Marijuana] -= 5;
        return 1;
    }
    else return SCM(playerid, red, "You don't have enough Marijuana");
}

CMD:givecocaine(playerid,params[])
{
    new targetid,amount;
    if(sscanf(params, "ud", targetid, amount)) return SCM(playerid, red, "Give Cocaine to player: /givecocaine <PlayerID> <Amount>");
    if(amount > Info[playerid][Cocaine]) return SCM(playerid,red,"You don't have enough Cocaine");
    if(targetid == playerid) return SCM(playerid,red,"You can not send Cocaine to yourself");

    new cmdstring[128],
        currenttime = gettime();

    new cooldown = (Cooldown[playerid][5] + 120) - currenttime;
    format(cmdstring, sizeof(cmdstring),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][5] + 120)) return SCM(playerid,red,cmdstring);
    Cooldown[playerid][5] = gettime();

    format(cmdstring, sizeof(cmdstring), "You have sent %d grams of Cocaine to %s", amount, GetName(targetid));
    SendClientMessage(playerid, green, cmdstring);

    format(cmdstring, sizeof(cmdstring), "%s has sent you %d grams of Cocaine", GetName(playerid), amount);
    SendClientMessage(targetid, green, cmdstring);

    Info[playerid][Cocaine] -= amount;
    Info[targetid][Cocaine] += amount;

    format(cmdstring, sizeof(cmdstring), "has sent %i grams of cocaine to %s", amount, GetName(targetid));
    SaveLog(playerid, cmdstring);
    return 1;
}

CMD:crack(playerid,params[])
{
    if(Info[playerid][Cocaine] > 5)
    {
        new Float:Health;
        if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
        if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");

        ApplyAnimation(playerid, "CRACK", "CRCKIDLE2", 4.1, true, false, false, false, 0, false);

        GetPlayerHealth(playerid, Health);
        SetPlayerHealthEx(playerid, Health+40);
        SetPlayerDrunkLevel(playerid, 8000);
        SetPlayerWeather(playerid, -60);
        SetTimerEx("Usedrugs", 15000, false, "d", playerid);
        Info[playerid][Cocaine] -= 5;
        return 1;
    }
    else return SCM(playerid, red, "You don't have enough Cocaine");
}

CMD:admins(playerid,params[])
{
   new IsOnline = 0;
   new string[300], Jstring[128];
   foreach(new i : Player)
   {
        if(Info[i][Level] >= 2 && Info[i][Duty] == 0)
        {
            format(Jstring, 128, "{FFFFFF}%s (%d) {FF0000}%s %s\n", GetName(i), i, GetLevel(i), IsPlayerAFK(i) == 1 ? ("{FF0000}AFK"):(""));
            strcat(string, Jstring, sizeof(string));
            IsOnline++;
        }
   }
   if (IsOnline == 0)
   ShowPlayerDialog(playerid,DIALOGS+165,DIALOG_STYLE_MSGBOX,"Note","{FF0000}No administrators found" ,"Close","");
   else ShowPlayerDialog(playerid,DIALOGS+165,DIALOG_STYLE_LIST,"Administrators", string ,"Close","");
   return 1;
}

CMD:helpers(playerid,params[])
{
   new IsOnline = 0;
   new string[300], Jstring[128];
   foreach(new i : Player)
   {
        if(Info[i][Level] == 1)
        {
            format(Jstring, 128, "{FFFFFF}%s (%d) {FF0000}Helper %s\n", GetName(i), i, IsPlayerAFK(i) == 1 ? ("{FF0000}AFK"):(""));
            strcat(string, Jstring, sizeof(string));
            IsOnline++;
        }
   }
   if (IsOnline == 0)
   ShowPlayerDialog(playerid,DIALOGS+165,DIALOG_STYLE_MSGBOX,"Note","{FF0000}No helpers found" ,"Close","");
   else ShowPlayerDialog(playerid,DIALOGS+165,DIALOG_STYLE_LIST,"Helpers",string ,"Close","");
   return 1;
}

CMD:poke(playerid,params[])
{
    new id;
    if(sscanf(params, "u",id)) return SCM(playerid, red, "Poke player: /Poke <PlayerID>");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    if(playerid == id) return SCM(playerid, red, "You can not poke yourself");

    new cmdstring[128],
        currenttime = gettime();

    new cooldown = (Cooldown[playerid][6] + 120) - currenttime;
    format(cmdstring, sizeof(cmdstring),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][6] + 120)) return SCM(playerid,red,cmdstring);
    Cooldown[playerid][6] = gettime();

    format(cmdstring,sizeof(cmdstring),"%s (%d) has poked you",GetName(playerid),playerid);
    SCM(id,NOTIF,cmdstring);

    PlayerPlaySound(id,1057,0.0,0.0,0.0);

    format(cmdstring,sizeof(cmdstring),"You have poked %s (%d)", GetName(id), playerid);
    SCM(playerid,red,cmdstring);
    return 1;
}

CMD:getid(playerid,params[])
{
    new Nick[24],str[80], string[128], count=0, Mainstring[300];

    if(sscanf(params, "s[24]",Nick)) return SCM(playerid, red, "Player's ID: /id <Part of name>");
    format(str, sizeof(str),"ID of %s",Nick);
    foreach(new i : Player)
    {
        if(strfind(GetName(i), Nick, true) != -1 )
        {
            count++;
            format(string, sizeof(string),"%d - %s (%d)",count,GetName(i),i);
            strcat(Mainstring, string);
        }
    }
    if(count==0) SCM(playerid,red,"No resuilt found");
    else ShowPlayerDialog(playerid, DIALOGS+126, DIALOG_STYLE_LIST, str, Mainstring, "Close", "");
    return 1;
}

CMD:event(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the event while you are in a gang zone");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You are already in the event");
    if(eInfo[Type] == EVENT_NONE) return SCM(playerid, red, "There is no event in progress");
    if(eInfo[EventStarted] == true) return SCM(playerid, red, "Event has already started");
    if(GetPlayerCash(playerid) < eInfo[Price]) return SCM(playerid, red, "You don't have enough money");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the event");

    InEvent[playerid] = 1;
    InAmmu[playerid] = 0;
    pProtectTick[playerid] = 0;
    GivePlayerCash(playerid, -eInfo[Price]);
    GetPlayerSpawnEx(playerid);
    SetPlayerHealthEx(playerid, 100.0);
    SetPlayerArmourEx(playerid, 100.0);

    switch(eInfo[Type])
    {
        case EVENT_TDM:
        {
            switch(EventBalance)
            {
                case 0:
                {
                    ePlayerTeamOne++;
                    EventBalance = 1;
                    SetPlayerInterior(playerid, eInfo[eInterior]);
                    SetPlayerPosition(playerid, eInfo[eSpawnX], eInfo[eSpawnY], eInfo[eSpawnZ], 0);
                    SetPlayerTeam(playerid, TEAM_ONE);
                }
                case 1:
                {
                    ePlayerTeamTwo++;
                    EventBalance = 0;
                    SetPlayerInterior(playerid, eInfo[eInterior]);
                    SetPlayerPosition(playerid, eInfo[eSX], eInfo[eSY], eInfo[eSZ], 0);
                    SetPlayerTeam(playerid, TEAM_TWO);
                }
            }
        }
        case EVENT_DM:
        {
            ePlayers++;
            SetPlayerInterior(playerid, eInfo[eInterior]);
            SetPlayerPosition(playerid, eInfo[eSpawnX], eInfo[eSpawnY], eInfo[eSpawnZ], 0);
        }
    }
    return 1;
}

CMD:eventlist(playerid, params[])
{
    if(eInfo[Type] == EVENT_NONE) return SCM(playerid, red, "There is no event in progress");

    new IsInEvent = 0;
    new string[128], cstring[220];
    foreach(new i : Player)
    {
        if(InEvent[i] == 1)
        {
            switch(eInfo[Type])
            {
                case EVENT_TDM:
                {
                    format(string, sizeof(string), "{FFFFFF}%s (%d) %s\n", GetName(i), i, GetPlayerTeam(i) == TEAM_ONE ? ("{FF0000}Team 1"):("{0099FF}Team 2"));
                    IsInEvent++;
                }
                case EVENT_DM:
                {
                    format(string, sizeof(string), "{FFFFFF}%s (%d)\n", GetName(i), i);
                    IsInEvent++;
                }
            }
            strcat(cstring, string);
        }
    }
    if (IsInEvent == 0) ShowPlayerDialog(playerid, DIALOGS+47, DIALOG_STYLE_MSGBOX, "{FFFFFF}Note", "{FFFFFF}No players found", "Close","");
    else ShowPlayerDialog(playerid, DIALOGS+47, DIALOG_STYLE_LIST, "Event list", cstring , "Close", "");
    return 1;
}

CMD:leaveevent(playerid, params[])
{
    if(InEvent[playerid] == 0) return SCM(playerid, red, "You are not in the event");

    InEvent[playerid] = 0;
    SpawnPlayerEx(playerid);
    new string[128];

    if(eInfo[EventStarted] == true)
    {
        switch(eInfo[Type])
        {
            case EVENT_TDM:
            {
                if(GetPlayerTeam(playerid) == TEAM_ONE)
                {
                    ePlayerTeamOne--;
                    if(ePlayerTeamOne == 0)
                    {
                        foreach(new i : Player)
                        {
                            if(InEvent[i] == 1 && GetPlayerTeam(i) == TEAM_TWO && GetPlayerState(i) != PLAYER_STATE_WASTED)
                            {
                                format(string, sizeof(string), "%s has won the event", GetName(i));
                                SendClientMessageToAll(0x00FFFFFF, string);

                                Info[i][XP] += 100;
                                GivePlayerCash(i, eInfo[Prize]);

                                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                                WinnerText(i, string);

                                InEvent[i] = 0;

                                ResetPlayerWeaponsEx(i);
                                SpawnPlayerEx(i);
                                SetPlayerHealthEx(i, 100);
                                SetPlayerArmourEx(i, 100);
                            }
                        }

                        ePlayers = 0;
                        ePlayerTeamTwo = 0;
                        ePlayerTeamOne = 0;
                        eInfo[Type] = EVENT_NONE;
                        eInfo[EventStarted] = false;
                    }
                }
                if(GetPlayerTeam(playerid) == TEAM_TWO)
                {
                    ePlayerTeamTwo--;
                    if(ePlayerTeamTwo == 0)
                    {
                        foreach(new i : Player)
                        {
                            if(InEvent[i] == 1 && GetPlayerTeam(i) == TEAM_ONE && GetPlayerState(i) != PLAYER_STATE_WASTED)
                            {
                                format(string, sizeof(string), "%s has won the event", GetName(i));
                                SendClientMessageToAll(0x00FFFFFF, string);

                                Info[i][XP] += 100;
                                GivePlayerCash(i, eInfo[Prize]);

                                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                                WinnerText(i, string);

                                InEvent[i] = 0;

                                ResetPlayerWeaponsEx(i);
                                SpawnPlayerEx(i);
                                SetPlayerHealthEx(i, 100);
                                SetPlayerArmourEx(i, 100);
                            }
                        }

                        ePlayers = 0;
                        ePlayerTeamTwo = 0;
                        ePlayerTeamOne = 0;
                        eInfo[Type] = EVENT_NONE;
                        eInfo[EventStarted] = false;
                    }
                }
            }
            case EVENT_DM:
            {
                ePlayers--;
                if(ePlayers == 1)
                {
                    foreach(new i : Player)
                    {
                        if(InEvent[i] == 1 && GetPlayerState(i) != PLAYER_STATE_WASTED)
                        {
                            format(string, sizeof(string), "%s has won the event", GetName(i));
                            SendClientMessageToAll(0x00FFFFFF, string);

                            Info[i][XP] += 100;
                            GivePlayerCash(i, eInfo[Prize]);

                            format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(eInfo[Prize]));
                            WinnerText(i, string);

                            InEvent[i] = 0;
                        
                            ResetPlayerWeaponsEx(i);
                            SpawnPlayerEx(i);
                            SetPlayerHealthEx(i, 100);
                            SetPlayerArmourEx(i, 100);
                        }
                    }

                    ePlayers = 0;
                    ePlayerTeamTwo = 0;
                    ePlayerTeamOne = 0;
                    eInfo[Type] = EVENT_NONE;
                    eInfo[EventStarted] = false;
                }
            }
        }
    }
    return 1;
}

CMD:deagledm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsDE));
    CreateDM(playerid,RandomSpawnsDE[Random][0], RandomSpawnsDE[Random][1], RandomSpawnsDE[Random][2], RandomSpawnsDE[Random][3],3,1,1,24,24,100,"~r~Desert Eagle DM");

    UpdateTeleportInfo(playerid, "has joined Deagle DM");

    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:microdm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsMicro));
    CreateDM(playerid,RandomSpawnsMicro[Random][0], RandomSpawnsMicro[Random][1], RandomSpawnsMicro[Random][2], RandomSpawnsMicro[Random][3],1,2,2,28,28,100,"~r~Micro SMG DM");

    UpdateTeleportInfo(playerid, "has joined Micro DM");

    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:minigundm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsMinigun));
    CreateDM(playerid,RandomSpawnsMinigun[Random][0], RandomSpawnsMinigun[Random][1], RandomSpawnsMinigun[Random][2], RandomSpawnsMinigun[Random][3],10,3,3,38,38,100,"~r~Minigun DM");

    UpdateTeleportInfo(playerid, "has joined Minigun DM");

    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:m4dm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsM4));
    CreateDM(playerid,RandomSpawnsM4[Random][0], RandomSpawnsM4[Random][1], RandomSpawnsM4[Random][2], RandomSpawnsM4[Random][3],3,4,4,31,31,100,"~r~M4 DM");

    UpdateTeleportInfo(playerid, "has joined M4 DM");

    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:sawndm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsSawns));
    CreateDM(playerid,RandomSpawnsSawns[Random][0], RandomSpawnsSawns[Random][1], RandomSpawnsSawns[Random][2], RandomSpawnsSawns[Random][3],0,5,5,26,26,100, "~r~Sawn Off DM");

    UpdateTeleportInfo(playerid, "has joined Sawn-Off DM");
    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:combatdm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsCombat));
    CreateDM(playerid,RandomSpawnsCombat[Random][0], RandomSpawnsCombat[Random][1], RandomSpawnsCombat[Random][2], RandomSpawnsCombat[Random][3],1,6,6,27,27,100, "~r~Combat Shotgun DM");

    UpdateTeleportInfo(playerid, "has joined Combat DM");
    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:sniperdm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsSniper));
    CreateDM(playerid,RandomSpawnsSniper[Random][0], RandomSpawnsSniper[Random][1], RandomSpawnsSniper[Random][2], RandomSpawnsSniper[Random][3],0,7,7,34,34,100,"~r~Sniper DM");

    UpdateTeleportInfo(playerid, "has joined Sniper DM");
    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:jetpackdm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    pProtectTick[playerid] = 0;
    GetPlayerSpawnEx(playerid);

    Listen(playerid, "http://k003.kiwi6.com/hotlink/dps7fbcqai/Deathmatch.mp3");
    new Random = random(sizeof(RandomSpawnsJetpack));
    CreateDM(playerid,RandomSpawnsJetpack[Random][0], RandomSpawnsJetpack[Random][1], RandomSpawnsJetpack[Random][2], RandomSpawnsJetpack[Random][3],0,8,8,28,28,100, "~r~Jetpack DM");
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
    GotJetpack[playerid] = 1;

    UpdateTeleportInfo(playerid, "has joined Jetpack DM");
    SCM(playerid, red, "Type /leavedm to leave the DM");
    return 1;
}

CMD:leavedm(playerid)
{
    if(Info[playerid][InDM] == 0) return SCM(playerid, red, "You are not in a deathmatch arena");
    
    Info[playerid][InDM] = 0;
    Info[playerid][DMZone] = 0;
    ResetPlayerWeaponsEx(playerid);
    SpawnPlayerEx(playerid);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
    StopAudioStreamForPlayer(playerid);
    SetCameraBehindPlayer(playerid);
    return 1;
}

CMD:dm(playerid)
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't use the command while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You are already in the DM");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the DM");

    new string[280],de,mic,mini,m4,sawns,sniper,combat,jetpack;
    foreach(new i : Player)
    {
        switch(Info[i][DMZone])
        {
            case 1: de++;
            case 2: mic++;
            case 3: mini++;
            case 4: m4++;
            case 5: sawns++;
            case 6: combat++;
            case 7: sniper++;
            case 8: jetpack++;
        }
    }
    format(string, sizeof(string),
    "Name\tPlayers\nDesert Eagle \t%d\nMicro SMG \t%d\nMinigun \t%d\nM4 \t%d\nSawn-Off Shotgun \t%d\nSniper Rifle \t%d\nCombat Shotgun \t%d\nJetpack \t%d\n",de,mic,mini,m4,sawns,sniper,combat,jetpack);
    ShowPlayerDialog(playerid, DIALOG_DM, DIALOG_STYLE_TABLIST_HEADERS, "Deathmatch List",string, "Select","Cancel");
    return 1;
}

CMD:me(playerid, params[])
{
    new string[128];
    if(isnull(params)) return SCM(playerid, red, "Empty message: /me <Message>");
    if(Info[playerid][Muted] == 1)
    {
        format(string, sizeof(string), "You are muted (%d Minutes)", MuteCounter[playerid] / 60);
        SCM(playerid, red, string);
        return 0;
    }
    format(string, sizeof(string), "%s {FFFFFF}%s", GetName(playerid), params);
    SendClientMessageToAll(GetPlayerColor(playerid), string);
    return 1;
}

CMD:moneybag(playerid)
{
    new string[240];
    if(!MoneyBagFound) 
    {
        format(string, sizeof(string), 
        "{FFFFFF}There is a money bag that appears from time to time in the server\n\
        {FFFFFF}First player find it will earn money between $20000 - $100000\n\n{FFFFFF}Money bag location: {00FF00}%s", MoneyBagLocation);
    }
    else if(MoneyBagFound) 
    {
        format(string, sizeof(string), 
        "{FFFFFF}There is a money bag that appears from time to time in the server\n\
        {FFFFFF}First player find it will earn money between $20000 - $100000\n\n{FFFFFF}Money bag location: {00FF00}There is no money bag at the moment", MoneyBagLocation);
    }
    ShowPlayerDialog(playerid, DIALOGS+574, DIALOG_STYLE_MSGBOX, "Money Bag", string, "Close", "");
    return 1;
}

CMD:hit(playerid, params[])
{
    new id, amount;
    if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Bounty on player: /hit <PlayerID> <Amount>");
    if(GetPlayerCash(playerid) < amount) return SCM(playerid, red, "You don't have enough money");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    if(amount <= 0) return SCM(playerid, red, "Invalid amount");

    Info[id][Hitman] = Info[id][Hitman] + amount;

    GivePlayerCash(playerid, -amount);
	new string[128];
    format(string, sizeof(string), "%s has set bounty on %s: $%s", GetName(playerid), GetName(id), cNumber(Info[id][Hitman]));
    TextDrawSetString(BText, string);
    TextDrawShowForAll(BText);
    TextDrawShowForAll(BBox);
    TextDrawShowForAll(BBounty);
	SetTimer("HideText", 5000, 0);
    return 1;
}

CMD:bounty(playerid, params[])
{
    new tmpbounty = 0, tmpbountystr[128], Mainstring[320];
    foreach(new i : Player)
    {
        if(Info[i][Hitman] > 0)
        {
            tmpbounty++;
            format(tmpbountystr, sizeof(tmpbountystr),"{FFFFFF}%s (%d): {FF5050}$%s\n", GetName(i), i, cNumber(Info[i][Hitman]));
            strcat(Mainstring, tmpbountystr);
        }
    }
    if(tmpbounty == 0) ShowPlayerDialog(playerid, DIALOGS+7741, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No bounties found", "Close", "");
    else ShowPlayerDialog(playerid, DIALOGS+7741, DIALOG_STYLE_LIST, "Bounties", Mainstring, "Close", "");
    return 1;
}

CMD:position(playerid, params[])
{
    new cmdstring[128];
    if(Info[playerid][Level] != 5)
    {
        new currenttime = gettime();

        new cooldown = (Cooldown[playerid][7] + 120) - currenttime;
        format(cmdstring, sizeof(cmdstring),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
        if(currenttime < (Cooldown[playerid][7] + 120)) return SCM(playerid,red,cmdstring);
        Cooldown[playerid][7] = gettime();
    }

    new zone[MAX_ZONE_NAME];
    GetPlayer2DZone(playerid, zone, MAX_ZONE_NAME);
    format(cmdstring, sizeof(cmdstring), "%s {FFFFFF}is located at {00FF00}%s", GetName(playerid), zone);
    SendClientMessageToAll(GetPlayerColor(playerid), cmdstring);
    return 1;
}

CMD:eject(playerid, params[])
{   
    new id, string[128];
    if(isnull(params))
    {
        foreach(new i : Player)
        {
            if(i != playerid)
            {
                if(IsPlayerInVehicle(i, GetPlayerVehicleID(playerid)))
                {
                    RemovePlayerFromVehicle(i);
                }
                else return SCM(playerid, red, "You are not in a vehicle");
            }
        }
        SCM(playerid, red, "You have ejected all the players from your vehicle");
    }
    
    if(sscanf(params, "u", id)) return SCM(playerid, red, "Eject player: /eject <PlayerID>");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    if(id == playerid) return SCM(playerid, red, "You can't eject yourself");

    if(IsPlayerInVehicle(id, GetPlayerVehicleID(playerid)))
    {
        RemovePlayerFromVehicle(id);
        format(string, sizeof(string), "You have ejected %s from your vehicle", GetName(id));
        SCM(playerid, red, string);
    }
    return 1;
}

CMD:hood(playerid) 
{
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, red, "You must be in vehicle to use this command");

    GetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
    if(g_Bonnet == 1) 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, 0, g_Boot, g_Objective);
        g_Bonnet = 0;
    }
    else 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, 1, g_Boot, g_Objective);
        g_Bonnet = 1;
    }
    return 1;
}

CMD:trunk(playerid) 
{
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, red, "You must be in vehicle to use this command");

    GetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
    if(g_Boot == 1) 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, g_Bonnet, 0, g_Objective);
        g_Boot = 0;
    }
    else 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, g_Bonnet, 1, g_Objective);
        g_Boot = 1;
    }
    return 1;
}

CMD:engine(playerid) 
{
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, red, "You must be in vehicle to use this command");

    GetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
    if(g_Engine == 0) 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), 1, g_Lights, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
        SendClientMessage(playerid, 0xFFC34DFF, "Vehicle Engine: ON");
        g_Engine = 1;
    }
    else 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), 0, g_Lights, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
        SendClientMessage(playerid, 0xFFC34DFF, "Vehicle Engine: OFF");
        g_Engine = 0;
    }
    return 1;
}

CMD:lights(playerid) 
{
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, red, "You must be in vehicle to use this command");

    GetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, g_Lights, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
    if(g_Lights == 1) 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, 0, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
        g_Lights = 0;
    }
    else 
    {
        SetVehicleParamsEx(GetPlayerVehicleID(playerid), g_Engine, 1, g_Alarm, g_Doors, g_Bonnet, g_Boot, g_Objective);
        g_Lights = 1;
    }
    return 1;
}

CMD:afk(playerid, params[])
{
	new string[128], cnt = 0;
	foreach(new i : Player)
	{
		if(IsPlayerAFK(i) == 1)
		{
			format(string, sizeof(string), "{FFFFFF}%s (%d) {FF0000}AFK\n", GetName(i), i);
			cnt++;
		}
	}
	if(cnt == 0) return ShowPlayerDialog(playerid, 18115, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No AFK players found", "Close", "");
	else ShowPlayerDialog(playerid, 18115, DIALOG_STYLE_LIST, "AFK Players", string, "Close", "");
	return 1;
}

CMD:name(playerid, params[])
{
	if(Info[playerid][NameChange] == 1)
	{
		new query[128], newname[MAX_PLAYER_NAME];
        if(sscanf(params, "s[24]", newname)) return SCM(playerid, red, "Change name: /changename <NewName>");
        if(!(24 > strlen(newname) > 3)) return SCM(playerid,red,"Name length must be between 3 - 24 characters");
        if(AccountExists(newname)) return SCM(playerid,red, "The name is already exists");

        mysql_format(mysql, query, sizeof(query),"UPDATE `Vehicles` SET `vehOwner` = '%e' WHERE `vehOwner` = '%e'", newname, GetName(playerid));
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query), "UPDATE `HouseKeys` SET `Player` = '%e' WHERE `Player` = '%e'", newname, GetName(playerid));
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query),"UPDATE `playersdata` SET `PlayerName` = '%e' WHERE `ID` = '%d'", newname, Info[playerid][ID]);
        mysql_tquery(mysql, query);

        format(query, sizeof(query), "%s has changed his name to %s", GetName(playerid), newname);
        SendClientMessageToAll(red, query);

        format(query, sizeof(query), "has changed his name to %s", newname);
        SaveLog(playerid, query);

        SetPlayerName(playerid, newname);
        return 1;
	}
	else return SCM(playerid, red, "You have to buy the name change access from /shop");
}

CMD:shop(playerid, params[])
{
	if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");

	new str[128], string[720];
	strcat(string, "Premium account\nGame money\nName change\nFight style\nHealth & Armour\nMarijuana\nCocaine\nWeapons\n\
    Skins\nJetpack\nProperty renew\nHouse renew\nWheels\nSpoilers\nNitro\nHydraulics\nDouble Jump");
	format(str, sizeof(str), "{FFFFFF}Shop {FF0066}Money: %0.2f UGC", Currency(playerid));
	ShowPlayerDialog(playerid, DIALOG_SHOP, DIALOG_STYLE_LIST, str, string, "Select", "Close");
	return 1;
}

CMD:benefits(playerid, params[])
{
	new string[1200];
	strcat(string, "{FFFFFF}You can buy premium from the game shop with command /shop and get a lot\n");
	strcat(string, "{FFFFFF}of benefits.\n\n");
	strcat(string, "{00CC00}Benefits for premium account:\n");
	strcat(string, "{FFFFFF}- Hide on map (command /hide)\n");
	strcat(string, "{FFFFFF}- Ability to set tag (command /tag)\n");
	strcat(string, "{FFFFFF}- Ability to change name and text color (command /color)\n");
	strcat(string, "{FFFFFF}- Premium chat (command /p or /premiumchat)\n");
	strcat(string, "{FFFFFF}- Ability to start vote (command /vote)\n");
	strcat(string, "{FFFFFF}- Ability to use timer (command /timer)\n");
	strcat(string, "{FFFFFF}- Ability to flip vehicle (command /flip)\n");
	strcat(string, "{FFFFFF}- Ability to attach objects on your skin (command /att or /attachments)\n");
	ShowPlayerDialog(playerid, N, DIALOG_STYLE_MSGBOX, "Premium Account", string, "Close", "");
	return 1;
}

CMD:ganghelp(playerid, params[])
{
    new string[900];
    strcat(string, "{FFFFFF}You can join 8 gangs on this server. As a gang member, You can take over hoods of\n");
    strcat(string, "{FFFFFF}enemy gang when you type /attack. Attacking gang hoods will increase your skills\n");
    strcat(string, "{FFFFFF}and money. Player with 5000 skills in the gang will become gang boss and will earn\n");
    strcat(string, "{FFFFFF}25% higher payout. You can view list of gang bosses with /boss. Type /gang to display\n");
    strcat(string, "{FFFFFF}list of gang members in your gang.\n\n");
    strcat(string, "{FFFFFF}Grove Street:{00FF00} Ganton\n");
    strcat(string, "{FFFFFF}Ballas:{00FF00} Idlewood\n");
    strcat(string, "{FFFFFF}Los Santos Vagos:{00FF00} East Los Santos\n");
    strcat(string, "{FFFFFF}Varrio Los Aztecas:{00FF00} El Corona\n");
    strcat(string, "{FFFFFF}Bikers:{00FF00} Conference Center\n");
    strcat(string, "{FFFFFF}Triad:{00FF00} Vinewood\n");
    strcat(string, "{FFFFFF}Mafia:{00FF00} Verdant Bluffs\n");
    strcat(string, "{FFFFFF}Da Nang Boys:{00FF00} Santa Maria Beach\n");
    ShowPlayerDialog(playerid, 18114, DIALOG_STYLE_MSGBOX, "Help", string, "Close", "");
    return 1;
}

CMD:gang(playerid, params[])
{
    new string[520];
    if(pTeam[playerid] == NO_TEAM) return SendClientMessage(playerid, red, "You are not in any gang");
    foreach(new i : Player)
    {
        if(pTeam[i] == pTeam[playerid] && pTeam[i] != NO_TEAM) 
        {
            switch(pTeam[playerid])
            {
                case GROVE: format(string, sizeof(string), "%s%s (%d) {00CC00}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][GROVE]);
                case BALLAS: format(string, sizeof(string), "%s%s (%d) {CC33FF}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][BALLAS]);
                case VAGOS: format(string, sizeof(string), "%s%s (%d) {FFCC00}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][VAGOS]);
                case AZTECAS: format(string, sizeof(string), "%s%s (%d) {00FFFF}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][AZTECAS]);
                case BIKERS: format(string, sizeof(string), "%s%s (%d) {595959}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][BIKERS]);
                case TRIADS: format(string, sizeof(string), "%s%s (%d) {6600FF}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][TRIADS]);
                case MAFIA: format(string, sizeof(string), "%s%s (%d) {E69500}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][MAFIA]);
                case NANG: format(string, sizeof(string), "%s%s (%d) {996633}%s (%d skills) \n", string, GetName(i), i, GetRank(i), Info[i][Skills][NANG]);
            }
        }
    }
    return ShowPlayerDialog(playerid, DIALOG_GANGLIST, DIALOG_STYLE_LIST, "Gang Members", string, "Close", "");
}

CMD:gangs(playerid, params[])
{
	new string[380];
	format(string, sizeof(string), 
        "Grove Street {00CC00}(%d Members)\n\
		Ballas {CC33FF}(%d Members)\n\
		Los Santos Vagos {FFCC00}(%d Members)\n\
		Varrios Los Aztecas {00FFFF}(%d Members)\n\
		Bikers {595959}(%d Members)\n\
		Triads {6600FF}(%d Members)\n\
		Mafia {E69500}(%d Members)\n\
		Da Nang Boys {996633}(%d Members)", gTeamCount[GROVE], gTeamCount[BALLAS], gTeamCount[VAGOS], gTeamCount[AZTECAS], \
											gTeamCount[BIKERS], gTeamCount[TRIADS], gTeamCount[MAFIA], gTeamCount[NANG]);
    return ShowPlayerDialog(playerid, DIALOG_GANGSLIST, DIALOG_STYLE_LIST, "Gangs", string, "Close", "");
}

CMD:boss(playerid, params[])
{
    new string[128];
    foreach(new i : Player)
    {
        if(pTeam[i] != NO_TEAM && Info[i][Skills][pTeam[i]] > 5000)
        {
            format(string, sizeof(string), "{FFFFFF}%s (%d) {%06x)(%d skills)", GetName(i), i, GetPlayerColor(i) >>> 8, Info[i][Skills][pTeam[i]]);
        }
        else return ShowPlayerDialog(playerid, DIALOGS+116, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No gangs boss found", "Close", "");
    }
    return ShowPlayerDialog(playerid, DIALOGS+116, DIALOG_STYLE_MSGBOX, "Gang Boss", string, "Close", "");
}

CMD:gangkick(playerid, params[])
{
    new id, txt[84], string[128];
    if(sscanf(params, "us[84]", id, txt)) return SendClientMessage(playerid, red, "Kick player from gang: /gangkick <ID> <Reason>");
    if(Info[playerid][Skills][pTeam[playerid]] < 5000) return SendClientMessage(playerid, red, "You need Gang Boss rank to use this command");
    if(Info[id][Skills][pTeam[playerid]] > 5000) return SCM(playerid, red, "You can't kick the gang boss");
    if(pTeam[playerid] != pTeam[id]) return SendClientMessage(playerid, red, "Player is not in your gang");
    if(id == playerid) return SendClientMessage(playerid, red, "You can't kick yourself");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, red, "Player is not connected");
    if(pTeam[id] == NO_TEAM) return SendClientMessage(playerid, red, "Player is not in gang");

    new currenttime = gettime();

    new cooldown = (Cooldown[playerid][8] + 240) - currenttime;
    format(string, sizeof(string),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][8] + 240)) return SCM(playerid,red,string);
    Cooldown[playerid][8] = gettime();

    pTeam[id] = NO_TEAM;
    SetPlayerColor(id, COLOR_NULL);

    format(Info[playerid][playerColor], 16, "0xFFFFFFFF");
    format(Info[playerid][textColor], 16, "FFFFFF");

    for(new i, j = sizeof(g_Turf); i < j; i++) 
    {
        GangZoneHideForPlayer(playerid, g_Turf[i][turfId]);
    }

	if(!isnull(txt)) format(string, sizeof(string), "%s has kicked %s from the gang: %s", GetName(playerid), GetName(id), txt);
	else format(string, sizeof(string), "%s has kicked %s from the gang", GetName(playerid), GetName(id));
    SendMessageToTeam(pTeam[playerid], GetPlayerColor(playerid), string);
    return 1;
}

CMD:gangbackup(playerid, params[])
{
    if(pTeam[playerid] == NO_TEAM) return SendClientMessage(playerid, red, "You are not in gang");
    if(Info[playerid][Skills][pTeam[playerid]] < 1000) return SendClientMessage(playerid, red, "You need Gang Commander rank to use this command");

    new string[128], currenttime = gettime();

    new cooldown = (Cooldown[playerid][9] + 120) - currenttime;
    format(string, sizeof(string),"You have to wait %d:%02d minutes", cooldown / 60, cooldown % 60);  
    if(currenttime < (Cooldown[playerid][9] + 120)) return SCM(playerid,red,string);
    Cooldown[playerid][9] = gettime();

    new zone[MAX_ZONE_NAME];
    GetPlayer2DZone(playerid, zone, MAX_ZONE_NAME);
    format(string, sizeof(string), "%s has called for a backup at %s", GetName(playerid), zone);
    SendMessageToTeam(pTeam[playerid], GetPlayerColor(playerid), string);
    return 1;
}

CMD:attack(playerid, params[]) 
{
    if(pTeam[playerid] == NO_TEAM) return SCM(playerid, red, "You are not in gang");
    if(!IsPlayerInAnyGangZone(playerid)) return SCM(playerid, red, "You are not in gang zone");

    if(GetPlayerState(playerid) != PLAYER_STATE_WASTED && GetPlayerInterior(playerid) == 0 && GetPlayerVirtualWorld(playerid) == 0) {

        for(new i, j = sizeof(g_Turf); i < j; i++) {

            if(IsPlayerInGangZone(playerid, i)) {

                if(pTeam[playerid] == g_Turf[i][turfOwner]) return SCM(playerid, red, "You cannot attack your gang hood");
                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED) return SCM(playerid, red, "There is already gang war in this hood");
            }

            foreach(new x : Player) {

                if(IsPlayerInGangZone(x, i)) {

                    if(pTeam[x] == pTeam[playerid]) {

                        if (g_MembersInTurf[i][pTeam[x]] >= TURF_REQUIRED_PLAYERS) {

                            g_Turf[i][turfState] = TURF_STATE_ATTACKED;
                            g_Turf[i][turfAttacker] = pTeam[playerid];
                            g_Turf[i][turfTimer] = SetTimerEx("OnTurfwarEnd", TURF_REQUIRED_CAPTURETIME, false, "i", i);

                            g_Turf[i][turfCountDown] = 180;
                            g_Turf[i][turfAttackTimer] = SetTimerEx("CountDownTimer", 999, 1, "i", i);

                            foreach(new p : Player) if(pTeam[p] != NO_TEAM) GangZoneFlashForPlayer(p, g_Turf[i][turfId], 0xFF0000AA);
                        }
                    }
                }
            }
        }
    }
    return 1;
}

CMD:leavegang(playerid, params[])
{
    if(pTeam[playerid] == NO_TEAM) return SendClientMessage(playerid, red, "You are not in gang");
    if(IsPlayerInAnyGangZone(playerid)) return SCM(playerid, red, "You have to leave the gang zone to leave the gang");

    if(pTeam[playerid])
    {
        gTeamCount[pTeam[playerid]] --;
        UpdateTeamLabel(pTeam[playerid]);
    }

    pTeam[playerid] = NO_TEAM;
    SetPlayerColor(playerid, COLOR_NULL);

    format(Info[playerid][textColor], 16, "FFFFFF");
    format(Info[playerid][playerColor], 16, "0xFFFFFFFF");

    for(new i, j = sizeof(g_Turf); i < j; i++) 
    {
        GangZoneHideForPlayer(playerid, g_Turf[i][turfId]);
    }

    PlayerTextDrawHide(playerid, CountDownAttack[playerid]);
    
    SendClientMessage(playerid, red, "You have left the gang");
    return 1;
}

CMD:derby(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't start the derby while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(DerbyStarted == true) return SCM(playerid, red, "There is already derby in progress");
    if(DerbyGame != NON_DERBY) return SCM(playerid, red, "There is already derby in progress");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You are already in derby");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    ShowPlayerDialog(playerid, DIALOG_DERBY, DIALOG_STYLE_LIST, "Derby Minigames", "Ranchers Derby\nBullets Derby\nHotrings Derby\nInfernus Derby", "Start", "Cancel");
    return 1;
}

CMD:joinderby(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the derby while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You are already in derby");
    if(DerbyStarted == true) return SCM(playerid, red, "Derby has already started");
    if(PlayersInDerby >= MAX_DERBY_PLAYERS) return SCM(playerid, red, "Derby is full");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the derby");

    pProtectTick[playerid] = 0;
    InAmmu[playerid] = 0;
    GetPlayerSpawnEx(playerid);
    if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

    new string[128];
    switch(DerbyGame)
    {
        case RANCHERS_DERBY:
        {
            ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
            InDerby[playerid] = 1;
            PlayersInDerby += 1;
            SpawnPlayerInDerby(playerid, 489, RanchersDerby, 6);
            PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
            SetVehicleHealth(DerbyVehicles[playerid],20000);
            TogglePlayerControllable(playerid, false);

            format(string, sizeof(string), "~r~Derby Map: ~g~Ranchers Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
            TextDrawSetString(DerbyInfo, string);
            TextDrawShowForPlayer(playerid, DerbyInfo);
        }
        case BULLETS_DERBY:
        {
            ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
            InDerby[playerid] = 1;
            PlayersInDerby += 1;
            SpawnPlayerInDerby(playerid, 541, BulletsDerby, 12);
            PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
            SetVehicleHealth(DerbyVehicles[playerid],20000);
            TogglePlayerControllable(playerid, false);

            format(string, sizeof(string), "~r~Derby Map: ~g~Bullets Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
            TextDrawSetString(DerbyInfo, string);
            TextDrawShowForPlayer(playerid, DerbyInfo);
        }
        case HOTRINGS_DERBY:
        {
            ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
            InDerby[playerid] = 1;
            PlayersInDerby += 1;
            SpawnPlayerInDerby(playerid, 503, HotringsDerby, 9);
            PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
            SetVehicleHealth(DerbyVehicles[playerid],20000);
            TogglePlayerControllable(playerid, false);

            format(string, sizeof(string), "~r~Derby Map: ~g~Hotrings Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
            TextDrawSetString(DerbyInfo, string);
            TextDrawShowForPlayer(playerid, DerbyInfo);
        }
        case INFERNUS_DERBY:
        {
            ShowInfoBox(playerid, 0x00000088, 7, "In this Derby you have to survive as the last vehicle to win!");
            InDerby[playerid] = 1;
            PlayersInDerby += 1;

            SpawnPlayerInDerby(playerid, 411, InfernusDerby, 7);
            PutPlayerInVehicle(playerid,DerbyVehicles[playerid],0);
            SetVehicleHealth(DerbyVehicles[playerid],20000);
            TogglePlayerControllable(playerid, false);

            format(string, sizeof(string), "~r~Derby Map: ~g~Infernus Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
            TextDrawSetString(DerbyInfo, string);
            TextDrawShowForPlayer(playerid, DerbyInfo);
        }    
    }
    return 1;
}

CMD:leavederby(playerid, params[])
{
    new string[128];
    if(InDerby[playerid] == 0) return SCM(playerid,red,"You are not in derby");
    if(InDerby[playerid] == 1 && DerbyStarted == false) return SCM(playerid, red, "You can't leave the derby now");

    InDerby[playerid] = 0;
    PlayersInDerby -= 1;
    DestroyVehicle(GetPlayerVehicleID(playerid));
    SpawnPlayerEx(playerid);
    TextDrawHideForPlayer(playerid, DerbyInfo);
    SCM(playerid, red, "You have left the derby");

    if(PlayersInDerby == 1)
    {
        foreach(new i : Player)
        {
            for(new x; x < DerbyVehicles[i]; x++)
            {
                DestroyVehicle(DerbyVehicles[i]);
            }

            if(InDerby[i] == 1)
            {
                InDerby[i] = 0;
                format(string, sizeof(string), "%s has won the derby", GetName(i));
                SendClientMessageToAll(0x00FFFFFF, string);
                TextDrawHideForPlayer(i, DerbyInfo);
                SpawnPlayerEx(i);
                Info[i][XP] += 100;
                GivePlayerCash(i, randomEx(10000,30000));
                format(string, sizeof(string), "Winner $%s ~n~+100 XP", randomEx(10000,30000));
                WinnerText(i, string);
            }
        }
        KillTimer(DerbyTDTimer);
        DerbyGame = NON_DERBY;
        DerbyStarted = false;
        PlayersInDerby = 0;
    }
    return 1;
}

CMD:tdm(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't start the TDM while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You are already in the TDM");
    if(TDMStarted == true) return SCM(playerid, red, "There is already TDM in progress");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");
    if(InAmmu[playerid] == 1) return SCM(playerid, red, "You must leave the ammunation to join the TDM");

    pProtectTick[playerid] = 0;
    ShowPlayerDialog(playerid, DIALOG_TDM, DIALOG_STYLE_LIST, "TDM Minigames", "Team Deathmatch #1\nTeam Deathmatch #2", "Start", "Cancel");
    return 1;
}

CMD:jointdm(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the TDM while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You are already in the TDM");
    if(TDMStarted == true) return SCM(playerid, red, "TDM has already started");
    if(PlayersInTDM >= MAX_TDM_PLAYERS) return SCM(playerid, red, "TDM is full");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    pProtectTick[playerid] = 0;
    InAmmu[playerid] = 0;
    GetPlayerSpawnEx(playerid);
    if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

    switch(TDMGame)
    {
        case TDM_ONE:
        {
            ShowInfoBox(playerid, 0x00000088, 7, "In this TDM you have to kill the enemy team to win the match");
            SendClientMessage(playerid, green, "TDM will start in 30 seconds");
            InTDM[playerid] = 1;
            PlayersInTDM += 1;

            TextDrawShowForPlayer(playerid, TDMInfo);
            ResetPlayerWeaponsEx(playerid);
            SetPlayerHealthEx(playerid, 100);
            SetPlayerArmourEx(playerid, 100);
            switch(TeamBalance)
            {
                case 0:
                {
                    PlayerTeamOne += 1;
                    TeamBalance = 1;
                    SetPlayerTeam(playerid, TDMTeamOne);
                    SetPlayerPosition(playerid,970.3297, -2708.9780, 19.7077, 266.6773);
                    ResetPlayerWeaponsEx(playerid);
                    TogglePlayerControllable(playerid, false);
                }
                case 1:
                {
                    PlayerTeamTwo += 1;
                    TeamBalance = 0;
                    SetPlayerTeam(playerid, TDMTeamTwo);
                    SetPlayerPosition(playerid, 1047.9230, -2708.3545, 19.7077, 92.1489);
                    ResetPlayerWeaponsEx(playerid);
                    TogglePlayerControllable(playerid, false);
                }
            }
        }
        case TDM_TWO:
        {
            ShowInfoBox(playerid, 0x00000088, 7, "In this TDM you have to kill the enemy team to win the match");
            SendClientMessage(playerid, green, "TDM will start in 30 seconds");
            InTDM[playerid] = 1;
            PlayersInTDM += 1;

            TextDrawShowForPlayer(playerid, TDMInfo);
            ResetPlayerWeaponsEx(playerid);
            SetPlayerHealthEx(playerid, 100);
            SetPlayerArmourEx(playerid, 100);
            switch(TeamBalance)
            {
                case 0:
                {
                    PlayerTeamOne += 1;
                    TeamBalance = 1;
                    SetPlayerTeam(playerid, TDMTeamOne);
                    SetPlayerPosition(playerid, 172.1281, 1886.1561, 1101.2722, 0.3179);
                    ResetPlayerWeaponsEx(playerid);
                    TogglePlayerControllable(playerid, false);
                }
                case 1:
                {
                    PlayerTeamTwo += 1;
                    TeamBalance = 0;
                    SetPlayerTeam(playerid, TDMTeamTwo);
                    SetPlayerPosition(playerid, 185.7635, 1981.8048, 1101.2722, 179.5225);
                    ResetPlayerWeaponsEx(playerid);
                    TogglePlayerControllable(playerid, false);
                }
            }	
        }
    }
    return 1;
}

CMD:leavetdm(playerid, params[])
{
    if(InTDM[playerid] == 0) return SCM(playerid, red, "You are not in TDM");

    new string[128];
    SCM(playerid, red, "You have left the TDM");
    InTDM[playerid] = 0;
    PlayersInTDM -= 1;
    TogglePlayerControllable(playerid, true);
    TextDrawHideForPlayer(playerid, TDMInfo);
    ResetPlayerWeaponsEx(playerid);
    SpawnPlayerEx(playerid);
    SetPlayerHealthEx(playerid, 100);
    SetPlayerArmourEx(playerid, 100);
    if(GetPlayerTeam(playerid) == TDMTeamOne) PlayerTeamOne -= 1;
    if(GetPlayerTeam(playerid) == TDMTeamTwo) PlayerTeamTwo -= 1;
    if(PlayerTeamOne == 0)
    {
        foreach(new i : Player)
        {
            if(InTDM[i] == 1 && GetPlayerTeam(i) == TDMTeamTwo)
            {
                InTDM[i] = 0;
                
                format(string, sizeof(string), "%s has won the TDM", GetName(i));
                SendClientMessageToAll(0x00FFFFFF, string);
                Info[i][XP] += 100;
                GivePlayerCash(i, randomEx(10000,30000));
                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                WinnerText(i, string);
                TextDrawHideForPlayer(i, TDMInfo);
                SpawnPlayerEx(i);
                ResetPlayerWeaponsEx(i);
                SetPlayerHealthEx(i, 100);
                SetPlayerArmourEx(i, 100);
            }
            if(InTDM[i] == 1)
            {
                InTDM[i] = 0;
                TextDrawHideForPlayer(i, TDMInfo);
                SpawnPlayerEx(i);
                ResetPlayerWeaponsEx(i);
                SetPlayerHealthEx(i, 100);
                SetPlayerArmourEx(i, 100);
            }
        }
        KillTimer(TDTimer);
        TDMGame = NON_TDM;
        TDMStarted = false;
        PlayersInTDM = 0;
        PlayerTeamOne = 0;
        PlayerTeamTwo = 0;
    }
    if(PlayerTeamTwo == 0)
    {
        foreach(new i : Player)
        {
            if(InTDM[i] == 1 && GetPlayerTeam(i) == TDMTeamOne)
            {
                InTDM[i] = 0;
                format(string, sizeof(string), "%s has won the TDM", GetName(i));
                SendClientMessageToAll(0x00FFFFFF, string);
                Info[i][XP] += 100;
                GivePlayerCash(i, randomEx(10000,30000));         
                format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                WinnerText(i, string);
                TextDrawHideForPlayer(i, TDMInfo);
                ResetPlayerWeaponsEx(i);
                SpawnPlayerEx(i);
                SetPlayerHealthEx(i, 100);
                SetPlayerArmourEx(i, 100);
            }
            if(InTDM[i] == 1)
            {
                InTDM[i] = 0;
                TextDrawHideForPlayer(i, TDMInfo);
                ResetPlayerWeaponsEx(i);
                SpawnPlayerEx(i);
                SetPlayerHealthEx(i, 100);
                SetPlayerArmourEx(i, 100);
            }
        }
        KillTimer(TDTimer);
        TDMGame = NON_TDM;
        TDMStarted = false;
        PlayersInTDM = 0;
        PlayerTeamOne = 0;
        PlayerTeamTwo = 0;
    }
    return 1;
}

CMD:teles(playerid,params[])
{
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You are already in parkour");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);

    new string[128];
    for(new i = 0; i <= TeleCount; i++)
    {
       format(string,sizeof(string),"%s\n",TeleName[i]);
       strcat(VLstring, string, sizeof(VLstring));
    }
    ShowPlayerDialog(playerid, DIALOGS+114, DIALOG_STYLE_LIST, "Teleports", VLstring, "Teleport", "Close");
    if(strlen(VLstring) < 1) ShowPlayerDialog(playerid, DIALOGS+116, DIALOG_STYLE_MSGBOX, "Teleports", "{FF0000}No teleports found", "Close", "");
    return 1;
}

CMD:parkour(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the parkour while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You are already in parkour");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    pProtectTick[playerid] = 0;
    ShowPlayerDialog(playerid, DIALOG_PARKOURS, DIALOG_STYLE_LIST, "Parkour Minigames", "Parkour #1\nParkour #2\nParkour #3\nParkour #4\nParkour #5\nParkour #6", "Select", "Cancel");
    return 1;
}

CMD:skydive(playerid, params[])
{
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't join the skydive while you are in a gang zone");
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You are already in the skydive");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    pProtectTick[playerid] = 0;
    ShowPlayerDialog(playerid, DIALOG_SKYDIVE, DIALOG_STYLE_LIST, "Skydive Minigames", "Skydive #1\nSkydive #2\nSkydive #3", "Select", "Cancel");
    return 1;
}

CMD:leaveskydive(playerid, params[])
{
    if(InSkydive[playerid] == 0) return SCM(playerid, red, "You are not in skydive minigame");

    InSkydive[playerid] = 0;
    ResetPlayerWeaponsEx(playerid);
    SpawnPlayerEx(playerid);
    SCM(playerid, red, "You have left the skydive minigame");
    return 1;
}

CMD:leaveparkour(playerid, params[])
{
    if(InParkour[playerid] == 0) return SCM(playerid, red, "You are not in parkour minigame");

    DestroyVehicle(GetPlayerVehicleID(playerid));

    InParkour[playerid] = 0;
    SpawnPlayerEx(playerid);
    SCM(playerid, red, "You have left the parkour minigame");
    return 1;
}

CMD:duel(playerid, params[])
{
	new id, w1, w2, c;
    if(sscanf(params, "uiii", id, w1, w2, c)) return SCM(playerid, red, "Duel player: /duel <PlayerID> <WeaponID> <WeaponID> <Bet>");
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't duel player while you are in a gang zone");
    if(InParkour[playerid] == 1 || InSkydive[playerid] == 1 || InTDM[playerid] == 1 || InEvent[playerid] == 1 || InDerby[playerid] == 1) 
    return SCM(playerid, red, "You can't duel player while you are in minigame");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You are already in a duel");
    if(Invited[playerid] == 2) return SCM(playerid, red, "You already invited someone to a duel");
    if(Invited[playerid] == 1) return SCM(playerid, red, "You are already invited by someone");
    if(id == playerid) return SCM(playerid, red, "You cannot invite yourself");
    if(GetPlayerCash(playerid) < c) return SCM(playerid, red, "You cannot affrod this bet");

    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    if(InParkour[id] || InSkydive[id] || InTDM[id] || InEvent[id] || InDerby[id]) return SCM(playerid, red, "You can't duel player while you are in minigame");
    if(InDuel[id] == 1) return SCM(playerid, red, "Player is already in a duel");
    if(Invited[id] == 1) return SCM(playerid, red, "Player is already invited to a duel");
    if(GetPlayerCash(id) < c) return SCM(playerid, red, "Player cannot affrod this bet");
	if(w1 < 1 || w1 > 42 || w1 == 38 || w1 == 36 || w1 == 40 || w1 == 39 || w1 == 21 || w1 == 20 || w1 == 19) return SCM(playerid, red, "Invalid weapon1 id");
    if(w2 < 1 || w2 > 42 || w2 == 38 || w2 == 36 || w2 == 40 || w2 == 39 || w2 == 21 || w2 == 20 || w2 == 19) return SCM(playerid, red, "Invalid weapon2 id");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    new wname1[34], wname2[34], string[124];
    GetWeaponName(w1, wname1, 34);
	GetWeaponName(w2, wname2, 34);

    format(string, 124, "[DUEL] %s (%d) have invited you to a duel for $%s. Weapons: %s and %s", GetName(playerid), playerid, cNumber(c), wname1, wname2);
    SCM(id, 0x00CDFFFF, string);

    format(string, 124, "[DUEL] You have invited %s (%d) to a duel for $%s. Weapons: %s and %s", GetName(id), id, cNumber(c), wname1, wname2);
    SCM(playerid, 0x00CDFFFF, string);

    SCM(playerid, 0x00CDFFFF, "[DUEL] Player have 15 second to ignore or accept it");
    SCM(id, 0x00CDFFFF, "[DUEL] You have 15 second to ignore or accept it");

    Invited[id] = 1;
    Invited[playerid] = 2;
    Weapon1[id] = w1;
    Weapon1[playerid] = w1;
    Weapon2[id] = w2;
    Weapon2[playerid] = w2;
    Opponent[playerid] = id;
   	Opponent[id] = playerid;
    Bet[id] = c;
    Bet[playerid] = c;
    pProtectTick[playerid] = 0;
    Dtimer[id] = SetTimerEx("CancelDuel", 15000, false, "i", id);
    Dtimer[playerid] = SetTimerEx("CancelDuel", 15000, false, "i", playerid);
    return 1;
}

new virtualworldforduel = 69;
CMD:daccept(playerid, params[])
{
    if(Invited[playerid] == 0) return SCM(playerid, red, "You aren't invited to any duel");
    if(Invited[playerid] == 2) return SCM(playerid, red, "You can accept your own duel request");
    if(IsPlayerInAnyGangZone(playerid) && pTeam[playerid] != NO_TEAM) return SCM(playerid, red, "You can't accept the duel while you are in a gang zone");
    if(InParkour[playerid] || InSkydive[playerid] || InTDM[playerid] || InEvent[playerid] || InDerby[playerid]) return SCM(playerid, red, "You can't accept the duel while you are in minigame");
    if(gettime() - AbuseTick[playerid] < 20) return SCM(playerid, red, "You have been attacked by another player");

    new id = Opponent[playerid];
    new w1 = Weapon1[playerid];
    new w2 = Weapon2[playerid];
    new wname1[34], wname2[34];
    GetWeaponName(w1, wname1, 34);
    GetWeaponName(w2, wname2, 34);
    InDuel[playerid] = 1;
    InDuel[id] = 1;
    Opponent[id] = playerid;
    Opponent[playerid] = id;
    pProtectTick[playerid] = 0;

    GetPlayerSpawnEx(playerid);
    GetPlayerSpawnEx(id);

    SetPlayerHealthEx(playerid, 100);
    SetPlayerHealthEx(id, 100);
    SetPlayerArmourEx(playerid, 100);
    SetPlayerArmourEx(id, 100);
    SetPlayerInterior(playerid, 10);
    SetPlayerInterior(id, 10);
    SetPlayerPos(playerid, -975.975708, 1060.983032, 1345.671875);
    SetPlayerPos(id, -1130.3517, 1057.7616, 1346.4141);
    ResetPlayerWeaponsEx(playerid);
    ResetPlayerWeaponsEx(id);
    SetPlayerTeam(playerid, NO_TEAM);
    SetPlayerTeam(id, NO_TEAM);
    GivePlayerWeaponEx(playerid, w1, 9999999);
    GivePlayerWeaponEx(id, w1, 9999999);
    GivePlayerWeaponEx(playerid, w2, 9999999);
    GivePlayerWeaponEx(id, w2, 9999999);
    KillTimer(Dtimer[id]);
    KillTimer(Dtimer[playerid]);

    new string[124];
    format(string, sizeof(string), "[DUEL] A duel have been started between %s (%d) and %s (%d) for $%s - Weapons: %s and %s", GetName(playerid), playerid, GetName(id), id, cNumber(Bet[playerid]), wname1, wname2);
    SendClientMessageToAll(0x00CDFFFF, string);
	SetPlayerVirtualWorld(playerid, virtualworldforduel);
    SetPlayerVirtualWorld(id, virtualworldforduel);
    virtualworldforduel++;
    return 1;
}

CMD:skins(playerid, params[])
{
	if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid,red,"You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDuel[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");

    new query[140], Cache:skins, skinid;
    mysql_format(mysql, query, sizeof(query), "SELECT `SkinID` FROM `SkinData` WHERE `ID` = %d ORDER BY `SkinID` ASC", Info[playerid][ID]);
	skins = mysql_query(mysql, query);
	new rows = cache_num_rows();

	if(rows)
	{
	    new list[512];
	    format(list, sizeof(list), "#\tSkin ID\tSkin Name\n");
	    for(new i; i < rows; ++i)
	    {
	    	skinid = cache_get_field_content_int(i, "SkinID");

	        format(list, sizeof(list), "%s%d\t%d\t%s\n", list, i+1, skinid, GetSkinName(skinid));
	    }
	    ShowPlayerDialog(playerid, DIALOG_SKIN_TAKE, DIALOG_STYLE_TABLIST_HEADERS, "Inventory - Skins", list, "Select", "Close");
	}
	else SendClientMessage(playerid, red, "You don't have any skins in your inventory");
	cache_delete(skins);
	return 1;
}

CMD:buyproperty(playerid, params[])
{
    new string[128];
	foreach(new i : Property)
    {
        if(IsPlayerInRangeOfPoint(playerid, 2.0, pInfo[i][PropertyX], pInfo[i][PropertyY], pInfo[i][PropertyZ]))
        {
			if(!strcmp(pInfo[i][Owner], "-"))
            {
		   	 	format(string, sizeof(string), "{FFFFFF}Property: {00FF00}%s\n{FFFFFF}Price: {00FF00}$%s\n{FFFFFF}Revenue: {00FF00}$%s\n{FFFFFF}Buy it?", pInfo[i][prName], cNumber(pInfo[i][Price]), cNumber(pInfo[i][Earning]));
				ShowPlayerDialog(playerid, DIALOG_BUY_PROPERTY, DIALOG_STYLE_MSGBOX, "Buy Property", string, "Buy", "Cancel");
			}
		}
	}
	return 1;
}

CMD:propertyinfo(playerid, params[])
{
	new pID = AvailablePID[playerid],
	 	string[360];

	if(!IsPlayerInRangeOfPoint(playerid, 2.0, pInfo[pID][PropertyX], pInfo[pID][PropertyY], pInfo[pID][PropertyZ])) return SCM(playerid, red, "You are not near the property");

    new diff_secs = ( pInfo[pID][PropertyExpire] - gettime() );
    new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
    diff_secs -= remain_months * 60 * 60 * 24 * 30;
    new remain_days = ( diff_secs / (60 * 60 * 24) );
    diff_secs -= remain_days * 60 * 60 * 24;
    new remain_hours = ( diff_secs / (60 * 60) );
    diff_secs -= remain_hours * 60 * 60;
    new remain_minutes = ( diff_secs / 60 );

	if(!strcmp(pInfo[pID][Owner], "-")) format(string, sizeof(string), "{FFFFFF}Property ID: {00FF00}%i\n{FFFFFF}Property: {00FF00}%s\n{FFFFFF}Price: {00FF00}$%s\n{FFFFFF}Revenue: {00FF00}$%s", pID, pInfo[pID][prName], cNumber(pInfo[pID][Price]), cNumber(pInfo[pID][Earning]));
    else
    { 
        format(string, sizeof(string), "{FFFFFF}Property ID: {00FF00}%i\n{FFFFFF}Property: {00FF00}%s\n{FFFFFF}Price: {00FF00}$%s\n{FFFFFF}Owner: {00FF00}%s\n{FFFFFF}Revenue: {00FF00}$%s\n{FFFFFF}Timleft: {00FF00}%d Months %d Days %d Hours %d Minutes", 
        pID, pInfo[pID][prName], cNumber(pInfo[pID][Price]), pInfo[pID][Owner], cNumber(pInfo[pID][Earning]), remain_months, remain_days, remain_hours, remain_minutes);
    }

	ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Property", string, "Close", "");
	return 1;
}

CMD:properties(playerid, params[])
{
    new string[128], cstring[128 * 10], cnt = 0;
    foreach(new i : Property)
    {
        if(cnt > 9)
        {
            strcat(cstring, "Next\n");
            break;
        }
        else
        {
            if(pOwns(playerid, i))
            {
                new diff_secs = ( pInfo[i][PropertyExpire] - gettime() );
                new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
                diff_secs -= remain_months * 60 * 60 * 24 * 30;
                new remain_days = ( diff_secs / (60 * 60 * 24) );
                diff_secs -= remain_days * 60 * 60 * 24;
                new remain_hours = ( diff_secs / (60 * 60) );
                diff_secs -= remain_hours * 60 * 60;
                new remain_minutes = ( diff_secs / 60 );

                format(string, sizeof(string), "{FFFFFF}Property: {00FF00}%s {FFFFFF}Location: {00FF00}%s (%d months %d days %d hours %d minutes)\n", pInfo[i][prName], GetZoneName(pInfo[i][PropertyX], pInfo[i][PropertyY], pInfo[i][PropertyZ]),
                remain_months, remain_days, remain_hours, remain_minutes);
                strcat(cstring, string);

                cnt++;
                CompleteLoop[playerid] = cnt;
                PlayerItem[playerid] = cnt;
            }
        }
    }
    if(cnt == 0) ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Properties", "{FF0000}No properties found", "Close", "");
    else ShowPlayerDialog(playerid, DIALOG_PROPERTIES, DIALOG_STYLE_LIST, "Properties", cstring, "Close", "");
    return 1;
}

CMD:friend(playerid, params[])
{
    new id, string[128], query[128];
    if(sscanf(params, "u", id)) return SCM(playerid, red, "Add friend: /friend <PlayerID>");
    if(Info[playerid][Friends] >= 20) return SCM(playerid, red, "You can't add more players");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    if(id == playerid) return SCM(playerid, red, "You can't add yourself");

    new Cache:friend;
    mysql_format(mysql, query, sizeof(query), "SELECT `FriendID` FROM `FriendsData` WHERE `ID` = %d", Info[playerid][ID]);
    friend = mysql_query(mysql, query);
    new rows = cache_num_rows();

    if(rows) 
    {
        new friendid;
        for(new i; i < rows; i++) 
        {
            friendid = cache_get_field_content_int(i, "FriendID");

            if(friendid == Info[id][ID]) return SCM(playerid, red, "Player is already in your friend list");
        }
        cache_delete(friend);
    }
    else
    {
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `FriendsData` (ID, FriendID) VALUES (%d, %d)", Info[playerid][ID], Info[id][ID]);
        mysql_tquery(mysql, query);

        format(string, sizeof(string), "You have added %s to your friend list", GetName(id));
        SCM(playerid, red, string);

        format(string, sizeof(string), "%s has added you to his friend list", GetName(playerid));
        SCM(id, NOTIF, string);

        Info[playerid][Friends]++;
    }
    cache_delete(friend);
    return 1;
} 

CMD:unfriend(playerid, params[])
{
    new id, string[128], query[128];
    if(sscanf(params, "u", id)) return SCM(playerid, red, "Delete friend: /unfriend <PlayerID>");
    if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    if(id == playerid) return SCM(playerid, red, "Invalid player ID");

    new Cache:friend;
    mysql_format(mysql, query, sizeof(query), "SELECT `FriendID` FROM `FriendsData` WHERE `FriendID` = %d AND `ID` = %d", Info[id][ID], Info[playerid][ID]);
    friend = mysql_query(mysql, query);
    new rows = cache_num_rows();

    if(rows) 
    {
        mysql_format(mysql, query, sizeof(query), "DELETE FROM `FriendsData` WHERE `FriendID` = %d AND `ID` = %d", Info[id][ID], Info[playerid][ID]);
        mysql_tquery(mysql, query);

        format(string, sizeof(string), "You have deleted %s from your friend list", GetName(id));
        SCM(playerid, red, string);

        Info[playerid][Friends]--;
    }
    else SCM(playerid, red, "Player is not in your friend list");
    cache_delete(friend);
    return 1;
}

CMD:friendchat(playerid, params[])
{
    new query[128], txt[84];
    if(sscanf(params, "s[84]", txt)) return SCM(playerid, red, "Friends chat: /friendchat <Message>");

    new Cache:friend, pID, found = 0;
    mysql_format(mysql, query, sizeof(query), "SELECT `FriendID` FROM `FriendsData` WHERE `ID` = %d", Info[playerid][ID]);
    friend = mysql_query(mysql, query);
    new rows = cache_num_rows();

    if(rows)
    {
        for(new i; i < rows; i++) 
        {
            pID = cache_get_field_content_int(i, "FriendID");

            foreach(new x : Player)
            {
                if(pID == Info[x][ID])
                {
                    format(query, sizeof(query), "%s (%d) [FRIENDS]: {FFFFFF}%s", GetName(playerid), playerid, txt);
                    SCM(x, GetPlayerColor(playerid), query);
                    found++;
                }
            }
        }
        SCM(playerid, GetPlayerColor(playerid), query);
    }
    else if(found == 0) SCM(playerid, red, "No online friends found");
    cache_delete(friend);
    return 1;
}
CMD:f(playerid, params[]) return cmd_friendchat(playerid, params);

CMD:friends(playerid, params[])
{
    new query[140], Cache:friends, pID, found = 0;
    mysql_format(mysql, query, sizeof(query), "SELECT `FriendID` FROM `FriendsData` WHERE `ID` = %d ORDER BY `FriendID` ASC", Info[playerid][ID]);
    friends = mysql_query(mysql, query);
    new rows = cache_num_rows();

    new list[512];
    if(rows) 
    {
        for(new i; i < rows; ++i)
        {
            pID = cache_get_field_content_int(i, "FriendID");

            foreach(new x : Player)
            {
                if(pID == Info[x][ID]) 
                {
                    format(list, sizeof(list), "%s (%d) %s\n", GetName(x), x, IsPlayerAFK(x) == 1 ? ("{FF0000}AFK"):("") );
                    found++;
                }
            }
        }
    }
    if(found == 0) ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_LIST, "Note", "{FF0000}No online friends found", "Close", "");
    else ShowPlayerDialog(playerid, DIALOG_FRIENDS, DIALOG_STYLE_LIST, "Online Friends", list, "Close", "");
    cache_delete(friends);
    return 1;
}

CMD:opm(playerid, params[])
{
	new txt[84], name[MAX_PLAYER_NAME];
	if(sscanf(params, "s[24]s[84]", name, txt)) return SCM(playerid, red, "Offline PM: /opm <PlayerName> <Message>");
    if(strlen(txt) > 84) return SCM(playerid, red, "Input text is too long");
	if(strfind(GetName(playerid), name, true) != -1) return SCM(playerid, red, "Invalid player name");
	if(IsPlayerConnected(GetID(name))) return SCM(playerid, red, "Player is connected");
	if(!AccountExists(name)) return SCM(playerid, red, "Account does not exists");

	new query[180];
	mysql_format(mysql, query, sizeof(query), "INSERT INTO `OfflinePMs` (`PlayerName`, `SenderName`, `Message`, `Status`) VALUES ('%e', '%e', '%e', 0)", name, GetName(playerid), txt);
	mysql_tquery(mysql, query);

	format(query, sizeof(query), "You have sent an offline message to %s", name);
	SCM(playerid, green, query);
	return 1;
}

CMD:myopms(playerid, params[])
{
    ShowPlayerDialog(playerid, DIALOG_OPMS, DIALOG_STYLE_LIST, "Offline Private Messages", "Show all messages\nShow read messages\nShow unread messages\nClear messages", "Select", "Close");
    return 1;
}

CMD:buyseeds(playerid, params[])
{
    if(!IsPlayerInRangeOfPoint(playerid, 2.0, -1061.2837, -1195.5339, 129.7724)) return SCM(playerid, red, "You must be close the marijuana dealer to buy seeds");
    ShowPlayerDialog(playerid, DIALOG_SEEDS, DIALOG_STYLE_LIST, "Marijuana Seeds", "{FFFFFF}25 Seeds {00FF00}$60,000\n\
                                                                                    {FFFFFF}50 Seeds {00FF00}$90,000\n\
                                                                                    {FFFFFF}100 Seeds {00FF00}$150,000\n", "Buy", "Close");
    return 1;
}

CMD:plant(playerid,params[])
{
	if(IsPlayerAtFarm(playerid))
	{
		new Float:X, Float:Y, Float:Z;
		GetPlayerPos(playerid, X, Y, Z);
	    new near = IsNearPlant(playerid);

	    if(near == -1)
	    {
	    	if(Z > 129.218750) return SendClientMessage(playerid, red, "You have to plant the marijuana only at the ground");
	    	if(GetPlayerCash(playerid) < 15000) return SCM(playerid, red, "You don't have enough money to plant");
            if(Info[playerid][Seeds] < 5) return SCM(playerid, red, "You need at least 5 seeds to plant");

	    	ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, false, false, false, false, 0, false);
	    	SetTimerEx("PlantMarijuana", 2000, false, "i", playerid);

            SaveLog(playerid, "has planted a marijuana plant");
	    	return 1;
		}
		else return SendClientMessage(playerid, red,"You can't plant too close to other plants");
	}
	else return SendClientMessage(playerid, red,"You should be at the farm to be able to plant");
}

CMD:sellmoney(playerid, params[])
{
	if (Info[playerid][UGC] >= 25)
    {
    	new string[2000], str[80];
        for (new Float: i = 0.25, Float: j = Currency(playerid); i <= j; i += 0.25) // Much thanks to Konstantinos
        {
            format(str, sizeof str, "{FF0066}%.2f UGC\n", i);
            strcat(string, str);
        }
        
        ShowPlayerDialog(playerid, DIALOG_SELL_MONEY, DIALOG_STYLE_LIST, "Sell UGC", string, "Select", "Close");
    	return 1;
    }
    else return SCM(playerid, red, "You don't have enough money");
}

CMD:sellcancel(playerid, params[])
{
	new query[140], Cache:market;
    mysql_format(mysql, query, sizeof(query), "SELECT `Amount`, `Price` FROM `Market` WHERE `Seller` = '%e'", GetName(playerid));
	market = mysql_query(mysql, query);
	new rows = cache_num_rows();

	if(rows) 
	{
		mysql_format(mysql, query, sizeof(query), "DELETE FROM `Market` WHERE `Seller` = '%e'", GetName(playerid));
		mysql_tquery(mysql, query);

		SCM(playerid, 0xFF0066FF, "You have removed your item from the marketplace");
	}
	else SendClientMessage(playerid, red, "You don't have items in the marketplace");
    cache_delete(market);
	return 1;
}

CMD:playersmoney(playerid,params[])
{
   new IsOnline = 0;
   new string[500], Jstring[128];
   foreach(new i : Player)
   {
        if(Info[i][UGC] >= 25)
        {
            format(Jstring, 128, "{FFFFFF}%s (%d) {FF0066}%0.2f UGC\n", GetName(i), i, Currency(i));
            strcat(string, Jstring, sizeof(string));
            IsOnline++;
        }
   }
   if (IsOnline == 0)
   ShowPlayerDialog(playerid,DIALOGS+165,DIALOG_STYLE_MSGBOX,"Note","{FF0000}No players found" ,"Close","");
   else ShowPlayerDialog(playerid,DIALOGS+165,DIALOG_STYLE_LIST,"Players Money",string ,"Close","");
   return 1;
}

CMD:market(playerid, params[])
{
 	mysql_tquery(mysql, "SELECT * FROM `Market`", "OnMarketLoad", "i", playerid);
	return 1;
}

CMD:buyhouse(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) 
    {
        new i = GetPVarInt(playerid, "PickupHouseID");
        if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[i][houseX], HouseData[i][houseY], HouseData[i][houseZ]))
        {
            if(!strcmp(HouseData[i][Owner], "-")) 
            {
                new string[128];
                format(string, sizeof(string), "{FFFFFF}House: {00FF00}%d\n{FFFFFF}Price: {00FF00}$%s\n{FFFFFF}Interior: {00FF00}%d\n{FFFFFF}Buy it?", i, cNumber(HouseData[i][Price]), HouseData[i][Interior]);
                ShowPlayerDialog(playerid, DIALOG_BUY_HOUSE, DIALOG_STYLE_MSGBOX, "Buy House", string, "Buy", "Close");
            }
        }
    }
    return 1;
}

CMD:enterexit(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) 
    {
        if(!IsPlayerInAnyVehicle(playerid))
        {
            new i = GetPVarInt(playerid, "PickupHouseID");
            if(strcmp(HouseData[i][Owner], "-")) 
            {
                if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[i][houseX], HouseData[i][houseY], HouseData[i][houseZ]))
                {
                    switch(HouseData[i][LockMode])
                    {
                        case STATUS_NOLOCK: SendToHouse(playerid, i);
                        case STATUS_KEYS:
                        {
                            new gotkeys = Iter_Contains(HouseKeys[playerid], i);
                            if(!gotkeys) if(!strcmp(HouseData[i][Owner], GetName(playerid))) gotkeys = 1;

                            if(gotkeys) SendToHouse(playerid, i);
                            else ShowInfoBox(playerid, 0x00000088, 5, "You don't have the keys for this house");
                        }
                        case STATUS_LOCK:
                        {
                            if(!strcmp(HouseData[i][Owner], GetName(playerid))) 
                            {
                                SendToHouse(playerid, i);
                            }
                            else ShowInfoBox(playerid, 0x00000088, 5, "You can't enter this house");
                        }
                    }
                }
            }
        }
    }
    else
    {
        for(new x; x < sizeof(HouseInteriors); x++)
        {  
            if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseInteriors[x][intX], HouseInteriors[x][intY], HouseInteriors[x][intZ]))
            {
                SetPlayerVirtualWorld(playerid, 0);
                SetPlayerInterior(playerid, 0);
                SetPlayerPos(playerid, HouseData[ InHouse[playerid] ][houseX], HouseData[ InHouse[playerid] ][houseY], HouseData[ InHouse[playerid] ][houseZ]);
                InHouse[playerid] = INVALID_HOUSE_ID;
                return 1;
            }
        }
    }
    return 1;
}

CMD:houses(playerid, params[])
{
    new string[128], cstring[128 * 10], cnt = 0;
    foreach(new i : Houses)
    {
        if(cnt > 9)
        {
            strcat(cstring, "Next\n");
            break;
        }
        else
        {
            if(!strcmp(HouseData[i][Owner], GetName(playerid)))
            {
                new diff_secs = ( HouseData[i][HouseExpire] - gettime() );
                new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
                diff_secs -= remain_months * 60 * 60 * 24 * 30;
                new remain_days = ( diff_secs / (60 * 60 * 24) );
                diff_secs -= remain_days * 60 * 60 * 24;
                new remain_hours = ( diff_secs / (60 * 60) );
                diff_secs -= remain_hours * 60 * 60;
                new remain_minutes = ( diff_secs / 60 );

                format(string, sizeof(string), "{FFFFFF}House: {00FF00}%d {FFFFFF}Location: {00FF00}%s {FFFFFF}(%d months %d days %d hours %d minutes)\n", i, GetZoneName(HouseData[i][houseX], HouseData[i][houseY],
                HouseData[i][houseZ]), remain_months, remain_days, remain_hours, remain_minutes);
                strcat(cstring, string);
                
                cnt++;
                CompleteLoop[playerid] = cnt;
                PlayerItem[playerid] = cnt;
            }
        }
    }
    if(cnt == 0) ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Houses", "{FF0000}No houses found", "Close", "");
    else ShowPlayerDialog(playerid, DIALOG_HOUSES, DIALOG_STYLE_LIST, "Houses", cstring, "Close", "");
    return 1;
}

CMD:houseinfo(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) 
    {
        new i = GetPVarInt(playerid, "PickupHouseID");
        if(IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[i][houseX], HouseData[i][houseY], HouseData[i][houseZ]))
        {
            new string[180];

            new diff_secs = ( HouseData[i][HouseExpire] - gettime() );
            new remain_months = ( diff_secs / (60 * 60 * 24 * 30) );
            diff_secs -= remain_months * 60 * 60 * 24 * 30;
            new remain_days = ( diff_secs / (60 * 60 * 24) );
            diff_secs -= remain_days * 60 * 60 * 24;
            new remain_hours = ( diff_secs / (60 * 60) );
            diff_secs -= remain_hours * 60 * 60;
            new remain_minutes = ( diff_secs / 60 );

            if(!strcmp(HouseData[i][Owner], "-")) format(string, sizeof(string), "{FFFFFF}House: {00FF00}%d\n{FFFFFF}Price: {00FF00}$%s\n{FFFFFF}Interior: {00FF00}%d", i, cNumber(HouseData[i][Price]), HouseData[i][Interior]);
            else format(string, sizeof(string), "{FFFFFF}House: {00FF00}%d\n{FFFFFF}Price: {00FF00}$%s\n{FFFFFF}Owner: {00FF00}%s\n{FFFFFF}Interior: {00FF00}%d\n{FFFFFF}Timleft: {00FF00}%d Months %d Days %d Hours %d Minutes", 
            i, cNumber(HouseData[i][Price]), HouseData[i][Owner], HouseData[i][Interior], remain_months, remain_days, remain_hours, remain_minutes);

            ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "House", string, "Close", "");
        }
        else return SCM(playerid, red, "You are not near the house");
    }
    return 1;
}

CMD:house(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
    ShowHouseMenu(playerid);
    return 1;
}

CMD:mykeys(playerid, params[])
{
    new query[200], Cache: mykeys;
    mysql_format(mysql, query, sizeof(query), "SELECT `HouseID`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as `KeyDate` FROM `HouseKeys` WHERE `Player` = '%e' ORDER BY `Date` DESC LIMIT 0, 15", GetName(playerid));
    mykeys = mysql_query(mysql, query);
    ListPage[playerid] = 0;

    new rows = cache_num_rows();
    if(rows) 
    {
        new list[1024], id, key_date[20];
        format(list, sizeof(list), "Owner\tKey Given On\n");
        for(new i; i < rows; ++i)
        {
            id = cache_get_field_content_int(i, "HouseID");
            cache_get_field_content(i, "KeyDate", key_date);
            format(list, sizeof(list), "%s%s \t%s\n", list, HouseData[id][Owner], key_date);
        }

        ShowPlayerDialog(playerid, DIALOG_MY_KEYS, DIALOG_STYLE_TABLIST_HEADERS, "My Keys (Page 1)", list, "Next", "Close");
    }
    else SendClientMessage(playerid, red, "You don't have any keys for any houses");

    cache_delete(mykeys);
    return 1;
}

CMD:givehousekeys(playerid, params[])
{
    new id, houseid = InHouse[playerid];
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
    if(strcmp(HouseData[houseid][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
    if(sscanf(params, "u", id)) return SendClientMessage(playerid, red, "Give player keys: /givehousekeys <PlayerID>");
    if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, red, "Invalid player ID");
    if(id == playerid) return SendClientMessage(playerid, red, "Invalid player ID");
    if(Iter_Contains(HouseKeys[id], houseid)) return SendClientMessage(playerid, red, "Player already has the keys for this house");
    Iter_Add(HouseKeys[id], houseid);
    
    new query[128];
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `HouseKeys` SET `HouseID` = %d, `Player` = '%e', `Date` = UNIX_TIMESTAMP()", houseid, GetName(id));
    mysql_tquery(mysql, query);

    format(query, sizeof(query), "%s has given you the keys of his house", GetName(playerid));
    SCM(id, green, query);

    format(query, sizeof(query), "You have given the keys of your house to %s", GetName(id));
    SCM(playerid, red, query);
    return 1;
}

CMD:takehousekeys(playerid, params[])
{
    new id, houseid = InHouse[playerid];
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
    if(strcmp(HouseData[houseid][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
    if(sscanf(params, "u", id)) return SendClientMessage(playerid, red, "Take house keys: /takehousekeys <PlayerID>");
    if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, red, "Invalid player ID");
    if(id == playerid) return SendClientMessage(playerid, red, "Invalid player ID");
    if(!Iter_Contains(HouseKeys[id], houseid)) return SendClientMessage(playerid, red, "Player doesn't have keys for this house");

    Iter_Remove(HouseKeys[id], houseid);
    
    new query[128];
    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseKeys` WHERE `HouseID` = %d AND `Player` = '%e'", houseid, GetName(id));
    mysql_tquery(mysql, query);

    format(query, sizeof(query), "%s has took the keys of his house from you", GetName(playerid));
    SCM(id, green, query);

    format(query, sizeof(query), "You have took the keys of your house from %s", GetName(id));
    SCM(playerid, red, query);
    return 1;
}

CMD:housekick(playerid, params[])
{
    new id, houseid = InHouse[playerid];

    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, red, "You're not in the house");
    if(strcmp(HouseData[houseid][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");
    if(sscanf(params, "u", id)) return SendClientMessage(playerid, red, "Kick player from the house: /housekick <PlayerID>");
    if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, red, "Invalid player ID");
    if(id == playerid) return SendClientMessage(playerid, red, "You can't kick yourself from your house");
    if(InHouse[id] != houseid) return SendClientMessage(playerid, red, "Player is not in your house");

    ShowInfoBox(id, 0x00000088, 5, "You have been kicked from the house");
    SetPlayerVirtualWorld(id, 0);
    SetPlayerInterior(id, 0);
    SetPlayerPos(id, HouseData[houseid][houseX], HouseData[houseid][houseY], HouseData[houseid][houseZ]);
    InHouse[id] = INVALID_HOUSE_ID;
    return 1;
}

CMD:buyvehicle(playerid, params[])
{
    new id, string[128];
    if(sscanf(params, "i", id)) return SCM(playerid, red, "Buy vehicle: /buyvehicle <VehicleID>");
    if(!Iter_Contains(ServerVehicles, id)) return SendClientMessage(playerid, red, "Invalid vehicle ID");
    if(Info[playerid][vehLimit] == 3 && Info[playerid][Level] < 5) return SCM(playerid, red, "You have reached the limit");

    if(!strcmp(vInfo[id][vehOwner], "-"))
    {
        SetPVarInt(playerid, "buyVehicle", id);
        format(string, sizeof(string), "{FFFFFF}Vehicle: {00FF00}%s \n{FFFFFF}Price: {00FF00}$%s \n{FFFFFF}Buy it?", vInfo[id][vehName], cNumber(vInfo[id][vehPrice]));
        ShowPlayerDialog(playerid, DIALOG_BUY_VEHICLE, DIALOG_STYLE_MSGBOX, "Buy Vehicle", string, "Buy", "Close");
        return 1;
    }
    else return SCM(playerid, red, "Vehicle is already owned by a player");
}

CMD:vehicles(playerid, params[])
{
    if(Info[playerid][InDM] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InDerby[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InEvent[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InParkour[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InSkydive[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(InTDM[playerid] == 1) return SCM(playerid, red, "You can't use this command now");
    if(GetPlayerCash(playerid) < 1000) return SCM(playerid, red, "You don't have enough money");
    if(GetPlayerInterior(playerid) != 0 && Info[playerid][Level] != 5) return SCM(playerid, red, "You can't spawn your car in an interior");

    new bool:found = false, list[512];
    list = "ID\tVehicle\tNumber Plate\n";
    foreach(new i : PrivateVehicles[playerid])
    {
        if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
        {
            found = true;
            format(list, sizeof(list), "%s%d\t%s\t%s\n", list, i, vInfo[i][vehName], vInfo[i][vehPlate]);
        }
    }
    if(found == true) return ShowPlayerDialog(playerid, DIALOG_VEHICLES, DIALOG_STYLE_TABLIST_HEADERS, "Vehicles", list, "Select", "Close");
    else return ShowPlayerDialog(playerid, 2114, DIALOG_STYLE_MSGBOX, "Vehicles", "{FF0000}No vehicles found", "Close", "");
}
CMD:v(playerid, params[]) return cmd_vehicles(playerid, params);

CMD:changeplate(playerid, params[])
{
    new txt[16];
    if(sscanf(params, "s[16]", txt)) return SCM(playerid, red, "Change vehicle number plate: /changeplate <Text>");
    if(strlen(txt) > 16) return SCM(playerid, red, "Input text is too long");
    if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not inside any vheicle");
    if(GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) return SCM(playerid, red, "You must be the driver to use this command");

    foreach(new i : PrivateVehicles[playerid])
    {
        if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
        {
            if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
            { 
                SetVehicleNumberPlate(vInfo[i][vehSessionID], txt);
                vInfo[i][vehPlate] = txt;

                new Float:playerX, Float:playerY, Float:playerZ;
                GetPlayerPos(playerid, playerX, playerY, playerZ);

                SetVehicleToRespawn(vInfo[i][vehSessionID]);
                SetVehiclePos(vInfo[i][vehSessionID], playerX, playerY, playerZ);
                PutPlayerInVehicle(playerid, vInfo[i][vehSessionID], 0);

                SaveVehicle(i);
            }
        }
        else return SCM(playerid, red, "You are not the owner of this vehicle");
    }

    SCM(playerid, red, "You have changed your vehicle's number plate");
    return 1;
}
CMD:cplate(playerid, params[]) return cmd_changeplate(playerid, params);

CMD:lock(playerid, params[])
{
    if(isnull(params))
    {
        foreach(new i : ServerVehicles)
        {
            if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
            {
                if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
                {
                    foreach(new x : Player) if(x != playerid) SetVehicleParamsForPlayer(vInfo[i][vehSessionID], x, 0, 1);

                    GameTextForPlayer(playerid, "~w~LOCKED", 2000, 3);
                    vInfo[i][vehLock] = MODE_LOCK;
                    SaveVehicle(i);
                }
                else return SCM(playerid, red, "You are not the owner of this vehicle");
            }
        }
        return 1;
    }

    new id;
    if(sscanf(params, "i", id)) return SCM(playerid, red, "Unlock vehicle: /unlock <VehicleID>");
    if(!Iter_Contains(ServerVehicles, id)) return SendClientMessage(playerid, red, "Invalid vehicle ID");
    if(strcmp(vInfo[id][vehOwner], GetName(playerid))) return SCM(playerid, red, "You are not the owner of this vehicle");

    if(vInfo[id][vehLock] == MODE_NOLOCK)
    {
        foreach(new x : Player) if(x != playerid) SetVehicleParamsForPlayer(vInfo[id][vehSessionID], x, 0, 1);

        GameTextForPlayer(playerid, "~w~LOCKED", 2000, 3);
        vInfo[id][vehLock] = MODE_LOCK;
        SaveVehicle(id);
        return 1;
    }
    else return SCM(playerid, red, "Vehicles is already locked");
}

CMD:unlock(playerid, params[])
{
    if(isnull(params))
    {
        foreach(new i : ServerVehicles)
        {
            if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID]))
            {
                if(!strcmp(vInfo[i][vehOwner], GetName(playerid)))
                {
                    foreach(new x : Player) if(x != playerid) SetVehicleParamsForPlayer(vInfo[i][vehSessionID], x, 0, 0);

                    GameTextForPlayer(playerid, "~w~UNLOCKED", 2000, 3);
                    vInfo[i][vehLock] = MODE_NOLOCK;
                    SaveVehicle(i);
                }
                else return SCM(playerid, red, "You are not the owner of this vehicle");
            }
        }
        return 1;
    }

    new id;
    if(sscanf(params, "i", id)) return SCM(playerid, red, "Unlock vehicle: /unlock <VehicleID>");
    if(!Iter_Contains(ServerVehicles, id)) return SendClientMessage(playerid, red, "Invalid vehicle ID");
    if(strcmp(vInfo[id][vehOwner], GetName(playerid))) return SCM(playerid, red, "You are not the owner of this vehicle");

    if(vInfo[id][vehLock] == MODE_LOCK)
    {
        foreach(new x : Player) if(x != playerid) SetVehicleParamsForPlayer(vInfo[id][vehSessionID], x, 0, 0);

        GameTextForPlayer(playerid, "~w~UNLOCKED", 2000, 3);
        vInfo[id][vehLock] = MODE_NOLOCK;
        SaveVehicle(id);
        return 1;
    }
    else return SCM(playerid, red, "Vehicles is already unlocked");
}

/*============================================================================*/
/*--------------------------Administration Commands---------------------------*/
/*============================================================================*/

CMD:acmds(playerid, params[])
{
    new DIALOG[1246+546];
    if(Info[playerid][Level] >= 2)
    {
        strcat(DIALOG, "{FF0000}NOTE! You're able to teleport from the map (ESC -> MAP)\n\n");
        strcat(DIALOG, "{FF0066}Moderator\n");
        strcat(DIALOG, ""lightblue"/movev, /h, /aka, /slap, /duty, /cal, /acmds, /goto, /get, /acr, /rejr, /readcmd\n");
        strcat(DIALOG, ""lightblue"/warp, /kick, /asay, /specoff, /clearchat(cc), /spos, /savedata, /lpos, /hidename\n");
        strcat(DIALOG, ""lightblue"/clearplayerchat(cpc), /spec, /unmute, /yradio, /stopyradio, /lang, /mute, /move\n");
        strcat(DIALOG, "{00FF00}Use @ for Staff Chat\n\n");
    }
    if(Info[playerid][Level] >= 3)
    {
        strcat(DIALOG, "{FF0066}Administrator\n");
        strcat(DIALOG, ""lightblue"/ban, /givekills, /cashfor, /giveveh, /setwanted, /hidecar, /unhidecar, /setxp, /sethealth\n");
        strcat(DIALOG, ""lightblue"/oban, /freeze, /unfreeze, /akill, /setinterior, /marjfor, /cocfor, /bplayers, /setarmour\n");
        strcat(DIALOG, ""lightblue"/unban, /setkills, /godcar, /jetpack, /vhealth, /setname, /giveweapon, /disarm, /esys, /osys\n");
        strcat(DIALOG, ""lightblue"/heal, /armour, /fakecmd, /write, /jail, /unjail, /spawncar, /destroycars, /carcolor, /setxlevel\n\n");
    }
    if(Info[playerid][Level] >= 4)
    {
        strcat(DIALOG, "{FF0066}Lead Administrator\n");
        strcat(DIALOG, ""lightblue"/fakechat, /fakekill, /spam, /banip, /unbanip, /getip, /deleteaccount, /setskills\n");
        strcat(DIALOG, ""lightblue"/announce(ann), /screenmessage(ss), /resetcash, /setpos, /setcash, /setskin\n\n");
    }
    if(Info[playerid][Level] >= 5)
    {
        strcat(DIALOG, "{FF0066}Community Owner\n");
        strcat(DIALOG, ""lightblue"/hostname, /mapname, /gmtext, /setlevel, /setugc, /giveugc, /setpassword, /ctele\n");
        strcat(DIALOG, ""lightblue"/pcreate, /psetprice, /psetrevenue, /pdelete, /preset, /pgoto, /createhouse\n");
        strcat(DIALOG, ""lightblue"/deletehouse, /gotohouse, /resethouse, /sethouseprice, /sethouseinterior\n");
    }
    ShowPlayerDialog(playerid, DIALOGS+111 , DIALOG_STYLE_MSGBOX, "Administrative", DIALOG, "Close", "");
    return 1;
}

/*============================================================================*/
/*-------------------------------Level 2--------------------------------------*/
/*============================================================================*/

CMD:arules(playerid, params[])
{
    new string[800];
    if(Info[playerid][Level] >= 2)
    {
        strcat(string, "{00FF00}1. {FFFFFF}You are not allowed to abuse your commands, Although you can use it for fun SOMETIMES.\n");
        strcat(string, "{00FF00}2. {FFFFFF}You must not show your commands to the players, If you did accidentally, Do /cc as fast as possible.\n");
        strcat(string, "{00FF00}3. {FFFFFF}You must collect a enough proof on a cheater before banning/kicking him.\n");
    }
    ShowPlayerDialog(playerid, DIALOGS+111 , DIALOG_STYLE_MSGBOX, "Staff Rules", string, "Close", "");
    return 1;
}

CMD:logs(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new name[25];
        if(sscanf(params, "s[25]", name)) return SCM(playerid, red, "Player's logs: /logs <PlayerName>");
        if(!AccountExists(name)) return SCM(playerid, red, "Account is not exist");

        new Cache:pLogs, query[160], bstring[500], text[64], date[20];
        mysql_format(mysql, query, sizeof(query), "SELECT `PlayerName`, `Text`, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') AS `Date` FROM `PlayerLogs` WHERE `PlayerName` = '%e' ORDER BY `Date` ASC", name);
        pLogs = mysql_query(mysql, query);
        new rows = cache_num_rows();

        if(rows)
        {
            new str[512];
            for(new i; i < rows; ++i)
            {
                cache_get_field_content(i, "PlayerName", name);
                cache_get_field_content(i, "Text", text);
                cache_get_field_content(i, "Date", date);
            
                format(str, sizeof(str), "%s %s \t%s\n", name, text, date);
                strcat(bstring, str);
            }
            ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_LIST, "Player Logs", bstring, "Close", "");
        }
        else ShowPlayerDialog(playerid, WARN, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No logs found", "Close", "");
        cache_delete(pLogs);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:deletelogs(playerid, params[])
{
    new query[80], name[25];
    if(sscanf(params, "s[25]", name)) return SCM(playerid, red, "Player's logs: /logs <PlayerName>");
    if(!AccountExists(name)) return SCM(playerid, red, "Account is not exist");

    mysql_format(mysql, query, sizeof(query), "DELETE FROM `PlayerLogs` WHERE `PlayerName` = '%e'", name);
    mysql_tquery(mysql, query);

    format(query, 80, "You have deleted %s logs", name);
    SCM(playerid, red, query);
    return 1;
}

CMD:move(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(Info[playerid][Move] == 0)
        {
            TogglePlayerControllable(playerid, false);
            SetCameraBehindPlayer(playerid);
            Info[playerid][Move] = 1;
            SendClientMessage(playerid, green, "Move system turned on");
            SendClientMessage(playerid, green, "Use UP/DOWN keys to move forward/backward, LEFT/RIGHT key to trun left/right and sprint/jump keys to move UP/DOWN");
        }
        else
        {
            TogglePlayerControllable(playerid,true);
            SetCameraBehindPlayer(playerid);
            Info[playerid][Move] = 0;
            SendClientMessage(playerid, green, "Move system turned off");
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:destroycar(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, red, "You are not inside any vehicle");
        foreach(new x : Player)
        {
            foreach(new i : PrivateVehicles[x]) 
            if(IsPlayerInVehicle(playerid, vInfo[i][vehSessionID])) return SCM(playerid, red, "You can't destroy this vehicle");
        }

        DestroyVehicle(GetPlayerVehicleID(playerid));
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:aka(playerid, params[])
{
    new id;
    if(sscanf(params, "u", id)) return SCM(playerid, red, "Get matched IPs: /aka <PlayerID>");
    if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");

    GetPlayerAKA(id, playerid);
    return 1;
}

CMD:time(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id;
        if(sscanf(params,"i", id)) return SendClientMessage(playerid, red, "Set time: /time <ID>");
        SetWorldTime(id);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:savedata(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        foreach(new i : Player)
        {
            SavePlayerData(i, 0, 1);
        }

        SCM(playerid, red, "Players data has been saved");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:yradio(playerid, params[])
{
	if(Info[playerid][Level] >= 2)
    {
		if(isnull(params)) return SendClientMessage(playerid, red, "Youtube radio: /yradio <URL>");
		format(params, 145, "http://www.youtubeinmp3.com/fetch/?video=%s", params);
		foreach(new i : Player) PlayAudioStreamForPlayer(i, params);
		return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:stopyradio(playerid, params[])
{
	if(Info[playerid][Level] >= 2)
    {
    	foreach(new i : Player) StopAudioStreamForPlayer(i);
    	SCM(playerid, red, "You have stopped the youtube radio for everyone");
    	return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:spos(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(GetPlayerState(playerid) != 1 && GetPlayerState(playerid) != 2 && GetPlayerState(playerid) != 3 && GetPlayerState(playerid) != 7)
        return SendClientMessage(playerid, red, "You can't use this command right now");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        SetPVarFloat(playerid, "X", x);
        SetPVarFloat(playerid, "Y", y);
        SetPVarFloat(playerid, "Z", z);
        SetPVarInt(playerid, "Int", GetPlayerInterior(playerid));
        SetPVarInt(playerid, "Vir", GetPlayerVirtualWorld(playerid));
        SendClientMessage(playerid, green, "You have saved your position, use /lpos to load it");
        PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
        if(Possaved[playerid] == 0)
        {
            Possaved[playerid] = 1;
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:lpos(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(GetPlayerState(playerid) != 1 && GetPlayerState(playerid) != 2 && GetPlayerState(playerid) != 3 && GetPlayerState(playerid) != 7) 
        return SCM(playerid, red, "You can't use this command right now");
        if(Possaved[playerid] == 1)
        {
            if(!IsPlayerInAnyVehicle(playerid))
            {
                SetPlayerInterior(playerid, GetPVarInt(playerid, "Int"));
                SetPlayerVirtualWorld(playerid, GetPVarInt(playerid, "Vir"));
                SetPlayerPos(playerid, GetPVarFloat(playerid,"X"), GetPVarFloat(playerid,"Y"), GetPVarFloat(playerid,"Z"));
            }
            else if(IsPlayerInAnyVehicle(playerid))
            {
                LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPVarInt(playerid, "Int"));
                SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPVarInt(playerid, "Vir"));
                SetVehiclePos(GetPlayerVehicleID(playerid), GetPVarFloat(playerid,"X"), GetPVarFloat(playerid,"Y"), GetPVarFloat(playerid,"Z"));
            }
            SCM(playerid, green,  "You have loaded your last position");
            PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
            return 1;
        }
        else return SCM(playerid, red, "You don't have any saved positions");
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:readcmd(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(Info[playerid][ReadCMD] == false)
        {
            Info[playerid][ReadCMD] = true;
            SCM(playerid, red, "You have enabled reading commands");
        }
        else if(Info[playerid][ReadCMD] == true)
        {
            Info[playerid][ReadCMD] = false;
            SCM(playerid, red, "You have disabled reading commands");
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:acr(playerid,params[]) 
{
    if(Info[playerid][Level] >= 2)
    {
        new id, res[80], string[128];
        if(sscanf(params,"uS()[80]",id, res)) return SCM(playerid,red,"Accept report: /accept <PlayerID> <Text>");
        if(!IsPlayerConnected(id)) return SCM(playerid,red,"Player not connected");
        if(CreatedReport[id] != 1) return SCM(playerid,red,"This player havent made any reports");
       
        CreatedReport[id] = 0;
     
        if(isnull(res))
        format(string, sizeof(string), "%s %s has accepted your report: %s", GetLevel(playerid), GetName(playerid), res);
        else format(string, sizeof(string), "%s %s has accepted your report", GetLevel(playerid), GetName(playerid));
        SCM(id, red, string);

        format(string, sizeof(string),"You have accepted %s report",GetName(id));
        SCM(playerid,red,string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:accept(playerid, params[]) return cmd_acr(playerid, params);
 
CMD:rejr(playerid,params[]) 
{
    if(Info[playerid][Level] >= 2)
    {
        new id, res[80], string[128];
        if(sscanf(params,"uS()[80]",id, res)) return SCM(playerid,red,"Reject report: /reject <PlayerID> <Text>");
        if(!IsPlayerConnected(id)) return SCM(playerid,red,"Player not connected");
        if(CreatedReport[id] != 1) return SCM(playerid,red,"This player havent made any reports");
       
        CreatedReport[id] = 0;

        if(isnull(res))
        format(string, sizeof(string), "%s %s has rejected your report: %s", GetLevel(playerid), GetName(playerid), res);
        else format(string, sizeof(string), "%s %s has rejected your report", GetLevel(playerid), GetName(playerid));
        SCM(id, red, string);
       
        format(string, sizeof(string),"You have rejected %s report",GetName(id));
        SCM(playerid,red,string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:reject(playerid, params[]) return cmd_rejr(playerid, params);

CMD:movev(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new Float:x, Float:y, Float:z;
        new vehicleid = GetClosestVehicle(playerid);
        GetPlayerPos(playerid, x, y, z);
        GetVehiclePos(vehicleid, x, y, z);
        if(IsPlayerInRangeOfPoint(playerid, 15.0, x, y, z))
        {
            SetVehiclePos(vehicleid, x+3, y, z);
            return 1;
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:h(playerid, params[])
{
    if(Info[playerid][Level] >= 1)
    {
        new id, message[84], string[128];
        if(sscanf(params, "us[84]", id, message)) return SCM(playerid, red, "Help player: /h <ID> <Message>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(playerid == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");
        if(playerid == id) return SCM(playerid, red, "Invalid player ID");

        format(string, sizeof(string), "%s (%d): {00FF00}%s: {FFFFFF}%s",GetName(playerid), playerid, GetName(id), message);
        SendClientMessageToAll(GetPlayerColor(playerid), string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:goto(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id,Float:Pos[3],string[128];
        if(sscanf(params, "u", id)) return SCM(playerid, red, "Teleport to player: /goto <PlayerID>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(id == playerid) return SCM(playerid, red, "You can't teleport to yourself");

        GetPlayerPos(id,Pos[0],Pos[1],Pos[2]);
        SetPlayerInterior(playerid,GetPlayerInterior(id));
        SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(id));
        if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            SetVehiclePos(GetPlayerVehicleID(playerid),Pos[0]+3,Pos[1],Pos[2]);
            LinkVehicleToInterior(GetPlayerVehicleID(playerid),GetPlayerInterior(id));
            SetVehicleVirtualWorld(GetPlayerVehicleID(playerid),GetPlayerVirtualWorld(id));
        }
        else SetPlayerPos(playerid,Pos[0]+3,Pos[1],Pos[2]);
        format(string, sizeof(string),"You have teleported to %s", GetName(id));
        SCM(playerid,red,string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:get(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id,string[128];
        if(sscanf(params, "u",id)) return SCM(playerid, red, "Teleport player to you: /get <PlayerID>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(id == playerid) return SCM(playerid, red, "You can't teleport to yourself");

        if(Info[playerid][Level] < Info[id][Level]) return ShowMessage(playerid, red, 6);
        new Float:Pos[3];
        GetPlayerPos(playerid,Pos[0],Pos[1],Pos[2]);
        SetPlayerInterior(id,GetPlayerInterior(playerid));
        SetPlayerVirtualWorld(id,GetPlayerVirtualWorld(playerid));
        if(GetPlayerState(id) == PLAYER_STATE_DRIVER)
        {
            new Veh = GetPlayerVehicleID(id);
            SetVehiclePos(Veh,Pos[0]+2,Pos[1],Pos[2]);
            LinkVehicleToInterior(Veh,GetPlayerInterior(playerid));
            SetVehicleVirtualWorld(Veh,GetPlayerVirtualWorld(playerid));
        }
        else SetPlayerPos(id, Pos[0]+2, Pos[1], Pos[2]+5);
        format(string,sizeof(string),"You have teleported %s to your position", GetName(id));
        return SCM(playerid,NOTIF,string);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:clearchat(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        for(new i; i < 90; i++) SendClientMessageToAll(red," ");

        new string[128];
        if(isnull(params)) format(string, sizeof(string),"%s %s has cleared the main chat",GetLevel(playerid),GetName(playerid));
        else format(string, sizeof(string), "%s %s has cleared the main chat: %s",GetLevel(playerid),GetName(playerid), params);

        SendClientMessageToAll(red, string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:cc(playerid, params[]) return cmd_clearchat(playerid, params);

CMD:mute(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id, reason[50], time, string[128];
        if(sscanf(params, "udS()[50]", id, time, reason)) return SCM(playerid, red, "Mute player: /mute <PlayerID> <Minutes> <Reason>");
        if(IsPlayerConnected(id))
        {
            if(Info[playerid][Level] < Info[id][Level]) return ShowMessage(playerid, red, 6);
            if(!isnull(reason))
            format(string,sizeof(string),"%s %s muted %s for %d minutes: %s",GetLevel(playerid), GetName(playerid), GetName(id), time, reason);
            else format(string,sizeof(string),"%s %s muted %s for %d minutes",GetLevel(playerid),GetName(playerid),GetName(id), time);
            SendClientMessageToAll(red,string);
            Info[id][Muted] = 1;
            MuteCounter[id] = time * 60;
            MuteTimer[id] = SetTimerEx("UnmutePlayer", MuteCounter[id]*1000, true, "i", id);
            return 1;
        }
        else return SCM(playerid, red, "Player not connected");
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:lang(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id, time, string[128];
        if(sscanf(params, "ui", id, time)) return SCM(playerid, red, "Another lang mute: /lang <PlayerID> <Minutes>");
        if(IsPlayerConnected(id))
        {
            format(string,sizeof(string),"%s %s muted %s for %d minutes: You are allowed to speak only english",GetLevel(playerid),GetName(playerid),GetName(id), time);
            SendClientMessageToAll(red,string);

            Info[id][Muted] = 1;
            MuteCounter[id] = time * 60;
            MuteTimer[id] = SetTimerEx("UnmutePlayer", MuteCounter[id]*1000, true, "i", id);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:unmute(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id, reason[50], string[128];
        if(sscanf(params, "uS()[50]", id, reason))  return SCM(playerid, red, "Unmute player: /unmute <PlayerID> <Reason>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player");
        if(Info[id][Muted] == 0) return SCM(playerid,red,"This player is not muted");

        if(!isnull(reason))
        format(string,sizeof(string),"You have been unmuted by %s %s for: %s",GetLevel(playerid),GetName(playerid),reason);
        else format(string,sizeof(string),"You have been unmuted by %s %s",GetLevel(playerid),GetName(playerid));
        SCM(id,red,string);

        format(string,sizeof(string),"You have unmuted %s",GetName(id));
        SCM(playerid,red,string);

        Info[id][Muted] = 0;
        MuteCounter[id] = 0;
        KillTimer(MuteTimer[playerid]);
        return 1;
    }
    else return ShowMessage(playerid, red, 2);
}

CMD:slap(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id, height, Float:x, Float:y, Float:z, string[128];
        if(sscanf(params, "ui", id, height)) return SCM(playerid, red, "Slap player: /slap <PlayerID> <Height>");
        if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");
        format(string,sizeof(string),"You have slapped %s (Height: %i)",GetName(id), height);
        SCM(playerid,red,string);
        GetPlayerPos(id, x, y, z);
        SetPlayerPos(id,x,y,z+height);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:asay(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new string[128];
        if(isnull(params)) return SCM(playerid,yellow,"Admin message: /asay <Text>");

        format(string, sizeof(string),"{FF0000}<!> {7575A3}%s %s: {FF5050}%s", GetLevel(playerid), GetName(playerid), params);
        SendClientMessageToAll(red, string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:duty(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(Info[playerid][Duty] == 0)
        {
            Info[playerid][Duty] = true;
            SCM(playerid,red,"You're invisible in the Administation List");
        }
        else
        {
            Info[playerid][Duty] = false;
            SCM(playerid,red,"You're visible in the Administation List");
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:cal(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new Num1,Num2,mark[10], string[128];
        if(sscanf(params, "is[10]i",Num1,mark,Num2)) return SCM(playerid, red, "Calculate: /cal <Number 1> <*|/|+|-> <Number 2>");
        if(strcmp(mark,"*",true) == 0)
        {
            format(string, sizeof(string), "[ANSWER] %d X %d = %d", Num1, Num2, Num1*Num2);
            SCM(playerid, lighterblue, string);
        }
        else if(strcmp(mark,"/",true) == 0)
        {
            format(string, sizeof(string), "[ANSWER] %d / %d = %0.2f", Num1, Num2, Float:Num1/Float:Num2);
            SCM(playerid, lighterblue, string);
        }
        else if(strcmp(mark,"+",true) == 0)
        {
            format(string, sizeof(string), "[ANSWER] %d + %d = %d", Num1, Num2, Num1+Num2);
            SCM(playerid, lighterblue, string);
        }
        else if(strcmp(mark,"-",true) == 0)
        {
            format(string, sizeof(string), "[ANSWER] %d - %d = %d", Num1, Num2, Num1-Num2);
            SCM(playerid, lighterblue, string);
        }
        else return SCM(playerid, red, "Calculate: /cal <Number 1> <*|/|+|-> <Number 2>");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:cvote(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new str[128], res[50];
        if(!IsPlayerAdmin(playerid)) return SCM(playerid, red, "You're not allowed to use this command");
        if(sscanf(params, "S()[50]", res)) return SCM(playerid, red, "Cancel vote: /cvote <Reason>");
        if(OnVote == 0) return SCM(playerid, red, "There is no vote currently");

        if(!isnull(res))
        format(str, sizeof(str), "Administrator %s has canceled the vote: %s", GetName(playerid), res);
        else format(str, sizeof(str), "Administrator %s has canceled the vote", GetName(playerid));
        SendClientMessageToAll(red, str);
        OnVote = 0;
        foreach(new i : Player) Voted[i] = -1;
        Voting[VoteY] = 0;
        Voting[VoteN] = 0;
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:votes(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new Players = 0;
        new string[500], str[128];
        if(!IsPlayerAdmin(playerid)) return SCM(playerid, red, "You're not allowed to use this command");
        new vote_res[][] = {"No", "Yes"};
        string = "{FFFFFF}";

        foreach(new i : Player)
        {
            if (Voted[i] != -1)
            {
                format(str, 128, "{FFFFFF}%s - {00FF00}%s\n", GetName(i), vote_res[Voted[i]]);
                strcat(string, str, sizeof(string));
                Players++;
            }
        }
        if(Players == 0)
        ShowPlayerDialog(playerid, 135,DIALOG_STYLE_MSGBOX,"Note","{FF0000}No one has voted" ,"Close","");
        if(OnVote == 0)
        ShowPlayerDialog(playerid, 136,DIALOG_STYLE_MSGBOX,"Note","{FF0000}There is no vote currently" ,"Close","");
        else ShowPlayerDialog(playerid,165,DIALOG_STYLE_LIST,"Players Votes",string,"Close","");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:kick(playerid, params[], help)
{
    if(Info[playerid][Level] >= 2)
    {
        new id, reason[50],string[128];
        if(sscanf(params, "uS()[50]", id, reason)) return SCM(playerid, red, "Kick player: /kick <PlayerID> <Reason>");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player id");

        if(Info[playerid][Level] <= Info[id][Level]) return ShowMessage(playerid, red, 6);
        if(!isnull(reason))
        format(string,sizeof(string),"%s %s has kicked %s: %s",GetLevel(playerid),GetName(playerid),GetName(id),reason);
        else format(string,sizeof(string),"%s %s has kicked %s",GetLevel(playerid),GetName(playerid),GetName(id));
        SendClientMessageToAll(red,string);
        return DelayKick(id);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:clearplayerchat(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id, string[128];
        if(sscanf(params, "u", id)) return SCM(playerid, yellow, "Clear player's chat: /claerplayerchat <PlayerID>");
        for(new i = 0; i < 150; i++)
        SCM(id,red, " ");
        format(string,sizeof(string),"You have cleared %s's chat",GetName(id));
        SCM(playerid,red,string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:cpc(playerid, params[]) return cmd_clearplayerchat(playerid, params);

CMD:warp(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id,id2,string[128];
        if(sscanf(params, "uu",id,id2)) return SCM(playerid, red, "Teleport player to player: /Warp <PlayerID> <PlayerID>");
        if(IsPlayerConnected(id) && IsPlayerConnected(id2))
        {
            if(Info[playerid][Level] < Info[id][Level]) return ShowMessage(playerid, red, 6);

            new Float:Pos[3];
            GetPlayerPos(id2,Pos[0],Pos[1],Pos[2]);
            SetPlayerInterior(id,GetPlayerInterior(id2));
            SetPlayerVirtualWorld(id,GetPlayerVirtualWorld(id2));

            if(GetPlayerState(id) == PLAYER_STATE_DRIVER)
            {
                new Veh = GetPlayerVehicleID(id);
                SetVehiclePos(Veh,Pos[0]+3,Pos[1],Pos[2]);
                LinkVehicleToInterior(Veh,GetPlayerInterior(id2));
                SetVehicleVirtualWorld(Veh,GetPlayerVirtualWorld(id2));
            }
            else SetPlayerPos(id,Pos[0]+3,Pos[1],Pos[2]);

            format(string,sizeof(string),"%s %s has teleported you to %s",GetLevel(playerid), GetName(playerid),GetName(id2));
            SCM(id,NOTIF,string);

            format(string,sizeof(string),"You have teleported %s to %s's Position", GetName(id), GetName(id2));
            return SCM(playerid,NOTIF,string);
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:hidename(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        if(Info[playerid][NameTagHidden] == 0)
        {
            SCM(playerid, orange, "You have enabled name tag hide");
            Info[playerid][NameTagHidden] = 1;
            foreach(new i : Player) ShowPlayerNameTagForPlayer(i, playerid, false);
        }
        else if(Info[playerid][NameTagHidden] == 1)
        {
            SCM(playerid, orange, "You have disabled name tag hide");
            Info[playerid][NameTagHidden] = 0;
            foreach(new i : Player) ShowPlayerNameTagForPlayer(i, playerid, true);
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:spec(playerid, params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id;
        if(sscanf(params, "u", id)) return SCM(playerid, red, "Spectate player: /Spec <PlayerID>");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Player is not connected");
        if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) return SCM(playerid, red, "You are already spectating");
       
        GetPlayerSpawnEx(playerid);
        Info[playerid][Spec] = 1;
        SpecID[playerid] = id;

        OldSkin[playerid] = GetPlayerSkin(playerid);
        SetPlayerInterior(playerid, GetPlayerInterior(id));
        SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
        TogglePlayerSpectating(playerid, 1);
 
        if (IsPlayerInAnyVehicle(id)) PlayerSpectateVehicle(playerid, GetPlayerVehicleID(id));
        else PlayerSpectatePlayer(playerid, id);

        SpecTimer[playerid] = SetTimerEx("SpecPlayer", 100, true, "i", playerid);
        return SCM(playerid,red,"You are spectating");
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:specoff(playerid, params[])
{
   if(Info[playerid][Level] >= 2)
   {
        if(Info[playerid][Spec] >= 1 || GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
        {
            KillTimer(SpecTimer[playerid]);
            PlayerTextDrawHide(playerid, SpectateTextDraw[playerid]);
            TogglePlayerSpectating(playerid, 0);
            return 1;
        }
        else return SCM(playerid,red,"You are not spectating");
   }
   else return ShowMessage(playerid, red, 1);
}

/*============================================================================*/
/*-------------------------------Level 3--------------------------------------*/
/*============================================================================*/

CMD:weapontp(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(Info[playerid][WeaponTeleport] == 0)
        {
            Info[playerid][WeaponTeleport] = 1;
            SCM(playerid, green, "You have enabled weapon teleport");
        }
        else
        {
            Info[playerid][WeaponTeleport] = 0;
            SCM(playerid, green, "You have disabled weapon teleport");
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:spawncar(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new veh[30],vehid;
        if(sscanf(params, "s[30]", veh)) return SCM(playerid, red, "Spawn a vehicle: /spawncar <Model ID/Vehicle Name>");
        if(IsNumeric(veh)) vehid = strval(veh);
        else vehid = ReturnVehicleModelID(veh);
        if(vehid < 400 || vehid > 611) return SCM(playerid, red, "Invalid vehicle model!");
        SpawnVehicle(playerid, vehid);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:jail(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, time = 0, reason[50], string[128];
        if(sscanf(params, "uiS()[50]", id, time, reason)) return SCM(playerid, red, "Jail player: /Jail <PlayerID> <Minutes> <Reason>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(Info[id][Jailed] == 1) return SCM(playerid,red,"This player is already jailed. see /jailed");
        if(!isnull(reason) && time == 0)
        format(string,sizeof(string),"%s %s has jailed player %s: %s",GetLevel(playerid),GetName(playerid),GetName(id),reason);
        else if(!isnull(reason) && time >= 1) format(string, sizeof(string),"%s %s has jailed you for %d minutes: %s",GetLevel(playerid),GetName(playerid), time, reason);
        else if(isnull(reason) && time >= 1) format(string, sizeof(string),"%s %s has jailed you for %d minutes",GetLevel(playerid),GetName(playerid), time);
        else format(string,sizeof(string),"%s %s has jailed you",GetLevel(playerid),GetName(playerid));
        SCM(id,red,string);
        Info[id][Jailed] = 1;
        JPlayer[id] = SetTimerEx("JailPlayer", 3000, false, "u", id);
        if(GetPlayerState(id) == PLAYER_STATE_ONFOOT) SetPlayerSpecialAction(id,SPECIAL_ACTION_HANDSUP);
        if(time >= 1) JTimer[id] = SetTimerEx("Unjail",time*1000*60,0,"u",id);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:unjail(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, reason[50], string[128];
        if(isnull(params)) return SCM(playerid, red, "Unjail player: /unjail <PlayerID> <Reason>");
        sscanf(params, "uS()[50]", id, reason);
        if(IsPlayerConnected(id))
        {
            if(Info[id][Jailed] == 0) return SCM(playerid,red,"This player is not jailed");
            if(!isnull(reason))
            format(string,sizeof(string),"You have been unjailed by %s %s: %s",GetLevel(playerid),GetName(playerid),reason);
            else format(string,sizeof(string),"You have been unjailed by %s %s",GetLevel(playerid),GetName(playerid));
            SCM(id,NOTIF,string);
            format(string,sizeof(string),"You have unjailed %s",GetName(id));
            SCM(playerid,red,string);
            Info[id][Jailed] = 0;
            TogglePlayerControllable(id, true);
            SetSpawnInfo(playerid, NO_TEAM, GetPlayerSkin(playerid), 2229.6204, -1366.4111, 23.9922, 88.1277, 0, 0, 0, 0, 0, 0);
            KillTimer(JTimer[id]);
            PlayerTextDrawDestroy(id, TimeLeft[id]);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:carcolor(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,color1,color2,string[128];
        if(sscanf(params, "uii", id,color1,color2))return SCM(playerid, red, "Change vehicle color: /carcolor <PlayerID> <Colour1> <Colour2>");
        if(IsPlayerConnected(id))
        {
            if(IsPlayerInAnyVehicle(id))
            {
                format(string, sizeof(string), "You have Changed %s vehicle's colour to %d,%d", GetName(id),  color1, color2);
                SCM(playerid,red,string);
                format(string,sizeof(string),"%s %s has changed your vehicle colour to %d,%d", GetLevel(playerid), GetName(playerid),color1, color2 );
                SCM(id,NOTIF,string);
                return ChangeVehicleColor(GetPlayerVehicleID(id), color1, color2);
            }
            else return ShowMessage(playerid, red, 5);
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:destroycars(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        for(new i=0; i<Info[playerid][SpawnedCars]; i++)
        {
            DestroyVehicle(Info[playerid][Cars][i]);
        }
        Info[playerid][SpawnedCars] = 0;
        SCM(playerid,red,"You have deleted all cars that you spawned");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:fakecmd(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, string[18];
        if(sscanf(params, "us[18]", id, string)) return SCM(playerid, red, "Fake command: /fakecmd <PlayerID> <Chat Message>");
        if(Info[playerid][Level] < Info[id][Level]) return ShowMessage(playerid, red, 6);
        if(IsPlayerConnected(id))
        {
            if(!strcmp(string, "/", .length = 1))
            {
                CallRemoteFunction("OnPlayerCommandText", "is", id, string);
                return SCM(playerid,red,"Fake command has been message sent");
            }
            else return SCM(playerid,red,"The command must include the ' / '");
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:write(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new string[128];
        if(sscanf(params, "s[128]",string)) return SCM(playerid, red, "Write Message: /write <Message>");
        SetPVarString(playerid,"SpamMsg",string);
        ShowPlayerDialog(playerid, DIALOGS+65, DIALOG_STYLE_LIST, "Select Message Color","Yellow\nWhite\nBlue\nRed\nGreen\nOrange\nPurple\nPink\nBrown\nBlack" , "Select", "Close");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:heal(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,string[128];
        sscanf(params, "u", id);
        if (isnull(params))
        {
            SetPlayerHealthEx(playerid,100);
            SCM(playerid, red,"You have healed yourself, also you can /heal <PlayerID>");
            return 1;
        }
        else if(IsPlayerConnected(id))
        {
            SetPlayerHealthEx(id,100);
            format(string,sizeof(string),"%s %s has healed you",GetLevel(playerid),GetName(playerid));
            SCM(id,NOTIF,string);
            format(string,sizeof(string),"You have healed %s", GetName(id));
            return SCM(playerid, red,string);
        }
        return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:armour(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,string[128];
        sscanf(params, "u", id);
        if (isnull(params))
        {
            SetPlayerArmourEx(playerid,100);
            SCM(playerid, red,"You have armoured yourself. also you can /armour <PlayerID>");
            return 1;
        }
        else if(IsPlayerConnected(id))
        {
            SetPlayerArmourEx(id,100);
            format(string,sizeof(string),"%s %s has armoured you",GetLevel(playerid),GetName(playerid));
            SCM(id,NOTIF,string);
            format(string,sizeof(string),"You have armoured %s", GetName(id));
            return SCM(playerid, red,string);
        }
        return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setarmour(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui",id,amount)) return SCM(playerid, yellow, "Set armour for player: /Setarmour <PlayerID> <Amount> (1-100)!");
        if(IsPlayerConnected(id))
        {
            if(amount < 0 ) return SCM(playerid, red, "Invalid amount");
            format(string, sizeof(string), "You have set %s's armour to %d", GetName(id), amount);
            SCM(playerid,red,string);
            format(string,sizeof(string),"%s %s has set your armour to %d",GetLevel(playerid), GetName(playerid), amount);
            SCM(id,NOTIF,string);
            SetPlayerArmourEx(id, amount);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:sethealth(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui",id,amount)) return SCM(playerid, yellow, "Set HP for player: /Sethealth <PlayerID> <Amount> (1-100)!");
        if(IsPlayerConnected(id))
        {
            if(amount < 0 ) return SCM(playerid, red, "Invalid amount!");
            format(string, sizeof(string), "You have set %s's health to %d", GetName(id), amount);
            SCM(playerid,red,string);
            format(string,sizeof(string),"%s %s has set your health to %d",GetLevel(playerid), GetName(playerid), amount);
            SCM(id,NOTIF,string);
            SetPlayerHealthEx(id, amount);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:ban(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new target, reason[35], days, string[128];
        if(sscanf(params, "uiS()[35]", target, days, reason)) return SCM(playerid, red, "Ban player: /ban <PlayerID> <Days(0 Permanent)> <Reason>");
        if(!IsPlayerConnected(target)) return SCM(playerid, red, "Player is not connected");
        if(days < 0) return SCM(playerid, red, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban");
        if(Info[playerid][Level] < Info[target][Level]) return ShowMessage(playerid, red, 6);

        new bandate[18], date[3], time;
        getdate(date[0], date[1], date[2]);
        format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

        if(days == 0) time = 0;
        else time = days*86400;

        new playerIP[16];
        GetPlayerIp(target, playerIP, sizeof(playerIP));

        new query[220];
        if(days == 0)
        {
            mysql_format(mysql, query, sizeof(query), "INSERT INTO `BannedPlayers` (PlayerName, BannedBy, BanReason, BanOn, BanExpire, IP) \
            VALUES ('%e', '%e', '%e', '%e', 0, '%e')", GetName(target), GetName(playerid), reason, bandate, playerIP);
            mysql_tquery(mysql, query);

            if(!isnull(reason)) format(string, sizeof(string), "%s %s has banned %s: %s", GetLevel(playerid), GetName(playerid), GetName(target));
            else format(string, sizeof(string), "%s %s has banned %s", GetLevel(playerid), GetName(playerid), GetName(target));
        }
        else
        {
            mysql_format(mysql, query, sizeof(query), "INSERT INTO `BannedPlayers` (PlayerName, BannedBy, BanReason, BanOn, BanExpire, IP) \
            VALUES ('%e', '%e', '%e', '%e', UNIX_TIMESTAMP() + %i, '%e')", GetName(target), GetName(playerid), reason, bandate, time, playerIP);
            mysql_tquery(mysql, query);

            if(!isnull(reason)) format(string, sizeof(string), "%s %s has banned %s for %i days: %s", GetLevel(playerid), GetName(playerid), GetName(target), days, reason);
            else format(string, sizeof(string), "%s %s has banned %s for %i days", GetLevel(playerid), GetName(playerid), GetName(target), days);
        }

        SendClientMessageToAll(red, string);
        DelayKick(target);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:oban(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new name[MAX_PLAYER_NAME], reason[35], days, string[128];
        if(sscanf(params, "s[24]is[35]", name, days, reason)) return SCM(playerid, red, "Ban player (Offline): /oban <PlayerName> <Days(0 Permanent)> <Reason>");
        if(!strcmp(name, GetName(playerid))) return SCM(playerid, red, "You can't ban yourself");
        foreach(new i : Player)
        {
            if(!strcmp(name, GetName(i), false))
            {
                return SCM(playerid, red, "The specified username is online");
            }
        }

        if(days < 0) return SCM(playerid, red, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban");
        if(strlen(reason) < 3 || strlen(reason) > 35) return SCM(playerid, red, "Invalid reason length, must be b/w 0-35 characters");
        if(!AccountExists(name)) return SCM(playerid, red, "Account does not exist");

        new bandate[18], date[3], time;
        getdate(date[0], date[1], date[2]);
        format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

        if(days == 0) time = 0;
        else time = days*86400;

        mysql_format(mysql, string, sizeof(string), "SELECT `IP` FROM `playersdata` WHERE `PlayerName` = '%e'", name);
        mysql_tquery(mysql, string, "OnOfflineBan", "sissi", name, playerid, reason, bandate, time);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

function OnOfflineBan(name[], playerid, reason[], bandate[], time)
{
    new playerIP[16], query[320];
    cache_get_field_content(0, "IP", playerIP);

    if(time == 0)
    {
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `BannedPlayers` (PlayerName, BannedBy, BanReason, BanOn, BanExpire, IP) \
        VALUES ('%e', '%e', '%e', '%e', 0, '%e')", name, GetName(playerid), reason, bandate, playerIP);
        mysql_tquery(mysql, query);

        format(query, sizeof(query), "You have successfully banned %s: %s [PREMANENT]", name, reason);
        SCM(playerid, green, query);
    }
    else
    {
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `BannedPlayers` (PlayerName, BannedBy, BanReason, BanOn, BanExpire, IP) \
        VALUES ('%e', '%e', '%e', '%e', UNIX_TIMESTAMP() + %i, '%e')", name, GetName(playerid), reason, bandate, time, playerIP);
        mysql_tquery(mysql, query);

        format(query, sizeof(query), "You have successfully banned %s: %s", name, reason);
        SCM(playerid, green, query);
    }
    return 1;
}

CMD:unban(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new name[24], query[100];
        if(sscanf(params,"s[24]", name)) return SCM(playerid, red, "Un-ban player: /unban <PlayerName>");

        mysql_format(mysql, query, sizeof(query), "DELETE FROM `BannedPlayers` WHERE `PlayerName` = '%e'", name);
        mysql_tquery(mysql, query);

        format(query, sizeof(query), "You have successfully unbanned %s", name);
        SCM(playerid, green, query);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:bans(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {  
        mysql_tquery(mysql, "SELECT * FROM `BannedPlayers`", "OnBanLoad", "i", playerid);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:bplayers(playerid, params[]) return cmd_bans(playerid, params);

CMD:ctag(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, str1[128], str2[128], text[50];
        if(sscanf(params, "us[50]", id, text)) return SCM(playerid, red, "Change player tag: /ctag <PlayerID> <Text>");
        if(!IsPlayerConnected(playerid)) return SCM(playerid, red, "Player is not connected");
        if(Info[id][Premium] != 1) return SCM(playerid, red, "Player is not premium");

        format(str1, sizeof(str1), "You have changed %s's tag to: %s", GetName(id), text);
        format(str2, sizeof(str2), "%s %s has changed your tag to: %s", GetLevel(playerid), GetName(playerid), text);
        SCM(playerid, red, str1);
        SCM(id, red, str2);
        UpdateDynamic3DTextLabelText(PlayerTag[id], 0x00FF00FF, text);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:cteam(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, tid,string[128];
        if(sscanf(params, "ui", id, tid)) return SCM(playerid, red, "Change player team: /cteam <PlayerID> <1-2>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(InEvent[id] == 0) return SCM(playerid, red, "Player is not in event");
        switch(tid)
        {
            case 1:
            {
                SetPlayerTeam(id, TEAM_ONE);
                format(string, sizeof(string), "You have changed %s's team to team 1");
                format(string, sizeof(string), "%s %s has set you team 1", GetLevel(playerid), GetName(playerid));
                SCM(playerid, red, string);
                SCM(id, NOTIF, string);
            }
            case 2:
            {
                SetPlayerTeam(id, TEAM_TWO);
                format(string, sizeof(string), "You have changed %s's team to team 2");
                format(string, sizeof(string), "%s %s has set you team 2", GetLevel(playerid), GetName(playerid));
                SCM(playerid, NOTIF, string);
                SCM(id, NOTIF, string);
            }
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:int(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new string[128], tmp;
        if(sscanf(params,"i", tmp)) return SCM(playerid,red,"Teleport to Interior: /int <ID>");
        if(tmp > 146 || tmp < 0) return SCM(playerid, red, "Invalid interior ID");

        if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            LinkVehicleToInterior(GetPlayerVehicleID(playerid), IntArray2[tmp][0]);
            SetVehiclePos(GetPlayerVehicleID(playerid), IntArray[tmp][0], IntArray[tmp][1], IntArray[tmp][2]);
            SetVehicleZAngle(GetPlayerVehicleID(playerid), IntArray[tmp][3]);
            PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
        }
        SetPlayerInterior(playerid, IntArray2[tmp][0]);
        SetPlayerPos(playerid, IntArray[tmp][0], IntArray[tmp][1], IntArray[tmp][2]);
        SetPlayerFacingAngle(playerid, IntArray[tmp][3]);

        format(string, sizeof(string), "Interior %d: %s", tmp, IntName[tmp]);
        SCM(playerid, 0xBF4080FF, string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:bsys(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new string[600];
        strcat(string, "{00FF00}Ban Player IN-GAME:\n");
        strcat(string, "{FFFFFF}/hban, /ban, /permban\n\n");
        strcat(string, "{00FF00}Un-Ban Player:\n");
        strcat(string, "{FFFFFF}/unban\n\n");
        strcat(string, "{00FF00}Informations\n");
        strcat(string, "{FFFFFF}/bans\n\n");
        ShowPlayerDialog(playerid, 4753, DIALOG_STYLE_MSGBOX, "Ban System - Commands", string, "Close", "");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:osys(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new string[800];
        strcat(string, "{00FF00}Creating/Editing Objects:\n");
        strcat(string, "{FFFFFF}/oadd, /oedit, /osel, /odel, /odelall, /ogoto, /oreplace\n\n");
        strcat(string, "{00FF00}Maps:\n");
        strcat(string, "{FFFFFF}/savemap, /loadmap, /delmap\n\n");
        strcat(string, "{00FF00}Movements:\n");
        strcat(string, "{FFFFFF}/omoveto, /omoveotop, /ostop\n\n");
        strcat(string, "{00FF00}Materials/Textures:\n");
        strcat(string, "{FFFFFF}/otextmat, /omat, /oclear, /textures\n\n");
        strcat(string, "{FF0000}NOTE! Before using /ocopy you have to select/edit the object first\n");
        strcat(string, "{FF0000}And make sure to recieve the message 'Saved'\n");
        ShowPlayerDialog(playerid, 4751, DIALOG_STYLE_MSGBOX, "Object System - Commands", string, "Close", "");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:esys(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new string[600];
        strcat(string, "{00FF00}Creating Event:\n");
        strcat(string, "{FFFFFF}/ctdm, /cdm\n\n");
        strcat(string, "{00FF00}Start/Stop Event:\n");
        strcat(string, "{FFFFFF}/startevent, /stopevent, /setewinner\n\n");
        ShowPlayerDialog(playerid, 4752, DIALOG_STYLE_MSGBOX, "Event System - Commands", string, "Close", "");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:loadmap(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new mapname[64];
        if (sscanf(params, "s[64]", mapname)) return SCM(playerid, red, "Load map: /loadmap <MapName>");
        if (!MapExists(mapname)) return SCM(playerid, red, "Map doesn't exists");

        for(new i; i < MAX_OBJECTS; i ++)
        {
            if(IsValidDynamicObject(objects[i]))
            {
                DestroyDynamicObject(objects[i]);
            }
        }

        new query[180];
        mysql_format(mysql, query, sizeof(query), "SELECT * FROM `Maps` WHERE `MapName` = '%e'", mapname);
        mysql_tquery(mysql, query, "OnMapsLoad", "i", playerid);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:deletemap(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new mapname[24];
        if (sscanf(params, "s[24]", mapname)) return SCM(playerid, red, "Delete map: /deletemap <MapName>");
        if (!MapExists(mapname)) return SCM(playerid, red, "Map doesn't exists");

        new query[140];
        mysql_format(mysql, query, sizeof(query), "DELETE FROM `Maps` WHERE `MapName` = '%e'", mapname);
        mysql_tquery(mysql, query);

        SCM(playerid, red, "Map has been destroyed");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:delmap(playerid, params[]) return cmd_deletemap(playerid, params);

CMD:savemap(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new mapname[64];
        if (sscanf(params, "s[64]", mapname)) return SCM(playerid, red, "Save map: /savemap <MapName>");
        
        if(MapExists(mapname))
        {
            new query[128];
            mysql_format(mysql, query, sizeof(query), "DELETE FROM `Maps` WHERE `MapName` = '%e'", mapname);
            mysql_tquery(mysql, query);
        }

        SaveMap(playerid, mapname);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:exportmap(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new string[184], mapname[35], handlename[35], totalobjects = 0;
        if(sscanf(params, "s[35]", mapname)) return SCM(playerid, red, "Export map: /exportmap <Map Name>");

        format(handlename, 35, "eFData/Maps/%s.txt", mapname);

        new File:handle = fopen(handlename, io_write);

        for(new i; i < MAX_OBJECTS; i ++)
        {
            if(IsValidDynamicObject(objects[i]))
            {
                new Float:x, Float:y, Float:z,
                    Float:rx, Float:ry, Float:rz;

                GetDynamicObjectPos(objects[i],x,y,z);
                GetDynamicObjectRot(objects[i],rx,ry,rz);

                if(handle)
                {
                    format(string, sizeof(string), "CreateDynamicObject(%i, %f, %f, %f, %f, %f, %f);\r\n", objectmodel[i], x, y, z, rx, ry, rz);     
                    fwrite(handle, string);
                }
                else return printf("Failed to open file - %s", handlename);
                totalobjects++;
            }
        }

        fclose(handle);

        if(totalobjects == 0) return SCM(playerid, red, "You must have atleast one object to save a map");

        format(msg, sizeof(msg),"Map has been exported as '%s'",mapname);
        SCM(playerid, green, msg);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:ogoto(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new slot;
        if (sscanf(params, "i", slot)) return SCM(playerid, red, "Teleport to object: /ogoto <Slot>");
        if(!IsValidDynamicObject(objects[slot])) return SCM(playerid, red, "There is nothing on this slot");

        new Float:X,Float:Y,Float:Z;
        GetDynamicObjectPos(objects[slot],X,Y,Z);
        SetPlayerPos(playerid, X,Y,Z+2);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:ostop(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new slot = GetPVarInt(playerid, "SelectedObject");
        if(slot == -1) return SCM(playerid, red, "You don't have any object selected, Use /osel first");

        SetPVarInt(playerid,"Modifying",1);
        CancelEdit(playerid);
        StopDynamicObject(objects[slot]);
        if(IsPlayerEdittingObject(playerid))
        EditDynamicObject(playerid,objects[slot]);
        UpdateObjectTextdraw(playerid, "Stopped");

        format(msg, sizeof(msg),"Object on slot %d has been stopped if it was moving",slot);
        SCM(playerid,green,msg);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:omovetop(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new Float:ospeed, targetid;
        if (sscanf(params, "uf", targetid,ospeed)) return SCM(playerid, red, "Move object to player: /omovetop <PlayerID> <Speed>");
        if(!IsPlayerConnected(targetid)) return SCM(playerid, red, "Player is not connected");

        new editting = GetPVarInt(playerid, "SelectedObject");
        if(editting == -1) return SCM(playerid, red, "You don't have any object selected, Use /osel first");

        SetPVarInt(playerid,"Modifying",1);
        CancelEdit(playerid);
        new Float:Float[9];
        GetPlayerPos(targetid,Float[0],Float[1],Float[2]);
        GetDynamicObjectPos(objects[editting],Float[3],Float[4],Float[5]);
        GetDynamicObjectRot(objects[editting],Float[6],Float[7],Float[8]);

        SetDynamicObjectRot(objects[editting],Float[6],Float[7],GetAngleToPoint(Float[3],Float[4],Float[0],Float[1]));
        MoveDynamicObject(objects[editting],Float[0],Float[1],Float[2],ospeed);
        UpdateObjectInfoTextdraws(playerid,objects[editting],editting);
        if(IsPlayerEdittingObject(playerid))
        EditDynamicObject(playerid,objects[editting]);
        UpdateObjectTextdraw(playerid, "Moved To Player");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:omoveto(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new Float:X,Float:Y,Float:Z,Float:ospeed;
        if (sscanf(params, "ffff",X,Y,Z,ospeed)) return SCM(playerid, red, "Move object: /omoveto <X> <Y> <Z> <Speed>");

        new editting = GetPVarInt(playerid, "SelectedObject");
        if(editting == -1) return SCM(playerid, red, "You're not editting any object");

        SetPVarInt(playerid,"Modifying",1);
        CancelEdit(playerid);
        MoveDynamicObject(objects[editting],X,Y,Z,ospeed);
        if(IsPlayerEdittingObject(playerid))
        EditDynamicObject(playerid,objects[editting]);
        UpdateObjectInfoTextdraws(playerid,objects[editting],editting);
        UpdateObjectTextdraw(playerid, "Moved");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:osave(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new slot = GetPVarInt(playerid, "SelectedObject");
        if(slot == -1) return SCM(playerid, red, "You don't have anything selected");

        format(msg, sizeof(msg),"You're no longer editting the object on slot %d",slot);
        SCM(playerid, green, msg);

        CancelEdit(playerid);
        DestroyObjectTextdraw(playerid);
        SetPVarInt(playerid, "SelectedObject",-1);
        UpdateObjectInfoTextdraws(playerid,objects[slot],slot);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}


CMD:oedit(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new slot;
        if(sscanf(params, "i", slot))
        {
            if(GetPVarInt(playerid, "SelectedObject") != -1)
            slot = GetPVarInt(playerid, "SelectedObject");
            else
            {
                SCM(playerid, red, "You're now on object selection mode");
                OnObjectEditMode(playerid,true);
                UpdateObjectTextdraw(playerid);
                return SelectObject(playerid);
            }
        }

        if(!IsValidDynamicObject(objects[slot])) return SCM(playerid, red, "There's no editable object on the slot you chosed");

        SetPVarInt(playerid, "SelectedObject",slot);
        format(msg, sizeof(msg),"You're now editting object slot %d",slot);
        SCM(playerid, green, msg);

        EditDynamicObject(playerid, objects[slot]);
        OnObjectEditMode(playerid,true);

        CreateObjectTextdraw(playerid);
        UpdateObjectTextdraw(playerid);
        ShowObjectTextdraw(playerid);
        SCM(playerid, red, "Use /osave to stop editting this object");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:omat(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new model,index,txd[24],txtna[24],hex;
        if(sscanf(params, "iis[24]s[24]H(0)", index,model,txd,txtna,hex)) return SCM(playerid, red, "Material object: /omat <Slot> <Model> <TXD Name> <Texture Name> <Color>");

        new editting = GetPVarInt(playerid, "SelectedObject");
        if(editting == -1) return SCM(playerid, red, "You're not editting any object");

        SetDynamicObjectMaterial(objects[editting],index,model,txd,txtna,hex);
        format(objectmatinfo[editting][index], 80,"%d %s %s %x",model,txd,txtna,hex);
        UpdateObjectInfoTextdraws(playerid,objects[editting],editting), MaterialApplied[playerid] = 1;
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:otextmat(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new txt[55], index, size, fontsize, bold, fontcolor, backcolor;
        if(sscanf(params, "iiiixxs[55]",index, size, fontsize, bold, fontcolor, backcolor, txt)) return
        SendClientMessage(playerid, red, "Set material: /otextmat <Slot> <Size> <Fontsize> <Bold(0-1)> <Font Color> <Background Color> <Text>");

        new editting = GetPVarInt(playerid, "SelectedObject");
        if(editting == -1) return SCM(playerid, red, "You're not editting any object");

        SetDynamicObjectMaterialText(objects[editting], index, txt, size, "Arial", fontsize, bold, fontcolor, backcolor, 0);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:oclear(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new index;
        if (sscanf(params, "i", index)) return SCM(playerid, red, "Clear material text: /oclear <Slot>");

        new editting = GetPVarInt(playerid, "SelectedObject");
        if(editting == -1) return SCM(playerid, red, "You're not editting any object");

        SetDynamicObjectMaterial(objects[editting],index,objectmodel[editting],"None","None",0);
        objectmatinfo[editting][index] = "None";
        UpdateObjectInfoTextdraws(playerid,objects[editting],editting);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:oreplace(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new model;
        if (sscanf(params, "i", model)) return SCM(playerid, red, "Replace object: /oreplace <Model>");

        new editting = GetPVarInt(playerid, "SelectedObject");
        if(editting == -1) return SCM(playerid, red, "You're not editting any object");

        new Float:X,Float:Y,Float:Z,Float:RX,Float:RY,Float:RZ;
        GetDynamicObjectPos(objects[editting],X,Y,Z);
        GetDynamicObjectRot(objects[editting],RX,RY,RZ);

        format(msg, sizeof(msg),"Object on slot %d replaced from model %d to model %d",editting,objectmodel[editting],model);
        SCM(playerid, green, msg);

        DestroyDynamicObject(objects[editting]);
        objects[editting] = CreateDynamicObject(model,X,Y,Z,RX,RY,RZ);
        objectmodel[editting] = model;
        ApplyDynamicObjectMaterial(objects[editting],editting,0);
        ApplyDynamicObjectMaterial(objects[editting],editting,1);
        ApplyDynamicObjectMaterial(objects[editting],editting,2);
        UpdateNearPlayers(playerid);
        UpdateObjectInfoTextdraws(playerid,objects[editting],editting);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:osel(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new slot;
        if (sscanf(params, "i", slot)) return SCM(playerid, red, "Select object: /osel <Slot>");

        if(!IsValidDynamicObject(objects[slot])) return SCM(playerid, red, "There's no object on the slot you selected");

        SetPVarInt(playerid, "SelectedObject",slot);
        format(msg, sizeof(msg),"Object slot %d has been selected",slot);
        SCM(playerid, green, msg);

        SCM(playerid, red, "Use /osave to unselect this object");
        UpdateObjectInfoTextdraws(playerid,objects[slot],slot);

        CreateObjectTextdraw(playerid);
        UpdateObjectTextdraw(playerid);
        ShowObjectTextdraw(playerid);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:ocopy(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new slot = -1;
        new selected = GetPVarInt(playerid, "SelectedObject");
        if(selected == -1) return SCM(playerid, red, "You don't have any object selected");

        if(!IsValidDynamicObject(objects[selected])) return SCM(playerid, red, "There is nothing on the slot you selected");

        SetPVarInt(playerid,"Modifying",1);
        cmd_osave(playerid, "");

        new Float:X,Float:Y,Float:Z,Float:RX,Float:RY,Float:RZ;
        GetDynamicObjectPos(objects[selected],X,Y,Z);
        GetDynamicObjectRot(objects[selected],RX,RY,RZ);

        for(new h = 0; h < MAX_OBJECTS; h++)
        {
            if(objects[h] == -1  && !IsValidDynamicObject(objects[h]))
            {
                slot = h;
                break;
            }
        }

        if(slot == -1) return SCM(playerid, red, "You have no more slots avaialble");
        objects[slot] = CreateDynamicObject(objectmodel[selected],X,Y,Z,RX,RY,RZ);
        objectmodel[slot] = objectmodel[selected];
        if(MaterialApplied[playerid] == 1)
        {
            objectmatinfo[slot][0] = objectmatinfo[selected][0];
            objectmatinfo[slot][1] = objectmatinfo[selected][1];
            objectmatinfo[slot][2] = objectmatinfo[selected][2];
            ApplyDynamicObjectMaterial(objects[slot],slot,0);
            ApplyDynamicObjectMaterial(objects[slot],slot,1);
            ApplyDynamicObjectMaterial(objects[slot],slot,2);
        }
        UpdateNearPlayers(playerid);

        format(msg, sizeof(msg),"Object ID %d copied on slot %d",selected,slot);
        SCM(playerid, green, msg);

        SCM(playerid, green, "Saved");
        cmd_oedit(playerid, "");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:oadd(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new idx,slot = -5;
        if (sscanf(params, "i", idx)) return SCM(playerid, red, "Create object: /oadd <Object>");

        new Float:X,Float:Y,Float:Z;
        GetPlayerPos(playerid, X,Y,Z);
        GetXYInFrontOfPlayer(playerid, X, Y, 2.0);

        for(new h; h < MAX_OBJECTS; h++)
        {
            if(objects[h] == -1 && !IsValidDynamicObject(objects[h]))
            {
                slot = h;
                break;
            }
        }

        if(slot == -5) return SCM(playerid, red, "You have no more slots available");

        objects[slot] = CreateDynamicObject(idx,X,Y,Z,0,0,0);
        objectmodel[slot] = idx;
        SetPVarInt(playerid,"Objects",GetPVarInt(playerid,"Objects") + 1);
        UpdateNearPlayers(playerid);

        format(msg, sizeof(msg),"Object ID %d created on slot %d",idx,slot);
        SCM(playerid, green, msg);

        format(msg, sizeof(msg),"%d",slot);
        cmd_oedit(playerid,msg);

        if(GetPVarInt(playerid,"NoObject"))
        DeletePVar(playerid, "NoObject");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:odelall(playerid,params[])
{
   if(Info[playerid][Level] >= 3)
    {
        if(!isnull(params)) return SCM(playerid, red, "Delete all objects: /odelall");

        MaterialApplied[playerid] = 0;

        for(new i = 0; i < MAX_OBJECTS; i ++)
        {
            DestroyDynamicObject(objects[i]);
            objects[i] = -1;
        }

        SetPVarInt(playerid,"SelectedObject",-1);
        SetPVarInt(playerid,"Objects",0);
        DestroyObjectTextdraw(playerid);

        if(IsPlayerEdittingObject(playerid))
        CancelEdit(playerid);

        OnObjectEditMode(playerid, false);
        SCM(playerid, red,"Every object that belonged to you has been deleted");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:odel(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(!isnull(params)) return SCM(playerid, red, "Delete object: /odel");

        MaterialApplied[playerid] = 0;

        new slot = GetPVarInt(playerid, "SelectedObject");
        if(slot == -1) return SCM(playerid, red, "You don't have any object selected");

        DestroyDynamicObject(objects[slot]);
        objects[slot] = -1;
        SetPVarInt(playerid,"SelectedObject",-1);
        SetPVarInt(playerid,"Objects",GetPVarInt(playerid,"Objects") - 1);

        if(IsPlayerEdittingObject(playerid))
        CancelEdit(playerid);

        OnObjectEditMode(playerid, false);
        DestroyObjectTextdraw(playerid);

        format(msg, sizeof(msg),"Object on slot %d has been deleted",slot);
        SCM(playerid,green,msg);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:cdm(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(eInfo[EventStarted] == true) return SCM(playerid, red, "There is already event in progress");

        new string[410];
        format(string, sizeof(string), "Event Name: %s \nPlayer Spawn: %f %f %f \nWeapon 1: %s \nWeapon 2: %s \nPrice: $%s \nPrize: $%s \nHeadshot: %s \nStart Event\nClear Settings",
        eInfo[eName], eInfo[eSpawnX], eInfo[eSpawnY], eInfo[eSpawnZ], WeaponNames(eInfo[eWeapon1]), WeaponNames(eInfo[eWeapon2]), cNumber(eInfo[Price]), cNumber(eInfo[Prize]), 
        eInfo[Headshot] == 1 ? ("ON"):("OFF"));        
        ShowPlayerDialog(playerid, DIALOG_EVENTS, DIALOG_STYLE_LIST, "Deathmatch", string, "Select", "Cancel");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:ctdm(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(eInfo[EventStarted] == true) return SCM(playerid, red, "There is already event in progress");

        new string[410];
        format(string, sizeof(string), "Event Name: %s \nTeam 1 Spawn: %f %f %f \nTeam 2 Spawn: %f %f %f \nWeapon 1: %s \nWeapon 2: %s \nPrice: $%s \nPrize: %s \nHeadshot: %s \nStart Event\nClear Settings",
        eInfo[eName], eInfo[eSpawnX], eInfo[eSpawnY], eInfo[eSpawnZ], eInfo[eSX], eInfo[eSY], eInfo[eSZ], WeaponNames(eInfo[eWeapon1]), WeaponNames(eInfo[eWeapon2]), cNumber(eInfo[Price]), 
        cNumber(eInfo[Prize]), eInfo[Headshot] == 1 ? ("ON"):("OFF"));
        ShowPlayerDialog(playerid, DIALOG_EVENTS+1, DIALOG_STYLE_LIST, "Team Deathmatch", string, "Select", "Cancel");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:startevent(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(eInfo[EventStarted] == true) return SCM(playerid, red, "Event has already started");
        if(eInfo[Type] == EVENT_NONE) return SCM(playerid, red, "There is no event in progress");

        StartEvent();
        SCM(playerid, red, "You have started the event");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setewinner(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, string[128];
        if(sscanf(params, "u", id)) return SCM(playerid, red, "Set event's winner: /setewinner <PlayerID>");
        if(eInfo[EventStarted] == false) return SCM(playerid, red, "There is no event in progress");
        if(InEvent[id] == 0) return SCM(playerid, red, "Player is not in event");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

        foreach(new i : Player)
        {
            if(InEvent[i] == 1)
            {
                ResetPlayerWeaponsEx(i);
                SpawnPlayerEx(i);
                SetPlayerHealthEx(i, 100.0);
                SetPlayerArmourEx(i, 100.0);
                InEvent[i] = 0;
            }
        }

        ePlayers = 0;
        ePlayerTeamTwo = 0;
        ePlayerTeamOne = 0;
        eInfo[Type] = EVENT_NONE;
        eInfo[EventStarted] = false;

        Info[id][XP] += 100;
        GivePlayerCash(id, eInfo[Prize]);

        format(string, sizeof(string), "%s has won the event", GetName(id));
        SendClientMessageToAll(red, string);

        format(string, sizeof(string), "Winner $%s", cNumber(eInfo[Prize]));
        WinnerText(id, string);
        return 1; 
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:stopevent(playerid, parmas[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(eInfo[Type] == EVENT_NONE) return SCM(playerid, red, "There is no event in progress");

        foreach(new i : Player)
        {
            if(InEvent[i] == 1)
            {
                ResetPlayerWeaponsEx(i);
                SpawnPlayerEx(i);
                SetPlayerHealthEx(i, 100.0);
                SetPlayerArmourEx(i, 100.0);
                InEvent[i] = 0;
                GameTextForPlayer(i, "EVENT IS OVER", 2000, 6);
            }
        }

        ePlayers = 0;
        ePlayerTeamTwo = 0;
        ePlayerTeamOne = 0;
        eInfo[Type] = EVENT_NONE;
        eInfo[EventStarted] = false;

        SCM(playerid, red, "You have stopped the event");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setname(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,str[128],query[128],newname[MAX_PLAYER_NAME];
        if(sscanf(params, "us[24]", id, newname)) return SCM(playerid, red, "Change player's name: /changename <PlayerID> <NewName>");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player id");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(!(24 > strlen(newname) > 3)) return SCM(playerid,red,"Name length must be between 3 - 24 characters");
        if(AccountExists(newname)) return SCM(playerid,red, "The name is already exists");

        mysql_format(mysql, query, sizeof(query),"UPDATE `Vehicles` SET `vehOwner` = '%e' WHERE `vehOwner` = '%e'", newname, GetName(playerid));
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query), "UPDATE `HouseKeys` SET `Player` = '%e' WHERE `Player` = '%e'", newname, GetName(playerid));
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query), "UPDATE `Property` SET `Owner` = '%e' WHERE `Owner` = '%e'", newname, GetName(playerid));
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query), "UPDATE `Houses` SET `HouseOwner` = '%e' WHERE `HouseOwner` = '%e'", newname, GetName(playerid));
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query), "SELECT `ID` FROM `playersdata` WHERE `PlayerName` = '%e'", Info[id][PlayerName]);
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query),"UPDATE `playersdata` SET `PlayerName` = '%e' WHERE `ID` = '%d'", newname, Info[id][ID]);
        mysql_tquery(mysql, query);

        SetPlayerName(id, newname);

        format(str, sizeof(str), "%s %s has changed your name to %s", GetLevel(playerid), GetName(playerid), newname);
        SCM(id, red, str);

        format(str, sizeof(str), "You have changed %s name to %s", GetName(id), newname);
        SCM(playerid, NOTIF, str);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setkills(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {  
        new id, amount, string[128];
        if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Set player kills: /setkills <PlayerID> <Amount>");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");

        format(string,sizeof(string),"You have set %s kills to %d",GetName(id), amount);
        SCM(playerid, red, string);

        format(string, sizeof(string), "%s %s has set your kills to %d",GetLevel(playerid),GetName(playerid),amount);
        SCM(id, NOTIF, string);

        Info[id][Kills] = amount;
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:givekills(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui", id, amount)) return
        SCM(playerid, red, "Give player kills: /givekills <PlayerID> <Amount>") ;
        if(IsPlayerConnected(id))
        {
            format(string,sizeof(string),"You have given %d kills to %s",amount,GetName(id));
            SCM(playerid,red,string);
            format(string, sizeof(string), "%s %s has given you %d kills",GetLevel(playerid),GetName(playerid),amount);
            SCM(id,NOTIF,string);
            Info[id][Kills] +=amount;
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:cashfor(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Give player money: /cashfor <PlayerID> <Amount>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

        format(string,sizeof(string),"You have given $%s to %s",cNumber(amount),GetName(id));
        SCM(playerid,red,string);
        format(string, sizeof(string), "%s %s has given you $%s",GetLevel(playerid),GetName(playerid), cNumber(amount));
        SCM(id,NOTIF,string);
        GivePlayerCash(id, amount);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setxp(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Set player XP: /setxp <PlayerID> <Amount>") ;
        if(IsPlayerConnected(id))
        {
            format(string,sizeof(string),"You have set %d's XP to %s",amount,GetName(id));
            SCM(playerid,red,string);
            format(string, sizeof(string), "%s %s has set your XP to %d",GetLevel(playerid),GetName(playerid),amount);
            SCM(id,NOTIF,string);
            Info[id][XP] = amount;
            LevelUp(playerid);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setxlevel(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, amount, str[128];
        if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Set player's XP: /setlevel <PlayerID> <Amount>");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Player is not connected");

        format(str, sizeof(str), "You have set %s's level to %i", GetName(id), amount);
        SCM(playerid, red, str);

        format(str, sizeof(str), "%s %s has set your level to %i", GetLevel(playerid), GetName(playerid), amount);
        SCM(id, red, str);

        Info[id][xLevel] = amount;
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:marijuanafor(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui", id, amount)) return
        SCM(playerid, red, "Give player Marijuana: /marijuanafor <PlayerID> <Amount>");
        if(IsPlayerConnected(id))
        {
            format(string,sizeof(string),"You have given %d grams of Marijuana to %s",amount,GetName(id));
            SCM(playerid,red,string);
            format(string, sizeof(string), "%s %s has given you %d grams of Marijuana",GetLevel(playerid),GetName(playerid),amount);
            SCM(id,NOTIF,string);
            Info[id][Marijuana] +=amount;
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:marjfor(playerid, params[]) return cmd_marijuanafor(playerid, params);

CMD:cocainefor(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount,string[128];
        if(sscanf(params, "ui", id, amount)) return
        SCM(playerid, red, "Give player Cocaine: /cocainefor <PlayerID> <Amount>") ;
        if(IsPlayerConnected(id))
        {
            format(string,sizeof(string),"You have given %d grams of Cocaine to %s",amount,GetName(id));
            SCM(playerid,red,string);
            format(string, sizeof(string), "%s %s has given you %d grams of Cocaine",GetLevel(playerid),GetName(playerid),amount);
            SCM(id,NOTIF,string);
            Info[id][Cocaine] +=amount;
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:cocfor(playerid, params[]) return cmd_cocainefor(playerid, params);

CMD:giveveh(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,veh[30],vehid,string[128];
        if(sscanf(params, "us[30]", id ,veh)) return SCM(playerid, 0xFF0000FF, "Give player vehicle: /giveveh <PlayerID> <VehicleID/Name>");
        if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);
        if (IsPlayerInAnyVehicle(id)) return SCM(playerid,red,"player is inside a vehicle");
        if(IsNumeric(veh)) vehid = strval(veh);
        else vehid = ReturnVehicleModelID(veh);
        if(vehid < 400 || vehid > 611) return SCM(playerid, red, "Invalid vehicle model");
        GiveVehicle(id,vehid);
        format(string,sizeof(string),"%s %s has given you a vehicle",GetLevel(playerid),GetName(playerid));
        SCM(id,NOTIF,string);
        format(string,sizeof(string),"You have given %s a vehicle", GetName(id));
        return SCM(playerid, red,string);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:giveweapon(playerid,params[])
{
    if(Info[playerid][Level] >= 2)
    {
        new id,weap[32],ammo, wname[50],weapid,string[128];
        if(sscanf(params, "us[32]i",id,weap,ammo)) return SCM(playerid, red, "Give player weapon: /Giveweapon <PlayerID> <Weapon ID> <Ammo>") ;
        if(IsNumeric(weap)) weapid = strval(weap);
        else weapid = GetWeaponID(weap);
        if(weapid < 1 || weapid > 46) return SCM(playerid, red, "Invalid weapon ID/Name");
        GetWeaponName(weapid, wname, sizeof(wname));
        if(IsPlayerConnected(id))
        {
            format(string, sizeof(string), "%s %s has given you %s with %d ammo",GetLevel(playerid),GetName(playerid),wname,ammo);
            SCM(id,NOTIF,string);
            format(string,sizeof(string),"You given %s weapon %s with %d ammo",GetName(id),wname,ammo);
            SCM(playerid,red,string);
            return GivePlayerWeaponEx(id, weapid, ammo);
        }
        else return SCM(playerid,red,"Player is not connected!");
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:godcar(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(Info[playerid][VGod] == 0)
        {
            if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid,red,"You can only use this command if you are inside a vehicle");
            Info[playerid][VGod] = true;
            SetPVarInt(playerid,"CarID",GetPlayerVehicleID(playerid));
            RepairVehicle(GetPlayerVehicleID(playerid));
            SetVehicleHealth(GetPlayerVehicleID(playerid),20000);
            SCM(playerid,NOTIF,"Vehcile Godmode: ON");
        }
        else
        {
            Info[playerid][VGod] = false;
            SCM(playerid,red,"Vehcile Godmode: OFF");
            SetVehicleHealth(GetPlayerVehicleID(playerid),990);
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setwanted(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, level,string[128];
        if(sscanf(params, "ui", id, level)) return SCM(playerid, 0xFF0000FF, "Set wanted level: /setwanted <PlayerID> <wanted level>");
        if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);
        if(level < 0 || level > 6) return SCM(playerid, red, "Invalid wanted level!");
        format(string,sizeof(string),"You have set %s's wanted level to %d",GetName(id),level);
        SCM(playerid,red,string);
        format(string,sizeof(string),"%s %s has set your wanted level to %d",GetLevel(playerid),GetName(playerid),level);
        SCM(id,NOTIF,string);
        SetPlayerWantedLevel(id,level);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:freeze(playerid, params[], help)
{
    if(Info[playerid][Level] >= 3)
    {
        new id, reason[50], string[128];
        if(sscanf(params, "uS()[50]", id, reason)) return SCM(playerid, red, "Freeze player: /freeze <PlayerID> <Reason>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(Info[id][Frozen] == 1) return SCM(playerid,red,"This player is already frozen");

        if(!isnull(reason))
        format(string,sizeof(string),"%s %s has frozen you: %s",GetLevel(playerid),GetName(playerid),reason);
        else format(string,sizeof(string),"%s %s has frozen you",GetLevel(playerid),GetName(playerid));
        SCM(id, red, string);

        if(!isnull(reason)) format(string,sizeof(string),"You have frozen %s: %s", GetName(id),reason);
        else format(string,sizeof(string),"You have frozen %s",GetLevel(id));
        SCM(playerid, red, string);

        Info[id][Frozen] = 1;
        TogglePlayerControllable(id, false);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:unfreeze(playerid, params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, reason[50],string[128];
        if(sscanf(params, "uS()[50]", id, reason)) return SCM(playerid, red, "Unfreeze player: /unfreeze <PlayerID> <Reason>");
        if(!IsPlayerConnected(id)) return SCM(playerid,  red, "Player is not connected");
        if(Info[id][Frozen] == 0) return SCM(playerid,red,"This player is not frozen!");

        if(!isnull(reason))
        format(string,sizeof(string),"You have been unfrozen by %s %s: %s",GetLevel(playerid),GetName(playerid),reason);
        else format(string,sizeof(string),"You have been unfrozen by %s %s",GetLevel(playerid),GetName(playerid));

        SCM(id,NOTIF,string);
        format(string,sizeof(string),"You have unfrozen %s",GetName(id));
        SCM(playerid,red,string);
        Info[id][Frozen] = 0;
        TogglePlayerControllable(id, true);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:hidecar(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            SetPVarInt(playerid,"Interior", GetPlayerInterior(playerid));
            LinkVehicleToInterior(GetPlayerVehicleID(playerid),GetPlayerInterior(playerid)+2);
            GameTextForPlayer(playerid, "~G~Car Invisibled",2000,3);
            SCM(playerid,red,"Your vehicle has been set to an another interior. No one can see it!");
            return 1;
        }
        else return SCM(playerid,red,"You must be in vehicle driver seat to use this command!");
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:unhidecar(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            SetPVarInt(playerid,"Interior", GetPlayerInterior(playerid));
            LinkVehicleToInterior(GetPlayerVehicleID(playerid),GetPVarInt(playerid,"Interior"));
            GameTextForPlayer(playerid, "~b~Car visibled",2000,3);
            return 1;
        }
        else return SCM(playerid,red,"You must be in vehicle driver seat to use this command!");
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:akill(playerid, params[], help)
{
    if(Info[playerid][Level] >= 3)
    {
        new id,reason[50],string[128];
        if(sscanf(params, "uS()[50]", id, reason)) return SCM(playerid, red, "Kill player: /akill <PlayerID> <Reason>");
        if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);
        SetPlayerHealthEx(id,0);
        if(!isnull(reason))
        format(string,sizeof(string),"%s %s has killed you: %s",GetLevel(playerid),GetName(playerid),reason);
        else format(string,sizeof(string),"%s %s has killed you",GetLevel(playerid),GetName(playerid));
        SCM(id,red,string);
        format(string,sizeof(string),"You have killed %s",GetName(id));
        SCM(playerid,NOTIF,string);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setinterior(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id, int,string[128];
        if(sscanf(params, "ui",id,int)) return SCM(playerid, yellow, "Set player's interior: /setinterior <PlayerID> <Interior ID>");
        format(string,sizeof(string),"You have set %s's Interior to %d",GetName(id),int);
        SCM(playerid,red,string);
        format(string,sizeof(string),"%s %s has set your interior to %d",GetLevel(playerid),GetName(playerid),int);
        SCM(id,NOTIF,string);
        SetPlayerInterior(id,int);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:jetpack(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        SetPlayerSpecialAction(playerid, 2);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:vhealth(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,amount, string[128];
        if(sscanf(params, "ui",id,amount)) return SCM(playerid, yellow, "Set vehicle damage: /vhealth <Player ID/Name> <Amount> (0-1000)");
        if(IsPlayerConnected(id))
        {
            if(amount < 0 ) return SCM(playerid, red, "Invalid amount!");
            if(!IsPlayerInAnyVehicle(id)) return ShowMessage(playerid, red, 5);
            format(string, sizeof(string), "You have set %s's Vehicle Health to %d", GetName(id), amount);
            SCM(playerid,red,string);
            format(string,sizeof(string),"%s %s has set your Vehicle's Health to %d", GetLevel(playerid), GetName(playerid), amount);
            SCM(id,NOTIF,string);
            SetVehicleHealth(GetPlayerVehicleID(id), amount);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:disarm(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,string[128];
        if(sscanf(params, "u", id)) return SCM(playerid, red, "Remove player's weapons: /disarm <PlayerID>");
        if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);

        format(string,sizeof(string),"You have disarmed %s",GetName(id));
        SCM(playerid,red,string);

        format(string,sizeof(string),"%s %s has disarmed you",GetLevel(playerid),GetName(playerid));
        SCM(id,NOTIF,string);

        ResetPlayerWeaponsEx(id);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

/*============================================================================*/
/*-------------------------------Level 4--------------------------------------*/
/*============================================================================*/

CMD:deleteaccount(playerid, params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new name[25];
        if(sscanf(params, "s[25]", name)) return SCM(playerid, red, "Delete account: /deleteaccount <PlayerName>");
        if(!AccountExists(name)) return SCM(playerid, red, "Account doesn't exist");

        new query[128];
        mysql_format(mysql, query, sizeof(query), "DELETE FROM `playersdata` WHERE `PlayerName` = '%e'", name);
        mysql_tquery(mysql, query);

        format(query, 128, "You have deleted %s's account", name);
        SCM(playerid, red, query);
        return 1;
    }
    else return ShowMessage(playerid, 0xFF0000FF, 1);
}

CMD:setskills(playerid, params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id, amount, string[128];
        if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Set player's gang skills: /setskills <PlayerID> <Amount>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");
        if(pTeam[id] == NO_TEAM) return SCM(playerid, red, "Player is not in gang");

        Info[id][Skills][pTeam[id]] = amount;

        format(string, sizeof(string), "%s %s has set your gang skills to %d", GetLevel(playerid), GetName(playerid), amount);
        SCM(id, NOTIF, string);

        format(string, sizeof(string), "You have set %s's gang skills to %d", GetName(id), amount);
        SCM(playerid, red, string);
        return 1;
    }
    else return ShowMessage(playerid, 0xFF0000FF, 1);
}

CMD:setskin(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id,skinid,str[128];
        if(sscanf(params, "ui", id, skinid)) return SCM(playerid, 0xFF0000FF, "Set player's skin: /setskin <PlayerID> <SkinID>") ;
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

        if(skinid < 0 || skinid > 311) return SCM(playerid, red, "Invaild skin ID");
        if(skinid == 74) return SCM(playerid, red, "Invaild skin ID");

        format(str,sizeof(str),"You have set %s's skin to %d", GetName(id), skinid);
        SCM(playerid,red,str);

        format(str, sizeof(str), "%s %s has set your skin to %d",GetLevel(playerid),GetName(playerid),skinid);
        SCM(id,0xFF0066FF,str);

        SetPlayerSkin(id, skinid);
        return 1;
    }
    else return ShowMessage(playerid, 0xFF0000FF, 1);
}

CMD:setpremium(playerid, params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id, days, string[128], query[128];
        if(sscanf(params, "ui", id, days)) return SCM(playerid, red, "Set player premium: /setpremium <PlayerID> <Days (0 to disable the premium)>");
        if(days == 0 && Info[id][Premium] == 0) return SCM(playerid, red, "Player is not premium");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

        if(days == 0)
        {
            Info[id][Premium] = 0;
            Info[id][PremiumExpires] = 0;

            if(IsValidDynamic3DTextLabel(PlayerTag[id])) DestroyDynamic3DTextLabel(PlayerTag[id]);
            TeamColorFP(id);

            mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `Premium` = %i, `PremiumExpires` = %i  WHERE `ID` = %d", Info[id][Premium], Info[id][PremiumExpires], Info[id][ID]);
            mysql_tquery(mysql, query);

            format(string, sizeof(string), "%s %s has removed your premium account", GetLevel(playerid), GetName(playerid));
            SCM(id, NOTIF, string);

            format(string, sizeof(string), "You have removed %s's premium account", GetName(id));
            SCM(playerid, red, string);
        }
        else
        {
            Info[id][Premium] = 1;
            if(Info[id][PremiumExpires] == 0) Info[id][PremiumExpires] = gettime() + days*86400;
            else Info[id][PremiumExpires] = Info[id][PremiumExpires] + (days*86400);

            mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `Premium` = %i, `PremiumExpires` = %i  WHERE `ID` = %d", Info[id][Premium], Info[id][PremiumExpires], Info[id][ID]);
            mysql_tquery(mysql, query);

            format(string, sizeof(string), "%s %s has set you premium for %d days", GetLevel(playerid), GetName(playerid), days);
            SCM(id, NOTIF, string);

            format(string, sizeof(string), "You have set %s premium for %d days", GetName(id), days);
            SCM(playerid, red, string);
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setcash(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id,cash,string[128];
        if(sscanf(params, "ui", id, cash)) return SCM(playerid, red, "Set player's money: /Setcash <PlayerID> <Cash>");
        if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");

        format(string, sizeof(string), "%s %s has set your cash to $%s",GetLevel(playerid),GetName(playerid),cNumber(cash));
        SCM(id, NOTIF, string);

        format(string, sizeof(string),"You have set %s's cash to $%s", GetName(id), cNumber(cash));
        SCM(playerid, red, string);

        SetPlayerCash(id, cash);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:startmb(playerid)
{
    if(Info[playerid][Level] >= 4)
    {
        MoneyBag();
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setpos(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new lvl, id, str[128];
        if(sscanf(params, "ui", id, lvl)) return SCM(playerid, red,"Promote/Demote player: /setpos <ID> <Level>");
        SCM(playerid, red,"0- Player, 1- Helper, 2- Moderator");
        if(playerid == id) return SCM(playerid, red, "You can't promote/demote yourself");
        if(id == INVALID_PLAYER_ID) return SCM(playerid, red,"Invalid player ID");
        if(lvl < 0 || lvl > 2) return SCM(playerid, red, "Invalid level");
        if(Info[playerid][Level] < Info[id][Level]) return ShowMessage(playerid, red, 6);
        switch (lvl)
        {
            case 0:
            {
                Info[id][Level] = 0;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Normal Player'", GetLevel(playerid), GetName(id));
                SCM(id, 0xFF0066FF, str );
                format(str, sizeof(str), "You have set %s as 'Normal Player'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 1:
            {
                Info[id][Level] = 1;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Helper'", GetLevel(playerid), GetName(id));
                SCM(id, 0xFF0066FF, str );
                format(str, sizeof(str), "You have set %s as 'Helper'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 2:
            {
                Info[id][Level] = 2;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Moderator'", GetLevel(playerid), GetName(id));
                SCM(id, 0xFF0066FF, str );
                format(str, sizeof(str), "You have set %s as 'Moderator'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
        }
    }
    return 1;
}

CMD:fakechat(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id,string[128];
        if(sscanf(params, "us[128]", id, string)) return SCM(playerid, red, "Fake chat: /fakechat <PlayerID> <Chat Message>");
        if(IsPlayerConnected(id))
        {
            CallRemoteFunction("OnPlayerText", "is", id, string);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:fakekill(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id,killed,reason;
        if(sscanf(params, "uui", id, killed, reason)) return SCM(playerid, red, "Fake kill: /fakekill <KillerID> <KilledID/> <Reson ID/weapon>");
        if(IsPlayerConnected(id))
        {
            if(reason > 0 && reason < 19 || reason > 21 && reason < 47)
            {
            if(!IsPlayerConnected(killed)) return SCM(playerid, red, "Killed id not connected!");
            SendDeathMessage(id,killed,reason);
            return SCM(playerid,lighterblue,"-Fake death message has been message sent");
            }
            else return SCM(playerid,red,"Invalid Reason ID");
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:announce(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new string[128];
        if(sscanf(params, "s[128]",string)) return SCM(playerid, red, "Screen message for players: /announce <Message>");
        return GameTextForAll(string,8000,3);
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:ann(playerid, params[]) return cmd_announce(playerid, params);

CMD:screenmessage(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id,string[128];
        if(sscanf(params, "us[128]",id,string)) return SCM(playerid, red, "Send screen message to player: /screenmessage <PlayerID> <Message>");
        return GameTextForPlayer(id,string, 5000, 3);
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:ss(playerid, params[]) return cmd_screenmessage(playerid, params);

CMD:resetcash(playerid,params[])
{
      if(Info[playerid][Level] >= 4)
      {
           new id,string[128];
           if(sscanf(params, "u", id)) return SCM(playerid, red, "Reset player money: /resetcash <PlayerID>");
           if(!IsPlayerConnected(id)) return ShowMessage(playerid, red, 2);
           format(string,sizeof(string),"You have reset %s's cash",GetName(id));
           SCM(playerid,red,string);
           format(string,sizeof(string),"%s %s has reset your cash'",GetLevel(playerid),GetName(playerid));
           SCM(id,NOTIF,string);
           ResetPlayerCash(id);
           return 1;
      }
      else return ShowMessage(playerid, red, 1);
}

CMD:getip(playerid,params[])
{
    if(Info[playerid][Level] >= 3)
    {
        new id,ip[16],string[128];
        if(sscanf(params, "u", id)) return SCM(playerid, red, "Get player's IP: /getip <PlayerID>");
        if(IsPlayerConnected(id))
        {
            GetPlayerIp(id,ip,16);
            format(string, sizeof(string),"Player Name: %s (%d) | IP: %s", GetName(id), id, ip);
            SCM(playerid, green, string);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:crash(playerid,params[])
{
    if(Info[playerid][Level] >= 4)
    {
        new id,string[128];
        if(sscanf(params, "u", id)) return SCM(playerid, red, "Crash player's game: /crash <PlayerID>");
        if(IsPlayerConnected(id))
        {
            if(Info[playerid][Level] <= Info[id][Level]) return SCM(playerid,red,"You cannot perform this command on this admin");

            GameTextForPlayer(id, "~~555~~J#~~L", 6000, 3);
            GameTextForPlayer(id, "%%$#@1~555#", 6000, 3);
            GameTextForPlayer(id, "%%$#@1~555#", 6000, 6);

            format(string, sizeof(string), "You have crashed %s", GetName(id));
            SCM(playerid, red, string);
            return 1;
        }
        else return ShowMessage(playerid, red, 2);
    }
    else return ShowMessage(playerid, red, 1);
}

/*============================================================================*/
/*-------------------------------Level 5--------------------------------------*/
/*============================================================================*/

CMD:setpassword(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new query[320], name[24], newpass[34], hash[34];
        if(sscanf(params, "s[24]s[34]", name, newpass)) return SCM(playerid, red, "Change player's password: /setpassword <PlayerName> <NewPassword>");
        if(!AccountExists(name)) return SCM(playerid, red, "Account does not exists");

        WP_Hash(hash, 129, newpass);
        mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `Password` = '%e' WHERE `PlayerName` = '%e'", hash, name);
        mysql_tquery(mysql, query);

        format(query, sizeof(query), "You have changed %s's password to %s", name, newpass);
        SCM(playerid, red, query);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:createvehicle(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new modelid[30], vehid, color1, color2, price;
        if(sscanf(params, "s[30]iii", modelid, color1, color2, price)) return SCM(playerid, red, "Create vehicle: /createvehicle <ModelID> <Color1> <Color2> <Price>");

        if(IsNumeric(modelid)) vehid = strval(modelid);
        else vehid = ReturnVehicleModelID(modelid);

        if(vehid < 400 || vehid > 611) return SCM(playerid, red, "Invalid vehicle model!");

        new index = Iter_Free(ServerVehicles);
        if(index == -1) return SCM(playerid, red, "You can't create more vehicle!");

        if(IsPlayerInAnyVehicle(playerid)) DestroyVehicle(GetPlayerVehicleID(playerid));

        GetPlayerPos(playerid, vInfo[index][vehX], vInfo[index][vehY], vInfo[index][vehZ]);
        GetPlayerFacingAngle(playerid, vInfo[index][vehA]);

        SetPlayerPos(playerid, vInfo[index][vehX] + 3, vInfo[index][vehY], vInfo[index][vehZ]);

        vInfo[index][vehSessionID] = CreateVehicle(vehid, vInfo[index][vehX], vInfo[index][vehY], vInfo[index][vehZ], vInfo[index][vehA], color1, color2, 10);
        SetVehicleParamsEx(vInfo[index][vehSessionID], 1, 0, 0, 1, 0, 0, 0);
        SetVehicleNumberPlate(vInfo[index][vehSessionID], "UG");

        format(vInfo[index][vehName], MAX_PLAYER_NAME, GetVehicleName(vehid));
        format(vInfo[index][vehOwner], MAX_PLAYER_NAME, "-");
        format(vInfo[index][vehPlate], 16, "UG");

        vInfo[index][vehModel] = vehid;
        vInfo[index][vehPrice] = price;
        vInfo[index][vehLock] = MODE_LOCK;
        vInfo[index][vehColorOne] = color1;
        vInfo[index][vehColorTwo] = color2;

        new string[120];
        format(string, sizeof(string), "VehicleID: %d\nVehicle: %s\nPrice: $%s\nType /buyvehicle to buy!", index, vInfo[index][vehName], cNumber(vInfo[index][vehPrice]));

        vInfo[index][vehLabel] = CreateDynamic3DTextLabel(string, 0xFFFF00FF, vInfo[index][vehX], vInfo[index][vehY], vInfo[index][vehZ], 10.0, INVALID_PLAYER_ID, vInfo[index][vehSessionID]);

        new query[340];
        mysql_format(mysql, query, sizeof(query),
        "INSERT INTO `Vehicles` (vehModel, vehPrice, vehName, vehPlate, vehColorOne, vehColorTwo, vehX, vehY, vehZ, vehA) VALUES (%d, %d, '%e', '%e', %d, %d, %f, %f, %f, %f)",
        vInfo[index][vehModel], vInfo[index][vehPrice], vInfo[index][vehName], vInfo[index][vehPlate], vInfo[index][vehColorOne], vInfo[index][vehColorTwo], vInfo[index][vehX], 
        vInfo[index][vehY], vInfo[index][vehZ], vInfo[index][vehA]);
        mysql_tquery(mysql, query, "OnDealerVehicleCreated", "i", index);

        format(query, sizeof(query), "You have created a vehicle - ModelID: %d, VehicleID: %d, Price: %d", vInfo[index][vehModel], index, vInfo[index][vehPrice]);
        SCM(playerid, red, query);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:vcreate(playerid, params[]) return cmd_createvehicle(playerid, params);

CMD:gotovehicle(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id;
        if(sscanf(params, "i", id)) return SCM(playerid, red, "Teleport to vehicle: /gotovehicle <VehicleID>");
        if(!Iter_Contains(ServerVehicles, id)) return SendClientMessage(playerid, red, "Invalid vehicle ID");

        GetVehiclePos(vInfo[id][vehSessionID], vInfo[id][vehX], vInfo[id][vehY], vInfo[id][vehZ]);

        SetPlayerPos(playerid, vInfo[id][vehX], vInfo[id][vehY], vInfo[id][vehZ]+3);
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setvehicleprice(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id, price;
        if(sscanf(params, "ii", id, price)) return SCM(playerid, red, "Set vehicle price: /setvehicleprice <VehicleID> <Price>");
        if(!Iter_Contains(ServerVehicles, id)) return SendClientMessage(playerid, red, "Invalid vehicle ID");

        new query[64];
        mysql_format(mysql, query, sizeof(query), "UPDATE `Vehicles` SET `vehPrice` = %i WHERE `vehID` = %d", price, vInfo[id][vehID]);
        mysql_tquery(mysql, query);

        SCM(playerid, red, "Price updated");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:setvprice(playerid, params[]) return cmd_setvehicleprice(playerid, params);

CMD:deletevehicle(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id;
        if(sscanf(params, "i", id)) return SCM(playerid, red, "Delete vehicle: /deletevehicle <VehicleID>");
        if(!Iter_Contains(ServerVehicles, id)) return SendClientMessage(playerid, red, "Invalid vehicle ID");

        ResetVehicle(id);

        Iter_Remove(ServerVehicles, id);

        new query[68];
        mysql_format(mysql, query, sizeof(query), "DELETE FROM `Vehicles` WHERE `vehID` = %d", vInfo[id][vehID]);
        mysql_tquery(mysql, query);

        SCM(playerid, red, "Vehicle deleted");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}
CMD:vdel(playerid, params[]) return cmd_deletevehicle(playerid, params);

CMD:createhouse(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new interior, price;
        if(sscanf(params, "ii", price, interior)) return SendClientMessage(playerid, red, "Create house: /createhouse <Price> <Interior>");
        if(!(0 <= interior <= sizeof(HouseInteriors)-1)) return SendClientMessage(playerid, red, "Interior ID you entered does not exist");

        new id = Iter_Free(Houses);
        if(id == -1) return SendClientMessage(playerid, red, "You can't create more houses");

        format(HouseData[id][Owner], MAX_PLAYER_NAME, "-");
        GetPlayerPos(playerid, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);

        HouseData[id][Price] = price;
        HouseData[id][Interior] = interior;
        HouseData[id][LockMode] = STATUS_NOLOCK;
        HouseData[id][SalePrice] = HouseData[id][SafeMoney] = HouseData[id][HouseExpire] = 0;
        HouseData[id][HouseSave] = true;

        new label[200];
        format(label, sizeof(label), "House: %d\nPrice: $%s", id, cNumber(price));

        HouseData[id][HouseLabel] = CreateDynamic3DTextLabel(label, 0xFFFF00FF, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]+0.35, 15.0, .testlos = 1);
        HouseData[id][HousePickup] = CreateDynamicPickup(1273, 1, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
        HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], 31, 0);

        Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1273);
        Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);

        new query[230];
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `Houses` SET `ID` = %d, `HouseX` = %f, `HouseY` = %f, `HouseZ` = %f, `HousePrice` = %d, `HouseInterior` = %d", id, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], price, interior);
        mysql_tquery(mysql, query);
        Iter_Add(Houses, id);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:gotohouse(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id;
        if(sscanf(params, "i", id)) return SendClientMessage(playerid, red, "Teleport to house: /gotohouse <HouseID>");
        if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, red, "Invalid house ID");

        SetPlayerPos(playerid, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:sethouseinterior(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id, interior;
        if(sscanf(params, "ii", id, interior)) return SendClientMessage(playerid, red, "Change house's interior: /sethouseinterior <HouseID> <InteriorID>");
        if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, red, "Invalid house ID");
        if(!(0 <= interior <= sizeof(HouseInteriors)-1)) return SendClientMessage(playerid, red, "Interior ID you entered does not exist");

        HouseData[id][Interior] = interior;

        new query[64];
        mysql_format(mysql, query, sizeof(query), "UPDATE Houses SET HouseInterior=%d WHERE ID=%d", interior, id);
        mysql_tquery(mysql, query);

        UpdateHouseLabel(id);
        SendClientMessage(playerid, red, "Interior updated");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:sethouseprice(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id, price;
        if(sscanf(params, "ii", id, price)) return SendClientMessage(playerid, red, "Set house's price: /sethouseprice <HouseID> <Price>");
        if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, red, "Invalid house ID");
        HouseData[id][Price] = price;

        new query[64];
        mysql_format(mysql, query, sizeof(query), "UPDATE `Houses` SET `HousePrice` = %d WHERE `ID` = %d", price, id);
        mysql_tquery(mysql, query);

        UpdateHouseLabel(id);
        SendClientMessage(playerid, red, "Price updated");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:resethouse(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id;
        if(sscanf(params, "i", id)) return SendClientMessage(playerid, red, "Reset house: /resethouse <HouseID>");
        if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, red, "Invalid house ID");

        ResetHouse(id);
        SendClientMessage(playerid, red, "House reseted");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:deletehouse(playerid, params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new id;
        if(sscanf(params, "i", id)) return SendClientMessage(playerid, red, "Delete house: /deletehouse <HouseID>");
        if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, red, "Invalid house ID");

        ResetHouse(id);

        DestroyDynamic3DTextLabel(HouseData[id][HouseLabel]);
        DestroyDynamicPickup(HouseData[id][HousePickup]);
        DestroyDynamicMapIcon(HouseData[id][HouseIcon]);

        Iter_Remove(Houses, id);
        HouseData[id][HouseLabel] = Text3D: INVALID_3DTEXT_ID;
        HouseData[id][HousePickup] = HouseData[id][HouseIcon] = -1;

        new query[64];
        mysql_format(mysql, query, sizeof(query), "DELETE FROM `Houses` WHERE `ID` = %d", id);
        mysql_tquery(mysql, query);

        SendClientMessage(playerid, red, "House deleted");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:ctele(playerid,params[])
{
    if(Info[playerid][Level] >= 5)
    {
        ShowPlayerDialog(playerid, DIALOGS+115, DIALOG_STYLE_INPUT, "Create Teleport", "Enter the teleport name", "Create", "Close");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:reloadteles(playerid,params[])
{
    if(Info[playerid][Level] >= 5)
    {
        LoadTeleports();
        SendClientMessage(playerid,yellow,"You have re-loaded the teleports!");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:clearteles(playerid,params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new file[100];
        format(file, 100, SETTING_PATH, "Teleports");
        if(!fexist(file)) return ShowPlayerDialog(playerid,DIALOGS+44,DIALOG_STYLE_MSGBOX,"Note","{FF0000}Could not clear the teleports (Could not find the file)","Close","");
        fremove(file);
        ShowPlayerDialog(playerid,DIALOGS+44,DIALOG_STYLE_MSGBOX,"Teleports cleared","You have successfully cleared the teleports","Close","");
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:createproperty(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {
		new price, name[34], revenue;
		if(sscanf(params, "iis[34]", price, revenue, name)) return SCM(playerid, red, "Create property: /createproperty <Price> <Revenue> <Name>");
        
        new id = Iter_Free(Property);
		if(id == -1) return SCM(playerid, red, "You can't create any more properties");

		format(pInfo[id][prName], MAX_PROPERTY_NAME, name);
		format(pInfo[id][Owner], MAX_PLAYER_NAME, "-");
		GetPlayerPos(playerid, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]);

		pInfo[id][Price] = price;
		pInfo[id][Earning] = revenue;
		pInfo[id][PropertyExpire] = 0;

        new string[128];
        format(string, sizeof(string), "Property: %s\nPrice: $%s", name, cNumber(price));

		pInfo[id][PropertyPickup] = CreateDynamicPickup(1273, 1, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]);
		pInfo[id][PropertyLabel] = CreateDynamic3DTextLabel(string, 0xFFFF00FF, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]+0.35, 15.0, .testlos = 1);
        pInfo[id][PropertyMapIcon] = CreateDynamicMapIcon(pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ], 31, 0, 0, 0);

		Iter_Add(Property, id);

		new query[220];
		mysql_format(mysql, query, sizeof(query), "INSERT INTO `Property` SET `ID` = %d, `Name` = '%e', `PropertyX` = %f, `PropertyY` = %f, `PropertyZ` = %f, `Price` = %d", id, pInfo[id][prName], pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ], price);
		mysql_tquery(mysql, query, "OnPropertyCreated", "i", id);
		return 1;
	}
    else return ShowMessage(playerid, red, 1);
}
CMD:pcreate(playerid, params[]) return cmd_createproperty(playerid, params);

CMD:gotoproperty(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {
	    new id;
		if(sscanf(params, "i", id)) return SCM(playerid, red, "Teleport to property: /gotoproperty <PropertyID>");
		if(!Iter_Contains(Property, id)) return SCM(playerid, red, "Invalid property ID");

	    SetPlayerPos(playerid, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]);
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, 0);
		return 1;
	}
    else return ShowMessage(playerid, red, 1);
}
CMD:pgoto(playerid, params[]) return cmd_gotoproperty(playerid, params);

CMD:setpropertyprice(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {   
		new id, price;
		if(sscanf(params, "ii", id, price)) return SCM(playerid, red, "Change property's price: /setpropertyprice <PropertyID> <Price>");
		if(!Iter_Contains(Property, id)) return SCM(playerid, red, "Invalid property ID");

	    pInfo[id][Price] = price;
	    pUpdateLabel(id);
	    pSave(id);

	    new string[80];
	    format(string, sizeof(string), "You have changed property ID: %d price to %s", id, cNumber(price));
	    SendClientMessage(playerid, red, string);
		return 1;
	}
    else return ShowMessage(playerid, red, 1);
}
CMD:psetprice(playerid, params[]) return cmd_setpropertyprice(playerid, params);

CMD:setpropertyrevenue(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {
	    new id, revenue;
		if(sscanf(params, "ii", id, revenue)) return SCM(playerid, red, "Change property's revenue: /setpropertyrevnue <PropertyID> <Revenue>");
		if(!Iter_Contains(Property, id)) return SCM(playerid, red, "Invalid property ID");

	    pInfo[id][Earning] = revenue;
	    pUpdateLabel(id);
	    pSave(id);

	    new string[80];
	    format(string, sizeof(string), "You have changed property ID: %d revenue to $%s", id, cNumber(revenue));
	    SendClientMessage(playerid, red, string);
		return 1;
	}
    else return ShowMessage(playerid, red, 1);
}
CMD:psetrevenue(playerid, params[]) return cmd_setpropertyrevenue(playerid, params);

CMD:resetproperty(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {
	    new id;
		if(sscanf(params, "i", id)) SCM(playerid, red, "Reset property: /resetproperty <PropertyID>");
		if(!Iter_Contains(Property, id)) return SCM(playerid, red, "Invalid property ID");
	    pReset(id);
	    
	    new string[50];
		format(string, sizeof(string), "You have reseted property ID: %d", id);
		SCM(playerid, red, string);
		return 1;
	}
    else return ShowMessage(playerid, red, 1);
}
CMD:preset(playerid, params[]) return cmd_resetproperty(playerid, params);

CMD:deleteproperty(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    { 
	    new id;
		if(sscanf(params, "i", id)) return SCM(playerid, red, "Delete property: /deleteproperty <PropertyID>");
		if(!Iter_Contains(Property, id)) return SCM(playerid, red, "Invalid property ID");

		DestroyDynamic3DTextLabel(pInfo[id][PropertyLabel]);
		DestroyDynamicPickup(pInfo[id][PropertyPickup]);
		DestroyDynamicMapIcon(pInfo[id][PropertyMapIcon]);

	    format(pInfo[id][prName], MAX_PROPERTY_NAME, "Property");
		format(pInfo[id][Owner], MAX_PLAYER_NAME, "-");

		pInfo[id][PropertyLabel] = Text3D:INVALID_3DTEXT_ID;
		pInfo[id][PropertyPickup] = -1;
		pInfo[id][PropertyExpire] = 0;
		pInfo[id][PropertySave] = false;
		Iter_Remove(Property, id);

		new query[64];
		mysql_format(mysql, query, sizeof(query), "DELETE FROM Property WHERE ID=%d", id);
		mysql_tquery(mysql, query);

		format(query, sizeof(query), "You have deleted property ID: %d", id);
		SCM(playerid, red, query);
		return 1;
	}
    else return ShowMessage(playerid, red, 1);
}
CMD:pdelete(playerid, params[]) return cmd_deleteproperty(playerid, params);

CMD:setlevel(playerid,params[])
{
    if(Info[playerid][Level] >= 5 || IsPlayerAdmin(playerid))
    {
        new id, lvl, str[128];
        if(sscanf(params, "ui", id, lvl)) return SCM( playerid, red,"Promote/Demote player: /setlevel <ID> <Level>");
        if(id == INVALID_PLAYER_ID) return SCM( playerid, red, "Invalid player ID" );
        if(lvl < 0 || lvl > 5) return SCM(playerid, red, "Invalid level");
        switch (lvl)
        {
            case 0:
            {
                Info[id][Level] = 0;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Normal Player'", GetLevel(playerid), GetName(playerid));
                SCM(id, 0xFF0066FF, str );

                format(str, sizeof(str), "You have set %s as 'Normal Player'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 1:
            {
                Info[id][Level] = 1;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Helper'", GetLevel(playerid), GetName(playerid));
                SCM(id, 0xFF0066FF, str );

                format(str, sizeof(str), "You have set %s as 'Helper'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 2:
            {
                Info[id][Level] = 2;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Moderator'", GetLevel(playerid), GetName(playerid));
                SCM(id, 0xFF0066FF, str );

                format(str, sizeof(str), "You have set %s as 'Moderator'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 3:
            {
                Info[id][Level] = 3;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Administrator'", GetLevel(playerid), GetName(playerid));
                SCM(id, 0xFF0066FF, str );

                format(str, sizeof(str), "You have set %s as 'Administrator'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 4:
            {
                Info[id][Level] = 4;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Lead Administrator'", GetLevel(playerid), GetName(playerid));
                SCM(id, 0xFF0066FF, str );

                format(str, sizeof(str), "You have set %s as 'Lead Administrator'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
            case 5:
            {
                Info[id][Level] = 5;
                format(str, sizeof(str), "{FF0066}%s %s has set you 'Community Owner'", GetLevel(playerid), GetName(playerid));
                SCM(id, NOTIF, str );

                format(str, sizeof(str), "You have set %s as 'Community Owner'", GetName(id));
                SCM(playerid, 0x6666FFFF, str);
                return 1;
            }
        }
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:giveugc(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {
    	new id, amount, string[128];
    	if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Give player UGC: /giveugc <PlayerID> <Amount>");
    	if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    	if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");

    	new Float:val = floatdiv(float(amount), 100);

    	format(string, sizeof(string), "%s %s has given you %0.2f UGC", GetLevel(playerid), GetName(playerid), val);
    	SCM(id, NOTIF, string);

    	format(string, sizeof(string), "You have given %s %0.2f UGC", GetName(id), val);
    	SCM(playerid, red, string);

    	Info[id][UGC] += amount;
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:setugc(playerid, params[])
{
	if(Info[playerid][Level] >= 5)
    {
    	new id, amount, string[128];
    	if(sscanf(params, "ui", id, amount)) return SCM(playerid, red, "Set player's UGC: /setugc <PlayerID> <Amount>");
    	if(!IsPlayerConnected(id)) return SCM(playerid, red, "Player is not connected");
    	if(id == INVALID_PLAYER_ID) return SCM(playerid, red, "Invalid player ID");

    	new Float:val = floatdiv(float(amount), 100); 

    	format(string, sizeof(string), "%s %s has set your money to %0.2f UGC", GetLevel(playerid), GetName(playerid), val);
    	SCM(id, NOTIF, string);

    	format(string, sizeof(string), "You have set %s's money to %0.2f UGC", GetName(id), val);
    	SCM(playerid, red, string);

    	Info[id][UGC] = amount;
        return 1;
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:hostname(playerid,params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new txt[60];
        if(sscanf(params, "s[60]",txt)) return SCM(playerid,red,"Change the host name: /Hostname <New Host Name>");
        format(txt,sizeof(txt),"hostname %s",txt);
        return SendRconCommand(txt);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:mapname(playerid,params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new txt[60];
        if(sscanf(params, "s[60]",txt)) return SCM(playerid,red,"Change the map name: /Mapname <New Map Name>");
        format(txt,sizeof(txt),"mapname %s",txt);
        return SendRconCommand(txt);
    }
    else return ShowMessage(playerid, red, 1);
}

CMD:gmtext(playerid,params[])
{
    if(Info[playerid][Level] >= 5)
    {
        new txt[60];
        if(sscanf(params, "s[60]",txt)) return SCM(playerid,red,"Change the gamemode name: /Gmtext <New Gamemode Name>");
        format(txt, sizeof(txt),"gamemodetext %s",txt);
        return SendRconCommand(txt);
    }
    else return ShowMessage(playerid, red, 1);
}

/*============================================================================*/
/*----------------------End Administration Commands---------------------------*/
/*============================================================================*/

stock IsValidSkin(skinid) return skinid < 0 || skinid > 311 || skinid == 74 ? false : true;  

function SpawnHim(playerid)
{
    SetSpawnInfo(playerid, NO_TEAM, Info[playerid][Skin], Info[playerid][PosX], Info[playerid][PosY], Info[playerid][PosZ], 0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
}

function SpawnHim2(playerid)
{
    Info[playerid][Registered] = 0;
    Info[playerid][Logged] = 1;

    GivePlayerCash(playerid, 25000);
    SetSpawnInfo(playerid, NO_TEAM, GetPlayerSkin(playerid), 1479.685302, -1685.790405, 14.046875, 180.214904, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);

    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerHealthEx(playerid, 100);
    SetPlayerArmourEx(playerid, 0);
}

function PausedCheck()
{
    foreach(new playerid : Player)
    {
        if(IsPlayerSpawned(playerid))
        {
            if(GetTickCount() - pTick[playerid] >= 1000)
            {
                IsPaused[playerid] = 1;
                if(StartTimer[playerid] == 0)
                {
                    StartTimer[playerid] = 1;
                    pauseTimer[playerid] = SetTimerEx("AntiAFK", 900000, false, "i", playerid);
                }
            }
            else
            {
                IsPaused[playerid] = 0;
                StartTimer[playerid] = 0;
                KillTimer(pauseTimer[playerid]);
            }
        }
    }
}

function AntiAFK(playerid)
{
    new str[84];
    format(str, sizeof(str), "%s has been kicked for inactivity", GetName(playerid));
    SendClientMessageToAll(red, str);
    DelayKick(playerid);
    return 1;
}

function VehicleSpeedoMeter(playerid)
{
    if(IsPlayerInAnyVehicle(playerid))
    {
        new  Float:vHealth;
        GetVehicleHealth(GetPlayerVehicleID(playerid), vHealth);
        new Float:percentage = (((vHealth - 250.0) / (1000.0 - 250.0)) * 100.0);

        new vspeed[40];
        format(vspeed, sizeof(vspeed), "~g~KM/H: ~w~%d  ~g~Health: ~w~%.0f", GetVehicleSpeed(playerid), percentage);
        PlayerTextDrawSetString(playerid, VehicleSpeedo, vspeed);
    }
}

function playerLevel(playerid) return Info[playerid][Level];

stock WinnerText(playerid, const text[])
{
    PlayerTextDrawHide(playerid, BPayout[playerid]);

    new string[84];
    format(string, sizeof(string), "%s", text);
    PlayerTextDrawSetString(playerid, BPayout[playerid], string);
    PlayerTextDrawShow(playerid, BPayout[playerid]);
    SetTimerEx("HidePayout", 5000, 0, "d", playerid);
}

GetPlayerSpeed(playerid)
{
    new Float:ST[4];
    if(!IsPlayerInAnyVehicle(playerid)) GetPlayerVelocity(playerid, ST[0], ST[1], ST[2]);
    ST[3] = floatsqroot(floatpower(floatabs(ST[0]), 2.0) + floatpower(floatabs(ST[1]), 2.0) + floatpower(floatabs(ST[2]), 2.0)) * 179.28625;
    return floatround(ST[3]);
}

Float:GetVehicleTopSpeed(vehicleid)
{
    new model = GetVehicleModel(vehicleid);

    if(model) return float(s_TopSpeed[(model - 400)]);
    return 0.0;
}

function SpecPlayer(playerid)
{
    new pstring[280], Float:health, Float:armour;
    new id = SpecID[playerid], ip[16], Float:percentage;

    GetPlayerIp(id, ip, sizeof(ip));

    GetPlayerHealth(id, health);
    GetPlayerArmour(id, armour);

    if(IsPlayerInAnyVehicle(id))
    {
        new Float:vHealth;
        GetVehicleHealth(GetPlayerVehicleID(id), vHealth);
        percentage = (((vHealth - 250.0) / (1000.0 - 250.0)) * 100.0);
    }
    else percentage = 0.0;

    format(pstring, sizeof(pstring), 
    "~g~Player: ~w~%s (%i) ~n~~g~Armour: ~w~%.0f ~n~~g~Health: ~w~%.0f ~n~~g~Weapon: ~w~%s (Ammo: %i) ~n~~g~Ping: ~w~%i\
    ~n~~g~IP: ~w~%s ~n~~g~Money: ~w~%i ~n~~g~Speed: ~w~%i MPH ~n~~g~Vehicle Speed: ~w~%i/%.0f MPH ~n~~g~Vehicle Health: ~w~%.0f", 
    GetName(id), id, armour, health, WeaponNames(GetPlayerWeapon(id)), GetPlayerAmmo(id), GetPlayerPing(id),
    ip, GetPlayerCash(id), GetPlayerSpeed(id), GetVehicleSpeed(id), GetVehicleTopSpeed(GetPlayerVehicleID(id)), percentage);

    PlayerTextDrawSetString(playerid, SpectateTextDraw[playerid], pstring);
    PlayerTextDrawShow(playerid, SpectateTextDraw[playerid]);
}

stock IsPlayerSpawned(playerid)
{
    switch(GetPlayerState(playerid))
    {
        case PLAYER_STATE_ONFOOT, PLAYER_STATE_DRIVER, PLAYER_STATE_PASSENGER, PLAYER_STATE_SPAWNED: return true;
        default: return false;
    }
    return false;
}

public DelayedKick(playerid)
{
    Kick(playerid);
    return 1;
}

// Get player name

GetName(playerid)
{
    new pName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pName, MAX_PLAYER_NAME);
    return pName;
}

// Show Message

ShowMessage(playerid, color, msgid)
{
    switch(msgid)
    {
        case 1: SCM(playerid, color, "Unknown command! Type /commands");
        case 2: SCM(playerid, color, "Player is not connected");
        case 3: SCM(playerid, color, "You can't use this command on yourself");
        case 4: SCM(playerid, color, "You must be logged in to use this command");
        case 5: SCM(playerid, color, "Player is not in a vehicle");
        case 6: SCM(playerid, color, "You can not perform command on this admin");
    }
    return 1;
}

// Get Level name

GetLevel(playerid)
{
    new ranklevel[24];
    switch(Info[playerid][Level])
    {
        case 1: ranklevel = "Helper";
        case 2: ranklevel = "Moderator";
        case 3: ranklevel = "Administrator";
        case 4: ranklevel = "Lead Administrator";
        case 5: ranklevel = "Community Owner";
    }
    return ranklevel;
}

// Logs

stock SaveLog(playerid, const text[])
{
    new query[180];
    mysql_format(mysql, query, sizeof(query),"INSERT INTO `PlayerLogs` (PlayerName, Text, Date) VALUES ('%e', '%e', UNIX_TIMESTAMP())", GetName(playerid), text);
    mysql_tquery(mysql, query);
    return 1;
}

// Message to admins

SendToAdmins(color, Message[], lvl = 2)
{
    foreach(new i : Player)
    {
       if(Info[i][Level] >= lvl)
       SCM(i, color, Message);
    }
}

// IsNumeric

IsNumeric(string[])
{
    for (new i = 0, j = strlen(string); i < j; i++)
    {
    	if (string[i] > '9' || string[i] < '0') return 0;
    }
    return 1;
}

// Vehicle Model ID

ReturnVehicleModelID(Name[])
{
    for(new i; i != 211; i++) if(strfind(VehicleNames[i], Name, true) != -1) return i + 400;
    return INVALID_VEHICLE_ID;
}

// Spawn Vehciles

public SpawnVehicle(playerid,vehicleid)
{
    new Float:x, Float:y, Float:z, Float:angle, string[128];
    if(Info[playerid][SpawnedCars] >= MAX_CAR_SPAWNS) return SCM(playerid, red, "You have reached the maximum amount of vehicles");
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    Info[playerid][Cars][Info[playerid][SpawnedCars]] = CreateVehicle(vehicleid, x+3, y, z, angle, -1, -1, -1);
    SetVehicleVirtualWorld(Info[playerid][Cars][Info[playerid][SpawnedCars]], GetPlayerVirtualWorld(playerid));
    LinkVehicleToInterior(Info[playerid][Cars][Info[playerid][SpawnedCars]], GetPlayerInterior(playerid));
    Info[playerid][SpawnedCars]++;
    format(string,sizeof(string),"You have spawned a %s (Model ID: %d) [%d/%d]", VehicleNames[vehicleid-400],vehicleid,Info[playerid][SpawnedCars],MAX_CAR_SPAWNS);
    return SCM(playerid, lighterblue, string);
}

// Jail Player

public Unjail(playerid)
{
    KillTimer(JTimer[playerid]);
    TogglePlayerControllable(playerid,true);
    Info[playerid][Jailed] = 0;
    PlayerPlaySound(playerid,1057,0.0,0.0,0.0);
    SetSpawnInfo(playerid, NO_TEAM, GetPlayerSkin(playerid), 2229.6204, -1366.4111, 23.9922, 88.1277, 0, 0, 0, 0, 0, 0);
    PlayerTextDrawDestroy(playerid, TimeLeft[playerid]);
}

public JailPlayer(playerid)
{
	SpawnPlayer(playerid);
    SetPlayerPos(playerid,197.6661,173.8179,1003.0234);
    SetPlayerInterior(playerid,3);
    SetCameraBehindPlayer(playerid);
    ResetPlayerWeaponsEx(playerid);
}

public JailCountDown(playerid)
{
    JailCountDownFromAmount--;
    if(JailCountDownFromAmount == 0)
    {
    	JailCountDownFromAmount = 0;
        KillTimer(JailTimer[playerid]);
    }
    return 1;
}

// Give Vehicles

public GiveVehicle(playerid,vehicleid)
{
    if(!IsPlayerInAnyVehicle(playerid))
    {
        new Float:x, Float:y, Float:z, Float:angle,string[128];
        if(Info[playerid][LastSpawnedCar] >= 0 || Info[playerid][LastSpawnedCar] != INVALID_VEHICLE_ID )
        {
            DestroyVehicle(Info[playerid][LastSpawnedCar]);
        }
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, angle);
        new veh = CreateVehicle(vehicleid, x, y, z, angle, -1, -1, -1);
        SetVehicleVirtualWorld(veh, GetPlayerVirtualWorld(playerid));
        LinkVehicleToInterior(veh, GetPlayerInterior(playerid));
        PutPlayerInVehicle(playerid, veh, 0);
        Info[playerid][LastSpawnedCar] = veh;
        format(string,sizeof(string),"You have spawned a %s (Model ID: %d)", VehicleNames[vehicleid-400],vehicleid);
        return SCM(playerid, lighterblue, string);
    }
    return 1;
}

// For local chat

ProxDetector(Float:f_Radius, playerid, string[], color)
{
    new
        Float: f_playerPos[3];

    GetPlayerPos(playerid, f_playerPos[0], f_playerPos[1], f_playerPos[2]);
    foreach(new i : Player)
    {
        if(GetPlayerVirtualWorld(i) == GetPlayerVirtualWorld(playerid))
        {
            if(IsPlayerInRangeOfPoint(i, f_Radius / 16, f_playerPos[0], f_playerPos[1], f_playerPos[2])) {
                SCM(i, color, string);
            }
            else if(IsPlayerInRangeOfPoint(i, f_Radius / 8, f_playerPos[0], f_playerPos[1], f_playerPos[2])) {
                SCM(i, color, string);
            }
            else if(IsPlayerInRangeOfPoint(i, f_Radius / 4, f_playerPos[0], f_playerPos[1], f_playerPos[2])) {
                SCM(i, color, string);
            }
            else if(IsPlayerInRangeOfPoint(i, f_Radius / 2, f_playerPos[0], f_playerPos[1], f_playerPos[2])) {
                SCM(i, color, string);
            }
            else if(IsPlayerInRangeOfPoint(i, f_Radius, f_playerPos[0], f_playerPos[1], f_playerPos[2])) {
                SCM(i, color, string);
            }
        }
    }
    return 1;
}

// Use Marijuana

public Usedrugs(playerid)
{
    SetPlayerDrunkLevel(playerid, 0);
    SetPlayerWeather(playerid, 2);
    return 1;
}

// Weapon IDs

GetWeaponID(Name[])
{
    new weapname[40];
    for(new w = 1; w <= 46; w++)
    {
       if(w == 0 || w ==  19 || w == 20 || w == 21 || w ==44|| w == 45) continue;

       GetWeaponName(w, weapname, sizeof(weapname));
       if(strfind(weapname,Name,true) != -1) return w;
    }
    return false;
}

// Weapons stuff

stock PlayerHaveWeapon(playerid, _weaponid)
{
    const MAX_WEAPONS_SLOTS = 13;
    new ammo, weaponid;
    for (new i; i != MAX_WEAPONS_SLOTS; i++)
    {
        if (GetPlayerWeaponData(playerid, i, weaponid, ammo) == 0) return 0;
        if (weaponid == _weaponid) return 1;
    }
    return 0;
}

WeaponNames(id)
{
    new wn[32];
    switch(id)
    {
        case 0: wn = "Fist";
        case 1: wn = "Brass Knuckles";
        case 2: wn = "Golf Club";
        case 3: wn = "Nightstick";
        case 4: wn = "Knife";
        case 5: wn = "Baseball Bat";
        case 6: wn = "Shovel";
        case 7: wn = "Pool Cue";
        case 8: wn = "Katana";
        case 9: wn = "Chainsaw";
        case 10: wn = "Dildo";
        case 11: wn = "Dildo";
        case 12: wn = "Dildo";
        case 13: wn = "Dildo";
        case 14: wn = "Flowers";
        case 15: wn = "Cane";
        case 16: wn = "Grenade";
        case 18: wn = "Molotov";
        case 22: wn = "9mm";
        case 23: wn = "Silenced";
        case 24: wn = "Desert Eagle";
        case 25: wn = "Shotgun";
        case 26: wn = "Sawn-off";
        case 27: wn = "Combat Shotgun";
        case 28: wn = "Micro SMG";
        case 29: wn = "SMG";
        case 30: wn = "Ak47";
        case 31: wn = "M4";
        case 32: wn = "Tec 9";
        case 33: wn = "Rifle";
        case 34: wn = "Sniper";
        case 35: wn = "Rocket Launcher";
        case 37: wn = "Flame Thrower";
        case 38: wn = "Minigun";
        case 39: wn = "Satchel Charge";
        case 40: wn = "Detonator";
        case 41: wn = "Spray";
        case 42: wn = "Fire Extinguisher";
        case 46: wn = "Parachute";
    }
    return wn;
}

// Event System

public StartEvent()
{
    foreach(new i : Player)
    {
        if(InEvent[i] == 1)
        {
            GameTextForPlayer(i, "EVENT STARTED", 3000, 6);
            GivePlayerWeaponEx(i, eInfo[eWeapon1], 1000000);
            GivePlayerWeaponEx(i, eInfo[eWeapon2], 1000000);
            SetPlayerHealthEx(i, 100.0);
            SetPlayerArmourEx(i, 100.0);
        }
    }
    eInfo[EventStarted] = true;
}

// Radio System

public CustomR(playerid)
{
    new sStr[200], sStr2[200];
    format(sStr2, sizeof(sStr2), "{FFFFFF}Hello, %s\n{FFFFFF}Enter Link:", GetName(playerid));
    strcat(sStr, sStr2, sizeof(sStr));
    return ShowPlayerDialog(playerid, CRADIO, DIALOG_STYLE_INPUT, "{FFFFFF}Custom Radio", sStr, "Listen", "Close");
}

public Listen(playerid, Link[])
{
    new sStr[128];
    format(sStr, sizeof(sStr), "%s", Link);
    PlayAudioStreamForPlayer(playerid, Link);
    return 1;
}

// Object System

stock UpdateObjectInfoTextdraws(playerid, object, slot)
{
    new Float:Float[6],littlestr[24];
    if(object != 999 && slot != 999)
    {
        GetDynamicObjectPos(object, Float[0], Float[1], Float[2]);
        GetDynamicObjectRot(object, Float[3], Float[4], Float[5]);
    }
    else
    {
        SetPVarInt(playerid,"NoObject",1);
        for(new i = 0; i < sizeof(Float); i ++)
        Float[i] = 0.0;
    }

    format(littlestr, 24, "~g~X: ~l~%.2f",Float[0]);
    PlayerTextDrawSetString(playerid, objinfo[playerid][1],littlestr);
    format(littlestr, 24, "~g~Y: ~l~%.2f",Float[1]);
    PlayerTextDrawSetString(playerid, objinfo[playerid][2],littlestr);
    format(littlestr, 24, "~g~Z: ~l~%.2f",Float[2]);
    PlayerTextDrawSetString(playerid, objinfo[playerid][3],littlestr);

    format(littlestr, 24, "~b~SLOT: ~l~%d",slot);
    PlayerTextDrawSetString(playerid, objinfo[playerid][4],littlestr);

    if(object != 999 && slot != 999)
    format(littlestr, 24, "~b~MODEL: ~l~%d",objectmodel[slot]);

    else

    littlestr = "NULL";
    PlayerTextDrawSetString(playerid, objinfo[playerid][5],littlestr);

    format(littlestr, 24, "~g~RX: ~l~%.2f",Float[3]);
    PlayerTextDrawSetString(playerid, objinfo[playerid][6],littlestr);
    format(littlestr, 24, "~g~RY: ~l~%.2f",Float[4]);
    PlayerTextDrawSetString(playerid, objinfo[playerid][7],littlestr);
    format(littlestr, 24, "~g~RZ: ~l~%.2f",Float[5]);
    PlayerTextDrawSetString(playerid, objinfo[playerid][8],littlestr);

    if(object != 999 && slot != 999)
    msg = "NULL";
    PlayerTextDrawSetString(playerid, objinfo[playerid][24],msg);

    format(msg, 64, "~b~INDEX: ~l~%d",GetPVarInt(playerid,"SettingIdx"));
    PlayerTextDrawSetString(playerid, objinfo[playerid][17],msg);
    format(msg, 64, "~b~MODEL: ~l~%d",GetPVarInt(playerid,"SettingModel"));
    PlayerTextDrawSetString(playerid, objinfo[playerid][18],msg);
    new txd[24],txt[24];
    GetPVarString(playerid,"SettingTxd",txd,24);
    GetPVarString(playerid,"SettingTxt",txt,24);
    format(msg, 64, "~b~TXD: ~l~%s",txd);
    PlayerTextDrawSetString(playerid, objinfo[playerid][19],msg);
    format(msg, 64, "~b~TXT: ~l~%s",txt);
    PlayerTextDrawSetString(playerid, objinfo[playerid][20],msg);
    CheckForNextPrev(playerid);
    return 1;
}

stock CheckForNextPrev(playerid)
{
    if(GetPVarInt(playerid,"NoObject"))
    {
        PlayerTextDrawHide(playerid, objinfo[playerid][25]);
        return PlayerTextDrawHide(playerid, objinfo[playerid][16]);
    }

    new slot = GetPVarInt(playerid, "SelectedObject");
    for(new i = slot-1; i >= 0; i --)
    {
        if(objects[i] != -1  && IsValidDynamicObject(objects[i]))
        {
            slot = i;
            break;
        }
    }
    if(slot == GetPVarInt(playerid, "SelectedObject"))
    PlayerTextDrawHide(playerid, objinfo[playerid][25]);

    else

    PlayerTextDrawShow(playerid, objinfo[playerid][25]);

    slot = GetPVarInt(playerid, "SelectedObject");
    for(new i = slot+1; i < MAX_OBJECTS; i ++)
    {
        if(objects[i] != -1  && IsValidDynamicObject(objects[i]))
        {
            slot = i;
            break;
        }
    }

    if(slot == GetPVarInt(playerid, "SelectedObject"))
    PlayerTextDrawHide(playerid, objinfo[playerid][16]);

    else

    PlayerTextDrawShow(playerid, objinfo[playerid][16]);
    return 1;
}

stock DestroyObjectTextdraw(playerid)
{
    if(ObjTextdraw[playerid] != PlayerText:INVALID_TEXT_DRAW)
    PlayerTextDrawDestroy(playerid, ObjTextdraw[playerid]), _:ObjTextdraw[playerid] = _:INVALID_TEXT_DRAW;
    return 1;
}

stock ShowObjectTextdraw(playerid) return PlayerTextDrawShow(playerid, ObjTextdraw[playerid]);

stock CreateObjectTextdraw(playerid)
{
    if(ObjTextdraw[playerid] != PlayerText:INVALID_TEXT_DRAW)
    return 1;

    ObjTextdraw[playerid] = CreatePlayerTextDraw(playerid, 2.000000, 434.000000, " ");
    PlayerTextDrawBackgroundColor(playerid, ObjTextdraw[playerid], 255);
    PlayerTextDrawFont(playerid, ObjTextdraw[playerid], 1);
    PlayerTextDrawLetterSize(playerid, ObjTextdraw[playerid], 0.290000, 1.300000);
    PlayerTextDrawColor(playerid, ObjTextdraw[playerid], -1);
    PlayerTextDrawSetOutline(playerid, ObjTextdraw[playerid], 0);
    PlayerTextDrawSetProportional(playerid, ObjTextdraw[playerid], 1);
    PlayerTextDrawSetShadow(playerid, ObjTextdraw[playerid], 1);
    PlayerTextDrawUseBox(playerid, ObjTextdraw[playerid], 1);
    PlayerTextDrawBoxColor(playerid, ObjTextdraw[playerid], 170);
    PlayerTextDrawTextSize(playerid, ObjTextdraw[playerid], 990.000000, 180.000000);
    return 1;
}

stock ApplyDynamicObjectMaterial(object,slot,index)
{
    new integer,strings[2][16],hex;
    if(index == 0) sscanf(objectmatinfo[slot][0],"is[16]s[16]h",integer,strings[0],strings[1],hex);
    else if(index == 1) sscanf(objectmatinfo[slot][1],"is[16]s[16]h",integer,strings[0],strings[1],hex);
    else if(index == 2) sscanf(objectmatinfo[slot][2],"is[16]s[16]h",integer,strings[0],strings[1],hex);
    SetDynamicObjectMaterial(object,index,integer,strings[0],strings[1],hex);
    return 1;
}

stock UpdateObjectTextdraw(playerid, const str2[] = "_")
{
    new bigmsg[230];
    if(GetPVarInt(playerid, "SelectedObject") != -1)
    {
        new slot = GetPVarInt(playerid, "SelectedObject");
        new Float:Float[6];
        GetDynamicObjectPos(objects[slot],Float[0],Float[1],Float[2]);
        GetDynamicObjectRot(objects[slot],Float[3],Float[4],Float[5]);
        format(bigmsg,256,"  ~y~Slot: ~w~%d  ~y~Model: ~w~%d           ~p~X: ~w~%.1f ~p~Y: ~w~%.1f ~p~Z: ~w~%.1f       ~p~RX: ~w~%.1f ~p~RY: ~w~%.1f ~p~RZ: ~w~%.1f       ~r~%s",
        slot,objectmodel[slot],Float[0],Float[1],Float[2],Float[3],Float[4],Float[5],str2);
    }
    else
    bigmsg = "                          You are on ~y~object selection mode~w~.    Click in ~y~any object~w~ to begin with the ~y~object edition system~w~.";
    PlayerTextDrawSetString(playerid, ObjTextdraw[playerid], bigmsg);
    return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    if(!IsValidDynamicObject(objectid)) return 0;

    switch(response)
    {
        case EDIT_RESPONSE_CANCEL:
        {
            if(!GetPVarInt(playerid,"Modifying"))
            {
                SCM(playerid, red, "You have canceled the object edition, you're no longer on edition mode");
                OnObjectEditMode(playerid, false);
                CancelEdit(playerid);
            }
            DeletePVar(playerid,"Modifying");
        }
        case EDIT_RESPONSE_FINAL:
        {
            if(!GetPVarInt(playerid,"Modifying"))
            {
                SetDynamicObjectPos(objectid, x, y, z);
                SetDynamicObjectRot(objectid, rx, ry, rz);
                SCM(playerid, green, "Saved");
                UpdateObjectTextdraw(playerid);
                SelectObject(playerid);
                OnObjectEditMode(playerid, false);
            }
        }
        case EDIT_RESPONSE_UPDATE:
        {
            if(!GetPVarInt(playerid,"Modifying"))
            {
                MoveDynamicObject(objectid, x, y, z, 100000, rx, ry, rz);
                UpdateObjectTextdraw(playerid,"Edit Mode");
                UpdateObjectInfoTextdraws(playerid, objectid, GetPVarInt(playerid,"SelectedObject"));
            }
        }
    }
    return 0;
}

public OnPlayerSelectDynamicObject(playerid, objectid, modelid, Float:x, Float:y, Float:z)
{
    new slot = -5;
    for(new h; h < MAX_OBJECTS; h++)
    {
        if(objects[h] == objectid)
        {
            slot = h;
            break;
        }
    }

    if(slot == -5) return SCM(playerid, red, "That's not your object");

    format(msg, sizeof(msg),"%d",slot);
    cmd_oedit(playerid,msg);
    OnObjectEditMode(playerid,true);
    UpdateObjectTextdraw(playerid);
    return 0;
}

stock OnObjectEditMode(playerid, bool:mode)
{
    if(mode == true)
    {
        if(IsPlayerEdittingObject(playerid))
        {
            UpdateObjectTextdraw(playerid);
            return 0;
        }

        SetPVarInt(playerid,"OnObjectEditMode",1);
        UpdateObjectTextdraw(playerid);
        return 1;
    }
    else
    {
        if(!IsPlayerEdittingObject(playerid)) return 0;
        SetPVarInt(playerid,"OnObjectEditMode",0);
        return 1;
    }
}

stock IsPlayerEdittingObject(playerid)
{
    return GetPVarInt(playerid,"OnObjectEditMode");
}

stock SaveMap(playerid, mapname[])
{
    new query[1600], totalobjects = 0;

    new Float:x, Float:y, Float:z,
        Float:rx, Float:ry, Float:rz;

    for(new i; i < MAX_OBJECTS; i ++)
    {
        if(IsValidDynamicObject(objects[i]))
        {
            GetDynamicObjectPos(objects[i],x,y,z);
            GetDynamicObjectRot(objects[i],rx,ry,rz);

            mysql_format(mysql, query, sizeof(query), 
            "INSERT INTO `Maps` (MapName, objectID, objectX, objectY, objectZ, objectRX, objectRY, objectRZ, objectMatInfo1, objectMatInfo2, objectMatInfo3)\
            VALUES ('%e', %i, %f, %f, %f, %f, %f, %f, '%e', '%e', '%e')",
            mapname, objectmodel[i], x, y, z, rx, ry, rz, objectmatinfo[i][0], objectmatinfo[i][1], objectmatinfo[i][2]);
            mysql_tquery(mysql, query);
            totalobjects++;
        }
    }

    if(totalobjects == 0) return SCM(playerid, red, "You must have atleast one object to save a map");

    format(msg, sizeof(msg),"Map has been saved as '%s', Use /loadmap to load it whenever you want",mapname);
    SCM(playerid, green, msg);
    return 1;
}
 
stock UpdateNearPlayers(playerid)
{
    new Float:x,Float:y,Float:z;
    GetPlayerPos(playerid, x,y,z);
    foreach(new i : Player)
    {
        if(IsPlayerConnected(i))
        {
            if(IsPlayerInRangeOfPoint(i, 200, x, y, z))
            {
                Streamer_Update(i);
            }
        }
    }
    return 1;
}

stock GetObjectSlot(object)
{
    if(!IsValidDynamicObject(object)) return -1;
    new slt = -1;

    for(new i = 0; i < MAX_OBJECTS; i ++)
    {
        if(object == objects[i])
        {
            return i;
        }
    }
    return slt;
}

stock ProcessFloat(Float:floatp)
{
    new procss[12];
    if(floatp >= 0.0) format(procss, sizeof(procss),"+%.1f",floatp);
    else format(procss, sizeof(procss),"%.1f",floatp);
    return procss;
}

stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
    new Float:a;
    GetPlayerPos(playerid, x, y, a);
    GetPlayerFacingAngle(playerid, a);
    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));
}

// DM System

new msgbox[3][128];
stock UpdateTeleportInfo(playerid, string[])
{
    new tdmsg[500];
    format(msgbox[2], 128, "%s", msgbox[1]);
    format(msgbox[1], 128, "%s", msgbox[0]);
    format(msgbox[0], 128, "~g~%s(%d) ~w~%s", GetName(playerid), playerid, string);
    new line[10];
    line = "~n~~n~";
    format(tdmsg, sizeof(tdmsg), "%s%s%s%s%s", msgbox[0], line, msgbox[1], line, msgbox[2]);
    TextDrawSetString(Textdraw10, tdmsg);
    TextDrawShowForAll(Textdraw10);
    return 1;
}

stock SetPlayerPosition(playerid, Float:X, Float:Y, Float:Z, Float:A)
{
    if(InDerby[playerid] == 0 && InTDM[playerid] == 0)
    {
        TogglePlayerControllable(playerid, 0);
        SetPlayerPos(playerid, X, Y, Z);
        SetPlayerFacingAngle(playerid, A);
        SetCameraBehindPlayer(playerid);
        SetTimerEx("UnFreezePosition", 5000, false, "i", playerid);
    }
    else
    {
        SetPlayerPos(playerid, X, Y, Z);
        SetPlayerFacingAngle(playerid, A);
        SetCameraBehindPlayer(playerid);
    }
}

function UnFreezePosition(playerid)
{
    return TogglePlayerControllable(playerid, 1);
}

stock CreateDM(playerid,Float:X,Float:Y,Float:Z,Float:A,interior,virtualworld,zone,weapondm1,weapondm2,health,text[])
{
    Info[playerid][InDM] = 1;
    Info[playerid][DMZone] = zone;

    if(IsPlayerInAnyVehicle(playerid)) RemovePlayerFromVehicle(playerid);
    SetPlayerPos(playerid, X,Y,Z);
    SetPlayerFacingAngle(playerid, A);
    SetPlayerInterior(playerid, interior);
    GameTextForPlayer(playerid, text, 2000, 3);
    SetPlayerFacingAngle(playerid, A);
    SetPlayerHealthEx(playerid, health);
    SetPlayerArmourEx(playerid, 100);
    ResetPlayerWeaponsEx(playerid);
    GivePlayerWeaponEx(playerid, weapondm1, 100000);
    GivePlayerWeaponEx(playerid, weapondm2, 100000);
    SetPlayerVirtualWorld(playerid, virtualworld);
    return 1;
}

stock RespawnInDM(playerid)
{
    GotJetpack[playerid] = 0;
    switch(Info[playerid][DMZone])
    {
        case 1:
        {
            new Random = random(sizeof(RandomSpawnsDE));
            CreateDM(playerid,RandomSpawnsDE[Random][0], RandomSpawnsDE[Random][1], RandomSpawnsDE[Random][2], RandomSpawnsDE[Random][3],3,1,1,24,24,100,"");
            return 1;
        }
        case 2:
        {
            new Random = random(sizeof(RandomSpawnsMicro));
            CreateDM(playerid,RandomSpawnsMicro[Random][0], RandomSpawnsMicro[Random][1], RandomSpawnsMicro[Random][2], RandomSpawnsMicro[Random][3],1,2,2,28,28,100,"");
            return 1;
        }
        case 3:
        {
            new Random = random(sizeof(RandomSpawnsMinigun));
            CreateDM(playerid,RandomSpawnsMinigun[Random][0], RandomSpawnsMinigun[Random][1], RandomSpawnsMinigun[Random][2], RandomSpawnsMinigun[Random][3],10,3,3,38,38,100,"");
            return 1;
        }
        case 4:
        {
            new Random = random(sizeof(RandomSpawnsM4));
            CreateDM(playerid,RandomSpawnsM4[Random][0], RandomSpawnsM4[Random][1], RandomSpawnsM4[Random][2], RandomSpawnsM4[Random][3],3,4,4,31,31,100,"");
            return 1;
        }
        case 5:
        {
            new Random = random(sizeof(RandomSpawnsSawns));
            CreateDM(playerid,RandomSpawnsSawns[Random][0], RandomSpawnsSawns[Random][1], RandomSpawnsSawns[Random][2], RandomSpawnsSawns[Random][3],0,5,5,26,26,100,"");
            return 1;
        }
        case 6:
        {
            new Random = random(sizeof(RandomSpawnsCombat));
            CreateDM(playerid,RandomSpawnsCombat[Random][0], RandomSpawnsCombat[Random][1], RandomSpawnsCombat[Random][2], RandomSpawnsCombat[Random][3],1,6,6,27,27,100, "");
            return 1;
        }
        case 7:
        {
            new Random = random(sizeof(RandomSpawnsSniper));
            CreateDM(playerid,RandomSpawnsSniper[Random][0], RandomSpawnsSniper[Random][1], RandomSpawnsSniper[Random][2], RandomSpawnsSniper[Random][3],0,7,7,34,34,100,"");
            return 1;
        }
        case 8:
        {
            new Random = random(sizeof(RandomSpawnsJetpack));
            CreateDM(playerid,RandomSpawnsJetpack[Random][0], RandomSpawnsJetpack[Random][1], RandomSpawnsJetpack[Random][2], RandomSpawnsJetpack[Random][3],0,8,8,28,28,100,"");
            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
            GotJetpack[playerid] = 1;
            return 1;
        }
    }
    return 1;
}

// XP System

LevelUp(playerid) // Much thanks to Konstantinos.
{
    new LU_xLevel = Info[playerid][xLevel], LU_XP = Info[playerid][XP];
    
    if ((LU_XP -= LU_xLevel == 1 ? 2000 : 2000 + (++LU_xLevel - 2) * 400) < 0) return 0;

    Info[playerid][xLevel]++;
    Info[playerid][XP] = 0;
    LevelName(playerid);
    return 1;
}

LevelName(playerid)
{
    new string[100];
    for(new i; i < sizeof(LevelArray); i++)
    {
        if(Info[playerid][xLevel] == LevelArray[i][titleLevel])
        {
            format(string, sizeof(string), "You have reached level %i!", LevelArray[i][titleLevel]);
            SCM(playerid, 0x9999FFFF, string);

            format(string, sizeof(string), "You have unlocked a new title: %s", LevelArray[i][Title]);
            SCM(playerid, 0x9999FFFF, string);
        }
    }
    return 1;
}

// Real Clocks

public UpdateTimeAndWeather()
{
    if(!worldtime_override) 
    {
        gettime(serverhour, serverminute);
    } 
    else 
    {
        serverhour = worldtime_overridehour;
        serverminute = worldtime_overridemin;
    }

    format(timestr,32,"%02d:%02d",serverhour,serverminute);
    TextDrawSetString(ServerTime,timestr);
    SetWorldTime(serverhour);
    
    foreach(new x : Player)
    {
        SetPlayerTime(x, serverhour, serverminute);
    }
}

// Near Vehicle

GetClosestVehicle(playerid)
{
    new Float:x, Float:y, Float:z;
    new Float:dist, Float:closedist=9999, closeveh;
    for(new i=1; i < MAX_VEHICLES; i++)
    {
        if(GetVehiclePos(i, x, y, z))
        {
            dist = GetPlayerDistanceFromPoint(playerid, x, y, z);
            if(dist < closedist)
            {
                closedist = dist;
                closeveh = i;
            }
        }
    }
    return closeveh;
}

// Split chat

SendMessage(color, message[], length_1 = 100)
{
    new length_2 = strlen(message);
    if(length_2 <= length_1)
    {
        SendClientMessageToAll(color, message);
    }
    else
    {
        new string[144], last_space, escape = floatround(length_1 / 1.2);
        while(length_2 > length_1)
        {
            strcpy(string, message, 144);

            for(new i = 0; i <= length_2; i ++)
            {
                if(message[i] == ' ' && i <= length_1)
                {
                    last_space = i;
                }

                if(i > length_1)
                {
                    i = length_2;
                }
            }

            if(!last_space)
            {
                strdel(string, length_1, strlen(string));
                strdel(message, 0, length_1);

                length_2 -= length_1;
            }
            else if(last_space < escape)
            {
                strdel(string, escape, strlen(string));
                strdel(message, 0, escape);

                length_2 -= escape;
                last_space = 0;
            }
            else 
            {
                strdel(string, last_space, strlen(string));
                strdel(message, 0, (last_space + 1));

                length_2 -= last_space;
                last_space = 0;
            }

            SendClientMessageToAll(color, message);

            if(length_2 < length_1)
            {
                SendClientMessageToAll(color, message);
            }
        }
    }
    return 1;
}

stock SendClientM(playerid, color, message[], length_1 = 100)
{
    new length_2 = strlen(message);
    if(length_2 <= length_1)
    {
        SendClientMessage(playerid, color, message);
    }
    else
    {
        new string[144], last_space, escape = floatround(length_1 / 1.2);
        while(length_2 > length_1)
        {
            strcpy(string, message, 144);

            for(new i = 0; i <= length_2; i ++)
            {
                if(message[i] == ' ' && i <= length_1)
                {
                    last_space = i;
                }

                if(i > length_1)
                {
                    i = length_2;
                }
            }

            if(!last_space)
            {
                strdel(string, length_1, strlen(string));
                strdel(message, 0, length_1);

                length_2 -= length_1;
            }
            else if(last_space < escape)
            {
                strdel(string, escape, strlen(string));
                strdel(message, 0, escape);

                length_2 -= escape;
                last_space = 0;
            }
            else 
            {
                strdel(string, last_space, strlen(string));
                strdel(message, 0, (last_space + 1));

                length_2 -= last_space;
                last_space = 0;
            }

            SendClientMessage(playerid, color, string);

            if(length_2 < length_1)
            {
                SendClientMessage(playerid, color, message);
            }
        }
    }
    return 1;
}

// Unmute player

public UnmutePlayer(playerid)
{
    if(IsPlayerConnected(playerid))
    {
        KillTimer(MuteTimer[playerid]);
        Info[playerid][Muted] = 0;
        MuteCounter[playerid] = 0;
        SCM(playerid, red, "You have been unmuted");
    }
}

// Money Bag

public MoneyBag()
{
    new string[128];
    if(!MoneyBagFound)
    {
        format(string, sizeof(string), "Money bag spawned at {FF5050}%s {00FFFF}Find it and earn some money!", MoneyBagLocation);
        SendClientMessageToAll(0x00FFFFFF, string);
    }
    else if(MoneyBagFound)
    {
        MoneyBagFound = 0;
        new randombag = random(sizeof(MBSPAWN));
        MoneyBagPos[0] = MBSPAWN[randombag][XPOS];
        MoneyBagPos[1] = MBSPAWN[randombag][YPOS];
        MoneyBagPos[2] = MBSPAWN[randombag][ZPOS];
        format(MoneyBagLocation, sizeof(MoneyBagLocation), "%s", MBSPAWN[randombag][Position]);
        format(string, sizeof(string), "Money bag spawned at {FF5050}%s {00FFFF}Find it and earn some money!", MoneyBagLocation);
        SendClientMessageToAll(0x00FFFFFF, string);
        MoneyBagPickup = CreateDynamicPickup(1550, 2, MoneyBagPos[0], MoneyBagPos[1], MoneyBagPos[2], 0, 0);
    }
    return 1;
}

// Bounty System

public HideText()
{
    TextDrawHideForAll(BText);
    TextDrawHideForAll(BBounty);
    TextDrawHideForAll(BBox);
    return 1;
}

public HidePayout(playerid)
{
    PlayerTextDrawHide(playerid, PlayerText:BPayout[playerid]);
    return 1;
}

// Random Number

randomEx(min, max)
{
    new rand = random(max-min)+min;
    return rand;
}

// Cancel Vote [Premium]

public CancelVote()
{
    if(OnVote == 0) return 0;

    new str[128];
    foreach(new i : Player) Voted[i] = -1;

    format(str, sizeof(str), "Vote: %s is OVER!", Voting[Vote]);
    SendClientMessageToAll(green, str);

    format(str, sizeof(str), "Yes: %d No: %d", Voting[VoteY], Voting[VoteN]);
    SendClientMessageToAll(green, str);

    OnVote = 0;
    Voting[VoteY] = 0;
    Voting[VoteN] = 0;
    return 1;
}

//MySQL System

stock SavePlayerData(playerid, registered, logged, closemysql = 0)
{
    new query[1000], weaponid, ammo, ps = GetPlayerState(playerid);
    if(Info[playerid][Logged] == 1 && ps != PLAYER_STATE_WASTED && ps != PLAYER_STATE_SPECTATING)
    {
        new Float:px, Float:py, Float:pz, Float:xHP, Float:xArmour;
        GetPlayerPos(playerid, px, py, pz);
        GetPlayerHealth(playerid, xHP);
        GetPlayerArmour(playerid, xArmour);
        GetPlayerIp(playerid, Info[playerid][IP], 16);

        Info[playerid][PlayerTeam] = pTeam[playerid];
        Info[playerid][Money] = GetPlayerCash(playerid);
        Info[playerid][FightStyle] = GetPlayerFightingStyle(playerid);
        Info[playerid][Skin] = GetPlayerSkin(playerid);
        Info[playerid][Interior] = GetPlayerInterior(playerid);
        Info[playerid][pHealth] = xHP;
        Info[playerid][pArmour] = xArmour;

        if(Info[playerid][InDM] == 1 || InEvent[playerid] == 1 || InDerby[playerid] == 1 || InTDM[playerid] == 1 || InParkour[playerid] == 1 || InSkydive[playerid] == 1 || InDuel[playerid] == 1)
        {
            Info[playerid][PosX] = LastPosX[playerid];
            Info[playerid][PosY] = LastPosY[playerid];
            Info[playerid][PosZ] = LastPosZ[playerid];
            Info[playerid][pHealth] = LastHealth[playerid];
            Info[playerid][pArmour] = LastArmour[playerid];
            Info[playerid][Interior] = LastInterior[playerid];
        }

        if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
        {
            Info[playerid][PosX] = px;
            Info[playerid][PosY] = py;
            Info[playerid][PosZ] = pz;
        }

        if(Info[playerid][InDM] == 0 && InEvent[playerid] == 0 && InDerby[playerid] == 0 && InTDM[playerid] == 0 && InParkour[playerid] == 0 && InSkydive[playerid] == 0 && InDuel[playerid] == 0)
        {
            for(new i; i < 13; i++)
            {
                GetPlayerWeaponData(playerid, i, weaponid, ammo); 

                if(!weaponid) continue;

                mysql_format(mysql, query, sizeof(query), "INSERT INTO `Weapons` (ID, Weapon, Ammo) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE `Ammo` = %d", Info[playerid][ID], weaponid, ammo, ammo);
                mysql_tquery(mysql, query);
            }
        }

        mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `LastSeen` = UNIX_TIMESTAMP(), `IP` = '%e', `AutoLogin` = %i, `Level` = %i, `Money` = %i, `UGC` = %i, `Kills` = %i,\
        `Deaths` = %i, `Suicides` = %i, `Hours` = %i, `Minutes` = %i, `Seconds` = %i, `Marijuana` = %i, `Seeds` = %i, `Cocaine` = %i, `Premium` = %i, `PremiumExpires` = %i, `FightStyle` = %i,\
        `xLevel` = %i, `XP` = %i, `Muted` = %i, `Hitman` = %i, `gSkills` = %i, `bSkills` = %i, `vSkills` = %i, `aSkills` = %i, `rSkills` = %i, `tSkills` = %i, `mSkills` = %i, `dSkills` = %i,\
        `PlayerTeam` = %i, `MoneyBags` = %i, `Skin` = %i, `PosX` = %f, `PosY` = %f, `PosZ` = %f, `Interior` = %i, `Health` = %f, `Armour` = %f, `Jetpack` = %i, `JetpackExpire` = %i,\
        `Friends` = %i, `Vehicles` = %i, `InHouse` = %i, `PlayerColor` = '%e', `TextColor` = '%e', `MapHide` = %i  WHERE `ID` = %d",
        Info[playerid][IP], Info[playerid][AutoLogin], Info[playerid][Level], Info[playerid][Money], Info[playerid][UGC], Info[playerid][Kills], Info[playerid][Deaths], Info[playerid][Suicides], Info[playerid][Hours], 
        Info[playerid][Minutes], Info[playerid][Seconds], Info[playerid][Marijuana], Info[playerid][Seeds], Info[playerid][Cocaine], Info[playerid][Premium], Info[playerid][PremiumExpires], Info[playerid][FightStyle], 
        Info[playerid][xLevel], Info[playerid][XP], MuteCounter[playerid], Info[playerid][Hitman], Info[playerid][Skills][GROVE], Info[playerid][Skills][BALLAS], Info[playerid][Skills][VAGOS], Info[playerid][Skills][AZTECAS], 
        Info[playerid][Skills][BIKERS], Info[playerid][Skills][TRIADS], Info[playerid][Skills][MAFIA], Info[playerid][Skills][NANG], Info[playerid][PlayerTeam], Info[playerid][MoneyBags], Info[playerid][Skin], Info[playerid][PosX],
        Info[playerid][PosY], Info[playerid][PosZ], Info[playerid][Interior], Info[playerid][pHealth], Info[playerid][pArmour], Info[playerid][Jetpack], Info[playerid][JetpackExpire], Info[playerid][Friends], Info[playerid][vehLimit], 
        InHouse[playerid], Info[playerid][playerColor], Info[playerid][textColor], Info[playerid][MapHide], Info[playerid][ID]);
        mysql_tquery(mysql, query);

        Info[playerid][Registered] = registered;
        Info[playerid][Logged] = logged;
    }
    if(closemysql == 1) mysql_close(mysql);
    return true;
}

public OnAccountCheck(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    if(rows)
    {
        new ip[16], query[128];

        GetPlayerIp(playerid, ip, sizeof(ip));

        cache_get_field_content(0, "IP", Info[playerid][IP]);
        Info[playerid][AutoLogin] = cache_get_field_content_int(0, "AutoLogin");

        if(!strcmp(ip, Info[playerid][IP]) && Info[playerid][AutoLogin] == 1)
        {
            mysql_format(mysql, query, sizeof(query), "SELECT * FROM `playersdata` WHERE `PlayerName` = '%e' LIMIT 1", GetName(playerid));
            mysql_tquery(mysql, query, "OnAccountLoad", "i", playerid);
        }
        else 
        { 
            cache_get_field_content(0, "Password", Info[playerid][Password], mysql, 129);
            Info[playerid][ID] = cache_get_field_content_int(0, "ID");
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "{FFFFFF}Welcome back to {9966FF}Explosive Freeroam\n\n{FF0066}Type your password below to login to your game account", "Login", "Quit");
        }
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "{FFFFFF}Welcome to {9966FF}Explosive Freeroam\n\n{FF0066}Type your password below to register game account", "Register", "Quit");
    }
    return true;
}

public OnAccountLoad(playerid)
{
    Info[playerid][Logged] = 0;

    Info[playerid][ID] = cache_get_field_content_int(0,"ID");
    Info[playerid][Level] = cache_get_field_content_int(0, "Level");
    Info[playerid][Money] = cache_get_field_content_int(0, "Money");
    Info[playerid][UGC] = cache_get_field_content_int(0, "UGC");
    Info[playerid][Kills] = cache_get_field_content_int(0, "Kills");
    Info[playerid][Deaths] = cache_get_field_content_int(0, "Deaths");
    Info[playerid][Hours] = cache_get_field_content_int(0, "Hours");
    Info[playerid][Minutes] = cache_get_field_content_int(0, "Minutes");
    Info[playerid][Seconds] = cache_get_field_content_int(0, "Seconds");
   	Info[playerid][Muted] = cache_get_field_content_int(0, "Muted");
    Info[playerid][Marijuana] = cache_get_field_content_int(0, "Marijuana");
    Info[playerid][Seeds] = cache_get_field_content_int(0, "Seeds");
    Info[playerid][Cocaine] = cache_get_field_content_int(0, "Cocaine");
    Info[playerid][Premium] = cache_get_field_content_int(0, "Premium");
    Info[playerid][PremiumExpires] = cache_get_field_content_int(0, "PremiumExpires");
    Info[playerid][NameChange] = cache_get_field_content_int(0, "NameChange");
    Info[playerid][FightStyle] = cache_get_field_content_int(0, "FightStyle");
    Info[playerid][xLevel] = cache_get_field_content_int(0, "xLevel");
    Info[playerid][XP] = cache_get_field_content_int(0, "XP");
    MuteCounter[playerid] = cache_get_field_content_int(0, "Muted");
    Info[playerid][Hitman] = cache_get_field_content_int(0, "Hitman");
    Info[playerid][Skills][GROVE] = cache_get_field_content_int(0, "gSkills");
    Info[playerid][Skills][BALLAS] = cache_get_field_content_int(0, "bSkills");
    Info[playerid][Skills][VAGOS] = cache_get_field_content_int(0, "vSkills");
    Info[playerid][Skills][AZTECAS] = cache_get_field_content_int(0, "aSkills");
    Info[playerid][Skills][BIKERS] = cache_get_field_content_int(0, "rSkills");
    Info[playerid][Skills][TRIADS] = cache_get_field_content_int(0, "tSkills");
    Info[playerid][Skills][MAFIA] = cache_get_field_content_int(0, "mSkills");
    Info[playerid][Skills][NANG] = cache_get_field_content_int(0, "dSkills");
    Info[playerid][PlayerTeam] = cache_get_field_content_int(0, "PlayerTeam");
    Info[playerid][Skin] = cache_get_field_content_int(0, "Skin");
    Info[playerid][PosX] = cache_get_field_content_float(0, "PosX");
    Info[playerid][PosY] = cache_get_field_content_float(0, "PosY");
    Info[playerid][PosZ] = cache_get_field_content_float(0, "PosZ");
    Info[playerid][Interior] = cache_get_field_content_int(0, "Interior");
    Info[playerid][pHealth] = cache_get_field_content_float(0, "Health");
    Info[playerid][pArmour] = cache_get_field_content_float(0, "Armour");
    Info[playerid][Jetpack] = cache_get_field_content_int(0, "Jetpack");
    Info[playerid][JetpackExpire] = cache_get_field_content_int(0, "JetpackExpire");
    Info[playerid][Jump] = cache_get_field_content_int(0, "Jump");
    Info[playerid][JumpExpire] = cache_get_field_content_int(0, "JumpExpire");
    Info[playerid][Friends] = cache_get_field_content_int(0, "Friends");
    Info[playerid][vehLimit] = cache_get_field_content_int(0, "Vehicles");
    InHouse[playerid] = cache_get_field_content_int(0, "InHouse");
    cache_get_field_content(0, "PlayerColor", Info[playerid][playerColor], mysql, 16);
    cache_get_field_content(0, "TextColor", Info[playerid][textColor], mysql, 16);
    Info[playerid][MapHide] = cache_get_field_content_int(0, "MapHide");
    cache_get_field_content(0, "Email", Info[playerid][Email], mysql, 35);



    new query[100];
    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `Vehicles` WHERE `vehOwner` = '%e'", GetName(playerid));
    mysql_tquery(mysql, query, "LoadPlayerVehicles", "i", playerid);

    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `Attachments` WHERE `ID` = %d", Info[playerid][ID]);
    mysql_tquery(mysql, query, "OnAttachmentLoad", "i", playerid);

    mysql_format(mysql, query, sizeof(query), "SELECT `Weapon`, `Ammo` FROM `Weapons` WHERE `ID` = %d", Info[playerid][ID]);
    mysql_tquery(mysql, query, "OnWeaponLoad", "i", playerid);

    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `FriendsData` WHERE `ID` = %d", Info[playerid][ID]);
    mysql_tquery(mysql, query, "OnFriendsLoad", "i", playerid);

    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `OfflinePMs` WHERE `PlayerName` = '%e'", GetName(playerid));
    mysql_tquery(mysql, query, "OnOfflinePMsLoad", "i", playerid);


    GivePlayerCash(playerid, Info[playerid][Money]);
    SetPlayerFightingStyle(playerid, Info[playerid][FightStyle]);

    if(MuteCounter[playerid] != 0) MuteTimer[playerid] = SetTimerEx("UnmutePlayer", MuteCounter[playerid]*1000, true, "i", playerid), Info[playerid][Muted] = 1;

    pTeam[playerid] = Info[playerid][PlayerTeam];

    if(pTeam[playerid] != NO_TEAM)
    {
        gTeamCount[pTeam[playerid]] ++;
        UpdateTeamLabel(pTeam[playerid]);
    }

    if(Info[playerid][AutoLogin] == 1) SCM(playerid, green, "You have automatically logged in!");

    TogglePlayerSpectating(playerid, false);
    SetSpawnInfo(playerid, NO_TEAM, Info[playerid][Skin], Info[playerid][PosX], Info[playerid][PosY], Info[playerid][PosZ], 0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
    SetPlayerInterior(playerid, Info[playerid][Interior]);
    SetPlayerHealthEx(playerid, Info[playerid][pHealth]);
    SetPlayerArmourEx(playerid, Info[playerid][pArmour]);

    PlayerTextDrawDestroy(playerid, Background);
    PlayerTextDrawDestroy(playerid, Middle);
    PlayerTextDrawDestroy(playerid, ServerName);
    PlayerTextDrawDestroy(playerid, ServerTitle);
    PlayerTextDrawDestroy(playerid, Bottom);
    PlayerTextDrawDestroy(playerid, Middle2);
    TextDrawShowForPlayer(playerid, WebsiteTD);
    TextDrawShowForPlayer(playerid, ServerTime);
    TextDrawShowForPlayer(playerid, Textdraw0);
    TextDrawShowForPlayer(playerid, Textdraw1);
    TextDrawShowForPlayer(playerid, Textdraw2);
    TextDrawShowForPlayer(playerid, Textdraw3);
    TextDrawShowForPlayer(playerid, Textdraw4);
    TextDrawShowForPlayer(playerid, Textdraw5);
    TextDrawShowForPlayer(playerid, Textdraw6);
    TextDrawShowForPlayer(playerid, Textdraw7);
    TextDrawShowForPlayer(playerid, Textdraw8);
    TextDrawShowForPlayer(playerid, Textdraw9);
    TextDrawShowForPlayer(playerid, Textdraw10);
    TextDrawShowForPlayer(playerid, Textdraw11);
    TextDrawShowForPlayer(playerid, Textdraw12);
    TextDrawShowForPlayer(playerid, Textdraw13);
    TextDrawShowForPlayer(playerid, Textdraw14);
    TextDrawShowForPlayer(playerid, Textdraw15);

    printf("Data Loaded - Player %s", GetName(playerid));
    return 1;
}

public OnAccountRegister(playerid)
{
    Info[playerid][ID] = cache_insert_id();
    printf("New account registered. Database ID: [%d]", Info[playerid][ID]);

    TogglePlayerSpectating(playerid, false);
    Info[playerid][Registered] = 1;
    Info[playerid][xLevel] = 1;
    pTeam[playerid] = NO_TEAM;

    format(Info[playerid][playerColor], 16, "0xFFFFFFFF");
    format(Info[playerid][textColor], 16, "FFFFFF");

    new query[94];
    format(query, sizeof(query), "{FF0000}<!> {CC6699}%s has registered to the server! Total players registered - %s", GetName(playerid), cNumber(Info[playerid][ID]));
    SendClientMessageToAll(red, query);
    return true;
}

function PlayerTimer(playerid)
{
    if(IsPlayerSpawned(playerid))
    {
        Info[playerid][Seconds]++;
        if(Info[playerid][Seconds] == 60)
        {
            Info[playerid][Seconds] = 0;
            Info[playerid][Minutes]++;
            if(Info[playerid][Minutes] == 60)
            {
                Info[playerid][Minutes] = 0;
                Info[playerid][Hours]++;
            }
        }

        if (pProtectTick[playerid] > 0)
        {
            pProtectTick[playerid]--;

            if (!pProtectTick[playerid])
            {
                SetPlayerHealthEx(playerid, 100.0);
            }
        }
    }
    return 1;
}

AccountExists(const str[])
{
    new query[85], Cache:result;
    mysql_format(mysql, query, sizeof(query), "SELECT `ID` FROM `playersdata` WHERE `PlayerName` = '%e' LIMIT 1",str);
    result = mysql_query(mysql, query);

    new rows = cache_get_row_count();
    cache_delete(result);
    if(rows > 0)
    {
        return 1;
    }
    return rows;
}

MapExists(const str[])
{
    new query[85], Cache:result;
    mysql_format(mysql, query, sizeof(query), "SELECT `MapName` FROM `Maps` WHERE `MapName` = '%e' LIMIT 1", str);
    result = mysql_query(mysql, query);
 
    new rows = cache_get_row_count();
    cache_delete(result);
    if(rows > 0) 
    {
        return 1;
    }
    return 0;
}

function OnMapsLoad(playerid)
{
    new rows = cache_num_rows();

    new Float:x, Float:y, Float:z,
        Float:rx, Float:ry, Float:rz;

    new objectID, matInfo[3][64];

    if(rows)
    {
        for(new i; i < rows; i++)
        {
            objectID = cache_get_field_content_int(i, "objectID");
            x = cache_get_field_content_float(i, "objectX");
            y = cache_get_field_content_float(i, "objectY");
            z = cache_get_field_content_float(i, "objectZ");
            rx = cache_get_field_content_float(i, "objectRX");
            ry = cache_get_field_content_float(i, "objectRY");
            rz = cache_get_field_content_float(i, "objectRZ");
            cache_get_field_content(i, "objectMatInfo1", matInfo[0]);
            cache_get_field_content(i, "objectMatInfo2", matInfo[1]);
            cache_get_field_content(i, "objectMatInfo3", matInfo[2]);

            objects[i] = CreateDynamicObject(objectID, x, y, z, rx, ry, rz);
            objectmodel[i] = objectID;

            if(strcmp(objectmatinfo[i][0],"None")) ApplyDynamicObjectMaterial(objects[i],i,0);
            if(strcmp(objectmatinfo[i][1],"None")) ApplyDynamicObjectMaterial(objects[i],i,1);
            if(strcmp(objectmatinfo[i][2],"None")) ApplyDynamicObjectMaterial(objects[i],i,2);
        }

        UpdateNearPlayers(playerid);
        SCM(playerid, green, "Map has been loaded");
    }
    return 1;
}

public OnBanCheck(playerid)
{
    new expire; 
    new rows = cache_num_rows();

    if(rows)
    {
        new
            bstring[6][38],
            string2[156],
            DIALOG[676];

        expire = cache_get_field_content_int(0, "BanExpire");
        cache_get_field_content(0, "PlayerName", bstring[1]);
        cache_get_field_content(0, "BannedBy", bstring[3]);
        cache_get_field_content(0, "BanReason", bstring[5]);
        cache_get_field_content(0, "BanOn", bstring[4]);

        if(expire > gettime() || expire == 0)
        {
            IsBanned[playerid] = 1;

            strcat(DIALOG, "{FF0000}You are banned from the server\n\n");

            format(string2, sizeof(string2), "{FFFFFF}Username: {FF0000}%s\n", bstring[1]);
            strcat(DIALOG, string2);

            format(string2, sizeof(string2), "{FFFFFF}Banned by: {FF0000}%s\n", bstring[3]);
            strcat(DIALOG, string2);

            format(string2, sizeof(string2), "{FFFFFF}Reason: {FF0000}%s\n", bstring[5]);
            strcat(DIALOG, string2);

            format(string2, sizeof(string2), "{FFFFFF}Ban date: {FF0000}%s\n", bstring[4]);
            strcat(DIALOG, string2);

            new expire2[68];
            if(expire == 0) expire2 = "PERMANENT";
            else expire2 = TimeConvert(expire);

            format(string2, sizeof(string2), "{FFFFFF}Expires date: {FF0000}%s\n\n", expire2);
            strcat(DIALOG, string2);

            ShowPlayerDialog(playerid, DIALOGS+99, DIALOG_STYLE_MSGBOX, "Note", DIALOG, "Close", "");
            return DelayKick(playerid);
        }
    }
    else
    {
        IsBanned[playerid] = 0;

        new query[150];
        mysql_format(mysql, query, sizeof(query), "SELECT `Password`, `ID`, `AutoLogin`, `IP` FROM `playersdata` WHERE `PlayerName` = '%e' LIMIT 1", GetName(playerid));
        mysql_tquery(mysql, query, "OnAccountCheck", "i", playerid);

        mysql_format(mysql, query, sizeof(query), "DELETE FROM `BannedPlayers` WHERE `PlayerName` = '%e'", GetName(playerid));
        mysql_tquery(mysql, query);

        format(query, sizeof(query), "%s has joined the server", GetName(playerid));
        SendClientMessageToAll(0x999999FF, query);
    }
    return 1;
}

public OnBanLoad(playerid) 
{
    new rows = cache_num_rows(),
        string[128], name[24], BannedBy[24], BanReason[24], BanOn[24], BanExpire,
        Mainstring[800], ban_expire[68];

    if(rows)
    {
        for(new i; i < rows; i++) 
        {
            cache_get_field_content(i, "PlayerName", name);
            cache_get_field_content(i, "BannedBy", BannedBy);
            cache_get_field_content(i, "BanReason", BanReason);
            cache_get_field_content(i, "BanOn", BanOn);
            BanExpire = cache_get_field_content_int(i, "BanExpire");

            if(BanExpire == 0) ban_expire = "PERMANENT";
            else ban_expire = TimeConvert(BanExpire);

            format(string, sizeof(string),"%s / %s / %s / %s / %s\n", name, BannedBy, BanReason, BanOn, ban_expire);
            strcat(Mainstring, string);
        }
        ShowPlayerDialog(playerid, DIALOGS+5471, DIALOG_STYLE_LIST, "Banned Players", Mainstring, "Close", "");
    }
    else ShowPlayerDialog(playerid, DIALOGS+5471, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No banned players found", "Close", "");
    return 1;
}

public OnAttachmentLoad(playerid)
{
    for(new i, j = cache_num_rows(); i < j; i++) 
    {
        new in = cache_get_row_int(i, 1);
        oInfo[playerid][in][index1] = in;
        oInfo[playerid][in][modelid1] = cache_get_row_int(i, 2);
        oInfo[playerid][in][bone1] = cache_get_row_int(i, 3);
        oInfo[playerid][in][fOffsetX1] = cache_get_row_float(i, 4);
        oInfo[playerid][in][fOffsetY1] = cache_get_row_float(i, 5);
        oInfo[playerid][in][fOffsetZ1] = cache_get_row_float(i, 6);
        oInfo[playerid][in][fRotX1] = cache_get_row_float(i, 7);
        oInfo[playerid][in][fRotY1] = cache_get_row_float(i, 8);
        oInfo[playerid][in][fRotZ1] = cache_get_row_float(i, 9);
        oInfo[playerid][in][fScaleX1] = cache_get_row_float(i, 10);
        oInfo[playerid][in][fScaleY1] = cache_get_row_float(i, 11);
        oInfo[playerid][in][fScaleZ1] = cache_get_row_float(i, 12);
        oInfo[playerid][in][used1] = true;
    }
}

public OnWeaponLoad(playerid)
{
    new weaponid, ammo;
    
    for(new i, j = cache_get_row_count(mysql); i < j; i++)
    {
        weaponid    = cache_get_row_int(i, 0, mysql);
        ammo        = cache_get_row_int(i, 1, mysql);
        
        if(!(0 <= weaponid <= 46)) continue;
        
        GivePlayerWeaponEx(playerid, weaponid, ammo); 
    }

    new query[65];
    mysql_format(mysql, query, sizeof(query), "DELETE FROM `Weapons` WHERE `ID` = %d", Info[playerid][ID]);
    mysql_tquery(mysql, query);
    return;
}

function OnFriendsLoad(playerid)
{
    new pID, count = 0;
    new rows = cache_num_rows();

    if(rows)
    {
        for(new i; i < rows; i++)
        {
            pID = cache_get_field_content_int(i, "FriendID");

            foreach(new x : Player)
            {
                if(pID == Info[x][ID]) count++;
            }
        }
    }

    new str[64];
    format(str, sizeof(str), "You have %i online friends!", count);
    SCM(playerid, NOTIF, str);
}

function OnOfflinePMsLoad(playerid)
{
    new rows = cache_num_rows();

    new str[64];
    format(str, sizeof(str), "You have %i offline private messages!", rows);
    SCM(playerid, NOTIF, str);
}

OnAkaConnect(playerid)
{
    new ip[16], Cache:results, query[128];
    GetPlayerIp(playerid, ip, sizeof(ip));

    mysql_format(mysql, query, sizeof(query), "SELECT `IP` FROM `playersdata` WHERE `PlayerName` = '%e'", GetName(playerid));
    results = mysql_query(mysql, query);
    new rows = cache_num_rows();

    if(rows)
    {
        mysql_format(mysql, query, sizeof(query), "UPDATE `playersdata` SET `IP` = '%e' WHERE `PlayerName` = '%e'", ip, GetName(playerid));
        mysql_tquery(mysql, query);
    }
    cache_delete(results);
    return 1;
}

GetPlayerAKA(playerid, id)
{
    new pip[16], query[320], strmain[750], string[64], bool:found = false, Cache:results;
    GetPlayerIp(playerid, pip, sizeof(pip));

    mysql_format(mysql, query, sizeof(query), "SELECT `PlayerName`, `IP` FROM `playersdata` WHERE `IP` = '%e'", pip);
    results = mysql_query(mysql, query);
    new rows = cache_num_rows();

    if(rows)
    {
        new matchedIP[16], name[MAX_PLAYER_NAME];
        for(new i; i < rows; i++) 
        {
            cache_get_field_content(i, "IP", matchedIP);
            cache_get_field_content(i, "PlayerName", name);

            if(strcmp(GetName(playerid), name))
            {
                found = true;
                format(query, sizeof(query), "{FFFFFF}%s - %s\n", name, matchedIP);
                strcat(strmain, query);
            }
        }
        format(string, 84, "%s - %s", GetName(playerid), pip);
        if(found == true) ShowPlayerDialog(id, WARN, DIALOG_STYLE_LIST, string, strmain, "Close", "");
        else ShowPlayerDialog(id, WARN, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No matched IPs found", "Close", "");
    }
    else ShowPlayerDialog(id, WARN, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No matched IPs found", "Close", "");
    cache_delete(results);
    return 1;
}

// Ban System

TimeConvert(time)
{
    new string[68];
    new values[6];
    TimestampToDate(time, values[0], values[1], values[2], values[3], values[4], values[5], 0, 0);
    format(string, sizeof(string), "%i/%i/%i", values[2], values[1], values[0]);
    return string;
}

// Commands Abuse

//73f7e6add84fe9280ae59c6efa9b8bdb
//99fe232dd07275d89c0c5b6ae72be09e

stock DisplayInMinutes(seconds)
{
    new String[150];
    new minutes,hours,days;
    if(seconds > 59)
    {
        minutes = seconds / 60;
        seconds = seconds - (minutes * 60);
    }
    if(minutes > 59)
    {
        hours = minutes / 60;
        minutes = minutes - (hours * 60);
    }
    if(hours > 23)
    {
        days = hours / 24;
        hours = hours - (days * 24);
    }
    format(String,150,"%d days, %d hours, %d minutes, %d seconds",days,hours,minutes,seconds);
    return String;
}

// Single player Textdraws

public ShowInfoBox(playerid, box_color, shown_for, text[])
{
    PlayerTextDrawBoxColor(playerid, ptInfoBox[playerid], box_color);
    PlayerTextDrawSetString(playerid, ptInfoBox[playerid], text);
    PlayerTextDrawShow(playerid, ptInfoBox[playerid]);

    KillTimer(tmInfoBox[playerid]);
    tmInfoBox[playerid] = SetTimerEx("HideInfoBox", (1000 * shown_for), false, "i", playerid);
    return 1;
}

public HideInfoBox(playerid)
{
    PlayerTextDrawHide(playerid, ptInfoBox[playerid]);
    return 1;
}

// SpeedoMeter

stock GetVehicleSpeed(playerid)
{
    new Float:Pos[4];
    GetVehicleVelocity(GetPlayerVehicleID(playerid), Pos[0], Pos[1], Pos[2]);
    Pos[3] = floatsqroot(floatpower(floatabs(Pos[0]), 2) + floatpower(floatabs(Pos[1]), 2) + floatpower(floatabs(Pos[2]), 2)) * 181.5;
    return floatround(Pos[3]);
}

// Reaction System

function xReactionProgress()
{
    switch(xTestBusy)
    {
        case true:
        {
            new
                string[128]
            ;
            format(string, sizeof(string), "[{FF0000}REACTION{FFFFFF}] {3399FF}No one won the reaction, New one starting in %d minutes", (TIME/60000));
            SendClientMessageToAll(-1, string);
            xReactionTimer = SetTimer("xReactionTest", TIME, 1);
            xTestBusy = false;
        }
    }
    return 1;
}

function xReactionTest()
{
    new
        xLength = (random(8) + 2),
        string[128]
    ;
    xCash = (randomEx(5000,20000));
    format(xChars, sizeof(xChars), "");
    Loop(x, xLength) format(xChars, sizeof(xChars), "%s%s", xChars, xCharacters[random(sizeof(xCharacters))][0]);
    format(string, sizeof(string), "[{FF0000}REACTION{FFFFFF}] {3399FF}First one types '{9999FF}%s{3399FF}' wins $%s", xChars, cNumber(xCash));
    SendClientMessageToAll(-1, string);
    KillTimer(xReactionTimer);
    xTestBusy = true;
    SetTimer("xReactionProgress", 150000, 0);
    return 1;
}

// Gangs

public OnPlayerEnterDynamicArea(playerid, areaid)
{
    for (new i, j = sizeof(g_Turf); i < j; i++)
    {
        if (areaid == g_Turf[i][areaId])
        {
            OnPlayerEnterGangZone(playerid, i);
            break;
        }
    }
    return 1;
}

public OnPlayerLeaveDynamicArea(playerid, areaid)
{
    for (new i, j = sizeof(g_Turf); i < j; i++)
    {
        if (areaid == g_Turf[i][areaId])
        {
            OnPlayerLeaveGangZone(playerid, i);
            break;
        }
    }
    return 1;
}

public OnPlayerEnterGangZone(playerid, zone) 
{
    if (pTeam[playerid] != NO_TEAM && GetPlayerState(playerid) != PLAYER_STATE_WASTED && GetPlayerInterior(playerid) == 0 && GetPlayerVirtualWorld(playerid) == 0) 
    {
        for (new i, j = sizeof(g_Turf); i < j; i++)
        {
            if(zone == g_Turf[i][turfId]) 
            {
                if (g_Turf[i][turfState] == TURF_STATE_NORMAL && pTeam[playerid] != g_Turf[i][turfOwner]) 
                {
                    g_MembersInTurf[i][pTeam[playerid]]++;
                }

                if (g_Turf[i][turfState] == TURF_STATE_ATTACKED)
                {
                    if(pTeam[playerid] != g_Turf[i][turfOwner] && pTeam[playerid] == g_Turf[i][turfAttacker])
                    {
                        PlayerTextDrawShow(playerid, CountDownAttack[playerid]);
                        g_MembersInTurf[i][pTeam[playerid]]++;
                    }
                }
            }
        }
    }
    return 1;
}

public OnPlayerLeaveGangZone(playerid, zone) 
{
    if(pTeam[playerid] != NO_TEAM) 
    {
        for(new i, j = sizeof(g_Turf); i < j; i++) 
        {
            if(zone == g_Turf[i][turfId]) 
            {
                if(g_Turf[i][turfState] == TURF_STATE_NORMAL && pTeam[playerid] != g_Turf[i][turfOwner]) 
                {
                    g_MembersInTurf[i][pTeam[playerid]]--;
                }

                if(pTeam[playerid] != g_Turf[i][turfOwner] && pTeam[playerid] == g_Turf[i][turfAttacker]) 
                {
                    g_MembersInTurf[i][pTeam[playerid]]--;
                    
                    if(g_Turf[i][turfState] == TURF_STATE_ATTACKED) 
                    {
                        PlayerTextDrawHide(playerid, CountDownAttack[playerid]);

                        if(g_MembersInTurf[i][pTeam[playerid]] < TURF_REQUIRED_PLAYERS) 
                        {
                            KillTimer(g_Turf[i][turfTimer]);
                            KillTimer(g_Turf[i][turfAttackTimer]);

                            g_Turf[i][turfCountDown] = 0;
                            g_Turf[i][turfTimer] = -1;
                            g_Turf[i][turfState] = TURF_STATE_NORMAL;
                            g_Turf[i][turfAttacker] = NO_TEAM;

                            foreach(new x : Player)
                            {
                                if(pTeam[x] != NO_TEAM)
                                {
                                    GangZoneStopFlashForPlayer(x, g_Turf[i][turfId]);
                                    GangZoneShowForPlayer(x, g_Turf[i][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[i][turfOwner]][teamColor]));
                                }

                                if(IsPlayerInGangZone(x, i)) 
                                {
                                    PlayerTextDrawHide(x, CountDownAttack[playerid]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return 1;
}

stock IsPlayerInGangZone(playerid, zone)
{
    if (IsPlayerInDynamicArea(playerid, g_Turf[zone][areaId])) return 1;
    return 0;
}

stock IsPlayerInAnyGangZone(playerid)
{
    for(new i, j = sizeof(g_Turf); i < j; i++) 
        if (IsPlayerInDynamicArea(playerid, g_Turf[i][areaId])) return 1;
    return 0;
}

public OnTurfwarEnd(turfid) 
{   
    foreach(new i : Player)
    {
        if(IsPlayerInGangZone(i, turfid))
        {
            if (pTeam[i] == g_Turf[turfid][turfAttacker]) 
            {
                PlayerTextDrawHide(i, CountDownAttack[i]);
                
                if(Info[i][Skills][pTeam[i]] < 5000) GivePlayerCash(i, 7500), WinnerText(i, "Payout $7,500");
                else GivePlayerCash(i, 9500), WinnerText(i, "Payout $9,500");

                Info[i][Skills][pTeam[i]] += 1;
            }
        }
    }

    KillTimer(g_Turf[turfid][turfAttackTimer]);

    g_Turf[turfid][turfTimer] = -1;
    g_Turf[turfid][turfOwner] = g_Turf[turfid][turfAttacker];
    g_Turf[turfid][turfState] = TURF_STATE_NORMAL;
    g_Turf[turfid][turfAttacker] = NO_TEAM;
    g_Turf[turfid][turfCountDown] = 0;

    foreach(new x : Player)
    {
        if(pTeam[x] != NO_TEAM)
        {
            GangZoneStopFlashForPlayer(x, g_Turf[turfid][turfId]);
            GangZoneShowForPlayer(x, g_Turf[turfid][turfId], COLOR_CHANGE_ALPHA(g_Team[g_Turf[turfid][turfOwner]][teamColor]));
        }
    }
}

public CountDownTimer(turfid)
{
    g_Turf[turfid][turfCountDown]--;
    new string[30];
    format(string, sizeof string, "~g~Attack: ~w~%d:%02d", g_Turf[turfid][turfCountDown] / 60, g_Turf[turfid][turfCountDown] % 60);
    foreach(new i : Player)
    {
        if(IsPlayerInGangZone(i, turfid) && pTeam[i] == g_Turf[turfid][turfAttacker] && IsPlayerSpawned(i)
        && pTeam[i] != NO_TEAM && GetPlayerInterior(i) == 0 && GetPlayerVirtualWorld(i) == 0) 
        {
            PlayerTextDrawSetString(i, CountDownAttack[i], string);
            PlayerTextDrawShow(i, CountDownAttack[i]);
            if(g_Turf[turfid][turfCountDown] == 0)
            {
                PlayerTextDrawHide(i, CountDownAttack[i]);
                KillTimer(g_Turf[turfid][turfAttackTimer]);
                g_Turf[turfid][turfCountDown] = 0;
            }
        }
    }
    return 1;
}

GetRank(playerid)
{
	new gRank[24];
	if(pTeam[playerid] != NO_TEAM)
	{
	    if(Info[playerid][Skills][pTeam[playerid]] >= 0) gRank = "Gangster";
	    if(Info[playerid][Skills][pTeam[playerid]] >= 1000) gRank = "Gang Commander";
	    if(Info[playerid][Skills][pTeam[playerid]] >= 5000) gRank = "Gang Boss";
	}
    return gRank;
}

stock TeamCount(playerid, team)
{
    if(pTeam[playerid] == NO_TEAM)
    {
        pTeam[playerid] = team;

        gTeamCount[team] ++;
        UpdateTeamLabel(team);
        return 0;
    }

    if(pTeam[playerid])
    {
        gTeamCount[pTeam[playerid]] --;
        UpdateTeamLabel(pTeam[playerid]);
    }

    pTeam[playerid] = team;

    gTeamCount[team] ++;
    UpdateTeamLabel(team);
    return 1;
}

stock UpdateTeamLabel(TeamID)
{
    new string[128];
    switch(TeamID)
    {
        case GROVE: format(string, sizeof(string), "Gang: Grove Street\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case BALLAS: format(string, sizeof(string), "Gang: Ballas\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case VAGOS: format(string, sizeof(string), "Gang: Los Santos Vagos\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case AZTECAS: format(string, sizeof(string), "Gang: Varrios Los Aztecas\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case BIKERS: format(string, sizeof(string), "Gang: Bikers\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case TRIADS: format(string, sizeof(string), "Gang: Triads\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case MAFIA: format(string, sizeof(string), "Gang: Mafia\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
        case NANG: format(string, sizeof(string), "Gang: Da Nang Boys\nMembers: %d\nPress LALT to join the gang", gTeamCount[TeamID]);
    }
    UpdateDynamic3DTextLabelText(TeamsLabel[TeamID], 0xFFFF00FF, string);
    return 1;
}

stock TeamColorFP(playerid)
{
    switch(pTeam[playerid]) 
    {
        case NO_TEAM: {

            if(!strcmp(Info[playerid][playerColor], "-") || !strcmp(Info[playerid][playerColor], "0xFFFFFFFF") || isnull(Info[playerid][playerColor])) {

                format(Info[playerid][playerColor], 16, "0xFFFFFFFF");
                format(Info[playerid][textColor], 16, "FFFFFF");
                SetPlayerColor(playerid, 0xFFFFFFFF);
            }
        }
        case GROVE: SetPlayerColor(playerid, COLOR_GROVE), format(Info[playerid][textColor], 16, "009900"), format(Info[playerid][playerColor], 16, "0xFFFFFFFF");
        case BALLAS: SetPlayerColor(playerid, COLOR_BALLAS), format(Info[playerid][textColor], 16, "CC00CC"), format(Info[playerid][playerColor], 16, "0xCC00CCFF");
        case VAGOS: SetPlayerColor(playerid, COLOR_VAGOS), format(Info[playerid][textColor], 16, "FFCC00"), format(Info[playerid][playerColor], 16, "0xFFCC00FF");
        case AZTECAS: SetPlayerColor(playerid, COLOR_AZTECAS), format(Info[playerid][textColor], 16, "00FFFF"), format(Info[playerid][playerColor], 16, "0x00FFFFFF");
        case BIKERS: SetPlayerColor(playerid, COLOR_BIKERS), format(Info[playerid][textColor], 16, "595959"), format(Info[playerid][playerColor], 16, "0x595959FF");
        case TRIADS: SetPlayerColor(playerid, COLOR_TRIADS), format(Info[playerid][textColor], 16, "6600FF"), format(Info[playerid][playerColor], 16, "0x6600FFFF");
        case MAFIA: SetPlayerColor(playerid, COLOR_MAFIA), format(Info[playerid][textColor], 16, "E69500"), format(Info[playerid][playerColor], 16, "0xE69500FF");
        case NANG: SetPlayerColor(playerid, COLOR_NANG), format(Info[playerid][textColor], 16, "996633"), format(Info[playerid][playerColor], 16, "0x996633FF");
    }
}

stock SendMessageToTeam(team, color, mess[])
{
    foreach(new i : Player)
    {
        if(pTeam[i] == team) SendClientMessage(i, color, mess);
    }
}

// Anti-Money Hack

function GivePlayerCash(playerid, money)
{
    Cash[playerid] += money;
    ResetMoneyBar(playerid);
    UpdateMoneyBar(playerid,Cash[playerid]);
    return Cash[playerid];
}

function SetPlayerCash(playerid, money)
{
    Cash[playerid] = money;
    ResetMoneyBar(playerid);
    UpdateMoneyBar(playerid,Cash[playerid]);
    return Cash[playerid];
}

function ResetPlayerCash(playerid)
{
    Cash[playerid] = 0;
    ResetMoneyBar(playerid);
    UpdateMoneyBar(playerid,Cash[playerid]);
    return Cash[playerid];
}

function GetPlayerCash(playerid)
{
    return Cash[playerid];
}

public AntiHacks(playerid)
{
    new string[80];
    if(Info[playerid][Level] != 5 && IsPlayerSpawned(playerid))
    {
        new Float:Positions[3], Float:Velocity[3], PlayerKeys[3];
        GetPlayerPos(playerid, Positions[0], Positions[1], Positions[2]); 
        GetPlayerVelocity(playerid, Velocity[0], Velocity[1], Velocity[2]);
        GetPlayerKeys(playerid, PlayerKeys[0], PlayerKeys[1], PlayerKeys[2]);

        if(GetPlayerCash(playerid) != GetPlayerMoney(playerid))
        {
            ResetMoneyBar(playerid);
            UpdateMoneyBar(playerid, GetPlayerCash(playerid));
        }

        if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK && Info[playerid][Jetpack] == 0 && Info[playerid][Level] < 3 && GotJetpack[playerid] == 0) 
        {
            format(string, sizeof(string), "%s has been kicked for jetpack hack", GetName(playerid));
            SendClientMessageToAll(red, string);
            return DelayKick(playerid);
        }

        if(IsPlayerUsingFlyAnim(playerid) && !IsPlayerInWater(playerid) && PlayerKeys[1] == KEY_UP && (Positions[2] >= 15.0) && 
        (Velocity[0] >= -0.9  || Velocity[1] >= -0.9 || Velocity[0] >= 0.9  || Velocity[1] >= 0.9) && Jumping[playerid] == 0)
        {
            if(gettime() - pTickWarnings[playerid] < 20)
            {
                HackWarnings[playerid]++;

                if(HackWarnings[playerid] == 5)
                {
                    HackWarnings[playerid] = 0;
                    format(string, sizeof(string), "%s has been kicked for fly hack", GetName(playerid));
                    SendClientMessageToAll(red, string);
                    return DelayKick(playerid);
                }
            }
            else HackWarnings[playerid] = 0;
            pTickWarnings[playerid] = gettime();
        }

        new animname[32], animlib[32];
        GetAnimationName(GetPlayerAnimationIndex(playerid), animlib, sizeof(animlib), animname, sizeof(animname));
        if (!strcmp(animname, "SWIM_CRAWL", true) && !IsPlayerInAnyVehicle(playerid))
        {
            new Float:velocityX, Float:velocityY, Float:velocityZ, Float:speed;
            GetPlayerVelocity(playerid, velocityX, velocityY, velocityZ);
            speed = floatsqroot((velocityX * velocityX) + (velocityY * velocityY) + (velocityZ * velocityZ) * 100);
            if (floatround(speed, floatround_round) >= 3)
            {
                if(gettime() - pTickWarnings[playerid] < 20)
                {
                    HackWarnings[playerid]++;

                    if(HackWarnings[playerid] == 5)
                    {
                        HackWarnings[playerid] = 0;
                        format(string, sizeof(string), "%s has been kicked for fly hack", GetName(playerid));
                        SendClientMessageToAll(red, string);
                        return DelayKick(playerid);
                    }
                }
                else HackWarnings[playerid] = 0;
                pTickWarnings[playerid] = gettime();
            }
        }

        if(GetPlayerAnimationIndex(playerid))
        {
            GetAnimationName(GetPlayerAnimationIndex(playerid), animlib, sizeof(animlib), animname, sizeof(animname));
            if(!strcmp(animlib, "PARACHUTE", true) && !strcmp(animname, "FALL_SkyDive_Accel", true))
            {
                if(GetPlayerWeapon(playerid) != 46)
                {
                    if(gettime() - pTickWarnings[playerid] < 20)
                    {
                        HackWarnings[playerid]++;

                        if(HackWarnings[playerid] == 5)
                        {
                            HackWarnings[playerid] = 0;
                            format(string, sizeof(string), "%s has been kicked for fly hack", GetName(playerid));
                            SendClientMessageToAll(red, string);
                            return DelayKick(playerid);
                        }
                    }
                    else HackWarnings[playerid] = 0;
                    pTickWarnings[playerid] = gettime();
                }
            }
        }

        new weaponid, ammo;

        for (new i; i <= 12; i++)
        {
            GetPlayerWeaponData(playerid, i, weaponid, ammo);

            if(weaponid != 0 && ammo > 1 && !gPlayerWeaponData[playerid][weaponid] && weaponid != 40 && weaponid != 46)
            {
                RemovePlayerWeapon(playerid, weaponid);
                format(string, sizeof(string), "%s has been kicked for weapon hack", GetName(playerid));
                SendClientMessageToAll(red, string);
                return DelayKick(playerid);
            }
        }

        new Float:itsHP, Float:itsArmour;
        GetPlayerHealth(playerid, itsHP);
        GetPlayerArmour(playerid, itsArmour);

        if(itsHP > 0.0 && AntiHealth[playerid] == false)
        {
            SetPlayerHealthEx(playerid, 10.0);
            format(string, sizeof(string), "%s has been kicked for health hack", GetName(playerid));
            SendClientMessageToAll(red, string);
            return DelayKick(playerid);
        }
        if(itsArmour > 0.0 && AntiArmour[playerid] == false)
        {
            SetPlayerArmourEx(playerid, 0.0);
            format(string, sizeof(string), "%s has been kicked for armour hack", GetName(playerid));
            SendClientMessageToAll(red, string);
            return DelayKick(playerid);
        }
    }
    return 1;
}

// Anti Health/Armour Hack

stock SetPlayerArmourEx(playerid, Float:armour)
{
    AntiArmour[playerid] = true;
    return SetPlayerArmour(playerid, armour);
}

stock SetPlayerHealthEx(playerid, Float:health)
{
    AntiHealth[playerid] = true;
    return SetPlayerHealth(playerid, health);
}

// Anti Weapon Hack

stock GivePlayerWeaponEx(playerid, weaponid, ammo)
{
    if(!weaponid) return 0;

    gPlayerWeaponData[playerid][weaponid] = true;
    return GivePlayerWeapon(playerid, weaponid, ammo);
}

stock ResetPlayerWeaponsEx(playerid)
{
    for(new weaponid; weaponid < 46; weaponid++)
    gPlayerWeaponData[playerid][weaponid] = false;
    return ResetPlayerWeapons(playerid);
}

// Anti Fly Hack

stock IsPlayerUsingFlyAnim(playerid) 
{
    switch(GetPlayerAnimationIndex(playerid))
    {
        case 1538, 1542, 1544, 1250, 1062, 1539, 958, 962: return true;
    }
    return false;
}

stock Float:Distance(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) return floatsqroot((((x1-x2)*(x1-x2))+((y1-y2)*(y1-y2))+((z1-z2)*(z1-z2))));
stock Float:Distance2D(Float:x1, Float:y1, Float:x2, Float:y2) return floatsqroot( ((x1-x2)*(x1-x2)) + ((y1-y2)*(y1-y2)) );

new Float:water_places[20][4] =
{
    {30.0,                        2313.0,                -1417.0,        23.0},
    {15.0,                        1280.0,                -773.0,                1083.0},
    {25.0,                        2583.0,                2385.0,                15.0},
    {20.0,                        225.0,                -1187.0,        74.0},
    {50.0,                        1973.0,                -1198.0,        17.0},
    {180.0,                        1937.0,          1589.0,                9.0},
    {55.0,                        2142.0,                1285.0,         8.0},
    {45.0,                        2150.0,                1132.0,                8.0},
    {55.0,                        2089.0,                1915.0,                10.0},
    {32.0,                        2531.0,                1567.0,                9.0},
    {21.0,                        2582.0,                2385.0,                17.0},
    {33.0,                        1768.0,                2853.0,                10.0},
    {47.0,                        -2721.0,        -466.0,                3.0},
    {210.0,                        -671.0,                -1898.0,        6.0},
    {45.0,                        1240.0,                -2381.0,        9.0},
    {50.0,                        1969.0,                -1200.0,        18.0},
    {10.0,                        513.0,                -1105.0,        79.0},
    {20.0,                        193.0,                -1230.0,        77.0},
    {30.0,                        1094.0,                -672.0,                113.0},
    {20.0,                        1278.0,                -805.0,                87.0}
};

stock IsPlayerInWater(playerid)
{
    new Float:flyPosX, Float:flyPosY, Float:flyPosZ;
    GetPlayerPos(playerid, flyPosX, flyPosY, flyPosZ);

    if(flyPosZ < 44.0)
    {
        if(Distance(flyPosX, flyPosY, flyPosZ, -965.0, 2438.0, 42.0) <= 700.0) return true;
    }

    for(new i; i < sizeof(water_places); i++)
    {
        if(Distance2D(flyPosX, flyPosY, water_places[i][1], water_places[i][2]) <= water_places[i][0])
        {
            if(flyPosZ < water_places[i][3]) return true;
        }
        if(flyPosZ < 1.9)
        {
            if(Distance(flyPosX, flyPosY, flyPosZ, 618.4129, 863.3164, 1.0839) < 200.0) return false; 
            else return true;
        }
    }
    return false;
}

// Derby Minigames

function DerbyTextDraws()
{
    foreach(new i : Player)
    {
        if(InDerby[i] == 1)
        {
            new string[128];
            switch(DerbyGame)
            {
                case RANCHERS_DERBY:
                {
                    if(DerbyCountDownFromAmount == 0)
                    {
                        format(string, sizeof(string), "~r~Derby Map: ~g~Ranchers Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
                        KillTimer(DerbyTDTimer);
                    }
                    else format(string, sizeof(string), "~r~Derby Map: ~g~Ranchers Derby~n~~r~Players: ~g~%i/20 ~n~~r~Starting In: ~g~%i", PlayersInDerby, DerbyCountDownFromAmount % 60);
                    TextDrawSetString(DerbyInfo, string);
                    TextDrawShowForPlayer(i, DerbyInfo);
                }
                case BULLETS_DERBY:
                {
                    if(DerbyCountDownFromAmount == 0)
                    { 
                        format(string, sizeof(string), "~r~Derby Map: ~g~Bullets Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
                        KillTimer(DerbyTDTimer);
                    }
                    else format(string, sizeof(string), "~r~Derby Map: ~g~Bullets Derby~n~~r~Players: ~g~%i/20 ~n~~r~Starting In: ~g~%i", PlayersInDerby, DerbyCountDownFromAmount % 60);
                    TextDrawSetString(DerbyInfo, string);
                    TextDrawShowForPlayer(i, DerbyInfo);
                }
                case HOTRINGS_DERBY:
                {
                    if(DerbyCountDownFromAmount == 0)
                    {
                        format(string, sizeof(string), "~r~Derby Map: ~g~Hotrings Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
                        KillTimer(DerbyTDTimer);
                    }
                    else format(string, sizeof(string), "~r~Derby Map: ~g~Hotrings Derby~n~~r~Players: ~g~%i/20 ~n~~r~Starting In: ~g~%i", PlayersInDerby, DerbyCountDownFromAmount % 60);
                    TextDrawSetString(DerbyInfo, string);
                    TextDrawShowForPlayer(i, DerbyInfo);
                }
                case INFERNUS_DERBY:
                {
                    if(DerbyCountDownFromAmount == 0)
                    {
                        format(string, sizeof(string), "~r~Derby Map: ~g~Infernus Derby~n~~r~Players: ~g~%i/20", PlayersInDerby);
                        KillTimer(DerbyTDTimer);
                    }
                    else format(string, sizeof(string), "~r~Derby Map: ~g~Infernus Derby~n~~r~Players: ~g~%i/20 ~n~~r~Starting In: ~g~%i", PlayersInDerby, DerbyCountDownFromAmount % 60);
                    TextDrawSetString(DerbyInfo, string);
                    TextDrawShowForPlayer(i, DerbyInfo);
                }
            }
        }
    }
}

public DerbyStart()
{
    if(PlayersInDerby >= 2)
    {
        foreach(new i : Player)
        {
            if(InDerby[i] == 1)
            {
            	DerbyCountDownFromAmount = 0;
                GameTextForPlayer(i, "GO GO GO!", 3000, 3);
                TogglePlayerControllable(i, true);
            }
        }
        DerbyStarted = true;
    }
    else 
    {
        foreach(new i : Player)
        {
            for(new x; x < DerbyVehicles[i]; x++)
            {
                DestroyVehicle(DerbyVehicles[i]);
            }

            if(InDerby[i] == 1)
            {
                InDerby[i] = 0;
                DerbyCountDownFromAmount = 0;
                TogglePlayerControllable(i, true);
                SpawnPlayerEx(i);
                TextDrawHideForPlayer(i, DerbyInfo);
            }
        }
        SendClientMessageToAll(red, "Derby is over - No enough players found");
        DerbyGame = NON_DERBY;
        DerbyStarted = false;
        PlayersInDerby = 0;
    }
}

public DerbyCountDown()
{
    DerbyCountDownFromAmount--;
    foreach(new i : Player)
    {
        if(InDerby[i] == 1) 
        {
            if(DerbyCountDownFromAmount == 0)
            {
                KillTimer(DerbyTimer);
                DerbyCountDownFromAmount = 0;
            }
        }
    }
    return 1;
}

public FallingChecker(playerid, Float:maxz)
{
    new Float:x, Float:y, Float:z;
    GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    if(InDerby[playerid] == 1 && DerbyStarted == true)
    {
        if(z <= maxz)
        {
            DestroyVehicle(GetPlayerVehicleID(playerid));
            InDerby[playerid] = 0;
            SpawnPlayerEx(playerid);
            SCM(playerid, red, "You have left the derby [VEHICLE FELL]");
            TextDrawHideForPlayer(playerid, DerbyInfo);
            PlayersInDerby -= 1;

            if(PlayersInDerby == 1)
            {
                new string[128];
                foreach(new i : Player)
                {
                    for(new car; car < DerbyVehicles[i]; car++)
                    {
                        DestroyVehicle(DerbyVehicles[car]);
                    }

                    if(InDerby[i] == 1)
                    {
                        InDerby[i] = 0;
                        format(string, sizeof(string), "%s has won the derby", GetName(i));
                        SendClientMessageToAll(0x00FFFFFF, string);
                        Info[i][XP] += 100;
                        GivePlayerCash(InDerby[i], randomEx(10000,30000));
                        format(string, sizeof(string), "Winner $%s ~n~+100 XP", cNumber(randomEx(10000,30000)));
                        WinnerText(i, string);
                        SpawnPlayerEx(i);
                        TextDrawHideForPlayer(i, DerbyInfo);
                    }
                }
                KillTimer(DerbyTDTimer);
                DerbyGame = NON_DERBY;
                DerbyStarted = false;
                PlayersInDerby = 0;
            }
        }
    }
    return 1;
}

new Current_Cell;
SpawnPlayerInDerby(playerid, modelid, Float:SpawnArray[][], MaxPositions)
{
    if(Current_Cell == MaxPositions) return (Current_Cell = 0), SpawnPlayerInDerby(playerid, modelid, SpawnArray, MaxPositions);
    if(!SetPlayerFacingAngle(playerid, SpawnArray[Current_Cell][3])) return false;

    DerbyVehicles[playerid] = CreateVehicle(modelid, SpawnArray[Current_Cell][0], SpawnArray[Current_Cell][1], SpawnArray[Current_Cell][2], SpawnArray[Current_Cell][3], 211, 1, 0);
    Current_Cell++;
    return true;
}

// TDM Minigames

function TDMTextDraws()
{
    foreach(new i : Player)
    {
        if(InTDM[i] == 1)
        {
            new string[128];
            switch(TDMGame)
            {
                case TDM_ONE:
                {
                    if(TDMCountDownFromAmount == 0) format(string, sizeof(string), "~r~TDM Map: ~g~Team Deathmatch #1~n~~r~Players: ~g~%i/20", PlayersInTDM);
                    else format(string, sizeof(string), "~r~TDM Map: ~g~Team Deathmatch #1~n~~r~Players: ~g~%i/20 ~n~~r~Starting In: ~g~%i", PlayersInTDM, TDMCountDownFromAmount % 60);
                    TextDrawSetString(TDMInfo, string);
                    TextDrawShowForPlayer(i, TDMInfo);
                }
                case TDM_TWO:
                {
                    if(TDMCountDownFromAmount == 0) format(string, sizeof(string), "~r~TDM Map: ~g~Team Deathmatch #2~n~~r~Players: ~g~%i/20", PlayersInTDM);
                    else format(string, sizeof(string), "~r~TDM Map: ~g~Team Deathmatch #2~n~~r~Players: ~g~%i/20 ~n~~r~Starting In: ~g~%i", PlayersInTDM, TDMCountDownFromAmount % 60);
                    TextDrawSetString(TDMInfo, string);
                    TextDrawShowForPlayer(i, TDMInfo);
                }
            }
        }
    }
}

public StartTDM()
{
    if(PlayersInTDM >= 2)
    {
        foreach(new i : Player)
        {
            if(InTDM[i] == 1)
            {
                switch(TDMGame)
                {
                    case TDM_ONE:
                    {
                        TogglePlayerControllable(i, true);
                        GameTextForPlayer(i, "GO GO GO!", 3000, 3);
                        GivePlayerWeaponEx(i, 24, 100000);
                        GivePlayerWeaponEx(i, 31, 100000);
                    }
                    case TDM_TWO:
                    {
                    	TogglePlayerControllable(i, true);
                        GameTextForPlayer(i, "GO GO GO!", 3000, 3);
                        GivePlayerWeaponEx(i, 27, 100000);
                        GivePlayerWeaponEx(i, 16, 100000);
                    }
                }
            }
        }
    }
    else
    {
        foreach(new i : Player)
        {
            if(InTDM[i] == 1)
            {
                InTDM[i] = 0;
                TextDrawHideForPlayer(i, TDMInfo);
                ResetPlayerWeaponsEx(i);
                TogglePlayerControllable(i, true);
                SpawnPlayerEx(i);
            }
        }
        SendClientMessageToAll(red, "TDM is over - No enough players found");
        KillTimer(TDTimer);
        KillTimer(TDMTimer);
        TDMStarted = false;
        TDMGame = NON_TDM;
        PlayersInTDM = 0;
    }
}

public TDMCountDown()
{
    TDMCountDownFromAmount--;
    foreach(new i : Player)
    {
        if(InTDM[i] == 1) 
        {
            if(TDMCountDownFromAmount == 0)
            {
            	TDMCountDownFromAmount = 0;
                KillTimer(TDMTimer);
            }
        }
    }
    return 1;
}

// Duel System

public CancelDuel(playerid)
{
    Invited[playerid] = 0; //not invited
    Weapon1[playerid] = -1; //setting weapon1 to invalid
    Weapon2[playerid] = -1; //setting weapon2 to invalid
    Opponent[playerid] = -1; //setting Opponent to invalid
    Bet[playerid] = -1; // setting bet to -1
    SendClientMessage(playerid, 0x00CDFFFF, "[DUEL] Duel invitation canceled");
    return 1;
}

// Skins Inventory 

stock GetSkinName(skinid)
{
	new returnt[64];
	switch(skinid)
	{
		case 0: returnt = "Carl CJ Johnson";
		case 1: returnt = "The Truth";
		case 2: returnt = "Maccer";
		case 3: returnt = "INVALID_SKIN_ID";
		case 4: returnt = "INVALID_SKIN_ID";
		case 5: returnt = "INVALID_SKIN_ID";
		case 6: returnt = "INVALID_SKIN_ID";
		case 7: returnt = "Taxi Driver/Train Driver";
		case 8: returnt = "INVALID_SKIN_ID";
		case 9: returnt = "Normal Ped";
		case 10: returnt = "Normal Ped";
		case 11: returnt = "Casino Worker";
		case 12: returnt = "Normal Ped";
		case 13: returnt = "Normal Ped";
		case 14: returnt = "Normal Ped";
		case 15: returnt = "RS Haul Owner";
		case 16: returnt = "Airport Ground Worker";
		case 17: returnt = "Normal Ped";
		case 18: returnt = "Beach Visitor";
		case 19: returnt = "Normal Ped";
		case 20: returnt = "Madd Dogg's Manager";
		case 21: returnt = "Normal Ped";
		case 22: returnt = "Normal Ped";
		case 23: returnt = "BMXer";
		case 24: returnt = "Madd Dogg Bodyguard";
		case 25: returnt = "Madd Dogg Bodyguard";
		case 26: returnt = "Mountain Climber";
		case 27: returnt = "Builder";
		case 28: returnt = "Drug Dealer";
		case 29: returnt = "Drug Dealer";
		case 30: returnt = "Drug Dealer";
		case 31: returnt = "Farm-Town inhabitant";
		case 32: returnt = "Farm-Town inhabitant";
		case 33: returnt = "Farm-Town inhabitant";
		case 34: returnt = "Farm-Town inhabitant";
		case 35: returnt = "Normal Ped";
		case 36: returnt = "Golfer";
		case 37: returnt = "Golfer";
		case 38: returnt = "Normal Ped";
		case 39: returnt = "Normal Ped";
		case 40: returnt = "Normal Ped";
		case 41: returnt = "Normal Ped";
		case 42: returnt = "INVALID_SKIN_ID";
		case 43: returnt = "Normal Ped";
		case 44: returnt = "Normal Ped";
		case 45: returnt = "Beach Visitor";
		case 46: returnt = "Normal Ped";
		case 47: returnt = "Normal Ped";
		case 48: returnt = "Normal Ped";
		case 49: returnt = "Snakehead (Da Nang)";
		case 50: returnt = "Mechanic";
		case 51: returnt = "Mountain Biker";
		case 52: returnt = "Mountain Biker";
		case 53: returnt = "INVALID_SKIN_ID";
		case 54: returnt = "Normal Ped";
		case 55: returnt = "Normal Ped";
		case 56: returnt = "Normal Ped";
		case 57: returnt = "Feds";
		case 58: returnt = "Normal Ped";
		case 59: returnt = "Normal Ped";
		case 60: returnt = "Normal Ped";
		case 61: returnt = "Pilot";
		case 62: returnt = "Colonel Fuhrberger";
		case 63: returnt = "Prostitute";
		case 64: returnt = "Prostitute";
		case 65: returnt = "INVALID_SKIN_ID";
		case 66: returnt = "Pool Player";
		case 67: returnt = "Pool Player";
		case 68: returnt = "Priest";
		case 69: returnt = "Normal Ped";
		case 70: returnt = "Scientist";
		case 71: returnt = "Security Guard";
		case 72: returnt = "Normal Ped";
		case 73: returnt = "Jethro";
		case 74: returnt = "INVALID_SKIN_ID";
		case 75: returnt = "Prostitute";
		case 76: returnt = "Normal Ped";
		case 77: returnt = "Homeless";
		case 78: returnt = "Homeless";
		case 79: returnt = "Homeless";
		case 80: returnt = "Boxer";
		case 81: returnt = "Boxer";
		case 82: returnt = "Elvis Wannabe";
		case 83: returnt = "Elvis Wannabe";
		case 84: returnt = "Elvis Wannabe";
		case 85: returnt = "Prostitute";
		case 86: returnt = "INVALID_SKIN_ID";
		case 87: returnt = "Whore";
		case 88: returnt = "Normal Ped";
		case 89: returnt = "Normal Ped";
		case 90: returnt = "Whore";
		case 91: returnt = "INVALID_SKIN_ID";
		case 92: returnt = "Beach Visitor";
		case 93: returnt = "Normal Ped";
		case 94: returnt = "Normal Ped";
		case 95: returnt = "Normal Ped";
		case 96: returnt = "Jogger";
		case 97: returnt = "Beach Visitor";
		case 98: returnt = "Normal Ped";
		case 99: returnt = "Skeelering";
		case 100: returnt = "Biker";
		case 101: returnt = "Normal Ped";
		case 102: returnt = "Ballas";
		case 103: returnt = "Ballas";
		case 104: returnt = "Ballas";
		case 105: returnt = "Grove Street Families";
		case 106: returnt = "Grove Street Families";
		case 107: returnt = "Grove Street Families";
		case 108: returnt = "Los Santos Vagos";
		case 109: returnt = "Los Santos Vagos";
		case 110: returnt = "Los Santos Vagos";
		case 111: returnt = "The Russian Mafia";
		case 112: returnt = "The Russian Mafia";
		case 113: returnt = "The Russian Mafia";
		case 114: returnt = "Varios Los Aztecas";
		case 115: returnt = "Varios Los Aztecas";
		case 116: returnt = "Varios Los Aztecas";
		case 117: returnt = "Traid";
		case 118: returnt = "Traid";
		case 119: returnt = "INVALID_SKIN_ID";
		case 120: returnt = "Traid";
		case 121: returnt = "Da Nang Boy";
		case 122: returnt = "Da Nang Boy";
		case 123: returnt = "Da Nang Boy";
		case 124: returnt = "The Mafia";
		case 125: returnt = "The Mafia";
		case 126: returnt = "The Mafia";
		case 127: returnt = "The Mafia";
		case 128: returnt = "Farm Inhabitant";
		case 129: returnt = "Farm Inhabitant";
		case 130: returnt = "Farm Inhabitant";
		case 131: returnt = "Farm Inhabitant";
		case 132: returnt = "Farm Inhabitant";
		case 133: returnt = "Farm Inhabitant";
		case 134: returnt = "Homeless";
		case 135: returnt = "Homeless";
		case 136: returnt = "Normal Ped";
		case 137: returnt = "Homeless";
		case 138: returnt = "Beach Visitor";
		case 139: returnt = "Beach Visitor";
		case 140: returnt = "Beach Visitor";
		case 141: returnt = "Office Worker";
		case 142: returnt = "Taxi Driver";
		case 143: returnt = "Normal Ped";
		case 144: returnt = "Normal Ped";
		case 145: returnt = "Beach Visitor";
		case 146: returnt = "Beach Visitor";
		case 147: returnt = "Director";
		case 148: returnt = "Secretary";
		case 149: returnt = "INVALID_SKIN_ID";
		case 150: returnt = "Secretary";
		case 151: returnt = "Normal Ped";
		case 152: returnt = "Prostitute";
		case 153: returnt = "Coffee mam'";
		case 154: returnt = "Beach Visitor";
		case 155: returnt = "Well Stacked Pizza";
		case 156: returnt = "Normal Ped";
		case 157: returnt = "Farmer";
		case 158: returnt = "Farmer";
		case 159: returnt = "Farmer";
		case 160: returnt = "Farmer";
		case 161: returnt = "Farmer";
		case 162: returnt = "Farmer";
		case 163: returnt = "Bouncer";
		case 164: returnt = "Bouncer";
		case 165: returnt = "MIB Agent";
		case 166: returnt = "MIB Agent";
		case 167: returnt = "Cluckin' Bell";
		case 168: returnt = "Food Vendor";
		case 169: returnt = "Normal Ped";
		case 170: returnt = "Normal Ped";
		case 171: returnt = "Casino Worker";
		case 172: returnt = "Hotel Services";
		case 173: returnt = "San Fierro Rifa";
		case 174: returnt = "San Fierro Rifa";
		case 175: returnt = "San Fierro Rifa";
		case 176: returnt = "Tatoo Shop";
		case 177: returnt = "Tatoo Shop";
		case 178: returnt = "Whore";
		case 179: returnt = "Ammu-Nation Salesmen";
		case 180: returnt = "Normal Ped";
		case 181: returnt = "Punker";
		case 182: returnt = "Normal Ped";
		case 183: returnt = "Normal Ped";
		case 184: returnt = "Normal Ped";
		case 185: returnt = "Normal Ped";
		case 186: returnt = "Normal Ped";
		case 187: returnt = "Buisnessman";
		case 188: returnt = "Normal Ped";
		case 189: returnt = "Valet";
		case 190: returnt = "Barbara Schternvart";
		case 191: returnt = "Helena Wankstein";
		case 192: returnt = "Michelle Cannes";
		case 193: returnt = "Katie Zhan";
		case 194: returnt = "Millie Perkins";
		case 195: returnt = "Denise Robinson";
		case 196: returnt = "Farm-Town inhabitant";
		case 197: returnt = "Farm-Town inhabitant";
		case 198: returnt = "Farm-Town inhabitant";
		case 199: returnt = "Farm-Town inhabitant";
		case 200: returnt = "Farmer";
		case 201: returnt = "Farmer";
		case 202: returnt = "Farmer";
		case 203: returnt = "Karate Teacher";
		case 204: returnt = "Karate Teacher";
		case 205: returnt = "Burger Shot Cashier";
		case 206: returnt = "Normal Ped";
		case 207: returnt = "Prostitute";
		case 208: returnt = "Well Stacked Pizza";
		case 209: returnt = "Normal Ped";
		case 210: returnt = "INVALID_SKIN_ID";
		case 211: returnt = "Shop Staff";
		case 212: returnt = "Homeless";
		case 213: returnt = "Weird old man";
		case 214: returnt = "Normal Ped";
		case 215: returnt = "Normal Ped";
		case 216: returnt = "Normal Ped";
		case 217: returnt = "Shop Staff";
		case 218: returnt = "Normal Ped";
		case 219: returnt = "Secretary";
		case 220: returnt = "Taxi Driver";
		case 221: returnt = "Normal Ped";
		case 222: returnt = "Normal Ped";
		case 223: returnt = "Normal Ped";
		case 224: returnt = "Sofori";
		case 225: returnt = "Normal Ped";
		case 226: returnt = "Normal Ped";
		case 227: returnt = "Normal Ped";
		case 228: returnt = "Normal Ped";
		case 229: returnt = "Normal Ped";
		case 230: returnt = "Homeless";
		case 231: returnt = "Normal Ped";
		case 232: returnt = "Normal Ped";
		case 233: returnt = "Normal Ped";
		case 234: returnt = "Normal Ped";
		case 235: returnt = "Normal Ped";
		case 236: returnt = "Normal Ped";
		case 237: returnt = "Prostitute";
		case 238: returnt = "Prostitute";
		case 239: returnt = "Homeless";
		case 240: returnt = "The D.A";
		case 241: returnt = "Afro-American";
		case 242: returnt = "Mexican";
		case 243: returnt = "Prostitute";
		case 244: returnt = "Whore";
		case 245: returnt = "Prostitute";
		case 246: returnt = "Whore";
		case 247: returnt = "Biker";
		case 248: returnt = "Biker";
		case 249: returnt = "Pimp";
		case 250: returnt = "Normal Ped";
		case 251: returnt = "Beach Visitor";
		case 252: returnt = "Naked Valet";
		case 253: returnt = "Bus Driver";
		case 254: returnt = "Drug Dealer";
		case 255: returnt = "Limo Driver";
		case 256: returnt = "Whore";
		case 257: returnt = "Whore";
		case 258: returnt = "Golfer";
		case 259: returnt = "Golfer";
		case 260: returnt = "Construction Site";
		case 261: returnt = "Normal Ped";
		case 262: returnt = "Taxi Driver";
		case 263: returnt = "Normal Ped";
		case 264: returnt = "Clown";
		case 265: returnt = "Tenpenny";
		case 266: returnt = "Pulaski";
		case 267: returnt = "Officer Frank Tenpenny (Crooked Cop)";
		case 268: returnt = "Dwaine";
		case 269: returnt = "Melvin Big Smoke Harris";
		case 270: returnt = "Sweet";
		case 271: returnt = "Lance Ryder Wilson";
		case 272: returnt = "Mafia Boss";
		case 273: returnt = "INVALID_SKIN_ID";
		case 274: returnt = "Paramedic";
		case 275: returnt = "Paramedic";
		case 276: returnt = "Paramedic";
		case 277: returnt = "Firefighter";
		case 278: returnt = "Firefighter";
		case 279: returnt = "Firefighter";
		case 280: returnt = "Los Santos Police";
		case 281: returnt = "San Fierro Police";
		case 282: returnt = "Las Venturas Police";
		case 283: returnt = "Country Sheriff";
		case 284: returnt = "San Andreas Police Dept.";
		case 285: returnt = "S.W.A.T Special Forces";
		case 286: returnt = "Federal Agents";
		case 287: returnt = "San Andreas Army";
		case 288: returnt = "Desert Sheriff";
		case 289: returnt = "INVALID_SKIN_ID";
		case 290: returnt = "Ken Rosenberg";
		case 291: returnt = "Desert Sheriff";
		case 292: returnt = "Cesar Vialpando";
		case 293: returnt = "Jeffrey OG Loc Cross";
		case 294: returnt = "Wu Zi Mu (Woozie)";
		case 295: returnt = "Michael Toreno";
		case 296: returnt = "Jizzy B.";
		case 297: returnt = "Madd Dogg";
		case 298: returnt = "Catalina";
		case 299: returnt = "Claude";
		default: returnt = "INVALID_SKIN_ID";
	}
	return returnt;
}

// UGC System

Float:Currency(playerid)
{
    return float(Info[playerid][UGC]) / 100;
}

public OnMarketLoad(playerid) 
{
	new rows = cache_num_rows(),
		string[128], Mainstring[500],
		Seller[24], pPrice, Amount, Float:value,
		cnt = 0;

    for(new i; i < rows; i++) 
    {
        cache_get_field_content(i, "Seller", Seller);

        if(IsPlayerConnected(GetID(Seller)))
        {
            Amount = cache_get_field_content_int(i, "Amount");
            pPrice = cache_get_field_content_int(i, "Price");

            value = float(Amount) / 100;

            if(Info[GetID(Seller)][UGC] >= Amount)
            {
        	    format(string, sizeof(string),"{FFFFFF}%s {FF0066}%0.2f UGC {FFFFFF}for {FF0066}$%s\n", Seller, value, cNumber(pPrice));
        	    strcat(Mainstring, string);
                cnt++;
            }
            else
            {
                mysql_format(mysql, string, sizeof(string), "DELETE FROM `Market` FROM `playersdata` WHERE `PlayerName` = '%e'", Seller);
                mysql_tquery(mysql, string);
            }
        }
    }
    if(cnt == 0) return ShowPlayerDialog(playerid, DIALOG_SELL_MONEY+2, DIALOG_STYLE_MSGBOX, "Note", "{FF0000}No items found", "Close", "");
    else ShowPlayerDialog(playerid, DIALOG_SELL_MONEY+3, DIALOG_STYLE_LIST, "Marketplace", Mainstring, "Select", "Close");
    return 1;
}

// Property System

public LoadProperties()
{
    new rows = cache_num_rows();
 	if(rows)
  	{
   		new id, label[150];
		for(new i; i < rows; i++)
		{
  			id = cache_get_field_content_int(i, "ID");
	    	cache_get_field_content(i, "Name", pInfo[id][prName], .max_len = MAX_PROPERTY_NAME);
		    cache_get_field_content(i, "Owner", pInfo[id][Owner], .max_len = MAX_PLAYER_NAME);
		    pInfo[id][PropertyX] = cache_get_field_content_float(i, "PropertyX");
		    pInfo[id][PropertyY] = cache_get_field_content_float(i, "PropertyY");
		    pInfo[id][PropertyZ] = cache_get_field_content_float(i, "PropertyZ");
		    pInfo[id][Price] = cache_get_field_content_int(i, "Price");
		    pInfo[id][Earning] = cache_get_field_content_int(i, "Earning");
		    pInfo[id][PropertyExpire] = cache_get_field_content_int(i, "Expire");

			if(strcmp(pInfo[id][Owner], "-")) 
			{
				format(label, sizeof(label), "Property: %s\nPrice: $%s\nOwner: %s",pInfo[id][prName], cNumber(pInfo[id][Price]), pInfo[id][Owner]);

				pInfo[id][PropertyPickup] = CreateDynamicPickup(1272, 1, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]);
			}
			else
			{
		 		format(label, sizeof(label), "Property: %s\nPrice: $%s", pInfo[id][prName], cNumber(pInfo[id][Price]));

		    	pInfo[id][PropertyPickup] = CreateDynamicPickup(1273, 1, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]);
		    	pInfo[id][PropertyMapIcon] = CreateDynamicMapIcon(pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ], 31, 0, 0, 0);
		    }

			pInfo[id][PropertyLabel] = CreateDynamic3DTextLabel(label, 0xFFFF00FF, pInfo[id][PropertyX], pInfo[id][PropertyY], pInfo[id][PropertyZ]+0.35, 15.0, .testlos = 1);
			Iter_Add(Property, id);
	    }
	    printf("Loaded %d Properties", rows);
	}
}

public OnPropertyCreated(propertyid)
{
	pSave(propertyid);
	return 1;
}

public ExpireStuff()
{
	foreach(new i : Property)
	{
        if(strcmp(pInfo[i][Owner], "-"))
        {
    		if(gettime() > pInfo[i][PropertyExpire]) pReset(i);
        }
	}
    foreach(new i : Houses)
    {
        if(strcmp(HouseData[i][Owner], "-"))
        {
            if(gettime() > HouseData[i][HouseExpire]) ResetHouse(i);
        }
    }
    foreach(new i : Player)
    {
        if(Info[i][Logged] == 1)
        {
            if(Info[i][Premium] >= 1 && gettime() > Info[i][PremiumExpires])
            {
                Info[i][Premium] = 0;
                Info[i][PremiumExpires] = 0;

                if(IsValidDynamic3DTextLabel(PlayerTag[i])) DestroyDynamic3DTextLabel(PlayerTag[i]);
                TeamColorFP(i);
                for(new x = 0; x < MAX_ATTACHMENTS; x++)
                {
                    if(IsPlayerAttachedObjectSlotUsed(i, x)) RemovePlayerAttachedObject(i, x);
                }

                new query[100];
                mysql_format(mysql, query, sizeof(query), "DELETE FROM `Attachments` WHERE `ID` = %d", Info[i][ID]);
                mysql_tquery(mysql, query);

                ShowPlayerDialog(i, WARN, DIALOG_STYLE_MSGBOX, "Note", "{FFFFFF}Your premium account has been expired", "Close", "");
                SavePlayerData(i, 0, 1);
            }
            if(Info[i][Jetpack] == 1 && gettime() > Info[i][JetpackExpire])
            {
                Info[i][Jetpack] = 0;
                Info[i][JetpackExpire] = 0;
                if(GetPlayerSpecialAction(i) == SPECIAL_ACTION_USEJETPACK) ClearAnimations(i);
                SavePlayerData(i, 0, 1);
            }
        }
    }
    for(new i; i < MAX_TEAMS; i++)
    {
        if(gTeamCount[i] < 0) gTeamCount[i] = 0;
    }
}

public PropertyTimer(playerid)
{
	foreach(new i : Property)
	{
		if(pOwns(playerid, i))
	    {
		    GivePlayerCash(playerid, pInfo[i][Earning]);
	     	pInfo[i][PropertySave] = true;

	     	new string[128];
	     	format(string, sizeof(string), "Property Revenue - $%s", cNumber(pInfo[i][Earning]));
	     	WinnerText(playerid, string);
		}
	}
	return 1;
}

pOwns(playerid, propertyid)
{
	if(!IsPlayerConnected(playerid)) return 0;
	if(!strcmp(pInfo[propertyid][Owner], GetName(playerid), true)) return 1;
	return 0;
}

pSave(propertyid)
{
	new query[230];
	mysql_format(mysql, query, sizeof(query), "UPDATE `Property` SET `Owner` = '%e', `Price` = %d, `Earning` = %d, `Expire` = %d WHERE `ID` = %d",
	pInfo[propertyid][Owner], pInfo[propertyid][Price], pInfo[propertyid][Earning], pInfo[propertyid][PropertyExpire], propertyid);
	mysql_tquery(mysql, query);

	pInfo[propertyid][PropertySave] = false;
	return 1;
}

pUpdateLabel(propertyid)
{
	new label[128];
    if(strcmp(pInfo[propertyid][Owner], "-")) 
	{
        DestroyDynamicMapIcon(pInfo[propertyid][PropertyMapIcon]);

		format(label, sizeof(label), "Property: %s\nPrice: $%s\nOwner: %s", pInfo[propertyid][prName], cNumber(pInfo[propertyid][Price]), pInfo[propertyid][Owner]);
	}
	else
	{
		DestroyDynamicMapIcon(pInfo[propertyid][PropertyMapIcon]);

        pInfo[propertyid][PropertyMapIcon] = CreateDynamicMapIcon(pInfo[propertyid][PropertyX], pInfo[propertyid][PropertyY], pInfo[propertyid][PropertyZ], 31, 0, 0, 0);
 		format(label, sizeof(label), "Property: %s\nPrice: $%s", pInfo[propertyid][prName], cNumber(pInfo[propertyid][Price]));
    }

	UpdateDynamic3DTextLabelText(pInfo[propertyid][PropertyLabel], 0xFFFF00FF, label);
	return 1;
}

pReset(propertyid)
{
    if(IsPlayerConnected(GetID(pInfo[propertyid][Owner])))
    {
        GivePlayerCash(GetID(pInfo[propertyid][Owner]), pInfo[propertyid][Price]);
    }
    else
    {
        new query[80];
        mysql_format(mysql, query, sizeof(query), 
        "UPDATE `playersdata` SET `Money` = `Money` + %i  WHERE `PlayerName` = '%e'", pInfo[propertyid][Price], pInfo[propertyid][Owner]);
        mysql_tquery(mysql, query);
    }

	format(pInfo[propertyid][prName], MAX_PROPERTY_NAME, "");
	format(pInfo[propertyid][Owner], MAX_PLAYER_NAME, "");

	pInfo[propertyid][PropertyExpire] = 0;

	pUpdateLabel(propertyid);
	pSave(propertyid);
	return 1;
}

stock cNumber(integer, const separator[] = ",") 
{ 
    new string[16]; 
    valstr(string, integer); 

    if(integer >= 1000) 
    { 
        for(new i = (strlen(string) - 3); i > 0; i -= 3) 
        { 
            strins(string, separator, i); 
        } 
    } 
    return string; 
}

// Friends System

GetID(name[])
{
	foreach(new i : Player)
	{
	    if(!strcmp(GetName(i), name, true)) return i;
	}
	return INVALID_PLAYER_ID;
}

// Marijuana System

public PlantGrow()
{
    for(new i = 0; i < sizeof(PlantInfo); i++)
	{
	    if(PlantInfo[i][Status] == 1)
	    {
	        PlantInfo[i][Time] --;
	        new string[128];
         	new hours = PlantInfo[i][Time] / 60;
			format(string,sizeof(string),"Time Left: %d:%02d\nOwner: %s", hours % 60, PlantInfo[i][Time], PlantInfo[i][Owner]);
			Update3DTextLabelText(PlantInfo[i][Label], 0xFFFF00FF, string);
			if(PlantInfo[i][Time] == 45)
			{
			    CA_DestroyObject_DC(PlantInfo[i][ID]);
			    PlantInfo[i][ID] = CA_CreateDynamicObject_DC(677, PlantInfo[i][pX],PlantInfo[i][pY],PlantInfo[i][pZ]-1, 0.0, 0.0, 0.0, 0);
			}
			if(PlantInfo[i][Time] == 30)
			{
			    CA_DestroyObject_DC(PlantInfo[i][ID]);
			    PlantInfo[i][ID] = CA_CreateDynamicObject_DC(678, PlantInfo[i][pX],PlantInfo[i][pY],PlantInfo[i][pZ]-1, 0.0, 0.0, 0.0, 0);
			}
			if(PlantInfo[i][Time] == 15)
			{
			    CA_DestroyObject_DC(PlantInfo[i][ID]);
			    PlantInfo[i][ID] = CA_CreateDynamicObject_DC(824, PlantInfo[i][pX],PlantInfo[i][pY],PlantInfo[i][pZ]-1, 0.0, 0.0, 0.0, 0);
			}
	        if(PlantInfo[i][Time] <= 0)
	        {
				PlantReady(i);
	        }
	    }
	}
}

public PlantMarijuana(playerid)
{
	new Float:x,Float:y,Float:z;
	GetPlayerPos(playerid,x,y,z);

	if(CreatePlant(x, y, z, GetName(playerid)))
	{
		ShowInfoBox(playerid, 0x00000088, 5, "You have planted a marijuana plant for 5 seeds, Press Y once it grow up to pick it");
        Info[playerid][Seeds] -= 5;
        return 1;
	}
	else return ShowInfoBox(playerid, 0x00000088, 5, "Failed to plant");
}

stock DestroyPlant(plantid)
{
    CA_DestroyObject_DC(PlantInfo[plantid][ID]);
    Delete3DTextLabel(PlantInfo[plantid][Label]);
    PlantInfo[plantid][pX] = 0;
    PlantInfo[plantid][pY] = 0;
    PlantInfo[plantid][pZ] = 0;
    PlantInfo[plantid][ID] = -1;
    PlantInfo[plantid][Status] = 0;
    PlantInfo[plantid][Time] = -1;
	return 1;
}

stock CreatePlant(Float:x11, Float:y11, Float:z11, name[24])
{
    for(new i = 0; i < sizeof(PlantInfo); i++)
	{
	    if(PlantInfo[i][Status] == 0)
	    {
	        new string[128];
		    PlantInfo[i][ID] = CA_CreateDynamicObject_DC(675, x11,y11,z11-1, 0.0, 0.0, 0.0, 0);
			PlantInfo[i][pX] = x11;
			PlantInfo[i][pY] = y11;
			PlantInfo[i][pZ] = z11;
			PlantInfo[i][Time] = 60;
			PlantInfo[i][Status] = 1;
			PlantInfo[i][Owner] = name;
			new hours = PlantInfo[i][Time] / 60;

			if(hours >= 1)
			{
				format(string,sizeof(string),"Time Left: %02d:00\nOwner: %s",hours,PlantInfo[i][Owner]);
			}
			else
			{
				format(string,sizeof(string),"Time Left: 00:%02d\nOwner: %s",PlantInfo[i][Time],PlantInfo[i][Owner]);
			}

			PlantInfo[i][Label] = Create3DTextLabel(string, 0xFFFF00FF, x11,y11,z11-0.7, 10.0, 0, 0);
			return 1;
		}
	}
	return 0;
}

stock IsNearPlant(playerid)
{
    for(new i = 0; i < sizeof(PlantInfo); i++)
	{
	    if(PlantInfo[i][Status] != 0)
	    {
    		if(IsPlayerInRangeOfPoint(playerid, 3.0, PlantInfo[i][pX], PlantInfo[i][pY], PlantInfo[i][pZ]))
   			{
   			    return i;
   			}
		}
	}
	return -1;
}

stock CreateFarm(Float:cfx,Float:cfx1,Float:cfy,Float:cfy1)
{
	FarmInfo[0][fx] = cfx;
	FarmInfo[0][fx1] = cfx1;
	FarmInfo[0][fy] = cfy;
	FarmInfo[0][fy1] = cfy1;
	return 1;
}

stock IsPlayerAtFarm(playerid)
{
	new Float:x,Float:y,Float:z;
	GetPlayerPos(playerid, x, y, z);
	for(new i = 0; i < sizeof(FarmInfo); i++)
	{
   	    if (x <= FarmInfo[i][fx1] && x >= FarmInfo[i][fx] && y <= FarmInfo[i][fy1] && y >= FarmInfo[i][fy])
		{
			return 1;
		}
	}
    return 0;
}

stock PlantReady(plantid)
{
	PlantInfo[plantid][Status] = 2;
	CA_DestroyObject_DC(PlantInfo[plantid][ID]);
 	PlantInfo[plantid][ID] = CA_CreateDynamicObject_DC(682, PlantInfo[plantid][pX],PlantInfo[plantid][pY],PlantInfo[plantid][pZ]-1, 0.0, 0.0, 0.0, 0);
    new string[128];
	format(string,sizeof(string),"{00FF00}READY\n{FFFF00}Owner: %s",PlantInfo[plantid][Owner]);
	Update3DTextLabelText(PlantInfo[plantid][Label], 0xFFFF00FF, string);

    if(IsPlayerConnected(GetID(PlantInfo[plantid][Owner])))
    {
        SendClientMessage(GetID(PlantInfo[plantid][Owner]), green, "Your marijuana plant is ready to be picked up");
    }
	return 1;
}

// Teleports

stock LoadTeleports()
{
    new temp[200],file[100];
    format(file, 100, SETTING_PATH, "Teleports");
    if(!fexist(file))
    {
          printf("--No Teleports File/Path Found!--\nCreating a new file..");
          new File:JLnew = fopen(file, io_write);
          if(JLnew)
          {
            fclose(JLnew);
          }
          printf("\n Teleports file successfully created: %s\n", file);
          return 1;
    }
    TeleCount = 0;
    new File:Jfile = fopen(file, io_read);
    while(fread(Jfile,temp,sizeof(temp),false))
    {
        if(strlen(temp) < 10) continue;
        if(TeleCount >= MAX_TELEPORTS -1)
        {
           printf("WARNING: Exceeded maximum teleports amount. Please delete some\n teleports from %s !",file);
           break;
        }
        if(sscanf(temp, "s[30]fffii",TeleName[TeleCount], TeleCoords[TeleCount][0], TeleCoords[TeleCount][1], TeleCoords[TeleCount][2], Teleinfo[TeleCount][0], Teleinfo[TeleCount][1])) continue;
        if(strfind(TeleName[TeleCount],"_",true) != -1 )
        {
            new i = 0;
            while (TeleName[TeleCount][i])
            {
                if (TeleName[TeleCount][i] == '_')
                TeleName[TeleCount][i] = ' ';
                i++;
            }
        }
        TeleCount++;
    }
    fclose(Jfile);
    if(TeleCount == 0) printf("--No Teleports loaded!--");
    else printf("--%d Teleports loaded!--",TeleCount);
    return 1;
}

// House System

public LoadHouses()
{
    new rows = cache_num_rows();
    if(rows)
    {
        new id, loaded, available, label[128];
        while(loaded < rows)
        {
            id = cache_get_field_content_int(loaded, "ID");
            cache_get_field_content(loaded, "HouseOwner", HouseData[id][Owner], .max_len = MAX_PLAYER_NAME);
            HouseData[id][houseX] = cache_get_field_content_float(loaded, "HouseX");
            HouseData[id][houseY] = cache_get_field_content_float(loaded, "HouseY");
            HouseData[id][houseZ] = cache_get_field_content_float(loaded, "HouseZ");
            HouseData[id][Price] = cache_get_field_content_int(loaded, "HousePrice");
            HouseData[id][Interior] = cache_get_field_content_int(loaded, "HouseInterior");
            HouseData[id][LockMode] = cache_get_field_content_int(loaded, "HouseLock");
            HouseData[id][SafeMoney] = cache_get_field_content_int(loaded, "HouseMoney");
            HouseData[id][HouseExpire] = cache_get_field_content_int(loaded, "HouseExpire");

            if(strcmp(HouseData[id][Owner], "-")) 
            {
                available = 0;
                format(label, sizeof(label), "House: %d\nPrice: $%s\nOwner: %s", id, cNumber(HouseData[id][Price]), HouseData[id][Owner]);
            }
            else
            {
                available = 1;
                format(label, sizeof(label), "House: %d\nPrice: $%s", id, cNumber(HouseData[id][Price]));
                HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], 31, 0);     
            }

            HouseData[id][HousePickup] = CreateDynamicPickup(available == 1 ? 1273 : 1272, 1, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
            HouseData[id][HouseLabel] = CreateDynamic3DTextLabel(label, 0xFFFF00FF, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]+0.35, 15.0, .testlos = 1);
            Iter_Add(Houses, id);
            loaded++;
        }
        printf("Loaded %d Houses", loaded);
    }
    return 1;
}

public GiveHouseKeys(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    new rows = cache_num_rows();
    if(rows)
    {
        new loaded;
        while(loaded < rows)
        {
            Iter_Add(HouseKeys[playerid], cache_get_field_content_int(loaded, "HouseID"));
            loaded++;
        }
    }
    return 1;
}

stock LoadHouseKeys(playerid)
{
    Iter_Clear(HouseKeys[playerid]);
    
    new query[72];
    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `HouseKeys` WHERE `Player` = '%e'", GetName(playerid));
    mysql_tquery(mysql, query, "GiveHouseKeys", "i", playerid);
    return 1;
}

stock RemovePlayerWeapon(playerid, weaponid)
{
    new plyWeapons[12], plyAmmo[12];

    for(new slot; slot != 12; slot ++)
    {
        new weap, ammo;
            
        GetPlayerWeaponData(playerid, slot, weap, ammo);
        if(weap != weaponid)
        {
            GetPlayerWeaponData(playerid, slot, plyWeapons[slot], plyAmmo[slot]);
        }
    }

    ResetPlayerWeaponsEx(playerid);

    for(new slot; slot != 12; slot ++)
    {
        GivePlayerWeaponEx(playerid, plyWeapons[slot], plyAmmo[slot]);
    }
}

stock SendToHouse(playerid, id)
{
    if(!Iter_Contains(Houses, id)) return 0;
    InHouse[playerid] = id;
    SetPlayerVirtualWorld(playerid, id);
    SetPlayerInterior(playerid, HouseInteriors[ HouseData[id][Interior] ][intID]);
    SetPlayerPos(playerid, HouseInteriors[ HouseData[id][Interior] ][intX], HouseInteriors[ HouseData[id][Interior] ][intY], HouseInteriors[ HouseData[id][Interior] ][intZ]);


    if(!strcmp(HouseData[id][Owner], GetName(playerid)))
    {
        HouseData[id][HouseSave] = true;
    }

    if(HouseData[id][LockMode] == STATUS_NOLOCK && LastVisitedHouse[playerid] != id)
    {
        new query[128];
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `HouseVisitors` SET `HouseID` = %d, `Visitor` = '%e', `Date` = UNIX_TIMESTAMP()", id, GetName(playerid));
        mysql_tquery(mysql, query);
        LastVisitedHouse[playerid] = id;
    }

    return 1;
}

stock ShowHouseMenu(playerid)
{
    if(strcmp(HouseData[ InHouse[playerid] ][Owner], GetName(playerid))) return SendClientMessage(playerid, red, "You're not the owner of this house");

    new string[140], id = InHouse[playerid];
    format(string, sizeof(string), "{FFFFFF}Lock: {00FF00}%s\n{FFFFFF}House Safe {00FF00}$%s\n{FFFFFF}Guns\n{FFFFFF}Visitors\n{FFFFFF}Keys\n{FFFFFF}Kick Everybody",
    LockNames[ HouseData[id][LockMode] ], cNumber(HouseData[id][SafeMoney]));
    ShowPlayerDialog(playerid, DIALOG_HOUSE_MENU, DIALOG_STYLE_LIST, "House Settings", string, "Select", "Close");
    return 1;
}

stock ResetHouse(id)
{
    if(!Iter_Contains(Houses, id)) return 0;
    format(HouseData[id][Owner], MAX_PLAYER_NAME, "-");
    HouseData[id][LockMode] = STATUS_NOLOCK;
    HouseData[id][SalePrice] = HouseData[id][SafeMoney] = HouseData[id][HouseExpire] = 0;
    HouseData[id][HouseSave] = true;

    foreach(new i : Player)
    {
        if(InHouse[i] == id)
        {
            SetPlayerVirtualWorld(i, 0);
            SetPlayerInterior(i, 0);
            SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
            InHouse[i] = INVALID_HOUSE_ID;
        }

        if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
    }

    new query[120];
    mysql_format(mysql, query, sizeof(query), "UPDATE `Houses` SET `HouseOwner` = '-', `HouseExpire` = 0 WHERE `ID` = %d", id);
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseGuns` WHERE `HouseID` = %d", id);
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseVisitors` WHERE `HouseID` = %d", id);
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseKeys` WHERE `HouseID` = %d", id);
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query), "DELETE FROM `HouseSafeLogs` WHERE `HouseID` = %d", id);
    mysql_tquery(mysql, query);

    new label[120];
    format(label, sizeof(label), "House: %d\nPrice: $%s", id, cNumber(HouseData[id][Price]));

    Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1273);
    Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);
    UpdateDynamic3DTextLabelText(HouseData[id][HouseLabel], 0xFFFF00FF, label);
    return 1;
}

stock SaveHouse(id)
{
    if(!Iter_Contains(Houses, id)) return 0;

    new query[230];
    mysql_format(mysql, query, sizeof(query), "UPDATE `Houses` SET `HouseOwner` = '%e', `HouseLock` = %d, `HouseMoney` = %d, `HouseExpire` = %d WHERE `ID` = %d",
    HouseData[id][Owner], HouseData[id][LockMode], HouseData[id][SafeMoney], HouseData[id][HouseExpire], id);
    mysql_tquery(mysql, query);
    HouseData[id][HouseSave] = false;
    return 1;
}

stock UpdateHouseLabel(id)
{
    if(!Iter_Contains(Houses, id)) return 0;

    new label[128];
    if(!strcmp(HouseData[id][Owner], "-")) 
    {
        format(label, sizeof(label), "House: %d\nPrice: $%s", id, cNumber(HouseData[id][Price]));
        if(!IsValidDynamicMapIcon(HouseData[id][HouseIcon]))
        {
            HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], 31, 0);
            Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);
        }
    }
    else
    {
        format(label, sizeof(label), "House: %d\nPrice: $%s\nOwner: %s", id, cNumber(HouseData[id][Price]), HouseData[id][Owner]);
        if(IsValidDynamicMapIcon(HouseData[id][HouseIcon])) DestroyDynamicMapIcon(HouseData[id][HouseIcon]);
    }

    UpdateDynamic3DTextLabelText(HouseData[id][HouseLabel], 0xFFFF00FF, label);
    return 1;
}

stock House_PlayerInit(playerid)
{
    InHouse[playerid] = LastVisitedHouse[playerid] = INVALID_HOUSE_ID;
    ListPage[playerid] = SelectMode[playerid] = SELECT_MODE_NONE;
    LoadHouseKeys(playerid);
    return 1;
}

// Get pos before Minigame

stock SpawnPlayerEx(playerid)
{
    SetPlayerPos(playerid, LastPosX[playerid], LastPosY[playerid], LastPosZ[playerid]);
    SetPlayerInterior(playerid, LastInterior[playerid]);
    SetPlayerHealthEx(playerid, LastHealth[playerid]);
    SetPlayerArmourEx(playerid, LastArmour[playerid]);
    SetPlayerSkin(playerid, OldSkin[playerid]);
    InJob[playerid] = NOJOB;

    new query[100];
    mysql_format(mysql, query, sizeof(query), "SELECT `Weapon`, `Ammo` FROM `Weapons` WHERE `ID` = %d", Info[playerid][ID]);
    mysql_tquery(mysql, query, "OnWeaponLoad", "i", playerid);
    return 1;
}

stock GetPlayerSpawnEx(playerid)
{
    new Float:x, Float:y, Float:z, Float:itsHP, Float:itsArmour;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerHealth(playerid, itsHP);
    GetPlayerArmour(playerid, itsArmour);

    LastPosX[playerid] = x;
    LastPosY[playerid] = y;
    LastPosZ[playerid] = z;
    LastHealth[playerid] = itsHP;
    LastArmour[playerid] = itsArmour;
    LastInterior[playerid] = GetPlayerInterior(playerid);
    OldSkin[playerid] = GetPlayerSkin(playerid);
    InJob[playerid] = NOJOB;

    new query[128], weaponid, ammo;
    for(new i; i < 13; i++)
    {
        GetPlayerWeaponData(playerid, i, weaponid, ammo);

        if(!weaponid) continue;

        mysql_format(mysql, query, sizeof(query), "INSERT INTO `Weapons` (ID, Weapon, Ammo) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE `Ammo` = %d", Info[playerid][ID], weaponid, ammo, ammo);
        mysql_tquery(mysql, query);
    }
    ResetPlayerWeapons(playerid);
    return 1;
}

// Jobs

function LeaveVehicleJob(playerid)
{
    if(InJob[playerid] == PARAMEDIC)
    {
        KillTimer(LeaveVehTimer[playerid]);
        InJob[playerid] = NOJOB;
        SCM(playerid, red, "You have left the vehicle");
        foreach(new i : Player) 
        {
            SetPlayerMarkerForPlayer(playerid, i, GetPlayerColor(playerid));
        }
    }
}

// Private Vehicle System

public LoadDealerVehicles()
{
    new rows = cache_num_rows();
    if(rows)
    {
        new string[84];
        for(new i; i < rows; i++)
        {
            new id = Iter_Free(ServerVehicles);
            
            cache_get_field_content(i, "vehOwner", vInfo[id][vehOwner], .max_len = MAX_PLAYER_NAME);
            vInfo[id][vehModel] = cache_get_field_content_int(i, "vehModel");
            cache_get_field_content(i, "vehName", vInfo[id][vehName]);
            cache_get_field_content(i, "vehPlate", vInfo[id][vehPlate]);
            vInfo[id][vehPrice] = cache_get_field_content_int(i, "vehPrice");
            vInfo[id][vehColorOne] = cache_get_field_content_int(i, "vehColorOne");
            vInfo[id][vehColorTwo] = cache_get_field_content_int(i, "vehColorTwo");
            vInfo[id][vehX] = cache_get_field_content_float(i, "vehX");
            vInfo[id][vehY] = cache_get_field_content_float(i, "vehY");
            vInfo[id][vehZ] = cache_get_field_content_float(i, "vehZ");
            vInfo[id][vehA] = cache_get_field_content_float(i, "vehA");

            vInfo[id][vehSessionID] = CreateVehicle(vInfo[id][vehModel], vInfo[id][vehX], vInfo[id][vehY], vInfo[id][vehZ], vInfo[id][vehA], vInfo[id][vehColorOne], vInfo[id][vehColorTwo], -1);

            vInfo[id][vehID] = cache_get_field_content_int(i, "vehID");

            SetVehicleToRespawn(vInfo[id][vehSessionID]);
            SetVehicleParamsEx(vInfo[id][vehSessionID], 0, 0, 0, 1, 0, 0, 0);
            SetVehicleNumberPlate(vInfo[id][vehSessionID], "UG");

            format(string, sizeof(string), "VehicleID: %d\nVehicle: %s\nPrice: $%s\nType /buyvehicle to buy!", id, vInfo[id][vehName], cNumber(vInfo[id][vehPrice]));

            vInfo[id][vehLabel] = CreateDynamic3DTextLabel(string, 0xFFFF00FF, vInfo[id][vehX], vInfo[id][vehY], vInfo[id][vehZ], 10.0, INVALID_PLAYER_ID, vInfo[id][vehSessionID]);
            Iter_Add(ServerVehicles, id);
        }
        printf("Loaded %d vehicles for dealership", rows);
    }
    return 1;
}

public LoadPlayerVehicles(playerid)
{
    new rows = cache_num_rows();
    if(rows)
    {
        for(new i; i < rows; i++)
        {
            new id = Iter_Free(ServerVehicles);

            cache_get_field_content(i, "vehOwner", vInfo[id][vehOwner], .max_len = MAX_PLAYER_NAME);
            vInfo[id][vehModel] = cache_get_field_content_int(i, "vehModel");
            cache_get_field_content(i, "vehName", vInfo[id][vehName]);
            cache_get_field_content(i, "vehPlate", vInfo[id][vehPlate], .max_len = 16);
            vInfo[id][vehPrice] = cache_get_field_content_int(i, "vehPrice");
            vInfo[id][vehLock] = cache_get_field_content_int(i, "vehLock");
            vInfo[id][vehMod][0] = cache_get_field_content_int(i, "vehMod_1");
            vInfo[id][vehMod][1] = cache_get_field_content_int(i, "vehMod_2");
            vInfo[id][vehMod][2] = cache_get_field_content_int(i, "vehMod_3");
            vInfo[id][vehMod][3] = cache_get_field_content_int(i, "vehMod_4");
            vInfo[id][vehMod][4] = cache_get_field_content_int(i, "vehMod_5");
            vInfo[id][vehMod][5] = cache_get_field_content_int(i, "vehMod_6");
            vInfo[id][vehMod][6] = cache_get_field_content_int(i, "vehMod_7");
            vInfo[id][vehMod][7] = cache_get_field_content_int(i, "vehMod_8");
            vInfo[id][vehMod][8] = cache_get_field_content_int(i, "vehMod_9");
            vInfo[id][vehMod][9] = cache_get_field_content_int(i, "vehMod_10");
            vInfo[id][vehMod][10] = cache_get_field_content_int(i, "vehMod_11");
            vInfo[id][vehMod][11] = cache_get_field_content_int(i, "vehMod_12");
            vInfo[id][vehMod][12] = cache_get_field_content_int(i, "vehMod_13");
            vInfo[id][vehMod][13] = cache_get_field_content_int(i, "vehMod_14");
            vInfo[id][vehColorOne] = cache_get_field_content_int(i, "vehColorOne");
            vInfo[id][vehColorTwo] = cache_get_field_content_int(i, "vehColorTwo");
            vInfo[id][vehHydraulics] = cache_get_field_content_int(i, "vehHydraulics");
            vInfo[id][vehNitro] = cache_get_field_content_int(i, "vehNitro");
            vInfo[id][vehX] = cache_get_field_content_float(i, "vehX");
            vInfo[id][vehY] = cache_get_field_content_float(i, "vehY");
            vInfo[id][vehZ] = cache_get_field_content_float(i, "vehZ");
            vInfo[id][vehA] = cache_get_field_content_float(i, "vehA");

            vInfo[id][vehSessionID] = CreateVehicle(vInfo[id][vehModel], vInfo[id][vehX], vInfo[id][vehY], vInfo[id][vehZ], vInfo[id][vehA], vInfo[id][vehColorOne], vInfo[id][vehColorTwo], -1);

            vInfo[id][vehID] = cache_get_field_content_int(i, "vehID");

            format(vInfo[id][vehName], MAX_PLAYER_NAME, GetVehicleName(vInfo[id][vehModel]));
            format(vInfo[id][vehPlate], 16, vInfo[id][vehPlate]);
            format(vInfo[id][vehOwner], MAX_PLAYER_NAME, GetName(playerid));

            SetVehicleToRespawn(vInfo[id][vehSessionID]);
            SetVehicleParamsEx(vInfo[id][vehSessionID], 0, 0, 0, vInfo[id][vehLock], 0, 0, 0);
            SetVehicleNumberPlate(vInfo[id][vehSessionID], vInfo[id][vehPlate]);
            for(new x = 0; x < 14; x++) if(vInfo[id][vehMod][x] > 0) AddVehicleComponent(vInfo[id][vehSessionID], vInfo[id][vehMod][x]);

            switch(vInfo[id][vehNitro]) {

                case 1: AddVehicleComponent(vInfo[id][vehSessionID], 1009);
                case 2: AddVehicleComponent(vInfo[id][vehSessionID], 1008);
                case 3: AddVehicleComponent(vInfo[id][vehSessionID], 1010);
            }

            if(vInfo[id][vehHydraulics] == 1)
                AddVehicleComponent(vInfo[id][vehSessionID], 1087);

            Iter_Add(PrivateVehicles[playerid], id);
            Iter_Add(ServerVehicles, id);
        }
        printf("Loaded %d vehicles for %s", rows, GetName(playerid));
    }
    return 1;
}

stock SaveVehicle(vehicleid)
{
    if(!Iter_Contains(ServerVehicles, vehicleid)) return 0;

    format(vInfo[vehicleid][vehName], 16, GetVehicleName(vInfo[vehicleid][vehModel]));
    GetVehiclePos(vInfo[vehicleid][vehSessionID], vInfo[vehicleid][vehX], vInfo[vehicleid][vehY], vInfo[vehicleid][vehZ]);
    GetVehicleZAngle(vInfo[vehicleid][vehSessionID], vInfo[vehicleid][vehA]);

    new query[660];
    mysql_format(mysql, query, sizeof(query), "UPDATE `Vehicles` SET `vehName` = '%e', `vehOwner` = '%e', `vehLock` = %i, `vehModel` = %i,\
    `vehPlate` = '%e', `vehMod_1` = %i, `vehMod_2` = %i, `vehMod_3` = %i, `vehMod_4` = %i, `vehMod_5` = %i, `vehMod_6` = %i, `vehMod_7` = %i,\
    `vehMod_8` = %i, `vehMod_9` = %i, `vehMod_10` = %i, `vehMod_11` = %i, `vehMod_12` = %i, `vehMod_13` = %i, `vehMod_14` = %i, `vehColorOne` = %i,\
    `vehColorTwo` = %i, `vehHydraulics` = %i, `vehNitro` = %i, `vehX` = %f, `vehY` = %f, `vehZ` = %f, `vehA` = %f WHERE `vehID` = %d", vInfo[vehicleid][vehName], 
    vInfo[vehicleid][vehOwner], vInfo[vehicleid][vehLock], vInfo[vehicleid][vehModel], vInfo[vehicleid][vehPlate], vInfo[vehicleid][vehMod][0], vInfo[vehicleid][vehMod][1], 
    vInfo[vehicleid][vehMod][2], vInfo[vehicleid][vehMod][3], vInfo[vehicleid][vehMod][4], vInfo[vehicleid][vehMod][5], vInfo[vehicleid][vehMod][6], vInfo[vehicleid][vehMod][7],
    vInfo[vehicleid][vehMod][8], vInfo[vehicleid][vehMod][9], vInfo[vehicleid][vehMod][10], vInfo[vehicleid][vehMod][11], vInfo[vehicleid][vehMod][12], vInfo[vehicleid][vehMod][13], 
    vInfo[vehicleid][vehColorOne], vInfo[vehicleid][vehColorTwo], vInfo[vehicleid][vehHydraulics], vInfo[vehicleid][vehNitro], vInfo[vehicleid][vehX], vInfo[vehicleid][vehY], 
    vInfo[vehicleid][vehZ], vInfo[vehicleid][vehA], vInfo[vehicleid][vehID]);
    mysql_tquery(mysql, query);
    return 1;
}

stock ResetVehicle(vehicleid)
{
    if(!Iter_Contains(ServerVehicles, vehicleid)) return 0;

    foreach(new i : Player)
    {
        if(!strcmp(vInfo[vehicleid][vehOwner], GetName(i))) 
        {
            Iter_Remove(PrivateVehicles[i], vehicleid);
            Info[i][vehLimit]--;
        }
    }

    format(vInfo[vehicleid][vehOwner], MAX_PLAYER_NAME, "-");
    format(vInfo[vehicleid][vehPlate], 16, "UG");

    vInfo[vehicleid][vehModel] = -1; 
    vInfo[vehicleid][vehLock] = MODE_NOLOCK;
    vInfo[vehicleid][vehPrice] = 0;
    vInfo[vehicleid][vehColorOne] = -1;
    vInfo[vehicleid][vehColorTwo] = -1;

    for(new i = 0; i < 14; i++)
    {
        if(vInfo[vehicleid][vehMod][i] > 0)
        {
            RemoveVehicleComponent(vInfo[vehicleid][vehSessionID], vInfo[vehicleid][vehMod][i]);
            vInfo[vehicleid][vehMod][i] = 0;
        }
    }

    if(IsValidDynamic3DTextLabel(vInfo[vehicleid][vehLabel])) DestroyDynamic3DTextLabel(vInfo[vehicleid][vehLabel]);
    DestroyVehicle(vInfo[vehicleid][vehSessionID]);
    return 1;
}

public OnDealerVehicleCreated(vehicleid)
{
    vInfo[vehicleid][vehID] = cache_insert_id(); 
    Iter_Add(ServerVehicles, vehicleid);
    return 1;
}

createVehicle(vehicleid, Float:itsX, Float:itsY, Float:itsZ, Float:itsA, bool:removeold = false)
{
    if(removeold == true)
    {
        DestroyVehicle(vInfo[vehicleid][vehSessionID]);
    }

    vInfo[vehicleid][vehSessionID] = CreateVehicle(vInfo[vehicleid][vehModel], itsX, itsY, itsZ, itsA, vInfo[vehicleid][vehColorOne], vInfo[vehicleid][vehColorTwo], -1);
    format(vInfo[vehicleid][vehName], MAX_PLAYER_NAME, GetVehicleName(vInfo[vehicleid][vehModel]));
    SetVehicleToRespawn(vInfo[vehicleid][vehSessionID]);
    SetVehicleParamsEx(vInfo[vehicleid][vehSessionID], 1, 1, 0, vInfo[vehicleid][vehLock], 0, 0, 0);
    SetVehicleNumberPlate(vInfo[vehicleid][vehSessionID], vInfo[vehicleid][vehPlate]);
    for(new x = 0; x < 14; x++) if(vInfo[vehicleid][vehMod][x] > 0) AddVehicleComponent(vInfo[vehicleid][vehSessionID], vInfo[vehicleid][vehMod][x]);
    ChangeVehicleColor(vInfo[vehicleid][vehSessionID], vInfo[vehicleid][vehColorOne], vInfo[vehicleid][vehColorTwo]);

    switch(vInfo[vehicleid][vehNitro]) {

        case 1: AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1009);
        case 2: AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1008);
        case 3: AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1010);
    }
    if(vInfo[vehicleid][vehHydraulics] == 1) {

        AddVehicleComponent(vInfo[vehicleid][vehSessionID], 1087);
    }
    return 1;
}

GetVehicleName(modelid) return VehicleNames[modelid - 400];

// Weapon Drops

CreateStaticPickup(modelid, ammount, type, Float:x, Float:y, Float:z, interior = -1, virtualworld = -1) 
{
    for (new i; i < MAX_DROPS; i++) 
    {
        if (!IsValidStaticPickup(i)) 
        {
            g_StaticPickup[i][pickupModel] = modelid;
            g_StaticPickup[i][pickupAmount] = ammount;
            g_StaticPickup[i][pickupPickupid] = CreateDynamicPickup(modelid, type, x, y, z, virtualworld, interior);
            g_StaticPickup[i][pickupTimer] = SetTimerEx("OnAutoPickupDestroy", 60 * 1000, false, "i", i);
            return i;
        }
    }
    return -1;
}

DestroyStaticPickup(pickupid) 
{
    DestroyDynamicPickup(g_StaticPickup[pickupid][pickupPickupid]);

    if(g_StaticPickup[pickupid][pickupTimer] != -1) 
    {
        KillTimer(g_StaticPickup[pickupid][pickupTimer]);
    }
    g_StaticPickup[pickupid][pickupTimer] = -1;
    return true;
}

IsValidStaticPickup(pickupid) return IsValidDynamicPickup(g_StaticPickup[pickupid][pickupPickupid]);

public OnAutoPickupDestroy(pickupid) return DestroyStaticPickup(pickupid);

GetModelWeaponID(weaponid) 
{
    switch (weaponid) 
    {
        case 331: return 1;
        case 333: return 2;
        case 334: return 3;
        case 335: return 4;
        case 336: return 5;
        case 337: return 6;
        case 338: return 7;
        case 339: return 8;
        case 341: return 9;
        case 321: return 10;
        case 322: return 11;
        case 323: return 12;
        case 324: return 13;
        case 325: return 14;
        case 326: return 15;
        case 342: return 16;
        case 343: return 17;
        case 344: return 18;
        case 346: return 22;
        case 347: return 23;
        case 348: return 24;
        case 349: return 25;
        case 350: return 26;
        case 351: return 27;
        case 352: return 28;
        case 353: return 29;
        case 355: return 30;
        case 356: return 31;
        case 372: return 32;
        case 357: return 33;
        case 358: return 34;
        case 359: return 35;
        case 360: return 36;
        case 361: return 37;
        case 362: return 38;
        case 363: return 39;
        case 364: return 40;
        case 365: return 41;
        case 366: return 42;
        case 367: return 43;
        case 368: return 44;
        case 369: return 45;
        case 371: return 46;
    }
    return -1;
}

GetWeaponModelID(weaponid) 
{
    switch (weaponid) 
    {
        case 1: return 331;
        case 2: return 333;
        case 3: return 334;
        case 4: return 335;
        case 5: return 336;
        case 6: return 337;
        case 7: return 338;
        case 8: return 339;
        case 9: return 341;
        case 10: return 321;
        case 11: return 322;
        case 12: return 323;
        case 13: return 324;
        case 14: return 325;
        case 15: return 326;
        case 16: return 342;
        case 17: return 343;
        case 18: return 344;
        case 22: return 346;
        case 23: return 347;
        case 24: return 348;
        case 25: return 349;
        case 26: return 350;
        case 27: return 351;
        case 28: return 352;
        case 29: return 353;
        case 30: return 355;
        case 31: return 356;
        case 32: return 372;
        case 33: return 357;
        case 34: return 358;
        case 35: return 359;
        case 36: return 360;
        case 37: return 361;
        case 38: return 362;
        case 39: return 363;
        case 40: return 364;
        case 41: return 365;
        case 42: return 366;
        case 43: return 367;
        case 44: return 368;
        case 45: return 369;
        case 46: return 371;
    }
    return -1;
}

// Attachment System

public OnPlayerModelSelection(playerid, response, listid, modelid)
{
    if(listid == objectlist)
    {
        if(response)
        {
            inmodel[playerid] = modelid;
            ShowPlayerDialog(playerid, DIALOG_ATTACHMENTS_SAVE, DIALOG_STYLE_LIST, "Bone", "Spine\nHead\nLeft Upper Arm\nRight Upper Arm\nLeft Hand\nRight Hand\nLeft Tight\
            \nRight Tight\nLeft Foot\nRight Foot\nRight Calf\nLeft Calf\nLeft Forearm\nRight Forearm\nLeft Shoulder\nRight Shoulder\nNeck\nJaw", "Select", "Cancel");
        }
        return 1;
    }
    if(listid == Airplanes || listid == Bikes || listid == Boats || listid == Convertible || listid == Helicopters || 
    listid == Industrials || listid == Lowrider || listid == OffRoad || listid == PublicService || listid == Saloon || 
    listid == Sports || listid == StationWagon || listid == Unique)
    {
        if(response)
        {
            if(Info[playerid][Premium] == 1 && GetPlayerCash(playerid) < 2500) return SCM(playerid, red, "You don't have enough money");
            else if(Info[playerid][Premium] == 0 && GetPlayerCash(playerid) < 5000) return SCM(playerid, red, "You don't have enough money");

            DestroyVehicle(playerCar[playerid]);

            new Float:pos[4], color[2];
            GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
            GetPlayerFacingAngle(playerid, pos[3]);

            color[0] = random(256);
            color[1] = random(256);

            playerCar[playerid] = CreateVehicle(modelid, pos[0], pos[1], pos[2]+2.0, pos[3], color[0], color[1], -1);
            PutPlayerInVehicle(playerid, playerCar[playerid], 0);

            if(Info[playerid][Premium] == 1) GivePlayerCash(playerid, -2500);
            else GivePlayerCash(playerid, -5000);
        }
        return 1;
    }
    return 1;
}

public OnPlayerEditAttachedObject(playerid, response, index, modelid, boneid, Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ, Float:fRotX, Float:fRotY, Float:fRotZ, Float:fScaleX, Float:fScaleY, Float:fScaleZ)
{
    oInfo[playerid][index][fOffsetX1] = fOffsetX;
    oInfo[playerid][index][fOffsetY1] = fOffsetY;
    oInfo[playerid][index][fOffsetZ1] = fOffsetZ;
    oInfo[playerid][index][fRotX1] = fRotX;
    oInfo[playerid][index][fRotY1] = fRotY;
    oInfo[playerid][index][fRotZ1] = fRotZ;
    oInfo[playerid][index][fScaleX1] = fScaleX;
    oInfo[playerid][index][fScaleY1] = fScaleY;
    oInfo[playerid][index][fScaleZ1] = fScaleZ;

    new query[60];
    SetPlayerAttachedObject(playerid, index, modelid, boneid, oInfo[playerid][index][fOffsetX1], oInfo[playerid][index][fOffsetY1], 
    oInfo[playerid][index][fOffsetZ1], oInfo[playerid][index][fRotX1], oInfo[playerid][index][fRotY1], oInfo[playerid][index][fRotZ1], 
    oInfo[playerid][index][fScaleX1], oInfo[playerid][index][fScaleY1], oInfo[playerid][index][fScaleZ1]);

    mysql_format(mysql, query, sizeof(query), "SELECT * FROM `Attachments` WHERE `Index` = %d AND `ID` = %d", index, Info[playerid][ID]);
    mysql_tquery(mysql, query, "OnAttachmentSave", "iiii", playerid, index, modelid, boneid);
    return 1;
}

public OnAttachmentSave(playerid, index, modelid, boneid)
{
    new query[250];
    if(!cache_num_rows())
    {
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `Attachments` (`ID`,`Index`,`Model`,`Bone`,`OffsetX`,`OffsetY`,`OffsetZ`) VALUES (%d,%d,%d,%d,%f,%f,%f)", Info[playerid][ID], index, modelid, 
        boneid, oInfo[playerid][index][fOffsetX1], oInfo[playerid][index][fOffsetY1], oInfo[playerid][index][fOffsetZ1]);
        mysql_tquery(mysql, query);

        mysql_format(mysql, query, sizeof(query), "UPDATE `Attachments` SET `RotX` = %f, `RotY` = %f, `RotZ` = %f, `ScaleX` = %f, `ScaleY` = %f, `ScaleZ` = %f WHERE `ID` = %d AND `Index` = %d", 
        oInfo[playerid][index][fRotX1], oInfo[playerid][index][fRotY1], oInfo[playerid][index][fRotZ1], oInfo[playerid][index][fScaleX1], oInfo[playerid][index][fScaleY1],
        oInfo[playerid][index][fScaleZ1], Info[playerid][ID], oInfo[playerid][index][index1]);
        mysql_tquery(mysql, query);
    }
    mysql_format(mysql, query, sizeof(query), "UPDATE `Attachments` SET `Model` = %d,`Bone` = %d,`OffsetX` = %f,`OffsetY` = %f,`OffsetZ` = %f WHERE `ID` = %d AND `Index` = %d",modelid, boneid, 
    oInfo[playerid][index][fOffsetX1], oInfo[playerid][index][fOffsetY1], oInfo[playerid][index][fOffsetZ1], Info[playerid][ID], oInfo[playerid][index][index1]);
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query), "UPDATE `Attachments` SET `RotX` = %f, `RotY` = %f, `RotZ` = %f, `ScaleX` = %f, `ScaleY` = %f, `ScaleZ` = %f WHERE `ID` = %d AND `Index` = %d",
    oInfo[playerid][index][fRotX1], oInfo[playerid][index][fRotY1], oInfo[playerid][index][fRotZ1], oInfo[playerid][index][fScaleX1], oInfo[playerid][index][fScaleY1], oInfo[playerid][index][fScaleZ1],
    Info[playerid][ID], oInfo[playerid][index][index1]);
    mysql_tquery(mysql, query);
}

// TimeStamp
 
stock IsLeapYear(year)
{
    if(year % 4 == 0) return 1;
    else return 0;
}
 
stock TimestampToDate(Timestamp, &year, &month, &day, &hour, &minute, &second, HourGMT, MinuteGMT = 0)
{
    new tmp = 2;
    year = 1970;
    month = 1;
    Timestamp -= 172800;
    for(;;)
    {
        if(Timestamp >= 31536000)
        {
            year ++;
            Timestamp -= 31536000;
            tmp ++;
            if(tmp == 4)
            {
                if(Timestamp >= 31622400)
                {
                    tmp = 0;
                    year ++;
                    Timestamp -= 31622400;
                }
                else break;
            }
        }
        else break;
    }              
    for(new i = 0; i < 12; i ++)
    {
        if(Timestamp >= MonthTimes[i][2 + IsLeapYear(year)])
        {
            month ++;
            Timestamp -= MonthTimes[i][2 + IsLeapYear(year)];
        }
        else break;
    }
    day = 1 + (Timestamp / 86400);
    Timestamp %= 86400;
    hour = HourGMT + (Timestamp / 3600);
    Timestamp %= 3600;
    minute = MinuteGMT + (Timestamp / 60);
    second = (Timestamp % 60);
    if(minute > 59)
    {
        minute = 0;
        hour ++;
    }
    if(hour > 23)
    {
        hour -= 24;
        day ++;
    }      
    if(day > MonthTimes[month][IsLeapYear(year)])
    {
        day = 1;
        month ++;
    }
    if(month > 12)
    {
        month = 1;
        year ++;
    }
    return 1;
}
 
stock DateToTimestamp(str[11])
{
    new date[3]; // date[0] = day           date[1] = month                 date[2] = year
    if(!sscanf(str,"p<.>ddd",date[0],date[1],date[2]))
    {
        new total = 0, tmp = 0;
        total += date[0] * 86400;
        if(date[1] == 2 && date[0] < 29) tmp = ((date[2] - 1968) / 4 - 2);
        else tmp = ((date[2] - 1968) / 4 - 1);
        total += tmp * 31622400;
        total += (date[2] - 1970 - tmp) * 31536000;
        for(new i = 1; i < date[1]; i ++) total += MonthTimes[i][0 + IsLeapYear(date[2])] * 86400;
        return total;
    }
    else return -1;
}

// Animations System

OnePlayAnim(playerid,animlib[],animname[], Float:animspeed, looping, lockx, locky, lockz, lp)
{
    ApplyAnimation(playerid, animlib, animname, animspeed, looping, lockx, locky, lockz, lp);
    animation[playerid]++;
}

LoopingAnim(playerid,animlib[],animname[], Float:speedanim, looping, lockx, locky, lockz, lp)
{
    PlayerUsingLoopingAnim[playerid] = 1;
    ApplyAnimation(playerid, animlib, animname, speedanim, looping, lockx, locky, lockz, lp);
    animation[playerid]++;
}

StopLoopingAnim(playerid)
{
    PlayerUsingLoopingAnim[playerid] = 0;
    ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0);
}
