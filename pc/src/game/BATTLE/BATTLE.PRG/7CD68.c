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

short func_8008DC7C(int, int);
void func_800DEEFC(vs_battle_aiState*, int);
void func_800E5EC0(int, int, int);
extern D_800F16EC_t D_800F16EC[8];
extern vs_battle_aiState* D_800F5878[];
extern u_short (*D_800F58B8)[32];
extern D_800F58BC_t* D_800F58BC;
extern u_short (*D_800F58D0)[32];
extern unsigned short* D_800F58C8;
void func_800E4288(void*, int);
int func_800DEC88(void* arg0);

int func_800E5568(func_800E5568_t* arg0);

int func_800E5600(int arg0, int actionId, u_int arg2);

int func_800E5698(vs_battle_aiState* arg0, int actionId);

typedef union {
    unsigned int raw;
    unsigned char bytes[4];
} actionMetadataWord;
typedef struct {
    actionMetadataWord flags;
    char pad[8];
    unsigned int flagsC;
    char rest[36];
} actionMetadataAction;
void func_800E5998(void);

void func_800E5A74(int* arg0, func_800E5A74_t* arg1);

typedef int actorSettingsCallback(vs_battle_aiState*);
extern unsigned int D_80069C1C[];
extern unsigned short D_800F17B8[][2], D_800F17C8[][2];
extern unsigned char D_800F17D8[], D_80069C18[];
extern actorSettingsEntry D_80069C3C[];
extern int D_800F58C0;
extern unsigned short* D_800F58C8;
extern int (*D_800F1790[])(vs_battle_aiState*);
const unsigned char D_80069C08[4] = { 9, 7, 0, 0 };
int func_800E7F8C(vs_battle_aiState*);
void func_800E7660(vs_battle_aiState*);
void func_800E5998(void);

void func_800E5A9C(vs_battle_aiState* state, actorSettingsWord* settings);

void func_800E5EC0(int arg0, int arg1, int arg2);

int func_800E5FDC(int arg0, int arg1);

void func_800E6098(void);

void func_800E6F9C(void);

void func_800E6158(void);

extern int D_800F590C;
void func_800A190C(unsigned char, int, void*, int);
int func_800A152C(int, int, int);

void func_800E4288(void*, int);
void func_800E6828(vs_battle_aiState*);

void func_800E7370(vs_battle_aiState*);
void func_800E72D0(void);

int func_800E6178(actorInitializationActor* actor, int options);

