/* The screens that drew with DrawPrim (the file menu, the title's copy of it) build their primitives as draw items
 * (pc/src/draw_items.h) and draw them at once: vs_now_begin, the items, vs_now_end (one packet through DrawPrim, as the
 * screen made it, then the items are dropped). Colours as 0xBBGGRR, places as x in the low half and y in the high, the
 * draw mode as the GP0 E1 word's bits (vs_getTpage), or PC_ITEM_INHERIT: the mode the GPU is in. */
#ifndef VS_IMMEDIATE_ITEM_H
#define VS_IMMEDIATE_ITEM_H
#include "pc/src/draw_items.h"

static inline int vs_now_begin(void) { return pc_frame_count(); }
static inline void vs_now_end(int first) { pc_frame_immediate(first); }
/* The command word of the last primitive the items from `first` make, in the packet vs_now_end draws (ui_text keys on it). */
static inline const void* vs_now_command(int first) { return pc_frame_immediate_command(first); }

static inline pc_item* vs_now_item(int kind, int verts, int flags, int mode)
{
    static pc_item spare; /* (a full frame: the item is made, and never drawn) */
    pc_item* item = pc_frame_add(kind, 0);
    if (!item)
        item = &spare, spare = (pc_item) { 0 };
    item->kind = (unsigned char)kind, item->verts = (unsigned char)verts, item->flags = (unsigned short)flags;
    item->mode = mode == PC_ITEM_INHERIT ? PC_ITEM_INHERIT : (unsigned short)(mode & 0x3fff);
    return item;
}
static inline void vs_now_xy(pc_item* item, int corner, int xy)
{
    item->x[corner] = (short)xy, item->y[corner] = (short)(xy >> 16);
}
static inline void vs_now_rgb(pc_item* item, int corner, int rgb)
{
    item->rgb[corner][0] = (unsigned char)rgb, item->rgb[corner][1] = (unsigned char)(rgb >> 8),
    item->rgb[corner][2] = (unsigned char)(rgb >> 16);
}

/* The draw mode alone (a packet that set it, and drew nothing). */
static inline void vs_now_mode(int mode) { vs_now_item(PC_ITEM_MODE_SET, 0, 0, mode); }
static inline void vs_now_words(const unsigned* words, int n) { pc_frame_immediate_words(words, n); }
/* A flat tile (wh: width low, height high). */
static inline void vs_now_tile(int mode, int semi, int rgb, int xy, int wh)
{
    pc_item* item = vs_now_item(PC_ITEM_TILE, 0, semi ? PC_ITEM_SEMI : 0, mode);
    vs_now_rgb(item, 0, rgb), vs_now_xy(item, 0, xy);
    item->w = (short)wh, item->h = (short)(wh >> 16);
}
/* A shaded quad (POLY_G4). */
static inline void vs_now_g4(int mode, int semi, int c0, int xy0, int c1, int xy1, int c2, int xy2, int c3, int xy3)
{
    pc_item* item = vs_now_item(PC_ITEM_POLY, 4, PC_ITEM_SHADED | (semi ? PC_ITEM_SEMI : 0), mode);
    vs_now_rgb(item, 0, c0), vs_now_xy(item, 0, xy0);
    vs_now_rgb(item, 1, c1), vs_now_xy(item, 1, xy1);
    vs_now_rgb(item, 2, c2), vs_now_xy(item, 2, xy2);
    vs_now_rgb(item, 3, c3), vs_now_xy(item, 3, xy3);
}
/* A textured rectangle (SPRT: uv_clut as vs_getUV0Clut packs it), the texels scaled by `rgb`. */
static inline void vs_now_sprite(int mode, int semi, int rgb, int xy, int uv_clut, int wh)
{
    pc_item* item = vs_now_item(PC_ITEM_SPRITE, 0, semi ? PC_ITEM_SEMI : 0, mode);
    vs_now_rgb(item, 0, rgb), vs_now_xy(item, 0, xy);
    item->u[0] = (unsigned char)uv_clut, item->v[0] = (unsigned char)(uv_clut >> 8), item->clut = (unsigned short)(uv_clut >> 16);
    item->w = (short)wh, item->h = (short)(wh >> 16);
}
#endif
