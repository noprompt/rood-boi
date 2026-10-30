//! zig_diff spec: func_8007350C -> func_8007350C.func_8007350C (146C.c).
//! The C body is one call to func_8006F5CC with no arguments and no branches,
//! so there are no branch or value edges to reach. Inputs are the empty
//! argument list. The callee is a recording stub that writes a random word
//! into the scratchpad, standing in for the side effects the real callee may
//! have. That word is compared at the call and at the return, so a port that
//! stores around the call, or calls twice or not at all, is caught.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007350C));

pub const classes = [_][:0]const u8{"call"};

pub const stubs = struct {
    /// The callee's unknown effect: it leaves a random word in the scratchpad
    /// (the harness compares the scratchpad, so a store the port makes around
    /// the call must not survive it).
    pub fn func_8006F5CC(ctx: *zd.Ctx) void {
        const word: *align(1) u32 = @ptrFromInt(zd.scratchpad + 0x40);
        word.* = ctx.value(u32);
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
