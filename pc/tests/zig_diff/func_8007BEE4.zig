//! zig_diff spec: func_8007BEE4 -> func_8007BEE4.func_8007BEE4 (146C.c).
//! The unit is a single tail call: `return func_800CF48C();`. There are no
//! branches and no arguments, so the inputs are the random scratchpad and
//! globals the stub's draw is independent of. The one callee returns any
//! c_int from ctx.value, so the port must return all 32 bits unchanged and
//! call it exactly once, with no argument to pass. Every run is the same
//! class; the mutations (a wrong constant, a narrowed return, an unsigned
//! narrowing, a duplicated call, a dropped call) are what the comparison must catch.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BEE4));

pub const classes = [_][:0]const u8{"call-returns"};

pub const stubs = struct {
    /// The callee's return value: any c_int (negative, zero, high bits set).
    pub fn func_800CF48C(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
