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
void func_800E4CE8(vs_battle_aiState* arg0);
void func_800E678C(vs_battle_aiState*);
extern vs_battle_aiState* D_800F5878[];
extern D_800F58BC_t* D_800F58BC;
extern D_800F5920_t* D_800F5920;
void func_800D8260(vs_battle_aiState* arg0, int arg1, int arg2);

int func_800D954C(vs_battle_aiState*, unsigned int);

int func_800E4624(short*, short*, int, int);
extern int D_800F58E0;
extern int D_800F16F4;

int func_800DB8AC(vs_battle_aiState*, actionCandidateEntry*);
int func_800E42D4(int, int);
int func_800E4624(short*, short*, int, int);
unsigned int func_800E4660(int, int, int);
void func_800DB5B8(vs_battle_aiState*, unsigned int, int);
void func_800DB5DC(vs_battle_aiState*, unsigned int, int);
int func_800DB61C(vs_battle_aiState*, int);
int func_800DB370(vs_battle_aiState*, int, int, int);
int func_800DB74C(vs_battle_aiState*, int);
int func_800D9E18(vs_battle_aiState* state, actionCandidateEntry* entry);

int func_800DB370(vs_battle_aiState*, int, int, int);
int func_800DB74C(vs_battle_aiState*, int);
int func_800DA1D4(vs_battle_aiState* state);

typedef union {
    unsigned int raw;
    unsigned char b[4];
} da4bcPoint;

typedef struct {
    char pad0[28];
    short x;
    char pad1E[2];
    short z;
    char pad22[58];
    vs_battle_movementPosition tile;
} da4bcModel;

typedef struct da4bcActor {
    psx_ptr(struct da4bcActor) next;
    int id;
} da4bcActor;
PSX_ASSERT_SIZE(struct da4bcActor, 0x8);

typedef struct {
    unsigned int target : 4, pad : 28;
} da4bcEntryTarget;

int func_800DBB2C(void*, void*, int);
void func_800DB5B0(void*);
void func_800DB5FC(void*);
void func_800E50A0(void*, int, int);
int func_800E45D4(int);
void func_800E1388(vs_battle_aiState*, vs_battle_movementPosition, int, unsigned int);

int func_800DA4BC(vs_battle_aiState* state, da4bcEntry* entry);

int func_800DAA6C(vs_battle_aiState* state);

int func_800DBD80(vs_battle_aiState*, func_800DCAA0_t*);
int func_800D826C(vs_battle_aiState*);
int func_800DBC60(vs_battle_aiState*, func_800DCAA0_t*);
int func_800E45D4(int);
extern int D_800F58E0;

int func_800DAC80(vs_battle_aiState* context, func_800DCAA0_t* action);

typedef struct actionDispatchModel {
    char pad0[8];
    unsigned int flags;
    char padC[6];
    unsigned char id;
    char pad13[7];
    short status;
    short position[3];
} actionDispatchModel;
typedef struct actionDispatchActor {
    psx_ptr(struct actionDispatchActor) next;
    int id;
    char pad8[0x3C];
    psx_ptr(actionDispatchModel) model;
} actionDispatchActor;
PSX_ASSERT_SIZE(struct actionDispatchActor, 0x48);
typedef struct {
    char pad[0x28];
    psx_ptr(actionDispatchActor) registered[4];
} actionDispatchRegistry;
PSX_ASSERT_SIZE(actionDispatchRegistry, 0x38);
extern int D_800F16F4;
void func_800DB820(vs_battle_aiState*);
void func_800DB7B4(vs_battle_aiState*);
int func_800DAD9C(vs_battle_aiState* state);

void func_800DAED0(void);

int func_800DB0BC(vs_battle_aiState* state);

