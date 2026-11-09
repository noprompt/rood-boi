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

/* Items one frame can hold. The credits' busiest frame has about 600; a battle frame's effects have more. */
#define ITEMS 2048
#define MARKER 0x00495449u /* "ITI": a GP0 no-op word, as render.c's markers are */

static struct {
    int count, full;
    pc_item item[ITEMS];
} pc_item_frame PC_SAVED_STATE = { 0 };

/* Developer coverage: the call sites that placed an item, by return address (dev_rpc.c effect_sites). */
#define SITES 4096
static int sites_on, sites_count, peak;
static const void* sites[SITES];

/* boot_runtime.c: one lowered packet drawn as a member of an ordering table. */
extern void pc_draw_item_packet(void* packet);
extern void pc_hw_begin_ot(void) __attribute__((weak));
extern void pc_hw_end_ot(void) __attribute__((weak));
extern void pc_gte_new_generation(void);

void pc_frame_begin(void)
{
    if (pc_item_frame.count > peak)
        peak = pc_item_frame.count;
    pc_item_frame.count = 0;
    pc_item_frame.full = 0;
}

static pc_item spare; /* where a full frame's item goes: never drawn */

pc_item* pc_frame_add(int kind, int depth)
{
    if (pc_item_frame.count == ITEMS) {
        if (!pc_item_frame.full++)
            fprintf(stderr, "[items] a frame holds %d items: the rest are left out\n", ITEMS);
        return NULL;
    }
    pc_item* it = &pc_item_frame.item[pc_item_frame.count++];
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

int pc_frame_count(void) { return pc_item_frame.count; }

/* The classic layer's site range (draw_items.h). */
static int site_first, site_end;
void pc_frame_site(int first, int end) { site_first = first, site_end = end; }
void pc_frame_site_range(int* first, int* end) { *first = site_first, *end = site_end; }

int pc_frame_suppress(int first, int end)
{
    int n = 0;
    for (int i = first < 0 ? 0 : first; i < end && i < pc_item_frame.count; i++)
        if (pc_item_frame.item[i].kind != PC_ITEM_NONE)
            pc_item_frame.item[i].kind = PC_ITEM_NONE, n++;
    return n;
}

void pc_frame_rewind(int count)
{
    if (count >= 0 && count < pc_item_frame.count)
        pc_item_frame.count = count, pc_item_frame.full = 0;
}

int pc_frame_is_placed(int index)
{
    return index >= 0 && index < pc_item_frame.count && (pc_item_frame.item[index].flags & PC_ITEM_PLACED) != 0;
}

/* Raw GP0 words as items (draw_items.h): the inverse of `lower`, with the draw mode and texture window set along the way. */
static unsigned short group_serial;
int pc_frame_add_packets(int depth, const unsigned* w, int n, int* first)
{
    int start = pc_item_frame.count, i = 0, mode = -1, window = -1, prims = 0, state_after = 0, last_mode = -1, last_window = -1;
    *first = start;
    while (i < n) {
        unsigned c = w[i] >> 24;
        pc_item* it;
        if (c == 0xe1) {
            mode = (int)(w[i] & 0x3fff), state_after = 1, i++;
            continue;
        }
        if (c == 0xe2) {
            window = (int)(w[i] & 0xfffff), state_after = 1, i++;
            continue;
        }
        state_after = 0;
        if (c == 0xe3 && i + 1 < n && w[i + 1] >> 24 == 0xe4) {
            int x = (int)(w[i] & 0x3ff), y = (int)(w[i] >> 10 & 0x3ff), x1 = (int)(w[i + 1] & 0x3ff), y1 = (int)(w[i + 1] >> 10 & 0x3ff);
            if (!(it = pc_frame_add(PC_ITEM_AREA, depth)))
                goto fail;
            it->x[0] = (int16_t)x, it->y[0] = (int16_t)y, it->w = (int16_t)(x1 - x + 1), it->h = (int16_t)(y1 - y + 1);
            i += 2, prims++;
            last_mode = mode, last_window = window;
            continue;
        }
        if (c >= 0x20 && c < 0x40) {
            int quad = (c & 8) != 0, tex = (c & 4) != 0, shade = (c & 0x10) != 0, verts = quad ? 4 : 3, k = i;
            if (i + (shade ? verts : 1) + verts + (tex ? verts : 0) > n || (!tex && mode < 0) || (tex && mode >= 0 && (mode & 0x600))
                || !(it = pc_frame_add(PC_ITEM_POLY, depth)))
                goto fail;
            it->verts = (uint8_t)verts;
            it->flags = (uint8_t)((c & 2 ? PC_ITEM_SEMI : 0) | (c & 1 ? PC_ITEM_RAW : 0) | (tex ? PC_ITEM_TEXTURED : 0)
                | (shade ? PC_ITEM_SHADED : 0));
            for (int v = 0; v < verts; v++) {
                if (v == 0 || shade) {
                    it->rgb[v][0] = (uint8_t)w[k], it->rgb[v][1] = (uint8_t)(w[k] >> 8), it->rgb[v][2] = (uint8_t)(w[k] >> 16);
                    k++;
                }
                it->x[v] = (int16_t)w[k], it->y[v] = (int16_t)(w[k] >> 16);
                k++;
                if (tex) {
                    it->u[v] = (uint8_t)w[k], it->v[v] = (uint8_t)(w[k] >> 8);
                    if (v == 0)
                        it->clut = (uint16_t)(w[k] >> 16);
                    else if (v == 1)
                        it->mode = (uint16_t)(w[k] >> 16);
                    k++;
                }
            }
            if (!tex)
                it->mode = (uint16_t)mode;
            i = k, prims++;
        } else if ((c & 0xfc) == 0x60 || (c & 0xfc) == 0x64) { /* a tile or a sprite, of a size it carries */
            int tex = (c & 4) != 0, need = tex ? 4 : 3;
            if (i + need > n || mode < 0 || !(it = pc_frame_add(tex ? PC_ITEM_SPRITE : PC_ITEM_TILE, depth)))
                goto fail;
            it->flags = (uint8_t)((c & 2 ? PC_ITEM_SEMI : 0) | (c & 1 ? PC_ITEM_RAW : 0));
            it->mode = (uint16_t)mode;
            it->rgb[0][0] = (uint8_t)w[i], it->rgb[0][1] = (uint8_t)(w[i] >> 8), it->rgb[0][2] = (uint8_t)(w[i] >> 16);
            it->x[0] = (int16_t)w[i + 1], it->y[0] = (int16_t)(w[i + 1] >> 16);
            if (tex)
                it->u[0] = (uint8_t)w[i + 2], it->v[0] = (uint8_t)(w[i + 2] >> 8), it->clut = (uint16_t)(w[i + 2] >> 16);
            it->w = (int16_t)w[i + need - 1], it->h = (int16_t)(w[i + need - 1] >> 16);
            i += need, prims++;
        } else if (c == 0x40 || c == 0x42) { /* a flat line */
            if (i + 3 > n || mode < 0 || !(it = pc_frame_add(PC_ITEM_LINE, depth)))
                goto fail;
            it->flags = (uint8_t)(c & 2 ? PC_ITEM_SEMI : 0);
            it->mode = (uint16_t)mode;
            it->rgb[0][0] = (uint8_t)w[i], it->rgb[0][1] = (uint8_t)(w[i] >> 8), it->rgb[0][2] = (uint8_t)(w[i] >> 16);
            it->x[0] = (int16_t)w[i + 1], it->y[0] = (int16_t)(w[i + 1] >> 16);
            it->x[1] = (int16_t)w[i + 2], it->y[1] = (int16_t)(w[i + 2] >> 16);
            i += 3, prims++;
        } else
            goto fail;
        if (window >= 0)
            it->flags |= PC_ITEM_WINDOW, it->tw = (unsigned)window;
        last_mode = mode, last_window = window;
    }
    /* (state set after the last primitive is only dropped when it is the state that primitive had) */
    if (!prims || (state_after && (mode != last_mode || window != last_window)))
        goto fail;
    if (!++group_serial)
        ++group_serial;
    for (int a = start; a < pc_item_frame.count; a++)
        pc_item_frame.item[a].group = group_serial;
    for (int a = start, b = pc_item_frame.count - 1; a < b; a++, b--) { /* (items of one depth draw last first) */
        pc_item t = pc_item_frame.item[a];
        pc_item_frame.item[a] = pc_item_frame.item[b];
        pc_item_frame.item[b] = t;
    }
    return pc_item_frame.count - start;
fail:
    pc_frame_rewind(start);
    return 0;
}

pc_item* pc_frame_poly_at(int depth, int kind, int verts, int flags, unsigned* ot, unsigned** cursor)
{
    int index = pc_item_frame.count;
    pc_item* it = pc_frame_add(kind, depth);
    if (!it) {
        memset(&spare, 0, sizeof spare);
        return &spare;
    }
    it->verts = (uint8_t)verts;
    it->flags = (uint8_t)flags;
    if (ot) /* (a frame of items alone has no table to place it in) */
        *cursor = pc_frame_place(index, 1, ot + depth, *cursor);
    if (sites_on) {
        const void* site = __builtin_return_address(0);
        int i;
        for (i = 0; i < sites_count && sites[i] != site; i++)
            ;
        if (i == sites_count && sites_count < SITES)
            sites[sites_count++] = site;
    }
    return it;
}

/* The sites seen since recording began (return addresses); `on` starts or stops recording, `reset` clears.
 * `peak` is the most items one frame has held. */
int pc_frame_sites(int on, int reset, const void*** list, int* peak_items)
{
    sites_on = on;
    if (reset)
        sites_count = 0, peak = 0;
    *list = sites;
    *peak_items = peak;
    return sites_count;
}

/* ---- the lowering: an item as the GP0 packet the game used to write ---- */

#define STRIDE 20 /* words per item in the packet arena: a mode packet (2) and the primitive (at most 15) */
static uint32_t* arena;
extern void pc_hw_anchor_packets(const void* start, const void* end, int anchor) __attribute__((weak));

const void* pc_frame_packet(int index)
{
    if (!arena && !(arena = malloc((size_t)ITEMS * STRIDE * sizeof *arena)))
        return NULL;
    return arena + (size_t)index * STRIDE;
}

pc_item* pc_frame_item(int index)
{
    return index >= 0 && index < pc_item_frame.count ? &pc_item_frame.item[index] : NULL;
}
/* (the primitive's tag is word 2 of an item's 20, its command word 3) */
const void* pc_frame_command(int index)
{
    const uint32_t* at = pc_frame_packet(index);
    return at ? at + 3 : NULL;
}
int pc_frame_command_item(const void* command)
{
    const uint32_t* at = (const uint32_t*)command - 3;
    if (!arena || !command || at < arena || at >= arena + (size_t)pc_item_frame.count * STRIDE || (size_t)(at - arena) % STRIDE)
        return -1;
    return (int)((size_t)(at - arena) / STRIDE);
}

void pc_frame_anchor(int first, int end, int anchor)
{
    if (pc_hw_anchor_packets && end > first && pc_frame_packet(first))
        pc_hw_anchor_packets(pc_frame_packet(first), (const char*)pc_frame_packet(end - 1) + STRIDE * sizeof *arena, anchor);
}

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
    if (it->flags & PC_ITEM_BRACKET) /* (dither off: a textured polygon's page is in its own words) */
        p[n++] = 0xe1000000u | (it->kind == PC_ITEM_LINE ? it->mode & 0x1ffu : 0u);
    switch (it->kind) {
    case PC_ITEM_AREA:
        p[n++] = 0xe3000000u | ((uint32_t)it->y[0] & 0x3ffu) << 10 | ((uint32_t)it->x[0] & 0x3ffu);
        p[n++] = 0xe4000000u | ((uint32_t)(it->y[0] + it->h - 1) & 0x3ffu) << 10 | ((uint32_t)(it->x[0] + it->w - 1) & 0x3ffu);
        break;
    case PC_ITEM_LINE:
        p[n++] = rgb_word(it, 0) | (0x40u | semi) << 24;
        p[n++] = xy_word(it, 0);
        p[n++] = xy_word(it, 1);
        break;
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
    if (it->flags & PC_ITEM_BRACKET)
        p[n++] = 0xe1000200u;
    return n;
}

/* Items [first, first + count) in draw order: larger depth first, then the later submission first. */
static int ordered(int first, int count, uint64_t* keys)
{
    int n = 0;
    for (int i = first; i < first + count && i < pc_item_frame.count; i++)
        if (pc_item_frame.item[i].kind != PC_ITEM_NONE)
            keys[n++] = (uint64_t)((int64_t)INT32_MAX - pc_item_frame.item[i].depth) << 32 | (uint32_t)(0xffffffffu - (uint32_t)i);
    for (int a = 1; a < n; a++) { /* (insertion sort: the list is nearly in order, a few depths) */
        uint64_t k = keys[a];
        int b = a;
        for (; b > 0 && keys[b - 1] > k; b--)
            keys[b] = keys[b - 1];
        keys[b] = k;
    }
    return n;
}

int pc_frame_order(int first, int count, int unplaced, int* out, int max)
{
    uint64_t keys[ITEMS];
    int n = ordered(first, count, keys), m = 0;
    for (int k = 0; k < n && m < max; k++) {
        int index = (int)(0xffffffffu - (uint32_t)keys[k]);
        if (!unplaced || !(pc_item_frame.item[index].flags & PC_ITEM_PLACED))
            out[m++] = index;
    }
    return m;
}

int pc_frame_lower(int index, unsigned words[3][16], int lengths[3])
{
    const pc_item* it;
    uint32_t tmp[16];
    unsigned n, packets = 0;
    if (index < 0 || index >= pc_item_frame.count || pc_item_frame.item[index].kind == PC_ITEM_NONE)
        return 0;
    it = &pc_item_frame.item[index];
    n = lower(it, tmp);
    if (it->flags & PC_ITEM_WINDOW) {
        words[packets][0] = 0xe2000000u | (it->tw & 0xfffffu);
        lengths[packets++] = 1;
    }
    if (it->kind != PC_ITEM_AREA && !(it->flags & PC_ITEM_BRACKET) && !(it->kind == PC_ITEM_POLY && (it->flags & PC_ITEM_TEXTURED))) {
        words[0][0] = 0xe1000000u | it->mode;
        lengths[packets++] = 1;
    }
    memcpy(words[packets], tmp, n * sizeof tmp[0]);
    lengths[packets++] = (int)n;
    return (int)packets;
}

/* Draws a run. `mode` is the draw mode the GPU is in; a packet sets it only when an item needs another
 * (a textured polygon sets its page itself, as it did). */
static void draw_run(int first, int count)
{
    uint64_t keys[ITEMS];
    int n = ordered(first, count, keys), mode = -1;
    unsigned window = ~0u; /* (the texture window the GPU is in, when an item set it) */
    if (!arena && !(arena = malloc((size_t)ITEMS * STRIDE * sizeof *arena)))
        return;
    for (int k = 0; k < n; k++) {
        int index = (int)(0xffffffffu - (uint32_t)keys[k]);
        const pc_item* it = &pc_item_frame.item[index];
        uint32_t* at = arena + (size_t)index * STRIDE;
        int textured_poly = it->kind == PC_ITEM_POLY && (it->flags & PC_ITEM_TEXTURED);
        if ((it->flags & PC_ITEM_WINDOW) && it->tw != window) {
            at[18] = 0x01ffffffu; /* one word: GP0 E2, the texture window */
            at[19] = 0xe2000000u | (it->tw & 0xfffffu);
            window = (int)it->tw;
            pc_draw_item_packet(at + 18);
        }
        if (it->kind == PC_ITEM_AREA) {
            /* (a drawing area: no draw mode) */
        } else if (it->flags & PC_ITEM_BRACKET)
            mode = 0x200; /* (its words end with the mode set) */
        else if (!textured_poly && it->mode != mode) {
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
    draw_run(0, pc_item_frame.count);
    if (pc_hw_end_ot)
        pc_hw_end_ot();
    pc_gte_new_generation();
    pc_cost_end(PC_COST_DRAW, cost);
}

/* ---- placing a run in an ordering table ---- */

uint32_t* pc_frame_place(int first, int count, uint32_t* ot_entry, uint32_t* packet)
{
    for (int i = first; i < first + count && i < pc_item_frame.count; i++)
        pc_item_frame.item[i].flags |= PC_ITEM_PLACED;
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
