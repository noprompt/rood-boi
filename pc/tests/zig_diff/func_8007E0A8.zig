//! zig_diff spec: func_8007E0A8 -> func_8007E0A8.func_8007E0A8 (146C.c).
//! Inputs: arg0 at the 25 bound and the sum at the 33 bound (both sides equal
//! on purpose), arg1 small with 0 included and the sum sometimes exactly 33,
//! arg2 inside and outside the byte range. The 32-byte table D_800F19A8 is
//! filled with arg2 in some runs, so every element matches and the store loop
//! runs, and is random otherwise, so the mismatch call runs. Inputs whose sum
//! would wrap into the window are avoided: the C would index D far outside its
//! table there. The only zero test is on var_s0, which is 0 or 1 by construction.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007E0A8));

pub const classes = [_][:0]const u8{ "outside", "mismatch", "all-match-store", "empty-match" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_uint = switch (ctx.range(u8, 0, 7)) {
        0 => ctx.edge(c_uint, &.{ 24, 25, 26, 31, 32, 33 }),
        1 => ctx.edge(c_uint, &.{ 0, 1, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF }),
        else => ctx.range(c_uint, 0, 40),
    };
    var arg1: c_uint = if (ctx.chance(2)) ctx.range(c_uint, 0, 10) else ctx.int(c_uint);
    if (arg0 >= 25 and arg0 <= 33 and ctx.chance(4)) arg1 = 33 - arg0;
    // A sum that wraps into the window would enter the branch and index D out of range.
    if (arg0 >= 25 and @as(u64, arg0) + arg1 > 0xFFFF_FFFF and arg0 +% arg1 < 33) arg1 = 0;

    const arg2: c_int = if (ctx.chance(2))
        ctx.range(c_int, 0, 255)
    else
        ctx.pick(c_int, &.{ -3, -1, 0, 256, std.math.maxInt(c_int), std.math.minInt(c_int) });

    if (arg0 >= 25 and @as(u64, arg0) + arg1 < 33 and arg2 >= 0 and arg2 <= 255 and ctx.chance(2)) {
        const d = v.g.D_800F19A8();
        var i: usize = 0;
        while (i < arg1) : (i += 1) d[arg0 + i] = @intCast(arg2);
    }

    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    const arg0: c_uint = args[0];
    const arg1: c_uint = args[1];
    const arg2: c_int = args[2];
    if (!(arg0 >= 25 and @as(u64, arg0) + arg1 < 33)) return 0;
    if (arg1 == 0) return 3;
    const d = v.g.D_800F19A8();
    var i: usize = 0;
    while (i < arg1) : (i += 1) {
        if (@as(c_int, d[arg0 + i]) != arg2) return 1;
    }
    return 2;
}
