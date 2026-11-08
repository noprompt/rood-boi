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
    char unk0[0xA];
    u_char unkA;
    char unkB;
    short unkC;
    short unkE;
    char unk10[2];
    u_short unk12;
    char unk14[2];
    u_char unk16;
    u_char unk17;
    char unk18[4];
    u_char unk1C;
} D_800F5920_t;

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
void func_800D82CC(func_800E78F4_t*);
void func_800D836C(func_800E78F4_t*);
int func_800DBCB4(func_800E78F4_t*, func_800E78F4_t2*);
void func_800DEEFC(func_800E0850_t*, int);
typedef struct movementRecoveryState movementRecoveryState;
void func_800E2CCC(movementRecoveryState*);
void func_800E4CE8(func_800DEEA4_t2* arg0);
void func_800E678C(func_800E0850_t*);
extern func_800DEEA4_t2* D_800F5878[];
extern D_800F58BC_t* D_800F58BC;
extern D_800F5920_t* D_800F5920;
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
int func_800D954C(func_800D8400_t*, unsigned int);

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

int func_800E4624(short*, short*, int, int);
extern int D_800F58E0;
extern int D_800F16F4;

typedef union {
    unsigned int raw;
    unsigned char bytes[4];
} candidateMovementWord;
typedef struct candidateMovementState {
    char pad0[1];
    unsigned char f1;
    char pad2[74];
    short position[3];
    char pad52[48];
    short height;
    char pad84[47];
    unsigned char maxRange;
    char padB4[122];
    unsigned char mode;
    char pad12F[5];
    candidateMovementWord destination;
    char pad138[36];
    unsigned char target;
    char pad15D[1];
    unsigned short flags;
    char pad160[8];
    candidateMovementWord next;
    char pad16C[56];
    candidateMovementWord targets[16];
    unsigned int distances[16];
    char pad224[588];
    int count;
} candidateMovementState;
int func_800DB8AC(candidateMovementState*, actionCandidateEntry*);
int func_800E42D4(int, int);
int func_800E4624(short*, short*, int, int);
unsigned int func_800E4660(int, int, int);
void func_800DB5B8(candidateMovementState*, unsigned int, int);
void func_800DB5DC(candidateMovementState*, unsigned int, int);
int func_800DB61C(candidateMovementState*, int);
int func_800DB370(actionCandidateState*, int, int, int);
int func_800DB74C(actionCandidateState*, int);
int func_800D9E18(candidateMovementState* state, actionCandidateEntry* entry);


int func_800DB370(actionCandidateState*, int, int, int);
int func_800DB74C(actionCandidateState*, int);
int func_800DA1D4(actionCandidateState* state);


typedef struct {
    unsigned int unk0, unk4, distance, flagsC;
} da4bcEntry;

typedef struct {
    char pad0[14];
    unsigned char flagE, flagF;
    char pad10[6];
    signed int target16 : 8;
    char pad17;
    unsigned char flag18;
    char pad19[27];
    unsigned int tile;
    char pad38[12];
    unsigned char timer44;
    char pad45[7];
    short x;
    char pad4E[2];
    short z;
    char pad52[54];
    unsigned char id;
    char pad89[42];
    unsigned char radius;
    char padB4[53];
    unsigned char mode;
    char padEA[68];
    unsigned char action;
    char pad12F[2];
    unsigned char pending;
    char pad132[42];
    unsigned char target15C;
    char pad15D[71];
    unsigned int targets[16];
    unsigned int distances[16];
    char pad224[524];
    psx_ptr(da4bcEntry) entries[16];
} da4bcState;
PSX_ASSERT_SIZE(da4bcState, 0x470);

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

typedef struct {
    unsigned int pad0 : 6, mode : 2, pad8 : 12, category : 7, pad27 : 1, oldMode : 2,
        pad30 : 2;
} da4bcTargetBits;

typedef struct {
    char pad[0x1A4];
    da4bcTargetBits targets[16];
} da4bcTargetState;

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
void func_800E1388(func_800D8400_t*, vs_battle_movementPosition, int, unsigned int);

int func_800DA4BC(da4bcState* state, da4bcEntry* entry);

int func_800DAA6C(da4bcState* state);

typedef struct {
    char prefix[0x13];
    u_char kind;
    char gap[0x12B];
    u_char cooldown;
    char gap2[0xEC];
    psx_ptr(func_800DCAA0_t) action;
} actionSetupContext;
PSX_ASSERT_SIZE(actionSetupContext, 0x230);
int func_800DBD80(actionSetupContext*, func_800DCAA0_t*);
int func_800D826C(actionSetupContext*);
int func_800DBC60(actionSetupContext*, func_800DCAA0_t*);
int func_800E45D4(int);
extern int D_800F58E0;

int func_800DAC80(actionSetupContext* context, func_800DCAA0_t* action);


typedef struct {
    unsigned int pad0, flags4, distance, flagsC;
} actionDispatchEntry;
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
typedef struct actionDispatchState {
    unsigned int flags0, flags4, flags8;
    unsigned short flagsC, padE;
    char pad10[4];
    unsigned char f14;
    char pad15[8];
    unsigned char f1D;
    char pad1E[0x16];
    unsigned char tileX, pad35, tileZ;
    char pad37[0x11];
    int target48;
    short position[3];
    char pad52[0x30];
    short height;
    char pad84[0x34];
    short depth;
    char padBA[0x78];
    signed char terrain132;
    char pad133[0xD];
    actionDispatchEntry fallback;
    char pad150[4];
    signed char terrain154;
    char pad155[7];
    unsigned char target;
    char pad15D[0x87];
    unsigned int distance;
    char pad1E8[0x248];
    psx_ptr(actionDispatchEntry) entries[16];
    int count;
} actionDispatchState;
PSX_ASSERT_SIZE(struct actionDispatchState, 0x474);
typedef struct {
    char pad[0x28];
    psx_ptr(actionDispatchActor) registered[4];
} actionDispatchRegistry;
PSX_ASSERT_SIZE(actionDispatchRegistry, 0x38);
extern int D_800F16F4;
void func_800DB820(actionDispatchState*);
void func_800DB7B4(actionDispatchState*);
int func_800DAD9C(actionDispatchState* state);

void func_800DAED0(void);


typedef union {
    u_int raw;
    struct {
        u_char x, y, z, status;
    } p;
} stuckMovementPosition;

typedef struct {
    char unk0[2];
    u_char stuck;
    char unk3[0x19];
    u_char unk1C;
    char unk1D[0x17];
    stuckMovementPosition position;
    stuckMovementPosition previous;
    char unk3C[0x10];
    short x;
    char unk4E[2];
    short z;
    char unk52[0xA8];
    u_char detourStep;
    u_char unkFB;
    char unkFC[0x1C];
    u_char detourDirections[4];
    char unk11C[0x40];
    u_char unk15C;
    char unk15D[0xB];
    stuckMovementPosition destination;
} stuckMovementState;

int func_800DB0BC(stuckMovementState* state);

