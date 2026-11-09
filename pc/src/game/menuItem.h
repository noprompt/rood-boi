/* The menus' flat and shaded primitives as typed draw items (pc/src/draw_items.h), for the screens that built them
 * as packets by hand. Each takes the words the packet had: colours as 0xBBGGRR (a code in the top byte is ignored), places
 * as x in the low half and y in the high, the draw mode as the GP0 E1 word (vs_getTpage). `depth` is the ordering-table
 * slot the packet was linked at, in words from vs_scratch.unk4 (unk8 is -16): the item takes its place there by a
 * marker, as the packet did. */
#ifndef VS_MENU_ITEM_H
#define VS_MENU_ITEM_H
#include "pc/src/game/EFFECT/effectItem.h"

/* A shaded quad (POLY_G4: its four points, the first's colour in its own word), semi-transparent when `semi`. */
static inline void vs_menu_g4(int depth, int mode, int semi, unsigned c0, unsigned xy0, unsigned c1, unsigned xy1,
    unsigned c2, unsigned xy2, unsigned c3, unsigned xy3)
{
    pc_item* item = vs_effect_item(PC_ITEM_POLY, 4, PC_ITEM_SHADED | (semi ? PC_ITEM_SEMI : 0), depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    vs_effect_rgb(item, 0, (int)c0), vs_effect_xy(item, 0, (int)xy0);
    vs_effect_rgb(item, 1, (int)c1), vs_effect_xy(item, 1, (int)xy1);
    vs_effect_rgb(item, 2, (int)c2), vs_effect_xy(item, 2, (int)xy2);
    vs_effect_rgb(item, 3, (int)c3), vs_effect_xy(item, 3, (int)xy3);
}

/* The same, with the E1 word `after` left as the draw mode. */
static inline void vs_menu_g4_after(int depth, int mode, int after, unsigned c0, unsigned xy0, unsigned c1, unsigned xy1,
    unsigned c2, unsigned xy2, unsigned c3, unsigned xy3)
{
    pc_item* item = vs_effect_item(PC_ITEM_POLY, 4, PC_ITEM_SHADED | PC_ITEM_AFTER, depth);
    item->mode = (unsigned short)(mode & 0x3fff);
    item->after = (unsigned short)(after & 0x3fff);
    vs_effect_rgb(item, 0, (int)c0), vs_effect_xy(item, 0, (int)xy0);
    vs_effect_rgb(item, 1, (int)c1), vs_effect_xy(item, 1, (int)xy1);
    vs_effect_rgb(item, 2, (int)c2), vs_effect_xy(item, 2, (int)xy2);
    vs_effect_rgb(item, 3, (int)c3), vs_effect_xy(item, 3, (int)xy3);
}

/* A flat tile (wh: width low, height high) and a flat line: in the E1 word `mode`, or (0) in whatever draw mode the GPU is in. */
static inline void vs_menu_tile(int depth, int mode, int semi, unsigned c, unsigned xy, unsigned wh)
{
    pc_item* item = vs_effect_item(PC_ITEM_TILE, 0, semi ? PC_ITEM_SEMI : 0, depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    vs_effect_rgb(item, 0, (int)c), vs_effect_xy(item, 0, (int)xy);
    item->w = (short)wh, item->h = (short)(wh >> 16);
}
static inline void vs_menu_line(int depth, int mode, int semi, unsigned c, unsigned xy0, unsigned xy1)
{
    pc_item* item = vs_effect_item(PC_ITEM_LINE, 0, semi ? PC_ITEM_SEMI : 0, depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    vs_effect_rgb(item, 0, (int)c), vs_effect_xy(item, 0, (int)xy0), vs_effect_xy(item, 1, (int)xy1);
}

/* A shaded triangle (POLY_G3). */
static inline void vs_menu_g3(int depth, int mode, int semi, unsigned c0, unsigned xy0, unsigned c1, unsigned xy1, unsigned c2,
    unsigned xy2)
{
    pc_item* item = vs_effect_item(PC_ITEM_POLY, 3, PC_ITEM_SHADED | (semi ? PC_ITEM_SEMI : 0), depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    vs_effect_rgb(item, 0, (int)c0), vs_effect_xy(item, 0, (int)xy0);
    vs_effect_rgb(item, 1, (int)c1), vs_effect_xy(item, 1, (int)xy1);
    vs_effect_rgb(item, 2, (int)c2), vs_effect_xy(item, 2, (int)xy2);
}

/* The draw mode (the E1 word) for what draws after it that has none of its own: a packet that set it alone. */
static inline void vs_menu_mode(int depth, int mode)
{
    vs_effect_item(PC_ITEM_MODE_SET, 0, 0, depth)->mode = (unsigned short)(mode & 0x3fff);
}

/* The mask bit set when drawing (DR_STP: SetDrawStp). */
static inline void vs_menu_mask(int depth, int on) { vs_effect_item(PC_ITEM_MASK, 0, 0, depth)->x[0] = (short)(on != 0); }

/* A flat quad (POLY_F4), in the E1 word `mode`. */
static inline void vs_menu_f4(int depth, int mode, int semi, unsigned c, unsigned xy0, unsigned xy1, unsigned xy2, unsigned xy3)
{
    pc_item* item = vs_effect_item(PC_ITEM_POLY, 4, semi ? PC_ITEM_SEMI : 0, depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    vs_effect_rgb(item, 0, (int)c);
    vs_effect_xy(item, 0, (int)xy0), vs_effect_xy(item, 1, (int)xy1), vs_effect_xy(item, 2, (int)xy2), vs_effect_xy(item, 3, (int)xy3);
}

/* A textured quad (POLY_FT4): its corners, texels (u low, v high each) and the texture page word and CLUT word it names;
 * semi-transparent when `semi`, drawn as the texels are (raw) when `raw`; `before` the E1 word set before it, or 0. */
static inline void vs_menu_ft4(int depth, int before, int tpage, int clut, int semi, int raw, unsigned c, unsigned xy0, unsigned xy1,
    unsigned xy2, unsigned xy3, unsigned uv0, unsigned uv1, unsigned uv2, unsigned uv3)
{
    pc_item* item = vs_effect_item(
        PC_ITEM_POLY, 4, PC_ITEM_TEXTURED | (semi ? PC_ITEM_SEMI : 0) | (raw ? PC_ITEM_RAW : 0), depth);
    item->mode = (unsigned short)tpage;
    item->clut = (unsigned short)clut;
    if (before) /* (the draw mode set before it, the E1 word: its dither bits stay) */
        item->flags |= PC_ITEM_BEFORE, item->before = (unsigned short)(before & 0x3fff);
    vs_effect_rgb(item, 0, (int)c);
    vs_effect_xy(item, 0, (int)xy0), vs_effect_xy(item, 1, (int)xy1), vs_effect_xy(item, 2, (int)xy2), vs_effect_xy(item, 3, (int)xy3);
    vs_effect_uv(item, 0, (int)uv0), vs_effect_uv(item, 1, (int)uv1), vs_effect_uv(item, 2, (int)uv2), vs_effect_uv(item, 3, (int)uv3);
}

/* A drawing area (x, y, w, h). */
static inline void vs_menu_area(int depth, int x, int y, int w, int h)
{
    pc_item* item = vs_effect_item(PC_ITEM_AREA, 0, 0, depth);
    item->x[0] = (short)x, item->y[0] = (short)y, item->w = (short)w, item->h = (short)h;
}

/* A sprite (a textured rectangle): its place, size, texels, colour (0 for a raw one) and CLUT, in the E1 word `mode`. */
static inline void vs_menu_sprite(int depth, int mode, int semi, int raw, unsigned c, int x, int y, int w, int h, int u, int v,
    int clut)
{
    pc_item* item = vs_effect_item(PC_ITEM_SPRITE, 0, (semi ? PC_ITEM_SEMI : 0) | (raw ? PC_ITEM_RAW : 0), depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    item->clut = (unsigned short)clut;
    vs_effect_rgb(item, 0, (int)c);
    item->x[0] = (short)x, item->y[0] = (short)y, item->w = (short)w, item->h = (short)h;
    item->u[0] = (unsigned char)u, item->v[0] = (unsigned char)v;
}

/* The slot a packet linked at `ot` is, as a depth: words from vs_scratch.unk4. */
static inline int vs_menu_depth(const void* ot) { return (int)((const unsigned*)ot - (const unsigned*)psx_get(vs_scratch.unk4)); }

/* A shaded line between two points, drawn in `mode`, with the E1 word `after` left as the draw mode (0: it is left as it was). */
static inline void vs_menu_line_g(int depth, int mode, int after, int semi, unsigned c0, unsigned xy0, unsigned c1, unsigned xy1)
{
    pc_item* item = vs_effect_item(PC_ITEM_LINE, 0, PC_ITEM_SHADED | (semi ? PC_ITEM_SEMI : 0) | (after ? PC_ITEM_AFTER : 0), depth);
    item->mode = mode ? (unsigned short)(mode & 0x3fff) : PC_ITEM_INHERIT;
    item->after = (unsigned short)(after & 0x3fff);
    vs_effect_rgb(item, 0, (int)c0), vs_effect_xy(item, 0, (int)xy0);
    vs_effect_rgb(item, 1, (int)c1), vs_effect_xy(item, 1, (int)xy1);
}
#endif
