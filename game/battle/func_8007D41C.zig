//! Builds the battle screen's full-screen primitives: ten textured polygon strips and a sprite (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007D41C (src/BATTLE/BATTLE.PRG/146C.c)
/// Initialises the polygon strips and the sprite of the battle screen's full-height overlay.
pub fn func_8007D41C() callconv(.c) void {
    const base: *v.D_800F1ABC_t = v.g.D_800F1ABC().*.?;
    const col = v.g.D_800F1A78();

    c.SetPolyFT4(psx.cptr(c.POLY_FT4, &base.poly[0]));
    base.poly[0].r0 = col.r0;
    base.poly[0].g0 = col.g0;
    base.poly[0].b0 = col.b0;
    c.SetSemiTrans(&base.poly[0], 1);
    base.poly[0].u0 = 0;
    base.poly[0].v0 = 0;
    base.poly[0].u1 = 64;
    base.poly[0].v1 = 0;
    base.poly[0].u2 = 0;
    base.poly[0].v2 = 223;
    base.poly[0].u3 = 64;
    base.poly[0].v3 = 223;

    var i: c_int = 0;
    while (i < 10) : (i +%= 1) {
        const idx: usize = @intCast(i);
        base.poly[idx] = base.poly[0];
        // i < 10: the offset is at most 9 * sizeof(POLY_FT4).
        const poly = psx.byteAt(v.POLY_FT4, base, @as(isize, i) * @sizeOf(v.POLY_FT4));
        const x: c_int = i *% 64;
        poly.x0 = psx.conv(i16, x);
        poly.y0 = 0;
        poly.x1 = psx.conv(i16, x +% 64);
        poly.y1 = 0;
        poly.x2 = psx.conv(i16, x);
        poly.y2 = 223;
        poly.x3 = psx.conv(i16, x +% 64);
        poly.y3 = 223;
        base.poly[idx].tpage = c.GetTPage(2, 0, x, 0);
    }

    base.poly[4].u0 = 0;
    base.poly[4].v0 = 0;
    base.poly[4].u1 = 63;
    base.poly[4].v1 = 0;
    base.poly[4].u2 = 0;
    base.poly[4].v2 = 223;
    base.poly[4].u3 = 63;
    base.poly[4].v3 = 223;

    base.poly[9].u0 = 0;
    base.poly[9].v0 = 0;
    base.poly[9].u1 = 63;
    base.poly[9].v1 = 0;
    base.poly[9].u2 = 0;
    base.poly[9].v2 = 223;
    base.poly[9].u3 = 63;
    base.poly[9].v3 = 223;

    c.SetSprt(psx.cptr(c.SPRT, &base.sprite[0]));
    base.sprite[0].r0 = col.r0;
    base.sprite[0].g0 = col.g0;
    base.sprite[0].b0 = col.b0;
    c.SetSemiTrans(&base.sprite[0], 1);
    base.sprite[0].u0 = 0;
    base.sprite[0].v0 = 0;
    base.sprite[0].w = 64;
    base.sprite[0].h = 223;

    i = 0;
    while (i < 10) : (i +%= 1) {
        base.sprite[@intCast(i)] = base.sprite[0];
    }
}
