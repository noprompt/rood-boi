#include "common.h"
#include "40564.h"
#include "146C.h"
#include "3A1A0.h"
#include "pc/src/game/SLUS_010.40/main.h"
#include "pc/src/game/SLUS_010.40/32154.h"
#include <abs.h>
#include "pc/src/psx_types.h"

typedef struct {
    u_char unk0;
    u_char unk1;
} func_800AAE9C_t;

/* An animation block as it is on disc: offsets from the block's own start. */
typedef struct {
    u_int dataOffset;  /* the packed streams */
    u_int indexOffset; /* the table of frame entries, one byte per animation */
    u_short unk8[0];
} func_800AD494_t;
PSX_ASSERT_SIZE(func_800AD494_t, 0x8);

typedef struct {
    short x;
    short y;
    short z;
    short id;
} func_8008D2C0_t;

/* The block-scope static of the original function: the Zig reaches this storage through the views
 * (battle_statics.py, STATE.tsv). */
static func_8008D2C0_t func_800A4A24__platforms[4] __attribute__((used));

void func_8007A824(DR_MOVE*);
int func_8008D2C0(func_8008D2C0_t*);
void func_800A0204(int, int, int, int);
void func_800A1280(int, int, SVECTOR*, int);
void func_800A1720(int, int, void*, int*);
int func_800A6EE8(SVECTOR*, int, int, int);
void func_800A70DC(void*, int);
void func_800AA698(int arg0, SVECTOR* arg1, int arg2);
void func_800AA984(int, short, int);
void func_800AAA88(int arg0, SVECTOR* arg1, int arg2);
void func_800AA290(int, func_8006EBF8_t_fields*, int, int);
void func_800AA490(int, func_8006EBF8_t_fields*, int, int);
void func_800AB098(D_800F4538_t*, int, int);

extern u_char D_800E8F2C;
extern func_800AAE9C_t D_800E909C[][28];
extern func_800AAE9C_t D_800E916C[][8];
extern u_char D_800F2450[];
extern void* D_800F4768;
extern char D_800F49DC;
extern u_char D_800F49E4;
extern int D_800F49F4;
extern u_char D_800F49F8;
extern u_char D_800F49F9;
extern short D_800F4B00;

_mpdRoomSection3* func_800A8D64(SVECTOR* arg0, int arg1);


int func_800A8E84(D_800F4538_t* arg0, SVECTOR* arg1);
typedef struct {
    char prefix[4];
    u_char excluded;
} actorCollisionExclusion;

int func_800A8E84(D_800F4538_t* actor, SVECTOR* position);

int func_800A8FD4(D_800F4538_t* actor, SVECTOR* motion);

int func_800A91DC(int arg0, int arg1, int arg2);

int func_800A92B8(int arg0, int arg1);

int func_800A9378(int arg0, int arg1, int arg2, int arg3);


// Inlined copy of 3A1A0 func_800A4A24.
// BUG: returns the address of a stack variable
static inline func_8008D2C0_t* func_800A4A24(int id)
{
#ifdef ROOD_PC
    /* See 3A1A0.c: keep the returned array readable on the host. */
    static func_8008D2C0_t platforms[4];
#else
    func_8008D2C0_t platforms[4];
#endif
    int count;
    int i;
    id -= 2;

    count = func_8008D2C0(platforms);

    for (i = 0; i < count; ++i) {
        if (platforms[i].id == id) {
            return &platforms[i];
        }
    }
#ifdef ROOD_PC
    /* No matching platform: see 3A1A0.c (reads of PS1 address 0). */
    return (func_8008D2C0_t*)0x80000000;
#else
    return NULL;
#endif
}

int func_800A9530(D_800F4538_t* actor, SVECTOR* offset);

void func_800A97EC(int arg0, func_8006EBF8_t_fields* arg1, int arg2, int arg3);


short func_8008DA24(int, int);

static inline int scanFloor(int arg0, int arg1)
{
    int var_t0;
    int i;

    var_t0 = 0xBB8;
    D_800F49F8 = 0;

    for (i = 0; i < 16; ++i) {

        D_800F45E0_t* temp_v1 = D_800F45E0[i];

        if (temp_v1 == NULL) {
            continue;
        }

        if (!temp_v1->unk8_0 && (temp_v1->unk5C == arg0) && (temp_v1->unk5E == arg1)
            && !temp_v1->unk9_0 && (temp_v1->unk1A != 0xFE)
            && (temp_v1->unk1E < var_t0)) {

            var_t0 = temp_v1->unk1E;
            D_800F49F8 = i;
        }
    }

    var_t0 -= 128;

    if (var_t0 > 0) {
        var_t0 = 0;
    }

    return var_t0;
}

void func_800A9988(int arg0, SVECTOR* arg1, int arg2, int arg3);

void func_800A9C54(int arg0, func_8006EBF8_t_fields* arg1, int arg2);

void func_800A9CDC(int arg0, func_8006EBF8_t_fields* arg1, int arg2);

void func_800A9D24(int arg0, SVECTOR* arg1, int arg2);

void func_800A9D90(int arg0, SVECTOR* arg1, int arg2);

void func_800A9E38(int arg0, short arg1, int arg2);

void func_800A9EB4(int arg0, short arg1, int arg2);

void func_800A9F64(int arg0, SVECTOR* arg1, int arg2);

void func_800A9FD0(int arg0, SVECTOR* arg1, int arg2);

void func_800AA290(int arg0, func_8006EBF8_t_fields* arg1, int arg2, int arg3);

void func_800AA454(int arg0, func_8006EBF8_t_fields* arg1, int arg2);

void func_800AA490(int arg0, func_8006EBF8_t_fields* arg1, int arg2, int arg3);

void func_800AA600(int arg0, SVECTOR* arg1, int arg2);

void func_800AA620(int arg0, SVECTOR* arg1, int arg2);

void func_800AA698(int arg0, SVECTOR* arg1, int arg2);

void func_800AA850(int arg0, u_short arg1, int arg2);

void func_800AA8D0(int arg0, short arg1, int arg2);

void func_800AA984(int arg0, short arg1, int arg2);

void func_800AAA88(int arg0, SVECTOR* arg1, int arg2);

void func_800AABD0(int arg0, SVECTOR* arg1, int arg2);

void func_800AACDC(void);

int func_800AAD4C(int actorId, int index, int value, int mode);

int func_800AAE9C(D_800F4538_t* actor);


extern u_char D_800E8F30[];
extern u_char D_800E8F90[];

typedef struct {
    u_char overlay;
    u_char x;
    u_char y;
    u_char columns;
} func_800AB098_t;

void func_800AB098(D_800F4538_t* actor, int index, int frame);

void func_800AB2AC(int arg0);

void func_800AB358(int index, u_char* arg);

void func_800AB4F0(void* actor);

void func_800AB788(u_char* actor, u_char* object, int arg2);


void func_800A190C(int, int, SVECTOR*, int);
void func_800A7524(void*, void*);
int func_800AC0D4(u_char* arg0, u_char* arg1, int arg2);
int func_800AC168(u_short* colors, int count, int amount, int mode, u_short* reference);
void func_800AC690(int arg0, D_800F4538_t* arg1);
extern u_char D_800F4B19;

void func_800AB9A4(D_800F45E0_t* arg0);

int func_800AC0D4(u_char* arg0, u_char* arg1, int arg2);

int func_800AC168(u_short* colors, int count, int amount, int mode, u_short* reference);

void func_800AC37C(int arg0, int arg1);

void func_800AC440(D_800F4538_t* arg0, int arg1, int arg2);

void func_800AC500(D_800F4538_t* arg0);

void func_800AC540(int arg0, D_800F4538_t* arg1);


void func_8006F450(SVECTOR*);
void func_8008C49C(int, int);
short func_8008DD0C(int, int);
void func_800ACF54(D_800F45E0_t*);
void func_800AE828(int, D_800F4538_t*, int);
void func_800E4C28();
void func_800E6764(int);
void func_800E6EB0(int);
extern u_int* D_800F49F0;
extern u_char D_800E9278[];
extern u_char D_800E92E8[];
extern u_char D_800E92F0[];
extern u_char D_800E92F8[];
extern u_char D_800E9300[];

typedef struct {
    u_int unk0 : 24;
    u_int timer : 8;
} func_800AC690_timer_t;

typedef struct {
    u_int unk0 : 16;
    u_int state : 3;
    u_int unk13 : 13;
} func_800AC690_flags_t;

typedef struct {
    u_int contact : 4;
    u_int unk4 : 28;
} func_800AC690_contact_t;

void func_800AC690(int arg0, D_800F4538_t* actor);


typedef struct {
    int unk0;
    int unk4;
} func_800ACF54_t;

void func_800ACF54(D_800F45E0_t* arg0);

inline void func_800ACFA0(SVECTOR* arg0, u_char* arg1, int arg2);


void func_800AE47C(D_800F4538_t*);

void func_800AD008(void* arg0, void* arg1);

int func_800AD494(void* arg0, int arg1, u_short** arg2);

void func_800AD62C(int arg0, int* arg1, int* arg2);

