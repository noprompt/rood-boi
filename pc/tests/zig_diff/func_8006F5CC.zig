//! zig_diff spec: func_8006F5CC -> func_8006F5CC.func_8006F5CC (146C.c).
//! Inputs: the unit takes no arguments and has no branches, so the inputs vary
//! only the global state: D_800F196C and _cameraMode start as random bytes, and
//! the _setRoomSeen stub either overwrites D_800F196C (the callee writes a
//! global the C wrote before the call) or leaves the globals alone. The port
//! must store D_800F196C before the call and _cameraMode before the call's
//! state hash is taken, in the C's order.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F5CC));

pub const classes = [_][:0]const u8{ "callee-writes", "callee-keeps" };

/// Set by prepare, read by the stub and by classify (the same in both runs).
var callee_writes: bool = false;

pub fn prepare(ctx: *zd.Ctx) Args {
    callee_writes = ctx.chance(2);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (callee_writes) 0 else 1;
}

pub const stubs = struct {
    pub fn _setRoomSeen(ctx: *zd.Ctx) void {
        if (callee_writes) v.g.D_800F196C().* = ctx.value(u32);
    }
};
