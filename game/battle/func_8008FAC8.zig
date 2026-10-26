//! Falling particle quads: projects each live particle, builds its quad from two projected points and links it into the ordering table (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008FAC8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Projects every live particle, builds its quad from two projected points and links it into the ordering table.
pub fn func_8008FAC8() callconv(.c) void {
    const scratch: *v.vs_scratch_t = @ptrFromInt(0x1F800000);
    c.SetRotMatrix(psx.cptr(c.MATRIX, &scratch.viewMatrix));
    c.SetTransMatrix(psx.cptr(c.MATRIX, &scratch.viewMatrix));
    const base: ?*v.D_800F1DD4_t = v.g.D_800F1DD4().*;
    var i: c_int = 0;
    while (i < @as(c_int, v.g.D_800F1DC0().*)) : (i +%= 1) {
        const particle: *v.D_800F1DD4_t = psx.at(base.?, i);
        if (particle.unkC != 0) continue;
        if (v.g.D_800F1BA4().* == 0) {
            particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) -% (@as(c_int, particle.unkF) *% v.g.vs_gametime_tickspeed().*));
            if (@as(c_int, particle.unk2) < -1024) c.func_8008FA14(psx.cptr(c.D_800F1DD4_t, particle));
        }
        var prim: *v.POLY_G4 = @ptrFromInt(@as(usize, psx.rawOf(scratch.unk0)));

        var dx: c_int = undefined;
        var dy: c_int = undefined;
        v.g.pc_gte_anchored().* +%= 1;
        var depth: c_int = c.RotTransPers(@ptrCast(particle), @ptrFromInt(@intFromPtr(&prim.x1)), &dx, &dy);
        v.g.pc_gte_anchored().* -%= 1;

        const widen: c_int = if (v.g.pc_gte_widescreen().* != 0) 54 else 0;
        const y1m: c_uint = psx.conv(c_uint, @as(c_int, psx.conv(u16, prim.y1)) -% 1);
        if (y1m >= 239 or @as(c_int, prim.x1) <= (0 -% widen) or @as(c_int, prim.x1) >= (@as(c_int, 320) +% widen) or depth <= 64 or depth >= 2048) continue;

        particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) +% 192);
        v.g.pc_gte_anchored().* +%= 1;
        depth = c.RotTransPers(@ptrCast(particle), @ptrFromInt(@intFromPtr(&prim.x2)), &dx, &dy);
        v.g.pc_gte_anchored().* -%= 1;
        particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) -% 192);

        dx = @divTrunc(@as(c_int, prim.x2) -% @as(c_int, prim.x1), 32);
        dy = @divTrunc(@as(c_int, prim.y2) -% @as(c_int, prim.y1), 32);
        prim.x0 = psx.conv(i16, @as(c_int, prim.x1) +% dx +% dy);
        prim.y0 = psx.conv(i16, @as(c_int, prim.y1) +% dy -% dx);
        prim.x3 = psx.conv(i16, @as(c_int, prim.x1) +% dx -% dy);
        prim.y3 = psx.conv(i16, dx +% (@as(c_int, prim.y1) +% dy));

        // setPolyG4 + setSemiTrans(prim, 1): P_TAG len at the tag's top byte, code at offset 7.
        const tag: *v.P_TAG = @ptrCast(prim);
        psx.setBits(tag, "len", 8);
        tag.code = 0x38;
        tag.code |= 0x02;

        prim.r1 = 192;
        prim.g1 = 64;
        prim.b1 = 64;
        prim.r0 = 32;
        prim.g0 = 8;
        prim.b0 = 32;
        prim.r3 = 32;
        prim.g3 = 8;
        prim.b3 = 32;
        prim.r2 = 0;
        prim.g2 = 0;
        prim.b2 = 0;

        // (u_long*)ot + depth: the ordering table is a native pointer, and the
        // signed depth is sign-extended into the address (u_long is 4 bytes).
        const otBase: usize = @intFromPtr(psx.get(scratch.unk4).?);
        const otStep: isize = @as(isize, depth) *% 4;
        const otAddr: usize = otBase +% @as(usize, @bitCast(otStep));
        const ot: ?*anyopaque = @ptrFromInt(otAddr);
        c.AddPrim(ot, prim);
        prim = @ptrFromInt(@intFromPtr(prim) +% @sizeOf(v.POLY_G4));
        psx.put(&scratch.unk0, prim);
        _ = c.pc_insert_tpage(depth, 32);
    }
}
