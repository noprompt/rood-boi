/* The draw walk's commands to the hardware renderer (hw_cmd.h). Host state: nothing here is game state. */
#include "hw_cmd.h"
#include "ui_text.h"
#include "render.h"
#include "dev_state.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* The renderer's hooks, applied by the consumer (gpu_hw.c). */
extern void pc_hw_set_2d(int);
extern void pc_hw_set_narrowed(void) __attribute__((weak));
extern void pc_hw_set_precise(const float*);
extern void pc_hw_set_depth(const int*);
extern void pc_hw_set_packet(const void*);
extern void pc_hw_set_flipped_uv(const int*, const int*);
extern void pc_hw_set_bounds(int, int, int, int, unsigned, unsigned, const int*, const int*);
extern void pc_hw_set_attr(const pc_hw_attr*, int, int);
extern void pc_hw_native_marker(unsigned, int, int, const int*, unsigned, int) __attribute__((weak));
extern void pc_hw_native_translucent(unsigned, int, int, int, int, const int*, unsigned, int) __attribute__((weak));
extern void pc_hw_ot_native_area(const int*) __attribute__((weak));
extern void pc_hw_rect(int, int, int, int, int, int, unsigned, unsigned, unsigned, unsigned, unsigned, const int*, int, int);
extern void pc_hw_line(int, int, int, int, unsigned, unsigned, int, unsigned, const int*, int);
extern void pc_hw_mark_raster(int, int, int, int);
extern void pc_hw_mark(int, int, int, int);
extern void pc_hw_before_write(int, int, int, int) __attribute__((weak));
extern void pc_hw_stale_copy(int, int, int, int, int, int) __attribute__((weak));
extern void pc_hw_sync_store(int, int, int, int) __attribute__((weak));
extern void pc_hw_sync_texture(unsigned, unsigned, unsigned, int, int, int, int, const int*) __attribute__((weak));
extern int pc_hw_text_quad_decide(int, const float*, const int*, unsigned, unsigned, unsigned, const int*, pc_ui_text_piece_info*);
extern void pc_hw_text_piece_apply(const pc_ui_text_piece_info*, unsigned, unsigned, unsigned, int, int, const void*);
extern void pc_hw_text_piece_end(void);
extern void pc_emissive_note_instance(uint32_t, const void*, int, int, unsigned, unsigned);
extern void pc_emissive_mesh_gone(uint32_t);
extern void pc_emissive_room_mesh(uint32_t, unsigned, unsigned, unsigned);
extern void pc_emissive_frame_room(int valid, int zone, int room);
extern int pc_hw_active;
extern const uint16_t* pc_native_vram(void);
extern int pc_gpu_immediate; /* DrawPrim, not an ordering table: ui_text identifies the info signs by it */
extern const void* pc_gpu_command; /* the packet a rectangle or text quad draws (boot_runtime.c) */

enum { C_SET_2D = 1, C_SET_NARROWED, C_SET_PRECISE, C_SET_DEPTH, C_SET_PACKET, C_SET_FLIPPED_UV, C_SET_BOUNDS, C_SET_ATTR, C_NATIVE_MARKER, C_NATIVE_TRANSLUCENT, C_OT_NATIVE_AREA, C_RECT, C_LINE, C_TRIANGLE, C_MARK_RASTER, C_MARK, C_RASTER_POST, C_BEFORE_WRITE, C_STALE_COPY, C_TEXT_PIECE, C_TEXT_PIECE_DONE, C_EMISSIVE_NOTE, C_EMISSIVE_GONE, C_EMISSIVE_ROOM_MESH, C_FRAME_ROOM };

struct pc_hwc_mirror_t pc_hwc_mirror = { .cur_effect = -1, .poly_effect = -1 };
int pc_hwc_pending;
int pc_hwc_stale_pending;
/* ROOD_HWC_INLINE=1: every record is applied at once, as the walk called the hooks before the buffer (the proof's reference:
 * the same binary, identical frames expected with and without). */
static int inline_mode = -1;
static int inline_now(void)
{
    if (inline_mode < 0)
        inline_mode = getenv("ROOD_HWC_INLINE") != NULL;
    return inline_mode;
}
static unsigned char buffer[1 << 18]; /* a walk's records: about 40 bytes each, a few thousand a frame at most */
#define ROOM_FOR(n) ((int)sizeof buffer - pc_hwc_pending >= (n) + 1)

static unsigned char* record(int type, int size)
{
    if (!ROOM_FOR(size))
        pc_hwc_flush();
    unsigned char* at = buffer + pc_hwc_pending;
    at[0] = (unsigned char)type;
    pc_hwc_pending += 1 + size;
    return at + 1;
}

void pc_hwc_set_2d(int is_2d)
{
    pc_hwc_mirror.is_2d = is_2d;
    memcpy(record(C_SET_2D, sizeof is_2d), &is_2d, sizeof is_2d);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_set_narrowed(void)
{
    record(C_SET_NARROWED, 0);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_set_precise(const float* xy6)
{
    memcpy(record(C_SET_PRECISE, 6 * sizeof(float)), xy6, 6 * sizeof(float));
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_set_depth(const int* depth3)
{
    memcpy(record(C_SET_DEPTH, 3 * sizeof(int)), depth3, 3 * sizeof(int));
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_set_packet(const void* packet)
{
    pc_hwc_mirror.poly_effect = pc_hwc_mirror.cur_effect;
    memcpy(record(C_SET_PACKET, sizeof packet), &packet, sizeof packet);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_set_flipped_uv(const int* xy6, const int* uv6)
{
    unsigned char* at = record(C_SET_FLIPPED_UV, 12 * sizeof(int));
    memcpy(at, xy6, 6 * sizeof(int));
    memcpy(at + 6 * sizeof(int), uv6, 6 * sizeof(int));
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_set_bounds(int x0, int y0, int x1, int y1, unsigned code, unsigned tpage, const int* uv4, const int* clip4)
{
    struct {
        int x0, y0, x1, y1;
        unsigned code, tpage;
        int has_uv, uv[4], clip[4];
    } b = { x0, y0, x1, y1, code, tpage, uv4 != NULL, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } };
    if (uv4)
        memcpy(b.uv, uv4, sizeof b.uv);
    memcpy(b.clip, clip4, sizeof b.clip);
    memcpy(record(C_SET_BOUNDS, sizeof b), &b, sizeof b);
    if (inline_now())
        pc_hwc_flush();
}

void pc_hwc_set_attr(const pc_hw_attr* attr, int screen_x, int screen_w)
{
    struct {
        pc_hw_attr attr;
        int x, w;
    } a = { *attr, screen_x, screen_w };
    pc_hwc_mirror.cur_effect = attr->effect;
    memcpy(record(C_SET_ATTR, sizeof a), &a, sizeof a);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_native_marker(unsigned list, int draw_x, int draw_y, const int* clip4, unsigned window, int mask_set)
{
    struct {
        unsigned list;
        int x, y, clip[4];
        unsigned window;
        int mask;
    } m = { list, draw_x, draw_y, { 0, 0, 0, 0 }, window, mask_set };
    memcpy(m.clip, clip4, sizeof m.clip);
    memcpy(record(C_NATIVE_MARKER, sizeof m), &m, sizeof m);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_native_translucent(unsigned list, int first, int count, int draw_x, int draw_y, const int* clip4, unsigned window,
    int mask_set)
{
    struct {
        unsigned list;
        int first, count, x, y, clip[4];
        unsigned window;
        int mask;
    } m = { list, first, count, draw_x, draw_y, { 0, 0, 0, 0 }, window, mask_set };
    memcpy(m.clip, clip4, sizeof m.clip);
    memcpy(record(C_NATIVE_TRANSLUCENT, sizeof m), &m, sizeof m);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_ot_native_area(const int* clip4)
{
    memcpy(record(C_OT_NATIVE_AREA, 4 * sizeof(int)), clip4, 4 * sizeof(int));
    if (inline_now())
        pc_hwc_flush();
}

typedef struct {
    int x, y, w, h, u, v;
    unsigned color, code, tpage, clut, window;
    int clip[4], mask_set, mask_check;
    const void* command;
    int immediate;
} rect_record;
void pc_hwc_rect(int x, int y, int w, int h, int u, int v, unsigned color, unsigned code, unsigned tpage, unsigned clut,
    unsigned window, const int* clip4, int mask_set, int mask_check)
{
    rect_record r = { x, y, w, h, u, v, color, code, tpage, clut, window, { 0, 0, 0, 0 }, mask_set, mask_check, pc_gpu_command, pc_gpu_immediate };
    memcpy(r.clip, clip4, sizeof r.clip);
    memcpy(record(C_RECT, sizeof r), &r, sizeof r);
    if (inline_now())
        pc_hwc_flush();
}
typedef struct {
    int x0, y0, x1, y1;
    unsigned ca, cb;
    int semi;
    unsigned tpage;
    int clip[4], mask_set;
} line_record;
void pc_hwc_line(int x0, int y0, int x1, int y1, unsigned ca, unsigned cb, int semi, unsigned tpage, const int* clip4,
    int mask_set)
{
    line_record r = { x0, y0, x1, y1, ca, cb, semi, tpage, { 0, 0, 0, 0 }, mask_set };
    memcpy(r.clip, clip4, sizeof r.clip);
    memcpy(record(C_LINE, sizeof r), &r, sizeof r);
    if (inline_now())
        pc_hwc_flush();
}

typedef struct {
    int xy[6], uv[6], rgb[9];
    unsigned code, tpage, clut, window;
    int clip[4], mask_set, mask_check;
    pc_hw_tri_decision decision;
} triangle_record;
int pc_hwc_triangle(const int* xy, const int* uv, const int* rgb, unsigned code, unsigned tpage, unsigned clut, unsigned window,
    const int* clip, int mask_set, int mask_check)
{
    triangle_record t;
    pc_hw_triangle_decide(uv, code, tpage, clip, pc_hwc_mirror.is_2d, pc_hwc_mirror.poly_effect, &t.decision);
    if (t.decision.action != PC_HW_TRI_IGNORE) {
        memcpy(t.xy, xy, sizeof t.xy), memcpy(t.uv, uv, sizeof t.uv), memcpy(t.rgb, rgb, sizeof t.rgb);
        t.code = code, t.tpage = tpage, t.clut = clut, t.window = window;
        memcpy(t.clip, clip, sizeof t.clip);
        t.mask_set = mask_set, t.mask_check = mask_check;
        memcpy(record(C_TRIANGLE, sizeof t), &t, sizeof t);
        if (inline_now())
            pc_hwc_flush();
    }
    return t.decision.skip;
}

/* The pending rasterized rectangles (the producer's list; the renderer's is kept in step by the mark records) and the pixel
 * payload of the posts: a pool the flush empties, and a block of its own for a post too big for it. */
static int pend[64][4], pend_count;
#define POOL_PIXELS (1 << 21)
static uint16_t pool[POOL_PIXELS];
static size_t pool_used;
void pc_hwc_mark_raster(int x0, int y0, int x1, int y1)
{
    if (pc_hw_active) {
        if (pend_count == 64)
            pc_hwc_raster_post();
        int* r = pend[pend_count++];
        r[0] = x0, r[1] = y0, r[2] = x1, r[3] = y1;
    }
    int rect[4] = { x0, y0, x1, y1 };
    memcpy(record(C_MARK_RASTER, sizeof rect), rect, sizeof rect);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_mark(int x0, int y0, int x1, int y1)
{
    int rect[4] = { x0, y0, x1, y1 };
    memcpy(record(C_MARK, sizeof rect), rect, sizeof rect);
    if (inline_now())
        pc_hwc_flush();
}
typedef struct {
    int count;
    size_t offset;    /* into the pool, or ... */
    uint16_t* block;  /* ... a block of its own (freed when applied) */
    int rects[64][4]; /* clipped to the VRAM */
} post_record;
void pc_hwc_raster_post(void)
{
    if (!pend_count)
        return;
    const uint16_t* vram = pc_native_vram();
    post_record q;
    size_t total = 0;
    q.count = 0;
    for (int i = 0; i < pend_count; i++) {
        const int* r = pend[i];
        int x0 = r[0] < 0 ? 0 : r[0], y0 = r[1] < 0 ? 0 : r[1], x1 = r[2] > 1023 ? 1023 : r[2], y1 = r[3] > 511 ? 511 : r[3];
        if (x1 < x0 || y1 < y0)
            continue;
        q.rects[q.count][0] = x0, q.rects[q.count][1] = y0, q.rects[q.count][2] = x1, q.rects[q.count][3] = y1;
        ++q.count;
        total += (size_t)(x1 - x0 + 1) * (size_t)(y1 - y0 + 1);
    }
    pend_count = 0;
    if (!q.count)
        return;
    uint16_t* at;
    q.block = NULL, q.offset = 0;
    if (total > POOL_PIXELS - pool_used)
        pc_hwc_flush(); /* the pool is empty after a flush */
    unsigned char* slot = record(C_RASTER_POST, sizeof q); /* (may flush: before the pool is used) */
    if (total <= POOL_PIXELS - pool_used) {
        q.offset = pool_used;
        at = pool + pool_used;
        pool_used += total;
    } else
        at = q.block = malloc(total * sizeof *at);
    for (int i = 0; i < q.count; i++) {
        int x0 = q.rects[i][0], y0 = q.rects[i][1], x1 = q.rects[i][2], y1 = q.rects[i][3], w = x1 - x0 + 1;
        for (int y = y0; y <= y1; y++, at += w)
            memcpy(at, vram + (size_t)y * 1024 + x0, (size_t)w * sizeof *at);
    }
    memcpy(slot, &q, sizeof q);
    if (inline_now())
        pc_hwc_flush();
}

typedef struct {
    pc_ui_text_piece_info info;
    unsigned rgb, code, window;
    int mask_set, mask_check;
    const void* command;
    int immediate;
} text_piece_record;
static int text_emitting; /* the producer's knowledge: a piece's triangles are being drawn */
int pc_hwc_text_quad(const float* xy, const int* uv, const int* rgb, unsigned code, unsigned tpage, unsigned clut, unsigned window,
    const int* clip, int mask_set, int mask_check)
{
    text_piece_record q;
    if (!pc_hw_text_quad_decide(text_emitting, xy, uv, code, tpage, clut, clip, &q.info))
        return 0;
    q.rgb = (unsigned)(rgb[0] | rgb[1] << 8 | rgb[2] << 16), q.code = code, q.window = window;
    q.mask_set = mask_set, q.mask_check = mask_check, q.command = pc_gpu_command, q.immediate = pc_gpu_immediate;
    memcpy(record(C_TEXT_PIECE, sizeof q), &q, sizeof q);
    text_emitting = 1;
    if (inline_now())
        pc_hwc_flush();
    return 1;
}
void pc_hwc_text_piece_done(void)
{
    text_emitting = 0;
    record(C_TEXT_PIECE_DONE, 0);
    if (inline_now())
        pc_hwc_flush();
}

void pc_hwc_before_write(int x, int y, int w, int h)
{
    int v[4] = { x, y, w, h };
    memcpy(record(C_BEFORE_WRITE, sizeof v), v, sizeof v);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_stale_copy(int sx, int sy, int dx, int dy, int w, int h)
{
    int v[6] = { sx, sy, dx, dy, w, h };
    memcpy(record(C_STALE_COPY, sizeof v), v, sizeof v);
    pc_hwc_stale_pending = 1;
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_fence_store(int x, int y, int w, int h)
{
    pc_hwc_flush();
    if (pc_hw_sync_store)
        pc_hw_sync_store(x, y, w, h);
}
void pc_hwc_fence_texture(unsigned tpage, unsigned clut, unsigned window, int u0, int v0, int u1, int v1, const int* clip4)
{
    pc_hwc_flush();
    if (pc_hw_sync_texture)
        pc_hw_sync_texture(tpage, clut, window, u0, v0, u1, v1, clip4);
}
/* ---- the emissive matcher's inputs (hw_cmd.h) ---- */
/* The instance keys already noted, as emissive.cpp keys them (a mesh and, with a texture override, its page and CLUT): the
 * producer sends a note once, as the matcher counts it once. An open-addressing table, rebuilt when a mesh goes. */
static uint64_t* noted;
static size_t noted_cap, noted_count;
static int noted_find(uint64_t ik, size_t* at)
{
    size_t i = (size_t)(ik * 0x9e3779b97f4a7c15ull >> 40) & (noted_cap - 1);
    while (noted[i]) {
        if (noted[i] == ik + 1)
            return *at = i, 1;
        i = (i + 1) & (noted_cap - 1);
    }
    return *at = i, 0;
}
static void noted_add(uint64_t ik)
{
    if ((noted_count + 1) * 2 > noted_cap) {
        uint64_t* old = noted;
        size_t old_cap = noted_cap;
        noted_cap = noted_cap ? noted_cap * 2 : 4096;
        noted = calloc(noted_cap, sizeof *noted);
        noted_count = 0;
        for (size_t i = 0; i < old_cap; i++)
            if (old[i])
                noted_add(old[i] - 1);
        free(old);
    }
    size_t at;
    if (!noted_find(ik, &at))
        noted[at] = ik + 1, ++noted_count;
}
typedef struct {
    uint32_t mesh;
    int count, override;
    unsigned tpage, clut;
    void* polygons; /* a copy, freed when applied */
} emissive_note_record;
void pc_hwc_emissive_note(uint32_t mesh, const void* polygons, int count, int override, unsigned tpage, unsigned clut)
{
    if (!mesh || !polygons || count <= 0)
        return;
    int texture = (override & RENDER_OVERRIDE_TEXTURE) != 0;
    uint64_t ik = (uint64_t)mesh << 32 | (texture ? ((uint64_t)(tpage & 0xffff) << 16 | (clut & 0xffff)) : 0xffffffffu);
    size_t at;
    if (noted_cap && noted_find(ik, &at))
        return;
    noted_add(ik);
    emissive_note_record q = { mesh, count, override, tpage, clut, malloc((size_t)count * sizeof(render_polygon)) };
    if (!q.polygons)
        return;
    memcpy(q.polygons, polygons, (size_t)count * sizeof(render_polygon));
    memcpy(record(C_EMISSIVE_NOTE, sizeof q), &q, sizeof q);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_emissive_mesh_gone(uint32_t mesh)
{
    if (noted_count) { /* forget the mesh's keys: rebuild without them */
        uint64_t* old = noted;
        size_t old_cap = noted_cap;
        noted = calloc(noted_cap, sizeof *noted);
        noted_count = 0;
        for (size_t i = 0; i < old_cap; i++)
            if (old[i] && (uint32_t)((old[i] - 1) >> 32) != mesh)
                noted_add(old[i] - 1);
        free(old);
    }
    memcpy(record(C_EMISSIVE_GONE, sizeof mesh), &mesh, sizeof mesh);
    if (inline_now())
        pc_hwc_flush();
}
void pc_hwc_emissive_room_mesh(uint32_t mesh, unsigned offset, unsigned tris, unsigned quads)
{
    unsigned v[4] = { mesh, offset, tris, quads };
    memcpy(record(C_EMISSIVE_ROOM_MESH, sizeof v), v, sizeof v);
    if (inline_now())
        pc_hwc_flush();
}
/* The room the frame is drawn in: sent when it changes, and with every ordering table's start. */
void pc_hwc_frame_room(void)
{
    static int last[3] = { -2, 0, 0 };
    struct pc_dev_state s;
    memset(&s, 0, sizeof s);
    if (pc_dev_state)
        pc_dev_state(&s);
    int v[3] = { s.valid != 0, s.valid ? s.zone : -1, s.valid ? s.room : -1 };
    if (!memcmp(v, last, sizeof v))
        return;
    memcpy(last, v, sizeof v);
    memcpy(record(C_FRAME_ROOM, sizeof v), v, sizeof v);
    if (inline_now())
        pc_hwc_flush();
}

/* Apply the records in order. The pending count is cleared first: the hooks called here begin with PC_HWC_SYNC and must find
 * nothing to apply. */
void pc_hwc_flush(void)
{
    int end = pc_hwc_pending, at = 0;
    pc_hwc_pending = 0;
    pc_hwc_stale_pending = 0;
    while (at < end) {
        const unsigned char* r = buffer + at;
        int type = r[0];
        ++r;
        switch (type) {
        case C_SET_2D: {
            int v;
            memcpy(&v, r, sizeof v);
            pc_hw_set_2d(v);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_SET_NARROWED:
            if (pc_hw_set_narrowed)
                pc_hw_set_narrowed();
            at += 1;
            break;
        case C_SET_PRECISE: {
            float v[6];
            memcpy(v, r, sizeof v);
            pc_hw_set_precise(v);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_SET_DEPTH: {
            int v[3];
            memcpy(v, r, sizeof v);
            pc_hw_set_depth(v);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_SET_PACKET: {
            const void* v;
            memcpy(&v, r, sizeof v);
            pc_hw_set_packet(v);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_SET_FLIPPED_UV: {
            int v[12];
            memcpy(v, r, sizeof v);
            pc_hw_set_flipped_uv(v, v + 6);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_SET_BOUNDS: {
            struct {
                int x0, y0, x1, y1;
                unsigned code, tpage;
                int has_uv, uv[4], clip[4];
            } b;
            memcpy(&b, r, sizeof b);
            pc_hw_set_bounds(b.x0, b.y0, b.x1, b.y1, b.code, b.tpage, b.has_uv ? b.uv : NULL, b.clip);
            at += 1 + (int)sizeof b;
            break;
        }
        case C_SET_ATTR: {
            struct {
                pc_hw_attr attr;
                int x, w;
            } a;
            memcpy(&a, r, sizeof a);
            pc_hw_set_attr(&a.attr, a.x, a.w);
            at += 1 + (int)sizeof a;
            break;
        }
        case C_NATIVE_MARKER: {
            struct {
                unsigned list;
                int x, y, clip[4];
                unsigned window;
                int mask;
            } m;
            memcpy(&m, r, sizeof m);
            if (pc_hw_native_marker)
                pc_hw_native_marker(m.list, m.x, m.y, m.clip, m.window, m.mask);
            at += 1 + (int)sizeof m;
            break;
        }
        case C_NATIVE_TRANSLUCENT: {
            struct {
                unsigned list;
                int first, count, x, y, clip[4];
                unsigned window;
                int mask;
            } m;
            memcpy(&m, r, sizeof m);
            if (pc_hw_native_translucent)
                pc_hw_native_translucent(m.list, m.first, m.count, m.x, m.y, m.clip, m.window, m.mask);
            at += 1 + (int)sizeof m;
            break;
        }
        case C_OT_NATIVE_AREA: {
            int clip[4];
            memcpy(clip, r, sizeof clip);
            if (pc_hw_ot_native_area)
                pc_hw_ot_native_area(clip);
            at += 1 + (int)sizeof clip;
            break;
        }
        case C_RECT: {
            rect_record q;
            memcpy(&q, r, sizeof q);
            const void* was = pc_gpu_command; /* the hook reads the packet it draws from here */
            pc_gpu_command = q.command;
            int was_immediate = pc_gpu_immediate;
            pc_gpu_immediate = q.immediate;
            pc_hw_rect(q.x, q.y, q.w, q.h, q.u, q.v, q.color, q.code, q.tpage, q.clut, q.window, q.clip, q.mask_set, q.mask_check);
            pc_gpu_immediate = was_immediate;
            pc_gpu_command = was;
            at += 1 + (int)sizeof q;
            break;
        }
        case C_LINE: {
            line_record q;
            memcpy(&q, r, sizeof q);
            pc_hw_line(q.x0, q.y0, q.x1, q.y1, q.ca, q.cb, q.semi, q.tpage, q.clip, q.mask_set);
            at += 1 + (int)sizeof q;
            break;
        }
        case C_TRIANGLE: {
            triangle_record t;
            memcpy(&t, r, sizeof t);
            pc_hw_triangle_apply(t.xy, t.uv, t.rgb, t.code, t.tpage, t.clut, t.window, t.clip, t.mask_set, t.mask_check,
                &t.decision);
            at += 1 + (int)sizeof t;
            break;
        }
        case C_TEXT_PIECE: {
            text_piece_record q;
            memcpy(&q, r, sizeof q);
            int was_immediate = pc_gpu_immediate;
            pc_gpu_immediate = q.immediate;
            pc_hw_text_piece_apply(&q.info, q.rgb, q.code, q.window, q.mask_set, q.mask_check, q.command);
            pc_gpu_immediate = was_immediate;
            at += 1 + (int)sizeof q;
            break;
        }
        case C_TEXT_PIECE_DONE:
            pc_hw_text_piece_end();
            at += 1;
            break;
        case C_EMISSIVE_NOTE: {
            emissive_note_record q;
            memcpy(&q, r, sizeof q);
            pc_emissive_note_instance(q.mesh, q.polygons, q.count, q.override, q.tpage, q.clut);
            free(q.polygons);
            at += 1 + (int)sizeof q;
            break;
        }
        case C_EMISSIVE_GONE: {
            uint32_t mesh;
            memcpy(&mesh, r, sizeof mesh);
            pc_emissive_mesh_gone(mesh);
            at += 1 + (int)sizeof mesh;
            break;
        }
        case C_EMISSIVE_ROOM_MESH: {
            unsigned v[4];
            memcpy(v, r, sizeof v);
            pc_emissive_room_mesh(v[0], v[1], v[2], v[3]);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_FRAME_ROOM: {
            int v[3];
            memcpy(v, r, sizeof v);
            pc_emissive_frame_room(v[0], v[1], v[2]);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_MARK_RASTER: {
            int rect[4];
            memcpy(rect, r, sizeof rect);
            pc_hw_mark_raster(rect[0], rect[1], rect[2], rect[3]);
            at += 1 + (int)sizeof rect;
            break;
        }
        case C_MARK: {
            int rect[4];
            memcpy(rect, r, sizeof rect);
            pc_hw_mark(rect[0], rect[1], rect[2], rect[3]);
            at += 1 + (int)sizeof rect;
            break;
        }
        case C_RASTER_POST: {
            post_record q;
            memcpy(&q, r, sizeof q);
            pc_hw_raster_apply(q.rects, q.count, q.block ? q.block : pool + q.offset);
            free(q.block);
            at += 1 + (int)sizeof q;
            break;
        }
        case C_BEFORE_WRITE: {
            int v[4];
            memcpy(v, r, sizeof v);
            if (pc_hw_before_write)
                pc_hw_before_write(v[0], v[1], v[2], v[3]);
            at += 1 + (int)sizeof v;
            break;
        }
        case C_STALE_COPY: {
            int v[6];
            memcpy(v, r, sizeof v);
            if (pc_hw_stale_copy)
                pc_hw_stale_copy(v[0], v[1], v[2], v[3], v[4], v[5]);
            at += 1 + (int)sizeof v;
            break;
        }
        default:
            return; /* (cannot happen: the records are this file's) */
        }
    }
    pool_used = 0; /* (the payloads are applied) */
}
