/* The GTE's maths as values (gte_value_core.h): each call loads a private
 * register set from the view and the vector, runs the one operation in
 * PsyCross's GTE (the same arithmetic, flags, widescreen narrowing and
 * projection log as the register interface) and reads the results back.
 * gte_cur is pointed at the private set for the call, so the game's
 * scratch registers stay as they were. */
#include "psx/gtereg.h"
#include "gte_value_core.h"

extern "C" const void* pc_gte_caller;

/* The projection the game has set (SetGeomOffset, SetGeomScreen, InitGeom): kept in step with the registers by
 * rood_gte_screen_written (psycross CTC2), and what the value functions read. Game state, with the registers. */
static vs_gte_screen frame_screen;

extern "C" void rood_gte_screen_written(int reg)
{
    /* Only writes to the game's own registers: a value call's private set is not the game's. */
    if (gte_cur)
        return;
    switch (reg) {
    case 24: frame_screen.ofx = gte_scratch.CP2C.p[24].sd; break;
    case 25: frame_screen.ofy = gte_scratch.CP2C.p[25].sd; break;
    case 26: frame_screen.h = gte_scratch.CP2C.p[26].sw.l; break;
    case 27: frame_screen.dqa = gte_scratch.CP2C.p[27].sw.l; break;
    case 28: frame_screen.dqb = gte_scratch.CP2C.p[28].sd; break;
    case 29: frame_screen.zsf3 = gte_scratch.CP2C.p[29].sw.l; break;
    case 30: frame_screen.zsf4 = gte_scratch.CP2C.p[30].sw.l; break;
    }
}

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

extern "C" void vs_gte_light_transform(const unsigned llm[5], const unsigned bk[3], const short v[3], short ir[3])
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    for (int i = 0; i < 5; ++i)
        regs.CP2C.p[8 + i].d = llm[i];
    regs.CP2C.p[12].d = (unsigned)(int)(short)llm[4]; /* CTC2 sign-extends register 12 */
    for (int i = 0; i < 3; ++i)
        regs.CP2C.p[13 + i].d = bk[i];
    regs.CP2D.p[0].d = (unsigned short)v[0] | ((unsigned)(unsigned short)v[1] << 16);
    regs.CP2D.p[1].d = (unsigned short)v[2];
    gte_cur = &regs;
    GTE_operator(0x04A2012);
    gte_cur = saved;
    for (int i = 0; i < 3; ++i)
        ir[i] = regs.CP2D.p[9 + i].sw.l;
}

/* DPCS: the colour word faded toward the far colour (all three channels `far_color`) by IR0, as RGB2 holds it. */
extern "C" unsigned vs_gte_dpcs(unsigned far_color, unsigned rgbc, unsigned ir0)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    regs.CP2C.p[21].d = far_color;
    regs.CP2C.p[22].d = far_color;
    regs.CP2C.p[23].d = far_color;
    regs.CP2D.p[6].d = rgbc;
    regs.CP2D.p[8].d = ir0;
    gte_cur = &regs;
    GTE_operator(0x0780010);
    gte_cur = saved;
    return regs.CP2D.p[22].d;
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

/* SetGeomOffset and SetGeomScreen: the record is set; the registers are not written. */
extern "C" void rood_gte_screen_set(int reg, int value)
{
    switch (reg) {
    case 24: frame_screen.ofx = value; break;
    case 25: frame_screen.ofy = value; break;
    case 26: frame_screen.h = (short)value; break;
    }
}

extern "C" {
void MTC2(unsigned int value, int reg);
void CTC2(unsigned int value, int reg);
unsigned int MFC2(int reg);
unsigned int CFC2(int reg);
int doCOP2(int op);
}

static_assert(sizeof(GTERegisters) <= sizeof(vs_gte_ctx), "vs_gte_ctx holds the registers");

/* One instruction on a context's registers: gte_cur is the context for its duration. */
#define ON_CTX(ctx, expression) \
    do { \
        GTERegisters* saved_ = gte_cur; \
        gte_cur = (GTERegisters*)(ctx); \
        expression; \
        gte_cur = saved_; \
    } while (0)

extern "C" void vs_gte_ctx_init(vs_gte_ctx* ctx)
{
    __builtin_memset(ctx, 0, sizeof(GTERegisters));
}

extern "C" void vs_gte_mtc2(vs_gte_ctx* ctx, int reg, unsigned value) { ON_CTX(ctx, MTC2(value, reg)); }
extern "C" void vs_gte_ctc2(vs_gte_ctx* ctx, int reg, unsigned value) { ON_CTX(ctx, CTC2(value, reg)); }
extern "C" unsigned vs_gte_mfc2(vs_gte_ctx* ctx, int reg)
{
    unsigned value;
    ON_CTX(ctx, value = MFC2(reg));
    return value;
}
extern "C" unsigned vs_gte_cfc2(vs_gte_ctx* ctx, int reg)
{
    unsigned value;
    ON_CTX(ctx, value = CFC2(reg));
    return value;
}
extern "C" void vs_gte_cop2(vs_gte_ctx* ctx, int op) { ON_CTX(ctx, doCOP2(op)); }

/* ApplyMatrixLV (the SDK routine, on a register set of its own): the long vector rotated by a matrix. */
extern "C" void* ApplyMatrixLV(void* m, void* v0, void* v1);
extern "C" void vs_gte_apply_matrix_lv(void* m, void* v0, void* v1)
{
    GTERegisters regs = {};
    GTERegisters* saved = gte_cur;
    gte_cur = &regs;
    ApplyMatrixLV(m, v0, v1);
    gte_cur = saved;
}

extern "C" int rood_screen_ofx(void)
{
    return frame_screen.ofx;
}

extern "C" vs_gte_screen vs_gte_screen_current(void)
{
    return frame_screen;
}
