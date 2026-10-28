//! zig_diff spec: func_8007BF0C -> func_8007BF0C.func_8007BF0C (146C.c).
//! Inputs: no arguments. The one callee, func_800CEEBC, returns a value the C
//! tests against zero. prepare picks that return from the edges that matter:
//! 0, 1, other positive, negative (sign bit set), INT_MIN and INT_MAX. The
//! stub returns the picked value, and classify names the case, so every
//! class is counted and every branch of the C is reached.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BF0C));

pub const classes = [_][:0]const u8{ "zero", "one", "positive", "negative", "int-min" };

/// The value func_800CEEBC returns this iteration, chosen in prepare.
var ret: c_int = 0;

pub const stubs = struct {
    pub fn func_800CEEBC(ctx: *zd.Ctx) c_int {
        _ = ctx;
        return ret;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    ret = ctx.pick(c_int, &.{ 0, 1, -1, 2, 0x100, 0x10000, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (ret == 0) return 0;
    if (ret == 1) return 1;
    if (ret == std.math.minInt(c_int)) return 4;
    if (ret < 0) return 3;
    return 2;
}
