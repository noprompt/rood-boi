//! zig_diff spec: _hitPrerequisiteCanApplyIntUp -> hit_prerequisite_can_apply_int_up.hitPrerequisiteCanApplyIntUp (146C.c).
//! Inputs: arg0 is an arena action or null (the C never reads it); arg1 is an
//! arena byte buffer or null (the C only passes it on). The callee
//! _hitPrerequisiteCanApplyEffect is a recording stub that returns 0, -1,
//! 0x100 (nonzero with the low byte zero and the sign bit clear) or any
//! c_int, so the `== 0` test sees zero and nonzero results with and without
//! the sign bit, and a narrowed result differs from the wide one.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyIntUp));

pub const classes = [_][:0]const u8{ "arg1-null", "arg1-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        _ = arg1;
        switch (ctx.value(u8) % 4) {
            0 => return 0,
            1 => return -1,
            2 => return 0x100,
            else => return ctx.value(c_int),
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(3)) null else ctx.allocBytes(8, 1);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
