#include "common.h"
#include "146C.h"
#include "2842C.h"
#include "2EA3C.h"
#include "30DB0.h"
#include "38C1C.h"
#include "3A1A0.h"
#include "40564.h"
#include "44F14.h"
#include "4A0A8.h"
#include "573B8.h"
#include "58578.h"
#include "5BF94.h"
#include "6E644.h"
#include "pc/src/game/SLUS_010.40/31724.h"
#include "pc/src/game/SLUS_010.40/32154.h"
#include "pc/src/game/BATTLE/INITBTL.PRG/18.h"
#include <abs.h>
#include "insertTPage.h"
#include <libetc.h>
#include <libgpu.h>
#include <libgte.h>
#include <limits.h>
#include <memory.h>
#include <rand.h>
#include "pc/src/psx_types.h"
#ifdef ROOD_PC
#include "pc/src/widescreen.h"
#include "pc/src/classic/classic_hook.h"
/* environment.cpp: a rain drop's packet, left out of the hardware picture
 * where solid room geometry hides the drop (native VRAM draws it) */
void pc_weather_drop_packet(const void* packet, int x, int y, int z);
int pc_charge_skip(int phase); /* pc/src/charge_skip.inc: battle charging skip */
int pc_charge_skip_hold(void);
void pc_charge_skip_name(int now);
#endif

/* The block-scope static of the original function: the Zig reaches this storage through the views
 * (battle_statics.py, STATE.tsv). */
/* Passed as a 32-bit int: needs a guest-range address. */
static char func_80074860__sp20[4] __attribute__((used));

typedef struct {
    u_char targetActor;
    signed char targetLimb;
    char hitThreshold;
    char unk3;
    short hp;
    short mp;
} func_8008631C_t2;

typedef struct {
    short value0;
    short value1;
} limbEffects_t;

typedef struct {
    func_8008631C_t2 unk0;
    short risk;
    short strength;
    short intelligence;
    short agility;
    short maxHp;
    short maxMp;
    int removeStatuses;
    int inflictStatuses;
    u_int hpEffect : 2;
    u_int mpEffect : 2;
    u_int riskEffect : 2;
    u_int strengthEffect : 2;
    u_int intelligenceEffect : 2;
    u_int agilityEffect : 2;
    u_int maxHpEffect : 2;
    u_int maxMpEffect : 2;
    u_int unk1C_16 : 2;
    u_int weaponDpEffect : 2;
    u_int weaponPpEffect : 2;
    u_int armorDpEffect : 2;
    u_int shieldPpEffect : 2;
    u_int unk1C_26 : 2;
    u_int unk1C_28 : 4;
    union {
        limbEffects_t effects;
        u_int hp;
    } limbs[6];
    short weaponDp;
    short weaponPp;
    short armorDp;
    short shieldPp;
    int unk40;
} _hitEntity_t;

typedef struct {
    u_short actionIndex;
    char unk2;
    char unk3;
    _hitEntity_t unk4;
    u_short unk48;
    u_short unk4A;
    _hitEntity_t unk4C[30];
    SVECTOR unk844;
} D_800F19CC_t2;

typedef struct {
    SVECTOR unk0;
    char unk8;
    char unk9;
    char unkA;
    char unkB;
    char unkC;
    char unkD;
    short unkE;
    int unk10;
    int unk14;
} D_800F19CC_t5;

typedef struct {
    u_int unk0;
    u_int unk4;
    D_800F19CC_t2 unk8;
    D_800F19CC_t2 unk854[4];
    int unk2984;
    int unk2988;
    u_char unk298C;
    u_char unk298D;
    char unk298E;
    char unk298F;
    SVECTOR unk2990;
    SVECTOR unk2998;
    char unk29A0;
    char unk29A1;
    short unk29A2;
    char unk29A4;
    char unk29A5;
    char unk29A6;
    char unk29A7;
    SVECTOR unk29A8;
    char unk29B0;
    char unk29B1;
    short unk29B2;
    char unk29B4;
    char unk29B5;
    char unk29B6;
    char unk29B7;
    SVECTOR unk29B8;
    D_800F19CC_t5 unk29C0[23];
    int unk2BE8;
    int unk2BEC;
    int unk2BF0;
    int unk2BF4;
    int unk2BF8;
    int unk2BFC;
    u_short unk2C00;
    char unk2C02;
    char unk2C03;
    char previousChainInput;
    char battleAbilityInputSuccessful;
    char battleAbilityInputAttempted;
    char unk2C07;
    u_short battleAbilityTimer;
    u_short battleAbilityTargetWindow;
    short unk2C0C;
    short unk2C0E;
} D_800F19CC_t;

typedef struct {
    char unk0;
    char unk1;
    short unk2;
    short currentHP;
    short maxHP;
    short currentMP;
    short maxMP;
    short totalStrength;
    short totalIntelligence;
    short totalAgility;
    short limbHp[6];
    int unk20;
    int unk24;
} func_80069EF0_t;

typedef struct {
    _mpdRoomSectionA* unk0;
    func_8006EBF8_t unk4;
} D_800F1910_t;

typedef struct {
    signed char unk0;
    signed char unk1;
    signed char unk2;
    char unk3;
    short unk4;
    short unk6;
} D_800F1BB0_t;

typedef struct {
    int unk0;
    int unk4;
    int unk8;
} func_8006EBF8_t2;

typedef struct {
    short unk0;
    short unk2;
    short unk4;
    short unk6;
    short unk8;
    short unkA;
    char unkC;
    char unkD;
    char unkE;
    char unkF;
} D_800F1DD4_t;

typedef struct {
    short unk0;
    short unk2;
    short unk4;
    short unk6;
    int unk8;
    char unkC[3][4];
    int unk18;
    int unk1C;
    int unk20;
    char unk24[4];
} D_800E8594_t;

typedef struct {
    int unk0[4];
} func_80077DF0_t2;

typedef struct {
    int unk0[17];
    func_80077DF0_t2 unk44;
} func_80077DF0_t3;

typedef struct {
    VECTOR position;
    VECTOR lookAt;
} func_80077DF0_t;

typedef struct {
    char unk0;
    char unk1;
    char unk2;
    char unk3;
    int unk4;
    int unk8;
    int unkC;
    int unk10;
    int unk14;
    int unk18;
    int unk1C;
    int unk20[8];
    int unk40;
} func_80085A34_t;

typedef struct {
    short unk0;
    char unk2;
    char unk3;
    short unk4;
    short unk6;
    char targetActor;
    char unk9;
    char unkA;
    char unkB;
    int unkC;
    short unk10;
    short unk12;
    func_8008631C_t2 unk14;
    int unk18[50];
#ifdef ROOD_PC
    /* func_800CF3F8 copies 0xE8 bytes (func_800CF0E8_t) from this request; the PS1 local is 0xE4 and the last four
     * bytes (unkE0.vz and pad) are whatever its stack held. Here they were dead host stack, which differs
     * between owned and original routes (pc/docs/Oracle.md, known hazards): make the local the size it is read. */
    int unkE4;
#endif
} func_8006C4C4_t;

typedef struct {
    int unk0;
    _mpdRoomSectionA* unk4;
} D_800F1D28_t;

typedef struct {
    short unk0;
    short unk1;
    short unk2;
    short unk3;
} func_8008D2C0_t;

typedef struct {
    int unk0;
    int unk4;
    short unk8;
    char unkA;
    char effect;
    short unkC;
    short unkE;
    int unk10;
    char unk14;
    char unk15;
    char unk16;
    char enemyClass;
} func_8006F630_t1;

typedef struct {
    u_short actionId;
    char unk2;
    char unk3;
} func_8006F630_t2;

typedef struct {
    char bytes[8];
} actorSpawnSettings;

typedef struct {
    u_char type;
    u_char index;
    u_char hidden;
    u_char unk3;
    u_char id;
    u_char slot;
    u_char flagTest;
    u_char statTest;
    u_short flagValue;
    u_short statValue;
    u_char x;
    u_char direction;
    u_char z;
    u_char height;
    actorSpawnSettings settings;
    u_char unk18[2];
    u_short itemId;
    u_short item2Id;
    u_short item3Id;
    u_char itemCount;
    u_char item2Count;
    u_char item3Count;
    u_char facing;
    u_char unk24;
    u_char variant;
    u_char unk26;
    u_char sceneTest;
} mpdEnemySpawn;

typedef struct {
    u_char unk0;
    u_char hidden;
    short unk2;
    short currentHP;
    short maxHP;
    short currentMP;
    short maxMP;
    short strength;
    short intelligence;
    short agility;
    short limbHP[6];
    short unk1E;
    int statuses;
    u_char x;
    u_char direction;
    u_char z;
    u_char height;
} savedEnemyState;

typedef struct {
    int unk0;
    int unk4;
    int model;
    int unkC;
    int blade;
    int unk14;
    int shield;
    int unk1C;
    int effect;
    int effectSize;
    int weaponEffect;
    int weaponEffectSize;
} zudHeader;

typedef struct {
    u_char type;
    u_char unk1;
    u_char unk2;
    u_char unk3;
    u_short flag;
    u_char flagMin;
    u_char flagMax;
    u_char slot;
    u_char unk9;
    u_char x;
    u_char z;
    u_char y;
    u_char direction;
    u_short model;
    u_char unk10[0x18];
} mpdObjectSpawn;

typedef struct {
    u_char actorId : 4;
    char unk0_4 : 4;
    char unk1;
    char unk2;
    char unk3;
    short unk4;
    short unk6;
    int unk8;
    int unkC;
    int unk10;
    int unk14;
} func_8006F630_t3;

typedef struct {
    int count;
    _mpdRoomDoorSection_t* values[32]; /* the PS1's 0x1D08..0x1D28 held a count and 7 words; a room with more matching doors overran it */
} D_800F1D08_t;

typedef struct {
    psx_long mpdOffset;
    int mpdLen;
    psx_long enemiesOffset;
    int enemiesLen;
    psx_long timOffset;
    int timLen;
    int musicId;
} _zndHeader;
PSX_ASSERT_SIZE(_zndHeader, 0x1C);

typedef union {
    char u8[4];
    int s32;
} func_800765B0_t;

typedef struct {
    POLY_FT4 poly[10];
    SPRT sprite[10];
    int unk258[30];
} D_800F1ABC_t;

typedef struct {
    int roomSectionOffset;
    u_short roomSectionLen;
    int clearedSectionOffset;
    u_short clearedSectionLen;
    int scriptSectionOffset;
    u_short scriptSectionLen;
    int doorSectionOffset;
    u_short doorSectionLen;
    int enemySectionOffset;
    int enemySectionLen;
    int lootSectionOffset;
    int lootSectionLen;
} _mpdHeader;

typedef struct {
    int unk0;
    int unk4;
    int unk8;
    int unkC;
    int unk10;
    int unk14;
    int unk18;
    int unk1C;
    int unk20;
} func_800A1108_t;

void func_800C64D0(u_long*, int*);
int _loadMpdRoomSection(int, void* data);
int _dropMisc(vs_battle_loot*, vs_battle_uiMisc*);
int _dropMiscRand(vs_battle_loot*, vs_battle_uiMiscRand*);
void _snapLookAtToPosition(VECTOR*);
void func_8006C350(void);
void func_8006C39C(void);
void func_8006C40C(void);
int func_8006C5AC(int);
void func_80069DEC(int, int);
int _removeActorAtIndex(u_int, int);
void _applyAccessoryStats(vs_battle_uiAccessory*, _accessoryIntermediate*);
void _applyArmorStats(vs_battle_uiArmor* arg0, _armorIntermediate* arg1);
void vs_battle_copyUiEquipmentStats(
    vs_main_inventoryArmor*, vs_battle_uiEquipment* equipment);
void func_8006B214(void);
void func_8006B2D4(void);
void _updateEnemyKills(vs_battle_actor*);
void _drawScreenTransition(void*);
void _updateWeaponKillStreak(int);
void _clampPositionToZoneBounds(VECTOR*, VECTOR*);
int _computeStepAndDisplacement(SVECTOR* arg0, VECTOR*, VECTOR*, int, int);
int _stepTowardTarget(SVECTOR*, int, int);
void func_8006E158(void);
void _computeCameraTransition(VECTOR*);
int _stepCameraTransition(void);
void _setRoomSeen(void);
void func_8006F5CC(void);
void func_8006F89C(void);
void func_8006FA20(void);
void func_8006FD1C(void);
void func_80070278(void);
void func_8007053C(void);
void func_80070CAC(void);
void func_80070F28(int);
void func_8007138C(void);
void func_80072BA8(int);
void func_80072EC4(int, u_short);
void _endBattleCameraTransition(void);
void func_80073718(void);
void func_80073D30(_mpdRoomSectionA*, func_8006EBF8_t*, int);
void func_80073E30(_mpdRoomSectionA*, int);
int func_80074798(func_8006EBF8_t*, char*);
void func_80074B14(int arg0, func_8006EBF8_t_fields* arg1);
void func_80076D50(u_int, int, int, int, int);
void func_80077130(vs_battle_actor*, int, int, int, int);
vs_battle_actor_dat* func_80077240(
    int, int, int, int, int, int, vs_battle_objectData_flags*, int);
void func_800773BC(vs_battle_actor*, int, int, int, int, int);
int func_80077F70(void);
void func_800780A8(SVECTOR*);
int func_80078828(int);
int func_800792E4(int arg0, int arg1, int arg2);
void _computeSphericalOffset(VECTOR*, VECTOR*, _sphericalValues*);
void _setCameraPositionFromAngles(_sphericalValues* arg0);
void _setCameraLookAtFromAngles(_sphericalValues* arg0);
void func_8007B10C(int, int, int, short, short);
void func_8007B1B8(int, int, short, short, short);
void func_8007B29C(int arg0, int arg1, int arg2, short arg3, short arg4, short arg5);
void func_8007B410(void);
void func_8007B63C(void);
void func_8007B470(void);
void func_8007B508(void);
void func_8007B764(void);
void func_8007B7DC(void);
void func_8007BCCC(void);
int func_8007BD8C(int arg0);
void func_8007BF6C(int);
void func_8007BFF8(int);
void func_8007C0AC(int, int);
int func_8007C4E0(_mpdRoomDoorSection_t*, int, int);
int func_8007C5C0(_mpdRoomDoorSection_t*, int, int);
int func_8007C694(int, int, int, int, int);
void vs_battle_initialiseCameraFromSpherical(
    VECTOR* arg0, VECTOR* arg1, int arg2, int arg3);
int _getLocationId(int, int);
void func_8007D360(void);
void func_8007D41C(void);
void _calculateWeaponClassAffinity(vs_battle_actor2*);
int vs_battle_itemIdIsInInventory(int);
short _getDefenseGemBuff(vs_action_t*, vs_battle_actor2*, int);
int _doesAttackHit(
    vs_action_t* arg0, _hitEntity_t* arg1, _hitEntity_t* arg2, int arg3, int arg4);
int func_8007F434(void);
int _hitPrerequisiteCanApplyEffect(int arg0, u_char* arg1);
int _getEnemyClass(u_char*);
void func_80080000(vs_action_t*, _hitEntity_t*, short);
void func_800801E0(vs_action_t*, _hitEntity_t*, short);
void _adjustDpPp(vs_action_t*, vs_battle_actor2*, vs_battle_actor2*, int);
void func_800803A4(vs_action_t*, vs_battle_actor2*, vs_battle_actor2*, int);
void _triggerArmorAffinityChange(vs_action_t*, vs_battle_uiEquipment*, int, int, int);
void _triggerClassChange(vs_action_t* arg0, vs_battle_uiEquipment*, int, int, int);
int _setApplicableStatuses(int, _hitEntity_t*);
int _setInflictedStatuses(int, _hitEntity_t*);
static short _getPhysicalAttackDamage(
    vs_action_t*, _hitEntity_t*, _hitEntity_t*, int, int, int);
short _calculateStatChange(vs_action_t*, _hitEntity_t*, _hitEntity_t*, int, int);
int _getActionCost(u_int, vs_battle_actor2*, int);
void func_80085008(_hitEntity_t*);
void func_80085390(
    vs_action_t* arg0, _hitEntity_t* arg1, _hitEntity_t* arg2, int arg3, int arg4);
void func_80085B10(int, D_800F19CC_t2*, D_800F19CC_t2*, int);
void func_80086754(int, vs_battle_actor2*);
void _applyBattleAbilityEffect(_hitEntity_t*);
void func_80087EF4(vs_battle_actor2*);
int func_800882F4(void);
int func_80088554(void);
void func_80088CA0(void);
void func_80089114(void);
void func_80089CE4(void);
void func_80089D04(void);
void func_8008A6FC(void);
int func_8008ABF0(int arg0);
void func_8008B320(void);
void func_8008B390(int arg0, int* arg1);
int func_8008B4C8(char arg0);
void func_8008C40C(void);
static void _loadZnd(int id);
void _loadMpd(int arg0);
void _loadZndTims(void*);
int func_8008AB80(int);
int func_8008ABB8(int);
void func_8008B2E0(void* arg0, int arg1, int arg2, int arg3);
void func_8008B4BC(int arg0);
void _vsBattleNop2(int arg0);
int _getCollisionMapDimensions(int arg0);
_zoneContextBounds* _getMapBounds(int arg0);
void func_8008B8F8(char (*arg0)[12]);
void func_8008B960(int, int, int);
_mpdRoomSectionA* func_8008BC04(int, int, int);
void func_8008BD74(_mpdRoomSectionA*);
int func_8008BEBC(_mpdRoomSectionA* arg0);
int func_8008BF48(_mpdRoomSectionA*);
void func_8008C070(int arg0, _mpdRoomSectionA* arg1);
int func_8008C1C8(_mpdRoomSectionA* arg0);
int func_8008C2C0(int arg0, int arg1, int arg2, int arg3);
int func_8008C49C(int, int);
void func_8008C538(void);
void func_8008C6B4(int, int);
_mpdRoomSection9* func_8008D438(int, int, int);
_mpdRoomSection13* func_8008D508(int arg0, int arg1, int arg2);
void func_8008D5A0(int);
void func_8008D594(int arg0);
void func_8008D5FC(_mpdRoomSectionA* arg0);
void func_8008D658(_mpdRoomSectionA*);
void func_8008D710(void);
int _getDoorId(int);
void func_800D82A8(int);
short func_8008DC7C(int arg0, int arg1);
void func_8008DEAC(_mpdRoomSection9* arg0, int arg1);
void func_8008E19C(int arg0, int arg1, short arg2, u_int arg3);
_mpdRoomSection13* func_8008E370(int* arg0);
_mpdRoomSectionA* func_8008E3B8(int* arg0);
void func_8008E480(int arg0);
void func_800E4C64(int);
void func_8008E4DC(int);
void _loadMpdLootSection(void* arg0);
void func_8008E6DC(int);
void func_8008E8F8(void);
void func_8008E938(void);
int func_8008EA90(int arg0);
int func_8008F234(void);
void func_8008FA14(D_800F1DD4_t*);
void func_80090A1C(D_800F1DD4_t*);
void func_80091378(void);
int* func_8009195C(int);
void func_80091AC0(int);
int func_8009291C(int);
void func_80092A18(void);
int func_80093764(int);
void func_80093824(int);
void func_80093A14(void);
void func_80093B04(void*);
void func_80093B68(int arg0, int arg1, int arg2, int arg3);
int vs_battle_renderBattleAbilityTimingResult(int);
void func_80093FEC(int, int, int, int);
void func_80093914(int);
void func_80095B7C(int, int);
void func_80096768(int, int, int);
void func_80096FF0(int);
void func_800971D4(void);
void func_8009723C(void*, int);
void func_80098194(int);
void func_800983F8(void*);
void func_80098D6C(void*, void*, D_800F1BB0_t*, int);
void func_80099960(u_short*);
void func_8009D458(void);
void func_8009D6F4(void);
void func_8009D7E8(int, int);
void func_8009DF3C(int, int);
void func_8009E070(int, short*, int);
int func_8009E480(void);
u_int func_8009E4B0(int);
void func_8009EA14(int, SVECTOR*);

void func_800E685C(int, int, int);

extern u_char D_8004EF20;
extern u_char D_8004EF80;
extern u_char D_8004EFA0;
extern u_char D_8004EFB2;
extern u_char D_8004EFE2;
extern u_char D_8004F000;
extern char D_8005FFAF;
extern D_800F18EC_t* D_800F18EC;
extern int D_80068C1C[];
extern char D_800E8184[];
extern char _wepIdCategories[];
extern u_char D_800E8200[];
extern int D_800E8204[];
extern u_short D_800E82F4[];
extern int (*_hitFunctions[])(vs_action_t*, _hitEntity_t*, _hitEntity_t*, int, int);
extern int (*_attackPrerequisiteFunctions[])(vs_action_t*, char*);
extern void (*_actionEffectMediators[])(
    vs_action_t*, _hitEntity_t*, _hitEntity_t*, int, int);
extern short (*_statCalculators[])(vs_action_t*, _hitEntity_t*, _hitEntity_t*, int, int);
extern int D_800E8490;
extern int D_800E8494;
extern int D_800E8498;
extern short D_800E849C[];
extern char D_800E84AC[][4];
extern MATRIX D_800E856C;
extern D_800E8594_t D_800E8594;
extern char D_800E85A0[];
extern RECT D_800E85BC;
extern RECT D_800E85C4;
extern int D_800F1858;
extern int D_800F185C;
extern int D_800F1860;
extern int D_800F1864;
extern int D_800F1868;
extern void* D_800F1870;
extern int _firstPersonViewEnabled;
extern void* D_800F18E4;
extern u_int _cameraMode;
extern char D_800F18F8;
extern int D_800F18FC;
extern int D_800F1908;
extern int D_800F190C;
D_800F1910_t D_800F1910;
extern vs_battle_actor* D_800F192C;
extern int D_800F1968;
extern u_int D_800F196C;
extern int D_800F19A0;
extern char D_800F19A8[];
extern int D_800F19C8;
extern D_800F19CC_t* D_800F19CC;
extern u_int D_800F1A00;
extern u_int D_800F1A04;
extern u_int _lastValue;
extern int D_800F1A0C;
extern short _armorDpAdjustmentAmounts[];
extern int D_800F1A20;
extern short D_800F1A28[];
extern short D_800F1A2C;
extern int D_800F1A30[];
extern int D_800F1A40;
extern u_int D_800F1A44;
extern int D_800F1A50[];
extern D_800F1A68_t D_800F1A68;
extern P_CODE D_800F1A78;
extern char D_800F1A9C[];
extern D_800F1ABC_t* D_800F1ABC;
extern int D_800F1B98;
extern int D_800F1B9C;
extern u_short D_800F1BA4;
extern D_800F1BB0_t D_800F1BB0;
extern short D_800F1BB6;
extern void* D_800F1BB8;
extern char D_800F1BBC;
extern short vs_battle_doorEntered;
/* Defined here: the room and zone records hold pointers among their words, so they cannot be imports (LP64). */
_mpdRoomSection vs_battle_roomData;
vs_view_t vs_view;
_zoneContext_t _zoneContext;
extern u_short D_800F1CCA;
extern void* D_800F1CC0;
extern char D_800F1CD6;
extern u_short D_800F1CDC;
D_800F1D08_t D_800F1D08;
D_800F1D28_t D_800F1D28[8];
extern short D_800F1D6A;
extern u_short D_800F1D6C;
extern int D_800F1D78[5];
extern char D_800F1DC7;
extern short D_800F1D68;
extern signed char D_800F1D6E;
extern char D_800F1D6F;
extern u_char D_800F1D70[];
extern short D_800F1D98[];
extern vs_main_CdQueueSlot* D_800F1DAC;
extern vs_main_CdQueueSlot* D_800F1DB0;
extern short D_800F1DB4;
extern short D_800F1DB6;
extern short D_800F1DB8;
extern short D_800F1DBA;
extern short D_800F1DBC;
extern short D_800F1DBE;
extern short D_800F1DC0;
extern short D_800F1DC2;
extern short D_800F1DC4;
extern char D_800F1DC6;
extern char D_800F1DC8;
extern u_char D_800F1DC9;
extern char D_800F1DCA;
extern char D_800F1DCB;
extern vs_battle_backgroundLayout* D_800F1DCC;
extern u_long* D_800F1DD0;
extern D_800F1DD4_t* D_800F1DD4;
extern short D_800F5160;
extern short D_8005FFB0;

void func_80069C6C(int arg0);

void func_80069D14(void);

void func_80069D78(void);

void func_80069DBC(void);

void func_80069DEC(int mapId, int zndId);

void* func_80069E80(int arg0);

void* func_80069EF0(int arg0);

void func_80069FC4(int arg0, int arg1);

int _insertActor(vs_battle_actor* actor);

int _removeActor(vs_battle_actor* actor);

int _removeActorAtIndex(u_int index, int arg1);

void vs_battle_applyWeaponStats( vs_battle_uiWeapon* target, vs_battle_weaponIntermediate* source);

void vs_battle_applyShieldStats( vs_battle_uiShield* target, vs_battle_shieldIntermediate* source);

void _applyAccessoryStats(vs_battle_uiAccessory* target, _accessoryIntermediate* source);

void _applyArmorStats(vs_battle_uiArmor* target, _armorIntermediate* source);

void vs_battle_copyInventoryBladeStats( vs_battle_uiEquipment* target, vs_main_inventoryBlade* source);

void vs_battle_copyInventoryGripStats( vs_battle_uiEquipment* target, vs_main_inventoryGrip* source);

void vs_battle_copyInventoryArmorStats( vs_battle_uiEquipment* target, vs_main_inventoryArmor* source);

void vs_battle_copyInventoryGemStats( vs_battle_uiEquipment* target, vs_main_inventoryGem* source);

void vs_battle_applyWeapon(vs_battle_uiWeapon* target, vs_main_inventoryWeapon* source);

void vs_battle_applyShield(vs_battle_uiShield* target, vs_main_inventoryShield* source);

void vs_battle_applyArmor(vs_battle_uiArmor* target, vs_main_inventoryArmor* source);

void vs_battle_applyAccessory( vs_battle_uiAccessory* target, vs_main_inventoryArmor* source);

void vs_battle_nop0(vs_battle_actor2* actor __attribute__((unused)));

void func_8006B214(void);

void func_8006B270(void);

void func_8006B2D4(void);

void vs_battle_copyUiBladeStats( vs_main_inventoryBlade* target, vs_battle_uiEquipment* source);

void vs_battle_copyUiGripStats( vs_main_inventoryGrip* target, vs_battle_uiEquipment* source);

void vs_battle_copyUiGemStats(vs_main_inventoryGem* target, vs_battle_uiEquipment* source);

void vs_battle_copyUiEquipmentStats( vs_main_inventoryArmor* target, vs_battle_uiEquipment* source);

int _dropWeaponRand(vs_battle_lootedWeapon* looted, vs_battle_uiWeapon* base);

int _dropShieldRand(vs_battle_lootedShield* looted, vs_battle_uiShield* base);

int _dropAccessoryRand(vs_battle_lootedAccessory* looted, vs_battle_uiAccessory* base);

int _dropArmorRand(vs_battle_lootedArmor* looted, vs_battle_uiArmor* base);

int _dropMisc(vs_battle_loot* looted, vs_battle_uiMisc* base);

int _dropMiscRand(vs_battle_loot* looted, vs_battle_uiMiscRand* base);

void _dropLoot(vs_battle_actor* enemy);

void _updateEnemyKills(vs_battle_actor* enemy);

void _updateWeaponKillStreak(int arg0 __attribute__((unused)));

void _enemyDefeated(int arg0, int actorId, int arg2);

void func_8006C250(void);

void func_8006C2A0(void);

void func_8006C2FC(void);

void func_8006C350(void);

void func_8006C39C(void);

void func_8006C40C(void);

void func_8006C480(int arg0, int arg1);

void func_8006C4A4(int arg0, int arg1);

void func_8006C4C4(int arg0, _hitEntity_t* arg1, int targetLimb);

int func_8006C5AC(int arg0);

int func_8006C84C(int arg0);

void func_8006CA20(int arg0, func_8006CE70_t* arg1);

/* PC only: the decomp's exact-matching C for func_8006CB04 (rood-reverse
 * .work/ultracode/r12-e/cb9.c, score 0). The decomp rejected it upstream only
 * for its conditional dead store, which is harmless here. */
extern u_char D_800E8194[];
void func_8006CB04(int arg0, func_8006CE70_t* arg1);

void func_8006CD60(u_int* arg0, int arg1, int arg2);

void func_8006CDB8(int arg0);

void func_8006CDD8(func_8006CE70_t* arg0);

void func_8006CE50(void);

void func_8006CE70(func_8006CE70_t* arg0);

void func_8006D028(int arg0);

void func_8006D064(void);

void _drawScreenTransition(void* ot);

int _addMinDelta(int base, int a, int b);

int _add_min(int base, int a, int b);

void _clampPositionToZoneBounds(VECTOR* inPos, VECTOR* outPos);

int _computeStepAndDisplacement(SVECTOR* targetPos, VECTOR* outStep, VECTOR* outDisplacement, int clampToZone, int maxSpeed);

int _stepTowardTarget(SVECTOR* targetPos, int transformFlag, int maxSpeed);

void _snapLookAtToPosition(VECTOR* arg0);

#define CAMERA_INPUT_LOCKED()                                                           \
    ((D_800F196C == 3) || ((D_800F196C == 2) && ((_cameraMode == 4) || (_cameraMode == 11))))

void func_8006E158(void);

void func_8006E640(int arg0);

int func_8006E7F0(void);

int func_8006EBF8(void);

/* First-person up/down, inverted by the PC port's setting qol_fp_invert_y
 * (project_settings.cpp); the original's directions in the PS1 build. */
#ifdef ROOD_PC
extern int pc_qol_fp_invert_y;
#define FP_INVERT_Y pc_qol_fp_invert_y
#else
#define FP_INVERT_Y 0
#endif

void func_8006EC7C(void);

void func_8006EF10(void);

void _computeCameraTransition(VECTOR* targetPosition);

int _stepCameraTransition(void);

void func_8006F450(func_800CF0E8_t* arg0);

void func_8006F4B0(func_8006EBF8_t3* arg0);

void _setRoomSeen(void);

void func_8006F5CC(void);

void func_8006F5FC(void);

void func_8006F630(func_8006F630_t1* arg0, func_8006F630_t2* arg1, func_8006F630_t3* arg2);

int _isArtOrAbilityUnlocked(void);

void func_8006F848(void);

void func_8006F89C(void);

void func_8006FA20(void);

void func_8006FB48(void);

void func_8006FBCC(int arg0);

void func_8006FCBC(void);

void func_8006FD0C(void);

void func_800DEEA4(D_800F19CC_t2*);
void func_80093F24(u_int);

void func_8006FD1C(void);

void func_80070278(void);

void func_800704B0(void);

void func_800704D8(void);

typedef struct {
    char reserved[0x29C0];
    struct {
        SVECTOR position;
        char kind, actor;
        signed char limb;
        char reservedB[13];
    } targets[23];
} actionTargetContextView;
extern unsigned char D_800E81C4[];
void func_800C0700(void*);
void func_800C1664(int, void*, int);
int func_8008631C(int, int, int, int, void*);

void func_8007053C(void);

void func_8007087C(D_800F19CC_t* arg0);

void func_800708EC(void);

void func_80070B04(void);

/* Environment targets overlay the actor-effect records with coordinates. */
typedef struct {
    short x, y, z, radius;
    char reserved8[56];
    int kind;
} environmentTarget;
typedef struct {
    unsigned short action;
    char reserved2[72];
    unsigned short count;
    environmentTarget targets[30];
} environmentTargetList;
_mpdRoomSection9* func_8008E400(int*);
int func_8008D2C0(func_8008D2C0_t*);
void func_80070CAC(void);

void func_80070F28(int arg0);

typedef struct {
    u_short type;
    short reserved2;
    union {
        struct {
            u_char actor;
            u_char reserved;
            signed char part;
            char reserved3;
        } actor;
        SVECTOR position;
    } value;
} actionEffectTarget;

typedef struct {
    u_short effect;
    signed char count;
    u_char otherCount;
    actionEffectTarget source;
    actionEffectTarget targets[16];
    char others[16];
    SVECTOR position;
} actionEffectRequest;

void func_8007138C(void);

void func_800719DC(int arg0 __attribute__((unused)));

extern unsigned char D_800E81B4[], D_800E81D4[];
void func_800A190C(int, int, void*, int);
void func_800719FC(int arg0 __attribute__((unused)));

/* 573B8.c stores the target list's guest address (arg3) in an int field. */
void func_800C05EC(void*, void*, int, void*);

void func_80071F68(int arg0);

void func_80072734(int arg0);

typedef struct {
    u_char id;
    u_char unk1;
    u_char flags;
} actionHeaderView;

extern unsigned char D_800E8194[];

void func_80072BA8(int action);

void func_80072EC4(int arg0, u_short arg1);

void _initBattleCameraTransition(void);

void _endBattleCameraTransition(void);

void func_80073484(void);

void func_800734C0(void);

void func_8007350C(void);

void func_8007352C(void);

void func_80073554(void);

void func_8007357C(int arg0 __attribute__((unused)), int arg1 __attribute__((unused)));

void func_800735CC(D_800F18EC_t* arg0);

void func_800735F8(D_800F18EC_t* arg0);

void func_80073718(void);

void func_80073870(void);

void func_80073898(void);

void func_800738E4(void);

void func_80073AA4(void);

void func_80073ACC(void);

int func_80073AFC(_mpdRoomSectionA* arg0);

void func_80073D30(_mpdRoomSectionA* arg0, func_8006EBF8_t* arg1, int targetActor);

void func_80073E30(_mpdRoomSectionA* arg0, int arg1);

void func_80073F7C(_mpdRoomSectionA* arg0, func_8006EBF8_t3* arg1, int arg2);

void func_80074050(_mpdRoomSectionA* arg0, int arg1);

int func_80074120(void);

int func_8007418C(void);

void func_800741D4(void);

int func_8007424C(void);

int func_80074294(void);

void func_800742A4(void);

void func_80074314(void);

int func_80074374(void);

void func_800743E0();

int func_800744B8(void);

void func_80074580(void);

void _checkFirstPersonViewExit(void);

void func_80074744(void);

int func_80074798(func_8006EBF8_t* arg0, char* arg1);

int func_80074860(int arg0);

_mpdRoomSectionA* func_800748B8(int arg0);

_mpdRoomSection13* func_80074950(int arg0);

int func_80074A20(int arg0);

void func_80074B14(int arg0, func_8006EBF8_t_fields* arg1);

int func_80074BAC(int, u_char*);
/* PC only: the decomp's closest non-matching C for func_80074BAC
 * (rood-reverse .work/ultracode/r7-near-b/74bac/p40.full.c, score 40: a
 * register-allocation swap, same behaviour). */
D_800F1D08_t* func_8008BAC8(int, int, int);
int func_80074BAC(int actorId, u_char* cell);

int func_800751B8(int arg0, func_8006EBF8_t3* arg1);

void func_800753F8(vs_battle_actor* arg0, SVECTOR* arg1);

int func_80075554(void);
#include "pc/src/actor_commands.inc"

void func_800760CC(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5);

int func_8007629C(u_long* otag);

void func_8007647C(int arg0, int arg1);

vs_battle_actor* func_800765B0( int index, int actorId, vs_battle_objectData_flags* arg2, int material, int arg4);

void func_80076784( int arg0, vs_battle_actor2* actor, vs_battle_charInitData* init, int arg3);

void func_80076D50(u_int id, int arg1, int arg2, int arg3, int arg4);

void func_80076F24( int id, vs_battle_charInitData* arg1, int arg2, int arg3, int arg4, int arg5);

int func_80077078(vs_battle_actor* arg0, int index, int wepId, vs_battle_objectData_flags* arg3, int arg4);

void func_800770FC(vs_battle_actor* arg0 __attribute__((unused)), int arg1);

void func_80077130( vs_battle_actor* actor, int actorId, int wepId, int isShield, int material);

void func_800771E0(char* arg0, int arg1, int arg2, int arg3);

vs_battle_actor_dat* func_80077240(int arg0, int arg1, int bladeWepId, int bladeMaterial, int shieldWepId, int shieldMaterial, vs_battle_objectData_flags* arg6, int arg7);

void func_800773BC( vs_battle_actor* arg0, int arg1, int arg2, int arg3, int arg4, int arg5);

vs_battle_actor* func_800774FC(int arg0, int arg1, int bladeWepId, int bladeMaterial, int shieldWepId, int shieldMaterial, vs_battle_objectData_flags* arg6, int arg7);

extern u_char D_8004FE88[];
extern vs_battle_charInitData* D_800F188C;

vs_battle_actor* func_800775C0( int id, mpdEnemySpawn* spawn, vs_battle_charInitData* init, int flags);

int _isLookAtAtDestination(void);

void func_80077F14(int arg0, int arg1, SVECTOR* arg2);

int func_80077F70(void);

void func_800780A8(SVECTOR* arg0);

void func_8007820C(int arg0);

void func_80078248(void);

void func_800782E4(void);

void func_80078364(void);

void _handleCombatCameraZoom(void);

void func_80078748(void);

void func_800787F0(void);

int func_80078828(int arg0);

void func_80078AB4(void);

void func_80079030(void);

void func_80079050(void);

void func_800790BC(void);

int func_800792E4(int arg0, int arg1, int arg2);

void func_800793C0(void);
extern int D_800F19D8;
extern int D_800F19EC;

void func_800793C0(void);

void func_800797BC(void);

void func_8007980C(void);

void func_8007983C(void);

void _finishLoadZnd(int id);
void func_80089DC0(int arg0);
int func_8008C8A8(void);
int func_80088B6C(void);
void func_80088B8C(void);
void func_8008EC48(VECTOR* arg0);
void func_8008AC78(void);
void func_8008B28C(void);
void func_8007D734(void*);
void func_8007DF98(void);
void func_8008A3A0(void);
void func_80089098(void);

void vs_battle_exec(void);
void func_800FA35C(int);

void vs_battle_exec(void);

void func_8007A824(int* arg0);

int vs_battle_syncCameraAnglesFromPosition(_sphericalCamera* arg0);

void _computeSphericalOffset( VECTOR* outPosition, VECTOR* basePosition, _sphericalValues* angles);

void _setCameraPositionFromAngles(_sphericalValues* spherical);

void _setCameraLookAtFromAngles(_sphericalValues* spherical);

void vs_battle_getCameraPosition(VECTOR* outPosition);

void vs_battle_setCameraPosition(VECTOR* inPosition);

void vs_battle_getCameraLookAt(VECTOR* outLookAt);

void vs_battle_setCameraLookAt(VECTOR* inLookAt);

void vs_battle_setCameraRoll(int arg0);

int vs_battle_getCameraRoll(void);

extern MATRIX D_8005E218;

void func_8007ACB0(void);

void vs_battle_lookAt(VECTOR* from, VECTOR* to, MATRIX* mat);

void func_8007B0FC(void);

void func_8007B104(void);

void func_8007B10C(int arg0, int arg1, int arg2, short arg3, short arg4);

void func_8007B1B8(int arg0, int arg1, short arg2, short arg3, short arg4);

void func_8007B29C(int arg0, int arg1, int arg2, short arg3, short arg4, short arg5);

void func_8007B344(int arg0, int arg1, short arg2, short arg3, short arg4);

void func_8007B378(int arg0, u_short* arg1, int arg2, int arg3) __attribute__((unused));
void func_8007B378(int arg0, u_short* arg1, int arg2, int arg3);

void func_8007B3D0(int arg0, int arg1, u_short* arg2, int arg3) __attribute__((unused));
void func_8007B3D0(int arg0, int arg1, u_short* arg2, int arg3);

void func_8007B410(void);

void func_8007B470(void);

void func_8007B4C4(void);

void func_8007B508(void);

void func_8007B63C(void);

void func_8007B764(void);

void func_8007B7DC();

void func_8007B834(void);

void func_8007B884(void);

void func_8007B908(void);

void func_8007B938(void);

void func_8007B9A0(void);

void func_8007B9CC(void);

int func_8007B9FC(void);

void func_8007BA98(int id0, int count0, int id1, int count1);

void func_8007BBB8(int arg0, int arg1);

void func_8007BBD8(int arg0, int arg1, int arg2);

void func_8007BCCC(void);

void func_8007BD3C(int arg0);

int func_8007BD8C(int arg0);

int func_8007BDD8(int arg0);

int func_8007BE10(int arg0);

void func_8007BE20(int arg0, int arg1);

void func_8007BEC4(int arg0);

int func_8007BEE4(void);

void func_8007BF04(void);

int func_8007BF0C(void);

void func_8007BF2C(void);

void func_8007BF4C(void);

void func_8007BF6C(int arg0);

void func_8007BFC0(void);

void func_8007BFF8(int arg0);

void func_8007C050(void);

void func_8007C0AC(int arg0, int arg1);

int func_8007C218(int arg0);

void func_8007C28C(int arg0);

void func_8007C31C(void);

void func_8007C348(int arg0, int arg1);

int func_8007C36C(int arg0);

int func_8007C398(void);

void func_8007C404(void);

void func_8007C424(void);

void func_8007C444(int arg0, int arg1, int arg2);

void func_8007C460(int arg0);

void func_8007C46C(int effect, int speed, int angle);

void func_8007C4AC(int effect, int arg1, int arg2);

void func_8007C4D4(void);

int func_8007C4E0(_mpdRoomDoorSection_t* arg0, int effect, int speed);

void func_8007C580(_mpdRoomDoorSection_t* arg0, int arg1, int arg2);

int func_8007C5C0(_mpdRoomDoorSection_t* arg0, int effect, int speed);

void func_8007C654(_mpdRoomDoorSection_t* arg0, int arg1, int arg2);

int func_8007C694(int arg0, int arg1, int arg2, int effect, int speed);

int _getLocationId(int zoneId, int mapId);

int vs_battle_getCurrentRoomId(void);

void func_8007C8A4(int arg0, int arg1);

int func_8007C8F8(int arg0);

int func_8007C928(u_int arg0, int arg1, vs_battle_objectData_flags* arg2);

void func_8007CA20(int actorId, int bladeWepId, int shieldWepId);

void func_8007CAA4(int arg0);

void func_8007CB84(int index, int wepId);

void func_8007CBBC(int arg0);

void func_8007CBDC(int index, int wepId, int arg2);

void vs_battle_loadEtm(int index, int wepId, int arg2);

void func_8007CC4C(int arg0);

void func_8007CC6C(int arg0);

int func_8007CCAC(void);

void vs_battle_setNearClip(int arg0);

void vs_battle_setProjectionDistance(int projectionDistance);

void vs_battle_setFarClip(int farClip, int arg1);

void vs_battle_initialiseCameraFromSpherical( VECTOR* outputPos, VECTOR* outputLookAt, int facing, int mode);

void func_8007CE74(int arg0);

void func_8007CEA0(int arg0);

void func_8007CEC0(void);

int func_8007CF18(int arg0);

vs_battle_actor* func_8007CF64(int actorId);

int func_8007CF80(int arg0);

char func_8007CFCC(int arg0);

void func_8007CFF8(int arg0, SVECTOR* arg1);

int func_8007D03C(int arg0);

int func_8007D08C(int arg0, int arg1);

int func_8007D15C(int arg0);

void func_8007D1A8(int arg0, int arg1);

void func_8007D260(int arg0);

int vs_battle_isActionUnlocked(u_int arg0);

void vs_battle_setActionUnlocked(u_int arg0);

void func_8007D340(int arg0);

void func_8007D360(void);

void func_8007D41C(void);

void func_8007D734(void* arg0);

void func_8007DD50(int arg0);

void func_8007DDAC(int arg0);

void func_8007DDB8(D_800F1A68_t* arg0);

void func_8007DDD4(P_CODE* arg0);

void func_8007DDF8(D_800F1A68_t* arg0);

void func_8007DE2C(int arg0);

void func_8007DE44(u_int arg0);

void func_8007DE5C(int arg0);

void func_8007DE88(int* arg0);

void func_8007DEA8(P_CODE* arg0);

void func_8007DECC(D_800F1A68_t* arg0);

void func_8007DF40(void);

void func_8007DF98(void);

int func_8007DFF0(u_int arg0, u_int arg1, int arg2);

int func_8007E0A8(u_int arg0, u_int arg1, int arg2);

int func_8007E180(int arg0);

int func_8007E1C0(int arg0);

void _calculateArmorClassAffinity(vs_battle_actor2* arg0, int arg1);

void _calculateShieldClassAffinity(vs_battle_actor2* arg0);

void _calculateWeaponClassAffinity(vs_battle_actor2* arg0);

extern u_int _itemCategorySizes[];

int vs_battle_itemIdIsInInventory(int id);

short _getAttackGemBuff(vs_action_t* action, vs_battle_actor2* actor);

short _getDefenseGemBuff(vs_action_t* action, vs_battle_actor2* actor, int hitNumber);

int _doesAttackHit(vs_action_t* action, _hitEntity_t* source, _hitEntity_t* target, int hitNumber, int addVariance);

int func_8007F434(void);

int _hitPrerequisiteCanApplyEffect(int debuff, u_char* arg1);

int _getEnemyClass(u_char* arg0);

int _canPerformAttack(vs_action_t* action, char* arg1, int hitNumber);

short func_8007FE5C( vs_action_t* action, short arg1, vs_battle_actor2* arg2, vs_battle_actor2* arg3);

void func_80080000(vs_action_t* action, _hitEntity_t* entity, short baseValue);

void func_800801E0(vs_action_t* action, _hitEntity_t* entity, short amount);

void _adjustDpPp( vs_action_t* action, vs_battle_actor2* source, vs_battle_actor2* target, int amount);

void func_800803A4( vs_action_t* action, vs_battle_actor2* arg1, vs_battle_actor2* arg2, int arg3);

void _triggerArmorAffinityChange(vs_action_t* action, vs_battle_uiEquipment* equipment, int affinity, int arg3, int actorId);

void _triggerWeaponAffinityChange(vs_action_t* action, vs_battle_uiEquipment* equipment, int affinity, int arg3, int suppressNotification);

void _triggerClassChange(vs_action_t* action __attribute__((unused)), vs_battle_uiEquipment* equipment, int class, int arg3, int actorId);

void func_80080C9C( vs_action_t* arg0, vs_battle_actor2* arg1, int arg2, int arg3, int arg4);

void func_80080F78(vs_action_t* action, vs_battle_actor2* arg1, int arg2, int arg3);

int _setApplicableStatuses(int arg0, _hitEntity_t* entity);

int _setInflictedStatuses(int arg0, _hitEntity_t* entity);

typedef struct {
    /* 0x00 */ u_char type;
    /* 0x01 */ u_char sourceAffinity;
    /* 0x02 */ u_char sourceClass;
    /* 0x03 */ u_char unk3;
    /* 0x04 */ short typeValue;
    /* 0x06 */ short weaponAffinity;
    /* 0x08 */ short weaponClass;
    /* 0x0A */ short value;
    /* 0x0C */ short weaponDamage;
    /* 0x0E */ short unkE;
    /* 0x10 */ u_char unk10;
    /* 0x11 */ u_char targetAffinity;
    /* 0x12 */ u_char targetClass;
    /* 0x13 */ u_char unk13;
    /* 0x14 */ short unk14;
    /* 0x16 */ short tempTargetAffinity;
    /* 0x18 */ short unk18;
    /* 0x1A */ short mediatingStat;
    /* 0x1C */ short shieldStat;
    /* 0x1E */ short armorStat;
    /* 0x20 */ short statFactor;
    /* 0x22 */ short shieldStatFactor;
    /* 0x24 */ short armorStatFactor;
} _hitIntermediate;

static short _getPhysicalAttackDamage(vs_action_t* action, _hitEntity_t* source,
    _hitEntity_t* target, int nHit, int withRandMod, int applyStatuses)
{
    _hitIntermediate sp18;
    int attack;
    short maxAffinity;
    short value;
    int i;
    int affinity;
    int defense;

    vs_battle_actor2* sourceActor =
        vs_battle_actors[source->unk0.targetActor]->unk3C;
    vs_battle_actor2* targetActor =
        vs_battle_actors[target->unk0.targetActor]->unk3C;
    int limb = target->unk0.targetLimb;

    sp18.sourceClass = sourceActor->enemyClass;
    sp18.targetClass = targetActor->enemyClass;

    if (action->hitParams[nHit].type == 0) {
        sp18.type = sourceActor->weapon.damageType;
        if (!sp18.type) {
            sp18.type = 1;
        }
    } else {
        sp18.type = action->hitParams[nHit].type;
    }

    if (action->hitParams[nHit].affinity == 0) {
        if (!(vs_battle_actors[sourceActor->unk957]->weaponDrawn & 1)
            || sourceActor->weapon.blade.id == 0) {
            affinity = 0;
        } else {
            affinity = 0;
            maxAffinity = 0;
            for (i = 0; i < 7; ++i) {
                if (maxAffinity
                    < sourceActor->weapon.classAffinityCurrent.affinity[0][i]) {
                    maxAffinity = sourceActor->weapon.classAffinityCurrent.affinity[0][i];
                    affinity = i;
                }
            }
        }
        sp18.sourceAffinity = affinity;
    } else {
        sp18.sourceAffinity = action->hitParams[nHit].affinity - 1;
    }

    affinity = 0;
    maxAffinity = 0;

    for (i = 0; i < 7; ++i) {

        sp18.tempTargetAffinity =
            targetActor->limbs[limb].affinities[i]
            + targetActor->limbs[limb].armor.classAffinityCurrent.affinity[0][i];

        if (vs_battle_actors[targetActor->unk957]->weaponDrawn & 1) {
            sp18.tempTargetAffinity +=
                targetActor->shield.classAffinityCurrent.affinity[0][i];
        }

        if (maxAffinity < sp18.tempTargetAffinity) {
            maxAffinity = sp18.tempTargetAffinity;
            affinity = i;
        }
    }

    sp18.targetAffinity = affinity;
    sp18.value = sourceActor->strength;

    if (vs_battle_actors[sourceActor->unk957]->weaponDrawn & 1) {

        sp18.value = sp18.value + sourceActor->weapon.currentStr;
        sp18.typeValue = sourceActor->weapon.damageTypeValue;
        sp18.weaponAffinity =
            sourceActor->weapon.classAffinityCurrent.affinity[0][sp18.sourceAffinity];
        sp18.weaponClass =
            sourceActor->weapon.classAffinityCurrent.class[0][targetActor->enemyClass];
        sp18.weaponDamage = sp18.weaponClass + (sp18.typeValue + sp18.weaponAffinity);

        if (sourceActor->weapon.maxDp != 0) {
            sp18.weaponDamage =
                sp18.weaponDamage
                - (((sourceActor->weapon.maxDp - sourceActor->weapon.currentDp) * 100)
                    / sourceActor->weapon.maxDp);
        }

        if (sourceActor->weapon.maxPp != 0) {
            sp18.weaponDamage +=
                (sourceActor->weapon.currentPp
                    * *((sourceActor->weapon.blade.category) + D_800E82F4))
                / sourceActor->weapon.maxPp;
        }

    } else {
        sp18.weaponClass = 0;
        sp18.weaponAffinity = 0;
        sp18.typeValue = 0;
        sp18.weaponDamage = 0;
    }

    sp18.value += sourceActor->accessory.currentStr;
    sp18.weaponDamage += sourceActor->accessory.types[sp18.type]
                       + sourceActor->accessory.classes[sp18.targetClass]
                       + sourceActor->accessory.affinities[sp18.sourceAffinity];
    sp18.weaponDamage = sp18.weaponDamage / 4 + 100;
    sp18.mediatingStat = targetActor->strength;
    sp18.armorStat = targetActor->limbs[limb].armor.currentStr;
    sp18.shieldStat = 0;
    sp18.armorStatFactor = 100;
    sp18.shieldStatFactor = 100;
    sp18.statFactor = 100;
    sp18.statFactor = targetActor->limbs[limb].types[sp18.type]
                    + targetActor->limbs[limb].affinities[sp18.sourceAffinity] + 100;
    sp18.armorStatFactor =
        targetActor->limbs[limb].armor.classAffinityCurrent.class[0][sp18.sourceClass]
        + (targetActor->limbs[limb].armor.types[sp18.type]
            + targetActor->limbs[limb]
                .armor.classAffinityCurrent.affinity[0][sp18.sourceAffinity])
        + 100;

    if (targetActor->limbs[limb].armor.maxDp != 0) {
        sp18.armorStatFactor -= (((targetActor->limbs[limb].armor.maxDp
                                      - targetActor->limbs[limb].armor.currentDp)
                                     * 100)
                                    / targetActor->limbs[limb].armor.maxDp)
                              / 4;
    }

    if (vs_battle_actors[targetActor->unk957]->weaponDrawn & 1) {

        sp18.shieldStat += targetActor->shield.currentStr;
        sp18.shieldStatFactor =
            sp18.shieldStatFactor
            + ((targetActor->shield.types[sp18.type]
                   + targetActor->shield.classAffinityCurrent
                       .affinity[0][sp18.sourceAffinity])
                + targetActor->shield.classAffinityCurrent.class[0][sp18.sourceClass]);

        if (targetActor->shield.maxDp != 0) {
            sp18.shieldStatFactor -=
                (((targetActor->shield.maxDp - targetActor->shield.currentDp) * 100)
                    / targetActor->shield.maxDp)
                / 4;
        }
        if (targetActor->shield.maxPp != 0) {
            sp18.shieldStatFactor +=
                (targetActor->shield.currentPp * 100) / targetActor->shield.maxPp / 4;
        }
    }

    sp18.mediatingStat = sp18.mediatingStat + targetActor->accessory.currentStr;
    sp18.statFactor = sp18.statFactor
                    + ((targetActor->accessory.types[sp18.type]
                           + targetActor->accessory.classes[sp18.sourceClass])
                        + targetActor->accessory.affinities[sp18.sourceAffinity]);
    attack = (sp18.value * sp18.weaponDamage) / 100;
    attack = (attack * ((action->hitParams[nHit].statFactor * 10) + 100)) / 100;
    defense = (sp18.mediatingStat - 20) * sp18.statFactor;
    defense += sp18.shieldStat * sp18.shieldStatFactor;
    defense += sp18.armorStat * sp18.armorStatFactor;
    defense /= (targetActor->risk / 2) + 100;
    value = func_8007FE5C(action, attack - defense, sourceActor, targetActor);

    if (value < 0) {
        value = 0;
    }

    if (withRandMod != 0) {
        value += 1 + vs_main_getRand(5);
    }

    if ((applyStatuses != 0) && (sourceActor->statuses & 2)) {
        value /= 2;
    }

    if (withRandMod != 0) {

        if ((action->id < 6) && (vs_main_getRand(100) < (sourceActor->risk / 10) + 10)) {
            value = (short)((u_int)(value << 0x10) >> 0xF);
            D_800F1A0C = 1;
        }

        if (nHit == 0) {
            if (target->unk40 == 0) {
                func_80080F78(action, sourceActor, (targetActor->enemyClass) + 1,
                    sp18.targetAffinity + 1);
                func_80080C9C(action, targetActor, (sourceActor->enemyClass) + 1,
                    sp18.sourceAffinity + 1, limb);
            }
        }
    }

    return value;
}

static int _getRoomTrapLevel(void);

short _calculateStatChange( vs_action_t* action, _hitEntity_t* arg1, _hitEntity_t* arg2, int hit, int arg4);

void func_80085008(_hitEntity_t* arg0);

void func_80085390( vs_action_t* action, _hitEntity_t* arg1, _hitEntity_t* arg2, int arg3, int hit);

void func_800856F8(void* arg0);

void func_80085718(_hitEntity_t* arg0);

/**
 * Retrieves a compound value of the action type, cost, and whether
 * the actor can pay the cost.
 * @return Packed integer:
 *         - bits 31-24 = bool requirements met
 *         - bits 23-16 = enum action type
 *         - bits 15-0  = int cost
 */
int _getActionCost(u_int actionId, vs_battle_actor2* actor, int updateStat);

void func_800859B4(u_int arg0, vs_battle_actor2* arg1, int arg2);

void func_80085A34(func_80085A34_t* arg0);

int func_800E6C34(SVECTOR*, SVECTOR*, SVECTOR*, int);

void func_80085B10(int action, D_800F19CC_t2* result, D_800F19CC_t2* source, int arg3);

int func_8008631C(int arg0, int arg1, int targetActor, int targetLimb, void* arg4);

int func_800863A4(int arg0, int arg1, int targetActor, int arg3, SVECTOR* arg4, SVECTOR* arg5, D_800F19CC_t2* arg6);

#ifdef ROOD_PC
#undef sp860
#undef sp870
#endif

void func_80086754(int arg0, vs_battle_actor2* arg1);

void func_80086EA4(vs_battle_actor2* arg0, int arg1, int arg2, int arg3);

void func_80086EF4(vs_battle_actor2* arg0, int arg1, int arg2, int arg3);

void func_80086FA8(int arg0, vs_battle_actor2* arg1);

void func_80087578(int arg0, int arg1, int arg2, int arg3);

void _applyBattleAbilityEffect(_hitEntity_t* arg0);

void func_80087EF4(vs_battle_actor2* actor);

int func_800882F4(void);

int func_80088554(void);

int func_80088B6C(void);

void func_80088B8C(void);

void func_80088CA0(void);

void func_80088CAC(void);

void _loadMpdLbas(void* arg0, int size);

void _loadZndEnemies(psx_long* data, int arg1 __attribute__((unused)));

static void _loadZnd(int id)
{
    vs_main_CdFile cdFile;

    cdFile.lba = vs_main_zndFiles[id].lba;
    cdFile.size = vs_main_zndFiles[id].size;
    if (_zoneContext.zndCdFile != 0) {
        vs_main_nop9(0x87, 0);
    }
    _zoneContext.zndCdFile = vs_main_allocateCdQueueSlot(&cdFile);
    if (_zoneContext.zndData != NULL) {
        vs_main_nop9(0x88, 0);
    }
    _zoneContext.zndData = vs_main_allocHeapR(cdFile.size);
    vs_main_cdEnqueuePriority(
        _zoneContext.zndCdFile, _zoneContext.zndData);
    if (_zoneContext.unk30 != 0) {
        int temp_s0 = D_8004FCCC[id];
        if (vs_main_getCurrentMusicId() != temp_s0) {
            func_8004552C(vs_main_soundData.currentMusicSlot, 0, 0x78);
        }
    }
}

void _finishLoadZnd(int id);

void func_80089098(void);

int func_80089104(void);


void func_80089114(void);

void func_80089888(void);

void func_80089A00(void);

void _loadMpdEnemySection(void* data, u_int dataLen);

void func_80089CE4(void);

void func_80089D04(void);

void _loadMpd(int id);

void func_80089DC0(int arg0);

void func_8008A364(void);

void func_8008A3A0(void);

void func_8008A6FC(void);

void _loadZndTims(void* data);

int _loadMpdRoomSection(int arg0, void* data);

void vs_battle_setDoorEntered(void);

int func_8008AB80(int arg0);

int func_8008ABB8(int arg0);

int func_8008ABF0(int arg0);

#include "pc/src/scene_submit.inc"
#include "pc/src/charge_skip.inc"

void func_8008B1FC(void* arg0);

void func_8008B28C(void);

void func_8008B2E0(void* arg0, int arg1, int arg2, int arg3);

void func_8008B320(void);

void func_8008B390(int arg0, int* arg1);

void func_8008B4BC(int arg0);

int func_8008B4C8(char arg0);

void vs_battle_setRoomsUnk0(vs_battle_scene* scene);

void _vsBattleNop2(int arg0 __attribute__((unused)));

void func_8008B590(MATRIX* arg0, int arg1);

void func_8008B6B4(void);

void* func_8008B6FC(void);

int _getCollisionMapDimensions(int arg0 __attribute__((unused)));

_zoneContextBounds* _getMapBounds(int arg0 __attribute__((unused)));

_mpdRoomSection3* func_8008B764(u_int width, u_int height, int arg2);

int func_8008B808(int arg0, int arg1, int arg2, int arg3);

void func_8008B8F8(char (*arg0)[12]);

void func_8008B960(int arg0, int arg1, int arg2);

D_800F1D08_t* func_8008BAC8(int arg0, int arg1, int arg2);

_mpdRoomSectionA* func_8008BC04(int arg0, int arg1, int arg2);

void func_8008BD74(_mpdRoomSectionA* arg0);

int func_8008BEBC(_mpdRoomSectionA* arg0);

int func_8008BF48(_mpdRoomSectionA* arg0);

void func_8008C070(int arg0, _mpdRoomSectionA* arg1);

void func_8008C0C0(void);

int func_8008C1C8(_mpdRoomSectionA* arg0);

int func_8008C2C0(int arg0, int arg1, int arg2, int arg3);

void func_8008C40C(void);

#ifndef ROOD_PC
void func_8008C458(int arg0) { func_80098B38(arg0, 0); }
#endif

int func_8008C49C(int arg0, int arg1);

void func_8008C538(void);

void func_8008C6B4(int arg0, int arg1);

static short const D_80068BEC[] __attribute__((used)) = { 8, 14, 16, 11, 7, 3, 1 };

typedef struct {
    unsigned int flags[2];
    VECTOR positions[4];
    VECTOR velocities[6];
} RoomMotionVectors;
int func_800A4494(int, SVECTOR*);
int func_8008C8A8(void);

#include "pc/src/room_shadows.inc"

int func_8008D2C0(func_8008D2C0_t arg0[]);

int vs_battle_getCurrentSceneId(void);

int func_8008D418(void);

_mpdRoomSection9* func_8008D438(int arg0, int arg1, int arg2);

_mpdRoomSection13* func_8008D508(int arg0, int arg1, int arg2);

void func_8008D594(int arg0);

void func_8008D5A0(int arg0);

void func_8008D5FC(_mpdRoomSectionA* arg0);

void func_8008D658(_mpdRoomSectionA* arg0);

void func_8008D710(void);

void vs_battle_parseTim(u_long* arg0, TIM_IMAGE* tim);

int _getDoorId(int door);

void vs_battle_setDoorEntered2(int arg0);

short func_8008DA24(int arg0, int arg1);

short func_8008DC7C(int arg0, int arg1);

short func_8008DD0C(int arg0, int arg1);

int func_8008DDA8(int arg0, int arg1);

void func_8008DEAC(_mpdRoomSection9* arg0, int arg1);

void func_8008DF14(void);

void func_8008E19C(int arg0, int arg1, short arg2, u_int arg3);

void func_8008E224(int arg0, int arg1);

void* func_8008E2D4(int arg0);

u_int func_8008E320(int arg0);

_mpdRoomSection13* func_8008E370(int* arg0);

_mpdRoomSectionA* func_8008E3B8(int* arg0);

_mpdRoomSection9* func_8008E400(int* arg0);

int func_8008E470(void);

void func_8008E480(int arg0);

short func_8008E4AC(void);

static int _getRoomTrapLevel(void)
{
    return vs_battle_roomData.sectionB->trapLevel;
}

void func_8008E4DC(int arg0);

void _loadMpdLootSection(void* data);

void func_8008E6DC(int arg0);

void func_8008E8F8(void);

void func_8008E938(void);

void func_80090C2C(int);

int func_8008EA90(int arg0);

void func_8008EAE4(int arg0, int arg1);

void func_8008EAF8(int arg0);

void func_8008EB04(int* arg0, int* arg1);

void func_8008EB30(int* arg0);

void func_8008EC48(VECTOR* arg0);

int func_8008EFCC(int arg0);

int func_8008F0FC(void);

int func_8008F234(void);

void func_8008F29C(int arg0, int arg1);

void func_8008F30C(int arg0, int arg1);

void func_8008F440(void);

void func_8008F9A4(int arg0, int arg1);

/* The screen's X range for the weather particles drawn as 2D at projected
 * points: in widescreen (port) the 16:9 view's (pc/src/widescreen.h). */
#ifdef ROOD_PC
#define WEATHER_LEFT (-PC_WIDESCREEN_MARGIN)
#define WEATHER_RIGHT (320 + PC_WIDESCREEN_MARGIN)
#else
#define WEATHER_LEFT 0
#define WEATHER_RIGHT 320
#endif

void func_8008FA14(D_800F1DD4_t* arg0);

void func_8008FAC8(void);

void func_8008FDC4(void);

void func_80090434(void);

void func_80090A1C(D_800F1DD4_t* arg0);

void func_80090B28(void);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/146C", D_80068C1C);

/* Declared for the Zig's c module (the C bodies that declared them are gone). */
extern void pc_story_frame(void);
extern void pc_frame_begin(void);
extern void pc_scene_room(const void*);
extern void pc_room_warp_room_loaded(void);
extern int pc_fast_travel_begin(int packed);
extern void pc_battle_frame_complete(void);

/* Declared for the Zig's c module (the C bodies that declared them are gone). */
extern int pc_weapon_slots_process_pad(void);
extern void pc_scene_camera(const void*);
extern void pc_room_warp_room_spawned(void);

/* Declared for the Zig's c module (the C bodies that declared them are gone). */
extern void pc_finish_room_checkpoint(void);
extern int pc_room_warp_poll(void);
