/* The producer-owned registrations of an ordering table (hw_registry.c). */
#ifndef PC_HW_REGISTRY_H
#define PC_HW_REGISTRY_H
#include <stdint.h>
#include "gpu_attr.h"
typedef struct {
    uintptr_t start, end;
    uint32_t list;
    int covered;
} effect_range;
typedef struct {
    uintptr_t packet;
    int length; /* x1 - x0 of the line it was made for */
    float top[2], bottom[2];
} span_shape;

/* The table starts: what was registered while it was built is the active set (called at DrawOTag). */
void pc_hwr_activate(void);
void pc_hwr_forget_pending(void); /* a restored state does not own what the abandoned timeline registered */
const effect_range* pc_hwr_effect(int index); /* NULL: none */
void pc_hwr_cover_effects(uint32_t list);
/* The producer's side of a table's start (the registrations, the bubbles' frame, the suppress flag), and of the native list
 * markers it records (the coverage assumed). */
void pc_hwr_begin_ot(void);
void pc_hwr_marker(uint32_t list, const int* clip);
void pc_hwr_translucent(uint32_t list);
const span_shape* pc_hwr_span_shape_of(uintptr_t packet);
/* The drawn areas (T1 R4e): where the renderer's target holds what the game's VRAM lacks (a primitive drew there). One set, the renderer's own
 * (the producer's copy went when the read-backs did: nothing asks the game's side whether an area is stale any more). Kinds: STALE_MISSING
 * (the game's VRAM lacks what the renderer drew: every primitive, since T5-6, and what a native list drew), STALE_PLACED (the target's picture
 * is placed for the view). Each is a bitmap of 64 x 16 cells (bit `band` of word `column`): a mark sets the cells it touches; the marks only
 * grow until a resync. A draw that samples a marked cell takes own copies of it (gpu_hw.c own_add). */
enum { PC_STALE_MISSING = 1, PC_STALE_PLACED = 2, PC_STALE_DRAWN = 4 };
typedef struct {
    uint32_t missing[16], placed[16]; /* MISSING, PLACED: the cells that differ now (an upload or a fill over whole cells ends it) */
    uint32_t ever_missing[16], ever_placed[16]; /* the same marks without that ending: where draws have flushed the batch before them (see gpu_hw.c own_flush) */
    int in_ot;                        /* an ordering table is being drawn (its native areas are marked) */
} pc_stale_set;
void pc_stale_mark(pc_stale_set* set, const int* clip, int kind);
/* Whether any cell is stale; whether one of `cells` meets the rectangle (x, y, w, h). */
int pc_stale_any(const pc_stale_set* set);
int pc_stale_meets(const uint32_t* cells, int x, int y, int w, int h);
/* The pixel rectangle {x0, y0, x1, y1} (cell-aligned, x1 and y1 exclusive) bounding the stale cells that meet (x, y, w, h); 0 when none does. */
int pc_stale_bbox(const uint32_t* cells, int x, int y, int w, int h, int* out);
int pc_stale_cells(const uint32_t* cells); /* how many are stale */
/* A copy of (sx, sy, w, h) to (dx, dy): a drawn source leaves the destination drawn; a clean one makes it clean (the cells wholly inside it). */
void pc_stale_copy(pc_stale_set* set, int sx, int sy, int dx, int dy, int w, int h);
/* A write that leaves the renderer's VRAM and the target equal (an upload, a fill): the cells lying wholly inside (x, y, w, h) are no longer drawn. */
void pc_stale_clear_covered(pc_stale_set* set, int x, int y, int w, int h);
#endif
