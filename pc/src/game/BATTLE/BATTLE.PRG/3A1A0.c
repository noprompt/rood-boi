#include "common.h"
#include "30DB0.h"
#include "3A1A0.h"
#include "../../SLUS_010.40/main.h"
#include <abs.h>
#include "pc/src/psx_types.h"

typedef struct {
    int unk0;
    int pad04[5];
    psx_ptr(D_800F45E0_t) unk18;
    short unk1C[18];
    int unk40;
} D_1F8003BC_t;
PSX_ASSERT_SIZE(D_1F8003BC_t, 0x44);

typedef struct {
    short unk0;
    short unk2;
    short unk4;
} func_800A3054_t;

typedef struct {
    short unk0;
    short unk2;
    short unk4;
    short unk6;
} func_8008D2C0_t;

/* The block-scope static of the original function: the Zig reaches this storage through the views
 * (battle_statics.py, STATE.tsv). */
static func_8008D2C0_t func_800A4A24__sp10[4] __attribute__((used));

typedef struct {
    char unk0[6];
    short unk6;
} func_800A6660_t;

void func_800A29A0(D_800F4538_t*);
void func_800ACF54(D_800F4538_t*);
void func_800E4C28();
u_int func_800A9C54(u_char, void*, int);
void func_800AEAE8(D_800F4538_t*);
void func_800AECA0(MATRIX*);
void func_800B28A8(void*, MATRIX*, int);
int func_8008D2C0(func_8008D2C0_t*);
short func_8008DD0C(int arg0, int arg1);
D_800F4538_t* func_800A3C34(int, int, int, int);
short func_8008DC7C(int, int);
short func_8008DA24(int, int);
u_int* func_800A8D64(SVECTOR*, int);
int func_800B13CC(int, int, int);
int func_800A92B8(int, int);
int func_800A9378(int, int, int, int);
void func_800AA850(int, short, int);
int func_800A8E84(D_800F45E0_t*, SVECTOR*);
void func_800B0908(D_800F45E0_t*, int);
int func_800A6EE8(SVECTOR*, int, int, int);
int func_800E75EC(void);
int func_8009E180(D_800F4538_t*, SVECTOR*);

extern u_int* D_800F49F0;
extern u_short D_800F49F4;
extern u_char D_800F49F8;
extern u_char D_800F49F9;
extern SVECTOR D_800F4B08;
extern char D_800F4B18;
extern u_char D_800E9278[];

void func_800A29A0(D_800F4538_t* arg0);

void func_800A2C48(D_800F4538_t* arg0);


void func_800A2FBC(D_800F4538_t*);
void func_800A9EB4(int, short, int);
void func_800AA620(int, SVECTOR*, int);

void func_800A2CD4(D_800F4538_t* arg0);

void func_800A2FBC(D_800F4538_t* arg0);

void func_800A3054(D_800F4538_t* arg0, func_800A3054_t* arg1);


inline int func_800A3310(int, SVECTOR*);
void func_800A3394(int, SVECTOR*);
int func_800A3500(int, int);
func_8008D2C0_t* func_800A4A24(int);
void func_800ACF54(D_800F4538_t*);

void func_800A30A0(int actorId, func_80089888_t* placement, int height, int mode);

inline int func_800A3310(int arg0, SVECTOR* arg1);

void func_800A3394(int arg0, SVECTOR* arg1);

int func_800A3500(int arg0, int arg1);

void func_800A35A8(void);

void func_800A36E0(int arg0, int arg1, func_8006EBF8_t* arg2);

int func_800A3760(int arg0, int arg1, int arg2);


extern int D_800F49E8;
int func_800A3BC4(int, int);
int func_800A3DB4(int, int, int);
int func_800A91DC(int, int, int);

int func_800A38E0(int actorId);


int func_800A3BC4(int arg0, int arg1);
D_800F4538_t* func_800A3C00(D_800F45E0_t* arg0, u_int arg1);
int func_800A3DB4(int x, int z, int minimumHeight);

int func_800A3BC4(int arg0, int arg1);

D_800F4538_t* func_800A3C00(D_800F45E0_t* arg0, u_int arg1);

D_800F4538_t* func_800A3C34(int arg0, int arg1, int arg2, int arg3);

int func_800A3DB4(int x, int z, int minimumHeight);


extern int D_800E90A8;
extern u_char D_800E8FD0[];
void func_800AE6C0(D_800F4538_t*, int, int);
void func_800E4C1C(int, int);
void func_800AA454(int, func_8006EBF8_t_fields*, int);

int func_800A3E6C(int actorId);

int func_800A190C(int, int, SVECTOR*, int);
void func_800E68A0(D_800F45E0_t*);

void func_800A41D0(D_800F4538_t* actor, int mode);


void func_800A4A88(D_800F4538_t*, int);
int func_800A46A4(D_800F4538_t*);
int func_800A4494(int contact, SVECTOR* point);


void func_800A70DC(D_800F4538_t*, int);
typedef struct {
    char prefix[0x2C];
    u_char contact, nextContact;
} collisionScratchView;

int func_800A46A4(D_800F4538_t* actor);

int func_800A47C4(void);

void func_800A4828(int arg0, MATRIX* arg1);


void func_800B64A8(int, int, int);
typedef struct {
    unsigned mode : 2;
    unsigned fast : 1;
    unsigned reserved : 29;
} vs_battleMovementModeFlags;
void func_800A48CC(int index, int direction, int distance);

inline func_8008D2C0_t* func_800A4A24(int arg0);


void func_8008C49C(int, int);
void func_800E4BD8(int);
void func_800E4BE0(int);

void func_800A4A88(D_800F4538_t* actor, int mode);

void func_800A4D8C(void);


void func_800A25EC(D_800F4538_t*); /* extern */
void func_800A2790(D_800F4538_t*); /* extern */
void func_800A291C(D_800F4538_t*); /* extern */
void func_800A2CD4(D_800F4538_t*); /* extern */
int func_800A51A0(int, SVECTOR*); /* extern */
void func_800A525C(D_800F4538_t*); /* extern */
int func_800A5280(int, int, int, SVECTOR*); /* extern */
void func_800AC690(int, D_800F4538_t*); /* extern */
void func_800E6B24(u_char); /* extern */

void func_800A4E68(int arg0);

int func_800A51A0(int arg0, SVECTOR* arg1);

void func_800A525C(D_800F4538_t* arg0);


extern short D_800F4B0A;
typedef struct {
    int words[2];
} probePosition;
extern int D_800E90BC;
extern u_char D_800E90C3[];
extern u_char D_800E90C4;
extern u_char D_800E90C6;
extern u_char D_800E91AC[];
extern u_char D_800F1D6E[];
int func_800A6798(D_800F4538_t*, SVECTOR*, SVECTOR*);
int func_800A69B4(D_800F4538_t*);
int func_800A6AA0(D_800F4538_t*, int, int);
int func_800A76BC(D_800F4538_t*, SVECTOR*, int*, int);
int func_800A9530(D_800F4538_t*, SVECTOR*);
void func_800AA600(int, SVECTOR*, int);
void func_800AA698(int, SVECTOR*, int);
void func_800AE4FC(D_800F4538_unk0*, int);
void func_800A6660(D_800F4538_t*, int, func_800A6660_t*);

int func_800A5280(int index, int direction, int distance, SVECTOR* input);

void func_800A6660(D_800F4538_t* arg0, int arg1, func_800A6660_t* arg2);

int func_800A6798(D_800F4538_t* actor, SVECTOR* offset, SVECTOR* motion);

int func_800A69B4(D_800F4538_t* arg0);


extern u_char D_800E90CC[];
extern u_char D_800E90D0[];
int func_800AD494(void*, int, u_short**);

int func_800A6AA0(D_800F4538_t* actor, int speed, int direction);

int func_800A6EE8(SVECTOR* arg0, int arg1, int arg2, int arg3);


typedef struct {
    char prefix[0x1C];
    short heights[8];
    u_char blocked[8];
    u_char attributes[8];
    u_char centerAttribute;
} ActorCollisionSamples;
void func_800A70DC(D_800F4538_t* actor, int diagonal);


typedef struct {
    char prefix[0x2C];
    u_char contacts[8];
} collisionResponseScratch;

void func_800A7524(D_800F4538_t* actor, SVECTOR* motion);


int func_800A8B34(SVECTOR* arg0, int arg1);
int func_800A8FD4(D_800F4538_t* actor, SVECTOR* motion);

int func_800A76BC(D_800F4538_t* actor, SVECTOR* motion, int* result, int probeOnly);

int func_800A8B34(SVECTOR* arg0, int arg1);

