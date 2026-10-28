//! zig_diff spec: _hitPrerequisiteCanApplyAglDown -> hit_prerequisite_can_apply_agl_down.hitPrerequisiteCanApplyAglDown (146C.c).
//! The unit is one call: `_hitPrerequisiteCanApplyEffect(9, arg1) == 0`. The inputs
//! vary arg0 (null or an arena action) and arg1 (null or an arena buffer). The
//! callee stub writes into arg1 when it is set and returns zero, -1, or any
//! c_int, so the `== 0` result and the callee's trace both get checked.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyAglDown));

pub const classes = [_][:0]const u8{ "buf-null", "buf-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        const p: [*c]u8 = arg1;
        if (p != null) p[0] = ctx.value(u8);
        if (ctx.value(u2) == 0) return 0;
        if (ctx.value(u3) == 0) return -1;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(4)) null else ctx.allocBytes(ctx.range(usize, 1, 16), 1);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
