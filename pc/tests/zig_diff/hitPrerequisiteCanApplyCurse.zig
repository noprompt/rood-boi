//! zig_diff spec: _hitPrerequisiteCanApplyCurse -> hit_prerequisite_can_apply_curse.hitPrerequisiteCanApplyCurse (146C.c).
//! Inputs: the action (null or an arena object, which the C never reads) and
//! arg1 (null or an arena buffer). The callee _hitPrerequisiteCanApplyEffect
//! is a recording stub that may write arg1[0] and returns 0 (about a third of
//! the calls), 0x80000000 (sign bit alone, a few calls), or any c_int, so
//! both the `== 0` result and the sign bit are seen. The stub never touches a
//! null arg1.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyCurse));

pub const classes = [_][:0]const u8{ "action-null", "action-set-arg1-null", "action-set-arg1-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (arg1 != null and ctx.value(u1) == 1) arg1[0] = ctx.value(u8);
        const k = ctx.value(u8);
        if (k < 85) return 0;
        if (k < 95) return @bitCast(@as(u32, 0x8000_0000));
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(3)) null else ctx.alloc(v.vs_action_t);
    var arg1: [*c]u8 = null;
    if (!ctx.chance(4)) arg1 = @ptrCast(ctx.allocBytes(16, 16));
    return .{ action, arg1 };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (args[1] == null) return 1;
    return 2;
}
