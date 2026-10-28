//! zig_diff spec: _hitPrerequisiteCanApplyPoison -> hit_prerequisite_can_apply_poison.hitPrerequisiteCanApplyPoison (146C.c).
//! Inputs: the action pointer (null or an arena object, which the C ignores)
//! and the byte pointer (null or an arena buffer). The callee
//! _hitPrerequisiteCanApplyEffect is a recording stub that returns 0 about a
//! quarter of the time and any c_int otherwise (so negative results occur),
//! and that may overwrite the first byte of arg1, which the real callee can
//! do. The C's result is `== 0` of that return value, so both outcomes and
//! the sign-bit cases are exercised.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyPoison));

pub const classes = [_][:0]const u8{ "action-null-buf-null", "action-null", "buf-null", "both-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        // The real callee may write the byte it is given.
        if (arg1) |p| {
            if (ctx.value(u2) == 0) p[0] = ctx.value(u8);
        }
        // Return 0 about a quarter of the time (the C tests this for equality
        // with 0), otherwise any value, sign bit included.
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(3)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(5)) null else ctx.allocBytes(16, 16);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    const a_null = args[0] == null;
    const b_null = args[1] == null;
    if (a_null and b_null) return 0;
    if (a_null) return 1;
    if (b_null) return 2;
    return 3;
}
