//! zig_diff spec: func_8007C444 -> func_8007C444.func_8007C444 (146C.c).
//! Inputs: three c_int arguments, each an edge value (0, +-1, 2, the 16-bit
//! and 32-bit extremes, 0x12345678) or a random value. The globals start
//! with random bytes too, so a store that is skipped shows up. The C only
//! stores the three arguments to the screen-transition globals; the spec
//! checks those stores and that nothing else is written. Input classes split
//! runs by the sign of arg0 (the effect), the case a sign-related slip in
//! the store would show up in.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C444));

pub const classes = [_][:0]const u8{ "arg0-negative", "arg0-zero", "arg0-positive" };

const edges = [_]c_int{
    0,
    1,
    -1,
    2,
    32767,
    -32768,
    65535,
    65536,
    std.math.maxInt(c_int),
    std.math.minInt(c_int),
    0x12345678,
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Old values differ from the new ones, so a missing store is visible.
    v.g.vs_battle_screenTransitionEffect().* = ctx.int(i32);
    v.g.vs_battle_screenTransitionSpeed().* = ctx.int(i32);
    v.g.vs_battle_screenTransitionWipeAngle().* = ctx.int(i32);
    return .{
        ctx.pick(c_int, &edges),
        ctx.pick(c_int, &edges),
        ctx.pick(c_int, &edges),
    };
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a < 0) return 0;
    if (a == 0) return 1;
    return 2;
}
