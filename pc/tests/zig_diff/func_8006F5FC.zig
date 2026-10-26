//! zig_diff spec: func_8006F5FC -> func_8006F5FC.func_8006F5FC (146C.c).
//! Inputs: none. The C has no branches and no arguments; it stores 12 to
//! D_800F196C, stores 0 to _cameraMode, then calls func_8009E5C4(0). The
//! globals start as random bytes, so both stores are observable. The callee
//! is a recording stub that writes both globals with ctx.value, so a port
//! that reads them after the call, or moves a store across the call, differs
//! in the call trace or the final state.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F5FC));

pub const classes = [_][:0]const u8{"always"};

pub const stubs = struct {
    pub fn func_8009E5C4(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        psx.global(u32, "D_800F196C").* = ctx.value(u32);
        psx.global(u32, "_cameraMode").* = ctx.value(u32);
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
