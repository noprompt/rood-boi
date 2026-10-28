//! zig_diff spec: func_8007BF4C -> func_8007BF4C.func_8007BF4C (146C.c).
//! Inputs: none. The function takes no arguments and reads no globals, so
//! the only thing it does is call func_8008ABB8(0) and discard the result.
//! The callee is a recording stub that returns any int; the C ignores that
//! value, so the port is checked on the call itself: its argument, its
//! count and its order relative to the other calls.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BF4C));

pub const classes = [_][:0]const u8{"call"};

pub const stubs = struct {
    pub fn func_8008ABB8(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
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
