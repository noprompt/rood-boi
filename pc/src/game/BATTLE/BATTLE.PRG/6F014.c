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
#include "ai_state.h"

struct func_800D4910_t;

typedef struct {
    int unk0;
    _loadFileContext loadContexts[8];
    u_short slots[8];
    u_short isClut[8];
} D_800F5638_t;

typedef struct {
    short tableCount;
    u_short dataOffset;
    int tableOffsets[0];
} pFileBlock1;

typedef struct {
    int unk0;
    u_char data[0];
} pFileBlock2;

typedef struct {
    int meta;
    u_char data[0];
} p_file_t;

void func_800D5260(VECTOR*);
void func_800D5294(int*);
void func_800D7890(int arg0);
void _parsePfileBlock1(pFileBlock1* arg0);
void _parsePfileBlock12(void*);
void _parsePfileBlock13(void*);
void func_800D8038(int);
void vs_battle_setPlgLoadState(int);
void func_800D8060(p_file_t* arg0);
void func_800D82CC(vs_battle_aiState*);
void func_800D836C(vs_battle_aiState*);
int func_8008631C(int, int, int, int, void*);
int func_800863A4(int, int, int, int, SVECTOR*, SVECTOR*, void*);
int func_8008D2C0(func_8008D2C0_t*);
short func_8008DC7C(int, int);
int func_800DBCB4(vs_battle_aiState*, func_800E78F4_t2*);
void func_800DC810(func_800DEEA4_t*);
struct actionStatSnapshot;
void func_800DC888(struct actionStatSnapshot*);
void func_800DEEFC(vs_battle_aiState*, int);
struct vs_battle_aiState;
int func_800E0678(struct vs_battle_aiState*, int);
struct vs_battle_aiState;
int func_800E0918(struct vs_battle_aiState*, int, int);
void func_800E2CCC(vs_battle_aiState*);
void func_800E3600(vs_battle_aiState*, int, int);
int func_800E42EC(int, int);
int func_800E4764(vs_battle_aiState*, int*, int*);
void func_800E4B18(vs_battle_aiState*);
void func_800E4C8C(vs_battle_aiState*);
void func_800E4CE8(vs_battle_aiState* arg0);
void func_800E5EC0(int, int, int);
void func_800E678C(vs_battle_aiState*);
int func_800E7698(vs_battle_aiState*);
void func_800E7960(vs_battle_aiState*);

extern p_file_t D_800EC4BC;
extern D_800F16EC_t D_800F16EC[8];
extern int D_800F5330[];
extern char D_800F53C0[];
extern int D_800F5630;
extern D_800F5638_t D_800F5638;
extern u_int D_800F5680;
extern vs_main_CdQueueSlot* D_800F568C;
extern u_int _plgLoadState;
extern _loadFileContext _plgLoadContext;
extern u_long* D_800F56A0;
extern int _plgEntryPointCount;
extern effectExec D_800F56A8[];
#ifndef ROOD_PC
extern func_800CF0E8_t* D_800F5798;
#endif
extern D_800F569C_t D_800F57A0;
extern int D_800F5874;
extern vs_battle_aiState* D_800F5878[];
extern u_short (*D_800F58B8)[32];
extern D_800F58BC_t* D_800F58BC;
extern u_short (*D_800F58D0)[32];
extern func_800DEEA4_t* D_800F5900;
extern D_800F5910_t* D_800F5910;
extern int D_800F5918;
extern int D_800F591C;
extern D_800F5920_t* D_800F5920;

void func_800D7814(void);

void func_800D7890(int arg0);

extern D_800F569C_t* D_800F5698;

void func_800D78B8(void);

void func_800D78CC(void);

void _parsePfileBlock5(pFileBlock5* block);

void func_800D78F0(void);

void _parsePfileBlock3(void* block);

void _parsePfileCurveBlock(pFileCurveBlock* block);

void _parsePfileBlock8(void* block);

void _parsePfileBlock9(pFileBlock9* arg0);

void _parsePfileBlock10(void* arg0);

void _parsePfileBlock1(pFileBlock1* block);

void _parsePfileBlock2(pFileBlock2* block);

void _parsePfileBlock11(u_char* arg0);

void _parsePfileBlock12(void* arg0);

void _parsePfileBlock13(void* arg0);

int vs_battle_loadEffPurge(void);

int func_800D7BF8(void);

void func_800D7C5C(void);

int func_800D7CFC(void);

int func_800D7EF4(void);

static void func_800D7FB4(int arg0, int arg1) __attribute__((unused));
static void func_800D7FB4(int lba, int size)
{
    vs_battle_pFileLoadContext.lba = lba;
    vs_battle_pFileLoadContext.size = size;
}

void func_800D8038(int arg0);

void vs_battle_setPlgLoadState(int arg0);

void func_800D8060(p_file_t* arg0);

int vs_battle_getMainMenuLba(void);

