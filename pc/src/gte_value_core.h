/* The GTE's maths as values: plain types and the one entry point.
 *
 * A call takes a view (rotation, translation and projection parameters) and a
 * vector and returns what the GTE would have left in its registers, with the
 * GTE's own fixed-point rounding, clamping and FLAG bits (the arithmetic is
 * PsyCross's, pc/third_party/psycross/src/gte). It runs on a private register
 * set: the game's registers are neither read nor changed. The typed wrappers
 * (MATRIX, SVECTOR, VECTOR) are in gte_value.h. */
#ifndef ROOD_GTE_VALUE_CORE_H
#define ROOD_GTE_VALUE_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

/* The projection: OFX and OFY as the registers hold them (16.16), H, and the
 * depth cue's DQA and DQB. */
typedef struct {
    int ofx, ofy, h, dqa, dqb;
} vs_gte_screen;

/* Rotation, translation, projection. */
typedef struct {
    short rot[3][3];
    int t[3];
    vs_gte_screen screen;
} vs_gte_view;

/* The registers an operation writes; the others are zero.
 *   project:   sxy (SXY2 as stored by gte_stsxy), sx, sy, sz (SZ3), otz (SZ3 >> 2,
 *              as gte_stszotz stores it), ir0 (depth cue), ir, mac, flag.
 *   transform, rotate: ir (gte_stsv), mac (gte_stlvnl), flag. */
typedef struct {
    int sxy;
    short sx, sy;
    unsigned sz, otz;
    short ir0, ir[3];
    int mac[4];
    unsigned flag;
} vs_gte_result;

enum { VS_GTE_RTPS = 0x0180001, VS_GTE_RTV0TR = 0x0480012, VS_GTE_RTV0 = 0x0486012 };

/* Runs GTE operation `op` on vector v (three shorts); `caller` is the code
 * address the projection log attributes the work to. */
vs_gte_result vs_gte_run(int op, const vs_gte_view* view, const short v[3], const void* caller);

/* The projection the game has set so far (SetGeomOffset, SetGeomScreen): the
 * one piece of GTE state left global, until the camera holds it. */
vs_gte_screen vs_gte_screen_current(void);

#ifdef __cplusplus
}
#endif
#endif
