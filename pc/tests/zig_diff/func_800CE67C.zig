//! zig_diff spec: func_800CE67C -> func_800CE67C.func_800CE67C (5BF94.c).
//! Inputs: the function takes no arguments and reads no pointers, so the
//! harness's random arena and globals are the whole input. Every run calls
//! func_800CF478(0) and then zeroes the globals listed in the C, with the loop
//! over D_800F5320 covering all four entries. The one callee, func_800CF478,
//! is a recording stub that changes D_800F5330[1], the one touched entry the
//! C does not overwrite, so a port that reads it back still gets the same
//! result. Its return type is void. The loop's `i < 4` compares equal at its
//! exit on every run, so the value-edge rule holds without any extra setup.
//! There is a single input class, since the function has no branch of its own.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CE67C));

pub const classes = [_][:0]const u8{"always"};

pub const stubs = struct {
    pub fn func_800CF478(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        v.g.D_800F5330()[1] = ctx.value(i32);
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
