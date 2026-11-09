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

void func_800D82CC(vs_battle_aiState*);
void func_800D836C(vs_battle_aiState*);
int func_800DBCB4(vs_battle_aiState*, func_800E78F4_t2*);
void func_800DEEFC(vs_battle_aiState*, int);
void func_800E2CCC(vs_battle_aiState*);
int func_800E7698(vs_battle_aiState*);
void func_800E7960(vs_battle_aiState*);
extern D_800F58BC_t* D_800F58BC;
extern int D_800F5918;
extern int D_800F591C;
extern D_800F5920_t* D_800F5920;

unsigned int func_800E4660(int, int, int);

int func_800D826C(vs_battle_aiState*);
unsigned int func_800E4660(int, int, int);

extern unsigned int D_80069C1C[];
extern unsigned char D_800F17D8[], D_80069C18[];
extern actorSettingsEntry D_80069C3C[];
int func_800E7F8C(vs_battle_aiState*);

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
int func_800E7698(vs_battle_aiState* state);

int func_800E78F4(vs_battle_aiState* arg0);

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
void func_800E7960(vs_battle_aiState* state);

int func_800E7F8C(vs_battle_aiState* arg0);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/7EE98", D_80069C18);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/7EE98", D_80069C1C);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/7EE98", D_80069C3C);
