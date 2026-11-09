/* Typed draw items: a frame as data (pc/docs/plans/2026-11-08-frames-as-data.md).
 *
 * Game code that used to build GPU packets and link them into an ordering table
 * adds items to the frame instead: a tile, a sprite or a polygon with its place,
 * texels, colour, draw mode and a depth to sort by. Nothing is written to guest
 * memory. The items live in one host list that is saved with the game's state
 * (draw_items.c), so a save state taken between building a frame and drawing it
 * keeps it.
 *
 * Draw order: a larger depth draws first (an ordering-table slot's number); items
 * of one depth draw in the opposite order to their submission, as packets linked
 * at the head of a slot did. pc_frame_draw draws the whole frame. A frame that
 * still has packets (a screen not converted yet) places a run of its items in the
 * ordering table with pc_frame_place: the walk draws them where the marker is.
 *
 * Today the host turns each item into the GP0 words the game used to write and
 * hands them to the packet path (the CPU rasterizer, the hardware path, ui_text,
 * the classic layer see what they saw). That is the transition's lowering; a
 * renderer that takes items directly replaces it. */
#ifndef ROOD_DRAW_ITEMS_H
#define ROOD_DRAW_ITEMS_H
/* (plain C types: the game's own headers, which do not have stdint.h, include it) */

#ifdef __cplusplus
extern "C" {
#endif

enum {
    PC_ITEM_NONE,   /* (a slot that draws nothing) */
    PC_ITEM_TILE,   /* a flat rectangle */
    PC_ITEM_SPRITE, /* a textured rectangle, texels copied 1:1 */
    PC_ITEM_POLY,   /* a triangle or quad: flat or shaded, textured or not */
    PC_ITEM_LINE,   /* a line from (x[0], y[0]) to (x[1], y[1]): flat, or shaded from rgb[0] to rgb[1] */
    PC_ITEM_AREA,   /* the drawing area for the items drawn after it: (x[0], y[0]) and w, h */
    PC_ITEM_MODE_SET, /* the draw mode (GP0 E1: `mode`) for the items drawn after it that carry none (PC_ITEM_INHERIT) */
    PC_ITEM_MASK    /* the mask bit set when drawing (x[0] 1) or not (0): GP0 E6 */
};

enum {
    PC_ITEM_SEMI = 1,     /* blends with what is behind it, by the mode's blend (a textured one: its STP texels) */
    PC_ITEM_RAW = 2,      /* textured: the texels as they are, not scaled by the colour */
    PC_ITEM_TEXTURED = 4, /* polygon: samples a texture (a sprite always does) */
    PC_ITEM_SHADED = 8,   /* polygon: a colour at each corner (else rgb[0] for all) */
    PC_ITEM_BRACKET = 16, /* polygon or line, as the effect plugins drew: with dither off, the draw mode (a line's is
                           * `mode`) set for it alone, and page 0, no blend, dither on left after it */
    PC_ITEM_PLACED = 32,  /* a marker in an ordering table draws it (set by pc_frame_place) */
    PC_ITEM_WINDOW = 64,  /* `tw` is the texture window it draws with (GP0 E2); without the flag the window is left as it is */
    PC_ITEM_AFTER = 128,  /* `after` is the draw mode (GP0 E1) left set after it; without the flag the mode it drew with stays */
    PC_ITEM_BEFORE = 256  /* textured polygon: `before` is the draw mode (GP0 E1) set before it, whose dither and display bits it
                           * draws with (its own page word sets the rest) */
};

/* The draw mode a tile, a sprite or an untextured polygon draws with, from a
 * libgpu texture page word (getTPage: page, blend, colour depth): what
 * SetDrawTPage(.., 0, 1, page) set, dither on. A textured polygon carries its
 * own page in `mode` (as its packet did): give it the page word as it was. */
/* A flat item with this mode draws in whatever draw mode the GPU is in (the packet had no draw mode before it). */
#define PC_ITEM_INHERIT 0xffff
#define PC_ITEM_MODE(page) (((page) & 0x9ff) | 0x200)
/* A colour as the items take it: 0xBBGGRR, each channel cut to a byte. */
#define PC_RGB(r, g, b) (((r) & 0xff) | ((g) & 0xff) << 8 | ((b) & 0xff) << 16)
#define PC_GREY(v) (((v) & 0xff) * 0x010101)

typedef struct {
    unsigned char kind;  /* PC_ITEM_* */
    unsigned char verts; /* polygon: 3 or 4 */
    unsigned short flags; /* PC_ITEM_* flags */
    unsigned short group; /* items added together as one call (pc_frame_add_packets) share it; 0: none */
    unsigned short mode; /* see PC_ITEM_MODE */
    unsigned short clut; /* textured: the CLUT word (y << 6 | x >> 4) */
    int depth; /* sort key: larger first (see above) */
    short x[4], y[4]; /* polygon corners; a rectangle's top left is x[0], y[0] */
    short w, h;       /* a rectangle's size */
    unsigned char u[4], v[4]; /* textured: texel at each corner (a sprite's top left is u[0], v[0]) */
    unsigned char rgb[4][3];  /* colour per corner; a flat item's is rgb[0] */
    unsigned tw;              /* PC_ITEM_WINDOW: the window word's 20 bits */
    unsigned short after;     /* PC_ITEM_AFTER: the draw mode word's bits */
    unsigned short before;    /* PC_ITEM_BEFORE: likewise */
} pc_item;

/* A new frame: the previous frame's items are dropped. */
void pc_frame_begin(void);
/* The next item, zeroed with its kind and depth set; NULL when the frame is full
 * (it is logged once and the item is left out). */
pc_item* pc_frame_add(int kind, int depth);
/* Helpers for the common ones (rgb, mode and clut are cut to their fields). */
void pc_frame_tile(int depth, int x, int y, int w, int h, int rgb, int mode, int flags);
void pc_frame_sprite(int depth, int x, int y, int w, int h, int u, int v, int rgb, int clut, int mode, int flags);
/* The next polygon item of a run of one, placed in the ordering table at slot
 * `depth` of the table at `ot` with a marker packet taken from `*cursor` (the
 * packet cursor, moved past it); a NULL `ot` places nothing (a frame of items alone). When the frame is full a spare item is returned
 * that is never drawn, so the caller can fill it all the same. */
pc_item* pc_frame_poly_at(int depth, int kind, int verts, int flags, unsigned* ot, unsigned** cursor);
/* The number of items so far: the first index of the next run. */
int pc_frame_count(void);
/* The classic layer's protocol (pc/src/classic): a site is a range of items, [first, end) of the frame's
 * list. pc_frame_site sets the range of the site about to be reported (PC_CLASSIC does, around the
 * statement), pc_frame_site_range reads it. */
void pc_frame_site(int first, int end);
void pc_frame_site_range(int* first, int* end);
/* Items [first, end) are no longer drawn (kind none); how many were. Items are mutable until the frame ends. */
int pc_frame_suppress(int first, int end);
/* Drops the items from index `count` on (a draw that was never to show, given back). */
void pc_frame_rewind(int count);
/* Whether item `index` is placed in an ordering table, and its kind. */
int pc_frame_is_placed(int index);
/* Raw GP0 words in draw order (one packet's payload, or several joined) as items at `depth`: polygons, tiles, sprites,
 * flat lines and drawing areas, each with the draw mode (E1) and texture window (E2) the words had set before it.
 * The items are added so that they draw in the order of the words. Returns how many items were added (from index *first); 0 when the words are anything else (a primitive with no
 * draw mode set before it, a state word after the last primitive, other commands): nothing is added then. */
int pc_frame_add_packets(int depth, const unsigned* words, int n, int* first);
/* Items [first, first + count) in the order they draw (the larger depth first, then the later submission first),
 * leaving out items that are placed in a table when `unplaced` is set; their indices go to out (at most max). */
int pc_frame_order(int first, int count, int unplaced, int* out, int max);
/* The packets item `index` is: what the GPU is given for it, up to three (a texture window, a draw mode, then the
 * primitive; a polygon that carries its page has no mode packet). The payload words of packet k go to words[k] (at most 16),
 * how many in lengths[k]; returns the number of packets. */
int pc_frame_lower(int index, unsigned words[3][16], int lengths[3]);
/* Widescreen: items [first, end) anchored as pc_hw_anchor_packets does a range of packets (their lowered packets have
 * a stable address per index). */
void pc_frame_anchor(int first, int end, int anchor);
/* Item `index`, to read or change before the frame is drawn; NULL out of range. */
pc_item* pc_frame_item(int index);
/* The command word of item `index`'s lowered packet: ui_text keys its words on it, as it did on a packet's. The index
 * of the item a command word belongs to, -1 when it is none's. */
const void* pc_frame_command(int index);
int pc_frame_command_item(const void* command);
/* The address of item `index`'s lowered packet (where the draw puts it; the key of anchors and interpolation). */
const void* pc_frame_packet(int index);
/* Lifting a packet printer's output to items (pc/src/hud/hud_bridge.c: the classic claims' commands): the game's printers keep
 * writing packets for the claims that call them; pc_lift_begin returns the word they link at, pc_lift_end turns what they wrote
 * into items placed at `ot` (a marker) or alone. A printer that adds items itself writes nothing to lift. */
void* pc_lift_begin(void);
int pc_lift_end(int depth, int placed, void* ot);
/* Whether `packet` is a marker (pc_frame_place) and the run of items it places. */
int pc_frame_marker(const unsigned* packet, int* first, int* count);
/* A packet printer's last step: the packet's words (no tag) as items, placed at `ot_entry` by a marker taken from `cursor`.
 * Returns the cursor past the marker, or NULL when the words are not items (pc_frame_add_packets): the printer then
 * writes the packet as it always did. The printers (shared with battle) keep their signatures and slots. */
unsigned* pc_frame_lift_words(const unsigned* words, int n, unsigned* ot_entry, unsigned* cursor);
/* A printer's call: its items [first, first + count) are one group (ui_text finds a word by it), and a draw mode alone is an
 * item too (a printer with nothing to print still set its draw mode). */
void pc_frame_group(int first, int count);
void pc_frame_mode_item(int depth, int mode);
/* The runs a marker placed in [start, end) of packet memory are anchored as that range is (pc_hw_anchor_packets). */
void pc_frame_anchor_markers(const void* start, const void* end, int anchor);
/* Draws the frame's items in order: what DrawOTag did for a table. */
void pc_frame_draw(void);
/* Links a marker for items [first, first + count) at the head of `*ot_entry`
 * in a packet of four words at `packet`; returns the next free word. The
 * ordering-table walk draws the run (in order among themselves) where the
 * marker is, with the drawing state in effect there. */
unsigned* pc_frame_place(int first, int count, unsigned* ot_entry, unsigned* packet);

#ifdef __cplusplus
}
#endif
#endif
