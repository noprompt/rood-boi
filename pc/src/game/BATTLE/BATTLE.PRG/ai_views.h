#pragma once
#include "146C.h"
#include "3A1A0.h"
#include <libgte.h>
#include "pc/src/psx_types.h"

/* The AI's views of the actor records, shared by the units that read them. */

typedef struct {
    int unk0;
    u_short unk4;
} func_800E5A74_t;

typedef struct {
    char rangeX;
    char rangeY;
    char rangeZ;
    u_char shape : 3;
    u_char angle : 5;
} func_800E5568_t;

typedef struct {
    char unk0[0x38];
    func_800E5568_t unk38;
} func_800E5698_t2;

typedef struct {
    char unk0[0x5C];
    psx_ptr(func_800E5698_t2) unk5C;
} func_800E5698_t;
PSX_ASSERT_SIZE(func_800E5698_t, 0x60);

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
PSX_ASSERT_SIZE(func_800DEB10_t2, 0x40);

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
PSX_ASSERT_SIZE(struct func_800E78F4_t, 0x474);

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
PSX_ASSERT_SIZE(D_800F58BC_t, 0x28);

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
PSX_ASSERT_SIZE(func_800E0850_t, 0x22c);

typedef struct {
    char unk0[0x88];
    u_char unk88;
} func_800DCAA0_t1;

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
    u_char unk0;
    char unk1;
    u_char unk2;
    char unk3[0x3D];
    int unk40;
} func_800DEB10_t;

typedef struct {
    u_short unk0;
    char unk2[2];
    u_char unk4;
    char unk5[0x3F];
    int unk44;
    char unk48[2];
    u_short unk4A;
    func_800DEB10_t unk4C[0];
} func_800DEEA4_t;

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
PSX_ASSERT_SIZE(func_800DEEA4_t2, 0x474);

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

typedef struct {
    char prefix[0x13];
    u_char kind;
    char gap[0x12B];
    u_char cooldown;
    char gap2[0xEC];
    psx_ptr(func_800DCAA0_t) action;
} actionSetupContext;
PSX_ASSERT_SIZE(actionSetupContext, 0x230);

typedef struct {
    char pad0[8];
    unsigned int flags;
    char padC[8];
    short angle14;
    char pad16[0x10];
    short angle26;
} movementRecoveryContext;

typedef struct {
    unsigned short first, second;
    unsigned char third, pad;
} actorSettingsEntry;

