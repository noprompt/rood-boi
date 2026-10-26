//! zig_diff spec: func_80077EC4 -> func_80077EC4.func_80077EC4 (146C.c).
//! The C has no branches and no value tests. It calls the camera setup with
//! the addresses of the scratchpad camera's position and lookAt, then stores
//! farClip and the three angles. The inputs are the random arena and global
//! state, with no arguments. The callee is a recording stub that writes
//! random values into position and lookAt, as the real setup does, so a port
//! that reads them back before the call would differ.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80077EC4));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}

pub const stubs = struct {
    pub fn vs_battle_initialiseCameraFromSpherical(ctx: *zd.Ctx, position: anytype, look_at: anytype, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        const pos: *v.VECTOR = @ptrCast(@alignCast(position));
        const look: *v.VECTOR = @ptrCast(@alignCast(look_at));
        pos.vx = ctx.value(i32);
        pos.vy = ctx.value(i32);
        pos.vz = ctx.value(i32);
        look.vx = ctx.value(i32);
        look.vy = ctx.value(i32);
        look.vz = ctx.value(i32);
    }
};
