//! zig_diff spec: _hitPrerequisiteCanApplyIntDown -> hit_prerequisite_can_apply_int_down.hitPrerequisiteCanApplyIntDown (146C.c).
//! Inputs: the unused arg0 is null or a vs_action_t in the arena, and arg1 is
//! null or a byte buffer in the arena (the C only forwards it to the callee).
//! The callee _hitPrerequisiteCanApplyEffect is a recording stub that returns
//! 0, -1, 1 or any c_int, so both sides of the `== 0` test are covered in
//! both directions, including negative values.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyIntDown));

pub const classes = [_][:0]const u8{ "arg0-null-arg1-null", "arg0-null-arg1-set", "arg0-set-arg1-null", "arg0-set-arg1-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        _ = arg1;
        return switch (ctx.value(u2)) {
            0 => 0,
            1 => -1,
            2 => 1,
            3 => ctx.value(c_int),
        };
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(3)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    const a: usize = if (args[0] == null) 0 else 1;
    const b: usize = if (args[1] == null) 0 else 2;
    return a + b;
}
