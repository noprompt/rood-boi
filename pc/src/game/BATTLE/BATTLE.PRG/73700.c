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
void func_800E4C8C(func_800DEEA4_t2*);
extern D_800F58BC_t* D_800F58BC;
struct actorTimerState;
void func_800DBF00(func_800E78F4_t*);
void func_800DBFE4(struct actorTimerState*);

void func_800DBF00(func_800E78F4_t* arg0);

typedef struct {
    char pad[8];
    unsigned int low : 26, mode : 2, high : 4;
} actorPhaseFlags;
typedef struct actorTimerState {
    char pad0[0x54];
    psx_ptr(actorPhaseFlags) actor;
    char pad58[0x30];
    unsigned char id;
    char pad89[5];
    unsigned short timer8E;
    char pad90[8];
    unsigned short timer98, timer9A;
    char pad9C[0x93];
    signed char phase, direction;
    char pad131[0x6F];
    psx_ptr(struct actorTimerState) next;
    unsigned char targetFlags;
} actorTimerState;
PSX_ASSERT_SIZE(struct actorTimerState, 0x1a8);
void func_800D820C(int, int);
void func_800DBFE4(actorTimerState* state);

void func_800DC0D0(void);

