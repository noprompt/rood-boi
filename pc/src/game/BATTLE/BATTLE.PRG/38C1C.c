#include "common.h"
#include "3A1A0.h"
#include <libgpu.h>
#include <inline_c.h>
#include "vs_inline_c.h"
#include <abs.h>
#ifdef ROOD_PC
#include "pc/src/psx_types.h"
#include "pc/src/widescreen.h"
#endif

void func_8009DF3C(int, int);
int func_800A152C(int, int, int);
int func_800A17BC(int, int, void*, int*);
int func_800A1C10(int arg0, int arg1, u_short* arg2, int arg3);
MATRIX* func_800A1DE8(int, int, MATRIX*);
void func_800A9EB4(int, int, int);

extern MATRIX D_800F49B8;

int func_800A141C(int arg0, int arg1, int arg2, int arg3);

int func_800A152C(int arg0, int arg1, int arg2);

int func_800A1648(int arg0, int arg1, int arg2);

int func_800A1720(int arg0, int arg1, int* arg2, int* arg3);

int func_800A17BC(int arg0, int arg1, void* arg2, int* arg3);

int func_800A190C(int arg0, int arg1, SVECTOR* arg2, int arg3);

int func_800A1AF8(int arg0, int arg1, u_short* arg2, int arg3);

int func_800A1B9C(int arg0, int arg1, u_short* arg2, int arg3);

int func_800A1C10(int actorId, int bone, u_short* result, int endpoint);

typedef struct {
    char prefix[0x4C];
    SVECTOR position;
    SVECTOR offset;
    char padding[8];
    MATRIX matrix;
} boneMatrixScratch;

void func_800B07DC(D_800F4538_t*);
void func_80041C68(MATRIX*, MATRIX*);

MATRIX* func_800A1DE8(int actorId, int bone, MATRIX* unused);

SVECTOR* func_800A4A24(int);
int func_800A3500(int, int);
void func_800AE4FC(D_800F4538_unk0*, int);
void func_800A0204(int, int, int, int);

extern u_char D_800E90AC[];
extern u_char D_800E90B4[];

void func_800A208C(D_800F4538_t* actor, u_char* target, int speed, short facing);

void func_800A249C(int arg0, int arg1);

void func_800A2574(int arg0, short arg1);

int func_800A6EE8(SVECTOR*, int, int, int);
void* func_800A8D64(SVECTOR*, int);
void func_800AC690(int, void*);

void func_800A25EC(D_800F4538_t* actor);

void func_800AA850(int, int, int);

void func_800A2790(D_800F4538_t* actor);

void func_800A291C(D_800F4538_t* arg0);

