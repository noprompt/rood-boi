//! zig_diff spec: func_8007D734 -> func_8007D734.func_8007D734 (146C.c).
//! Inputs: the draw state D_800F1B98 over idle, the early return at 1, the
//! draw at 2 and the count and free at 3..6 (with the heap block null or
//! present), and a frame block with room either side of the D_800F1ABC object
//! (frame index -2..5). The poly/sprite choice comes from D_800F1A28[2], which
//! is the same 16-bit word as D_800F1A2C (the table's next symbol); both are
//! written with one value, so the C reads the same word whichever way it
//! reaches it. D_800F1A30[0] and [1] take the 0x1000 and equal-pair cases so
//! the sprite path is reached about one time in eight of the draws. D_800F1A40
//! has both truth values, with and without the sign bit. D_800F1A68 and
//! D_800F1A44 take edges and random values. RotTrans writes random sp50
//! coordinates and GetTPage returns random page words. The matrix calls and
//! AddPrim change nothing the C reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D734));

pub const classes = [_][:0]const u8{
    "idle",
    "early-return",
    "draw-sprite",
    "draw-poly",
    "count-3",
    "free-null",
    "free",
};

pub const stubs = struct {
    /// Writes the projected vertex the C reads back from sp50 (vx, vy).
    pub fn RotTrans(ctx: *zd.Ctx, v0: anytype, v1: anytype, flag: anytype) void {
        _ = v0;
        _ = flag;
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        out.vx = ctx.value(i32);
        out.vy = ctx.value(i32);
    }

    /// The page word the C passes on to SetDrawMode or stores as tpage.
    pub fn GetTPage(ctx: *zd.Ctx, tp: anytype, abr: anytype, x: anytype, y: anytype) u16 {
        _ = tp;
        _ = abr;
        _ = x;
        _ = y;
        return ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // A frame block with 512 bytes of room before the object and enough after it
    // for every index the frame index below can produce.
    const block = ctx.allocBytes(2048, 16);
    const obj: *v.D_800F1ABC_t = @ptrCast(@alignCast(block + 512));

    const state: i32 = if (ctx.chance(3))
        ctx.range(i32, -100000, 100000)
    else
        ctx.edge(i32, &.{ -2147483648, -1, 0, 1, 2, 2, 2, 3, 3, 4, 4, 5, 6 });
    v.g.D_800F1B98().* = state;
    // The draw (state 2) always has the block; the free path may see null.
    v.g.D_800F1ABC().* = if (state != 2 and ctx.chance(2)) null else obj;

    v.g.vs_main_frameBuf().* = ctx.edge(i32, &.{ 0, 1, 0, 1, 2, 3, 5, -1, -2 });
    v.g.D_800F1A40().* = ctx.edge(i32, &.{ 0, 1, -1, -2147483648, 0x100 });
    v.g.D_800F1A44().* = ctx.pick(u32, &.{ 0, 1, 0xFFFF_FFFF, 0x8000_0000 });

    const d68 = v.g.D_800F1A68();
    d68.unk0 = ctx.pick(i32, &.{ 0, -160, -0xA0, -0x8000_0000, 0x7FFF_FF00 });
    d68.unk4 = ctx.pick(i32, &.{ 0, -112, -0x70, 0x7FFF_FF00 });

    // D_800F1A28[2] and D_800F1A2C are one word: the C's first test reads the
    // former, the poly loop's tpage test the latter. Both get the same value.
    // Its low 12 bits pick the poly or sprite draw; half the time they are zero.
    const low: i16 = if (ctx.chance(2))
        ctx.edge(i16, &.{ 0, 4096, -4096, -32768, 0x7000 })
    else
        ctx.edge(i16, &.{ 1, -1, 0x0FFF, 2049, -32767, 2048 });
    v.g.D_800F1A2C().* = low;
    v.g.D_800F1A28()[2] = low;

    const a30 = v.g.D_800F1A30();
    a30[0] = if (ctx.chance(2)) 0x1000 else ctx.pick(i32, &.{ 0, -4096, 0x800, 4097 });
    a30[1] = if (ctx.chance(2)) a30[0] else ctx.pick(i32, &.{ 0x1000, 0, -1 });

    const arg0: ?*anyopaque = @ptrCast(block);
    return .{arg0};
}

fn polyBranch() bool {
    const a30 = v.g.D_800F1A30();
    const low: u16 = @bitCast(v.g.D_800F1A28()[2]);
    return (low & 0xFFF) != 0 or a30[0] != 0x1000 or a30[1] != a30[0];
}

pub fn classify(args: Args) usize {
    _ = args;
    const st = v.g.D_800F1B98().*;
    if (st == 1) return 1;
    if (st == 2) return if (polyBranch()) 3 else 2;
    if (st == 3) return 4;
    if (st >= 4) return if (v.g.D_800F1ABC().* == null) 5 else 6;
    return 0;
}
