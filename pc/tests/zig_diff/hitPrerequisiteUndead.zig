//! zig_diff spec: _hitPrerequisiteUndead -> hit_prerequisite_undead.hitPrerequisiteUndead (146C.c).
//! The C has no branches: it calls _getEnemyClass(arg1) and compares the result with
//! enemyClassUndead. The inputs cover arg1 as null and as an arena buffer, and arg0 as
//! null and as an arena action. The stub returns the undead class (2) in about a quarter
//! of its calls and any c_int otherwise, so the comparison is seen both equal and unequal,
//! and a result with the low byte 2 but other high bits is seen too.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteUndead));

pub const classes = [_][:0]const u8{ "arg1-null", "arg1-set" };

pub const stubs = struct {
    pub fn _getEnemyClass(ctx: *zd.Ctx, p: anytype) c_int {
        _ = p;
        if (ctx.value(u8) < 64) return 2;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(8)) null else ctx.allocBytes(32, 16);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
