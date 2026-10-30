//! zig_diff spec: func_800CEF0C -> func_800CEF0C.func_800CEF0C (5BF94.c).
//! Inputs: the two globals the C reads. D_800F531C is a u32 tested as
//! `(x - 4) < 2` unsigned, which holds only for 4 and 5. Prepare draws it
//! from the edges around that window (0..8, and the wrapping 0xFFFFFFFB and
//! 0xFFFFFFFC) and sets it to 6 one time in three, so the comparison's two
//! sides are equal often. D_800F5224 is the i32 the C returns when the test
//! holds, drawn from zero, the signs and the i32 extremes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CEF0C));

pub const classes = [_][:0]const u8{ "below-window", "window-4-5", "equal-six", "above-window" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const x = v.g.D_800F531C();
    x.* = if (ctx.chance(3)) 6 else ctx.pick(u32, &.{ 0, 1, 2, 3, 4, 5, 7, 8, 0xFFFF_FFFB, 0xFFFF_FFFC, 0xFFFF_FFFF });
    v.g.D_800F5224().* = ctx.pick(i32, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0x1234 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F531C().*;
    if (x < 4) return 0;
    if (x < 6) return 1;
    if (x == 6) return 2;
    return 3;
}
