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
void func_800E2CCC(vs_battle_aiState*);
void func_800E4CE8(vs_battle_aiState* arg0);
extern vs_battle_aiState* D_800F5878[];
extern D_800F58BC_t* D_800F58BC;

int func_800D96C8(vs_battle_aiState*, unsigned int, unsigned int, int);
int func_800D954C(vs_battle_aiState*, unsigned int);
unsigned int func_800DB93C(vs_battle_aiState*, unsigned int, int, unsigned int);
unsigned int func_800D8400( vs_battle_aiState* state, int first, int second, unsigned int direction);

int func_800E4CF4(vs_battle_aiState*, actionCandidateEntry*, int);
int func_800E4DF8(vs_battle_aiState*, int, int);
void func_800D9DD8(vs_battle_aiState*);
int func_800D85D8(vs_battle_aiState* state);

int func_800E4624(short*, short*, int, int);
int func_800E44E8(SVECTOR*, SVECTOR*, int, int);
int func_800E437C(SVECTOR*, SVECTOR*, int, u_int);

#define RELATION_STATES(id) psx_slot_get(vs_battle_aiState*, 0x1F80037C, id)

static inline int checkExtent(
    SVECTOR* from, SVECTOR* to, vs_battle_aiState* state, int id)
{
    vs_battle_aiState* other = RELATION_STATES(id);
    int extent;

    if (other) {
        extent = other->extent;
    } else {
        extent = 128;
    }
    return func_800E44E8(from, to, extent, state->extent);
}

static inline int checkHeight(
    SVECTOR* from, SVECTOR* to, vs_battle_aiState* state, int id)
{
    vs_battle_aiState* other = RELATION_STATES(id);
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

void func_800D87E8(vs_battle_aiState* state, int id);

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

static inline int historyRepeats(vs_battle_aiState* state)
{
    return state->historyX.w[0] == state->historyX.w[1]
        && state->historyZ.w[0] == state->historyZ.w[1];
}

static inline int historyStalled(vs_battle_aiState* state)
{
    return state->historyMask == 0xFF ? historyRepeats(state) : 0;
}

extern int D_800F58D4;
extern int D_800F58E0;
extern int D_800F16F4;
struct vs_battle_aiState;
struct vs_battle_aiState;
void func_800D821C(struct vs_battle_aiState*);
void func_800DBF00(vs_battle_aiState*);
void func_800DBFE4(struct vs_battle_aiState*);
void func_800E4F14(void*);
void func_800D8280(vs_battle_aiState*);
void func_800E4358(vs_battle_aiState*);
void func_800E48F8(vs_battle_aiState*);
void func_800E48A8(vs_battle_aiState*, int, int);

void func_800D8EF4(void);

extern int D_800F58C4;

void func_800D9538(void);

