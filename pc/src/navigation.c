/* Native translations of the room navigation setup in BATTLE/7E05C.s. */
#include "psx_types.h" /* psx_load/psx_store: 4-byte guest pointers */
extern void* vs_main_allocHeap(unsigned);
extern void* vs_main_allocHeapR(unsigned);
extern void vs_main_freeHeapR(void*);
extern void func_800E4288(void*, unsigned);
extern void func_800E6098(void);
extern void func_800DC638(void);
extern void* func_8008B6FC(void); /* 146C.c: the room's section 6 */
extern unsigned _getCollisionMapDimensions(int);
extern short func_8008E4AC(void);
extern unsigned* func_8008B764(unsigned, unsigned, int);
extern unsigned short* func_8008D438(unsigned, unsigned, int);
extern int func_8008DC7C(int, int);
/* Guest words at 0x800F58xx hold 32-bit guest addresses: stored as words so
 * a write never spills into the next one (the game declares D_800F58C0 int). */
extern unsigned D_800F58C0, D_800F58D8, D_800F58C8, D_800F5908, D_800F5910, D_800F58CC,
    D_800F58B8, D_800F58D0;
extern void pc_unimplemented(const char*);

int func_800E71DC(int x, int z);

void func_800E6B4C(void);

void func_800E6F9C(void);


extern int func_8008D2C0(void*);
/* 73C84.s: enable navigation links associated with active room exits.
 * Retain the register mutation across iterations, including variable shifts. */
void func_800DC638(void);

