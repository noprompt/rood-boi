//! zig_diff spec: func_800D17A8 -> func_800D17A8.func_800D17A8 (5BF94.c).
//! Inputs: three random VECTORs (every i32 field random) and a lerp weight
//! drawn from edges (0, 1, -1, 4096, the i32 extremes) and random values.
//! The output vector is sometimes the same object as arg0 or arg1, so the
//! store to arg3 is observed through the later reads. vs_battle_lerp is a
//! recording stub returning ctx.value(c_int), the same in both runs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D17A8));

pub const classes = [_][:0]const u8{ "distinct", "out-is-arg0", "out-is-arg1" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.alloc(v.VECTOR);
    const a1 = ctx.alloc(v.VECTOR);
    const a3 = ctx.alloc(v.VECTOR);
    if (ctx.chance(4)) {
        if (ctx.chance(2)) {
            return .{ a0, a1, ctx.pick(c_int, &.{ 0, 1, -1, 4096, std.math.minInt(c_int), std.math.maxInt(c_int) }), a0 };
        }
        return .{ a0, a1, ctx.pick(c_int, &.{ 0, 1, -1, 4096, std.math.minInt(c_int), std.math.maxInt(c_int) }), a1 };
    }
    return .{ a0, a1, ctx.pick(c_int, &.{ 0, 1, -1, 4096, std.math.minInt(c_int), std.math.maxInt(c_int) }), a3 };
}

pub fn classify(args: Args) usize {
    const out = args[3].?;
    if (out == args[0].?) return 1;
    if (out == args[1].?) return 2;
    return 0;
}
