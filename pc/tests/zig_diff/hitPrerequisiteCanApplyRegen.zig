//! zig_diff spec: _hitPrerequisiteCanApplyRegen -> hit_prerequisite_can_apply_regen.hitPrerequisiteCanApplyRegen (146C.c).
//! Inputs: an action that is null or a fresh arena object (the C never reads it), and a
//! byte buffer that is null or valid (the C passes it on unread). The callee stub returns
//! 0 a quarter of the time and otherwise any c_int, so the `== 0` test sees zero, negative
//! and positive values. The stub also writes the buffer, as the real callee may.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyRegen));

pub const classes = [_][:0]const u8{ "null-buf", "buf" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (arg1 != null) arg1[0] = ctx.value(u8);
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(4)) null else ctx.allocBytes(8, 1);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
