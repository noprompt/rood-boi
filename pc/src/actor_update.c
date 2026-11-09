/* 7DDDC.s and 7C7E0.s: actor navigation frame preparation. Native C keeps
 * its own stack; scratchpad data layout and explicit missing callees remain. */
#include "psx_types.h" /* psx_load/psx_store: 4-byte guest pointers */
#include "game/BATTLE/BATTLE.PRG/ai_state.h"
extern unsigned char* D_800F5878[];
extern unsigned D_800F58BC, D_800F58D0, D_800F58B8, D_800F58CC, D_800F58C0, D_800F58C4;
extern unsigned D_800F16E0, D_800F16E4, D_800F16E8, D_800F16EC, D_800F16F0;
extern void pc_unimplemented(const char*);
extern int func_800E45B4(void);
extern int func_800E4660(int, int, int);
extern void func_800DEEFC(void*, int);
extern void func_800E50A0(void*, int, int);
extern void func_800D9538(void);
extern void vs_main_freeHeapR(void*);
extern int ratan2(int, int);
extern void func_800E19FC(void*, int);
extern void* vs_main_allocHeapR(unsigned);
extern void func_800E4288(void*, unsigned);
extern void func_800D82CC(void*);
extern void func_800D821C(void*);
extern void func_800DBF00(void*);
extern void pc_route_continuation(void*, unsigned); /* battle_movement.c */

void pc_actor_scratch(unsigned* scratch)
{
    for (int i = 16; i >= 0; --i)
        scratch[(0x37c / 4) + i] = psx_to_int(unsigned, D_800F5878[i]);
    scratch[0x3bc / 4] = D_800F58D0;
    scratch[0x3c0 / 4] = D_800F58B8;
    scratch[0x3c4 / 4] = D_800F58CC;
    scratch[0x3f4 / 4] = D_800F58C0;
    scratch[0x3f8 / 4] = D_800F58C4;
    scratch[0x3e0 / 4] = D_800F16E0;
    scratch[0x3e4 / 4] = D_800F16E4;
    scratch[0x3e8 / 4] = D_800F16E8;
    scratch[0x3ec / 4] = D_800F16EC;
    scratch[0x3f0 / 4] = D_800F16F0;
    /* Without a navigation record (func_800E5308 does not test it, unlike
     * func_800E511C) the original reads word 4 of address 0: PS1 RAM, the
     * kernel area, read here through guest RAM. */
    scratch[0x3dc / 4] = *psx_to_ptr(unsigned*, (D_800F58BC ? D_800F58BC : 0x80000000u) + 4);
}
void func_800E65DC(void);

void func_800E5240(unsigned id);

/* func_800E5154: func_800E5158 with $a3 = 1. 0 when actor `id`'s route
 * record is on its target tile, 1 while it is elsewhere, 2 when there is no
 * navigation grid, state or route. (The game's C caller passes no argument;
 * the PS1 relied on $a0 still holding the actor id, see 146C.c.) */
int func_800E5154(unsigned id);

/* func_800E51C8: copy actor `id`'s navigation state into `route` and reset
 * its route fields. */
/* func_800E527C: send actor `id` towards (x, z). Releases its reservations,
 * then allocates its route record on first use (0x484 bytes, heap 7) and
 * initializes it with the target. Returns 0 without a grid, state or memory.
 * As in the assembly, an existing route record is left alone: the state
 * record is copied onto itself and takes the target instead. */
int func_800E527C(unsigned id, int x, int z);

void func_800E5308(void);

