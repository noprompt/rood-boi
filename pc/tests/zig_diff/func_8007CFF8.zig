//! zig_diff spec: func_8007CFF8 -> func_8007CFF8.func_8007CFF8 (146C.c).
//! Inputs: any c_int arg0 (0, 1, 2, -1 and the extremes, or random) and a
//! random SVECTOR in the arena whose vx and vz are i16 edges or random, with
//! vz sometimes equal to vx, so a swapped or wrong-field read shows. The C has
//! no branch. Both callees are void recording stubs, so the call traces carry
//! the arguments and the state hashes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CFF8));

pub const classes = [_][:0]const u8{ "vx-equals-vz", "vx-negative", "vx-nonnegative" };

pub fn classify(args: Args) usize {
    const sv = args[1].?;
    if (sv.vx == sv.vz) return 0;
    if (sv.vx < 0) return 1;
    return 2;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const sv = ctx.alloc(v.SVECTOR);
    const edges = [_]i16{ 0, 1, -1, 32767, -32768 };
    sv.vx = ctx.pick(i16, &edges);
    sv.vz = ctx.pick(i16, &edges);
    if (ctx.chance(4)) sv.vz = sv.vx;
    const arg0 = ctx.pick(c_int, &.{ 0, 1, 2, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{ arg0, sv };
}
