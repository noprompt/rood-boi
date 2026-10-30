//! zig_diff spec: _hitPrerequisiteCanApplySilence -> hit_prerequisite_can_apply_silence.hitPrerequisiteCanApplySilence (146C.c).
//! The C forwards arg1 to _hitPrerequisiteCanApplyEffect(12, arg1) and returns whether that result is 0.
//! Inputs: an action that is null or an arena object (the C never reads it), arg1 null or an arena
//! buffer (the callee may write it, so the stub does). The callee stub returns each result class
//! chosen in prepare: 0, a positive value, a negative value, and any 32-bit value. Each class
//! is a separate input class, so the sign bit and the zero test are both exercised.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplySilence));

pub const classes = [_][:0]const u8{ "result-zero", "result-positive", "result-negative", "result-any" };

/// The callee result class prepare chose for this iteration (0..3). Set once per
/// iteration, so the C run and the Zig run see the same stub behaviour.
var result_mode: u8 = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const arg1: [*c]u8 = if (ctx.chance(6)) null else ctx.allocBytes(16, 16);
    result_mode = ctx.range(u8, 0, 3);
    return .{ action, arg1 };
}

pub fn classify(args: Args) usize {
    _ = args;
    return result_mode;
}

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, id: anytype, p: anytype) c_int {
        _ = id;
        // The callee may write its buffer argument: it is a real output the C never reads back.
        const b: [*c]u8 = p;
        if (b != null and ctx.value(u1) == 1) b[0] = ctx.value(u8);
        return switch (result_mode) {
            0 => 0,
            1 => @as(c_int, @intCast(ctx.value(u30))) + 1,
            2 => -(@as(c_int, @intCast(ctx.value(u30))) + 1),
            else => ctx.value(c_int),
        };
    }
};
