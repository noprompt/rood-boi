//! zig_diff spec: _hitPrerequisiteNever3 -> hit_prerequisite_never3.hitPrerequisiteNever3 (146C.c).
//! The C body is a constant `return 0;` that ignores both arguments, so there
//! are no branches and no callees. The inputs vary only the two pointers:
//! arg0 is a valid arena vs_action_t or null, and arg1 is a valid arena
//! buffer or null, in every combination. The return value must match in all
//! of them, and the mutations return values that depend on the arguments.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteNever3));

pub const classes = [_][:0]const u8{ "arg0-null-arg1-null", "arg0-null-arg1-set", "arg0-set-arg1-null", "both-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    var actor: ?*v.vs_action_t = null;
    if (!ctx.chance(4)) actor = ctx.alloc(v.vs_action_t);
    var buf: [*c]u8 = null;
    if (!ctx.chance(3)) buf = ctx.allocBytes(8, 1);
    return .{ actor, buf };
}

pub fn classify(args: Args) usize {
    return @as(usize, @intFromBool(args[0] != null)) * 2 + @intFromBool(args[1] != null);
}
