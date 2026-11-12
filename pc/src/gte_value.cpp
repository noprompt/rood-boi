/* The GTE's maths as values (gte_value_core.h): each call loads a private
 * register set from the view and the vector, runs the one operation in
 * PsyCross's GTE (the same arithmetic, flags, widescreen narrowing and
 * projection log as the register interface) and reads the results back.
 * gte_cur is pointed at the private set for the call, so the game's
 * registers (gte_global) stay as they were. */
#include "psx/gtereg.h"
#include "gte_value_core.h"

extern "C" const void* pc_gte_caller;

static void load_view(GTERegisters& regs, const vs_gte_view* view)
{
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
    regs.CP2C.p[29].sd = (short)view->screen.zsf3;
    regs.CP2C.p[30].sd = (short)view->screen.zsf4;
}

extern "C" vs_gte_result vs_gte_run(int op, const vs_gte_view* view, const short v[3], const void* caller)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    vs_gte_result r = {};
    int i;
    load_view(regs, view);
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

extern "C" vs_gte_result4 vs_gte_run4(const vs_gte_view* view, const short v[4][3], const void* caller)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    vs_gte_result4 r = {};
    int i;
    load_view(regs, view);
    /* V0..V2 as MTC2 stores them. */
    for (i = 0; i < 3; ++i) {
        regs.CP2D.p[2 * i].d = (unsigned short)v[i][0] | ((unsigned)(unsigned short)v[i][1] << 16);
        regs.CP2D.p[2 * i + 1].d = (unsigned short)v[i][2];
    }
    gte_cur = &regs;
    pc_gte_caller = caller;
    GTE_operator(0x0280030); /* RTPT */
    r.sxy[0] = (int)regs.CP2D.p[12].d;
    r.sxy[1] = (int)regs.CP2D.p[13].d;
    r.sxy[2] = (int)regs.CP2D.p[14].d;
    r.flag = regs.CP2C.p[31].d;
    regs.CP2D.p[0].d = (unsigned short)v[3][0] | ((unsigned)(unsigned short)v[3][1] << 16);
    regs.CP2D.p[1].d = (unsigned short)v[3][2];
    pc_gte_caller = caller;
    GTE_operator(0x0180001); /* RTPS */
    r.sxy[3] = (int)regs.CP2D.p[14].d;
    r.ir0 = regs.CP2D.p[8].sw.l;
    r.flag |= regs.CP2C.p[31].d;
    GTE_operator(0x168002E); /* AVSZ4 */
    r.otz = regs.CP2D.p[7].d;
    gte_cur = saved;
    return r;
}

extern "C" int vs_gte_nclip(unsigned sxy0, unsigned sxy1, unsigned sxy2)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    regs.CP2D.p[12].d = sxy0;
    regs.CP2D.p[13].d = sxy1;
    regs.CP2D.p[14].d = sxy2;
    gte_cur = &regs;
    GTE_operator(0x01400006);
    gte_cur = saved;
    return (int)regs.CP2D.p[24].d;
}

extern "C" unsigned vs_gte_avsz3(int zsf3, unsigned sz1, unsigned sz2, unsigned sz3)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    regs.CP2C.p[29].sd = (short)zsf3;
    regs.CP2D.p[17].d = sz1;
    regs.CP2D.p[18].d = sz2;
    regs.CP2D.p[19].d = sz3;
    gte_cur = &regs;
    GTE_operator(0x0158002D);
    gte_cur = saved;
    return (unsigned)regs.CP2D.p[7].w.l;
}

extern "C" void vs_gte_op0(unsigned r11, unsigned r22, unsigned r33, unsigned ir1, unsigned ir2, unsigned ir3, int mac[3])
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    regs.CP2C.p[0].d = r11;
    regs.CP2C.p[2].d = r22;
    regs.CP2C.p[4].d = (unsigned)(int)(short)r33;
    regs.CP2D.p[9].d = ir1;
    regs.CP2D.p[10].d = ir2;
    regs.CP2D.p[11].d = ir3;
    gte_cur = &regs;
    GTE_operator(0x0170000C);
    gte_cur = saved;
    for (int i = 0; i < 3; ++i)
        mac[i] = (int)regs.CP2D.p[25 + i].d;
}

extern "C" vs_gte_screen vs_gte_screen_current(void)
{
    vs_gte_screen s;
    s.ofx = gte_global.CP2C.p[24].sd;
    s.ofy = gte_global.CP2C.p[25].sd;
    s.h = gte_global.CP2C.p[26].sw.l;
    s.dqa = gte_global.CP2C.p[27].sw.l;
    s.dqb = gte_global.CP2C.p[28].sd;
    s.zsf3 = gte_global.CP2C.p[29].sw.l;
    s.zsf4 = gte_global.CP2C.p[30].sw.l;
    return s;
}
