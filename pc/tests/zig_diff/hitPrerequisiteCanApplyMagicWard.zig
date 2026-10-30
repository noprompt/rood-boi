//! zig_diff spec: _hitPrerequisiteCanApplyMagicWard -> hit_prerequisite_can_apply_magic_ward.hitPrerequisiteCanApplyMagicWard (146C.c).
//! Inputs: the action is null or a valid arena object (the C never reads it), and arg1 is
//! null or a random 16-byte arena buffer. The callee stub returns 0 in about a quarter of
//! its calls and any other int (negative included) otherwise, and it may write arg1[0] when
//! arg1 is non-null. The four classes are the null/non-null combinations of action and arg1.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyMagicWard));

pub const classes = [_][:0]const u8{
    "action-null-arg1-null",
    "action-null-arg1-set",
    "action-set-arg1-null",
    "action-set-arg1-set",
};

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: c_int, arg1: [*c]u8) c_int {
        _ = arg0;
        if (arg1 != null and ctx.value(u1) == 1) arg1[0] = ctx.value(u8);
        if (ctx.value(u8) < 64) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(2)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    const a: usize = if (args[0] == null) 0 else 2;
    const b: usize = if (args[1] == null) 0 else 1;
    return a + b;
}
