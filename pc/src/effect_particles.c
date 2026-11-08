/* Native adaptation of the retained gte-macros/s5.c decompilation candidate
 * for BATTLE/6E644.s. Preserves original packet layout and GTE stages, but is
 * not a matching decompilation claim. Uses an explicit host argument instead
 * of the original wrapper's implicit MIPS argument-register forwarding. */
#include "common.h"
#include "pc/src/game/BATTLE/BATTLE.PRG/5BF94.h"
#include "pc/src/game/BATTLE/BATTLE.PRG/6E644.h"
#include "pc/src/game/SLUS_010.40/main.h"
#include <inline_c.h>
extern void pc_unimplemented(const char*);
#define gte_ctc2(reg, value) CTC2((value), (reg))
#define gte_mtc2(reg, value) MTC2((value), (reg))
#define gte_mfc2(reg, value) ((value) = (int)MFC2(reg))
#define gte_mfc2_b(reg, value) gte_mfc2(reg, value)
#define gte_lwc2(reg, ptr) MTC2(*(unsigned*)(ptr), (reg))
#define gte_mvmva2_b(sf, mx, v, cv, lm) gte_mvmva(sf, mx, v, cv, lm)
#define gte_rtv0tr2() gte_rtv0tr()
#define gte_rtps2() gte_rtps()
typedef struct func_800D6E44_t {
    psx_ptr(struct func_800D6E44_t) previous;
    psx_ptr(struct func_800D6E44_t) next;
    short unk8;
    short unkA;
    int x;
    int y;
    int z;
    int dx;
    int dy;
    int dz;
    int unk24[3];
    int unk30[3];
    func_800D6CF_t sprite;
    int flags;
    union {
        u_int value;
        struct {
            u_int scale : 8;
            u_int depthMode : 4;
            u_int unk60_12 : 4;
            u_int unk62 : 16;
        } bits;
    } unk60;
    short unk64[2];
    short lifetime;
    u_char matrixIndex;
    u_char unk6B;
    u_char endEvent;
    u_char tickEvent;
    char unk6E[2];
    int unk70;
    func_800D2904_curves curves;
} func_800D6E44_t;

/* A host view of the game's particle node (func_800D2904_t, 5BF94.h, PS1
 * layout with psx_ptr links), whose int unk3C[8] holds the sprite state
 * (func_800D6CF_t, also PS1 layout): the two views must agree on every target. */
_Static_assert(sizeof(func_800D6CF_t) <= sizeof(((func_800D2904_t*)0)->unk3C)
                   && __builtin_offsetof(func_800D6E44_t, sprite)
                          == __builtin_offsetof(func_800D2904_t, unk3C)
                   && __builtin_offsetof(func_800D6E44_t, curves)
                          == __builtin_offsetof(func_800D2904_t, unk74)
                   && sizeof(func_800D6E44_t) == sizeof(func_800D2904_t),
               "particle view != func_800D2904_t");
PSX_ASSERT_SIZE(func_800D6E44_t, 0x78);
#ifndef ROOD_PC_LP64
PSX_ASSERT_OFFSET(func_800D6E44_t, sprite, 0x3C);
PSX_ASSERT_OFFSET(func_800D6E44_t, curves, 0x74);
#endif

extern u_char D_80040A14[];
/* Native particles (effect_native.c; absent in unit probes). */
extern void pc_particles_native_begin(void) __attribute__((weak));
extern void pc_particles_native_node(unsigned* start, unsigned* end, int tiles, const int view[3], int sz,
    unsigned xy, int bucket, int layered, const void* node, int age, unsigned source) __attribute__((weak));
extern unsigned* pc_particles_native_end(unsigned* packet, unsigned* ot) __attribute__((weak));

void func_800D6E44(void* head);

