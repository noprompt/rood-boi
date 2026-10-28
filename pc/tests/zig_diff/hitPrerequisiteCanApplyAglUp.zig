//! zig_diff spec: _hitPrerequisiteCanApplyAglUp -> hit_prerequisite_can_apply_agl_up.hitPrerequisiteCanApplyAglUp (146C.c).
//! Inputs: an action pointer (null or an arena object, which the C never
//! reads) and a byte buffer (null or an arena block). The callee
//! _hitPrerequisiteCanApplyEffect is a recording stub that writes the buffer
//! when it is non-null and returns 0, -1, 256 (zero low byte, nonzero) or any
//! int, so the `== 0` test sees zero, negative, and nonzero values with and
//! without a zero low byte.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyAglUp));

pub const classes = [_][:0]const u8{ "arg1-null", "arg1-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (arg1 != null) arg1[0] = ctx.value(u8);
        const r = ctx.value(u8);
        if (r < 64) return 0;
        if (r < 96) return -1;
        if (r < 128) return 256;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(8)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(8)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
