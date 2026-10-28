//! zig_diff spec: _hitPrerequisiteAlways2 -> hit_prerequisite_always2.hitPrerequisiteAlways2 (146C.c).
//! The C body is a constant: it returns 1 and never reads or writes its arguments,
//! globals or callees. The inputs still vary both pointer arguments across null and
//! valid arena or random-byte objects, so a port that tests either pointer, or returns
//! a different constant, is caught. Each of the four null combinations is a class.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteAlways2));

pub const classes = [_][:0]const u8{ "both-null", "arg0-null", "arg1-null", "both-valid" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const name: [*c]u8 = if (ctx.chance(4)) null else @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, name };
}

pub fn classify(args: Args) usize {
    const a0 = args[0] == null;
    const a1 = args[1] == null;
    if (a0 and a1) return 0;
    if (a0) return 1;
    if (a1) return 2;
    return 3;
}
