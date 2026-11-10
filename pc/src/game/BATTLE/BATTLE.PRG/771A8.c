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
#include "ai_state.h"

int func_8008D2C0(func_8008D2C0_t*);
void func_800DEEFC(vs_battle_aiState*, int);
struct vs_battle_aiState;
int func_800E0678(struct vs_battle_aiState*, int);
struct vs_battle_aiState;
int func_800E0918(struct vs_battle_aiState*, int, int);
void func_800E2CCC(vs_battle_aiState*);
void func_800E3600(vs_battle_aiState*, int, int);
int func_800E42EC(int, int);
int func_800E4764(vs_battle_aiState*, int*, int*);
void func_800E4B18(vs_battle_aiState*);
void func_800E678C(vs_battle_aiState*);
extern D_800F58BC_t* D_800F58BC;
extern D_800F5910_t* D_800F5910;
void func_800D8260(vs_battle_aiState* arg0, int arg1, int arg2);

int func_800D96C8(vs_battle_aiState*, unsigned int, unsigned int, int);
int func_800D954C(vs_battle_aiState*, unsigned int);
unsigned int func_800E4660(int, int, int);
void func_800E50A0(void*, int, int);
int func_800E45D4(int);
void func_800E1388(vs_battle_aiState*, vs_battle_movementPosition, int, unsigned int);
int func_800E45D4(int);

void func_800DF9A8(func_800DFA54_t* arg0, func_800DFA54_t* arg1);

void func_800DFA54(int arg0, int arg1, int arg2, func_800DFA54_t* arg3);

int func_800DFAF8(int arg0, u_int arg1, int arg2);

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

static inline int routeSetArea(vs_battle_aiState* state, vs_battle_movementPosition position)
{
    state->area = routeTile(position.p.z, position.p.x) & 15;
    return 6;
}

int func_800DFBCC(vs_battle_aiState* state, int index, int area);

typedef struct {
    unsigned char p0, p1, tested, p3, result[8];
} obstructionCache;
#define OBSTRUCTION_CACHE ((obstructionCache*)0x1F8003D0)
#define OBSTRUCTION_DIRECTIONS ((D_800F16EC_t*)0x1F8003EC)
#define OBSTRUCTION_STATES(id) psx_slot_get(vs_battle_aiState*, 0x1F80037C, id)

int func_800E02B4(vs_battle_aiState* state, int direction, int ahead);

#undef OBSTRUCTION_CACHE
#undef OBSTRUCTION_DIRECTIONS
#undef OBSTRUCTION_STATES

int func_800E42EC(int, int);
typedef struct {
    unsigned char tested, valid;
} directionalCacheBits;
#define MOVEMENT_CHECK_CACHE ((directionalCacheBits*)0x1F8003D0)
#define MOVEMENT_CHECK_DIRECTIONS ((D_800F16EC_t*)0x1F8003EC)
#define MOVEMENT_CHECK_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))
int func_800E0678(vs_battle_aiState* state, int direction);

#undef MOVEMENT_CHECK_CACHE
#undef MOVEMENT_CHECK_DIRECTIONS
#undef MOVEMENT_CHECK_TILES

int func_800E0850(vs_battle_aiState* arg0, u_int arg1);

void func_800E4B2C();
void func_800E4B70();
unsigned int func_800E45F4(unsigned int, unsigned int);
int func_800E42E0(unsigned int);
void func_800E4B10(void*);
int func_800E0918(vs_battle_aiState* state, int action, int mode);

typedef struct {
    char pad0[0x1E];
    short y;
    char pad20[0x3C];
    directionalCachePoint tile;
    char pad60[0x5DE];
    unsigned short height;
} movementStepActor;
int func_800E02B4(vs_battle_aiState*, int, int);
int func_800E6A6C(int, int, int, int);
void func_800E1238(vs_battle_aiState*, int);
#define MOVEMENT_STEP_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))
#define MOVEMENT_STEP_RESULT (*(int*)0x1F8003C8)
void func_800E0A68(vs_battle_aiState* state, int action);

#undef MOVEMENT_STEP_TILES
#undef MOVEMENT_STEP_RESULT

void func_800E1238(vs_battle_aiState* arg0, int arg1);

void func_800E1388(vs_battle_aiState* state, vs_battle_movementPosition source, int angle, unsigned int distance);

unsigned int func_800E4660(int, int, int);
unsigned int func_800E45F4(unsigned int, unsigned int);
void func_800E4B2C(vs_battle_aiState*, int);
void func_800E153C(vs_battle_aiState* state, int unused);

void func_800E1764(vs_battle_aiState* state, int angle);

u_char func_800E1850(u_char arg0, u_int arg1, int arg2);

#define TERRAIN_TILE_MASK (psx_slot_get(unsigned char*, 0x1F8003C4, 0))
#define TERRAIN_MAP_WIDTH (*(unsigned char*)0x1F8003DC)
#define TERRAIN_MOVE_RESULT (*(int*)0x1F8003C8)
#define TERRAIN_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))
struct vs_battle_aiState;
int func_800DFBCC(struct vs_battle_aiState*, int, int);
void func_800E4BB8(vs_battle_aiState*);
void func_800E4B70(vs_battle_aiState*, int);
void func_800E1908(vs_battle_aiState* state);

void func_800E19FC(vs_battle_aiState* state);

#undef TERRAIN_TILE_MASK
#undef TERRAIN_MAP_WIDTH
#undef TERRAIN_MOVE_RESULT
#undef TERRAIN_TILES

#define WANDER_DIRECTIONS ((D_800F16EC_t*)0x1F8003EC)
#define WANDER_TILES (psx_slot_get(__typeof__(unsigned short(*)[32]), 0x1F8003C0, 0))

int func_800E4690(unsigned int, int);
int D_800D9B6C(vs_battle_aiState*, int);

static inline D_800F16EC_t* wanderDirection(int index)
{
    return WANDER_DIRECTIONS + index;
}

int func_800E1BB8(vs_battle_aiState* state, unsigned int tile, unsigned int maxCount, int arg3);

static inline int wanderRandomHeading(int direction)
{
    int offset = func_800E45D4(512);
    int angle = direction << 9;
    offset += 0xFF00;
    return angle + offset;
}

static inline void wanderStartWalk(vs_battle_aiState* s)
{
    s->angle = -1;
    s->count = 0;
    s->cooldown = 60;
    s->mode++;
    func_800E2CCC((vs_battle_aiState*)s);
}

void func_800E1EAC(vs_battle_aiState* state, unsigned int tile, unsigned int range);

#undef WANDER_DIRECTIONS
#undef WANDER_TILES

extern unsigned short (*D_800F58D8)[8];
void func_800E50A0(void*, int, int);
static inline unsigned int patrolWaypoint(unsigned short* row, int index)
{
    unsigned short* ptr = row;
    ptr += index;
    return *ptr;
}
void func_800E23AC(vs_battle_aiState* state);

int func_800E4FB0(void*, int, int);
void func_800E50A0(void*, int, int);
int func_800E4180(void*, int, int, int);
void func_800E4904(void*);

int func_800E24EC(vs_battle_aiState* s, int option);

int func_800E4180(void*, int, int, int);

int func_800E2B2C(vs_battle_aiState* context, int targetId);

typedef struct {
    char pad0[0x1C];
    short x, y, z;
} movementActorPosition;
void func_800E4B10(void*);
int func_800E4320(int, int);
void func_800E2CCC(vs_battle_aiState* state);

typedef int (*movementPathTest)(vs_battle_aiState*, int);

int func_800D98E8(vs_battle_aiState*, int);
int func_800E3D5C(vs_battle_aiState*, movementPathTest);

int func_800E2F5C(vs_battle_aiState* state, movementPathTest test, int mask);

typedef int (*movementApproachTest)(vs_battle_aiState*, int);
extern int (*D_800F1760[3][4])();
u_int func_800E49D8(vs_battle_aiState*, u_int, int, int);
int func_800E47E4(vs_battle_aiState*, u_int);
u_int func_800D8400(vs_battle_aiState*, int, int, u_int);

void func_800E3600(vs_battle_aiState* approach, int angleArg, int mode);

