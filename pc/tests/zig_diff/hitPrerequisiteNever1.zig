//! zig_diff spec: _hitPrerequisiteNever1 -> hit_prerequisite_never1.hitPrerequisiteNever1 (146C.c).
//! The C body is `return 0;` and never reads its arguments, so there are no branches to reach.
//! The inputs still vary both pointer arguments (null or a valid object in the arena) so that a port
//! which dereferences or null-tests either one, or returns something other than 0, is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteNever1));

pub const classes = [_][:0]const u8{ "null-arg0", "null-arg1", "both-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    var action: ?*v.vs_action_t = null;
    var text: [*c]u8 = null;
    if (!ctx.chance(3)) action = ctx.alloc(v.vs_action_t);
    if (!ctx.chance(3)) text = @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, text };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (args[1] == null) return 1;
    return 2;
}
