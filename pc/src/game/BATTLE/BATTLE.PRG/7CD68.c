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

short func_8008DC7C(int, int);
void func_800DEEFC(func_800E0850_t*, int);
void func_800E5EC0(int, int, int);
extern D_800F16EC_t D_800F16EC[8];
extern func_800DEEA4_t2* D_800F5878[];
extern u_short (*D_800F58B8)[32];
extern D_800F58BC_t* D_800F58BC;
extern u_short (*D_800F58D0)[32];
extern unsigned short* D_800F58C8;
void func_800E4288(void*, int);
int func_800DEC88(void* arg0);

int func_800E5568(func_800E5568_t* arg0);

int func_800E5600(int arg0, int actionId, u_int arg2);

int func_800E5698(func_800E5698_t* arg0, int actionId);

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
typedef struct {
    unsigned short id, pad;
} actionMetadataSlot;
typedef struct {
    char pad[0x8C0];
    actionMetadataSlot slots[6][4];
} actionMetadataStats;
typedef struct {
    unsigned int f0 : 1, f1 : 1, f2 : 1, kind : 2, longRange : 1, special : 1, f7 : 1,
        radius : 16, high : 8;
    unsigned int rangeSquared;
} actionMetadataEntry;
typedef struct {
    char pad0[0x17];
    unsigned char maxActionCost;
    char pad18[0x44];
    psx_ptr(actionMetadataStats) stats;
    char pad60[0x28];
    unsigned char id;
    char pad89[0x1A7];
    actionMetadataEntry entries[6][4];
} actionMetadataState;
PSX_ASSERT_SIZE(actionMetadataState, 0x2f0);
void func_800E5998(void);

void func_800E5A74(int* arg0, func_800E5A74_t* arg1);

typedef union {
    unsigned int raw;
    unsigned short half[2];
    unsigned char byte[4];
} actorSettingsWord;
typedef struct actorSettingsActor {
    char pad0[26];
    unsigned short kind;
    char pad1C[20];
    actorSettingsWord flags;
    union {
        unsigned int raw;
        struct {
            unsigned int low : 12, mode : 2, high : 18;
        } bits;
    } flags34;
} actorSettingsActor;
typedef int actorSettingsCallback(func_800E78F4_t*);
typedef struct actorSettingsState {
    char pad0[22];
    unsigned char f16;
    char pad17[2];
    unsigned char f19;
    char pad1A[6];
    unsigned char f20;
    unsigned char f21;
    unsigned char f22;
    unsigned char f23;
    unsigned char f24;
    unsigned char f25;
    unsigned char f26;
    unsigned char f27;
    unsigned char f28;
    unsigned char f29;
    unsigned char f2A;
    unsigned char f2B;
    unsigned char f2C;
    unsigned char f2D;
    unsigned char f2E;
    unsigned char f2F;
    unsigned char f30;
    unsigned char f31;
    unsigned char f32;
    unsigned char f33;
    char pad34[32];
    psx_ptr(actorSettingsActor) actor;
    char pad58[16];
    psx_ptr(actorSettingsCallback) callback;
    char pad6C[40];
    unsigned short collisionRadius;
    char pad96[14];
    unsigned int limit;
    int cosine;
    unsigned int rangeSquared;
    unsigned short fB0;
    unsigned char fB2;
    char padB3[7];
    unsigned short fBA;
    char padBC[12];
    unsigned int fC8;
    unsigned char fCC;
    char padCD[1];
    unsigned char fCE;
    char padCF[5];
    unsigned short fD4;
    unsigned short fD6;
    unsigned char fD8;
    char padD9[40];
    unsigned char f101;
    unsigned char f102;
    char pad103[37];
    unsigned short angle;
    char pad12A[52];
    unsigned short flags;
} actorSettingsState;
PSX_ASSERT_SIZE(struct actorSettingsState, 0x160);
extern unsigned int D_80069C1C[];
extern unsigned short D_800F17B8[][2], D_800F17C8[][2];
extern unsigned char D_800F17D8[], D_80069C18[];
extern actorSettingsEntry D_80069C3C[];
extern int D_800F58C0;
extern unsigned short* D_800F58C8;
extern int (*D_800F1790[])(func_800E78F4_t*);
const unsigned char D_80069C08[4] = { 9, 7, 0, 0 };
int func_800E7F8C(func_800E78F4_t*);
void func_800E7660(actorSettingsState*);
void func_800E5998(void);

void func_800E5A9C(actorSettingsState* state, actorSettingsWord* settings);

void func_800E5EC0(int arg0, int arg1, int arg2);

int func_800E5FDC(int arg0, int arg1);

void func_800E6098(void);

void func_800E6F9C(void);

void func_800E6158(void);

extern int D_800F590C;
void func_800A190C(unsigned char, int, void*, int);
int func_800A152C(int, int, int);
typedef union {
    unsigned int raw;
    struct {
        unsigned char b0, b1, b2, b3;
    } bytes;
    struct {
        unsigned int low : 24, f24 : 2, f26 : 2, high : 4;
    } bits;
} actorInitializationFlags;
typedef union {
    unsigned int raw;
    struct {
        unsigned char x, y, z, w;
    } p;
} actorInitializationPoint;
typedef struct actorInitializationStats {
    char pad0[48];
    unsigned char field30;
    unsigned char field31;
    unsigned char field32;
    unsigned char field33;
} actorInitializationStats;
typedef struct actorInitializationModel {
    char pad0[8];
    unsigned int flags;
    char padC[16];
    short position[3];
    char pad22[58];
    actorInitializationPoint tile;
    char pad60[268];
    unsigned int kind;
    char pad170[1228];
    unsigned short radius;
    unsigned short field63E;
} actorInitializationModel;
typedef struct actorInitializationActor {
    char pad0[4];
    int id;
    actorInitializationFlags flags;
    char padC[16];
    unsigned short attributes;
    char pad1E[1];
    unsigned char field1F;
    char pad20[16];
    int field30;
    unsigned int field34;
    int field38;
    psx_ptr(actorInitializationStats) stats;
    int field40;
    psx_ptr(actorInitializationModel) model;
} actorInitializationActor;
PSX_ASSERT_SIZE(struct actorInitializationActor, 0x48);
typedef struct actorInitializationState {
    char pad0[42];
    unsigned char field2A;
    char pad2B[9];
    int tile;
    int previous;
    char pad3C[6];
    short options;
    char pad44[16];
    psx_ptr(actorInitializationActor) actor;
    psx_ptr(actorInitializationModel) model;
    psx_ptr(actorInitializationStats) stats;
    psx_ptr(short) position;
    psx_ptr(unsigned int) tilePointer;
    char pad68[26];
    unsigned short field82;
    char pad84[4];
    unsigned char id;
    unsigned char field89;
    unsigned char field8A;
    char pad8B[7];
    unsigned short radius;
    unsigned short collisionRadius;
    char pad96[6];
    int field9C;
    char padA0[12];
    unsigned int rangeSquared;
    char padB0[3];
    unsigned char maxRange;
    int distance;
    unsigned short fieldB8;
    char padBA[2];
    short fieldBC;
    short fieldBE;
    char padC0[67];
    unsigned char field103;
    char pad104[12];
    int field110;
    char pad114[16];
    unsigned char field124;
    char pad125[8];
    unsigned char field12D;
    char pad12E[14];
    unsigned short stepHeight;
    char pad13E[32];
    unsigned short flags;
    char pad160[16];
    int next;
    char pad174[16];
    int targetY;
    char pad188[12];
    int field194;
    char pad198[140];
    unsigned char field224;
    unsigned char field225;
    unsigned char field226;
    unsigned char field227;
} actorInitializationState;
PSX_ASSERT_SIZE(struct actorInitializationState, 0x228);

void func_800E4288(void*, int);
void func_800E6828(actorInitializationState*);

void func_800E7370(actorInitializationState*);
void func_800E72D0(void);

int func_800E6178(actorInitializationActor* actor, int options);

