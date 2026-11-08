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
    PC_ITEM_LINE    /* a flat line from (x[0], y[0]) to (x[1], y[1]) */
};

enum {
    PC_ITEM_SEMI = 1,     /* blends with what is behind it, by the mode's blend (a textured one: its STP texels) */
    PC_ITEM_RAW = 2,      /* textured: the texels as they are, not scaled by the colour */
    PC_ITEM_TEXTURED = 4, /* polygon: samples a texture (a sprite always does) */
    PC_ITEM_SHADED = 8,   /* polygon: a colour at each corner (else rgb[0] for all) */
    PC_ITEM_BRACKET = 16  /* polygon or line, as the effect plugins drew: with dither off, the draw mode (a line's is
                           * `mode`) set for it alone, and page 0, no blend, dither on left after it */
};

/* The draw mode a tile, a sprite or an untextured polygon draws with, from a
 * libgpu texture page word (getTPage: page, blend, colour depth): what
 * SetDrawTPage(.., 0, 1, page) set, dither on. A textured polygon carries its
 * own page in `mode` (as its packet did): give it the page word as it was. */
#define PC_ITEM_MODE(page) (((page) & 0x9ff) | 0x200)
/* A colour as the items take it: 0xBBGGRR, each channel cut to a byte. */
#define PC_RGB(r, g, b) (((r) & 0xff) | ((g) & 0xff) << 8 | ((b) & 0xff) << 16)
#define PC_GREY(v) (((v) & 0xff) * 0x010101)

typedef struct {
    unsigned char kind;  /* PC_ITEM_* */
    unsigned char flags; /* PC_ITEM_* flags */
    unsigned char verts; /* polygon: 3 or 4 */
    unsigned char spare;
    unsigned short mode; /* see PC_ITEM_MODE */
    unsigned short clut; /* textured: the CLUT word (y << 6 | x >> 4) */
    int depth; /* sort key: larger first (see above) */
    short x[4], y[4]; /* polygon corners; a rectangle's top left is x[0], y[0] */
    short w, h;       /* a rectangle's size */
    unsigned char u[4], v[4]; /* textured: texel at each corner (a sprite's top left is u[0], v[0]) */
    unsigned char rgb[4][3];  /* colour per corner; a flat item's is rgb[0] */
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
 * packet cursor, moved past it). When the frame is full a spare item is returned
 * that is never drawn, so the caller can fill it all the same. */
pc_item* pc_frame_poly_at(int depth, int kind, int verts, int flags, unsigned* ot, unsigned** cursor);
/* The number of items so far: the first index of the next run. */
int pc_frame_count(void);
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
