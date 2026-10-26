//! zig_diff spec: _hitPrerequisiteAlways1 -> hit_prerequisite_always1.hitPrerequisiteAlways1 (146C.c).
//! The C ignores both arguments and always returns 1, so there are no branches or
//! value edges to reach. The inputs still vary both arguments: arg0 is null or a
//! valid action in the arena, arg1 is null or a random arena buffer, so a port that
//! reads either one, or returns anything but 1, is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteAlways1));

pub const classes = [_][:0]const u8{ "arg0-null", "arg0-object" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(4))
        null
    else
        @ptrCast(ctx.allocBytes(16, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
