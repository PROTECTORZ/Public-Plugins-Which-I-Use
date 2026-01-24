#include <amxmodx>
#include <cstrike>
#include <fun>
#include <engine> 
#include <csx> 
#define RandomNum random_num(0, 255)
#define vip ADMIN_SLAY
new const soundHS[] = "misc/nice_sounds/headshot.wav";
new const soundKnife[] = "misc/nice_sounds/knife.wav";
new const soundGren[] = "misc/nice_sounds/grenade.wav";
new nHead_Bonus_CvarMoney, HeadBonusCvarHP;
new KnifeBonusCvarMoney, KnifeBonusCvarHP;
new GrenadeBonusCvarMoney, GrenadeBonusCvarHP;
new VipOnlyCvar;
new MessagesCvar, SoundsCvar;
/* Проследяване на серия убийства (по индекс на играч) */
new gKillStreak[33];
new bool:gFirstBloodDone;
/* Cvars за допълнителни функции */
new KillStreakThresholdCvar, KillStreakBonusMoneyCvar, KillStreakBonusHpCvar;
new EndStreakBonusMoneyCvar, EndStreakBonusHpCvar;
new StreakAnnounceCvar;
new FirstBloodBonusMoneyCvar, FirstBloodBonusHpCvar;
new DistanceThresholdCvar, DistanceBonusMoneyCvar, DistanceBonusHpCvar;
new RandomChanceCvar;
new HudColorRCvar, HudColorGCvar, HudColorBCvar;
new LowHealthThresholdCvar, LowHealthBonusMoneyCvar, LowHealthBonusHpCvar;
new PistolBonusMoneyCvar, PistolBonusHpCvar;
new LogBonusCvar;
/* Нови cvar-ове за допълнителни бонуси */
new TeamKillPenaltyMoneyCvar, TeamKillPenaltyHpCvar;
new SpreeBonusMoneyCvar, SpreeBonusHpCvar;
new ComboTimeCvar, ComboBonusMoneyCvar, ComboBonusHpCvar;
new RevengeBonusMoneyCvar, RevengeBonusHpCvar;
new LastManBonusMoneyCvar, LastManBonusHpCvar;
new SniperBonusMoneyCvar, SniperBonusHpCvar;
new SuppressBonusMoneyCvar, SuppressBonusHpCvar;
new BroadcastMessagesCvar;
new DefuseBonusMoneyCvar, DefuseBonusHpCvar;
new PlantBonusMoneyCvar, PlantBonusHpCvar;
new HostageBonusMoneyCvar, HostageBonusHpCvar;
new StreakProgressCvar;
new RandomMoneyMinCvar, RandomMoneyMaxCvar;
new RandomHpMinCvar, RandomHpMaxCvar;
new MoneyEnableCvar, HpEnableCvar;
new SoundVolumeCvar;
new TopKillerBonusMoneyCvar, TopKillerBonusHpCvar;
new TopHeadshotBonusMoneyCvar, TopHeadshotBonusHpCvar;
new UnstoppableThresholdCvar, UnstoppableBonusMoneyCvar, UnstoppableBonusHpCvar;

/* ----- Допълнителни cvar-ове за бонуси, добавени във версия 7.0 (масивно обновление) ----- */
/* Бонус за асистенция (участие в убийството с нанесени щети, но без финалния изстрел) */
new AssistBonusMoneyCvar, AssistBonusHpCvar;
/* Бонус за no-scope снайперско убийство (убийство без приближаване/zoom) */
new NoScopeBonusMoneyCvar, NoScopeBonusHpCvar;
#define WEAPON_COUNT 25

/* Списък с имената на оръжията. Редът е важен – използва се при регистрацията на cvar-ове. */
new const WeaponNames[WEAPON_COUNT][] = {
    "usp",
    "glock18",
    "deagle",
    "p228",
    "elite",
    "fiveseven",
    "m3",
    "xm1014",
    "tmp",
    "mac10",
    "mp5navy",
    "p90",
    "ump45",
    "ak47",
    "m4a1",
    "famas",
    "galil",
    "sg552",
    "aug",
    "scout",
    "awp",
    "g3sg1",
    "sg550",
    "m249",
    "hegrenade"
};

/* Масиви за cvar-ите, които дефинират бонуси за обикновено убийство и headshot с конкретно оръжие */
new WeaponBonusMoneyCvar[WEAPON_COUNT];
new WeaponBonusHpCvar[WEAPON_COUNT];
new WeaponHsBonusMoneyCvar[WEAPON_COUNT];
new WeaponHsBonusHpCvar[WEAPON_COUNT];

/*
 * Масиви за специфични бонуси при клек и въздушно убийство за всяко оръжие.
 * За всяко оръжие поддържаме отделни стойности за пари и здраве.
 * Примерни cvar-ове: nice_ak47_crouch_bonus_money, nice_ak47_crouch_bonus_hp,
 * nice_ak47_air_bonus_money, nice_ak47_air_bonus_hp.
 */
new WeaponCrouchBonusMoneyCvar[WEAPON_COUNT];
new WeaponCrouchBonusHpCvar[WEAPON_COUNT];
new WeaponAirBonusMoneyCvar[WEAPON_COUNT];
new WeaponAirBonusHpCvar[WEAPON_COUNT];

/*
 * Допълнителни глобални cvar-ове за 10 бонуса, базирани на околна среда.
 * Всеки бонус има два cvar-а: един за пари и един за здраве.
 */
new FullArmorBonusMoneyCvar, FullArmorBonusHpCvar;
new HelmetBonusMoneyCvar, HelmetBonusHpCvar;
new NoArmorBonusMoneyCvar, NoArmorBonusHpCvar;
new NvgBonusMoneyCvar, NvgBonusHpCvar;
new BombCarryKillBonusMoneyCvar, BombCarryKillBonusHpCvar;
new DefuseKitKillBonusMoneyCvar, DefuseKitKillBonusHpCvar;
new HighGroundBonusMoneyCvar, HighGroundBonusHpCvar;
new LowGroundBonusMoneyCvar, LowGroundBonusHpCvar;
new CloseRangeBonusMoneyCvar, CloseRangeBonusHpCvar;
new MediumRangeBonusMoneyCvar, MediumRangeBonusHpCvar;

/*
 * ----- Milestone и други бонуси за версия 8.0 -----
 * Съдържа 50 бонуса за общ брой убийства, 20 бонуса за брой headshot-и,
 * 10 бонуса за високо здраве, 10 за ниско здраве, бонус за убийство във вода,
 * бонус за spawn kill (в рамките на определено време след началото на рунда),
 * бонуси за специфични карти (6 карти) и бонуси за „богати“ играчи с много пари.
 */
#define KILL_MILESTONE_COUNT 50
new KillMilestoneMoneyCvar[KILL_MILESTONE_COUNT];
new KillMilestoneHpCvar[KILL_MILESTONE_COUNT];

#define HS_MILESTONE_COUNT 20
new HSMilestoneMoneyCvar[HS_MILESTONE_COUNT];
new HSMilestoneHpCvar[HS_MILESTONE_COUNT];

#define HIGH_HP_THRESHOLD_COUNT 10
new const HighHpThresholds[HIGH_HP_THRESHOLD_COUNT] = {100, 90, 80, 70, 60, 50, 40, 30, 20, 10};
new HighHpBonusMoneyCvar[HIGH_HP_THRESHOLD_COUNT];
new HighHpBonusHpCvar[HIGH_HP_THRESHOLD_COUNT];

#define LOW_HP_THRESHOLD_COUNT 10
new const LowHpThresholds[LOW_HP_THRESHOLD_COUNT] = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100};
new LowHpBonusMoneyCvar[LOW_HP_THRESHOLD_COUNT];
new LowHpBonusHpCvar[LOW_HP_THRESHOLD_COUNT];

#define MAP_BONUS_COUNT 6
new const MapBonusNames[MAP_BONUS_COUNT][] = {"de_dust2", "de_nuke", "de_inferno", "de_mirage", "de_overpass", "cs_office"};
new MapBonusMoneyCvar[MAP_BONUS_COUNT];
new MapBonusHpCvar[MAP_BONUS_COUNT];

/* Бонус за убийство във вода */
new WaterKillBonusMoneyCvar, WaterKillBonusHpCvar;
/* Бонус за spawn kill (ранно убийство) */
new SpawnKillTimeCvar, SpawnKillBonusMoneyCvar, SpawnKillBonusHpCvar;

#define RICH_THRESHOLD_COUNT 2
new const RichThresholds[RICH_THRESHOLD_COUNT] = {10000, 16000};
new RichBonusMoneyCvar[RICH_THRESHOLD_COUNT];
new RichBonusHpCvar[RICH_THRESHOLD_COUNT];
/* Бонуси по категория оръжие */
new ShotgunBonusMoneyCvar, ShotgunBonusHpCvar;
new SmgBonusMoneyCvar, SmgBonusHpCvar;
new RifleBonusMoneyCvar, RifleBonusHpCvar;
new MachinegunBonusMoneyCvar, MachinegunBonusHpCvar;
new DeagleBonusMoneyCvar, DeagleBonusHpCvar;
/* Бонус за серия headshot-и */
new HSStreakThresholdCvar, HSStreakBonusMoneyCvar, HSStreakBonusHpCvar;
/* Бонус за убийство при клек (клекнал убиец) */
new CrouchBonusMoneyCvar, CrouchBonusHpCvar;
/* Бонус за въздушно убийство (убиец във въздуха) */
new AirBonusMoneyCvar, AirBonusHpCvar;
/* Бонус за последен патрон */
new LastBulletBonusMoneyCvar, LastBulletBonusHpCvar;
/* Бонус за мулти-убийства с граната */
new GrenadeMultiKillThresholdCvar, GrenadeMultiKillBonusMoneyCvar, GrenadeMultiKillBonusHpCvar;
/* Бонус за clutch – убиец сам срещу X противника */
new ClutchOpponentsThresholdCvar, ClutchBonusMoneyCvar, ClutchBonusHpCvar;
/* Бонус за убиване на лидер (играч с най-много убийства в рунда) */
new LeaderBonusMoneyCvar, LeaderBonusHpCvar;
/* Бонус за оцелял в края на рунда */
new SurvivalBonusMoneyCvar, SurvivalBonusHpCvar;
/* Бонус за бързо убийство след началото на рунда */
new FastKillTimeCvar, FastKillBonusMoneyCvar, FastKillBonusHpCvar;
/* Бонус за убиване на носителя на бомбата */
new BombCarrierBonusMoneyCvar, BombCarrierBonusHpCvar;
/* Бонус за няколко убийства с нож в един рунд */
new KnifeMultiKillThresholdCvar, KnifeMultiKillBonusMoneyCvar, KnifeMultiKillBonusHpCvar;
/* Бонус за серия от убийства с различни оръжия */
new WeaponSwitchStreakThresholdCvar, WeaponSwitchBonusMoneyCvar, WeaponSwitchBonusHpCvar;
/* Бонус за няколко убийства без презареждане */
new NoReloadKillThresholdCvar, NoReloadBonusMoneyCvar, NoReloadBonusHpCvar;
/* Бонус за ACE (определен брой убийства в рунда) */
new AceKillsThresholdCvar, AceBonusMoneyCvar, AceBonusHpCvar;
/* Бонус за недокоснат (оцелява без да получи щета в рунда) */
new UntouchableBonusMoneyCvar, UntouchableBonusHpCvar;

/* ----- Глобални променливи за проследяване на новите състояния ----- */
/* Сериен брояч на поредни headshot-и по играч */
new gHSStreak[33];
/* Брояч за убийства с граната в един рунд по играч */
new gGrenadeKillCount[33];
/* Брояч за убийства с нож в един рунд по играч */
new gKnifeKillCount[33];
/* Брояч за поредица от различни оръжия */
new gWeaponStreakCount[33];
/* Последно оръжие, използвано от играча за поредица от различни оръжия */
new gLastWeaponID[33];
/* Брояч за убийства без презареждане */
new gClipKillCount[33];
/* Последен брой патрони в пълнителя за проверка за презареждане */
new gLastWeaponClip[33];
/* Идентификатор на оръжието за брояча без презареждане */
new gClipWeaponId[33];
/* Време на стартиране на рунда (float) */
new Float:gRoundStartTime;
/* Флаг дали играчът е получил щета през рунда за Untouchable бонус */
new bool:gDamageTaken[33];
/* Матрица за следене на нанесени щети за бонуса за асистенция (attacker -> victim) */
new gDamageDone[33][33];
/* Променливи за проследяване на допълнително състояние */
new Float:gLastKillTime[33];
new gComboCount[33];
new gLastKiller[33];
new gRoundKills[33];
new gRoundHSKills[33];
new gRoundNumber;
/* Общ брой убийства и headshot-и за всеки играч през картата (използва се за milestone бонусите) */
new gTotalKills[33];
new gTotalHSKills[33];
/* Предварително зареждане на звуковите файлове при стартиране на картата */
public plugin_precache()
{
    precache_sound(soundHS);
    precache_sound(soundKnife);
    precache_sound(soundGren);
}
/* Инициализация на плъгина */
public plugin_init()
{
    register_plugin("Kill Bonuses", "5.0", "1MP4C7");
    /* Използваме DeathMsg, за да имаме достъп до убиец, жертва, оръжие и флаг за headshot */
    register_event("DeathMsg", "OnDeathMsg", "a");

    /* Събитие Damage за следене на нанесените щети и асист бонуси */
    register_event("Damage", "OnDamage", "b");
    /* Създаване на cvar-ове със стойности по подразбиране */
    nHead_Bonus_CvarMoney = register_cvar("nice_headshot_bonus_money", "1000");
    HeadBonusCvarHP = register_cvar("nice_headshot_bonus_hp", "10");
    KnifeBonusCvarMoney = register_cvar("nice_knife_bonus_money", "2000");
    KnifeBonusCvarHP = register_cvar("nice_knife_bonus_hp", "15");
    GrenadeBonusCvarMoney = register_cvar("nice_grenade_bonus_money", "1500");
    GrenadeBonusCvarHP = register_cvar("nice_grenade_bonus_hp", "10");
    VipOnlyCvar = register_cvar("nice_bonus_vip_only", "0");
    MessagesCvar = register_cvar("nice_messages", "2");
    SoundsCvar = register_cvar("nice_sounds", "1");
    /* Нови cvar-ове за разширени функции */
    KillStreakThresholdCvar = register_cvar("nice_killstreak_threshold", "3");
    KillStreakBonusMoneyCvar = register_cvar("nice_killstreak_bonus_money", "3000");
    KillStreakBonusHpCvar = register_cvar("nice_killstreak_bonus_hp", "20");
    StreakAnnounceCvar = register_cvar("nice_killstreak_announce", "1");
    EndStreakBonusMoneyCvar = register_cvar("nice_endstreak_bonus_money", "2500");
    EndStreakBonusHpCvar = register_cvar("nice_endstreak_bonus_hp", "15");
    FirstBloodBonusMoneyCvar = register_cvar("nice_firstblood_bonus_money", "1500");
    FirstBloodBonusHpCvar = register_cvar("nice_firstblood_bonus_hp", "10");
    DistanceThresholdCvar = register_cvar("nice_distance_threshold", "1000");
    DistanceBonusMoneyCvar = register_cvar("nice_distance_bonus_money", "1000");
    DistanceBonusHpCvar = register_cvar("nice_distance_bonus_hp", "10");
    RandomChanceCvar = register_cvar("nice_random_chance", "10"); /* процент: 0-100 */
    HudColorRCvar = register_cvar("nice_hud_r", "-1");
    HudColorGCvar = register_cvar("nice_hud_g", "-1");
    HudColorBCvar = register_cvar("nice_hud_b", "-1");
    LowHealthThresholdCvar = register_cvar("nice_lowhealth_threshold", "30");
    LowHealthBonusMoneyCvar = register_cvar("nice_lowhealth_bonus_money", "800");
    LowHealthBonusHpCvar = register_cvar("nice_lowhealth_bonus_hp", "20");
    PistolBonusMoneyCvar = register_cvar("nice_pistol_bonus_money", "500");
    PistolBonusHpCvar = register_cvar("nice_pistol_bonus_hp", "5");
    LogBonusCvar = register_cvar("nice_log_bonus_events", "0");
    /* Регистриране на cvar-ове за допълнителни бонуси */
    TeamKillPenaltyMoneyCvar = register_cvar("nice_teamkill_penalty_money", "1000");
    TeamKillPenaltyHpCvar = register_cvar("nice_teamkill_penalty_hp", "10");
    SpreeBonusMoneyCvar = register_cvar("nice_spree_bonus_money", "100");
    SpreeBonusHpCvar = register_cvar("nice_spree_bonus_hp", "5");
    ComboTimeCvar = register_cvar("nice_combo_time", "3.0");
    ComboBonusMoneyCvar = register_cvar("nice_combo_bonus_money", "150");
    ComboBonusHpCvar = register_cvar("nice_combo_bonus_hp", "5");
    RevengeBonusMoneyCvar = register_cvar("nice_revenge_bonus_money", "500");
    RevengeBonusHpCvar = register_cvar("nice_revenge_bonus_hp", "10");
    LastManBonusMoneyCvar = register_cvar("nice_lastman_bonus_money", "1000");
    LastManBonusHpCvar = register_cvar("nice_lastman_bonus_hp", "20");
    SniperBonusMoneyCvar = register_cvar("nice_sniper_bonus_money", "500");
    SniperBonusHpCvar = register_cvar("nice_sniper_bonus_hp", "10");
    SuppressBonusMoneyCvar = register_cvar("nice_suppress_bonus_money", "300");
    SuppressBonusHpCvar = register_cvar("nice_suppress_bonus_hp", "5");
    BroadcastMessagesCvar = register_cvar("nice_broadcast_bonus_messages", "0");
    DefuseBonusMoneyCvar = register_cvar("nice_defuse_bonus_money", "1500");
    DefuseBonusHpCvar = register_cvar("nice_defuse_bonus_hp", "15");
    PlantBonusMoneyCvar = register_cvar("nice_plant_bonus_money", "1000");
    PlantBonusHpCvar = register_cvar("nice_plant_bonus_hp", "10");
    HostageBonusMoneyCvar = register_cvar("nice_hostage_bonus_money", "500");
    HostageBonusHpCvar = register_cvar("nice_hostage_bonus_hp", "5");
    StreakProgressCvar = register_cvar("nice_streak_progress", "0");
    RandomMoneyMinCvar = register_cvar("nice_random_money_min", "500");
    RandomMoneyMaxCvar = register_cvar("nice_random_money_max", "2000");
    RandomHpMinCvar = register_cvar("nice_random_hp_min", "5");
    RandomHpMaxCvar = register_cvar("nice_random_hp_max", "10");
    MoneyEnableCvar = register_cvar("nice_money_bonus_enable", "1");
    HpEnableCvar = register_cvar("nice_hp_bonus_enable", "1");
    SoundVolumeCvar = register_cvar("nice_sound_volume", "1.0");
    TopKillerBonusMoneyCvar = register_cvar("nice_topkiller_bonus_money", "2000");
    TopKillerBonusHpCvar = register_cvar("nice_topkiller_bonus_hp", "20");
    TopHeadshotBonusMoneyCvar = register_cvar("nice_topheadshot_bonus_money", "1500");
    TopHeadshotBonusHpCvar = register_cvar("nice_topheadshot_bonus_hp", "15");
    UnstoppableThresholdCvar = register_cvar("nice_unstoppable_threshold", "5");
    UnstoppableBonusMoneyCvar = register_cvar("nice_unstoppable_bonus_money", "4000");
    UnstoppableBonusHpCvar = register_cvar("nice_unstoppable_bonus_hp", "25");

    /* Регистрация на cvar-ове за новите бонуси във версия 7.0 */
    AssistBonusMoneyCvar = register_cvar("nice_assist_bonus_money", "300");
    AssistBonusHpCvar = register_cvar("nice_assist_bonus_hp", "3");
    NoScopeBonusMoneyCvar = register_cvar("nice_noscope_bonus_money", "1000");
    NoScopeBonusHpCvar = register_cvar("nice_noscope_bonus_hp", "10");

    /*
     * Регистрация на cvar-ове за milestone бонуси и други функции във версия 8.0.
     * Всички стойности по подразбиране са нула (0), за да бъдат изключени, освен ако
     * администраторът не ги настрои. Тези cvar-ове се дефинират динамично с номера
     * на прага или името на картата/прага.
     */
    {
        new cvarName[64];
        /* Kill milestone bonuses: nice_kill_milestone_X_bonus_money / _hp */
        for (new i = 0; i < KILL_MILESTONE_COUNT; i++)
        {
            formatex(cvarName, charsmax(cvarName), "nice_kill_milestone_%d_bonus_money", i + 1);
            KillMilestoneMoneyCvar[i] = register_cvar(cvarName, "0");
            formatex(cvarName, charsmax(cvarName), "nice_kill_milestone_%d_bonus_hp", i + 1);
            KillMilestoneHpCvar[i] = register_cvar(cvarName, "0");
        }
        /* Headshot milestone bonuses */
        for (new j = 0; j < HS_MILESTONE_COUNT; j++)
        {
            formatex(cvarName, charsmax(cvarName), "nice_hs_milestone_%d_bonus_money", j + 1);
            HSMilestoneMoneyCvar[j] = register_cvar(cvarName, "0");
            formatex(cvarName, charsmax(cvarName), "nice_hs_milestone_%d_bonus_hp", j + 1);
            HSMilestoneHpCvar[j] = register_cvar(cvarName, "0");
        }
        /* High HP threshold bonuses */
        for (new k = 0; k < HIGH_HP_THRESHOLD_COUNT; k++)
        {
            new thr = HighHpThresholds[k];
            formatex(cvarName, charsmax(cvarName), "nice_highhp_%d_bonus_money", thr);
            HighHpBonusMoneyCvar[k] = register_cvar(cvarName, "0");
            formatex(cvarName, charsmax(cvarName), "nice_highhp_%d_bonus_hp", thr);
            HighHpBonusHpCvar[k] = register_cvar(cvarName, "0");
        }
        /* Low HP threshold bonuses */
        for (new l = 0; l < LOW_HP_THRESHOLD_COUNT; l++)
        {
            new thr2 = LowHpThresholds[l];
            formatex(cvarName, charsmax(cvarName), "nice_lowhp_%d_bonus_money", thr2);
            LowHpBonusMoneyCvar[l] = register_cvar(cvarName, "0");
            formatex(cvarName, charsmax(cvarName), "nice_lowhp_%d_bonus_hp", thr2);
            LowHpBonusHpCvar[l] = register_cvar(cvarName, "0");
        }
        /* Water kill bonus */
        WaterKillBonusMoneyCvar = register_cvar("nice_waterkill_bonus_money", "1000");
        WaterKillBonusHpCvar    = register_cvar("nice_waterkill_bonus_hp", "10");
        /* Spawn kill bonus */
        SpawnKillTimeCvar       = register_cvar("nice_spawnkill_time", "10.0");
        SpawnKillBonusMoneyCvar = register_cvar("nice_spawnkill_bonus_money", "500");
        SpawnKillBonusHpCvar    = register_cvar("nice_spawnkill_bonus_hp", "5");
        /* Map-specific bonuses */
        for (new m = 0; m < MAP_BONUS_COUNT; m++)
        {
            formatex(cvarName, charsmax(cvarName), "nice_map_%s_bonus_money", MapBonusNames[m]);
            MapBonusMoneyCvar[m] = register_cvar(cvarName, "0");
            formatex(cvarName, charsmax(cvarName), "nice_map_%s_bonus_hp", MapBonusNames[m]);
            MapBonusHpCvar[m] = register_cvar(cvarName, "0");
        }
        /* Rich killer bonuses */
        for (new r = 0; r < RICH_THRESHOLD_COUNT; r++)
        {
            new thrR = RichThresholds[r];
            formatex(cvarName, charsmax(cvarName), "nice_rich_%d_bonus_money", thrR);
            RichBonusMoneyCvar[r] = register_cvar(cvarName, "0");
            formatex(cvarName, charsmax(cvarName), "nice_rich_%d_bonus_hp", thrR);
            RichBonusHpCvar[r] = register_cvar(cvarName, "0");
        }
    }

    /*
     * Регистрация на cvar-ове за оръжейни бонуси (WEAPON_COUNT × 2 вида)
     * За всяко оръжие създаваме четири cvar-а: за пари и HP при обикновено убийство,
     * както и за пари и HP при headshot с това оръжие. Стойностите по подразбиране
     * са умерени, но администраторът може да ги коригира според нуждите на сървъра.
     */
    for (new i = 0; i < WEAPON_COUNT; i++)
    {
        new cvarName[64];
        /* Обикновено убийство – пари */
        formatex(cvarName, charsmax(cvarName), "nice_%s_bonus_money", WeaponNames[i]);
        WeaponBonusMoneyCvar[i] = register_cvar(cvarName, "500");
        /* Обикновено убийство – HP */
        formatex(cvarName, charsmax(cvarName), "nice_%s_bonus_hp", WeaponNames[i]);
        WeaponBonusHpCvar[i] = register_cvar(cvarName, "5");
        /* Headshot – пари */
        formatex(cvarName, charsmax(cvarName), "nice_%s_hs_bonus_money", WeaponNames[i]);
        WeaponHsBonusMoneyCvar[i] = register_cvar(cvarName, "1000");
        /* Headshot – HP */
        formatex(cvarName, charsmax(cvarName), "nice_%s_hs_bonus_hp", WeaponNames[i]);
        WeaponHsBonusHpCvar[i] = register_cvar(cvarName, "10");

        /* Клек – пари */
        formatex(cvarName, charsmax(cvarName), "nice_%s_crouch_bonus_money", WeaponNames[i]);
        WeaponCrouchBonusMoneyCvar[i] = register_cvar(cvarName, "700");
        /* Клек – HP */
        formatex(cvarName, charsmax(cvarName), "nice_%s_crouch_bonus_hp", WeaponNames[i]);
        WeaponCrouchBonusHpCvar[i] = register_cvar(cvarName, "7");
        /* Въздух – пари */
        formatex(cvarName, charsmax(cvarName), "nice_%s_air_bonus_money", WeaponNames[i]);
        WeaponAirBonusMoneyCvar[i] = register_cvar(cvarName, "900");
        /* Въздух – HP */
        formatex(cvarName, charsmax(cvarName), "nice_%s_air_bonus_hp", WeaponNames[i]);
        WeaponAirBonusHpCvar[i] = register_cvar(cvarName, "9");
    }

    /* Регистрация на cvar-ове за бонуси, базирани на околна среда */
    FullArmorBonusMoneyCvar = register_cvar("nice_fullarmor_bonus_money", "800");
    FullArmorBonusHpCvar    = register_cvar("nice_fullarmor_bonus_hp", "8");
    HelmetBonusMoneyCvar    = register_cvar("nice_helmet_bonus_money", "600");
    HelmetBonusHpCvar       = register_cvar("nice_helmet_bonus_hp", "6");
    NoArmorBonusMoneyCvar   = register_cvar("nice_noarmor_bonus_money", "1000");
    NoArmorBonusHpCvar      = register_cvar("nice_noarmor_bonus_hp", "10");
    NvgBonusMoneyCvar       = register_cvar("nice_nvg_bonus_money", "500");
    NvgBonusHpCvar          = register_cvar("nice_nvg_bonus_hp", "5");
    BombCarryKillBonusMoneyCvar = register_cvar("nice_carrybomb_kill_bonus_money", "700");
    BombCarryKillBonusHpCvar    = register_cvar("nice_carrybomb_kill_bonus_hp", "7");
    DefuseKitKillBonusMoneyCvar = register_cvar("nice_defusekit_kill_bonus_money", "700");
    DefuseKitKillBonusHpCvar    = register_cvar("nice_defusekit_kill_bonus_hp", "7");
    HighGroundBonusMoneyCvar = register_cvar("nice_highground_bonus_money", "600");
    HighGroundBonusHpCvar    = register_cvar("nice_highground_bonus_hp", "6");
    LowGroundBonusMoneyCvar  = register_cvar("nice_lowground_bonus_money", "600");
    LowGroundBonusHpCvar     = register_cvar("nice_lowground_bonus_hp", "6");
    CloseRangeBonusMoneyCvar = register_cvar("nice_closerange_bonus_money", "500");
    CloseRangeBonusHpCvar    = register_cvar("nice_closerange_bonus_hp", "5");
    MediumRangeBonusMoneyCvar = register_cvar("nice_mediumrange_bonus_money", "400");
    MediumRangeBonusHpCvar    = register_cvar("nice_mediumrange_bonus_hp", "4");

    /* ----- Регистрация на cvar-ове за новите функции ----- */
    ShotgunBonusMoneyCvar = register_cvar("nice_shotgun_bonus_money", "800");
    ShotgunBonusHpCvar = register_cvar("nice_shotgun_bonus_hp", "8");
    SmgBonusMoneyCvar = register_cvar("nice_smg_bonus_money", "600");
    SmgBonusHpCvar = register_cvar("nice_smg_bonus_hp", "6");
    RifleBonusMoneyCvar = register_cvar("nice_rifle_bonus_money", "700");
    RifleBonusHpCvar = register_cvar("nice_rifle_bonus_hp", "7");
    MachinegunBonusMoneyCvar = register_cvar("nice_machinegun_bonus_money", "900");
    MachinegunBonusHpCvar = register_cvar("nice_machinegun_bonus_hp", "9");
    DeagleBonusMoneyCvar = register_cvar("nice_deagle_bonus_money", "1000");
    DeagleBonusHpCvar = register_cvar("nice_deagle_bonus_hp", "10");
    HSStreakThresholdCvar = register_cvar("nice_hs_streak_threshold", "2");
    HSStreakBonusMoneyCvar = register_cvar("nice_hs_streak_bonus_money", "1200");
    HSStreakBonusHpCvar = register_cvar("nice_hs_streak_bonus_hp", "12");
    CrouchBonusMoneyCvar = register_cvar("nice_crouch_bonus_money", "500");
    CrouchBonusHpCvar = register_cvar("nice_crouch_bonus_hp", "5");
    AirBonusMoneyCvar = register_cvar("nice_air_bonus_money", "700");
    AirBonusHpCvar = register_cvar("nice_air_bonus_hp", "7");
    LastBulletBonusMoneyCvar = register_cvar("nice_lastbullet_bonus_money", "800");
    LastBulletBonusHpCvar = register_cvar("nice_lastbullet_bonus_hp", "8");
    GrenadeMultiKillThresholdCvar = register_cvar("nice_grenade_multikill_threshold", "2");
    GrenadeMultiKillBonusMoneyCvar = register_cvar("nice_grenade_multikill_bonus_money", "1500");
    GrenadeMultiKillBonusHpCvar = register_cvar("nice_grenade_multikill_bonus_hp", "15");
    ClutchOpponentsThresholdCvar = register_cvar("nice_clutch_opponents_threshold", "2");
    ClutchBonusMoneyCvar = register_cvar("nice_clutch_bonus_money", "2000");
    ClutchBonusHpCvar = register_cvar("nice_clutch_bonus_hp", "20");
    LeaderBonusMoneyCvar = register_cvar("nice_leader_bonus_money", "1000");
    LeaderBonusHpCvar = register_cvar("nice_leader_bonus_hp", "10");
    SurvivalBonusMoneyCvar = register_cvar("nice_survival_bonus_money", "800");
    SurvivalBonusHpCvar = register_cvar("nice_survival_bonus_hp", "8");
    FastKillTimeCvar = register_cvar("nice_fastkill_time", "15.0");
    FastKillBonusMoneyCvar = register_cvar("nice_fastkill_bonus_money", "500");
    FastKillBonusHpCvar = register_cvar("nice_fastkill_bonus_hp", "5");
    BombCarrierBonusMoneyCvar = register_cvar("nice_bombcarrier_bonus_money", "1200");
    BombCarrierBonusHpCvar = register_cvar("nice_bombcarrier_bonus_hp", "12");
    KnifeMultiKillThresholdCvar = register_cvar("nice_knife_multikill_threshold", "2");
    KnifeMultiKillBonusMoneyCvar = register_cvar("nice_knife_multikill_bonus_money", "1000");
    KnifeMultiKillBonusHpCvar = register_cvar("nice_knife_multikill_bonus_hp", "10");
    WeaponSwitchStreakThresholdCvar = register_cvar("nice_weaponswitch_streak_threshold", "3");
    WeaponSwitchBonusMoneyCvar = register_cvar("nice_weaponswitch_bonus_money", "900");
    WeaponSwitchBonusHpCvar = register_cvar("nice_weaponswitch_bonus_hp", "9");
    NoReloadKillThresholdCvar = register_cvar("nice_noreload_kill_threshold", "3");
    NoReloadBonusMoneyCvar = register_cvar("nice_noreload_bonus_money", "1600");
    NoReloadBonusHpCvar = register_cvar("nice_noreload_bonus_hp", "16");
    AceKillsThresholdCvar = register_cvar("nice_ace_kills_threshold", "5");
    AceBonusMoneyCvar = register_cvar("nice_ace_bonus_money", "3000");
    AceBonusHpCvar = register_cvar("nice_ace_bonus_hp", "30");
    UntouchableBonusMoneyCvar = register_cvar("nice_untouchable_bonus_money", "2000");
    UntouchableBonusHpCvar = register_cvar("nice_untouchable_bonus_hp", "20");

    /* Регистрираме Damage event за засичане на щети (за Untouchable бонус).
     * Използваме стандартния event вместо Ham модул, за да избегнем зависимост от hamsandwich. */
    register_event("Damage", "OnDamage", "b");
    /* Регистриране на logevent за край на рунд, за да награждаваме най-добрите играчи */
    register_logevent("OnRoundEnd", 2, "1=Round_End");
    /* Извеждане на съобщение за версията на плъгина */
    server_print("Плъгинът Kill Bonuses версия 5.0 е зареден");
    /* Forward-овете за бомба/заложници (bomb_planted, bomb_defused, hostage_rescued) се предоставят от csx и ще извикват функциите ни автоматично */
    /* Регистриране на събитие за начало на рунд, за да нулираме серията убийства и first blood */
    register_event("HLTV", "OnNewRound", "a", "1=0", "2=0");
}
/* Обработчик на събитието DeathMsg */
public OnDeathMsg()
{
    new killer = read_data(1);
    new victim = read_data(2);
    /* Игнорираме, ако убиецът или жертвата не са валидни или е world/self убийство */
    if (!killer || !victim || killer == victim)
    {
        return;
    }
    if (!is_user_connected(killer) || !is_user_connected(victim))
    {
        return;
    }
    /* Ограничаваме бонусите само за VIP/админ, ако е конфигурирано */
    new bool:allowBonus = true;
    if (get_pcvar_num(VipOnlyCvar))
    {
        /* проверяваме дали убиецът има VIP флага */
        allowBonus = (get_user_flags(killer) & vip) != 0;
    }
    if (!allowBonus)
    {
        return;
    }
    /* Обработка на серия убийства и first blood */
    new victimStreak = gKillStreak[victim];
    gKillStreak[killer]++;
    gKillStreak[victim] = 0;
    /* Бонус за first blood */
    if (!gFirstBloodDone)
    {
        gFirstBloodDone = true;
        new fbMoney = get_pcvar_num(FirstBloodBonusMoneyCvar);
        new fbHP = get_pcvar_num(FirstBloodBonusHpCvar);
        /* Даване на бонус за first blood */
        AwardBonus(killer, fbMoney, fbHP);
        /* Обявяване на first blood */
        static fbName[32], fbMsg[128];
        get_user_name(killer, fbName, charsmax(fbName));
        formatex(fbMsg, charsmax(fbMsg), "%s napravi First Blood! +$%d +%dHP", fbName, fbMoney, fbHP);
        ShowBonusMessage(0, fbMsg);
        /* Лог */
        if (get_pcvar_num(LogBonusCvar))
        {
            log_to_file("killbonuses.log", fbMsg);
        }
    }
    /* Бонус за прекъсване на серия – ако жертвата е имала серия над прага преди това убийство */
    new ksThreshold = get_pcvar_num(KillStreakThresholdCvar);
    if (ksThreshold > 0 && victimStreak >= ksThreshold)
    {
        new eMoney = get_pcvar_num(EndStreakBonusMoneyCvar);
        new eHP = get_pcvar_num(EndStreakBonusHpCvar);
        AwardBonus(killer, eMoney, eHP);
        static vName[32], endMsg[128];
        get_user_name(victim, vName, charsmax(vName));
        formatex(endMsg, charsmax(endMsg), "Ti prekusna seriata na %s! +$%d +%dHP", vName, eMoney, eHP);
        ShowBonusMessage(killer, endMsg);
        if (get_pcvar_num(LogBonusCvar))
        {
            log_to_file("killbonuses.log", endMsg);
        }
    }
    /* Четене на флага за headshot и името на оръжието */
    new headshot = read_data(3);
    static weapon[32];
    read_data(4, weapon, charsmax(weapon));
    /* Определяне на типа убийство: 1 = headshot, 2 = нож, 3 = граната */
    new killType = 0;
    if (headshot)
    {
        killType = 1;
    }
    else if (equali(weapon, "knife"))
    {
        killType = 2;
    }
    else if (equali(weapon, "hegrenade") || equali(weapon, "flashbang") || equali(weapon, "smokegrenade"))
    {
        killType = 3;
    }
    /* Ако killType е 0 (обикновено убийство), не връщаме от функцията.
     * Това позволява да обработим останалите бонуси (пистолет, серия, и т.н.)
     * въпреки че не е headshot, нож или граната. */
    // if killType == 0, simply skip special kill-type bonuses but continue execution
    /* Наказание за team kill – ако убиецът и жертвата са от един и същи отбор, наказваме убиеца и пропускаме всички останали бонуси */
    if (cs_get_user_team(killer) == cs_get_user_team(victim))
    {
        new tkMoney = get_pcvar_num(TeamKillPenaltyMoneyCvar);
        new tkHp = get_pcvar_num(TeamKillPenaltyHpCvar);
        /* Прилагаме отрицателни стойности, за да намалим парите/здравето */
        AwardBonus(killer, -tkMoney, -tkHp);
        static tkMsg[128];
        formatex(tkMsg, charsmax(tkMsg), "Team kill! Shte si namalish %d$ i %dHP", tkMoney, tkHp);
        ShowBonusMessage(killer, tkMsg);
        if (get_pcvar_num(LogBonusCvar))
        {
            log_to_file("killbonuses.log", tkMsg);
        }
        return;
    }
    /* Взимане на стойностите на cvar-овете */
    new bonusHSMoney = get_pcvar_num(nHead_Bonus_CvarMoney);
    new bonusHSHP = get_pcvar_num(HeadBonusCvarHP);
    new bonusKnifeMoney = get_pcvar_num(KnifeBonusCvarMoney);
    new bonusKnifeHP = get_pcvar_num(KnifeBonusCvarHP);
    new bonusGrenMoney = get_pcvar_num(GrenadeBonusCvarMoney);
    new bonusGrenHP = get_pcvar_num(GrenadeBonusCvarHP);
    /* Даване на пари и здраве на убиеца според типа убийство */
    /* Запазваме здравето на убиеца преди бонуса за по-късна проверка за ниско здраве */
    new killerHealth = get_user_health(killer);
    switch (killType)
    {
        case 1:
        {
            AwardBonus(killer, bonusHSMoney, bonusHSHP);
            /* Записваме броя headshot-и за рунда */
            gRoundHSKills[killer]++;
        }
        case 2:
        {
            AwardBonus(killer, bonusKnifeMoney, bonusKnifeHP);
        }
        case 3:
        {
            AwardBonus(killer, bonusGrenMoney, bonusGrenHP);
        }
    }
    /* Увеличаваме брояча за убийства в рунда */
    gRoundKills[killer]++;
    /* Пускане на звук за убийство */
    PlayKillSound(killer, victim, killType);
    /* Създаване и показване на съобщения, ако са включени */
    new msgMode = get_pcvar_num(MessagesCvar);
    if (msgMode > 0)
    {
        static nameKiller[32], nameVictim[32];
        get_user_name(killer, nameKiller, charsmax(nameKiller));
        get_user_name(victim, nameVictim, charsmax(nameVictim));
        /* Подготовка на текстовете за чат */
        static msgVictim[192], msgKiller[192];
        switch (killType)
        {
            case 1:
            {
                /* Съобщения за headshot */
                formatex(msgVictim, charsmax(msgVictim), "%s ti razcepi tikvata!", nameKiller);
                formatex(msgKiller, charsmax(msgKiller), "Ti razcepi tikvata na %s i poluchi %dHP kakto i %d$", nameVictim, bonusHSHP, bonusHSMoney);
            }
            case 2:
            {
                /* Съобщения за нож */
                formatex(msgVictim, charsmax(msgVictim), "%s ti napravi kamikadze!", nameKiller);
                formatex(msgKiller, charsmax(msgKiller), "Ti hvurli kamikadze na %s i poluchi %dHP kakto i %d$", nameVictim, bonusKnifeHP, bonusKnifeMoney);
            }
            case 3:
            {
                /* Съобщения за граната */
                formatex(msgVictim, charsmax(msgVictim), "%s hvurli granata!", nameKiller);
                formatex(msgKiller, charsmax(msgKiller), "Ti hvurli granata na %s i poluchi %dHP kakto i %d$", nameVictim, bonusGrenHP, bonusGrenMoney);
            }
        }
        if (msgMode == 1)
        {
            /* Чат съобщения: изпращаме на жертвата и на убиеца */
            ColorPrint(victim, msgVictim);
            ColorPrint(killer, msgKiller);
        }
        else if (msgMode == 2)
        {
            /* HUD съобщения: случайни цветове, центрирани близо до мерника.
             * Ползваме стандартно HUD вместо director HUD за по-добра съвместимост. */
            new r = RandomNum, g = RandomNum, b = RandomNum;
            /* Показваме на жертвата */
            set_hudmessage(r, g, b, -1.0, 0.25, 0, 0.1, 3.0, 0.1, 0.2);
            show_hudmessage(victim, msgVictim);
            /* Показваме на убиеца */
            set_hudmessage(r, g, b, -1.0, 0.35, 0, 0.1, 3.0, 0.1, 0.2);
            show_hudmessage(killer, msgKiller);
        }
    }
    /* Пускането на звук се обработва от PlayKillSound по-горе */
    /* Допълнителни функции за бонуси */
    /* Достигнат праг за серия убийства */
    if (ksThreshold > 0 && gKillStreak[killer] >= ksThreshold)
    {
        new ksMoney = get_pcvar_num(KillStreakBonusMoneyCvar);
        new ksHP = get_pcvar_num(KillStreakBonusHpCvar);
        AwardBonus(killer, ksMoney, ksHP);
        /* Обявяване на серията, ако е включено */
        if (get_pcvar_num(StreakAnnounceCvar))
        {
            static streakName[32], streakMsg[128];
            get_user_name(killer, streakName, charsmax(streakName));
            formatex(streakMsg, charsmax(streakMsg), "%s e na seria ot %d ubiistva! +$%d +%dHP", streakName, ksThreshold, ksMoney, ksHP);
            ShowBonusMessage(0, streakMsg);
        }
        if (get_pcvar_num(LogBonusCvar))
        {
            static streakLog[128];
            get_user_name(killer, streakLog, 31);
            formatex(streakLog, charsmax(streakLog), "%s dostigna seria ot ubiistva %d", streakLog, ksThreshold);
            log_to_file("killbonuses.log", streakLog);
        }
        /* Нулираме серията, за да може играчът да я постигне отново */
        gKillStreak[killer] = 0;
    }
    /* Бонус за далечно убийство */
    new distThresh = get_pcvar_num(DistanceThresholdCvar);
    if (distThresh > 0)
    {
        static originK[3], originV[3];
        get_user_origin(killer, originK, 0);
        get_user_origin(victim, originV, 0);
        new dx = originK[0] - originV[0];
        new dy = originK[1] - originV[1];
        new dz = originK[2] - originV[2];
        new dist2 = dx*dx + dy*dy + dz*dz;
        if (dist2 >= distThresh * distThresh)
        {
            new dMoney = get_pcvar_num(DistanceBonusMoneyCvar);
            new dHP = get_pcvar_num(DistanceBonusHpCvar);
            AwardBonus(killer, dMoney, dHP);
            static distMsg[128];
            formatex(distMsg, charsmax(distMsg), "Daleko ubistvo! +$%d +%dHP", dMoney, dHP);
            ShowBonusMessage(killer, distMsg);
            if (get_pcvar_num(LogBonusCvar)) {
                log_to_file("killbonuses.log", distMsg);
            }
        }
    }
    /* Случаен бонус */
    new chance = get_pcvar_num(RandomChanceCvar);
    if (chance > 0 && random_num(1, 100) <= chance)
    {
        /* Случайният бонус ползва диапазони за пари и здраве */
        new minMoney = get_pcvar_num(RandomMoneyMinCvar);
        new maxMoney = get_pcvar_num(RandomMoneyMaxCvar);
        new minHP = get_pcvar_num(RandomHpMinCvar);
        new maxHP = get_pcvar_num(RandomHpMaxCvar);
        new rMoney = minMoney;
        new rHP = minHP;
        if (maxMoney >= minMoney)
        {
            rMoney = random_num(minMoney, maxMoney);
        }
        if (maxHP >= minHP)
        {
            rHP = random_num(minHP, maxHP);
        }
        AwardBonus(killer, rMoney, rHP);
        static rMsg[128];
        formatex(rMsg, charsmax(rMsg), "Kusmet! Poluchi +$%d +%dHP", rMoney, rHP);
        ShowBonusMessage(killer, rMsg);
        if (get_pcvar_num(LogBonusCvar)) {
            log_to_file("killbonuses.log", rMsg);
        }
    }
    /* Бонус за убийство при ниско здраве */
    new lowThresh = get_pcvar_num(LowHealthThresholdCvar);
    if (lowThresh > 0 && killerHealth <= lowThresh)
    {
        new lMoney = get_pcvar_num(LowHealthBonusMoneyCvar);
        new lHP = get_pcvar_num(LowHealthBonusHpCvar);
        AwardBonus(killer, lMoney, lHP);
        static lMsg[128];
        formatex(lMsg, charsmax(lMsg), "Klasichesko ubistvo pri nisko zdrave! +$%d +%dHP", lMoney, lHP);
        ShowBonusMessage(killer, lMsg);
        if (get_pcvar_num(LogBonusCvar)) {
            log_to_file("killbonuses.log", lMsg);
        }
    }
    /* Бонус за пистолетно убийство */
    if (equali(weapon, "usp") || equali(weapon, "glock18") || equali(weapon, "deagle") || equali(weapon, "p228") || equali(weapon, "elite") || equali(weapon, "fiveseven"))
    {
        new pMoney = get_pcvar_num(PistolBonusMoneyCvar);
        new pHP = get_pcvar_num(PistolBonusHpCvar);
        AwardBonus(killer, pMoney, pHP);
        static pMsg[128];
        formatex(pMsg, charsmax(pMsg), "Ubiistvo s pistolet! +$%d +%dHP", pMoney, pHP);
        ShowBonusMessage(killer, pMsg);
        if (get_pcvar_num(LogBonusCvar)) {
            log_to_file("killbonuses.log", pMsg);
        }
    }
    /* Spree бонус: допълнителни пари/здраве за всяко убийство след първото в живота */
    if (gKillStreak[killer] > 1)
    {
        new sMoney = get_pcvar_num(SpreeBonusMoneyCvar);
        new sHp = get_pcvar_num(SpreeBonusHpCvar);
        if (sMoney > 0 || sHp > 0)
        {
            AwardBonus(killer, sMoney, sHp);
            static sMsg[128];
            formatex(sMsg, charsmax(sMsg), "Seria! +$%d +%dHP", sMoney, sHp);
            ShowBonusMessage(killer, sMsg);
            if (get_pcvar_num(LogBonusCvar))
            {
                log_to_file("killbonuses.log", sMsg);
            }
        }
    }
    /* Combo бонус: убийства в бърза последователност (в рамките на nice_combo_time секунди) */
    {
        new Float:comboTime = get_pcvar_float(ComboTimeCvar);
        new Float:now = get_gametime();
        if (now - gLastKillTime[killer] <= comboTime)
        {
            gComboCount[killer]++;
            new cMoney = get_pcvar_num(ComboBonusMoneyCvar);
            new cHp = get_pcvar_num(ComboBonusHpCvar);
            if (cMoney > 0 || cHp > 0)
            {
                AwardBonus(killer, cMoney, cHp);
                static cMsg[128];
                formatex(cMsg, charsmax(cMsg), "Combo %d! +$%d +%dHP", gComboCount[killer], cMoney, cHp);
                ShowBonusMessage(killer, cMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", cMsg);
                }
            }
        }
        else
        {
            gComboCount[killer] = 1;
        }
        gLastKillTime[killer] = now;
    }
    /* Revenge бонус: ако убиецът убие играча, който последно го е убил */
    if (gLastKiller[killer] == victim)
    {
        new rMoney = get_pcvar_num(RevengeBonusMoneyCvar);
        new rHp = get_pcvar_num(RevengeBonusHpCvar);
        if (rMoney > 0 || rHp > 0)
        {
            AwardBonus(killer, rMoney, rHp);
            static rvMsg[128];
            formatex(rvMsg, charsmax(rvMsg), "Revansh! +$%d +%dHP", rMoney, rHp);
            ShowBonusMessage(killer, rvMsg);
            if (get_pcvar_num(LogBonusCvar))
            {
                log_to_file("killbonuses.log", rvMsg);
            }
        }
    }
    /* Бонус за последен оцелял: ако убиецът е единственият жив играч в отбора си */
    {
        new players[32], num;
        get_players(players, num, "ae", (cs_get_user_team(killer) == CS_TEAM_T) ? "TERRORIST" : "CT");
        if (num == 1)
        {
            new lmMoney = get_pcvar_num(LastManBonusMoneyCvar);
            new lmHp = get_pcvar_num(LastManBonusHpCvar);
            if (lmMoney > 0 || lmHp > 0)
            {
                AwardBonus(killer, lmMoney, lmHp);
                static lmMsg[128];
                formatex(lmMsg, charsmax(lmMsg), "Posleden zhiv! +$%d +%dHP", lmMoney, lmHp);
                ShowBonusMessage(killer, lmMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", lmMsg);
                }
            }
        }
    }
    /* Бонус за снайперско убийство с определени оръжия */
    if (equali(weapon, "awp") || equali(weapon, "scout") || equali(weapon, "g3sg1") || equali(weapon, "sg550"))
    {
        new snMoney = get_pcvar_num(SniperBonusMoneyCvar);
        new snHp = get_pcvar_num(SniperBonusHpCvar);
        if (snMoney > 0 || snHp > 0)
        {
            AwardBonus(killer, snMoney, snHp);
            static snMsg[128];
            formatex(snMsg, charsmax(snMsg), "Sniper ubistvo! +$%d +%dHP", snMoney, snHp);
            ShowBonusMessage(killer, snMsg);
            if (get_pcvar_num(LogBonusCvar))
            {
                log_to_file("killbonuses.log", snMsg);
            }
        }
    }
    /* Бонус за оръжие със заглушител (m4a1 и usp в заглушен режим) */
    if (equali(weapon, "m4a1") || equali(weapon, "usp"))
    {
        new spMoney = get_pcvar_num(SuppressBonusMoneyCvar);
        new spHp = get_pcvar_num(SuppressBonusHpCvar);
        if (spMoney > 0 || spHp > 0)
        {
            AwardBonus(killer, spMoney, spHp);
            static spMsg[128];
            formatex(spMsg, charsmax(spMsg), "Tih ubiec! +$%d +%dHP", spMoney, spHp);
            ShowBonusMessage(killer, spMsg);
            if (get_pcvar_num(LogBonusCvar))
            {
                log_to_file("killbonuses.log", spMsg);
            }
        }
    }
    /* Бонус за „неудържим“ – когато серията достигне зададения праг */
    {
        new unstopThresh = get_pcvar_num(UnstoppableThresholdCvar);
        if (unstopThresh > 0 && gKillStreak[killer] == unstopThresh)
        {
            new uMoney = get_pcvar_num(UnstoppableBonusMoneyCvar);
            new uHp = get_pcvar_num(UnstoppableBonusHpCvar);
            AwardBonus(killer, uMoney, uHp);
            static uMsg[128];
            formatex(uMsg, charsmax(uMsg), "NEUSTOIM! +$%d +%dHP", uMoney, uHp);
            ShowBonusMessage(0, uMsg);
            if (get_pcvar_num(LogBonusCvar))
            {
                log_to_file("killbonuses.log", uMsg);
            }
        }
    }
    /* Съобщения за напредъка на серията – ако е включено */
    if (get_pcvar_num(StreakProgressCvar))
    {
        static progMsg[128];
        formatex(progMsg, charsmax(progMsg), "V momenta si na seria ot %d ubistva", gKillStreak[killer]);
        ShowBonusMessage(killer, progMsg);
    }
    /* ===== НОВИ ФУНКЦИИ ЗА БОНУСИ ===== */
    /* 1. Бонуси за вид оръжие (дробовик, SMG, пушка, картечница, Deagle) */
    {
        new catMoney = 0, catHp = 0;
        if (equali(weapon, "m3") || equali(weapon, "xm1014"))
        {
            catMoney = get_pcvar_num(ShotgunBonusMoneyCvar);
            catHp = get_pcvar_num(ShotgunBonusHpCvar);
        }
        else if (equali(weapon, "mp5navy") || equali(weapon, "tmp") || equali(weapon, "p90") || equali(weapon, "mac10") || equali(weapon, "ump45"))
        {
            catMoney = get_pcvar_num(SmgBonusMoneyCvar);
            catHp = get_pcvar_num(SmgBonusHpCvar);
        }
        else if (equali(weapon, "ak47") || equali(weapon, "m4a1") || equali(weapon, "famas") || equali(weapon, "galil") || equali(weapon, "sg552") || equali(weapon, "aug"))
        {
            catMoney = get_pcvar_num(RifleBonusMoneyCvar);
            catHp = get_pcvar_num(RifleBonusHpCvar);
        }
        else if (equali(weapon, "m249"))
        {
            catMoney = get_pcvar_num(MachinegunBonusMoneyCvar);
            catHp = get_pcvar_num(MachinegunBonusHpCvar);
        }
        else if (equali(weapon, "deagle"))
        {
            catMoney = get_pcvar_num(DeagleBonusMoneyCvar);
            catHp = get_pcvar_num(DeagleBonusHpCvar);
        }
        if (catMoney != 0 || catHp != 0)
        {
            AwardBonus(killer, catMoney, catHp);
            static catMsg[128];
            formatex(catMsg, charsmax(catMsg), "Bonus oruzhie! +$%d +%dHP", catMoney, catHp);
            ShowBonusMessage(killer, catMsg);
            if (get_pcvar_num(LogBonusCvar))
            {
                log_to_file("killbonuses.log", catMsg);
            }
        }
    }
    /* 2. Бонус за серия от поредни headshot-и */
    {
        if (headshot)
        {
            gHSStreak[killer]++;
        }
        else
        {
            gHSStreak[killer] = 0;
        }
        new hsThresh = get_pcvar_num(HSStreakThresholdCvar);
        if (hsThresh > 0 && gHSStreak[killer] >= hsThresh)
        {
            new hsMoney2 = get_pcvar_num(HSStreakBonusMoneyCvar);
            new hsHp2 = get_pcvar_num(HSStreakBonusHpCvar);
            if (hsMoney2 != 0 || hsHp2 != 0)
            {
                AwardBonus(killer, hsMoney2, hsHp2);
                static hsMsg2[128];
                formatex(hsMsg2, charsmax(hsMsg2), "Seria headshot-i! +$%d +%dHP", hsMoney2, hsHp2);
                ShowBonusMessage(killer, hsMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", hsMsg2);
                }
            }
            gHSStreak[killer] = 0;
        }
    }
    /* 3. Бонус за убийство при клек (crouch) */
    {
        new flags = entity_get_int(killer, EV_INT_flags);
        if (flags & FL_DUCKING)
        {
            new crMoney2 = get_pcvar_num(CrouchBonusMoneyCvar);
            new crHp2 = get_pcvar_num(CrouchBonusHpCvar);
            if (crMoney2 != 0 || crHp2 != 0)
            {
                AwardBonus(killer, crMoney2, crHp2);
                static crMsg2[128];
                formatex(crMsg2, charsmax(crMsg2), "Krouch kill! +$%d +%dHP", crMoney2, crHp2);
                ShowBonusMessage(killer, crMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", crMsg2);
                }
            }
        }
    }
    /* 4. Бонус за въздушно убийство (killer във въздуха) */
    {
        new flags2 = entity_get_int(killer, EV_INT_flags);
        if (!(flags2 & FL_ONGROUND))
        {
            new airMoney2 = get_pcvar_num(AirBonusMoneyCvar);
            new airHp2 = get_pcvar_num(AirBonusHpCvar);
            if (airMoney2 != 0 || airHp2 != 0)
            {
                AwardBonus(killer, airMoney2, airHp2);
                static airMsg2[128];
                formatex(airMsg2, charsmax(airMsg2), "Vzduh ubistvo! +$%d +%dHP", airMoney2, airHp2);
                ShowBonusMessage(killer, airMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", airMsg2);
                }
            }
        }
    }
    /* 5. Бонус за убийство с последен патрон в пълнителя */
    {
        new lbClip, lbAmmo;
        /* Използваме get_user_weapon, за да получим стойностите на патроните в пълнителя
         * и резервната амуниция. Върнатата стойност (идентификатор на оръжието)
         * не ни е необходима тук. */
        get_user_weapon(killer, lbClip, lbAmmo);
        if (lbClip == 0 && killType == 0)
        {
            new lbMoney2 = get_pcvar_num(LastBulletBonusMoneyCvar);
            new lbHp2 = get_pcvar_num(LastBulletBonusHpCvar);
            if (lbMoney2 != 0 || lbHp2 != 0)
            {
                AwardBonus(killer, lbMoney2, lbHp2);
                static lbMsg2[128];
                formatex(lbMsg2, charsmax(lbMsg2), "Posleden patron! +$%d +%dHP", lbMoney2, lbHp2);
                ShowBonusMessage(killer, lbMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", lbMsg2);
                }
            }
        }
    }
    /* 6. Бонус за няколко убийства с граната в един рунд */
    {
        new gmThresh2 = get_pcvar_num(GrenadeMultiKillThresholdCvar);
        if (killType == 3)
        {
            gGrenadeKillCount[killer]++;
            if (gmThresh2 > 0 && gGrenadeKillCount[killer] >= gmThresh2)
            {
                new gmMoney2 = get_pcvar_num(GrenadeMultiKillBonusMoneyCvar);
                new gmHp2 = get_pcvar_num(GrenadeMultiKillBonusHpCvar);
                if (gmMoney2 != 0 || gmHp2 != 0)
                {
                    AwardBonus(killer, gmMoney2, gmHp2);
                    static gmMsg2[128];
                    formatex(gmMsg2, charsmax(gmMsg2), "Multi-kill s granata! +$%d +%dHP", gmMoney2, gmHp2);
                    ShowBonusMessage(killer, gmMsg2);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", gmMsg2);
                    }
                }
                gGrenadeKillCount[killer] = 0;
            }
        }
    }
    /* 7. Бонус за clutch убийство (сам срещу X врагове) */
    {
        new oppThresh2 = get_pcvar_num(ClutchOpponentsThresholdCvar);
        if (oppThresh2 > 0)
        {
            /* използваме CsTeams таг за да избегнем предупреждения за несъответствие */
            new CsTeams:killerTeam2 = cs_get_user_team(killer);
            new players2[32], num2, aliveTeam2 = 0, aliveOpp2 = 0;
            get_players(players2, num2, "ae");
            for (new ii = 0; ii < num2; ii++)
            {
                if (cs_get_user_team(players2[ii]) == killerTeam2)
                    aliveTeam2++;
                else
                    aliveOpp2++;
            }
            if (aliveTeam2 == 1 && aliveOpp2 >= oppThresh2)
            {
                new clMoney2 = get_pcvar_num(ClutchBonusMoneyCvar);
                new clHp2 = get_pcvar_num(ClutchBonusHpCvar);
                if (clMoney2 != 0 || clHp2 != 0)
                {
                    AwardBonus(killer, clMoney2, clHp2);
                    static clMsg2[128];
                    formatex(clMsg2, charsmax(clMsg2), "Clutch kill! +$%d +%dHP", clMoney2, clHp2);
                    ShowBonusMessage(killer, clMsg2);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", clMsg2);
                    }
                }
            }
        }
    }
    /* 8. Бонус за убийство на лидер на рунда */
    {
        new maxKills2 = 0;
        for (new jj = 1; jj <= 32; jj++)
        {
            if (gRoundKills[jj] > maxKills2)
                maxKills2 = gRoundKills[jj];
        }
        if (maxKills2 > 0 && gRoundKills[victim] == maxKills2)
        {
            new ldMoney2 = get_pcvar_num(LeaderBonusMoneyCvar);
            new ldHp2 = get_pcvar_num(LeaderBonusHpCvar);
            if (ldMoney2 != 0 || ldHp2 != 0)
            {
                AwardBonus(killer, ldMoney2, ldHp2);
                static ldMsg2[128], vName2[32];
                get_user_name(victim, vName2, charsmax(vName2));
                formatex(ldMsg2, charsmax(ldMsg2), "Premahna lidera %s! +$%d +%dHP", vName2, ldMoney2, ldHp2);
                ShowBonusMessage(killer, ldMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", ldMsg2);
                }
            }
        }
    }
    /* 9. Бързо убийство – ако се случи в първите няколко секунди на рунда */
    {
        new Float:now2 = get_gametime();
        new Float:threshold2 = get_pcvar_float(FastKillTimeCvar);
        if (threshold2 > 0.0 && now2 - gRoundStartTime <= threshold2)
        {
            new fkMoney2 = get_pcvar_num(FastKillBonusMoneyCvar);
            new fkHp2 = get_pcvar_num(FastKillBonusHpCvar);
            if (fkMoney2 != 0 || fkHp2 != 0)
            {
                AwardBonus(killer, fkMoney2, fkHp2);
                static fkMsg2[128];
                formatex(fkMsg2, charsmax(fkMsg2), "Burzo ubistvo! +$%d +%dHP", fkMoney2, fkHp2);
                ShowBonusMessage(killer, fkMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", fkMsg2);
                }
            }
        }
    }
    /* 10. Бонус за убийство на носителя на бомбата */
    {
        /* Проверяваме дали жертвата има C4 (бомба) чрез user_has_weapon.
         * Използваме стандартната константа CSW_C4, която е дефинирана в cstrike_const.inc.
         */
        if (user_has_weapon(victim, CSW_C4))
        {
            new bcMoney2 = get_pcvar_num(BombCarrierBonusMoneyCvar);
            new bcHp2 = get_pcvar_num(BombCarrierBonusHpCvar);
            if (bcMoney2 != 0 || bcHp2 != 0)
            {
                AwardBonus(killer, bcMoney2, bcHp2);
                static bcMsg2[128];
                formatex(bcMsg2, charsmax(bcMsg2), "Ubi bombonosetsa! +$%d +%dHP", bcMoney2, bcHp2);
                ShowBonusMessage(killer, bcMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", bcMsg2);
                }
            }
        }
    }
    /* 11. Бонус за няколко убийства с нож в рунда */
    {
        new knifeThresh2 = get_pcvar_num(KnifeMultiKillThresholdCvar);
        if (killType == 2)
        {
            gKnifeKillCount[killer]++;
            if (knifeThresh2 > 0 && gKnifeKillCount[killer] >= knifeThresh2)
            {
                new kmMoney2 = get_pcvar_num(KnifeMultiKillBonusMoneyCvar);
                new kmHp2 = get_pcvar_num(KnifeMultiKillBonusHpCvar);
                if (kmMoney2 != 0 || kmHp2 != 0)
                {
                    AwardBonus(killer, kmMoney2, kmHp2);
                    static kmMsg2[128];
                    formatex(kmMsg2, charsmax(kmMsg2), "Multi-kill s nozh! +$%d +%dHP", kmMoney2, kmHp2);
                    ShowBonusMessage(killer, kmMsg2);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", kmMsg2);
                    }
                }
                gKnifeKillCount[killer] = 0;
            }
        }
    }
    /* 12. Бонус за поредица от убийства с различни оръжия */
    {
        new wsClip2, wsAmmo2, wsId;
        wsId = get_user_weapon(killer, wsClip2, wsAmmo2);
        if (gLastWeaponID[killer] != wsId)
        {
            gWeaponStreakCount[killer]++;
        }
        else
        {
            gWeaponStreakCount[killer] = 1;
        }
        gLastWeaponID[killer] = wsId;
        new wsThresh2 = get_pcvar_num(WeaponSwitchStreakThresholdCvar);
        if (wsThresh2 > 0 && gWeaponStreakCount[killer] >= wsThresh2)
        {
            new wsMoney2 = get_pcvar_num(WeaponSwitchBonusMoneyCvar);
            new wsHp2 = get_pcvar_num(WeaponSwitchBonusHpCvar);
            if (wsMoney2 != 0 || wsHp2 != 0)
            {
                AwardBonus(killer, wsMoney2, wsHp2);
                static wsMsg2[128];
                formatex(wsMsg2, charsmax(wsMsg2), "Orujien streak! +$%d +%dHP", wsMoney2, wsHp2);
                ShowBonusMessage(killer, wsMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", wsMsg2);
                }
            }
            gWeaponStreakCount[killer] = 0;
        }
    }
    /* 13. Бонус за няколко убийства без презареждане */
    {
        new nrClip2, nrAmmo2, nrId;
        nrId = get_user_weapon(killer, nrClip2, nrAmmo2);
        if (gClipWeaponId[killer] != nrId)
        {
            gClipKillCount[killer] = 1;
        }
        else
        {
            if (nrClip2 > gLastWeaponClip[killer])
            {
                gClipKillCount[killer] = 1;
            }
            else
            {
                gClipKillCount[killer]++;
            }
        }
        gClipWeaponId[killer] = nrId;
        gLastWeaponClip[killer] = nrClip2;
        new nrThresh2 = get_pcvar_num(NoReloadKillThresholdCvar);
        if (nrThresh2 > 0 && gClipKillCount[killer] >= nrThresh2)
        {
            new nrMoney2 = get_pcvar_num(NoReloadBonusMoneyCvar);
            new nrHp2 = get_pcvar_num(NoReloadBonusHpCvar);
            if (nrMoney2 != 0 || nrHp2 != 0)
            {
                AwardBonus(killer, nrMoney2, nrHp2);
                static nrMsg2[128];
                formatex(nrMsg2, charsmax(nrMsg2), "Kill bez prezarezhdane! +$%d +%dHP", nrMoney2, nrHp2);
                ShowBonusMessage(killer, nrMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", nrMsg2);
                }
            }
            gClipKillCount[killer] = 0;
        }
    }
    /* 14. Бонус за конкретни оръжия (обикновено и headshot)
     * За всяко оръжие от списъка WeaponNames дава отделен бонус. Това
     * позволява допълнително стимулиране на играчите да използват
     * любимото си оръжие. Съществуват два набора cvar-ове: за нормално
     * убийство и за headshot. Ако стойностите са нула, бонус не се прилага.
     */
    {
        /* Намиране на индекса на оръжието в списъка. Търсим до съвпадение */
        for (new wi = 0; wi < WEAPON_COUNT; wi++)
        {
            if (equali(weapon, WeaponNames[wi]))
            {
                new wMoney, wHp;
                if (headshot)
                {
                    wMoney = get_pcvar_num(WeaponHsBonusMoneyCvar[wi]);
                    wHp = get_pcvar_num(WeaponHsBonusHpCvar[wi]);
                }
                else
                {
                    wMoney = get_pcvar_num(WeaponBonusMoneyCvar[wi]);
                    wHp = get_pcvar_num(WeaponBonusHpCvar[wi]);
                }
                if (wMoney != 0 || wHp != 0)
                {
                    AwardBonus(killer, wMoney, wHp);
                    static wMsg[128];
                    if (headshot)
                    {
                        formatex(wMsg, charsmax(wMsg), "Specifichen HS bonus s %s! +$%d +%dHP", WeaponNames[wi], wMoney, wHp);
                    }
                    else
                    {
                        formatex(wMsg, charsmax(wMsg), "Specifichen bonus s %s! +$%d +%dHP", WeaponNames[wi], wMoney, wHp);
                    }
                    ShowBonusMessage(killer, wMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", wMsg);
                    }
                }
                break;
            }
        }
    }
    /*
     * 15. Специфични бонуси при убийство в клек и във въздуха за всяко оръжие
     * За всяко оръжие от списъка WeaponNames се проверява дали убиецът е клекнал
     * (FL_DUCKING) или се намира във въздуха (не е на земята – няма флаг FL_ONGROUND).
     * При съвпадение се прилагат съответните cvar-ове nice_<weapon>_crouch_bonus_* и
     * nice_<weapon>_air_bonus_*.  Добавяме отделни съобщения за клек и въздушен
     * бонус.  Ако стойностите са нула, бонус не се прилага.
     */
    {
        /* Получаваме флаговете на убиеца, за да проверим позата му. */
        new kFlags = entity_get_int(killer, EV_INT_flags);
        /* Обхождаме списъка с оръжия, за да намерим съвпадение. */
        for (new ci = 0; ci < WEAPON_COUNT; ci++)
        {
            if (equali(weapon, WeaponNames[ci]))
            {
                /* Бонус при клек (crouch) с конкретно оръжие */
                if (kFlags & FL_DUCKING)
                {
                    new cMoney = get_pcvar_num(WeaponCrouchBonusMoneyCvar[ci]);
                    new cHp = get_pcvar_num(WeaponCrouchBonusHpCvar[ci]);
                    if (cMoney != 0 || cHp != 0)
                    {
                        AwardBonus(killer, cMoney, cHp);
                        static cMsg[128];
                        formatex(cMsg, charsmax(cMsg), "Specifichen crouch bonus s %s! +$%d +%dHP", WeaponNames[ci], cMoney, cHp);
                        ShowBonusMessage(killer, cMsg);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", cMsg);
                        }
                    }
                }
                /* Бонус при въздушно убийство (air kill) с конкретно оръжие */
                if (!(kFlags & FL_ONGROUND))
                {
                    new aMoney = get_pcvar_num(WeaponAirBonusMoneyCvar[ci]);
                    new aHp = get_pcvar_num(WeaponAirBonusHpCvar[ci]);
                    if (aMoney != 0 || aHp != 0)
                    {
                        AwardBonus(killer, aMoney, aHp);
                        static aMsg[128];
                        formatex(aMsg, charsmax(aMsg), "Specifichen air bonus s %s! +$%d +%dHP", WeaponNames[ci], aMoney, aHp);
                        ShowBonusMessage(killer, aMsg);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", aMsg);
                        }
                    }
                }
                /* Намерихме съвпадение, няма нужда да продължаваме да обхождаме. */
                break;
            }
        }
    }

    /*
     * 16. Бонуси, базирани на околна среда и екипировка
     * Проверяваме състоянието на убиеца (броня, каска, NVG, притежание на бомба/defuse kit,
     * височина спрямо жертвата и разстояние) и прилагаме съответните бонуси.
     * Стойностите се дефинират чрез cvar-ове nice_fullarmor_bonus_*, nice_helmet_bonus_*,
     * nice_noarmor_bonus_*, nice_nvg_bonus_*, nice_carrybomb_kill_bonus_*,
     * nice_defusekit_kill_bonus_*, nice_highground_bonus_*, nice_lowground_bonus_*,
     * nice_closerange_bonus_* и nice_mediumrange_bonus_*.
     */
    {
        /* Проверка за броня и каска: cs_get_user_armor връща стойността на бронята и типа й. */
        new CsArmorType:armorType;
        new armorVal = cs_get_user_armor(killer, armorType);
        /* Пълна броня (100) с каска */
        if (armorVal >= 100 && armorType == CS_ARMOR_VESTHELM)
        {
            new fMoney = get_pcvar_num(FullArmorBonusMoneyCvar);
            new fHp = get_pcvar_num(FullArmorBonusHpCvar);
            if (fMoney != 0 || fHp != 0)
            {
                AwardBonus(killer, fMoney, fHp);
                static fMsg[128];
                formatex(fMsg, charsmax(fMsg), "Pulna bronya s kasca! +$%d +%dHP", fMoney, fHp);
                ShowBonusMessage(killer, fMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", fMsg);
                }
            }
        }
        /* Само каска (вест+каска) но не пълна броня */
        else if (armorType == CS_ARMOR_VESTHELM)
        {
            new hMoney = get_pcvar_num(HelmetBonusMoneyCvar);
            new hHp = get_pcvar_num(HelmetBonusHpCvar);
            if (hMoney != 0 || hHp != 0)
            {
                AwardBonus(killer, hMoney, hHp);
                static hMsg[128];
                formatex(hMsg, charsmax(hMsg), "Bronya s kasca! +$%d +%dHP", hMoney, hHp);
                ShowBonusMessage(killer, hMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", hMsg);
                }
            }
        }
        /* Без броня */
        else if (armorType == CS_ARMOR_NONE)
        {
            new naMoney = get_pcvar_num(NoArmorBonusMoneyCvar);
            new naHp = get_pcvar_num(NoArmorBonusHpCvar);
            if (naMoney != 0 || naHp != 0)
            {
                AwardBonus(killer, naMoney, naHp);
                static naMsg[128];
                formatex(naMsg, charsmax(naMsg), "Bez bronya! +$%d +%dHP", naMoney, naHp);
                ShowBonusMessage(killer, naMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", naMsg);
                }
            }
        }
        /* Нощно виждане */
        if (cs_get_user_nvg(killer))
        {
            new nvgMoney = get_pcvar_num(NvgBonusMoneyCvar);
            new nvgHp = get_pcvar_num(NvgBonusHpCvar);
            if (nvgMoney != 0 || nvgHp != 0)
            {
                AwardBonus(killer, nvgMoney, nvgHp);
                static nvgMsg[128];
                formatex(nvgMsg, charsmax(nvgMsg), "Nosish NVG! +$%d +%dHP", nvgMoney, nvgHp);
                ShowBonusMessage(killer, nvgMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", nvgMsg);
                }
            }
        }
        /* Убиецът носи C4 бомба */
        if (user_has_weapon(killer, CSW_C4))
        {
            new bcMoney = get_pcvar_num(BombCarryKillBonusMoneyCvar);
            new bcHp = get_pcvar_num(BombCarryKillBonusHpCvar);
            if (bcMoney != 0 || bcHp != 0)
            {
                AwardBonus(killer, bcMoney, bcHp);
                static bcMsg[128];
                formatex(bcMsg, charsmax(bcMsg), "Nosish C4! +$%d +%dHP", bcMoney, bcHp);
                ShowBonusMessage(killer, bcMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", bcMsg);
                }
            }
        }
        /* Убиецът носи defuse kit */
        /*
         * В някои версии на AMXX функцията за проверка на defuse kit се нарича
         * cs_get_user_defuse, а не cs_get_user_defusekit. За съвместимост
         * използваме cs_get_user_defuse(), която връща 1 ако играчът има
         * defuse kit. Ако съществува и cs_get_user_defusekit, тя ще бъде
         * дефинирана да сочи към cs_get_user_defuse чрез условна директива
         * по-долу в кода.
         */
        if (cs_get_user_defuse(killer))
        {
            new dkMoney = get_pcvar_num(DefuseKitKillBonusMoneyCvar);
            new dkHp = get_pcvar_num(DefuseKitKillBonusHpCvar);
            if (dkMoney != 0 || dkHp != 0)
            {
                AwardBonus(killer, dkMoney, dkHp);
                static dkMsg[128];
                formatex(dkMsg, charsmax(dkMsg), "Nosish defuse kit! +$%d +%dHP", dkMoney, dkHp);
                ShowBonusMessage(killer, dkMsg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", dkMsg);
                }
            }
        }
        /* Изчисляване на разстоянието и височината между убиеца и жертвата за високо/ниско място и близка/средна дистанция */
        {
            static oK[3], oV[3];
            get_user_origin(killer, oK, 0);
            get_user_origin(victim, oV, 0);
            new dX = oK[0] - oV[0];
            new dY = oK[1] - oV[1];
            new dZ = oK[2] - oV[2];
            new dist2hv = dX*dX + dY*dY + dZ*dZ;
            /* Високо/ниско място: праг 50 единици по Z-оста */
            if (dZ > 50)
            {
                new hgMoney = get_pcvar_num(HighGroundBonusMoneyCvar);
                new hgHp = get_pcvar_num(HighGroundBonusHpCvar);
                if (hgMoney != 0 || hgHp != 0)
                {
                    AwardBonus(killer, hgMoney, hgHp);
                    static hgMsg[128];
                    formatex(hgMsg, charsmax(hgMsg), "Ubivash ot visoko! +$%d +%dHP", hgMoney, hgHp);
                    ShowBonusMessage(killer, hgMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", hgMsg);
                    }
                }
            }
            else if (dZ < -50)
            {
                new lgMoney = get_pcvar_num(LowGroundBonusMoneyCvar);
                new lgHp = get_pcvar_num(LowGroundBonusHpCvar);
                if (lgMoney != 0 || lgHp != 0)
                {
                    AwardBonus(killer, lgMoney, lgHp);
                    static lgMsg[128];
                    formatex(lgMsg, charsmax(lgMsg), "Ubivash ot nishto! +$%d +%dHP", lgMoney, lgHp);
                    ShowBonusMessage(killer, lgMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", lgMsg);
                    }
                }
            }
            /* Близка и средна дистанция: прагове 500 и 1500 единици */
            new closeThresh2 = 500 * 500;
            new mediumThresh2 = 1500 * 1500;
            if (dist2hv <= closeThresh2)
            {
                new crMoney = get_pcvar_num(CloseRangeBonusMoneyCvar);
                new crHp = get_pcvar_num(CloseRangeBonusHpCvar);
                if (crMoney != 0 || crHp != 0)
                {
                    AwardBonus(killer, crMoney, crHp);
                    static crMsg3[128];
                    formatex(crMsg3, charsmax(crMsg3), "Bliska distanciya! +$%d +%dHP", crMoney, crHp);
                    ShowBonusMessage(killer, crMsg3);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", crMsg3);
                    }
                }
            }
            else if (dist2hv <= mediumThresh2)
            {
                new mrMoney = get_pcvar_num(MediumRangeBonusMoneyCvar);
                new mrHp = get_pcvar_num(MediumRangeBonusHpCvar);
                if (mrMoney != 0 || mrHp != 0)
                {
                    AwardBonus(killer, mrMoney, mrHp);
                    static mrMsg3[128];
                    formatex(mrMsg3, charsmax(mrMsg3), "Sredna distanciya! +$%d +%dHP", mrMoney, mrHp);
                    ShowBonusMessage(killer, mrMsg3);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", mrMsg3);
                    }
                }
            }
        }
    }
    /*
     * --- Допълнителни бонуси за milestones, HP прагове, вода, spawn kill, карти и богати играчи (версия 9.0) ---
     *
     * След като обработим бонусите, базирани на оръжия и околна среда, увеличаваме
     * брояча за общи убийства и headshot-и за играча и прилагаме подходящи
     * milestone бонуси. Тези бонуси се активират когато играчът достигне
     * определен брой общи убийства или headshot-и, когато е с високо или ниско
     * здраве, когато убие във вода, бързо след началото на рунда, на определени
     * карти или когато има голямо количество пари.
     */
    {
        /* Увеличаваме общите броячи за убийства и headshot-и през картата */
        gTotalKills[killer]++;
        if (headshot)
        {
            gTotalHSKills[killer]++;
        }
        /* 1. Kill milestone bonuses: награда при достигане на определен брой общи убийства */
        for (new mi = 0; mi < KILL_MILESTONE_COUNT; mi++)
        {
            /* Прагът е номерът на milestone (от 1 до KILL_MILESTONE_COUNT) */
            if (gTotalKills[killer] == (mi + 1))
            {
                new mMoney = get_pcvar_num(KillMilestoneMoneyCvar[mi]);
                new mHp = get_pcvar_num(KillMilestoneHpCvar[mi]);
                if (mMoney != 0 || mHp != 0)
                {
                    AwardBonus(killer, mMoney, mHp);
                    static mMsg[128];
                    formatex(mMsg, charsmax(mMsg), "Milestone %d ubiistva! +$%d +%dHP", mi + 1, mMoney, mHp);
                    ShowBonusMessage(killer, mMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", mMsg);
                    }
                }
                break;
            }
        }
        /* 2. Headshot milestone bonuses: награда при достигане на определен брой headshot-и */
        if (headshot)
        {
            for (new hj = 0; hj < HS_MILESTONE_COUNT; hj++)
            {
                if (gTotalHSKills[killer] == (hj + 1))
                {
                    new hsMoney3 = get_pcvar_num(HSMilestoneMoneyCvar[hj]);
                    new hsHp3 = get_pcvar_num(HSMilestoneHpCvar[hj]);
                    if (hsMoney3 != 0 || hsHp3 != 0)
                    {
                        AwardBonus(killer, hsMoney3, hsHp3);
                        static hsMsg3[128];
                        formatex(hsMsg3, charsmax(hsMsg3), "HS milestone %d! +$%d +%dHP", hj + 1, hsMoney3, hsHp3);
                        ShowBonusMessage(killer, hsMsg3);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", hsMsg3);
                        }
                    }
                    break;
                }
            }
        }
        /* 3. Бонуси за високо здраве: проверяваме от по-високите прагове към по-ниските */
        {
            for (new hi = 0; hi < HIGH_HP_THRESHOLD_COUNT; hi++)
            {
                new thrH = HighHpThresholds[hi];
                if (killerHealth >= thrH)
                {
                    new hMoney2 = get_pcvar_num(HighHpBonusMoneyCvar[hi]);
                    new hHp2 = get_pcvar_num(HighHpBonusHpCvar[hi]);
                    if (hMoney2 != 0 || hHp2 != 0)
                    {
                        AwardBonus(killer, hMoney2, hHp2);
                        static hMsg2[128];
                        formatex(hMsg2, charsmax(hMsg2), "Vysoko HP (%d+) kill! +$%d +%dHP", thrH, hMoney2, hHp2);
                        ShowBonusMessage(killer, hMsg2);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", hMsg2);
                        }
                    }
                    /* Не прекъсваме, за да позволим награда за няколко прага, ако администраторът желае */
                }
            }
        }
        /* 4. Бонуси за ниско здраве: ако здравето на убиеца е под или равно на прага */
        {
            for (new li = 0; li < LOW_HP_THRESHOLD_COUNT; li++)
            {
                new thrL = LowHpThresholds[li];
                if (killerHealth <= thrL)
                {
                    new lMoney2 = get_pcvar_num(LowHpBonusMoneyCvar[li]);
                    new lHp2 = get_pcvar_num(LowHpBonusHpCvar[li]);
                    if (lMoney2 != 0 || lHp2 != 0)
                    {
                        AwardBonus(killer, lMoney2, lHp2);
                        static lMsg2[128];
                        formatex(lMsg2, charsmax(lMsg2), "Nisko HP (%d-) kill! +$%d +%dHP", thrL, lMoney2, lHp2);
                        ShowBonusMessage(killer, lMsg2);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", lMsg2);
                        }
                    }
                    /* Не прекъсваме – може да се прилагат няколко прага */
                }
            }
        }
        /* 5. Бонус за убийство във вода */
        if (entity_get_int(killer, EV_INT_waterlevel) > 0)
        {
            new wMoney = get_pcvar_num(WaterKillBonusMoneyCvar);
            new wHp = get_pcvar_num(WaterKillBonusHpCvar);
            if (wMoney != 0 || wHp != 0)
            {
                AwardBonus(killer, wMoney, wHp);
                static wMsg2[128];
                formatex(wMsg2, charsmax(wMsg2), "Kill pod voda! +$%d +%dHP", wMoney, wHp);
                ShowBonusMessage(killer, wMsg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", wMsg2);
                }
            }
        }
        /* 6. Бонус за spawn kill – убийство рано след началото на рунда */
        {
            new Float:spawnThresh = get_pcvar_float(SpawnKillTimeCvar);
            if (spawnThresh > 0.0)
            {
                new Float:now3 = get_gametime();
                if (now3 - gRoundStartTime <= spawnThresh)
                {
                    new spMoney2 = get_pcvar_num(SpawnKillBonusMoneyCvar);
                    new spHp2 = get_pcvar_num(SpawnKillBonusHpCvar);
                    if (spMoney2 != 0 || spHp2 != 0)
                    {
                        AwardBonus(killer, spMoney2, spHp2);
                        static spMsg3[128];
                        formatex(spMsg3, charsmax(spMsg3), "Spawn kill! +$%d +%dHP", spMoney2, spHp2);
                        ShowBonusMessage(killer, spMsg3);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", spMsg3);
                        }
                    }
                }
            }
        }
        /* 7. Map-specific bonuses – проверяваме името на картата */
        {
            static curMap[32];
            get_mapname(curMap, charsmax(curMap));
            for (new mp = 0; mp < MAP_BONUS_COUNT; mp++)
            {
                if (equali(curMap, MapBonusNames[mp]))
                {
                    new mpmoney = get_pcvar_num(MapBonusMoneyCvar[mp]);
                    new mph = get_pcvar_num(MapBonusHpCvar[mp]);
                    if (mpmoney != 0 || mph != 0)
                    {
                        AwardBonus(killer, mpmoney, mph);
                        static mpMsg[128];
                        formatex(mpMsg, charsmax(mpMsg), "Karta %s bonus! +$%d +%dHP", MapBonusNames[mp], mpmoney, mph);
                        ShowBonusMessage(killer, mpMsg);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", mpMsg);
                        }
                    }
                    break;
                }
            }
        }
        /* 8. Богат убиец: бонус ако играчът има много пари */
        {
            new curMoney = cs_get_user_money(killer);
            for (new ri = 0; ri < RICH_THRESHOLD_COUNT; ri++)
            {
                new rThr = RichThresholds[ri];
                if (curMoney >= rThr)
                {
                    new rMoney2 = get_pcvar_num(RichBonusMoneyCvar[ri]);
                    new rHp2 = get_pcvar_num(RichBonusHpCvar[ri]);
                    if (rMoney2 != 0 || rHp2 != 0)
                    {
                        AwardBonus(killer, rMoney2, rHp2);
                        static rMsg2[128];
                        formatex(rMsg2, charsmax(rMsg2), "Bogatyash bonus (%d+)! +$%d +%dHP", rThr, rMoney2, rHp2);
                        ShowBonusMessage(killer, rMsg2);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", rMsg2);
                        }
                    }
                }
            }
        }
    }

    /*
     * 17. Бонус за асистенция
     * След като жертвата умре, проверяваме всички играчи, които са нанесли
     * значителни щети (>=50 HP) на жертвата, но не са я убили. Те получават
     * бонус, конфигуриран чрез nice_assist_bonus_money и nice_assist_bonus_hp.
     * След възнаграждаване, обнуляваме съхранените щети за този случай.
     */
    {
        new asMoney = get_pcvar_num(AssistBonusMoneyCvar);
        new asHp = get_pcvar_num(AssistBonusHpCvar);
        if (asMoney != 0 || asHp != 0)
        {
            for (new ap = 1; ap <= 32; ap++)
            {
                if (ap != killer && gDamageDone[ap][victim] >= 50 && is_user_connected(ap))
                {
                    AwardBonus(ap, asMoney, asHp);
                    static asMsg[128];
                    formatex(asMsg, charsmax(asMsg), "Assist bonus! +$%d +%dHP", asMoney, asHp);
                    ShowBonusMessage(ap, asMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", asMsg);
                    }
                }
                /* Нулираме натрупаните щети към тази жертва */
                gDamageDone[ap][victim] = 0;
            }
        }
    }

    /*
     * 18. Бонус за no-scope снайперско убийство
     * Проверяваме дали оръжието е снайпер (awp, scout, g3sg1, sg550) и дали
     * играчът не е бил в режим zoom (cs_get_user_zoom връща 0 при нормален FOV).
     * Ако условието е изпълнено, прилагаме бонусите nice_noscope_bonus_money и
     * nice_noscope_bonus_hp.
     */
    {
        if (equali(weapon, "awp") || equali(weapon, "scout") || equali(weapon, "g3sg1") || equali(weapon, "sg550"))
        {
            new zoom = cs_get_user_zoom(killer);
            if (zoom == 0)
            {
                new nsMoney = get_pcvar_num(NoScopeBonusMoneyCvar);
                new nsHp = get_pcvar_num(NoScopeBonusHpCvar);
                if (nsMoney != 0 || nsHp != 0)
                {
                    AwardBonus(killer, nsMoney, nsHp);
                    static nsMsg[128];
                    formatex(nsMsg, charsmax(nsMsg), "No-scope ubistvo! +$%d +%dHP", nsMoney, nsHp);
                    ShowBonusMessage(killer, nsMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", nsMsg);
                    }
                }
            }
        }
    }

    /* ===== КРАЙ НА НОВИТЕ БОНУСИ ===== */
    /* Записваме кой е убил всеки играч за системата за revenge */
    gLastKiller[victim] = killer;
}
/* Показване на цветно съобщение в чата. Обвиваме client_print за по-лесно форматиране.
 * В някои версии на AMX Mod X съществува client_print_color, но за съвместимост
 * просто изпращаме обикновени чат съобщения. Цветовете могат да се добавят с
 * нативни кодове (напр. ^3, ^4), ако сървърът ги поддържа. */
stock ColorPrint(const id, const message[], any:...)
{
    static buffer[192];
    /* Първият параметър на vformat е изходният буфер, вторият – дължината му,
     * третият – форматният низ, а аргументите започват от четвъртия параметър (индекс 3). */
    vformat(buffer, charsmax(buffer), message, 3);
    client_print(id, print_chat, "%s", buffer);
}
/* Показване на бонус съобщение на играч или на всички, спазвайки cvar-овете nice_messages и nice_hud_*.
 * id = 0 означава изпращане до всички играчи. */
stock ShowBonusMessage(const id, const message[])
{
    new mode = get_pcvar_num(MessagesCvar);
    if (mode <= 0)
    {
        return;
    }
    /* Пренасочване към всички, ако е включено broadcast и е подаден конкретен id */
    if (id != 0 && get_pcvar_num(BroadcastMessagesCvar))
    {
        ShowBonusMessage(0, message);
        return;
    }
    if (mode == 1)
    {
        /* Режим чат: изпращане на обикновено чат съобщение */
        ColorPrint(id, message);
    }
    else if (mode == 2)
    {
        /* Режим HUD: ползваме зададени или случайни цветове */
        new r = get_pcvar_num(HudColorRCvar);
        new g = get_pcvar_num(HudColorGCvar);
        new b = get_pcvar_num(HudColorBCvar);
        if (r < 0 || r > 255) r = RandomNum;
        if (g < 0 || g > 255) g = RandomNum;
        if (b < 0 || b > 255) b = RandomNum;
        /* Позиция малко по-надолу от основните съобщения за убийства */
        set_hudmessage(r, g, b, -1.0, 0.60, 0, 0.1, 3.0, 0.1, 0.2);
        show_hudmessage(id, "%s", message);
    }
}
/* Даване на бонус пари и здраве на играч, спазвайки cvar-овете за включване на пари/здраве */
stock AwardBonus(const id, const money, const hp)
{
    if (id <= 0)
    {
        return;
    }
    if (money != 0 && get_pcvar_num(MoneyEnableCvar))
    {
        cs_set_user_money(id, cs_get_user_money(id) + money);
    }
    if (hp != 0 && get_pcvar_num(HpEnableCvar))
    {
        set_user_health(id, get_user_health(id) + hp);
    }
}
/* Пускане на звук за убийство чрез emit_sound с регулируема сила на звука.
 * killType: 1 = headshot, 2 = нож, 3 = граната. */
stock PlayKillSound(const killer, const victim, const killType)
{
    new mode = get_pcvar_num(SoundsCvar);
    if (mode <= 0)
    {
        return;
    }
    static sample[64];
    switch (killType)
    {
        case 1: copy(sample, charsmax(sample), soundHS);
        case 2: copy(sample, charsmax(sample), soundKnife);
        case 3: copy(sample, charsmax(sample), soundGren);
        default: return;
    }
    new Float:vol = get_pcvar_float(SoundVolumeCvar);
    if (vol < 0.0 || vol > 1.0) {
        vol = 1.0;
    }
    if (mode == 1)
    {
        emit_sound(killer, CHAN_AUTO, sample, vol, ATTN_NORM, 0, PITCH_NORM);
        emit_sound(victim, CHAN_AUTO, sample, vol, ATTN_NORM, 0, PITCH_NORM);
    }
    else if (mode == 2)
    {
        emit_sound(0, CHAN_AUTO, sample, vol, ATTN_NORM, 0, PITCH_NORM);
    }
}
/* Извиква се в началото на всеки рунд, за да нулира серията убийства и статуса на first blood */
public OnNewRound()
{
    gFirstBloodDone = false;
    /* Увеличаваме брояча на рундовете */
    gRoundNumber++;
    /* Записваме времето за начало на рунда */
    gRoundStartTime = get_gametime();
    for (new i = 1; i <= 32; i++)
    {
        gKillStreak[i] = 0;
        gComboCount[i] = 0;
        gLastKiller[i] = 0;
        gRoundKills[i] = 0;
        gRoundHSKills[i] = 0;
        gLastKillTime[i] = 0.0;
        /* Ресет на новите броячи и състояния */
        gHSStreak[i] = 0;
        gGrenadeKillCount[i] = 0;
        gKnifeKillCount[i] = 0;
        gWeaponStreakCount[i] = 0;
        gLastWeaponID[i] = 0;
        gClipKillCount[i] = 0;
        gLastWeaponClip[i] = 0;
        gClipWeaponId[i] = 0;
        gDamageTaken[i] = false;
        /* Нулираме всички щети, нанесени от играча към останалите (и обратно) за асист бонуса */
        for (new j = 1; j <= 32; j++)
        {
            gDamageDone[i][j] = 0;
            gDamageDone[j][i] = 0;
        }
        /* Не нулираме gTotalKills и gTotalHSKills, за да следим общия брой убийства и headshot-и през цялата карта. */
    }
}
/* Извиква се при край на рунд, за да награди най-добрите убийци и най-много headshot-и */
public OnRoundEnd()
{
    new maxKills = 0;
    new maxHS = 0;
    /* Определяне на максималния брой убийства и headshot-и за рунда */
    for (new i = 1; i <= 32; i++)
    {
        if (gRoundKills[i] > maxKills)
            maxKills = gRoundKills[i];
        if (gRoundHSKills[i] > maxHS)
            maxHS = gRoundHSKills[i];
    }
    /* Награда за най-добър убиец(и) */
    if (maxKills > 0)
    {
        new bonusMoney = get_pcvar_num(TopKillerBonusMoneyCvar);
        new bonusHp = get_pcvar_num(TopKillerBonusHpCvar);
        static msg[128], name[32];
        for (new i = 1; i <= 32; i++)
        {
            if (gRoundKills[i] == maxKills && is_user_connected(i))
            {
                AwardBonus(i, bonusMoney, bonusHp);
                get_user_name(i, name, charsmax(name));
                formatex(msg, charsmax(msg), "%s e top ubiets na runda! +$%d +%dHP", name, bonusMoney, bonusHp);
                ShowBonusMessage(i, msg);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", msg);
                }
            }
        }
    }
    /* Награда за най-много headshot-и */
    if (maxHS > 0)
    {
        new hsMoney = get_pcvar_num(TopHeadshotBonusMoneyCvar);
        new hsHp = get_pcvar_num(TopHeadshotBonusHpCvar);
        static msg2[128], name2[32];
        for (new i = 1; i <= 32; i++)
        {
            if (gRoundHSKills[i] == maxHS && is_user_connected(i))
            {
                AwardBonus(i, hsMoney, hsHp);
                get_user_name(i, name2, charsmax(name2));
                formatex(msg2, charsmax(msg2), "%s ima nai-mnogo headshoti! +$%d +%dHP", name2, hsMoney, hsHp);
                ShowBonusMessage(i, msg2);
                if (get_pcvar_num(LogBonusCvar))
                {
                    log_to_file("killbonuses.log", msg2);
                }
            }
        }
    }

    /* ----- Допълнителни бонуси в края на рунда ----- */
    {
        /* 1. Survival бонус: награждаваме всички живи играчи */
        new survMoney = get_pcvar_num(SurvivalBonusMoneyCvar);
        new survHp = get_pcvar_num(SurvivalBonusHpCvar);
        if (survMoney != 0 || survHp != 0)
        {
            for (new i = 1; i <= 32; i++)
            {
                if (is_user_connected(i) && is_user_alive(i))
                {
                    AwardBonus(i, survMoney, survHp);
                    static svMsg[128], name3[32];
                    get_user_name(i, name3, charsmax(name3));
                    formatex(svMsg, charsmax(svMsg), "%s ocelya kraya na runda! +$%d +%dHP", name3, survMoney, survHp);
                    ShowBonusMessage(i, svMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", svMsg);
                    }
                }
            }
        }
        /* 2. Ace бонус: играч с достатъчно убийства в рунда */
        new aceThresh = get_pcvar_num(AceKillsThresholdCvar);
        if (aceThresh > 0)
        {
            for (new i = 1; i <= 32; i++)
            {
                if (is_user_connected(i) && gRoundKills[i] >= aceThresh)
                {
                    new aMoney = get_pcvar_num(AceBonusMoneyCvar);
                    new aHp = get_pcvar_num(AceBonusHpCvar);
                    if (aMoney != 0 || aHp != 0)
                    {
                        AwardBonus(i, aMoney, aHp);
                        static aMsg[128], name4[32];
                        get_user_name(i, name4, charsmax(name4));
                        formatex(aMsg, charsmax(aMsg), "%s napravi ACE! +$%d +%dHP", name4, aMoney, aHp);
                        ShowBonusMessage(i, aMsg);
                        if (get_pcvar_num(LogBonusCvar))
                        {
                            log_to_file("killbonuses.log", aMsg);
                        }
                    }
                }
            }
        }
        /* 3. Untouchable бонус: жив и без получени щети */
        new utMoney = get_pcvar_num(UntouchableBonusMoneyCvar);
        new utHp = get_pcvar_num(UntouchableBonusHpCvar);
        if (utMoney != 0 || utHp != 0)
        {
            for (new i = 1; i <= 32; i++)
            {
                if (is_user_connected(i) && is_user_alive(i) && !gDamageTaken[i])
                {
                    AwardBonus(i, utMoney, utHp);
                    static utMsg[128], name5[32];
                    get_user_name(i, name5, charsmax(name5));
                    formatex(utMsg, charsmax(utMsg), "%s beshe nedokosnat! +$%d +%dHP", name5, utMoney, utHp);
                    ShowBonusMessage(i, utMsg);
                    if (get_pcvar_num(LogBonusCvar))
                    {
                        log_to_file("killbonuses.log", utMsg);
                    }
                }
            }
        }
    }
}

/*
 * Обработчик на Damage събития, използван за бонус за асистенция.
 * Събитието "Damage" се извиква когато играч получи щета. read_data(2) съдържа
 * количеството щета. Използваме get_user_attacker, за да идентифицираме
 * причинителя и натрупваме нанесената щета в матрицата gDamageDone[attacker][victim].
 */
public OnDamage(victim)
{
    /*
     * Обработчикът на Damage събития изпълнява две функции:
     *  1) Натрупва нанесената щета за нуждите на бонуса за асистенция.
     *  2) Отбелязва, че играчът е получил щета, което се използва за
     *     Untouchable бонуса (ако играчът не получи щета през целия рунд).
     * 
     * Параметърът victim е индексът на играча, получил щетата.
     */
    if (!is_user_connected(victim))
    {
        return;
    }

    /* Отбелязваме, че жертвата е получила щета за Untouchable бонуса */
    if (victim > 0 && victim <= 32)
    {
        gDamageTaken[victim] = true;
    }

    /* Извличаме атакувача на тази щета */
    new attacker = get_user_attacker(victim);
    if (!attacker || attacker == victim)
    {
        return;
    }
    /* Количество щета, нанесена сега */
    new dmg = read_data(2);
    if (dmg <= 0)
    {
        return;
    }
    /* Добавяме към общия урон, но не надвишаваме 100, за да предотвратим прекомерни стойности */
    gDamageDone[attacker][victim] += dmg;
    if (gDamageDone[attacker][victim] > 100)
    {
        gDamageDone[attacker][victim] = 100;
    }
}
/* Бонус за разминиране на бомба */
public bomb_defused(defuser)
{
    if (!is_user_connected(defuser))
        return;
    new m = get_pcvar_num(DefuseBonusMoneyCvar);
    new h = get_pcvar_num(DefuseBonusHpCvar);
    if (m > 0 || h > 0)
    {
        AwardBonus(defuser, m, h);
        static msg[128], name[32];
        get_user_name(defuser, name, charsmax(name));
        formatex(msg, charsmax(msg), "%s razmini bombata! +$%d +%dHP", name, m, h);
        ShowBonusMessage(defuser, msg);
        if (get_pcvar_num(LogBonusCvar))
        {
            log_to_file("killbonuses.log", msg);
        }
    }
}
/* Бонус за поставяне на бомба */
public bomb_planted(planter)
{
    if (!is_user_connected(planter))
        return;
    new m = get_pcvar_num(PlantBonusMoneyCvar);
    new h = get_pcvar_num(PlantBonusHpCvar);
    if (m > 0 || h > 0)
    {
        AwardBonus(planter, m, h);
        static msg[128], name[32];
        get_user_name(planter, name, charsmax(name));
        formatex(msg, charsmax(msg), "%s zalozhi bombata! +$%d +%dHP", name, m, h);
        ShowBonusMessage(planter, msg);
        if (get_pcvar_num(LogBonusCvar))
        {
            log_to_file("killbonuses.log", msg);
        }
    }
}
/* Бонус за спасяване на заложник */
public hostage_rescued(id)
{
    if (!is_user_connected(id))
        return;
    new m = get_pcvar_num(HostageBonusMoneyCvar);
    new h = get_pcvar_num(HostageBonusHpCvar);
    if (m > 0 || h > 0)
    {
        AwardBonus(id, m, h);
        static msg[128], name[32];
        get_user_name(id, name, charsmax(name));
        formatex(msg, charsmax(msg), "%s spasi zalozhnik! +$%d +%dHP", name, m, h);
        ShowBonusMessage(id, msg);
        if (get_pcvar_num(LogBonusCvar))
        {
            log_to_file("killbonuses.log", msg);
        }
    }
}
