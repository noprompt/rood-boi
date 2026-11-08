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

void func_800D82CC(func_800E78F4_t*);
void func_800D836C(func_800E78F4_t*);
int func_800DBCB4(func_800E78F4_t*, func_800E78F4_t2*);
void func_800DEEFC(func_800E0850_t*, int);
typedef struct movementRecoveryState movementRecoveryState;
void func_800E2CCC(movementRecoveryState*);
typedef struct radialMotionState radialMotionState;
int func_800E7698(radialMotionState*);
typedef struct trackingMotionState trackingMotionState;
void func_800E7960(trackingMotionState*);
extern D_800F58BC_t* D_800F58BC;
extern int D_800F5918;
extern int D_800F591C;
extern D_800F5920_t* D_800F5920;

unsigned int func_800E4660(int, int, int);

int func_800D826C(actionSetupContext*);
unsigned int func_800E4660(int, int, int);

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
extern unsigned int D_80069C1C[];
extern unsigned char D_800F17D8[], D_80069C18[];
extern actorSettingsEntry D_80069C3C[];
int func_800E7F8C(func_800E78F4_t*);

typedef struct {
    char pad[0x5B0];
    unsigned int a : 4, active : 1, b : 27;
} radialMotionContext;
struct radialMotionState {
    char pad[0x4C];
    short x, y, z;
    char pad52[6];
    psx_ptr(radialMotionContext) context;
    char pad5C[0x120];
    int targetX, targetZ, targetY;
    char pad188[0x2E8];
    int field470;
};
PSX_ASSERT_SIZE(struct radialMotionState, 0x474);
typedef struct {
    short facing;
    unsigned char state, flag3;
    char pad4[6];
    unsigned char flagA, frame;
    char padC[4];
    short angle;
    char pad12[6];
    short x, z;
} radialMotion;
typedef struct {
    char pad[8];
    unsigned int flags;
} radialMotionActor;
extern short D_800F17DC[][2];
unsigned int func_800E4660(int, int, int);
int func_800E7698(radialMotionState* state);

int func_800E78F4(func_800E78F4_t* arg0);

typedef struct {
    char pad[0x18];
    short current, maximum;
} trackingMotionStats;
struct trackingMotionState {
    char pad[0x4C];
    short x, y, z;
    char pad52[6];
    psx_ptr(radialMotionContext) context;
    psx_ptr(trackingMotionStats) stats;
    char pad60[0xFC];
    unsigned char targetActor;
    char pad15D[0x1F];
    int targetX, targetZ, targetY;
};
PSX_ASSERT_SIZE(struct trackingMotionState, 0x188);
typedef struct {
    unsigned short facing;
    unsigned char state, flag3;
    int radiusSquared;
    char pad8[4];
    short stateC, stateE, angle, height;
    unsigned char phase;
    char pad15[7];
    unsigned char initialized;
} trackingMotion;
typedef struct {
    char pad[0x1C];
    short x, y, z;
} trackingMotionActor;
int rand(void);
int vs_gte_rsqrt(int);
unsigned int func_800E4660(int, int, int);
void func_800E7960(trackingMotionState* state);

int func_800E7F8C(func_800E78F4_t* arg0);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/7EE98", D_80069C18);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/7EE98", D_80069C1C);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/7EE98", D_80069C3C);
