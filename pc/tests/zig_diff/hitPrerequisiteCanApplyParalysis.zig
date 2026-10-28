//! zig_diff spec: _hitPrerequisiteCanApplyParalysis -> hit_prerequisite_can_apply_paralysis.hitPrerequisiteCanApplyParalysis (146C.c).
//! Inputs: an action pointer that is null or an arena object (the C never
//! reads it) and a byte pointer that is null or an arena buffer (passed
//! through to the callee). The callee `_hitPrerequisiteCanApplyEffect` is a
//! recording stub that returns zero a quarter of the time and otherwise any
//! 32-bit value, so the `== 0` test sees zero and nonzero results, with and
//! without the sign bit.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyParalysis));

pub const classes = [_][:0]const u8{ "arg1-null", "arg1-nonnull" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        _ = arg1;
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(4)) null else ctx.allocBytes(16, 1);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
