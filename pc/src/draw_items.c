/* Typed draw items (draw_items.h). The frame's list is saved state: a save state
 * taken after a frame is built and before it is drawn (the game waits for the
 * vsync between them) keeps it. */
#include <stdint.h>
#include "draw_items.h"
#include "frame_cost.h"
#include "snapshot.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Items one frame can hold. The credits' busiest frame has about 600. */
#define ITEMS 1024
#define MARKER 0x00495449u /* "ITI": a GP0 no-op word, as render.c's markers are */

static struct {
    int count, full;
    pc_item item[ITEMS];
} frame PC_SAVED_STATE = { 0 };

/* boot_runtime.c: one lowered packet drawn as a member of an ordering table. */
extern void pc_draw_item_packet(void* packet);
extern void pc_hw_begin_ot(void) __attribute__((weak));
extern void pc_hw_end_ot(void) __attribute__((weak));
extern void pc_gte_new_generation(void);

void pc_frame_begin(void)
{
    frame.count = 0;
    frame.full = 0;
}

pc_item* pc_frame_add(int kind, int depth)
{
    if (frame.count == ITEMS) {
        if (!frame.full++)
            fprintf(stderr, "[items] a frame holds %d items: the rest are left out\n", ITEMS);
        return NULL;
    }
    pc_item* it = &frame.item[frame.count++];
    memset(it, 0, sizeof *it);
    it->kind = (uint8_t)kind;
    it->depth = depth;
    return it;
}

void pc_frame_tile(int depth, int x, int y, int w, int h, int rgb, int mode, int flags)
{
    pc_item* it = pc_frame_add(PC_ITEM_TILE, depth);
    if (!it)
        return;
    it->flags = (uint8_t)flags;
    it->mode = (uint16_t)mode;
    it->x[0] = (int16_t)x, it->y[0] = (int16_t)y, it->w = (int16_t)w, it->h = (int16_t)h;
    it->rgb[0][0] = (uint8_t)rgb, it->rgb[0][1] = (uint8_t)(rgb >> 8), it->rgb[0][2] = (uint8_t)(rgb >> 16);
}

void pc_frame_sprite(int depth, int x, int y, int w, int h, int u, int v, int rgb, int clut, int mode, int flags)
{
    pc_item* it = pc_frame_add(PC_ITEM_SPRITE, depth);
    if (!it)
        return;
    it->flags = (uint8_t)flags;
    it->mode = (uint16_t)mode;
    it->clut = (uint16_t)clut;
    it->x[0] = (int16_t)x, it->y[0] = (int16_t)y, it->w = (int16_t)w, it->h = (int16_t)h;
    it->u[0] = (uint8_t)u, it->v[0] = (uint8_t)v;
    it->rgb[0][0] = (uint8_t)rgb, it->rgb[0][1] = (uint8_t)(rgb >> 8), it->rgb[0][2] = (uint8_t)(rgb >> 16);
}

int pc_frame_count(void) { return frame.count; }

/* ---- the lowering: an item as the GP0 packet the game used to write ---- */

#define STRIDE 16 /* words per item in the packet arena: a mode packet (2) and the primitive (at most 13) */
static uint32_t* arena;

static uint32_t rgb_word(const pc_item* it, int i)
{
    return (uint32_t)it->rgb[i][0] | (uint32_t)it->rgb[i][1] << 8 | (uint32_t)it->rgb[i][2] << 16;
}
static uint32_t xy_word(const pc_item* it, int i)
{
    return (uint16_t)it->x[i] | (uint32_t)(uint16_t)it->y[i] << 16;
}

/* The words of `it` at `p` (after a tag word); returns how many. */
static unsigned lower(const pc_item* it, uint32_t* p)
{
    unsigned n = 0;
    uint32_t semi = it->flags & PC_ITEM_SEMI ? 2u : 0u, raw = it->flags & PC_ITEM_RAW ? 1u : 0u;
    switch (it->kind) {
    case PC_ITEM_TILE:
        p[n++] = rgb_word(it, 0) | (0x60u | semi) << 24;
        p[n++] = xy_word(it, 0);
        p[n++] = (uint16_t)it->w | (uint32_t)(uint16_t)it->h << 16;
        break;
    case PC_ITEM_SPRITE:
        p[n++] = rgb_word(it, 0) | (0x64u | semi | raw) << 24;
        p[n++] = xy_word(it, 0);
        p[n++] = it->u[0] | (uint32_t)it->v[0] << 8 | (uint32_t)it->clut << 16;
        p[n++] = (uint16_t)it->w | (uint32_t)(uint16_t)it->h << 16;
        break;
    case PC_ITEM_POLY: {
        int quad = it->verts == 4, textured = (it->flags & PC_ITEM_TEXTURED) != 0, shaded = (it->flags & PC_ITEM_SHADED) != 0;
        uint32_t code = 0x20u | raw | semi | (textured ? 4u : 0u) | (quad ? 8u : 0u) | (shaded ? 0x10u : 0u);
        for (int i = 0; i < (quad ? 4 : 3); i++) {
            if (i == 0)
                p[n++] = rgb_word(it, 0) | code << 24;
            else if (shaded)
                p[n++] = rgb_word(it, i);
            p[n++] = xy_word(it, i);
            if (textured)
                p[n++] = it->u[i] | (uint32_t)it->v[i] << 8 | (i == 0 ? (uint32_t)it->clut << 16 : i == 1 ? (uint32_t)it->mode << 16 : 0u);
        }
        break;
    }
    }
    return n;
}

/* Items [first, first + count) in draw order: larger depth first, then the later submission first. */
static int ordered(int first, int count, uint64_t* keys)
{
    int n = 0;
    for (int i = first; i < first + count && i < frame.count; i++)
        if (frame.item[i].kind != PC_ITEM_NONE)
            keys[n++] = (uint64_t)((int64_t)INT32_MAX - frame.item[i].depth) << 32 | (uint32_t)(0xffffffffu - (uint32_t)i);
    for (int a = 1; a < n; a++) { /* (insertion sort: the list is nearly in order, a few depths) */
        uint64_t k = keys[a];
        int b = a;
        for (; b > 0 && keys[b - 1] > k; b--)
            keys[b] = keys[b - 1];
        keys[b] = k;
    }
    return n;
}

/* Draws a run. `mode` is the draw mode the GPU is in; a packet sets it only when an item needs another
 * (a textured polygon sets its page itself, as it did). */
static void draw_run(int first, int count)
{
    uint64_t keys[ITEMS];
    int n = ordered(first, count, keys), mode = -1;
    if (!arena && !(arena = malloc((size_t)ITEMS * STRIDE * sizeof *arena)))
        return;
    for (int k = 0; k < n; k++) {
        int index = (int)(0xffffffffu - (uint32_t)keys[k]);
        const pc_item* it = &frame.item[index];
        uint32_t* at = arena + (size_t)index * STRIDE;
        int textured_poly = it->kind == PC_ITEM_POLY && (it->flags & PC_ITEM_TEXTURED);
        if (!textured_poly && it->mode != mode) {
            at[0] = 0x01ffffffu; /* one word: GP0 E1, as SetDrawTPage wrote */
            at[1] = 0xe1000000u | it->mode;
            mode = it->mode;
            pc_draw_item_packet(at);
        } else if (textured_poly && mode >= 0)
            mode = (mode & ~0x1ff) | (it->mode & 0x1ff);
        unsigned words = lower(it, at + 3);
        at[2] = (words << 24) | 0xffffffu;
        pc_draw_item_packet(at + 2);
    }
}

void pc_frame_draw(void)
{
    uint64_t cost = pc_cost_begin();
    if (pc_hw_begin_ot)
        pc_hw_begin_ot();
    draw_run(0, frame.count);
    if (pc_hw_end_ot)
        pc_hw_end_ot();
    pc_gte_new_generation();
    pc_cost_end(PC_COST_DRAW, cost);
}

/* ---- placing a run in an ordering table ---- */

uint32_t* pc_frame_place(int first, int count, uint32_t* ot_entry, uint32_t* packet)
{
    packet[0] = (*ot_entry & 0xffffff) | 3u << 24;
    packet[1] = MARKER;
    packet[2] = (uint32_t)first & 0xffffff;
    packet[3] = (uint32_t)count & 0xffffff;
    *ot_entry = (*ot_entry & 0xff000000) | ((uint32_t)(uintptr_t)packet & 0xffffff);
    return packet + 4;
}

/* boot_runtime.c's walk: whether `packet` is a marker, and the run it names. */
int pc_frame_marker(const uint32_t* packet, int* first, int* count)
{
    if ((packet[0] >> 24) != 3 || packet[1] != MARKER)
        return 0;
    *first = (int)packet[2];
    *count = (int)packet[3];
    return 1;
}
void pc_frame_draw_run(int first, int count) { draw_run(first, count); }
