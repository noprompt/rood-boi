/* Native translations of actor-unload assembly in 7E05C.s, 7DE94.s,
 * 7BDD4.s and 6FA0C.s. Guest structure offsets retain the original ABI. */
#include "psx_types.h" /* psx_load/psx_store: 4-byte guest pointers */
#include "game/BATTLE/BATTLE.PRG/ai_state.h"
extern unsigned char* D_800F5878[];
/* Guest words at 0x800F58xx: 32-bit guest addresses. */
extern D_800F58BC_t* D_800F58BC;
extern unsigned D_800F58B8, D_800F590C, D_800F5920;
extern void func_800E5240(unsigned);
extern void func_80095B7C(int, int);
extern void func_800DBF00(void*);
extern void vs_main_freeHeap(void*);

void func_800E4C28(int x, int z);

void func_800D821C(void* actor);

void func_800E678C(void* actor);

void func_800E7454(void* actor);


extern unsigned D_800F58D0, D_800F58C0;
void func_800E6F1C(void);


/* 7E05C.s: the room's height limit (word 0x14 of the D_800F58BC record), or 0
 * when no record is loaded. Used when placing actors on room entry. */
int func_800E75EC(void);

