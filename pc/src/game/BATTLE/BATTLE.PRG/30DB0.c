#include "common.h"
#include "146C.h"
#include "30DB0.h"
#include "38C1C.h"
#include "3A1A0.h"
#include "44F14.h"
#include "6E644.h"
#include "../SLUS_010.40/main.h"
#include "../SLUS_010.40/31724.h"
#include "../SLUS_010.40/32154.h"
#include "build/src/include/lbas.h"
#include "gpu.h"
#include <libgte.h>
#include <libetc.h>
#include <memory.h>
#include "pc/src/psx_types.h"
#ifdef ROOD_PC
#include "pc/src/widescreen.h"
#endif

typedef struct {
    u_char unk0[0x1FE0];
    u_short unk1FE0;
} D_800F2458_t;

typedef struct {
    u_char unk0;
    u_char unk1;
    u_char unk2;
    u_char unk3;
    int unk4;
    int unk8;
} func_800A0024_t;

typedef struct {
    u_char unk0[0x30];
    psx_ptr(int) unk30;
} func_8004644C_t;
PSX_ASSERT_SIZE(func_8004644C_t, 0x34);

typedef struct {
    int unk0;
    int unk4;
    int unk8;
    int unkC;
} D_800E8FB4_t;

typedef struct {
    u_char unk0[0x84];
    SVECTOR unk84;
} D_1F80035C_t;

void func_8008C49C(int, int);
int func_8009998C(vs_battle_objectData*);
void func_80099E7C(void*, int, int, int, int);
void* func_8009A028(int* arg0, void* arg1, int arg2);
int _loadWep(vs_battle_objectData*);
int _parseWep(vs_battle_objectData*);
int _loadShp(vs_battle_objectData*);
int _parseShp(vs_battle_objectData*);
int func_8009BE5C(vs_battle_objectData*);
int _loadSeq(vs_battle_objectData*);
int _loadEtm(vs_battle_objectData*);
void _loadMaterialPalette(int index, int material);
int func_8009E180(D_800F4538_t*, SVECTOR* arg1);
int func_8009E228(D_800F4538_t* arg0, SVECTOR* arg1);
void func_8009E700(int, int);
int func_8009F794(D_800F45E0_t* arg0);
void func_8009F9F4(int, D_800F4538_unk64*);
void func_8009FD38(D_800F4538_t* arg0);
int func_800A0104(int, int);
void func_800A06B8(D_800F4538_t*, int);
void func_800A11D8(int, int, MATRIX*, u_long*);
/* 38C1C.c takes the output vector's address as an int. */
int func_800A141C(int arg0, int arg1, int arg2, int arg3);
int func_800A152C(int, int, int);
void func_800A2C48(D_800F4538_t*);
void func_800A525C(D_800F4538_t*);
int func_800A6EE8(short*, int, int, int);
int func_800A91DC(int, int, int);
int func_800AAD4C(int, int, int, int);
void func_800AB2AC(int);
void func_800AC500(D_800F4538_t*);
void func_800AD008(void*, void*);
int func_800AD494(D_800F4538_t*, int, u_short**);
void func_800AD62C(int, int*, int*, int);
int func_800AD714(D_800F4538_t*, D_800F4538_unkC54*, int);
void func_800AE47C(D_800F4538_t*);
void func_800AE6C0(D_800F4538_t*, int, int);
short func_800BEB00();
void func_800E6898(void*);
void func_800E68A0(D_800F45E0_t*);

extern u_short _shpLbaOffsets[];
extern u_char _shpFileSectorSizes[];
extern u_char D_800E8960[];
extern u_short _etmLbaOffsets[];
extern u_char _etmFileSectorSizes[];
extern u_char _wepFileSectorOffsets[];
extern u_short D_800E8D00[];
extern u_char D_800E8E80[];
extern u_char _loadShpState;
extern u_char D_800E8F29;
extern u_char D_800E8F2C;
extern u_char _loadEtmState;
extern u_char D_800E8FA8[];
extern void* D_800E8FB4[];
extern char D_800E8FC0;
extern int D_800E8FC4;
extern u_char _weaponMaterialPaletteMap[];
extern u_char D_800E9030[];
extern u_char D_800E9090[];
extern u_char D_800E909C[];
extern u_char D_800E919C[];
extern void* _wepFileData;
extern int _wepFileLoaded;
extern vs_main_CdFile _wepFile;
extern vs_main_CdQueueSlot* _wepCdSlot;
extern void* _shpData;
extern int _shpAllocated;
extern vs_main_CdFile _shpFile;
extern vs_main_CdQueueSlot* _shpCdSlot;
extern u_short* _etmData;
extern vs_main_CdFile _etmFile;
extern vs_main_CdQueueSlot* _etmFileCdSlot;
extern void* _wepFileEpilog;
extern u_char D_800F244F[];
extern u_char D_800F2450[];
extern D_800F2458_t D_800F2458;
extern VECTOR D_800F4438;
extern char D_800F4448[];
extern int D_800F457C;
extern int D_800F4580;
extern int D_800F45D8;
extern short D_800F4628[4][16];
extern char* D_800F4810[4][16];
extern short D_800F4938[4][16];
extern int D_800F49D8;
extern u_int D_800F49E0;

int vs_battle_getEmptyObjectDataSlot(void);

int vs_battle_populateDataSlot(vs_battle_objectData* objectData);

int vs_battle_processObjectDataQueue(void);

void func_80099960(void* arg0);

int func_8009998C(vs_battle_objectData* arg0);

int func_80099D6C(int arg0);

void func_80099E7C(void* arg0, int arg1, int arg2, int arg3, int arg4);

void* func_8009A028(int* arg0, void* arg1, int arg2);

int _loadWep(vs_battle_objectData* arg0);

int _parseWep(vs_battle_objectData* objectData);

void _loadMaterialPalette(int index, int material);

int func_8009AA84(int index);

inline int func_8009AC24(vs_battle_objectData* arg0);

int _loadShp(vs_battle_objectData* arg0);

extern u_char D_800E8F30[];
extern u_char D_800E8F90[];
extern u_char* D_800F22B4;
extern u_char D_800F22B8;
extern int D_800F22BC;
extern int D_800F22C0;
extern int D_800F22C4;
extern void* D_800F4528[];

void func_8009CAEC(D_800F4538_t* arg0, int arg1);

int _parseShp(vs_battle_objectData* object);

extern u_short D_800E8A60[], D_800E8E8E[], D_800E8EA8[][4];
extern u_char D_800E8B40[], D_800E8EA3[], D_800E8EFC[][4];
extern void* D_800F22C8;
extern int D_800F22D0;
extern vs_main_CdFile D_800F22D8;
extern vs_main_CdQueueSlot* D_800F22E0;
int func_8009BE5C(vs_battle_objectData* object);

inline void func_8009C378(func_8009C378_t* arg0, func_8009C378_t* arg1);

extern u_char D_800E8F2B;
extern u_char* D_800F22E4;
extern void* D_800F4768;

int _loadSeq(vs_battle_objectData* object);

void func_8009CAEC(D_800F4538_t* arg0, int arg1);

int func_8009CC20(int arg0, int arg1);

void func_800AB098(D_800F4538_t*, int, int);

int func_8009CE9C(u_int arg0);

int func_8009CFA0(void);

int func_8009CFB0(int arg0);

int func_8009D208(int arg0);

int _loadEtm(vs_battle_objectData* objdata);

void func_8009D458(void);

void func_8009D468(int arg0, int arg1);

void func_8009D6F4(void);

void func_8009D7E8(int arg0, int arg1);

void func_8009D854(int arg0);

void func_8009D88C(int arg0);

void func_8009D934(int arg0, int arg1, int arg2);

void func_8009DBDC(int arg0, int arg1);

void func_8009DC38(int arg0);

void func_8009DC8C(int arg0);

void func_8009DD00(int arg0, SVECTOR* arg1, int arg2);

void func_8009DDF4(int arg0, SVECTOR* arg1);

void func_8009DF3C(int arg0, int arg1);

void func_8009E070(int arg0, SVECTOR* arg1, int arg2);

int func_8009E180(D_800F4538_t* arg0, SVECTOR* arg1);

int func_8009E228(D_800F4538_t* arg0, SVECTOR* arg1);

void func_8009E2E0(int arg0, SVECTOR* arg1, int arg2);

int func_8009E480(void);

int func_8009E4B0(int arg0);

void func_8009E5C4(int arg0);

void func_8009E614(int arg0);

void func_8009E700(int actorId, int animation);

void func_8009EA14(int arg0, SVECTOR* arg1);

void func_8009EC9C(int arg0, SVECTOR* arg1, int arg2, int arg3);

void func_8009EE9C(int arg0, SVECTOR* arg1, int arg2);

extern char D_800F49E4;

void func_8009EFEC(int actorId, SVECTOR* target, int mode);

void func_8009F298(int arg0, SVECTOR* arg1, int arg2);

void func_800AE7D8(void*, int, int);

void func_8009F314(int actorId, void* context, int animate);

void func_8009F530(int arg0);

int func_8009F794(D_800F45E0_t* arg0);

int func_8009F858(int arg0);

void func_8009F898(int arg0, int arg1, int arg2);

int func_8009F8DC(int arg0);

void func_8009F940(int arg0, int arg1, D_800F4538_unk58_2* arg2, D_800F4538_unk58_2* arg3);

void func_8009F990(int arg0, D_800F4538_unk64* arg1);

void func_8009F9F4(int arg0, D_800F4538_unk64* arg1);

int func_8009FBD8(int arg0, int arg1);

int func_8009FC60(int arg0, int arg1, SVECTOR* arg2, int arg3);

void func_8009FD38(D_800F4538_t* arg0);

int func_8009FD5C(int arg0, int arg1, int arg2);

int func_8009FE74(int arg0, int arg1);

void func_8009FF08(int arg0, int arg1, int arg2, int arg3);

int func_8009FFA8(int arg0, int arg1);

int func_800A0024(int arg0, func_800A0024_t* arg1);

int func_800A0104(int index, int material);

int func_800A01C8(int arg0, int arg1, int arg2, int arg3);

int func_800A0204(int actorId, int animation, int arg2, int blendFrames);

int func_800A0618(int arg0, int arg1, int arg2, int arg3);

void func_800A06B8(D_800F4538_t* arg0, int arg1);

int func_800A07FC(int arg0, D_800F4538_unk58_2* arg1);

void func_800A0870(int arg0);

void func_800A087C(int actorId, int arg1);

void func_800A09D8(int arg0, int arg1);

void func_800A0A1C(int arg0, int arg1);

void func_800A0ABC(int arg0);

void func_800A0AFC(int arg0, int arg1, int arg2);

u_int func_800A0BE0(int actorId);

int func_800A1108(int arg0, void* arg1);

int func_800A1178(int arg0, int arg1, MATRIX* arg2, u_long* arg3);

void func_800A11D8(int arg0, int arg1, MATRIX* arg2, u_long* arg3);

int func_800A1280(int arg0, int arg1, SVECTOR* arg2, int arg3);

