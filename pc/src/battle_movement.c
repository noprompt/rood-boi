/* Native equivalents of the hand-written actor movement-state assembly in
 * BATTLE.PRG 72B70.s and its 7BDD4.s/7C7E0.s helpers. Guest structure offsets
 * keep the original ABI; return values reproduce the original $v0 where C
 * callers test them. */
#include "psx_types.h" /* psx_load/psx_store: 4-byte guest pointers */
#include "game/BATTLE/BATTLE.PRG/ai_state.h"
extern unsigned char* D_800F5878[];
extern unsigned D_800F58D8; /* a 32-bit guest address */
/* Scratchpad bytes and words; pointers kept there are 4-byte guest addresses
 * (SCRATCH_PTR), like every pointer stored inside the PS1-layout actor and AI
 * records read below by offset (psx_load/psx_store). */
#define SCRATCH_AT(offset) psx_to_ptr(unsigned char*, 0x1f800000 + (offset))
#define SCRATCH8(offset) (*SCRATCH_AT(offset))
#define SCRATCH32(offset) (*(unsigned*)SCRATCH_AT(offset))
#define SCRATCH_PTR(T, offset) psx_load(T, SCRATCH_AT(offset))
extern void pc_unimplemented(const char*);
extern void pc_require_native_callback(unsigned, const char*, unsigned);
extern int func_800DAD9C(void*);
extern int func_800DB0BC(void*);
extern void func_800E1EAC(void*, unsigned, int);
extern void func_800D820C(int, int);
extern void func_800E7370(void*);
int func_800E4180(void* state, int chance, int kind, int slot);

/* 7BDD4.s: rebuild the movement flags at 0x190: keep bits outside 0xFE1
 * (mask 0xFFFFF01E) and set 0x3C0 when the signed byte at 0x23 is nonzero. */
void func_800E4BB8(void* state);


/* 72B70.s: enter movement mode `mode` (byte 0x89 always records the request).
 * Re-entering the current mode (0x8A) does nothing. Modes reset their own
 * fields; mode 5 picks the nearest flagged waypoint of the actor's set
 * (D_800F58D8, 8 halfwords; bit 15 marks an entry, bits 0-4/5-9 its tile)
 * by Manhattan distance to the actor tile at 0x34. Returns the original $v0,
 * which is always nonzero. */
int func_800DB4AC(void* state, int mode);


/* 72B70.s: func_800DB5B8 enters mode 3 and wanders around (tile, range);
 * func_800DB5B0 does so with the state's own 0xCC/0xC8 fields. */
void func_800DB5B8(void* state, unsigned tile, int range);

void func_800DB5B0(void* state);


/* 72B70.s: func_800DB5DC enters mode 2 to walk to `tile` (stored at 0x168):
 * within `range` of the tile centre (L800E5030 in 7C7E0.s; height from
 * func_800E42E0, squared distances compared unsigned) the walk finishes
 * (func_800DEEFC 0), otherwise it moves (func_800E50A0 0, heading 0). */
extern int func_800E42E0(unsigned);
extern void func_800DEEFC(void*, int);
extern void func_800E50A0(void*, int, int);
extern int func_800E4660(int, int, int);
void func_800DB5DC(void* state, unsigned tile, int range);

/* 72B70.s: func_800DB5FC enters mode 5 and patrols its waypoints
 * (func_800E23AC). The assembly skips both when $a2 is 0; its only caller
 * (func_800DAA6C) passes no such argument and the PS1 value is whatever
 * func_800DA1D4 left there, nonzero on most of its paths (3, 0x280, the grid
 * size), so the port always patrols. */
extern void func_800E23AC(void*);
void func_800DB5FC(void* state);


/* 72B70.s: per-frame movement decision. Dispatch (func_800DAD9C), unstick
 * (func_800DB0BC) and the state's own callback at 0x68 each may claim the
 * frame; otherwise the actor wanders. The callback must be a native function. */
void func_800DB820(void* state);


/* Guest words at 0x800F58xx hold 32-bit guest addresses (see psx_load). */
extern unsigned D_800F58BC, D_800F58B8;
extern int func_800E4660(int, int, int);
extern int vs_gte_rsqrt(int);

int func_800E45F4(unsigned a, unsigned b);


/* 73460.s: candidate needs its target engaged: 1 when the state is busy
 * (byte 0x13), 0 without candidate option bit 4, else whether the target has
 * no engagement (D_800F45E0[target] null). */
int func_800DBC60(void* state, void* candidate);

/* 73460.s: candidate allowed now: not while the halfword at 0x90 is set, and
 * not when func_800DBC60 holds and the timer at 0x13F is running. */
int func_800DBCB4(void* state, void* candidate);


/* PS1 main RAM through any of its KUSEG/KSEG0/KSEG1 mirrors (2 MB repeated
 * up to 8 MB), for the original's out-of-list reads. The game's data,
 * overlays and heap keep their PS1 addresses there; an unaligned or non-RAM
 * address would raise an address/bus error on the PS1. */
/* 73460.s: 1 unless some hostile actor (relation >= 3) stands within two
 * tiles of the engaged target of `id`. The original starts its list walk at
 * &vs_battle_actors itself, so the first "node" has id vs_battle_actors[1]
 * (a pointer, or 0); its relation word (0x1A4 + id * 4, wrapping) and, when
 * that reads as hostile, its model D_800F4538[id] (0x800F4538 + id * 4) and
 * the model's tile (+0x5C) are read through guest RAM as the PS1 does. */
int func_800DBCEC(void* state, int id);


/* 73580.s: whether candidate action `candidate` can start now (weight,
 * threshold against the room value at D_800F58BC + 0x18, availability, target
 * engagement, distance and range, relation and model flags). The original
 * calls vs_gte_rsqrt on the distance and discards the result; the call is kept
 * for its GTE side effects. */
int func_800DBD80(void* state, void* candidate);


extern unsigned* func_8008E2D4(int);
extern void func_800DFA54(int, unsigned, unsigned, void*);
extern int func_800E24EC(void*, int);
extern int func_800E2B2C(void*, int);
extern int ratan2(int, int);
extern void func_800E2CCC(void*, int);
extern void func_800E19FC(void*, int);
extern void func_800E1908(void*, int);
extern void func_800E3600(void*, int, int);
extern void func_800E0A68(void*, int);
extern void func_800E1238(void*, int);
extern void func_800E153C(void*, int);
extern void func_800E1764(void*, int);

extern void func_800E4BD8(int);
extern int func_800DFAF8(int, unsigned, int);
extern int func_800D954C(void*, unsigned);
extern void func_800DEEFC(void*, int);
extern unsigned D_800F5910; /* guest address of the room's u16 link pairs */
/* 766FC.s L800DF8A4: continue a route through a room link (gate). Byte 0x19B
 * is the gate bit the actor holds in the room flags (func_800E4BE0 by
 * func_800DFBCC), word 0x19C the far end it is heading to. Off a link tile
 * (tile byte 1 < 2) the gate is released (func_800E4BD8), the far end reset
 * to -1 and 0x19B cleared. On a link tile, func_800DFAF8 finds the link whose
 * far end is 0x19C; when its near end (even halfword `index` * 2 of
 * D_800F5910: x bits 0-4, z bits 5-9) can be entered (func_800D954C > 0), the
 * gate of pair index / 2 is released, the step is stored at 0x170 and command
 * 14 issued; otherwise func_800E2CCC recovers.
 * The original builds the step tile in the caller's $s2 (it saves $s2 but
 * never initialises it), so byte 3 of 0x170 is the caller's top $s2 byte:
 * `caller_s2` passes it. func_800D954C shifts byte 3 out and the command
 * consumers (func_80075554, func_800A208C, func_800B6580) read bytes 0-2
 * only, so the value is unobservable; callers pass what they know. */
/* The AI state's layout for the test that pokes it (route_continuation_smoke reads these by symbol). */
const unsigned pc_ai_offset_priority = __builtin_offsetof(vs_battle_aiState, unk125);
const unsigned pc_ai_offset_gate = __builtin_offsetof(vs_battle_aiState, gate);
const unsigned pc_ai_offset_far_end = __builtin_offsetof(vs_battle_aiState, exit);
unsigned pc_route_continuations; /* times run (tests read it by symbol) */
void pc_route_continuation(void* state, unsigned caller_s2)
{
    vs_battle_aiState* base = state;
    ++pc_route_continuations;
    if (base->tile.b[1] < 2) {
        *(int*)&base->exit = -1;
        func_800E4BD8(base->gate);
        base->gate = 0;
        return;
    }
    int index = func_800DFAF8(psx_to_int(int, base), *(unsigned*)&base->exit, 0);
    if (index >= 0) {
        unsigned link = psx_to_ptr(unsigned short*, D_800F5910)[index * 2];
        unsigned tile = (caller_s2 & 0xff000000u) | (link & 0x1f) | (((link >> 5) & 0x1f) << 16);
        if (func_800D954C(state, tile) > 0) {
            *(int*)&base->exit = -1;
            func_800E4BD8((index >> 1) + 2);
            base->gate = 0;
            base->next.movementPosition.raw = tile;
            func_800DEEFC(state, 14);
            return;
        }
    }
    func_800E2CCC(state, 0);
}

/* 7BDD4.s: head for the packed target tile at 0x168 unless already on it
 * (then func_800E2CCC); with a gate held (0x19B) continue the route through
 * it instead (L800DF8A4). The callers' $s2 is not known natively; its byte
 * is unobservable (see pc_route_continuation). */
void func_800E4B2C(void* state, int angle);

/* 7BDD4.s: free movement (func_800E3600 mode 1, angle & 0xFFF) unless the
 * actor is held (0x1A); with a gate held (0x19B) continue the route through
 * it (L800DF8A4, returning through 0x800E4BAC). */
void func_800E4B70(void* state, int angle);

/* 7C7E0.s: dispatch through jtbl_800F1740 by priority state (0x125) and
 * `kind`, passing `angle`. The original table holds these six functions. */
void func_800E50A0(void* state, int kind, int angle);

/* 7C7E0.s: aim at the point (0x17C, 0x180), record it packed at 0x158, mark
 * movement (bytes 1 = kind, 9 = 1) and dispatch with the heading. */
void func_800E4FE0(void* state, int kind);


/* 72B70.s: approach actor `id`. Uses the model's waypoint group when allowed,
 * otherwise its tile; then plans with func_800E24EC and on success enters
 * mode 1. A missing cached actor still enters mode 1 for nonzero ids, as the
 * original's leftover $v0 (id * 4) does. */
int func_800DB370(void* state, int id, int distance, int option);

int func_800DB74C(void* state, int id);

/* 72B70.s: flee toward the (logically halved, running) average tile of hostile
 * actors (relation bits 5-7 == 7), remembering it for 90 frames at 0x110/0x114;
 * while in mode 4 keep going there until the timer runs out. */
int func_800DB61C(void* state, int kind);

/* 72B70.s: first other actor whose relation bits 6-7 equal `relation`; stores
 * its object's tile in *tile when given. Returns its id or -1. */
int func_800DBB2C(void* state, unsigned* tile, int relation);


extern int func_800DA1D4(void*);
extern int func_800DA5CC(void*);
extern int func_800DA6A4(void*);
extern int func_800DA738(void*);
extern int func_800DAA6C(void*);
extern int func_800DAAD8(void*);
extern int func_800D826C(void*);
extern void func_800DB5DC(void*, unsigned, int);

/* 72B70.s behaviour 0x800DBA4C: wander unless fleeing (0x0E set), else
 * func_800DA1D4. */
static int behaviour_800DBA4C(void* state)
{
    if (!((vs_battle_aiState*)state)->flagE)
        return func_800DA1D4(state);
    if (!func_800DB61C(state, 1))
        func_800DB5B0(state);
    return 1;
}
/* 72B70.s behaviour 0x800DBA88: flee when 0x0E is set; for stances 0/1 (0x131)
 * approach the best candidate's target within 0x100 (0x140 for models with
 * flag 0x20), stance 0 capping that by the candidate's rsqrt distance. */
static int behaviour_800DBA88(void* state)
{
    vs_battle_aiState* base = state;
    if (base->flagE)
        return func_800DB61C(state, 1);
    unsigned stance = (1u << base->status) & 3;
    if (!stance)
        return func_800DA1D4(state);
    unsigned* best = (unsigned*)base->entries.candidates[0];
    int limit = ((unsigned char*)base->object.actorObject)[0xa] & 0x20 ? 0x140 : 0x100;
    unsigned target = best[3] & 0xf;
    if (stance & 1) {
        int root = vs_gte_rsqrt((int)best[2]);
        if (!(limit < root))
            limit = root;
    }
    int result = func_800DB370(state, target, limit, 0);
    return result ? result : func_800DB74C(state, target);
}
/* 72B70.s behaviour 0x800DBB98: unless func_800DA1D4 claims the frame, wander
 * near the first hostile actor (relation 2): far ones (> 0x64000) by tile
 * (func_800DB5DC), near ones by area (func_800DB5B8, range 5). */
static int behaviour_800DBB98(void* state)
{
    vs_battle_aiState* base = state;
    unsigned tile;
    int result = func_800DA1D4(state);
    if (result)
        return result;
    int id = func_800DBB2C(state, &tile, 2);
    if (id < 0)
        return 0;
    if (0x64000u < base->tbl.t.distances[id])
        func_800DB5DC(state, tile, 0);
    else
        func_800DB5B8(state, tile, 5);
    return 1;
}
/* 72B70.s behaviour D_800DBC0C: when func_800D826C holds let func_800DA1D4
 * claim the frame; otherwise approach actor 0 within 0x100. Not static:
 * func_800DC210's Zig port stores its address. */
int behaviour_800DBC0C(void* state)
{
    if (func_800D826C(state)) {
        int result = func_800DA1D4(state);
        if (result)
            return result;
    }
    int result = func_800DB370(state, 0, 0x100, 0);
    return result ? result : func_800DB74C(state, 0);
}
/* Native D_800F1790 (actor behaviour table indexed by actor flags bits 4-8);
 * build_boot.py verifies the original words before linking. */
int (*D_800F1790[])(void*) = { behaviour_800DBA4C, behaviour_800DBA88, behaviour_800DBB98,
    func_800DA5CC, func_800DA6A4, func_800DA738, func_800DAA6C, func_800DAAD8,
    behaviour_800DBC0C, 0 };

/* 72B70.s: whether a candidate's target counts as engaged in the room's
 * current encounter (D_800F58BC): forced by 0x8E, blocked by 0x98, otherwise
 * the target relation bit 0 plus the room's counters and per-actor mask. The
 * original calls func_800DBCB4 and discards its result. */
int func_800DB8AC(void* state, void* candidate);


extern unsigned D_800F58E0;
extern void func_800DBF00(void*);
/* 6FA6C.s: join the room's encounter. Already engaged (0x8E) succeeds;
 * a full encounter (count 0x0D below members 0x12) or a block (0x98 or
 * D_800F58E0) fails. Otherwise set the engagement timer (1, or 0x20 after a
 * recent leave at 0x9A), add the actor's bit to mask 0x10, bump members and
 * push the actor on the room's engaged list (head 0x1C, tail 0x20, link 0x1A0). */
int func_800D836C(void* state);

/* 6FA6C.s: leave the encounter: clear the mask bit and timer, block
 * re-joining (0x98 = 0x30 unless exactly two actors remain; 0x9A = 90),
 * unlink (func_800DBF00), drop a member and notify (func_800D820C). */
void func_800D82CC(void* state);

void func_800D82A8(int id);


/* 7C7B0.s: whether actor `id` is farther than the reach threshold. The
 * original adds 0x80 to `range` for model class 10 but then squares its
 * constant 10 instead, so the test is always 100 < distance (unsigned). */
int func_800E4FB0(void* state, int id, int range);


/* 7B5DC.s floor-height helpers over the grid cached at scratchpad 0x3BC
 * (64-byte rows of 16-bit cells): raw height sign((cell & 0x3FF) << 6) minus
 * (cell & 0x1C00) >> 3; the *EC variants sign-extend it from 15 bits. */
int func_800E4320(int x, int z);

int func_800E4318(int x, int z);

int func_800E4308(unsigned tile);

int func_800E42EC(int x, int z);

int func_800E42E0(unsigned tile);

int func_800E42D4(int x, int z);


/* Scratchpad tables set up by the movement code (see func_800E65DC):
 * 0x3EC + dir: packed direction (dx signed bits 0-1, dz signed bits 4-5);
 * 0x3E0 + 3x3 index: per-neighbour direction or -1; 0x3C0: navigation cells;
 * 0x3BC: floor cells; 0x3C4/0x3DC/0x3F4: optional occupancy bitmap.
 * SCRATCH8/SCRATCH32/SCRATCH_PTR are defined at the top of the file. */
static int direction_dx(int packed) { return (int)((unsigned)packed << 30) >> 30; }
static int direction_dz(int packed) { return (int)((unsigned)packed << 26) >> 30; }

/* 7BDD4.s: whether stepping from `tile` in direction `dir` is blocked: the
 * neighbour has no floor (raw height negative) or differs by 64 or more. */
int func_800E4690(unsigned tile, int dir);


/* 70D4C.s: id + 1 of the first other actor whose bounds overlap the point one
 * radius ahead of `state` in direction `dir`, else 0; cached per direction in
 * scratchpad 0x3D2 (valid bits) / 0x3D4 + dir. */
int func_800D98E8(void* state, int dir);


/* 70D4C.s D_800D9B6C: whether direction `dir` is passable (1) or blocked (0),
 * cached in scratchpad 0x3D0 (valid bits) / 0x3D1 (passable bits). Blocked by
 * an actor (func_800D98E8), the occupancy/step test, reserved cell 0x38, cell
 * flags (bit 4 unless state byte 6, bits 5/7, mask byte 0x32 against bits
 * 8-15), a different area code when required, or a higher floor level. The
 * original also stashes `dir` in GTE VXY2, which is not reproduced. */
int D_800D9B6C(void* state, int dir)
{
    vs_battle_aiState* base = state;
    if ((SCRATCH8(0x3d0) >> dir) & 1)
        return (SCRATCH8(0x3d1) >> dir) & 1;
    int blocked = func_800D98E8(state, dir);
    if (!blocked) {
        unsigned tile = base->tile.raw, fine = base->unk120;
        int packed = SCRATCH8(0x3ec + dir), probe = dir;
        int tile_x = tile & 0xff, tile_z = (tile >> 16) & 0xff;
        int next_x = ((int)(fine & 0xff) + direction_dx(packed)) >> 1;
        int next_z = ((int)((fine >> 16) & 0xff) + direction_dz(packed)) >> 1;
        if (next_x == tile_x && next_z == tile_z)
            goto done;
        if (dir & 1)
            probe = (signed char)SCRATCH8(0x3e0 + (next_x - tile_x + 1) + (next_z - tile_z + 1) * 4);
        unsigned char* cells = SCRATCH_PTR(unsigned char*, 0x3c0);
        unsigned short* cell = (unsigned short*)(cells + next_x * 2 + next_z * 64);
        if (!SCRATCH32(0x3f4)) {
            blocked = func_800E4690(tile, probe);
        } else {
            unsigned reserved = base->previous.stuckMovementPosition.raw;
            unsigned char* reserved_cell =
                cells + (((reserved >> 10) & 0x3fc0) | ((reserved & 0xff) << 1));
            if (reserved_cell == (unsigned char*)cell) {
                blocked = 1;
                goto done;
            }
            unsigned char* bitmap = SCRATCH_PTR(unsigned char*, 0x3c4);
            blocked = (bitmap[tile_z * SCRATCH8(0x3dc) + tile_x] >> probe) & 1;
        }
        if (blocked)
            goto done;
        unsigned flags = *cell;
        if ((blocked = (flags >> 4) & (base->flags4.b[2] ^ 1)))
            goto done;
        if ((blocked = ((flags >> 5) & 1) | ((flags >> 7) & 1)))
            goto done;
        if ((blocked = base->f32 & (flags >> 8)))
            goto done;
        unsigned here = *(unsigned short*)(cells + tile_x * 2 + tile_z * 64);
        if ((base->f29 & (base->flags0.b[2] ^ 1)) && (here & 0xf) != (flags & 0xf)
            && (base->area & 0xf) != (flags & 0xf)) {
            blocked = 1;
            goto done;
        }
        unsigned char* floors = SCRATCH_PTR(unsigned char*, 0x3bc);
        blocked = (int)(*(unsigned short*)(floors + tile_x * 2 + tile_z * 64) & 0x1c00)
                < (int)(*(unsigned short*)(floors + next_x * 2 + next_z * 64) & 0x1c00);
    }
done:
    SCRATCH8(0x3d0) |= 1u << dir;
    if (blocked)
        SCRATCH8(0x3d1) &= ~(1u << dir);
    else
        SCRATCH8(0x3d1) |= 1u << dir;
    return (SCRATCH8(0x3d1) >> dir) & 1;
}

/* 7BDD4.s: scratchpad linear-congruential step (seed half 0x3F8 + increment
 * word 0x3FC, stored back as a word); returns the value & (n - 1). */
int func_800E45D4(int n);

/* 70D4C.s: whether `tile` can be entered: 0 for the reserved tile (0x38,
 * compared on its low 24 bits against tile with byte 1 cleared), outside the
 * grid, or blocked cell flags (0x80B0 plus the actor's mask 0x32 in bits
 * 8-15); -1 when another actor's bounds overlap the tile centre; else 1. */
int func_800D954C(void* state, unsigned tile);


/* 70D4C.s: whether the actor may step from tile `from` to tile `to` in
 * direction `dir`: 1 yes, 0 no, -1 when the step leaves its approach radius.
 * Quirks kept: for a negative X step the original negates the Z delta instead
 * of X; the area-code test always uses byte 0x132 (0x154 is loaded then
 * overwritten); the approach test reads halfwords from the D_800F4538 array
 * itself (+0x1C/+0x20 past the entry, not through it) and passes the packed
 * `to` tile as the SQR Z input. */
int func_800D96C8(void* state, unsigned from, unsigned to, int dir);


typedef int (*direction_test)(void*, int);
extern int rcos(int);
extern int rsin(int);
extern void func_800DEEFC(void*, int);
extern unsigned char D_800F1758[];

/* 7B55C.s: passability bits of the four axis directions (0, 2, 4, 6) as
 * bits 3..0. The original stashes its state in GTE registers (IR0-IR3,
 * SXY0/1, MAC1), which is not reproduced. */
int func_800E3D5C(void* state, direction_test test);


/* 7B3C8.s: record the step tile toward the target (0x168) in the path flags
 * (0x190 bits 22+ = x, 27+ = z; 0 per axis already reached, otherwise the
 * target coordinate plus one when it lies ahead). The fields overlap, as in the
 * original. */
void func_800E3BC8(void* state);


/* 7B3C8.s: forget (0x194/0x198/0x19A) a tile the actor keeps revisiting
 * (5 frames running blocks it for 120), clear 0x156, and store the step
 * count (0x7E, or 0x1F at random for non-flagged actors) in flags bits 5-11. */
unsigned func_800E3CDC(void* state, unsigned flags);


/* 7B5DC.s: start a step plan. When the plan was empty, forced (bit 16) or the
 * actor is fleeing (byte 4), pick a random turn side (bit 4) and maybe shout
 * (func_800E4180 kind 1); clear bit 17 when no steps remain; store the
 * passability of the four axis directions in bits 18-21. */
unsigned func_800E3DDC(void* state, unsigned flags, direction_test test);


/* Shared tail of the three step planners (7B5DC.s L800E3F50/L800E4084). */
static int finish_step(vs_battle_aiState* base, unsigned flags, int dir, int axis_only)
{
    unsigned plan = func_800E3CDC(base, (flags & 0xfffffff1) | ((unsigned)dir << 1));
    unsigned tile = base->tile.raw, target = base->destination168.destination;
    int tile_x = tile & 0xff, tile_z = (tile >> 16) & 0xff;
    int target_x = target & 0xff, target_z = (target >> 16) & 0xff;
    unsigned x, z;
    if (!axis_only) {
        z = tile_z == target_z ? 0 : tile_z + (tile_z < target_z);
        x = tile_x == target_x ? 0 : tile_x + (tile_x < target_x);
    } else if (plan & 4) {
        z = tile_z + (tile_z < target_z);
        x = 0;
    } else {
        x = tile_x + (tile_x < target_x);
        z = 0;
    }
    plan = (plan & 0x3fffff) | (z << 27) | (x << 22) | 1;
    base->movementFlags.raw = plan;
    return 1;
}
/* 7B5DC.s: step around an obstacle between headings `from` and `to`. */
int func_800E3EAC(void* state, int from, int to, direction_test test)
{
    vs_battle_aiState* base = state;
    unsigned flags = func_800E3DDC(state, base->movementFlags.raw, test);
    int turn = (flags & 0x10) ? 2 : -2;
    int offset = ((from + turn) & 7) == to ? turn : 4;
    int dir = (to + offset) & 7;
    if (!test(state, dir)) {
        dir = (((flags >> 1) & 7) + turn) & 7;
        if (!test(state, dir)) {
            base->movementFlags.raw = flags;
            return 0;
        }
    }
    return finish_step(base, flags, dir, 0);
}
static int final_step(vs_battle_aiState* base, unsigned flags, int dir, direction_test test)
{
    if (!test(base, dir)) {
        base->movementFlags.raw = flags;
        return 0;
    }
    return finish_step(base, flags, dir, 1);
}
/* 7B5DC.s: keep following a wall: `side` is +-1; turning the planned way
 * succeeds at once, otherwise try the reverse heading, then reverse - turn. */
int func_800E3FF4(void* state, int heading, int side, direction_test test)
{
    vs_battle_aiState* base = state;
    unsigned flags = func_800E3DDC(state, base->movementFlags.raw, test);
    int turn = (flags & 0x10) ? 1 : -1;
    if (turn == side)
        return finish_step(base, flags, heading, 1);
    int dir = (heading + 4) & 7;
    if (test(state, dir))
        return finish_step(base, flags, dir, 1);
    return final_step(base, flags, (dir - turn * 2) & 7, test);
}
/* 7B5DC.s (0x800E40F0): step toward heading `dir`, trying dir - turn, its
 * reverse, then dir reversed. */
int func_800E40F0(void* state, int dir, direction_test test)
{
    vs_battle_aiState* base = state;
    unsigned flags = func_800E3DDC(state, base->movementFlags.raw, test);
    int turn = (flags & 0x10) ? 2 : -2;
    int next = (dir - turn) & 7;
    if (test(state, next))
        return finish_step(base, flags, next, 1);
    next = (next + 4) & 7;
    if (test(state, next))
        return finish_step(base, flags, next, 1);
    return final_step(base, flags, (dir + 4) & 7, test);
}

/* 7B3C8.s entries 0x800E3C30/3C3C/3C48: run a step planner only when the
 * target is within 0x31000 (squared, tile centres) and byte 4 bit 0 is set,
 * then refresh the step tile (func_800E3BC8). The original stashes $ra/$a0/$v0
 * in GTE VXY0/VZ0/VXY1, which is not reproduced. */
static int near_target(vs_battle_aiState* base)
{
    unsigned tile = base->tile.raw, target = base->destination168.destination;
    int dx = (int)((target & 0xff) << 7) - (int)((tile & 0xff) << 7);
    int dz = (int)(((target << 8) >> 17)) - (int)(((tile << 8) >> 17));
    return ((dx * dx + dz * dz) < 0x31000) & (int)base->flags4.word;
}
int func_800E3C30(void* state, int a, int b, direction_test test)
{
    if (!near_target(state))
        return 0;
    int result = func_800E3EAC(state, a, b, test);
    func_800E3BC8(state);
    return result;
}
int func_800E3C3C(void* state, int a, int b, direction_test test)
{
    if (!near_target(state))
        return 0;
    int result = func_800E3FF4(state, a, b, test);
    func_800E3BC8(state);
    return result;
}
int func_800E3C48(void* state, int a, direction_test test)
{
    if (!near_target(state))
        return 0;
    int result = func_800E40F0(state, a, test);
    func_800E3BC8(state);
    return result;
}
/* Native D_800F1760 (rows: around, follow, toward; columns: approach mode).
 * build_boot.py verifies the original words. */
int (*D_800F1760[3][4])() = {
    { (int (*)())func_800E3EAC, (int (*)())func_800E3C30, (int (*)())func_800E3EAC,
        (int (*)())func_800E3C30 },
    { (int (*)())func_800E3FF4, (int (*)())func_800E3C3C, (int (*)())func_800E3FF4,
        (int (*)())func_800E3C3C },
    { (int (*)())func_800E40F0, (int (*)())func_800E3C48, (int (*)())func_800E40F0,
        (int (*)())func_800E3C48 },
};

/* 7B5DC.s: per-slot cry/animation request (0x474 + slot * 2: count << 8 |
 * kind). A new request (kind != 3) fires with chance/128 and loads its length
 * from D_800F1758; each call counts down, sets 0x13A = 0x40 and, for kinds 1
 * and 2, a pitch at 0x188 by remaining length before func_800DEEFC(16).
 * Returns 1 while at least 2 frames remained. */
int func_800E4180(void* state, int chance, int kind, int slot);


/* 7BDD4.s: whether `tile` lies behind the actor relative to its facing
 * target (actor 0x15C, or its own model heading when that is >= 16). */
int func_800E47E4(void* state, unsigned tile);


/* 7BDD4.s: try climbing toward a higher tile: from `tile` walk up to
 * steps - 1 tiles in `dir` while the floor stays at least as high; on the
 * first lower tile return it if func_800D96C8 and func_800D954C accept the
 * step, else 0. Only with the occupancy bitmap active (0x3F4). The original
 * intended min(steps - 1, 2) but tests its constant, so the bound is steps - 1. */
unsigned func_800E49D8(void* state, unsigned tile, int dir, int steps);

void func_800E4C1C(int x, int z);


/* func_800DEEFC speed selection from the actor's gait word 0x224: running
 * (byte 1) uses mask `run` (bytes 0/1 test, speed from byte 2/3), walking
 * uses `walk_low`/`walk_high`. Returns 0 with *command set, or -1 to stand. */
/* func_800DEEFC's shared move (L800DEF8C): face `angle`, pick the gait and
 * step; if a corner of the actor's square (half-size 0x92) would enter a
 * blocked neighbour, slide to the tile edge instead (command 0x0D). */
/* 766FC.s: issue movement/action command `action` to the actor's command
 * block (0x54): record it at scratchpad 0x3C8, reset the block (byte 8 =
 * 0x80, byte 10 = facing target) and fill it through jtbl_800F16F8 (18
 * entries). Byte 9 receives the command code. */
void func_800DEEFC(void* state, int action);


/* 7BDD4.s: refresh the approach point (0xF4/0xF6, half-tile units) of the
 * target actor 0xE5: its waypoint group when it has one (model byte 0x5D for
 * plain models, tile byte 1 of 0x60 for flagged ones), else its position. */
void func_800E4904(void* state);

void func_800E48F8(void* state);


extern void func_800E678C(void*);
/* 72B70.s: finish a pending stop request (0x12D): request 1 with a basic
 * command (< 9) idles (command 1); otherwise release the tile reservation
 * (func_800E678C), clear the request and switch to command 2. */
void func_800DB7B4(void* state);


/* 7BDD4.s: with no route (0x18C) and no cooldown (0x155), and a random draw
 * below `range` (always true for powers of two), set command byte 0xB to
 * `value` and start a 30-frame cooldown. The original computes a masked byte
 * but stores the raw value. */
void func_800E48A8(void* state, int value, int range);


extern int func_8008D2C0(void*);
extern short func_8008DC7C(int, int);
/* 7E05C.s func_800E6BA0 (register ABI: the probe point in $s2-$s4): 1 unless
 * one of the room's obstacle points (func_8008D2C0) lies within 0x40 / 0x20 /
 * 0x40 of it (obstacle Y raised by 0x20). */
/* 7E05C.s: trace an attack from `from` toward `to` in 32 steps of
 * (to - from) >> 5. Stop at the first actor (not `self`, not hidden by flags
 * 0xEA, not knocked down) whose bounds contain the point while in front of the
 * start, at an obstacle, or below the floor: store the point (pad = actor id
 * + 1, or 0) in `out` and return it. Returns 0 when nothing was hit. The start
 * X/Z are compared as GTE IR0/IR2 (16-bit), and the routine ends by falling
 * through into func_800E6EAC's return. The address comes back as a 32-bit
 * word: 146C.c declares the function int (an 8-byte pointer would be read
 * through a 4-byte return there). */
int func_800E6C34(unsigned* from, unsigned* to, unsigned* out, int self);


/* 7DE94.s: release actor `id`'s tile reservation (func_800E678C body) and
 * mark it held (0x1A = 1). The original enters func_800E678C's body with the
 * flag value; setting it afterwards is equivalent (nothing reads it there). */
void func_800E6764(int id);

/* 7DE94.s: release the reservation of actor `id` when its command (byte 9)
 * is one of the set 0xA41800 and its model has no motion flags (0xA & 0x1F,
 * 0xB & 0xB). */
void func_800E6700(int id);


/* 72B70.s: resolve a step onto a cell flagged 0x20 (e.g. a ledge or gap):
 * keep stepping in `dir` while cells stay flagged; at the first clear cell
 * within min(0xB2, 3) steps, return it with the step/entry result
 * (func_800D96C8, then func_800D954C) in bits 24-31. Unflagged targets are
 * returned unchanged. As in the original, the flagged-cell walk continues
 * past the step limit while byte 0xB2 is nonzero. */
unsigned func_800DB93C(void* state, unsigned tile, int dir, unsigned from);


/* 7BDD4.s: remember the best candidate's target (when there is one and the
 * actor is not locked, byte 0x19): 0x38 = target << 24 | current tile,
 * 0x3C = the target's tile, 0x40 = 900-frame memory. */
void func_800E4C8C(void* state);


/* Room-entry and actor bookkeeping helpers from 7BDD4.s and 7E05C.s. */
extern unsigned D_800F58D0, D_800F5920;
extern void* vs_main_allocHeap(unsigned);
extern void func_800E4288(void*, unsigned);

/* 7BDD4.s: pick the first armed reaction from the packed bytes at 0x224:
 * flag 0x20 (code 10) then 0x10 (code 9) when byte 1 is set, the reverse
 * otherwise. Low byte flags select byte 2, byte 1 flags select byte 3. */
int func_800E4764(void* state, int* value, int* code);


/* 7BDD4.s: clear the reaction word, copy 0x34 to 0x170 and issue actor
 * command 11 (func_800E4B10) or 12 (func_800E4B18). */
void func_800E4B10(void* state);

void func_800E4B18(void* state);


/* 7BDD4.s: clear (func_800E4BD8) or set (func_800E4BE0) bit `bit` of the
 * room record's byte 0xE. Bit 31 inverts the sign test, as in the original. */
static void room_flag(int bit, int clear)
{
    unsigned char* room = psx_to_ptr(unsigned char*, D_800F58BC);
    if (!room)
        return;
    int mask = 1 << (bit & 31);
    if (clear)
        mask = -1 - mask;
    room[0xE] = mask < 0 ? room[0xE] & mask : room[0xE] | mask;
}
void func_800E4BD8(int bit);

void func_800E4BE0(int bit);


/* 7BDD4.s: set actor `id`'s 0x13F countdown to 30 and fall through into
 * func_800E4C8C with that actor. */
void func_800E4C64(int id);


/* 7E05C.s: adjust the occupancy count of the tile under an actor's placement
 * word (0x5C) by +1 (func_800E6898) or -1 (func_800E68A0), in steps of 0x400. */
static void tile_occupancy(unsigned char* actor, int delta)
{
    unsigned placement = *(unsigned*)(actor + 0x5c);
    if (!D_800F58B8)
        return;
    unsigned short* cell =
        psx_to_ptr(unsigned short*, D_800F58D0 + (placement & 0xff) * 2 + ((placement << 8) >> 18));
    *cell += delta << 10;
}
void func_800E6898(void* actor);

void func_800E68A0(void* actor);

void func_800E68EC(int x, int z);


/* 7E05C.s: lowest of 16 floor heights sampled from (x0, z0) toward (x1, z1)
 * in steps of a sixteenth, starting at 0 (heights are 15-bit signed). */
int func_800E6A6C(int x0, int z0, int x1, int z1);

void func_800E6B24(int id);


/* 7E05C.s: when actor `id` is of type 11 or 14, its room-flag word (0x170,
 * bits 8-15) is set and its model byte 0xC has a zero low nibble, clear that
 * room flag. A missing record reads PS1 low RAM, as the original does. */
void func_800E6EB0(int id);


/* 7E05C.s: actors whose 0x16 target is `id` drop it (0x10), then release
 * actor `id`'s reservation through func_800D82CC. */
void func_800E7608(int id);

void func_800E7660(void* state);


/* Engagement state helpers from 7399C.s and 73B0C.s. */
extern int rand(void);
extern void func_800D8260(void*, int, int);

/* 7399C.s: leave the engaged state (0x13): restore the saved movement
 * callback (0x6C -> 0x68) and, unless 0x30 is set, queue the recovery motion. */
void func_800DC19C(void* state);


/* 7399C.s: enter the engaged state when forced, or on the second of two
 * rand() & 0x7F < 0x4C rolls; save 0x68 to 0x6C and install D_800DBC0C. */
void func_800DC210(void* state, int force);


/* 73B0C.s: move *value by `step` (up when mode is 2, else down) and clamp it
 * to 0..*limit. */
void func_800DC30C(short* value, short* limit, int step, int mode);

