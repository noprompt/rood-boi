//! zig_diff spec: func_8007B3F0 -> func_8007B3F0.func_8007B3F0 (146C.c).
//! Inputs: an arg0 over the int edges (0, 1, -1, 255, 256, INT_MAX, INT_MIN)
//! and an arg1 that is null about one time in four or a fresh arena object
//! with random bytes. The C only forwards its arguments to func_800472D0, so
//! the callee stub is what matters: it writes all four bytes of a non-null
//! object with ctx.value (the callee can change them, and the port must not
//! read them before the call), and it ignores a null object.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B3F0));

pub const classes = [_][:0]const u8{ "null-object", "object" };

pub const stubs = struct {
    pub fn func_800472D0(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
        _ = arg0;
        const d: ?*v.D_8005DC6C_t = @ptrCast(@alignCast(arg1));
        if (d) |o| {
            o.r = ctx.value(u8);
            o.g = ctx.value(u8);
            o.b = ctx.value(u8);
            o.unk3 = ctx.value(u8);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_8005DC6C_t);
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ arg0, if (ctx.chance(4)) null else obj };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
