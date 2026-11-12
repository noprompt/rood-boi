/* GTE maths as values (see gte_value_core.h): the game-typed wrappers.
 *
 *   vs_gte_view v = vs_gte_view_of(&matrix, vs_gte_screen_current());
 *   vs_gte_result r = vs_gte_project(&v, &vertex);      was ldv0; rtps; stsxy; stszotz
 *   vs_gte_result r = vs_gte_transform(&v, &vertex);    was ldv0; rtv0tr; stlvnl
 *   vs_gte_result r = vs_gte_rotate(&v, &vertex);       was ApplyRotMatrix
 *
 * The registers are not touched, so a view set in one function cannot leak
 * into another: it is passed. */
#ifndef ROOD_GTE_VALUE_H
#define ROOD_GTE_VALUE_H
#include <libgte.h>
#include "gte_value_core.h"

/* For a transform or a rotation, which do not project. */
#define VS_GTE_NO_SCREEN ((vs_gte_screen){ 0, 0, 0, 0, 0, 0, 0 })

/* Rotation and translation of m (SetRotMatrix, SetTransMatrix). */
static inline vs_gte_view vs_gte_view_of(const MATRIX* m, vs_gte_screen screen)
{
    vs_gte_view view;
    int i, j;
    for (i = 0; i < 3; ++i) {
        for (j = 0; j < 3; ++j)
            view.rot[i][j] = m->m[i][j];
        view.t[i] = m->t[i];
    }
    view.screen = screen;
    return view;
}

/* Rotation of m, translation zero (SetRotMatrix; gte_zrtr). */
static inline vs_gte_view vs_gte_view_rotation(const MATRIX* m, vs_gte_screen screen)
{
    vs_gte_view view = vs_gte_view_of(m, screen);
    view.t[0] = view.t[1] = view.t[2] = 0;
    return view;
}

/* Rotation of m, translation t (gte_SetRotMatrix, gte_SetTransVector). */
static inline vs_gte_view vs_gte_view_at(const MATRIX* m, const VECTOR* t, vs_gte_screen screen)
{
    vs_gte_view view = vs_gte_view_of(m, screen);
    view.t[0] = t->vx;
    view.t[1] = t->vy;
    view.t[2] = t->vz;
    return view;
}

#define VS_GTE_CALLER __builtin_return_address(0)

static inline __attribute__((always_inline)) vs_gte_result vs_gte_project(
    const vs_gte_view* view, const SVECTOR* v)
{
    return vs_gte_run(VS_GTE_RTPS, view, &v->vx, VS_GTE_CALLER);
}

static inline __attribute__((always_inline)) vs_gte_result vs_gte_transform(
    const vs_gte_view* view, const SVECTOR* v)
{
    return vs_gte_run(VS_GTE_RTV0TR, view, &v->vx, VS_GTE_CALLER);
}

static inline __attribute__((always_inline)) vs_gte_result vs_gte_rotate(
    const vs_gte_view* view, const SVECTOR* v)
{
    return vs_gte_run(VS_GTE_RTV0, view, &v->vx, VS_GTE_CALLER);
}

/* Transform or rotate v and store the result as a vector (gte_stlvnl): its pad is
 * left alone; the flags are dropped. */
static inline __attribute__((always_inline)) void vs_gte_transform_to(
    VECTOR* out, const vs_gte_view* view, const SVECTOR* v)
{
    vs_gte_result r = vs_gte_run(VS_GTE_RTV0TR, view, &v->vx, VS_GTE_CALLER);
    out->vx = r.mac[1];
    out->vy = r.mac[2];
    out->vz = r.mac[3];
}

static inline __attribute__((always_inline)) void vs_gte_rotate_to(
    VECTOR* out, const vs_gte_view* view, const SVECTOR* v)
{
    vs_gte_result r = vs_gte_run(VS_GTE_RTV0, view, &v->vx, VS_GTE_CALLER);
    out->vx = r.mac[1];
    out->vy = r.mac[2];
    out->vz = r.mac[3];
}

/* MAC1..3 into a vector (gte_stlvnl): its pad is left alone. */
static inline void vs_gte_mac_to_vector(VECTOR* out, const vs_gte_result* r)
{
    out->vx = r->mac[1];
    out->vy = r->mac[2];
    out->vz = r->mac[3];
}

/* IR1..3 into a short vector (gte_stsv). */
static inline void vs_gte_ir_to_svector(SVECTOR* out, const vs_gte_result* r)
{
    out->vx = r->ir[0];
    out->vy = r->ir[1];
    out->vz = r->ir[2];
}
#endif
