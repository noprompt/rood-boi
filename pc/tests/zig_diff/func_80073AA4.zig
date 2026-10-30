//! zig_diff spec: func_80073AA4 -> func_80073AA4.func_80073AA4 (146C.c).
//! Inputs: none. The function takes no arguments and its only branch-free body
//! stores 0xB to D_800F196C and calls func_8006C350. The global starts as random
//! bytes, and the callee may overwrite it, so a port that skips the store, drops
//! the call, or reorders them across the call is seen in the call's state hash
//! or in the final state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073AA4));

pub const classes = [_][:0]const u8{"no-args"};

pub const stubs = struct {
    /// The callee may overwrite the global the C stored before the call;
    /// the C then leaves whatever it wrote there.
    pub fn func_8006C350(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F196C().* = ctx.value(u32);
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
