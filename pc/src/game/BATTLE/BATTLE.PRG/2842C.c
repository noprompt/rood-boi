#include "common.h"
#include "146C.h"
#include "pc/src/game/SLUS_010.40/main.h"
#include <abs.h>
#include <memory.h>
#include <rand.h>
#include <stdio.h>
#include <string.h>
#include "pc/src/psx_types.h"
#ifdef ROOD_PC
#include "pc/src/widescreen.h"
#include "pc/src/hud/hud_hook.h"
#endif

typedef struct {
    psx_ptr(int) unk0;
    psx_ptr(void) unk4;
    short unk8;
    short unkA;
    int unkC;
    int unk10;
    int unk14;
    int unk18;
    SVECTOR unk1C;
    short unk24;
    short unk26;
    short unk28;
    short unk2A;
    short unk2C;
    short unk2E;
    short unk30;
    short unk32;
} func_80092F74_t;
PSX_ASSERT_SIZE(func_80092F74_t, 0x34);

typedef struct {
    psx_ptr(int) unk0;
    union {
        u_short u16[2];
        short s16[2];
        int s32;
    } unk4[4];
    int unk14;
    int unk18;
} func_80092F74_t2;
PSX_ASSERT_SIZE(func_80092F74_t2, 0x1c);

typedef struct {
    int unk0;
    char unk4;
    char unk5;
    char unk6;
    char unk7;
    int unk8;
    int unkC;
    int unk10;
    int unk14;
    int unk18;
    int unk1C;
    int unk20;
} D_800F1DD8_t2;

typedef struct {
    char unk0;
    u_char unk1;
    char unk2;
    char unk3;
    D_800F1DD8_t2* unk4;
    D_800F1DD8_t2* unk8;
} D_800F1DD8_t;

typedef struct {
    short unk0;
    short unk2;
} func_80092B04_t2;

typedef struct {
    int unk0;
    psx_ptr(void) unk4;
    char unk8[0x2C];
} func_80092B04_t;
PSX_ASSERT_SIZE(func_80092B04_t, 0x34);

typedef struct {
    u_short unk0;
    u_short unk2;
    u_short unk4;
    u_short unk6;
    char unk8;
    char unk9;
    char unkA;
    char unkB;
    short unkC;
    char unkE;
    char unkF;
} func_800962E4_t;

typedef struct {
    u_char unk0[0xC];
    u_char unkC;
    u_char unkD;
    u_char unkE;
    u_char unkF;
    u_char unk10;
    u_char unk11;
    u_char unk12;
    u_char unk13;
    u_char unk14;
    u_char unk15;
    u_char unk16[0xA];
} func_80093914_t;

typedef struct {
    u_char unk0[0xC];
    u_char unkC;
    u_char unkD;
    u_char unkE;
    u_char unkF;
    u_char unk10;
    u_char unk11;
    u_char unk12;
    u_char unk13;
    u_char unk14;
    u_char unk15;
    u_char unk16[0xE];
    u_char unk24;
    u_char unk25;
    u_char unk26;
    u_char unk27;
} func_80093914_t2;

typedef struct {
    int geometryOffset;
    char unk4[3];
    u_char delay;
    u_char baseU;
    u_char baseV;
    u_char frameCount;
    u_char columns;
    u_char frameWidth;
    u_char frameHeight;
    u_char tick;
    u_char frame;
    u_char u[4];
    u_char v[4];
} func_80091C6C_t;

typedef struct {
    int geometryOffset;
    char unk4[3];
    u_char delay;
    u_char baseU;
    u_char baseV;
    u_char width;
    u_char height;
    u_char currentU;
    u_char currentV;
    u_char windowWidth;
    u_char windowHeight;
    signed char stepU;
    signed char stepV;
    u_char tick;
    char unk13;
    u_char u[4];
    u_char v[4];
} func_80091E10_t;

typedef struct {
    u_char tick;
    u_char frame;
    u_char frameCount;
    u_char columns;
    char unk4[3];
    u_char delay;
    int scrollStep;
    RECT rect;
} func_80091FE8_t;

typedef struct {
    u_char count;
    u_char unk1;
    u_char active;
    u_char unk3;
} func_80092548_t;

short func_8008DC7C(int, int);
void func_8008F29C(int, int);
void func_8008F30C(int, int);
void func_8008F440(void);
void func_8008F9A4(int, int);
void func_8008FAC8(void);
void func_8008FDC4(void);
void func_80090434(void);
void func_80090B28(void);
int vs_battle_clamp(short, int, int);
void func_8009121C(void);
void func_800927AC(D_800F1DD8_t*);
int func_80092B04(func_80092B04_t*, int, D_800F1DD8_t*);
int func_8009291C(int);
void func_80092EDC(func_80092F74_t* arg0);
int func_8009306C(func_80092F74_t* arg0);
int func_80093364(func_80092F74_t* arg0);
int func_8009406C(int, int, int, int);
int func_80094E18(int, int, D_800F1BAC_t*);
void func_80095C18(int, int);
int func_800A1280(int, int, SVECTOR*, int);
int func_800A152C(int, int, int);
int func_800A190C(int, int, SVECTOR*, int);
int func_800A1AF8(int, int, u_short*, int);
void* func_800962E4();
void func_80096444(int);

extern int (*D_800E85CC[])(D_800F1DD8_t2*);
extern int (*D_800E85E8[])(func_80092B04_t*, func_80092B04_t2*);
extern char D_80068EB4[];
extern int D_80068F04[][4];
extern u_short D_80068F64[][4];
extern int D_80068F94[];
extern int D_800F2274;
int func_80096254(int, int);
int func_8009F858(int);
u_long* vs_battle_setSprite(int, int, int, u_long*);
void func_8009651C(SVECTOR*, int);
extern char D_800691E4[];
extern RECT D_80068FAC[];
typedef struct {
    u_char count;
    u_char labels[2];
    u_char color;
} CombatLabel;
extern CombatLabel D_800690B4[];
extern const CVECTOR D_80069134[];
extern const RECT D_80069144[];
extern const RECT D_8006917C[];
extern int D_800E861C[];
extern short D_800E8634[];
extern RECT D_800E8640[];
extern u_short D_800F1CDC;
extern short D_800F1D00;
extern short D_800F1D98[];
extern short D_800F1DA4;
extern short D_800F1DA8;
extern short D_800F1DB4;
extern short D_800F1DB6;
extern short D_800F1DBC;
extern short D_800F1DC0;
extern short D_800F1DC2;
extern short D_800F1DC4;
extern char D_800F1DCA;
extern char D_800F1DCB;
extern void* D_800F1DD4;
D_800F1DD8_t D_800F1DD8[96]; /* 0x480 bytes of 12-byte entries on the PS1 */

/* room_effects.c: whether slot is running and its record (the PS1 reads were by byte offset). */
int pc_effect_slot(int slot, const unsigned char** record)
{
    const D_800F1DD8_t* e = &D_800F1DD8[slot];
    *record = (const unsigned char*)e->unk4;
    return e->unk0 && e->unk2;
}
extern short D_800F2258;
extern char D_800F225A;
extern char D_800F225B;
extern char D_800F2260[];
extern short D_800F2270;
extern short D_800F2272;
extern short D_800F2278;
extern short D_800F227A;
extern short D_800F227C;
extern short D_800F227E;
void func_800970BC(void);
void func_80094844(short*, D_800F1BAC_t*);
void func_80094AF8(D_800F1BAC_t*);
void func_80094B0C(int, int, D_800F1BAC_t*);
void func_8009506C(int, int, D_800F1BAC_t*);
void func_80095258(int, int, D_800F1BAC_t*);
void func_800958A4(int, int, D_800F1BAC_t*);
void func_80095A4C(int, int, D_800F1BAC_t*);
void func_8009695C(int, int, D_800F1BAC_t*);
void func_8009639C(int);
extern SVECTOR D_800F2280;

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80068EB4);

void func_80090C2C(int arg0);

#ifdef ROOD_PC
/* The game's room weather, including event-script overrides. A room's
 * generated moon must not shine through the overcast during rain. Keep
 * this a render-only query: the original weather update remains unchanged. */
int pc_weather_raining(void)
{
    return vs_battle_roomData.sectionB != NULL && D_800F1DCA == 1;
}
#endif

void func_80090EEC(void);

int vs_battle_clamp(short arg0, int arg1, int arg2);

void func_8009121C(void);

void func_80091314(int arg0);

void func_80091320(int arg0);

void func_8009134C(int arg0, int arg1);

void func_80091378(void);

int func_800913BC(int arg0);

void func_80091468(int arg0, int arg1);

/* The sky panorama's tiles drawn (their top-left corner, 20.12 screen X): in
 * widescreen (port) as far past the sides as the 16:9 view reaches
 * (pc/src/widescreen.h). */
#ifdef ROOD_PC
#define SKY_LEFT (-0x40000 - (PC_WIDESCREEN_MARGIN << 12))
#define SKY_RIGHT (0x180000 + (PC_WIDESCREEN_MARGIN << 12))
#else
#define SKY_LEFT -0x40000
#define SKY_RIGHT 0x180000
#endif

void func_8009147C(vs_battle_backgroundLayout* arg0, int arg1, int arg2, int arg3);

void func_800918E8(int arg0);

void* func_8009195C(int arg0);

int func_80091998(int arg0);

int func_800919D8(int arg0);

int func_80091A1C(int arg0, int arg1);

int func_80091A78(int arg0, int arg1);

int func_80091AC0(int arg0);

void func_80091B04(void);

int func_80091C6C(func_80091C6C_t* arg0);

int func_80091E10(func_80091E10_t* arg0);

int func_80091FE8(func_80091FE8_t* arg0);

int func_800923F8(D_800F1DD8_t2* arg0);

int func_80092540(void);

void func_80092548(void);

void func_800927AC(D_800F1DD8_t* arg0);

int func_8009291C(int arg0);

int func_80092A18(void);

int func_80092B04(func_80092B04_t* arg0, int arg1, D_800F1DD8_t* arg2);

int func_80092C68(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_80092E14(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_80092E7C(func_80092F74_t* arg0, func_80092F74_t2* arg1);

void func_80092EDC(func_80092F74_t* arg0);

int func_80092F6C(func_80092F74_t* arg0 __attribute__((unused)), func_80092F74_t2* arg1 __attribute__((unused)));

int func_80092F74(func_80092F74_t* arg0, func_80092F74_t2* arg1 __attribute__((unused)));

int func_80092F98(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_80092FBC(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_8009306C(func_80092F74_t* arg0);

int func_80093364(func_80092F74_t* arg0);

int func_8009352C(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_800935B8(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_800935F8(func_80092F74_t* arg0 __attribute__((unused)), func_80092F74_t2* arg1);

int func_8009361C(func_80092F74_t* unk0 __attribute__((unused)), func_80092F74_t2* arg1);

int func_80093640(func_80092F74_t* arg0, func_80092F74_t2* arg1);

int func_800936F0(func_80092F74_t* arg0 __attribute__((unused)), func_80092F74_t2* arg1 __attribute__((unused)));

int func_800936F8(int arg0);

int func_80093764(int arg0);

void func_80093788(int arg0);

void func_80093824(int arg0);

void func_800938AC(int arg0);

void func_80093914(int arg0);

void func_80093A14(void);

void func_80093A70(void);

void func_80093AB4(void);

int func_80093B04(u_short* arg0);

int func_80093B68(int arg0, int arg1, int arg2, int arg3);

int vs_battle_renderBattleAbilityTimingResult(int arg0);

int func_80093F24(int arg0);

int func_80093FEC(int arg0, int arg1, int arg2, int arg3);

int func_8009406C(int arg0, int arg1, int arg2, int arg3);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80068F04);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80068F64);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80068F94);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80068FAC);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_800690B4);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80069134);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_80069144);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_8006917C);

INCLUDE_RODATA("build/src/BATTLE/BATTLE.PRG/nonmatchings/2842C", D_800691E4);

#ifdef ROOD_PC
/* PC_CLASSIC: a word over an actor (MISS or a combat label) for the classic layer
 * (classic_hook.h): the draw the label loop chose and its inputs, copied before it runs.
 */
#define PC_ACTOR_WORD(miss, call)                                                                       \
    do {                                                                                                \
        pc_classic_actor_word pc_word = { label, miss, label->unkB, label->unkC, label->unkE & 1 };    \
        PC_CLASSIC(PC_CLASSIC_SITE_ACTOR_WORD, &pc_word, screen[0], screen[1], call);                  \
    } while (0)
#endif

void func_800941FC(void);

void func_80094844(short* pos, D_800F1BAC_t* label);

void func_80094AF8(D_800F1BAC_t* arg0);

void func_80094B0C(int x, int y, D_800F1BAC_t* p);

int func_80094E18(int x, int y, D_800F1BAC_t* p);

void func_8009506C(int arg0, int arg1, D_800F1BAC_t* arg2);

void func_80095258(int x, int y, D_800F1BAC_t* p);

void func_800957D0(int arg0, int arg1, int arg2);

#ifdef ROOD_PC
/* ui_text font (pc/src/ui_text.c): the status words' packets, set as words. */
extern void pc_text_status(const void* first, const void* end) __attribute__((weak));
#define PC_TEXT_STATUS(call)                                                     \
    do {                                                                         \
        void* pc_first = psx_get(((vs_scratch_t*)0x1F800000)->unk0);             \
        call;                                                                    \
        if (pc_text_status)                                                      \
            pc_text_status(pc_first, psx_get(((vs_scratch_t*)0x1F800000)->unk0)); \
    } while (0)
#else
#define PC_TEXT_STATUS(call) call
#endif

void func_800958A4(int x, int y, D_800F1BAC_t* p);

void func_80095A4C(int x, int y, D_800F1BAC_t* p);

void func_80095B70(int arg0);

void func_80095B7C(int arg0, int arg1);

#ifdef ROOD_PC
/* PC_CLASSIC: what func_80095C18 decided, as it decides it, for the classic layer
 * (classic_hook.h). Defined in hud_bridge.c: func_8009627C's Zig port hands it to the site too. */
extern pc_classic_emote pc_emote_record;
#endif

void func_80095C18(int actor, int kind);

int func_80096254(int arg0, int arg1);

void func_8009627C(void);

void* func_800962E4(void);

void func_8009639C(int arg0);

void func_80096444(int arg0);

void func_8009651C(SVECTOR* position, int direction);

int func_80096768(int arg0, int arg1, int arg2);

void func_8009695C(int x, int y, D_800F1BAC_t* p);

void func_80096FF0(int arg0);

void func_800970BC(void);

void func_800971D4(void);

void func_8009722C(void);

#ifdef ROOD_PC
#include "pc/src/room_callbacks.inc"

/* Defined here: the slots mix words with a pointer, so they cannot be an LP64 import. */
vs_battle_objectData vs_battle_objectDataSlots[16];
#endif
