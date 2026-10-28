//! zig_diff spec: _hitPrerequisiteCanApplyStrDown -> hit_prerequisite_can_apply_str_down.hitPrerequisiteCanApplyStrDown (146C.c).
//! Inputs: arg0 is an arena vs_action_t or null (the C never reads it), and arg1 is an
//! arena buffer or null. The callee only receives arg1, so the stub never dereferences it.
//! The callee _hitPrerequisiteCanApplyEffect is a stub that returns zero, a nonzero value
//! with a zero low byte, or any int, so the `== 0` test sees zero, nonzero, negative and
//! low-byte-zero results. The stub's arguments are recorded in the call trace.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyStrDown));

pub const classes = [_][:0]const u8{ "null-arg0", "null-arg1", "valid" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        _ = arg1;
        return switch (ctx.value(u2)) {
            0 => 0,
            1 => ctx.value(c_int) & ~@as(c_int, 0xFF),
            else => ctx.value(c_int),
        };
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(5)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(6)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (args[1] == null) return 1;
    return 2;
}
