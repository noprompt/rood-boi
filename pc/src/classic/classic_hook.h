/* The classic look drawn in Lua (plan pc/docs/plans/2026-10-20-classic-ui-in-lua.md
 * §2): the game side's hook, under ROOD_PC only.
 *
 * PC_CLASSIC wraps the call that draws one of the game's classic elements:
 * the packets the statement allocates from the scratchpad's packet pointer
 * (0x1F800000), its place and the game's record go to pc_classic_site
 * (pc/src/classic/classic_bridge.c), which
 *   - keeps them as the kind's capture (RPC packets, the parity gate),
 *   - and, when a plugin's classic claim on the kind is honoured, turns them
 *     into no-ops and has the claim emit its own in the same ordering-table
 *     slot (emit-only suppression: the statement still runs, so whatever
 *     game state it steps is stepped as before).
 * Without a claim nothing changes: the game's own drawing is the fallback.
 * The kinds are classic_parity.h's PC_CLASSIC_* (the HUD layer's kinds keep
 * their numbers: hud_hook.h's PC_HUD is this hook). */
#ifndef ROOD_CLASSIC_HOOK_H
#define ROOD_CLASSIC_HOOK_H
#ifdef ROOD_PC
#define PC_CLASSIC_SITE_GAUGES 8       /* classic_parity.h PC_CLASSIC_GAUGES: func_800CA2DC's gauges */
#define PC_CLASSIC_SITE_FIGURE 9       /* Ashley's five limb sprites */
/* Snapshot at the status carousel's emit boundary; no game pointers escape. */
typedef struct {
    int previous, current, next, count, selected, offset, slide;
} pc_classic_status_icons;
#define PC_CLASSIC_SITE_STATUS_ICONS 10
typedef struct { int step, slide, pulse; } pc_classic_battle_mode;
#define PC_CLASSIC_SITE_BATTLE_MODE 11
typedef struct { int animation, offset, group, availability; } pc_classic_ability_icons;
#define PC_CLASSIC_SITE_ABILITY_ICONS 12
/* A word over an actor at the label loop's call (2842C.c): its record (identity only), which draw the game chose
 * (MISS, or the combat label), and that draw's inputs, copied before it runs. */
typedef struct { const void* label; int miss, age, index, lowered; } pc_classic_actor_word;
#define PC_CLASSIC_SITE_ACTOR_WORD 13
#define PC_CLASSIC_SITE_TIMER 14 /* _renderTimer: its record the string it composed (D_800EC258) */
/* An emote over an actor (2842C.c func_80095C18), as the game decided it inside the function: draw 1 the
 * balloon and its marks (kind, side, the screen place, z the depth slot), 2 the off-screen arrow
 * (func_8009651C: direction, the clamped place), 3 a far actor's sprite (frame); 0 nothing. */
typedef struct { int draw, kind, side, x, y, z, direction, frame; } pc_classic_emote;
#define PC_CLASSIC_SITE_EMOTE 15
#define PC_CLASSIC_SITE_TEXT_FRAME 16 /* func_800CD3E4: its record the text box (read only), x its id */
#define PC_CLASSIC_SITE_TEXT_BAND 17 /* func_800CD158: likewise */
#define PC_CLASSIC_SITE_BOX_TEXT 18 /* _printVariableWidthFont: likewise (its glyphs recorded as it sets them) */
/* An image (func_800CCA90: the portraits and stills): its index (0..2), drawer (D_800EC25C), CLUT word and slot
 * (bytes from vs_scratch.unk4: the table's far end, or after unk8). */
typedef struct {
    int image, mode, clut, slot;
    void* gim; /* its record (gim_t: identity, for the drawer) */
} pc_classic_image;
#define PC_CLASSIC_SITE_IMAGE 19
#define PC_CLASSIC_SITE_STATUS_PANEL 20 /* classic_parity.h PC_CLASSIC_STATUS_PANEL: func_800CA2DC */
void pc_classic_site(int kind, void* record, int x, int y, void* first, void* end) __attribute__((weak));
#define PC_CLASSIC(kind, record, x, y, statement) \
    do { \
        void* pc_classic_first = psx_load(void*, (u_int*)0x1F800000); \
        statement; \
        if (pc_classic_site) \
            pc_classic_site(kind, record, x, y, pc_classic_first, psx_load(void*, (u_int*)0x1F800000)); \
    } while (0)
#endif
#endif
