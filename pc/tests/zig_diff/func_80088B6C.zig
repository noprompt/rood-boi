//! zig_diff spec: func_80088B6C -> func_80088B6C.func_80088B6C (146C.c).
//! The C body only forwards to func_80088554 and returns its result, so the
//! arguments are the empty tuple and the C reads and writes no state of its
//! own. What varies is the callee's result. prepare picks an input class per
//! iteration and stores it in `chosen`, a spec variable that both runs read
//! unchanged. The stub returns 0, -1, INT_MIN, INT_MAX, or a value from
//! ctx.value, as the class says. A port that drops the call, adds to, negates,
//! or masks the result, or that returns a constant, is caught by the
//! return-value and call-trace comparison.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80088B6C));

pub const classes = [_][:0]const u8{ "zero", "minus-one", "int-min", "int-max", "other" };

/// The class prepare chose for this iteration (read by the stub and classify).
var chosen: usize = 0;

pub const stubs = struct {
    pub fn func_80088554(ctx: *zd.Ctx) c_int {
        return switch (chosen) {
            0 => 0,
            1 => -1,
            2 => std.math.minInt(c_int),
            3 => std.math.maxInt(c_int),
            else => ctx.value(c_int),
        };
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    chosen = ctx.range(usize, 0, 4);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return chosen;
}
