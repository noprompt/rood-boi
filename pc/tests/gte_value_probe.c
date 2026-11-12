/* TEMPORARY: compares the GTE value functions (pc/src/gte_value.h) with the
 * old register interface (psycross inline_c.h macros on the global GTE) on
 * random and edge inputs: every result field and the FLAG word, with the
 * widescreen narrowing off and on, and checks a value call leaves the global
 * registers as they were.
 *
 * Delete this file, its ctest entry and its CMake lines together with the old
 * GTE state machine (pc/docs/plans/2026-11-08-off-the-ps1.md, Picture lane
 * step 1): once nothing calls the register interface there is nothing to
 * compare with. */
#include <libgte.h>
#include "psx/gtereg.h"
#include "psx/inline_c.h"
#include "gte_value.h"

/* (No system headers: PsyCross's types.h and sys/types.h disagree on u_long.) */
extern int dprintf(int fd, const char* format, ...);
extern int puts(const char* text);
extern int memcmp(const void* a, const void* b, __SIZE_TYPE__ size);
extern int pc_gte_widescreen;

static unsigned long long rng = 0x9e3779b97f4a7c15ull;
static unsigned next(void)
{
    rng ^= rng << 13;
    rng ^= rng >> 7;
    rng ^= rng << 17;
    return (unsigned)(rng >> 16);
}

static const int edge16[] = { 0, 1, -1, 2, 0x7fff, -0x8000, 0x7ffe, -0x7fff, 0x1000, -0x1000, 0x800, 0x4000, -0x4000 };
static const int edge32[] = { 0, 1, -1, 0x7fffffff, (int)0x80000000, 0x7ffff, -0x80000, 0x1000, 0x10000, -0x10000,
    0x3fffffff, -0x40000000 };

static short pick16(int mode)
{
    if (mode == 0)
        return (short)edge16[next() % (sizeof edge16 / sizeof *edge16)];
    if (mode == 1)
        return (short)((int)(next() % 8193) - 4096);
    return (short)next();
}

static int pick32(int mode)
{
    if (mode == 0)
        return edge32[next() % (sizeof edge32 / sizeof *edge32)];
    if (mode == 1)
        return (int)(next() % 0x200001) - 0x100000;
    return (int)next();
}

static int failures;
#define CHECK(cond, ...) \
    do { \
        if (!(cond)) { \
            if (++failures < 20) { \
                dprintf(2, "FAIL %s:%d: ", __FILE__, __LINE__); \
                dprintf(2, __VA_ARGS__); \
                dprintf(2, "\n"); \
            } \
        } \
    } while (0)

static void load_old(const MATRIX* m, const vs_gte_screen* s, const SVECTOR* v)
{
    gte_SetRotMatrix(m);
    gte_SetTransMatrix(m);
    C2_OFX = s->ofx;
    C2_OFY = s->ofy;
    C2_H = s->h;
    C2_DQA = s->dqa;
    C2_DQB = s->dqb;
    gte_ldv0(v);
}

static void compare(const char* what, const vs_gte_result* r, int project, const MATRIX* m, const SVECTOR* v)
{
    int i;
    CHECK(r->flag == CFC2(31), "%s flag %08x vs %08x (v %d %d %d rot %d %d %d t %d %d %d)", what, r->flag,
        CFC2(31), v->vx, v->vy, v->vz, m->m[0][0], m->m[0][1], m->m[0][2], m->t[0], m->t[1], m->t[2]);
    for (i = 0; i < 3; ++i) {
        CHECK(r->ir[i] == (short)(MFC2(9 + i) & 0xffff), "%s ir%d", what, i + 1);
        CHECK((unsigned)r->mac[1 + i] == MFC2(25 + i), "%s mac%d %d vs %d", what, i + 1, r->mac[1 + i],
            (int)MFC2(25 + i));
    }
    if (project) {
        uint sxy, otz;
        gte_stsxy(&sxy);
        gte_stszotz(&otz);
        CHECK((uint)r->sxy == sxy, "%s sxy %08x vs %08x", what, r->sxy, sxy);
        CHECK(r->otz == otz, "%s otz", what);
        CHECK(r->sz == MFC2(19), "%s sz", what);
        CHECK(r->sx == (short)(sxy & 0xffff) && r->sy == (short)(sxy >> 16), "%s sx sy", what);
        CHECK(r->ir0 == (short)MFC2(8), "%s ir0", what);
        CHECK((unsigned)r->mac[0] == MFC2(24), "%s mac0", what);
    }
}

int main(void)
{
    int round, wide;
    for (wide = 0; wide < 2; ++wide) {
        pc_gte_widescreen = wide;
        for (round = 0; round < 60000; ++round) {
            int mode = round % 3;
            MATRIX m;
            SVECTOR v = { 0, 0, 0, 0 };
            vs_gte_screen s;
            vs_gte_view view;
            vs_gte_result r;
            GTERegisters before;
            int i, j;
            for (i = 0; i < 3; ++i) {
                for (j = 0; j < 3; ++j)
                    m.m[i][j] = pick16(mode);
                m.t[i] = pick32(mode);
            }
            v.vx = pick16(mode);
            v.vy = pick16(mode);
            v.vz = pick16(mode);
            v.pad = (short)next();
            s.ofx = pick32(mode);
            s.ofy = pick32(mode);
            s.h = (short)(mode == 2 ? next() : (next() % 3 ? next() % 2000 : pick16(0)));
            s.dqa = pick16(mode);
            s.dqb = pick32(mode);
            /* Junk in the global registers: a value call must not read it. */
            for (i = 0; i < 32; ++i) {
                gte_global.CP2D.p[i].d = next();
                gte_global.CP2C.p[i].d = next();
            }
            before = gte_global;
            view = vs_gte_view_of(&m, s);
            r = vs_gte_project(&view, &v);
            CHECK(memcmp(&before, &gte_global, sizeof before) == 0, "project changed the global registers");
            load_old(&m, &s, &v);
            gte_rtps();
            compare("rtps", &r, 1, &m, &v);

            r = vs_gte_transform(&view, &v);
            load_old(&m, &s, &v);
            gte_rtv0tr();
            compare("rtv0tr", &r, 0, &m, &v);

            r = vs_gte_rotate(&view, &v);
            load_old(&m, &s, &v);
            gte_rtv0();
            compare("rtv0", &r, 0, &m, &v);

            /* Zero translation (SetRotMatrix; gte_zrtr), translation from a vector. */
            {
                vs_gte_view rot = vs_gte_view_rotation(&m, s);
                VECTOR t = { pick32(mode), pick32(mode), pick32(mode), 0 };
                vs_gte_view at = vs_gte_view_at(&m, &t, s);
                r = vs_gte_transform(&rot, &v);
                load_old(&m, &s, &v);
                CTC2(0, 5);
                CTC2(0, 6);
                CTC2(0, 7);
                gte_rtv0tr();
                compare("rtv0tr zrtr", &r, 0, &m, &v);
                r = vs_gte_project(&at, &v);
                load_old(&m, &s, &v);
                gte_SetTransVector(&t);
                gte_rtps();
                compare("rtps at", &r, 1, &m, &v);
            }
        }
    }
    {
        /* The projection the game set is read back as set. */
        vs_gte_screen s = { 160 << 16, 112 << 16, 800, -98, 340, 341, 256 };
        vs_gte_screen got;
        pc_gte_widescreen = 0;
        C2_OFX = s.ofx;
        C2_OFY = s.ofy;
        C2_H = s.h;
        C2_DQA = s.dqa;
        C2_DQB = s.dqb;
        C2_ZSF3 = s.zsf3;
        C2_ZSF4 = s.zsf4;
        got = vs_gte_screen_current();
        CHECK(!memcmp(&s, &got, sizeof s), "vs_gte_screen_current");
    }
    if (failures) {
        dprintf(2, "%d failures\n", failures);
        return 1;
    }
    puts("gte_value_probe ok");
    return 0;
}
