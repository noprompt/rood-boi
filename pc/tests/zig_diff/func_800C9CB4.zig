//! zig_diff spec: func_800C9CB4 -> func_800C9CB4.func_800C9CB4 (5BF94.c).
//! Inputs: arg0 is 0xFF about one time in ten (the early exit) and otherwise a
//! 0..31 index into the 32-entry status icon table; D_800EB9B0 is zero five
//! times in six, else a random nonzero (both signs); arg1 mostly edge values
//! around 0, +-7 (so var_s1 == 9 on both sides) and +-8, else -40..40, plus the
//! 16-bit limits; arg2 mostly edge values with the low bits set or clear, else
//! a range that keeps arg2 * 16 inside int. vs_scratch.unk4 points at a 64-byte
//! arena block, so the two primitive writes (indices 0..5) stay inside it. The
//! texture-page callee is a recording stub that writes its primitive and returns
//! the same pointer or one element on, so the C's store lands in memory the
//! harness owns. Limitation: arg0 is an index into a 32-entry table, so its sign
//! bit cannot be set without reading before the table; the sign-bit value flag
//! on `arg0 & 0x10` is therefore not reachable.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C9CB4));

pub const classes = [_][:0]const u8{
    "guard-off",
    "neg-arg1",
    "pos-arg1",
    "inner-ge9-aligned",
    "inner-ge9-unaligned",
    "inner-lt9",
};

pub const stubs = struct {
    pub fn vs_battle_setSpriteDefaultTexPage(
        ctx: *zd.Ctx,
        brightnessTransparency: anytype,
        xy: anytype,
        wh: anytype,
        nextPrim: anytype,
    ) @TypeOf(nextPrim) {
        _ = brightnessTransparency;
        _ = xy;
        _ = wh;
        nextPrim[0] = ctx.value(u32);
        nextPrim[1] = ctx.value(u32);
        return nextPrim + @as(usize, ctx.value(u1));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const scratch = v.g.vs_scratch();
    const buf = ctx.allocBytes(64, 16);
    psx.put(&scratch.unk4, @as(*anyopaque, @ptrCast(buf + 4)));

    v.g.D_800EB9B0().* = if (ctx.chance(6)) (ctx.int(i32) | 1) else 0;

    const arg0: c_int = if (ctx.chance(10)) 0xFF else ctx.range(c_int, 0, 31);
    const arg1: c_int = if (ctx.chance(2))
        ctx.range(c_int, -40, 40)
    else
        ctx.edge(c_int, &.{ 0, 7, -7, 8, -8, 9, -9, 16, -16, 1, -1, 0x7FFF, -0x8000 });
    const arg2: c_int = if (ctx.chance(2))
        ctx.range(c_int, -(1 << 26), 1 << 26)
    else
        ctx.edge(c_int, &.{ 0, 1, 7, 8, -1, -8, 0x3FFFFFF, -0x4000000, 0x10, 0x18 });
    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    const arg1 = args[1];
    const arg2 = args[2];
    if (arg0 == 0xFF or v.g.D_800EB9B0().* != 0) return 0;
    if ((arg0 & 0x10) != 0 and (arg2 & 8) == 0) {
        const s1: c_int = if (arg1 < 0) arg1 + 16 else 16 - arg1;
        if (s1 >= 9) return if ((arg2 & 7) == 0) 3 else 4;
        return 5;
    }
    return if (arg1 < 0) 1 else 2;
}
