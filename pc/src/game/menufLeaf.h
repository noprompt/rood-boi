/* The drawing leaves MENUF's screens and ENDING's MISSION COMPLETE screen share (renderTextures.h, MENUF's 3B8.c)
 * as typed draw items (pc/src/draw_items.h). They draw at depth -7, where their packets linked: 28 bytes before
 * vs_scratch.unk4. MENUF draws in the game's ordering table, which places an item with a marker packet; ENDING's frame
 * is items alone. The includer sets PC_LEAF_TABLE to 1 or 0 first. */
#ifndef VS_MENUF_LEAF_H
#define VS_MENUF_LEAF_H
#include "common.h"
#include "scratch.h"
#include "texture_t.h"
#include "pc/src/draw_items.h"

#define PC_LEAF_DEPTH -7

/* A leaf's item of `kind` (PC_ITEM_POLY, PC_ITEM_AREA): filled by the caller; a full frame's is a spare. */
static inline pc_item* _leafItem(int kind, int verts, int flags)
{
#if PC_LEAF_TABLE
    unsigned* cursor = psx_get(vs_scratch.unk0);
    pc_item* item = pc_frame_poly_at(PC_LEAF_DEPTH, kind, verts, flags, psx_get(vs_scratch.unk4), &cursor);
    psx_set(vs_scratch.unk0, cursor);
#else
    pc_item* item = pc_frame_poly_at(PC_LEAF_DEPTH, kind, verts, flags, NULL, NULL);
#endif
    return item;
}

/* A texture's quad at (x, y): its corners and texels in the order the packets set them (setXY4, setUV4: the
 * quad's four points, left to right and top to bottom), the texels' bytes wrapping as the game's do. */
static inline void _leafQuad(pc_item* item, int x, int y, const _texture_t* texture)
{
    item->x[0] = (short)x, item->y[0] = (short)y;
    item->x[1] = (short)(texture->w + x), item->y[1] = (short)y;
    item->x[2] = (short)x, item->y[2] = (short)(texture->h + y);
    item->x[3] = (short)(texture->w + x), item->y[3] = (short)(texture->h + y);
    item->u[0] = (unsigned char)texture->x, item->v[0] = (unsigned char)texture->y;
    item->u[1] = (unsigned char)(texture->x + texture->w), item->v[1] = (unsigned char)texture->y;
    item->u[2] = (unsigned char)texture->x, item->v[2] = (unsigned char)(texture->y + texture->h);
    item->u[3] = (unsigned char)(texture->x + texture->w), item->v[3] = (unsigned char)(texture->y + texture->h);
}

/* A drawing area item for `rect` (SetDrawArea's fields). */
static inline void _leafArea(pc_item* item, const RECT* rect)
{
    item->x[0] = (short)rect->x, item->y[0] = (short)rect->y;
    item->w = (short)rect->w, item->h = (short)rect->h;
}

/* The colour of corner `i` from three bytes. */
static inline void _leafRgb(pc_item* item, int i, int r, int g, int b)
{
    item->rgb[i][0] = (unsigned char)r, item->rgb[i][1] = (unsigned char)g, item->rgb[i][2] = (unsigned char)b;
}
#endif
