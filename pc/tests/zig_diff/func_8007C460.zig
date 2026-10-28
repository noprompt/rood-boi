//! zig_diff spec: func_8007C460 -> func_8007C460.func_8007C460 (146C.c).
//! The unit has no branches and no calls: it stores its argument into
//! vs_battle_screenTransitionWipeAngle. The inputs cover the edges a porter
//! could get wrong: zero, negative values, the i16 and u16 boundaries, 4096,
//! INT_MAX and INT_MIN, and random values. Classes split negative, zero and
//! positive arguments. The global starts as random bytes, so a dropped store
//! shows as a mismatch.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C460));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{
        0,
        1,
        -1,
        4096,
        0x7FFF,
        0x8000,
        0xFFFF,
        0x10000,
        std.math.maxInt(c_int),
        std.math.minInt(c_int),
    };
    return .{ctx.pick(c_int, &edges)};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
