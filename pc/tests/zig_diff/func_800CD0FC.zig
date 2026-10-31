//! zig_diff spec: func_800CD0FC -> func_800CD0FC.func_800CD0FC (5BF94.c).
//! Inputs: arg1 (unsigned) from the edges 0..5, 0x7FFFFFFF, 0x80000000 and
//! 0xFFFFFFFF, so the `< 3` test sees equal sides at arg1 == 3 and the high
//! bit set both ways; arg0 (signed) from zero, the sign bit, and values
//! whose shift by 16 overflows. Both sprite and value tables get edge
//! entries. The sprite-default callee returns a fresh 5-word arena block
//! (the C writes word 4), fills it with random words, and sometimes rewrites
//! an entry of D_800EC2D8, which the C reads after the call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CD0FC));

pub const classes = [_][:0]const u8{ "index-0", "index-1", "index-2", "out-of-range" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const sprites = v.g.D_800EC2CC();
    const values = v.g.D_800EC2D8();
    for (0..3) |i| {
        sprites[i] = ctx.pick(i32, &.{ 0, -1, 1, 0x7FFF, -0x8000, 0x7FFFFFFF });
        values[i] = ctx.pick(i32, &.{ 0, -1, 0x7FFFFFFF, -0x80000000, 0x0F0F });
    }
    const arg0 = ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFF, -0x8000, 0x7FFFFFFF, -0x80000000 });
    const arg1 = ctx.pick(c_uint, &.{ 0, 1, 2, 3, 4, 5, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const idx = args[1];
    if (idx == 0) return 0;
    if (idx == 1) return 1;
    if (idx == 2) return 2;
    return 3;
}

pub const stubs = struct {
    pub fn vs_battle_setSpriteDefault(ctx: *zd.Ctx, wh: anytype, xy: anytype) [*c]c_uint {
        _ = wh;
        _ = xy;
        const p: [*]c_uint = @ptrCast(@alignCast(ctx.allocBytes(20, 4)));
        for (0..5) |i| p[i] = ctx.value(u32);
        if (ctx.value(u1) == 1) v.g.D_800EC2D8()[ctx.value(u8) % 3] = ctx.value(i32);
        return p;
    }
};
