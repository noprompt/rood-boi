//! zig_diff spec: func_8007CC8C -> func_8007CC8C.func_8007CC8C (146C.c).
//! The C body is a single call to func_8009CFA0 with no branches and no
//! arguments, so the inputs are the empty argument tuple and the whole
//! random state. The callee's return value is an int the C discards; its
//! stub returns `ctx.value(c_int)`, which both runs draw identically. Every
//! iteration makes the same one call, and the harness compares the call
//! trace, the return value and all state bytes (including the scratchpad),
//! so dropped, doubled or misplaced calls and stray stores are caught.

const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CC8C));

pub const classes = [_][:0]const u8{"call"};

pub const stubs = struct {
    pub fn func_8009CFA0(ctx: *zd.Ctx) c_int {
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
