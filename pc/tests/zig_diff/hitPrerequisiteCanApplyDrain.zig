//! zig_diff spec: _hitPrerequisiteCanApplyDrain -> hit_prerequisite_can_apply_drain.hitPrerequisiteCanApplyDrain (146C.c).
//! Inputs: the effect check's result (zero or not, with negative and sign-bit
//! values) and the enemy class (undead 2, its neighbours 3, 1, 0, -1, the
//! minimum), set by prepare and returned by the two recording stubs. The
//! action pointer is null or an arena object (the C never reads it), and
//! arg1 is null or an arena buffer the effect stub writes into (the C never
//! reads it back). Classes split the three paths: the effect is nonzero
//! (the class is never fetched), the effect is zero and the class is undead,
//! and the effect is zero and the class is anything else.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyDrain));

pub const classes = [_][:0]const u8{ "effect-nonzero", "effect-zero-undead", "effect-zero-drainable" };

var effect_result: c_int = 0;
var class_result: c_int = 0;

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        const p: [*c]u8 = arg1;
        if (p != null) p[0] = ctx.value(u8);
        return effect_result;
    }

    pub fn _getEnemyClass(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = ctx;
        _ = arg;
        return class_result;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    effect_result = if (ctx.chance(2))
        0
    else
        ctx.pick(c_int, &.{ 1, -1, std.math.minInt(c_int), 0x40000000, 2 });
    class_result = if (ctx.chance(2))
        2
    else
        ctx.pick(c_int, &.{ 0, 1, 3, -1, -2, std.math.minInt(c_int) });
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(8)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    _ = args;
    if (effect_result != 0) return 0;
    return if (class_result == 2) 1 else 2;
}
