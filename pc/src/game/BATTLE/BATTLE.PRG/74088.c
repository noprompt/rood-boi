#include "common.h"
#include "3A1A0.h"
#include "4A0A8.h"
#include "5BF94.h"
#include "6E644.h"
#include "pc/src/game/SLUS_010.40/32154.h"
#include "pc/src/game/SLUS_010.40/main.h"
#include "pc/src/game/SLUS_010.40/overlay.h"
#include "build/src/include/lbas.h"
#include <abs.h>
#include <stdlib.h>
#include "pc/src/psx_types.h"
#include "ai_views.h"

int func_8008631C(int, int, int, int, void*);
int func_800863A4(int, int, int, int, SVECTOR*, SVECTOR*, void*);
void func_800DC810(func_800DEEA4_t*);
struct actionStatSnapshot;
void func_800DC888(struct actionStatSnapshot*);
void func_800E4C8C(func_800DEEA4_t2*);
void func_800E4CE8(func_800DEEA4_t2* arg0);
extern func_800DEEA4_t2* D_800F5878[];
extern D_800F58BC_t* D_800F58BC;
extern u_short (*D_800F58D0)[32];
extern func_800DEEA4_t* D_800F5900;
extern D_800F5920_t* D_800F5920;

int func_800E4CF4(actionCandidateState*, actionCandidateEntry*, int);
int func_800E4DF8(actionCandidateState*, int, int);
void func_800D9DD8(actionCandidateState*);
int func_800D85D8(actionCandidateState* state);
struct actorEvaluationState;
void func_800D821C(struct actorEvaluationState*);
void func_800E4F14(void*);
int func_800E42D4(int, int);
unsigned int func_800E4660(int, int, int);
void func_800D820C(int, int);

typedef struct actionStatSnapshot {
    int unknown;
    short hp, maxHP, mp, maxMP;
    unsigned int status;
    short value10, limit10, value14, limit14;
} actionStatSnapshot;
typedef struct {
    unsigned char actor;
    char pad1;
    unsigned char value2;
    char pad3;
    short hp, mp;
    char pad8[12];
    unsigned int addStatus, removeStatus, modes;
    char pad20[24];
    short value10;
    char pad3A[2];
    short value14;
    char pad3E[2];
    int skip;
} actionStatDelta;
typedef struct {
    unsigned short action;
    char pad2[2];
    actionStatDelta first;
    char pad48[2];
    unsigned short count;
    actionStatDelta entries[1];
} actionStatApplication;
typedef struct {
    unsigned int flags;
    char pad4[48];
} actionCostView;

void func_800DC30C(short*, short*, int, int);
void func_800DC888(actionStatSnapshot* stats);

void func_800DCAA0(func_800DCAA0_t1* arg0, int arg1, func_800DCAA0_t* arg2, int arg3);

void func_800DCBD8(func_800DCAA0_t* arg0);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/74088", D_80069B68);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/74088", D_80069BBC);

typedef struct {
    char pad0[0x17];
    unsigned char maxActionCost;
    char pad18[0x13];
    unsigned char special;
    char pad2C[0x178];
    struct {
        unsigned char classification;
        char pad[3];
    } targets[16];
} actionScoreState;
typedef struct actionScoreActor {
    psx_ptr(struct actionScoreActor) next;
    int id;
} actionScoreActor;
PSX_ASSERT_SIZE(struct actionScoreActor, 0x8);
typedef struct {
    char pad[14];
    unsigned short flags;
} actionScoreMetadata;
void func_800DC424(actionStatSnapshot*);
int func_800DC284(int, int, int, int);
const signed char D_80069BD0[] = { -51, -39, -39, -39, -26, -51, 50, -13, 12, -13, 12, 25,
    -51, -26, -45, -26, -39, 76, 19, -13, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0, 0, 0 };
void func_800DCC94(actionScoreState* state, actionCandidateEntry* candidate, int mode, actionScoreMetadata* action);

typedef union {
    unsigned int raw;
    struct {
        unsigned int unk0 : 6, classification : 2, unk8 : 7, timer : 5, counter : 7,
            unk27 : 1, previous : 2, unk30 : 2;
    } p;
    struct {
        unsigned char flags, pad[3];
    } b;
} actionReactionTarget;
typedef struct {
    char pad0[0x13];
    unsigned char flag13;
    char pad14[12];
    unsigned char flag20, flag21;
    char pad22[5];
    unsigned char flag27;
    char pad28[4];
    unsigned char flag2C;
    char pad2D[3];
    unsigned char flag30;
    char pad31[0x57];
    unsigned char id;
    char pad89[0xA4];
    unsigned char mode;
    char pad12E[0x76];
    actionReactionTarget targets[16];
} actionReactionState;
typedef struct {
    char pad0[20];
    unsigned int effect1, effect2;
    char pad1C[24];
} actionReactionAction;
typedef struct {
    char pad0[10];
    unsigned char flag;
} actionReactionMotion;
int func_800DC48C(int, int);
int func_800DC484(int, int);
void func_800DC210(actionReactionState*, int);
void func_800DC19C(actionReactionState*);
void func_800DC784(actionReactionState*, int);
void func_800DD000(actionReactionState* state, actionStatApplication* app);

void func_800DD344(actionReactionState* state);

typedef struct {
    u_int unk0_0 : 2;
    u_int flag2 : 1;
    u_int mode : 2;
    u_int flag5 : 1;
    u_int usable : 1;
    u_int enabled : 1;
    u_int range : 16;
    u_int unk0_24 : 8;
    u_int value;
} actionSlotConfig;

typedef struct {
    u_int flag0 : 1;
    u_int flag1 : 1;
    u_int flag2 : 1;
    u_int flag3 : 1;
    u_int unk4 : 28;
} actionChoiceFlags;

typedef struct {
    int unk0;
    u_int category : 3;
    u_int slot : 2;
    u_int action : 8;
    u_int unk4_13 : 19;
    u_int score;
    u_int unkC_0 : 19;
    u_int targetWeight : 8;
    u_int unkC_27 : 5;
    actionChoiceFlags flags;
} actionChoice;

typedef struct {
    char unk0[0x1B];
    u_char dead;
    char unk1C[0x40];
    psx_ptr(vs_battle_actor2) stats;
    char unk60[0x22];
    short heading;
    char unk84[0xBC];
    actionChoice choice;
    char unk154[0xDC];
    actionSlotConfig configs[6][4];
} actionChoiceState;
PSX_ASSERT_SIZE(actionChoiceState, 0x2f0);

/* Local view of the vs_main_actions flag word at 0xC */
typedef struct {
    char unk0[0xC];
    u_int unkC_0 : 23;
    u_int flag23 : 1;
    u_int unkC_24 : 4;
    u_int flag28 : 1;
    u_int flag29 : 1;
    u_int unkC_30 : 2;
    char unk10[0x24];
} actionChoiceInfo;

typedef struct {
    char pad0[0x4C];
    short x, y, z;
} nearestWaypointState;
typedef struct {
    unsigned char x, y, z, flags;
} nearestWaypointDestination;
extern unsigned short* D_800F58C8;
static inline unsigned int nearestWaypointValue(unsigned short* row, int index)
{
    unsigned short* p = row;
    p += index;
    return *p;
}
static inline unsigned short* nearestWaypointAddress(unsigned short* row, int index)
{
    row += index;
    return row;
}
void func_800DD7CC(nearestWaypointState* state, nearestWaypointDestination* destination);

extern u_char (*D_800F5904)[256];
void func_800E4288(void*, int);
void func_800DC2E0(actionCandidateEntry*, actionCandidateEntry*);
void func_800DC344(actionChoiceState*, actionCandidateEntry*);
void func_800DC4F0(actionCandidateEntry*, actionChoiceInfo*);

static inline vs_battle_uiEquipment_limb* actorLimb(vs_battle_actor2* stats, int limb)
{
    return psx_to_ptr(vs_battle_actor2*,
        limb * sizeof(vs_battle_uiEquipment_limb) + psx_to_int(int, stats))
        ->limbs;
}

typedef struct {
    int mask;
    u_short unk4;
    u_short interval;
    int unk8;
    int unkC;
} statusEffectTick;
typedef struct {
    statusEffectTick entries[1];
} statusEffectTable;

extern u_int D_80069BBC[];
void func_800E4F14(void*);

void func_800DE030(int elapsed);

#define MIN(a, b) ((a) > (b) ? (b) : (a))
#define MAX(a, b) ((a) < (b) ? (b) : (a))

typedef struct {
    char unk0[0x26];
    u_char allowFallback;
    char unk27[0x2D];
    psx_ptr(vs_battle_actor) actor;
    char unk58[4];
    psx_ptr(vs_battle_actor2) stats;
    char unk60[0x28];
    u_char id;
    char unk89[0xA5];
    u_char mode;
    char unk12F[0x10];
    u_char minDelay;
    char unk140[0x1B0];
    actionCandidateEntry candidates[16];
    psx_ptr(actionCandidateEntry) entries[16];
    int count;
} actionPlanState;
PSX_ASSERT_SIZE(actionPlanState, 0x474);

extern int D_800F58F0;
extern int D_800F58F4;
extern vs_battle_actor2* D_800F58E8;
extern actionCandidateEntry (*D_800F58EC)[16];
extern actionCandidateEntry* D_800F58F8;
void func_800DC3E8(vs_battle_actor2* src, vs_battle_actor2* dst);
void func_800DC3CC(actionPlanState*);
void func_800DC574(actionPlanState*, int);

static inline int snapshotActorStats(void)
{
    vs_battle_actor* actor;

    D_800F58E8 = vs_main_allocHeapR(sizeof(vs_battle_actor2) * 16);
    if (D_800F58E8 == NULL) {
        return 0;
    }
    for (actor = vs_battle_actors[0]; actor != NULL; actor = psx_get(actor->next)) {
        func_800DC3E8(psx_get(actor->unk3C), &D_800F58E8[actor->id]);
    }
    return 1;
}

static inline void restoreActorStats(void)
{
    vs_battle_actor* actor;

    for (actor = vs_battle_actors[0]; actor != NULL; actor = psx_get(actor->next)) {
        func_800DC3E8(&D_800F58E8[actor->id], psx_get(actor->unk3C));
    }
    vs_main_freeHeapR(D_800F58E8);
}

#undef MIN
#undef MAX

void func_800DEB10(func_800DEEA4_t* arg0);

typedef struct actorEvaluationStats {
    char pad0[24];
    short hp;
    char pad1A[23];
    unsigned char f31;
    char pad32[1];
    unsigned char f33;
} actorEvaluationStats;
typedef struct actorEvaluationActor {
    psx_ptr(struct actorEvaluationActor) next;
    int id;
    unsigned char flags;
    char pad9[51];
    psx_ptr(actorEvaluationStats) stats;
} actorEvaluationActor;
PSX_ASSERT_SIZE(struct actorEvaluationActor, 0x40);
typedef struct actorEvaluationState {
    char pad0[19];
    unsigned char f13;
    char pad14[7];
    unsigned char dead;
    char pad1C[108];
    unsigned char id;
    char pad89[17];
    unsigned short timer;
    char pad9C[75];
    unsigned char fE7;
    unsigned char fE8;
    char padE9[177];
    unsigned char f19A;
} actorEvaluationState;
typedef struct actorEvaluationContext {
    char pad0[4];
    unsigned char id;
    char pad5[63];
    int f44;
} actorEvaluationContext;
extern u_char (*D_800F5904)[256];
void func_800E685C(int, int, int);
void func_800D821C(actorEvaluationState*);
int func_800DEC88(void* arg0);

void func_800DEEA4(func_800DEEA4_t* arg0);

