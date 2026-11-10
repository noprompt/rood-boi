/* An effect's polygon or line as a typed draw item (pc/src/draw_items.h). It takes the place in the
 * battle ordering table that the packet had: the marker packet links at slot `depth`, so the item draws
 * among the frame's other packets and native lists where the packet did. The item's fields are the
 * packet's: corners and texels as the GPU takes them, a texture page in `mode`. */
#ifndef VS_EFFECT_ITEM_H
#define VS_EFFECT_ITEM_H
#include "common.h"
#include "scratch.h"
#include "pc/src/draw_items.h"

/* The kinds the plugins draw: semi-transparent, bracketed by the default draw mode (the packets'). */
#define VS_EFFECT_GT4 (PC_ITEM_TEXTURED | PC_ITEM_SHADED | PC_ITEM_SEMI | PC_ITEM_BRACKET)
#define VS_EFFECT_GT3 VS_EFFECT_GT4
#define VS_EFFECT_FT4 (PC_ITEM_TEXTURED | PC_ITEM_SEMI | PC_ITEM_BRACKET)
#define VS_EFFECT_LINE (PC_ITEM_SEMI | PC_ITEM_BRACKET)

static inline pc_item* vs_effect_item(int kind, int verts, int flags, int depth)
{
    unsigned* cursor = vs_scratch.unk0;
    pc_item* item = pc_frame_poly_at(depth, kind, verts, flags, vs_scratch.unk4, &cursor);
    vs_scratch.unk0 = cursor;
    return item;
}

/* A corner from the GTE's packed screen position (x in the low half, y in the high). */
static inline void vs_effect_xy(pc_item* item, int corner, int sxy)
{
    item->x[corner] = (short)sxy;
    item->y[corner] = (short)(sxy >> 16);
}

/* A corner's texel from a u, v byte pair (u in the low byte). */
static inline void vs_effect_uv(pc_item* item, int corner, int uv)
{
    item->u[corner] = (unsigned char)uv;
    item->v[corner] = (unsigned char)(uv >> 8);
}

/* A corner's colour from a colour word (r, g, b in the low three bytes). */
static inline void vs_effect_rgb(pc_item* item, int corner, int word)
{
    item->rgb[corner][0] = (unsigned char)word;
    item->rgb[corner][1] = (unsigned char)(word >> 8);
    item->rgb[corner][2] = (unsigned char)(word >> 16);
}

/* A ribbon segment's quad from a template item: its corners' positions and texels, with the texture page
 * and CLUT. The caller sets the colours. */
static inline void vs_effect_quad(pc_item* item, const pc_item* quad, int mode, int clut)
{
    int i;
    for (i = 0; i < 4; ++i) {
        item->x[i] = quad->x[i];
        item->y[i] = quad->y[i];
        item->u[i] = quad->u[i];
        item->v[i] = quad->v[i];
    }
    item->mode = (unsigned short)mode;
    item->clut = (unsigned short)clut;
}

/* A corner's colour copied from another item's. */
static inline void vs_effect_rgb_of(pc_item* item, int corner, const pc_item* from, int fromCorner)
{
    item->rgb[corner][0] = from->rgb[fromCorner][0];
    item->rgb[corner][1] = from->rgb[fromCorner][1];
    item->rgb[corner][2] = from->rgb[fromCorner][2];
}

/* A corner of a template item takes another's position and texel (a ribbon moves on by one segment). */
static inline void vs_effect_advance(pc_item* quad, int to, int from)
{
    quad->x[to] = quad->x[from];
    quad->y[to] = quad->y[from];
    quad->u[to] = quad->u[from];
    quad->v[to] = quad->v[from];
}

/* A line's end moves one pixel toward its start along the longer axis (the step the packet code gave every
 * segment: a line is drawn to its last pixel). */
static inline void vs_effect_shorten_line(pc_item* line)
{
    int sx = -1, sy = -1, dx = line->x[1] - line->x[0], dy = line->y[1] - line->y[0];
    if (dx == 0 && dy == 0)
        return;
    if (dx < 0)
        dx = -dx, sx = 1;
    if (dy < 0)
        dy = -dy, sy = 1;
    if (dy < dx) {
        line->x[1] += sx;
        if (dx < dy * 2)
            line->y[1] += sy;
    } else {
        line->y[1] += sy;
        if (dy < dx * 2)
            line->x[1] += sx;
    }
}
#endif
