//! zig_diff spec: _hitPrerequisiteCanApplyQuicken -> hit_prerequisite_can_apply_quicken.hitPrerequisiteCanApplyQuicken (146C.c).
//! Inputs: an action pointer (null or an arena object, which the C never reads)
//! and a char pointer (null or an arena block). The callee
//! _hitPrerequisiteCanApplyEffect is a recording stub whose result cycles
//! through 0, -1, 1, INT_MIN and a random value, so the `== 0` test sees
//! zero, nonzero values with the sign bit set and without it, and the extremes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyQuicken));

pub const classes = [_][:0]const u8{ "arg1-null", "arg1-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, id: anytype, p: anytype) c_int {
        _ = id;
        _ = p;
        return switch (ctx.value(u8) % 5) {
            0 => 0,
            1 => -1,
            2 => 1,
            3 => std.math.minInt(c_int),
            else => ctx.value(c_int),
        };
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const arg1: [*c]u8 = if (ctx.chance(4)) null else @ptrCast(ctx.allocBytes(8, 1));
    return .{ action, arg1 };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
