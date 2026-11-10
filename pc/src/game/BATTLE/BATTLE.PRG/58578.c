#include "common.h"
#include "146C.h"
#include "30DB0.h"
#include "58578.h"
#include "573B8.h"
#include "5BF94.h"
#include "target_block.h"
#include "../../SLUS_010.40/main.h"
#include <memory.h>
#include <stddef.h>
#include <inline_c.h>
#include "vs_inline_c.h"
#include "pc/src/psx_types.h"
#ifdef ROOD_PC
#include "pc/src/classic/classic_hook.h"
#include "pc/src/widescreen.h"
#endif

typedef struct {
    u_short unk0[3];
    u_char unk6;
    u_char unk7;
    u_char unk8;
    u_char unk9;
    signed char unkA;
    char unkB[0xD];
} func_800C4650_t;

typedef struct {
    SVECTOR unk0;
    SVECTOR unk8;
    short unk10[4];
    short unk18[4];
} func_800C0FA8_t2;

int func_800C1034(func_800C1564_t* arg0, u_short* arg1);
int func_800C123C(func_800C1564_t* arg0, u_short* arg1, int arg2);
int func_800C1384(func_800C1564_t* arg0, u_short* arg1, int arg2);
void func_800C1DC4(D_800EB9B8_unk990* arg0);
void func_800C20B4(void);
void func_800C253C(int type);
void func_800C02A8(void);
MATRIX* func_800C085C(u_char* scale, int angle);
void func_800C0B50(func_800C1564_t* shape, int color);
int func_800C0758(int phase, int segments, int index);
int func_800C2368(int step, int radius, int index);

extern short D_800EA234[];
extern short D_800EA2C4[];
extern u_char D_800EA438[];
extern u_short D_800EA46C[];
extern int D_800EA670[];
extern int D_800EA684[];
extern int D_800EA698[];
extern u_char D_800EA6AC;

extern D_800EB9B8_t* D_800EB9B8;

void func_800C0D78(void);

void func_800C0FA8(func_800C1564_t* arg0, func_800C0FA8_t2* arg1, MATRIX* arg2);

int func_800C1034(func_800C1564_t* arg0, u_short* arg1);

int func_800C110C(func_800C1564_t* arg0, u_short* arg1, int arg2);

int func_800C123C(func_800C1564_t* arg0, u_short* arg1, int arg2);

int func_800C1384(func_800C1564_t* shape, u_short* position, int angled);

int func_800C1564(func_800C1564_t* arg0, u_short* arg1);

void func_800C1664(int arg0, void* arg1, int arg2);

void func_800C16DC(void);

void func_800C16FC(int x0, int x1, int count);

void func_800C1A40(int x0, int x1, int count);

int func_800C1D84(void);

extern u_char D_800F4CB4;

void func_800C1DC4(D_800EB9B8_unk990* arg0);

void func_800C20B4(void);

int func_800C2254(int angle, int index);

int func_800C2368(int step, int radius, int index);

void func_800C253C(int type);

void* func_800C282C(void);

void func_800C28AC(SVECTOR* position, int arg1);

int _getCollisionMapDimensions(int arg0);
int func_800FA188(int x, int z, int* offset);
int func_800A91DC(int, int, int);
int func_8008DDA8(int x, int z);

void func_800C2B0C(u_short* position, u_int row);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/58578", D_80069860);
