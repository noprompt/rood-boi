/* Native equivalents of the actor motion-request routines that BATTLE.PRG
 * 4A0A8.c keeps as original inline assembly (excluded under ROOD_PC).
 * Model layout offsets follow the original (D_800F4538 entries). Branch
 * delay slots are executed, as in the byte-matched original. */
#include "common.h"
#include "pc/src/game/BATTLE/BATTLE.PRG/146C.h"
#include "pc/src/game/BATTLE/BATTLE.PRG/3A1A0.h"

extern void func_800A208C(void*, void*, int, int);
extern int func_800A0204(int, int, int, int);
extern void func_800A9EB4(int, int, int);
extern void func_800A249C(int, int);
extern void func_800AA8D0(int, int, int);

/* Clear the motion flags (0xA bits 5-6) and set bit 6, then hand the target
 * to func_800A208C. */
/* Play animation 0x1F (blend 8) before moving: sets motion bits 5-6. */
static void motion_animated(int id, D_800F4538_t* model, int* target, int speed, int facing)
{
    ((unsigned char*)&model->unk0)[0xa] |= 0x60; /* the header's flag bytes */
    func_800A0204(id, 0x1f, 0, 8);
    func_800A208C(model, target, speed, facing);
}
/* 4A0A8.c func_800B63AC: start a move; actors already moving restart it
 * (bit 6) or animate first (bit 5); otherwise mark state 0x5B0 = 1. */
void func_800B63AC(int id, int* target, int speed, int facing);

void func_800B6404(int id, int* target, int speed, int facing);

void func_800B6438(int id, int* target, int speed, int facing)
{
    motion_animated(id, D_800F4538[id], target, speed, facing);
}
/* The motion request block (unk1848): the kind word, the packed pair, a word and the position. */
void func_800B64CC(int id, int a, int b, int c)
{
    D_800F4538_unk1848* request = &D_800F4538[id]->unk1848;
    *(unsigned*)&request->unk4 = ((unsigned)c << 16) | (unsigned)a; /* unk4 and unk6 as one word */
    request->unk8 = b;
    *(unsigned*)&request->unk0 = 1; /* the kind */
}
void func_800B64A8(int id, int a, int b);

void func_800B6500(int id, unsigned* position);

void func_800B653C(int id, unsigned* position, int b, int c);

void func_800B6530(int id, unsigned* position, int b);

/* Start a turn toward position[0] at rate b unless one is pending (0xB low
 * nibble); also applies to the linked actor 0x17FD when its id is >= 2. */
void func_800B6580(int id, int* position, int b);

void func_800B65E8(int id, int* position, int b);

void func_800B65F4(int id, int* position, int b);

/* Walk (0x20) or run (0x80, when 0x63C >= 0x80), then func_800A249C. */
void func_800B6634(int id, int a)
{
    D_800F4538_t* model = D_800F4538[id];
    func_800A9EB4(id, a, model->unk63C < 0x80 ? 0x20 : 0x80);
    func_800A249C(id, a);
}
void func_800B668C(int id, short a, int b);

