//! zig_diff spec: _hitPrerequisiteCanApplyNumbness -> hit_prerequisite_can_apply_numbness.hitPrerequisiteCanApplyNumbness (146C.c).
//! Inputs: an optional action (unused by the C) and an optional byte buffer
//! passed through to _hitPrerequisiteCanApplyEffect(15, arg1). The callee is a
//! recording stub that returns 0 about a quarter of the time (so the `== 0`
//! test sees both outcomes, with and without the sign bit), and otherwise any
//! 32-bit value. It also writes a random byte into arg1 when arg1 is non-null,
//! so a port that reads the buffer before the call still differs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyNumbness));

pub const classes = [_][:0]const u8{ "action-null", "arg-null", "both-set" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        const p: [*c]u8 = arg1;
        if (p != null) p[0] = ctx.value(u8);
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(3)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(8)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (args[1] == null) return 1;
    return 2;
}
