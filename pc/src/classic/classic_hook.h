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
/* A target row (58578.c func_800C1DC4: a part's name and its plate), as the game reads it before it draws: the row
 * (identity only), its name, place (x the row's, y with the list's offset), selected, the plate's fade step
 * (before the call steps it), its colour bank and its ordering-table slot (bytes from vs_scratch.unk4). */
typedef struct {
    const void* row;
    const char* text;
    int x, y, selected, fade, bank, slot;
} pc_classic_target_row;
#define PC_CLASSIC_SITE_TARGET_ROW 20
/* A selected row's leader lines (func_800C1DC4's func_800C16FC / func_800C1A40 calls): the row (identity only), the
 * line's start (its 3D point projected), the row's place and the line's age (unk3: the lines' sweep). */
typedef struct {
    const void* row;
    int x, y, row_x, row_y, age;
} pc_classic_target_line;
#define PC_CLASSIC_SITE_TARGET_LINE 21
/* The area target's marker (58578.c func_800C28AC): its place (the point projected), lock (the call's arg1: the
 * pitch locked, the brackets' quads off and the other sprites) and its brightness step (D_800EA6AC, stepped). */
typedef struct { int x, y, lock, step; } pc_classic_target_marker;
#define PC_CLASSIC_SITE_TARGET_MARKER 22
/* MAINMENU's shared frame (58EC.c), every menu screen's: the background (its fade step, the opaque brightness, its
 * slot: words from vs_scratch.unk4, the frame buffer), the command title's sprite (the action shown, its slide),
 * a row of vs_battle_menuItems (its emit after its slide is stepped: the row, identity only; its id; a copy of its
 * record, 0x40 bytes, before the emit steps its gradient), the pointing hand (vs_mainMenu_renderCursor: its
 * step, packed place, colour) and the tab arrows (vs_mainMenu_renderTabNavigation: mode, the step just taken,
 * lit). */
typedef struct { int fade, brightness, slot, frame; } pc_classic_menu_background;
#define PC_CLASSIC_SITE_MENU_BACKGROUND 23
typedef struct { int action, y; } pc_classic_menu_command;
#define PC_CLASSIC_SITE_MENU_COMMAND 24
typedef struct {
    const void* row;
    int id;
    unsigned char item[0x40];
} pc_classic_menu_row;
#define PC_CLASSIC_SITE_MENU_ROW 25
typedef struct { int step, xy, color; } pc_classic_menu_cursor;
#define PC_CLASSIC_SITE_MENU_CURSOR 26
typedef struct { int mode, step, lit; } pc_classic_menu_tabs;
#define PC_CLASSIC_SITE_MENU_TABS 27
/* A row's value in our Option pages (pc/src/ui/classic_options.c draw_values: not the game's, but drawn with its
 * printers): the page's row (its index), kind (PC_UI_SET_*), enabled, focused, the choice's index; the column's x
 * and the window's right end; the colours (current, other); the toggle's gap; the slider's gauge (colour, width,
 * fill); a link's target there; capitals; the window's x and the row's y; the texts (value, the toggle's two
 * names, a note's label: the page model's, read only). */
typedef struct {
    int row, kind, enabled, focused, index, x, right, lit, other, gap, bar_colour, bar_width, fill, link, upper,
        window_x, y;
    const char *value, *on, *off, *label;
} pc_classic_option_value;
#define PC_CLASSIC_SITE_OPTION_VALUE 28
#define PC_CLASSIC_SITE_STATUS_PANEL 29 /* classic_parity.h PC_CLASSIC_STATUS_PANEL: func_800CA2DC */
/* MAINMENU's shared frame (58EC.c), read for the menu model (pc/src/classic/menu_model.c, rood.game.menu()): the
 * statics its list and command title keep (the list's cursor row and page, the sub-menu's id, row info and row
 * count, whether its rows take input (_itemsText), the rows' y offset; the command title's current and next). */
typedef struct {
    int row, page, sub_menu, row_info, row_count, list_open, row_offset, command, command_next;
} pc_classic_mainmenu;
void pc_classic_mainmenu_read(pc_classic_mainmenu* out); /* 58EC.c */
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
