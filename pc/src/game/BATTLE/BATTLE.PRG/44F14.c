#include "common.h"
#include <rand.h>
#include <abs.h>
#include <inline_c.h>
#include "vs_inline_c.h"
#include "146C.h"
#include "3A1A0.h"
#include "44F14.h"
#include "../../SLUS_010.40/main.h"
#include "pc/src/psx_types.h"

void func_8008EB04(int*, int*);
int func_800A91DC(int, int, int);
/* Returns the animation record's guest address as an int (40564.c). */
int func_800AD494(D_800F4538_t*, u_char, u_short**);
void func_800AF844(SVECTOR*, SVECTOR*, int);
void func_800B147C(D_800F4538_unkC54*, D_800F4538_unkC54*, int, int, int);

extern u_char D_800E91A4[];
extern u_char D_800E9278[];

void func_800AB358(int index, u_char* arg);
void func_800A41D0(D_800F4538_t* actor, int mode);
void func_800AE6C0(D_800F4538_t*, int, int);
int func_800A1280(int, int, SVECTOR*, int);
void func_800AE828(int arg0, D_800F4538_t* arg1, int arg2);
void func_800AD008(void*, void*);
int func_800CEF74(int);
int func_800AAD4C(int, int, int, int);
void func_800AE46C();
void func_800AE474();
void func_800AC440(D_800F4538_t* arg0, int arg1, int arg2);
void func_800CF8BC(void);
short func_800BEB00(void);
extern u_char D_800E9298[];
extern u_char D_800E92DC[];
extern int D_800F1868;
extern u_short D_800E9A28[][4];

int func_800AD714(D_800F4538_t* actor, D_800F4538_unkC54* state, int mode);

void func_800AE46C(void);

void func_800AE474(void);

void func_800AE47C(D_800F4538_t* arg0);

void func_800AE4FC(D_800F4538_unk0* arg0, int arg1);

void func_800AE68C(int arg0, int arg1);

void func_800AE6C0(D_800F4538_t* arg0, int arg1, int arg2);

void func_800AE7D8(void* arg0, int arg1, int arg2);

void func_800AE828(int arg0, D_800F4538_t* arg1, int arg2);

void func_800AE980(D_800F4538_unkC54* dst, D_800F4538_unkC54* src, int count);


typedef struct {
    char prefix[0x3A];
    u_short angleX, angleY;
    char padding[0x16];
    SVECTOR offset;
    char padding2[8];
    MATRIX matrix;
    SVECTOR rotation;
} actorTransformScratch;
extern struct {
    char prefix[0x1FD0];
    int scales[3];
} D_800F2458;
void func_800B07DC(D_800F4538_t*);

void func_800AEAE8(D_800F4538_t* actor);


extern MATRIX D_8005E218;
extern MATRIX D_800F4910;
extern MATRIX D_800F49B8;

/* The block-scope static of the original function: the Zig reaches this storage through the views
 * (battle_statics.py, STATE.tsv). */
static MATRIX func_800AEF94__zero __attribute__((used));
static int func_800AEF94__reported __attribute__((used));
static int func_800AE47C__reported __attribute__((used));
void func_80041C68(MATRIX*, MATRIX*);
typedef struct {
    char prefix[0x64];
    MATRIX matrix;
    char gap[8];
    VECTOR scale;
} cameraTransformScratch;

void func_800AECA0(MATRIX* source);


void func_800AEEC4(D_800F4538_t* arg0) __attribute__((unused));
void func_800AEEC4(D_800F4538_t* arg0);


void func_800AAE9C(void*);
void func_800AB4F0(void*);
void func_800AB788(void*, void*, int);
void func_800AB9A4(void*);
void func_800AC540(int, D_800F4538_t*);
typedef struct objectAnimationState objectAnimationState;
void func_800B0908(objectAnimationState*, int);
void func_800B1A68(D_800F45E0_t*, MATRIX*);
extern int D_800E9308;
extern u_char D_800F4B18, D_800F4B19;

struct frameScratch {
    int unused;
    int depth;
};

void func_800AEF94(MATRIX* camera);

void func_800AF6E8(D_800F4538_t* arg0);

void func_800AF844(SVECTOR* dst, SVECTOR* src, int count);


void func_800AF960(D_800F45E0_t* arg0) __attribute__((unused));
void func_800AF960(D_800F45E0_t* arg0);


struct animationFrameScratch {
    char prefix[8];
    int first, last;
    psx_ptr(u_char*) data;
};
PSX_ASSERT_SIZE(struct animationFrameScratch, 0x14);
void func_800AFDE8(int, SVECTOR*, int);
void func_800AFA28(D_800F4538_t* actor, D_800F4538_unkC54* state, int mode);

void func_800AFDE8(int offset, SVECTOR* value, int rotation);


int func_800A92B8(int x, int z);
int vs_gte_rsqrt(int);
short func_800BEB00(void);
extern u_char D_800F49F8;

typedef struct {
    int unk0;
    int unk4;
} intPair;

void func_800B002C(D_800F4538_t* actor, int arg1);

void func_800B07DC(D_800F4538_t* actor);


struct objectAnimationState {
    char prefix[8];
    int flags;
    char padC[3];
    u_char id, pad10;
    signed char delay;
    u_char parent, pad13;
    int pad14;
    short rotationTicks, mode;
    SVECTOR position;
    short rx, ry, rz, pad2A;
    short sx, sy, sz, pad32;
    short dx, dy, dz, orientation;
    short drx, dry, drz;
    char pad42[0x1A];
    u_char tileX, pad5D, tileZ, pad5F;
    char pad60[0x10C];
    u_char material, durability, pad16E, parentObject, frame;
};
int func_800B101C();
int func_800A3DB4(int, int, int);
int func_800A6EE8(SVECTOR*, int, int, int);
void func_800E6898(void*);
void func_800E4C28(int, int);
void func_800B0908(objectAnimationState* object, int unused);


typedef struct {
    char prefix[8];
    u_int flags;
    char paddingC[3];
    u_char objectId;
    char padding10[0xA];
    short mode;
    short x, y, z, padding22;
    short rotationX, rotationY, rotationZ, padding2A;
    short scaleX, scaleY, scaleZ, padding32, padding34;
    short deltaY, padding38, orientation;
    char padding3C[0xF0];
    char savedState[32];
    char state[32];
    char padding16C[2];
    u_char material, padding16F, frame;
} objectMotionContext;
extern u_char D_800E91AC[], D_800E91BC[], D_800E91CC[], D_800E91DC[];
extern u_char D_800E91EC[], D_800E91F0[], D_800E91FC[], D_800E9208[];
extern u_char D_800E9218[], D_800E9228[], D_800E9238[], D_800E9248[];
extern u_char D_800E9258[], D_800E9268[];
int func_800A0104(int, int);

int func_800B101C(objectMotionContext* object);

int func_800B13CC(int arg0, int arg1, int arg2);

/* Declared for the Zig's c module (the C bodies that declared them are gone). */
extern int sprintf(char*, const char*, ...);

/* Declared for the Zig's c module (the C bodies that declared them are gone). */
extern void pc_log(const char*);
