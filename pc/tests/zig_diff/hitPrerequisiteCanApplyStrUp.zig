//! zig_diff spec: _hitPrerequisiteCanApplyStrUp -> hit_prerequisite_can_apply_str_up.hitPrerequisiteCanApplyStrUp (146C.c).
//! The C has no branches of its own: it calls _hitPrerequisiteCanApplyEffect(6, arg1) and
//! returns whether the result is 0. Inputs: arg0 (the action) null or an arena object, arg1
//! (the name buffer) null or an arena buffer; the callee is a recording stub that returns 0
//! a quarter of the time and any 32-bit value (negatives included) otherwise, so both sides
//! of `== 0` and the `<= 0` / `!= 0` variants are told apart. The stub never reads arg1.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyStrUp));

pub const classes = [_][:0]const u8{ "arg0-null", "arg1-null", "both-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        _ = arg1;
        if (ctx.value(u2) == 0) return 0; // the C's `== 0` true branch
        return ctx.value(c_int); // any value, negatives included
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(6)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(6)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    if (args[1] == null) return 1;
    if (args[0] == null) return 0;
    return 2;
}
