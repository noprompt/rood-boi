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

typedef struct {
    signed char dx : 2;
    signed char unk0_2 : 2;
    signed char dz : 2;
    signed char unk0_6 : 2;
} D_800F16EC_t;

typedef struct {
    char unk0[8];
    u_char unk8;
    u_char unk9;
    char unkA;
    u_int unkB_0 : 2;
    u_int unkB_2 : 2;
    u_int unkB_4 : 4;
    u_short unkC;
    u_short unkE;
    SVECTOR unk10;
    char unk18[0x24];
    psx_ptr(vs_battle_actor2) unk3C;
} func_800DEB10_t2;

typedef struct {
    int unk0;
    u_int unk4;
} func_800E78F4_t2;

typedef struct func_800E78F4_t {
    char unk0[0x4E];
    u_short unk4E;
    char unk50[4];
    psx_ptr(func_800DEB10_t2) unk54;
    char unk58[4];
    psx_ptr(vs_battle_actor2) unk5C;
    char unk60[0xCF];
    u_char unk12F;
    char unk130[0x70];
    psx_ptr(struct func_800E78F4_t) unk1A0;
    char unk1A4[0x28C];
    psx_ptr(func_800E78F4_t2) unk430;
    char unk434[0x3C];
    int unk470;
} func_800E78F4_t;

typedef struct {
    u_char maxX, maxZ, minX, minZ;
    char unk4[0x10];
    int unk14;
    u_short unk18;
    char unk1A[2];
    psx_ptr(func_800E78F4_t) unk1C;
    psx_ptr(func_800E78F4_t) unk20;
    int unk24;
} D_800F58BC_t;

typedef struct {
    int unk0;
    u_int unk4_0 : 3;
    u_int unk4_3 : 2;
    u_int unk4_5 : 8;
    u_int unk4_13 : 19;
    int unk8;
    u_int unkC_0 : 4;
    u_int unkC_4 : 3;
    u_int unkC_7 : 12;
    u_int unkC_19 : 8;
    u_int unkC_27 : 5;
} func_800DCAA0_t;

typedef struct {
    char unk0[0x16];
    signed char unk16;
    char unk17[0x21];
    int unk38;
    char unk3C[0x18];
    psx_ptr(func_800DEB10_t2) unk54;
    char unk58[0x42];
    short unk9A;
    char unk9C[0x5F];
    u_char unkFB;
    char unkFC[0x2E];
    u_char unk12A;
    char unk12B[0xD];
    u_short unk138;
    char unk13A[0x2F6];
    psx_ptr(func_800DCAA0_t) unk430[16];
    int unk470;
} func_800DEEA4_t2;
void func_800D82CC(func_800E78F4_t*);
typedef struct movementRecoveryState movementRecoveryState;
void func_800E2CCC(movementRecoveryState*);
void func_800E4CE8(func_800DEEA4_t2* arg0);
extern func_800DEEA4_t2* D_800F5878[];
extern D_800F58BC_t* D_800F58BC;

typedef union {
    unsigned int raw;
    struct {
        unsigned int x : 8, y : 8, z : 8, status : 8;
    } p;
} vs_battle_movementPosition;
typedef struct {
    unsigned char pad[7];
    unsigned char disabled;
    unsigned char rest[0x2C];
    vs_battle_movementPosition position;
    char unk38[0x130];
    vs_battle_movementPosition destination;
} func_800D8400_t;
int func_800D96C8(func_800D8400_t*, unsigned int, unsigned int, int);
int func_800D954C(func_800D8400_t*, unsigned int);
unsigned int func_800DB93C(func_800D8400_t*, unsigned int, int, unsigned int);
unsigned int func_800D8400( func_800D8400_t* state, int first, int second, unsigned int direction);


typedef struct {
    int score;
    unsigned int row : 3, column : 2, action : 8, threshold : 16, pad29 : 3;
    unsigned int distanceSquared;
    unsigned int targetId : 4, part : 3, heading : 12, weight : 8, padC27 : 5;
    unsigned int low : 1, flag1 : 1, flag2 : 1, flag3 : 1, flag4 : 1, flag5 : 1,
        range : 16, high : 10;
} actionCandidateEntry;
typedef struct {
    unsigned char flags, pad[3];
} actionCandidateTarget;
typedef struct {
    char pad0[0x131];
    unsigned char status;
    char pad132[0x72];
    actionCandidateTarget targets[16];
    unsigned int targetDistancesSquared[16];
    char pad224[0x20C];
    psx_ptr(actionCandidateEntry) entries[16];
    int count;
} actionCandidateState;
PSX_ASSERT_SIZE(actionCandidateState, 0x474);
int func_800E4CF4(actionCandidateState*, actionCandidateEntry*, int);
int func_800E4DF8(actionCandidateState*, int, int);
void func_800D9DD8(actionCandidateState*);
int func_800D85D8(actionCandidateState* state);


typedef struct {
    char unk0[8];
    union {
        u_int raw;
        struct {
            u_int unk0 : 16;
            u_int unk16 : 3;
            u_int unk19 : 2;
            u_int unk21 : 10;
            u_int unk31 : 1;
        } bits;
    } flags;
    char unkC[8];
    short unk14;
    char unk16[6];
    SVECTOR position;
    short unk24;
    short facing;
    char unk28[0x34];
    vs_battle_movementPosition tile;
    vs_battle_movementPosition lastTile;
    char unk64[0x548];
    u_int unk5AC_0 : 15;
    u_int unk5AC_15 : 1;
    u_int unk5AC_16 : 16;
} actorObject;

typedef union {
    u_int raw;
    struct {
        u_int active : 1;
        u_int previous : 1;
        u_int hidden : 1;
        u_int inView : 1;
        u_int unk4 : 1;
        u_int visible : 1;
        u_int kind : 2;
        u_int counter : 7;
        u_int timer : 5;
        u_int kindTimer : 7;
        u_int blocked : 1;
        u_int previousKind : 2;
        u_int outOfReach : 1;
        u_int unk31 : 1;
    } bits;
} actorRelation;

typedef struct {
    char unk0[0x22];
    u_char unk22;
    char unk23[2];
    u_char unk25;
    char unk26[0xE];
    vs_battle_movementPosition tile;
    char unk38[0x14];
    SVECTOR position;
    char unk54[4];
    psx_ptr(actorObject) object;
    char unk5C[0x26];
    short height;
    char unk84[4];
    u_char actorId;
    char unk89[9];
    u_short radius;
    char unk94[0x10];
    u_int nearDistance;
    u_int angleLimit;
    u_int farDistance;
    char unkB0[8];
    short extent;
    char unkBA[0x71];
    u_char phase;
    char unk12C[0x78];
    actorRelation relations[16];
    u_int distances[16];
} actorRelationState;
PSX_ASSERT_SIZE(actorRelationState, 0x224);

int func_800E4624(short*, short*, int, int);
int func_800E44E8(SVECTOR*, SVECTOR*, int, int);
int func_800E437C(SVECTOR*, SVECTOR*, int, u_int);

#define RELATION_STATES(id) psx_slot_get(actorRelationState*, 0x1F80037C, id)

static inline int checkExtent(
    SVECTOR* from, SVECTOR* to, actorRelationState* state, int id)
{
    actorRelationState* other = RELATION_STATES(id);
    int extent;

    if (other) {
        extent = other->extent;
    } else {
        extent = 128;
    }
    return func_800E44E8(from, to, extent, state->extent);
}

static inline int checkHeight(
    SVECTOR* from, SVECTOR* to, actorRelationState* state, int id)
{
    actorRelationState* other = RELATION_STATES(id);
    int height;
    int own;

    if (other) {
        height = ABS(other->height);
    } else {
        height = 64;
    }
    own = state->height;
    if (own < 0) {
        own = -own;
    }
    return func_800E44E8(from, to, height, own);
}

void func_800D87E8(actorRelationState* state, int id);


typedef struct actorUpdateActor {
    psx_ptr(struct actorUpdateActor) next;
    int id;
    u_char flags;
    u_char unk9;
    char unkA;
    u_int unkB_0 : 2;
    u_int unkB_2 : 6;
    char unkC[0x30];
    psx_ptr(vs_battle_actor2) stats;
} actorUpdateActor;
PSX_ASSERT_SIZE(struct actorUpdateActor, 0x40);

typedef struct {
    u_int position;
    u_int unk4;
} actorUpdatePoint;

typedef struct {
    u_int current : 16;
    u_int max : 16;
} actorUpdateHp;

typedef struct {
    char unk0[0x18];
    actorUpdateHp hp;
    int current;
    int max;
} actorUpdateStats;

typedef struct {
    char unk0[8];
    u_char unk8;
    char unk9[5];
    u_char unkE;
    char unkF[5];
    u_char unk14;
    char unk15[3];
    u_char unk18;
    char unk19[3];
    u_char unk1C;
    u_char unk1D;
    char unk1E[0x11];
    u_char unk2F;
    char unk30[4];
    u_int unk34;
    union {
        int value;
        u_char b[4];
    } unk38;
    u_int unk3C;
    u_short unk40;
    char unk42[3];
    u_char unk45;
    u_short unk46;
    char unk48[4];
    int unk4C;
    int unk50;
    psx_ptr(vs_battle_actor) actor;
    psx_ptr(actorObject) object;
    psx_ptr(actorUpdatePoint) unk5C;
    psx_ptr(actorUpdatePoint) unk60;
    psx_ptr(actorUpdatePoint) unk64;
    char unk68[8];
    union {
        u_char b[8];
        int w[2];
    } historyX;
    union {
        u_char b[8];
        int w[2];
    } historyZ;
    u_char historyIndex;
    u_char historyMask;
    char unk82[0xE];
    u_short unk90;
    char unk92[0x68];
    u_char unkFA;
    u_char unkFB;
    char unkFC[0x18];
    u_short unk114;
    char unk116[0xA];
    u_int unk120;
    u_char unk124;
    char unk125[5];
    u_char unk12A;
    char unk12B[6];
    u_char unk131;
    char unk132[6];
    u_short unk138;
    char unk13A[0x1C];
    u_short unk156;
    char unk158[0x34];
    int unk18C;
    u_int unk190_0 : 5;
    u_int unk190_5 : 7;
    u_int unk190_12 : 20;
    char unk194[6];
    u_char unk19A;
    char unk19B[9];
    u_int targets[16];
} actorUpdateState;
PSX_ASSERT_SIZE(actorUpdateState, 0x1e4);

static inline int historyRepeats(actorUpdateState* state)
{
    return state->historyX.w[0] == state->historyX.w[1]
        && state->historyZ.w[0] == state->historyZ.w[1];
}

static inline int historyStalled(actorUpdateState* state)
{
    return state->historyMask == 0xFF ? historyRepeats(state) : 0;
}

extern int D_800F58D4;
extern int D_800F58E0;
extern int D_800F16F4;
struct actorEvaluationState;
struct actorTimerState;
void func_800D821C(struct actorEvaluationState*);
void func_800DBF00(func_800E78F4_t*);
void func_800DBFE4(struct actorTimerState*);
void func_800E4F14(void*);
void func_800D8280(actorUpdateState*);
void func_800E4358(actorUpdateState*);
void func_800E48F8(actorUpdateState*);
void func_800E48A8(actorUpdateState*, int, int);

void func_800D8EF4(void);


extern int D_800F58C4;

void func_800D9538(void);

