/* Native equivalents of hand-written game assembly, added only when verified. */
/* pc/src/game/BATTLE/BATTLE.PRG/7E05C.s: func_800E6EAC returns immediately.
 * Its delay slot only writes caller-saved $t0 (the following function's lui). */
#include "psx_types.h" /* psx_load/psx_store: 4-byte guest pointers */
#include "game/BATTLE/BATTLE.PRG/ai_state.h"
#include "draw_items.h"
#include "scratch.h"
extern void pc_unimplemented(const char*);
void func_800E4288(void* destination, unsigned bytes);


/* 7E028.s: merge the two actor flags and derive their priority state.
 * Explicit offsets preserve the assembly ABI until this structure is shared. */
void func_800E6828(void* actor);


extern unsigned char* D_800F5878[];
extern unsigned char D_80069C0C[];
/* 7E05C.s: store an actor's two stat bytes and their maximum; empty actor
 * slots are ignored. The original's return value is not meaningful. */
void func_800E685C(int id, int first, int second);

/* 7E05C.s: propagate reciprocal actor relations through the linked actor list.
 * The reciprocal field is read before writing the outgoing field, including
 * the self-relation case; preserving that order preserves recursion behavior. */
void func_800E7370(void* actor);


extern void func_800DC210(void*, int);
void func_800E72D0(void);


int func_80099514(unsigned x, unsigned z, unsigned layer);


/* The sprite entry points of 573B8.c are items (game/spriteItem.h). */
/* The packet cursor, and the table's default slot, as the items' markers use them. */
static unsigned* cursor_get(void) { return psx_get(vs_scratch.unk0); }
static void cursor_set(unsigned* cursor) { psx_set(vs_scratch.unk0, cursor); }

/* The sprite as an item (game/spriteItem.h): the packet's fields, the marker where it linked. */
int vs_battle_spriteItem(unsigned* ot, int brightness, int xy, int wh, int mode, int uv_clut)
{
    unsigned* cursor = cursor_get();
    int first = pc_frame_count();
    unsigned grey = (unsigned)brightness & 255;
    pc_frame_sprite(0, (short)xy, (short)(xy >> 16), (short)wh, (short)(wh >> 16), uv_clut & 255, uv_clut >> 8 & 255,
        (int)(grey * 0x010101u), uv_clut >> 16 & 0xffff, mode ? mode & 0x3fff : PC_ITEM_INHERIT,
        (brightness >> 7) & 2 ? PC_ITEM_SEMI : 0);
    cursor_set(pc_frame_place(first, pc_frame_count() - first, ot ? ot : psx_get(vs_scratch.unk8), cursor));
    return first;
}
/* vs_battle_addTile as an item: a flat tile (code 0x60, 0x62: wh its size) or a flat line (0x40, 0x42: wh its end), placed
 * where the packet linked; 0 when the words are anything else (a draw mode and window pair: they stay the packet). */
int vs_battle_tileItem(unsigned* ot, unsigned rgb0, unsigned xy, unsigned wh)
{
    unsigned code = rgb0 >> 24;
    unsigned* cursor = cursor_get();
    int first = pc_frame_count();
    if ((code & 0xfc) == 0x60)
        pc_frame_tile(0, (short)xy, (short)(xy >> 16), (short)wh, (short)(wh >> 16), (int)(rgb0 & 0xffffff), PC_ITEM_INHERIT,
            code & 2 ? PC_ITEM_SEMI : 0);
    else if (code == 0x40 || code == 0x42) {
        pc_item* it = pc_frame_add(PC_ITEM_LINE, 0);
        if (it) {
            it->mode = PC_ITEM_INHERIT, it->flags = code & 2 ? PC_ITEM_SEMI : 0;
            it->x[0] = (short)xy, it->y[0] = (short)(xy >> 16), it->x[1] = (short)wh, it->y[1] = (short)(wh >> 16);
            it->rgb[0][0] = (unsigned char)rgb0, it->rgb[0][1] = (unsigned char)(rgb0 >> 8), it->rgb[0][2] = (unsigned char)(rgb0 >> 16);
        }
    } else
        return 0;
    cursor_set(pc_frame_place(first, pc_frame_count() - first, ot, cursor));
    return 1;
}
const void* vs_battle_spriteCommand(int item) { return pc_frame_command(item); }
/* The sprite's colour as a full colour word (0xBBGGRR; its top byte, a packet's code, only says semi-transparent: bit 1). */
int vs_battle_spriteColor(int item, int colour)
{
    pc_item* it = pc_frame_item(item);
    if (it)
        it->rgb[0][0] = (unsigned char)colour, it->rgb[0][1] = (unsigned char)(colour >> 8), it->rgb[0][2] = (unsigned char)(colour >> 16),
        it->flags = (unsigned short)((colour >> 24) & 2 ? it->flags | PC_ITEM_SEMI : it->flags & ~PC_ITEM_SEMI);
    return item;
}

short func_800E6694(int id);


/* 7C4F4.s: decide whether action slot (row, column) is usable and record it in
 * bit 7 of the slot's flags. Type 1 checks a signed 16-bit resource and a
 * blocking flag; type 3 compares cost plus half the high stat against the low
 * stat; type 4 checks a second signed resource. A 0x2000 state allows only
 * types 1 and 2. Rows with a count below 2 are never usable. */
int func_800E4DF8(void* state, int row, int column);


extern void func_800DD000(void*, void*);
extern void func_800DD344(void*);
/* 73C84.s: run func_800DD000 for every actor, then func_800DD344 for every
 * actor (the second pass also receives the context in $a1, which it ignores).
 * The original walks the list as a do-while; an empty list would fault. */
void func_800DC810(void* context);


/* 73B0C.s: copy an actor's stat words (0x18, 0x1c, 0x30, 0x948) and the
 * 0x528-byte block at 0x398 from src to dst, tail-calling vs_main_memcpy. */
void func_800DC3E8(void* src, void* dst);


/* 7C4F4.s: derive three condition bytes from the actor's paired 16-bit stats
 * (low = current, high = maximum) and the state threshold at 0x17:
 * 0x12 = low1 * 2 < high1; 0x11 = threshold and (low2 < threshold or
 * low2 * 2 < high2); 0x10 = status flags. The original loads 0x90000 with lui
 * and then overwrites it with ori $zero, so the mask is 0xE2B0. */
void func_800E4F14(void* state);


/* 73C24.s: snapshot each listed actor's id and stat words into a 0x18-byte
 * record indexed by id. Like the original do-while, an empty list faults. */
void func_800DC424(void* snapshots);

void func_800DC2E0(void* dst, void* src);


/* 73C84.s: bit 15 (func_800DC484) or 14 (func_800DC48C) of the action's
 * target flags. For action 0x60 against an actor of class 2 the original
 * returns the whole shifted halfword xor 1, not just the inverted bit. */
int func_800DC484(int action, int id);

int func_800DC48C(int action, int id);


extern int D_800F58F0;
extern unsigned D_800F58F4;
extern unsigned D_800F58F8; /* a 32-bit guest address */
/* 73C84.s: remember the first candidate for each action slot whose action has
 * flag 0x40, up to 16 entries. The slot bit is set even when the list is full. */
void func_800DC4F0(void* candidate, void* info);


/* 7C4F4.s: whether a candidate may target actor id. Requires a peer and a
 * relation >= 2; candidate bit 5 adds a relation < 3 check against the action's
 * target mask (unless action flag 0x100); bit 4 rejects relation < 3; a slot
 * flag bit 1 rejects targeting oneself. */
int func_800E4CF4(void* state, void* candidate, int id);


extern unsigned D_800F5904; /* a 32-bit guest address */
/* 73B0C.s: append a scored candidate (up to 16, nonzero weight) to the state's
 * list at 0x2F0, record its pointer at 0x430, and mark (target, action) used. */
void func_800DC344(void* state, void* candidate);


/* 7E05C.s func_800E6974: K&R quicksort of candidate pointers by their first
 * word (score), descending. The original packs left/right into bytes when
 * saving them, which is lossless for the 16-entry lists it sorts. The list
 * holds 4-byte guest pointers (PS1 layout of the AI record). */
extern int rand(void);
/* 73C84.s: give the first `count` candidates (0x430) one chance each, in
 * order, to take the lead: a candidate with a nonzero byte at bit 5 of word 4
 * wins when rand() & 0x7F is below its weight (bits 19-26 of word 0xC,
 * capped at 0x4C); it swaps with the first entry and the rest are re-sorted
 * (L800E6958, the func_800E6974 quicksort from index 1). */
extern void func_800D8260(void*, int, int);
extern void func_800E48A8(void*, int, int);
/* 73C84.s: mark target `id` (word 0x1A4 + id * 4) as classification 3 and
 * clear bits 8-14. Unless it already was, the actor first reacts: byte 0x18
 * is set (the original's rand() & 0x7F < 0x80 always holds, but rand is
 * still drawn), then func_800D8260(6, 0x28) and func_800E48A8(2, 0x80). */
void func_800DC784(void* state, int id);


extern int func_800DAA6C(void*);
extern void func_800DD7CC(void*, void*);
/* 70D4C.s: choose the movement mode at 0x12E. Actors already running
 * func_800DAA6C, or whose best candidate's flags miss the mask at 0x2D, use
 * mode 1; otherwise mode 2 and a waypoint search into 0x134. */
void func_800D9DD8(void* state);


extern unsigned D_800F58B8;
extern unsigned D_800F590C;
extern int D_800F58D4;
extern void func_800E65DC(void); /* pc/src/actor_update.c */
extern void func_800D8EF4(void);
extern void func_800DAED0(void);
extern void func_800DC0D0(void);
extern void func_800D9538(void);
/* 7C7E0.s: per-frame AI driver. The original walks the null-terminated
 * routine table D_800F16BC: func_800E65DC, 0x800E50C8 (advance to the next
 * active actor), 0x800E5100 (move $sp to the scratchpad at 0x1F800374),
 * func_800D8EF4, func_800DAED0, func_800DC0D0, 0x800E5110 (restore $sp) and
 * func_800D9538. The table is fixed data, so it is called directly here; the
 * stack switch is a speed trick and is not reproduced (the host stack does not
 * overwrite scratchpad below 0x374 as the original's frames would). */
void func_800E511C(void);


extern void func_80095B7C(int, int);
/* 6FA0C.s: forward (id, value) to func_80095B7C for nonzero actor ids. For id 0
 * the original falls into func_800D826C's tail and returns 1; otherwise $v0 is
 * whatever func_80095B7C leaves (callers ignore it). */
int func_800D820C(int id, int value);

int func_800D826C(void* state);

/* 6FA6C.s: count down the timer at 0x12A. On reaching zero send 0 (L800D8254),
 * otherwise send the halfword at 0x138, both for the state's actor id. */
void func_800D8280(void* state);


/* 7B5DC.s: count down the two per-actor byte timers at 0x155 and 0x13F,
 * stopping at zero. */
void func_800E4358(void* state);


extern int func_800E4660(int, int, int);
/* 7BDD4.s: squared distance between two short XYZ positions, with height
 * offsets added to each Y; falls through into func_800E4660 (GTE SQR). */
int func_800E4624(short* a, short* b, int a_height, int b_height);


/* 7B5DC.s: whether height y is above the floor of the navigation cell at
 * (x >> 7, z >> 7) in the grid (64-byte rows) cached at scratchpad 0x3BC. A cell with
 * bit 13 set has floor 0; otherwise floor = sign15(sign((cell & 0x3FF) << 6)
 * - ((cell & 0x1C00) >> 3)). Returns 1 when y < floor. */
int func_800E4478(int x, int y, int z);

/* 7B5DC.s: sample 16 points from `from` toward `to` (each Y lowered by its
 * height argument, X read as unsigned 16-bit) in steps of delta >> 4; return 1
 * as soon as a sample has y >= floor (func_800E4478 returns 0; Y grows down). */
int func_800E44E8(short* from, short* to, int from_height, int to_height);

