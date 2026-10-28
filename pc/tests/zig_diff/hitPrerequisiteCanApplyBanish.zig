//! zig_diff spec: _hitPrerequisiteCanApplyBanish -> hit_prerequisite_can_apply_banish.hitPrerequisiteCanApplyBanish (146C.c).
//! Inputs: the action pointer (null or an arena object, which the C ignores) and
//! arg1 (null or an arena block, passed through unread). The callee
//! _hitPrerequisiteCanApplyEffect is a recording stub that returns 0, 1, -1,
//! 256 or any 32-bit value, so the `== 0` test sees zero, nonzero values with
//! and without the sign bit, and values whose low byte is zero. Its arguments
//! are recorded, so the constant 29 and the pass-through of arg1 are checked.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyBanish));

pub const classes = [_][:0]const u8{ "arg1-null", "arg1-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        _ = arg1;
        return switch (ctx.value(u8)) {
            0...99 => 0,
            100...139 => 1,
            140...179 => -1,
            180...219 => 256,
            else => ctx.value(c_int),
        };
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const arg1: [*c]u8 = if (ctx.chance(4)) null else @ptrCast(ctx.allocBytes(16, 16));
    return .{ action, arg1 };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
