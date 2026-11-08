/* The GTE's maths as values (gte_value_core.h): each call loads a private
 * register set from the view and the vector, runs the one operation in
 * PsyCross's GTE (the same arithmetic, flags, widescreen narrowing and
 * projection log as the register interface) and reads the results back.
 * gte_cur is pointed at the private set for the call, so the game's
 * registers (gte_global) stay as they were. */
#include "psx/gtereg.h"
#include "gte_value_core.h"

extern "C" const void* pc_gte_caller;

extern "C" vs_gte_result vs_gte_run(int op, const vs_gte_view* view, const short v[3], const void* caller)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    vs_gte_result r = {};
    int i;
    /* Control registers as CTC2 stores them (R33 sign-extended). */
    regs.CP2C.p[0].d = (unsigned short)view->rot[0][0] | ((unsigned)(unsigned short)view->rot[0][1] << 16);
    regs.CP2C.p[1].d = (unsigned short)view->rot[0][2] | ((unsigned)(unsigned short)view->rot[1][0] << 16);
    regs.CP2C.p[2].d = (unsigned short)view->rot[1][1] | ((unsigned)(unsigned short)view->rot[1][2] << 16);
    regs.CP2C.p[3].d = (unsigned short)view->rot[2][0] | ((unsigned)(unsigned short)view->rot[2][1] << 16);
    regs.CP2C.p[4].sd = view->rot[2][2];
    for (i = 0; i < 3; ++i)
        regs.CP2C.p[5 + i].sd = view->t[i];
    regs.CP2C.p[24].sd = view->screen.ofx;
    regs.CP2C.p[25].sd = view->screen.ofy;
    regs.CP2C.p[26].sd = (short)view->screen.h;
    regs.CP2C.p[27].sd = (short)view->screen.dqa;
    regs.CP2C.p[28].sd = view->screen.dqb;
    /* V0 as MTC2 stores it. */
    regs.CP2D.p[0].d = (unsigned short)v[0] | ((unsigned)(unsigned short)v[1] << 16);
    regs.CP2D.p[1].d = (unsigned short)v[2];
    gte_cur = &regs;
    pc_gte_caller = caller;
    GTE_operator(op);
    gte_cur = saved;
    r.sxy = (int)regs.CP2D.p[14].d;
    r.sx = regs.CP2D.p[14].sw.l;
    r.sy = regs.CP2D.p[14].sw.h;
    r.sz = regs.CP2D.p[19].w.l;
    r.otz = r.sz >> 2;
    r.ir0 = regs.CP2D.p[8].sw.l;
    for (i = 0; i < 3; ++i)
        r.ir[i] = regs.CP2D.p[9 + i].sw.l;
    for (i = 0; i < 4; ++i)
        r.mac[i] = regs.CP2D.p[24 + i].sd;
    r.flag = regs.CP2C.p[31].d;
    if (op != VS_GTE_RTPS) {
        /* Only RTPS writes the screen registers. */
        r.sxy = r.sx = r.sy = 0;
        r.sz = r.otz = 0;
        r.ir0 = 0;
        r.mac[0] = 0;
    }
    return r;
}

extern "C" vs_gte_screen vs_gte_screen_current(void)
{
    vs_gte_screen s;
    s.ofx = gte_global.CP2C.p[24].sd;
    s.ofy = gte_global.CP2C.p[25].sd;
    s.h = gte_global.CP2C.p[26].sw.l;
    s.dqa = gte_global.CP2C.p[27].sw.l;
    s.dqb = gte_global.CP2C.p[28].sd;
    return s;
}
