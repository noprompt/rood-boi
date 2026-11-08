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
    u_short unk0_0 : 5;
    u_short unk0_5 : 5;
    u_short unk0_10 : 6;
} D_800F5910_t;

typedef struct {
    u_char unk0;
    u_char unk1;
    u_char unk2;
} func_800DFA54_t;

typedef struct {
    short unk0;
    short unk1;
    short unk2;
    short unk3;
} func_8008D2C0_t;

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
    int unk4;
    u_int unk8_0 : 21;
    u_int unk8_21 : 1;
    u_int unk8_22 : 10;
} func_800E1238_t;

typedef struct {
    char unk0[7];
    u_char unk7;
    char unk8[0x2C];
    u_char unk34;
    char unk35;
    u_char unk36;
    char unk37[0x17];
    short unk4E;
    char unk50[8];
    psx_ptr(func_800E1238_t) unk58;
    char unk5C[0x62];
    short unkBE;
    char unkC0[0xBC];
    int unk17C;
    int unk180;
    int unk184;
    short unk188;
    char unk18A[0x9E];
    int unk228;
} func_800E0850_t;

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
int func_8008D2C0(func_8008D2C0_t*);
void func_800DEEFC(func_800E0850_t*, int);
struct directionalCacheState;
int func_800E0678(struct directionalCacheState*, int);
struct movementCheckState;
int func_800E0918(struct movementCheckState*, int, int);
typedef struct movementRecoveryState movementRecoveryState;
void func_800E2CCC(movementRecoveryState*);
void func_800E3600(func_800E0850_t*, int, int);
int func_800E42EC(int, int);
int func_800E4764(func_800E0850_t*, int*, int*);
void func_800E4B18(func_800E0850_t*);
void func_800E678C(func_800E0850_t*);
extern D_800F58BC_t* D_800F58BC;
extern D_800F5910_t* D_800F5910;
void func_800D8260(func_800DEEA4_t2* arg0, int arg1, int arg2);

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
unsigned int func_800E4660(int, int, int);
void func_800E50A0(void*, int, int);
int func_800E45D4(int);
void func_800E1388(func_800D8400_t*, vs_battle_movementPosition, int, unsigned int);
int func_800E45D4(int);

void func_800DF9A8(func_800DFA54_t* arg0, func_800DFA54_t* arg1);

void func_800DFA54(int arg0, int arg1, int arg2, func_800DFA54_t* arg3);

int func_800DFAF8(int arg0, u_int arg1, int arg2);


typedef struct routeEdgeState {
    char unk0[5];
    u_char unk5;
    char unk6[0x2E];
    vs_battle_movementPosition tile;
    char unk38[0x14];
    short x;
    short y;
    short z;
    char unk52[0x36];
    u_char id;
    char unk89[0xB1];
    u_short cooldown;
    u_short period;
    char unk13E[0x16];
    u_char area;
    char unk155[7];
    u_char target;
    char unk15D[0xB];
    vs_battle_movementPosition destination;
    char unk16C[4];
    vs_battle_movementPosition next;
    char unk174[8];
    int moveX;
    int moveZ;
    char unk184[4];
    short heading;
    short angle;
    char unk18C[0xF];
    u_char gate;
    func_800DFA54_t exit;
} routeEdgeState;

typedef struct {
    char unk0[0x60];
    psx_ptr(short) position;
} routeEdgeActor;
PSX_ASSERT_SIZE(routeEdgeActor, 0x64);

typedef struct {
    char unk0[14];
    u_char closedGates;
} routeEdgeGlobals;

typedef u_short routeEdgePair[2];

extern u_char D_800F175C[];
int func_8008E320(int);
void func_800E4BE0(int);

static inline u_int routeWord(routeEdgePair* pair) { return *(u_int*)pair; }

static inline u_short routeHalf(routeEdgePair* pair, int index) { return (*pair)[index]; }

static inline u_int routeTile(int z, int x)
{
    return (psx_slot_get(__typeof__(u_short(*)[32]), 0x1F8003C0, 0))[z][x];
}

static inline int routeSetArea(routeEdgeState* state, vs_battle_movementPosition position)
{
    state->area = routeTile(position.p.z, position.p.x) & 15;
    return 6;
}

int func_800DFBCC(routeEdgeState* state, int index, int area);


typedef struct {
    short x, y, z, pad;
} obstructionVector;
typedef struct {
    char pad[0x1C];
    obstructionVector position;
} obstructionModel;
typedef struct {
    char pad0[0x4C];
    obstructionVector position;
    char pad54[4];
    psx_ptr(obstructionModel) model;
    char pad5C[0x2C];
    unsigned char id;
    char pad89[9];
    unsigned short radius;
    char pad94[0x1F];
    unsigned char step;
    char padB4[4];
    short height;
} obstructionState;
PSX_ASSERT_SIZE(obstructionState, 0xbc);
typedef struct {
    unsigned char p0, p1, tested, p3, result[8];
} obstructionCache;
#define OBSTRUCTION_CACHE ((obstructionCache*)0x1F8003D0)
#define OBSTRUCTION_DIRECTIONS ((D_800F16EC_t*)0x1F8003EC)
#define OBSTRUCTION_STATES(id) psx_slot_get(obstructionState*, 0x1F80037C, id)

int func_800E02B4(obstructionState* state, int direction, int ahead);


#undef OBSTRUCTION_CACHE
#undef OBSTRUCTION_DIRECTIONS
#undef OBSTRUCTION_STATES

typedef union {
    unsigned int raw;
    struct {
        unsigned char x, y, z, w;
    } p;
} directionalCachePoint;
typedef struct directionalCacheState {
    char pad[0x34];
    directionalCachePoint tile, previous;
    char pad3C[0x82];
    short minimumHeight;
} directionalCacheState;

int func_800E42EC(int, int);
typedef struct {
    unsigned char tested, valid;
} directionalCacheBits;
#define MOVEMENT_CHECK_CACHE ((directionalCacheBits*)0x1F8003D0)
#define MOVEMENT_CHECK_DIRECTIONS ((D_800F16EC_t*)0x1F8003EC)
#define MOVEMENT_CHECK_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))
int func_800E0678(directionalCacheState* state, int direction);


#undef MOVEMENT_CHECK_CACHE
#undef MOVEMENT_CHECK_DIRECTIONS
#undef MOVEMENT_CHECK_TILES

int func_800E0850(func_800E0850_t* arg0, u_int arg1);


typedef struct {
    char pad0[8];
    unsigned int flags;
} movementCheckObject;
typedef struct movementCheckState {
    char pad0[0x34];
    int position;
    char pad38[0x20];
    psx_ptr(movementCheckObject) object;
    char pad5C[0x62];
    short height;
    char padC0[0x9E];
    unsigned short flags;
    char pad160[8];
    int target;
} movementCheckState;
PSX_ASSERT_SIZE(struct movementCheckState, 0x16c);
void func_800E4B2C();
void func_800E4B70();
unsigned int func_800E45F4(unsigned int, unsigned int);
int func_800E42E0(unsigned int);
void func_800E4B10(void*);
int func_800E0918(movementCheckState* state, int action, int mode);


typedef union {
    unsigned int raw;
    struct {
        short x;
        short y;
    } p;
} movementStepPosition;
typedef struct {
    unsigned char unk0;
    char pad1[6];
    unsigned char unk7;
    char pad8[0x2C];
    directionalCachePoint tile;
    char pad38[0x14];
    movementStepPosition position;
    short z;
    char pad52[6];
    psx_ptr(movementCheckObject) object;
    char pad5C[0x60];
    short clearance;
    short height;
    char padC0[0x25];
    unsigned char actorId;
    char padE6[0x82];
    directionalCachePoint destination;
    char pad16C[0x10];
    int moveX;
    int moveZ;
    int moveY;
    short angle;
    char pad18A[0x9E];
    int unk228;
} movementStepState;
PSX_ASSERT_SIZE(movementStepState, 0x22c);
typedef struct {
    char pad0[0x1E];
    short y;
    char pad20[0x3C];
    directionalCachePoint tile;
    char pad60[0x5DE];
    unsigned short height;
} movementStepActor;
int func_800E02B4(obstructionState*, int, int);
int func_800E6A6C(int, int, int, int);
void func_800E1238(func_800E0850_t*, int);
#define MOVEMENT_STEP_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))
#define MOVEMENT_STEP_RESULT (*(int*)0x1F8003C8)
void func_800E0A68(movementStepState* state, int action);

#undef MOVEMENT_STEP_TILES
#undef MOVEMENT_STEP_RESULT

void func_800E1238(func_800E0850_t* arg0, int arg1);

void func_800E1388(func_800D8400_t* state, vs_battle_movementPosition source, int angle, unsigned int distance);


typedef struct {
    char pad0[0xD];
    unsigned char flagD;
    char padE[0x26];
    vs_battle_movementPosition position;
    char pad38[0x10];
    vs_battle_movementPosition previous;
    short x;
    char pad4E[2];
    short z;
    char pad52[0x3A];
    unsigned short attempts;
    char pad8E[0x26];
    int distance;
    char padB8[0xA6];
    unsigned short flags;
    char pad160[8];
    vs_battle_movementPosition destination;
    char pad16C[4];
    vs_battle_movementPosition next;
    char pad174[8];
    int referenceX, referenceZ;
} movementDestinationState;
unsigned int func_800E4660(int, int, int);
unsigned int func_800E45F4(unsigned int, unsigned int);
void func_800E4B2C(movementDestinationState*, int);
void func_800E153C(movementDestinationState* state, int unused);

void func_800E1764(movementDestinationState* state, int angle);

u_char func_800E1850(u_char arg0, u_int arg1, int arg2);


typedef union {
    unsigned int raw;
    struct {
        unsigned char x, y, z, w;
    } p;
} terrainMovementPoint;
typedef struct terrainMovementActor {
    char pad0[9];
    unsigned char mode;
    char padA[2];
    unsigned short angle;
} terrainMovementActor;
typedef struct terrainMovementState {
    char pad0[2];
    unsigned char f2;
    char pad3[1];
    unsigned char f4;
    unsigned char f5;
    char pad6[20];
    unsigned char f1A;
    char pad1B[14];
    unsigned char f29;
    char pad2A[10];
    terrainMovementPoint tile;
    char pad38[20];
    short position[3];
    char pad52[2];
    psx_ptr(terrainMovementActor) actor;
    char pad58[272];
    terrainMovementPoint destination;
    char pad16C[16];
    int targetX;
    int targetZ;
    char pad184[4];
    short angle;
} terrainMovementState;
PSX_ASSERT_SIZE(struct terrainMovementState, 0x18c);
#define TERRAIN_TILE_MASK (psx_slot_get(unsigned char*, 0x1F8003C4, 0))
#define TERRAIN_MAP_WIDTH (*(unsigned char*)0x1F8003DC)
#define TERRAIN_MOVE_RESULT (*(int*)0x1F8003C8)
#define TERRAIN_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))
struct routeEdgeState;
int func_800DFBCC(struct routeEdgeState*, int, int);
void func_800E4BB8(terrainMovementState*);
void func_800E4B70(terrainMovementState*, int);
void func_800E1908(terrainMovementState* state);

void func_800E19FC(terrainMovementState* state);


#undef TERRAIN_TILE_MASK
#undef TERRAIN_MAP_WIDTH
#undef TERRAIN_MOVE_RESULT
#undef TERRAIN_TILES

typedef struct {
    char pad0[8];
    unsigned int flags;
} wanderObject;
typedef struct wanderState {
    char pad0[2];
    unsigned char flag2;
    unsigned char flag3;
    char pad4[4];
    unsigned char flag8;
    char pad9[0x2B];
    vs_battle_movementPosition tile;
    char pad38[0x10];
    vs_battle_movementPosition saved;
    short x, y, z;
    char pad52[6];
    psx_ptr(wanderObject) object;
    char pad5C[0x58];
    unsigned int moveArg;
    char padB8[8];
    unsigned short mode;
    unsigned short timer;
    int rangeSquared;
    char padC8[8];
    short angle;
    unsigned short cooldown;
    unsigned short restPeriod;
    unsigned short movePeriod;
    unsigned char rate;
    char padD9[0x43];
    vs_battle_movementPosition goal;
    char pad120[13];
    unsigned char mode12D;
    char pad12E[0x2F];
    unsigned char count;
    unsigned short flags;
    char pad160[8];
    vs_battle_movementPosition dest;
} wanderState;
PSX_ASSERT_SIZE(struct wanderState, 0x16c);

#define WANDER_DIRECTIONS ((D_800F16EC_t*)0x1F8003EC)
#define WANDER_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))

int func_800E4690(unsigned int, int);
int D_800D9B6C(wanderState*, int);

static inline D_800F16EC_t* wanderDirection(int index)
{
    return WANDER_DIRECTIONS + index;
}

int func_800E1BB8(wanderState* state, unsigned int tile, unsigned int maxCount, int arg3);


static inline int wanderRandomHeading(int direction)
{
    int offset = func_800E45D4(512);
    int angle = direction << 9;
    offset += 0xFF00;
    return angle + offset;
}

static inline void wanderStartWalk(wanderState* s)
{
    s->angle = -1;
    s->count = 0;
    s->cooldown = 60;
    s->mode++;
    func_800E2CCC((movementRecoveryState*)s);
}

void func_800E1EAC(wanderState* state, unsigned int tile, unsigned int range);


#undef WANDER_DIRECTIONS
#undef WANDER_TILES

typedef struct {
    char pad0[0x34];
    vs_battle_movementPosition tile;
    char pad38[0xC8];
    unsigned char index, row, rate, direction, timer;
    char pad105[0x63];
    vs_battle_movementPosition dest;
} patrolWaypointState;
extern unsigned short (*D_800F58D8)[8];
void func_800E50A0(void*, int, int);
static inline unsigned int patrolWaypoint(unsigned short* row, int index)
{
    unsigned short* ptr = row;
    ptr += index;
    return *ptr;
}
void func_800E23AC(patrolWaypointState* state);


typedef union {
    unsigned int raw;
    unsigned char b[4];
} targetMovementPoint;
typedef struct {
    unsigned int f0 : 1, f1 : 1, f2 : 1, pad3 : 2, f5 : 1, pad6 : 26;
} targetMovementFlags;
typedef struct {
    char pad[9];
    unsigned char id;
} targetMovementActor;
typedef struct {
    char pad0[8];
    unsigned int flags;
    char padC[16];
    short x;
    char pad1E[2];
    short z;
} targetMovementModel;
typedef struct targetMovementState {
    unsigned char b0;
    unsigned char b1;
    char pad2[1];
    unsigned char b3;
    unsigned char b4;
    char pad5[4];
    unsigned char b9;
    char padA[2];
    unsigned char bC;
    unsigned char bD;
    char padE[22];
    unsigned char b24;
    char pad25[14];
    unsigned char b33;
    vs_battle_movementPosition tile;
    char pad38[16];
    targetMovementPoint previousDestination;
    short x;
    char pad4E[2];
    short z;
    char pad52[2];
    psx_ptr(targetMovementActor) actor;
    psx_ptr(targetMovementModel) model;
    char pad5C[44];
    unsigned char id;
    char pad89[83];
    int range;
    int previousRange;
    unsigned char bE4;
    unsigned char targetId;
    unsigned char timeout;
    unsigned char bE7;
    unsigned char bE8;
    unsigned char rangeMode;
    unsigned char previousOption;
    unsigned char previousTargetId;
    targetMovementPoint cachedDestination;
    char padF0[4];
    unsigned char targetTileX;
    char padF5[1];
    unsigned char targetTileZ;
    char padF7[1];
    unsigned short timer;
    char padFA[94];
    short destinationX;
    short destinationZ;
    unsigned char movementTargetId;
    char pad15D[1];
    unsigned short flags15E;
    char pad160[8];
    targetMovementPoint destination;
    char pad16C[16];
    int targetX;
    int targetZ;
    char pad184[32];
    targetMovementFlags targets[16];
    unsigned int distances[16];
} targetMovementState;
PSX_ASSERT_SIZE(struct targetMovementState, 0x224);
int func_800E4FB0(void*, int, int);
void func_800E50A0(void*, int, int);
int func_800E4180(void*, int, int, int);
void func_800E4904(void*);

int func_800E24EC(targetMovementState* s, int option);


typedef struct {
    char prefix[0x4C];
    short x;
    short padding4E;
    short z;
    char padding52[6];
    psx_ptr(D_800F4538_t) actor;
    char padding5C[0x2C];
    u_char actorId;
    char padding89[0x31];
    u_short delay;
    char paddingBC[0x4C];
    int previousDestination;
    u_char pending;
    char padding10D[0x2D];
    u_short timer;
    char padding13C[0x2C];
    int destination;
    char padding16C[0x10];
    int targetX;
    int targetZ;
    char padding184[4];
    u_int padding188 : 16;
    int angle : 16;
    char padding18C[0x18];
    u_int targetFlags[17];
    char padding1E8[0x299];
    u_char reaction;
} movementDecisionContext;
PSX_ASSERT_SIZE(movementDecisionContext, 0x484);
int func_800E4180(void*, int, int, int);

int func_800E2B2C(movementDecisionContext* context, int targetId);


typedef struct {
    char pad0[8];
    unsigned int flags;
    char padC[8];
    short angle14;
    char pad16[0x10];
    short angle26;
} movementRecoveryContext;
struct movementRecoveryState {
    char pad0[9];
    unsigned char flag9;
    char padA[0x2A];
    vs_battle_movementPosition position;
    char pad38[0x14];
    short x;
    char pad4E[2];
    short z;
    char pad52[6];
    psx_ptr(movementRecoveryContext) context;
    char pad5C[0xDE];
    unsigned short timer, duration;
    char pad13E[0x1A];
    short targetX, targetZ;
    unsigned char targetActor;
    char pad15D;
    unsigned short flags;
    char pad160[0x28];
    unsigned short facing188, facing18A;
    char pad18C[0x9C];
    int counter;
};
PSX_ASSERT_SIZE(struct movementRecoveryState, 0x22c);
typedef struct {
    char pad0[0x1C];
    short x, y, z;
} movementActorPosition;
void func_800E4B10(void*);
int func_800E4320(int, int);
void func_800E2CCC(movementRecoveryState* state);


typedef union {
    u_int raw;
    struct {
        u_int unk0 : 1;
        u_int direction : 3;
        u_int clockwise : 1;
        u_int count : 7;
        u_int visited : 4;
        u_int stop : 1;
        u_int changed : 1;
        u_int cell : 4;
        u_int boundX : 5;
        u_int boundZ : 5;
    } bits;
} movementPath;

typedef struct {
    char unk0;
    u_char unk1;
    char unk2[2];
    u_char unk4;
    u_char unk5;
    char unk6[0x2E];
    vs_battle_movementPosition tile;
    char unk38[0x14];
    short x;
    char unk4E[2];
    short z;
    char unk52[0x92];
    u_char unkE4;
    char unkE5[2];
    u_char unkE7;
    u_char unkE8;
    char unkE9[0x75];
    u_short flags;
    char unk160[8];
    vs_battle_movementPosition destination;
    char unk16C[4];
    vs_battle_movementPosition next;
    char unk174[0x1C];
    movementPath path;
    char unk194[5];
    u_char unk199;
    u_char waitTimer;
} movementPathState;

typedef int (*movementPathTest)(movementPathState*, int);

int func_800D98E8(movementPathState*, int);
int func_800E3D5C(movementPathState*, movementPathTest);

int func_800E2F5C(movementPathState* state, movementPathTest test, int mask);


/* PC only: the decomp's closest non-matching C for func_800E3600
 * (rood-reverse .work/ultracode/r8-6E644-tail/e3600/vt10.c, score 20: one
 * register-allocation difference, same behaviour). */
typedef struct movementApproachState {
    char unk0[4];
    u_char unk4;
    char unk5[0x2F];
    vs_battle_movementPosition tile;
    char unk38[0x51];
    u_char unk89;
    char unk8A[0x28];
    u_char radius;
    char unkB3[0xA3];
    u_short timer;
    char unk158[0x10];
    vs_battle_movementPosition destination;
    char unk16C[4];
    vs_battle_movementPosition next;
    char unk174[0x14];
    short heading;
    char unk18A[6];
    u_int path;
} movementApproachState;
typedef int (*movementApproachTest)(movementApproachState*, int);
extern int (*D_800F1760[3][4])();
u_int func_800E49D8(movementApproachState*, u_int, int, int);
int func_800E47E4(movementApproachState*, u_int);
u_int func_800D8400(func_800D8400_t*, int, int, u_int);

void func_800E3600(func_800E0850_t* approach, int angleArg, int mode);


