#include "common.h"
#include <rand.h>
#include <abs.h>
#include <inline_c.h>
#include "146C.h"
#include "3A1A0.h"
#include "44F14.h"
#include "../../SLUS_010.40/main.h"
#include "pc/src/psx_types.h"

extern struct {
    char prefix[0x1FD0];
    int scales[3];
} D_800F2458;

typedef struct {
    char prefix[0x34];
    u_short tpage, clut;
    char pad38[0x14];
    SVECTOR translation, position;
    psx_ptr(MATRIX) parent;
    int pad60;
    MATRIX matrix;
    SVECTOR rotation;
    VECTOR scale;
    psx_ptr(char) model;
} weaponTransformScratch;
PSX_ASSERT_SIZE(weaponTransformScratch, 0xa0);
extern MATRIX D_800F3C58[];
extern MATRIX D_800F3C78;
void func_800B17F0(SVECTOR*, MATRIX*);
void func_800B196C(MATRIX*, MATRIX*);
void func_800B396C(MATRIX*, VECTOR*);
int func_800B3A68(void*, MATRIX*, int, void*);
void func_800B4594(void*, void*, void*, void*);
void func_800B5C30(void*, void*, void*, void*);
int func_800A190C(int, int, SVECTOR*, int);

void func_800B1A68(D_800F45E0_t* object, MATRIX* camera);

typedef struct {
    char prefix[0x20];
    MATRIX matrix;
} weaponMatrix;
typedef struct {
    char prefix[0xA0];
    SVECTOR rotation;
} weaponRotation;
extern MATRIX D_800F3C58[];
void func_800B17F0(SVECTOR*, MATRIX*);
void func_800B196C(MATRIX*, MATRIX*);
void func_800B396C(MATRIX*, VECTOR*);
int func_800B3A68(void*, MATRIX*, int, void*);
short func_800BEB00(void);
void func_800B516C(void*, void*, void*, void*);
void func_800B3CF0(void*, void*, void*, void*);

void func_800B217C(vs_battle_wepModels_t* weapon, MATRIX* source);

typedef struct {
    char prefix[0x4C];
    SVECTOR translation;
} boneTransformScratch;
extern MATRIX D_800F3C58[];
void func_800B196C(MATRIX*, MATRIX*);
