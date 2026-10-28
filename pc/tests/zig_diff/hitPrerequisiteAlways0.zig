//! zig_diff spec: _hitPrerequisiteAlways0 -> hit_prerequisite_always0.hitPrerequisiteAlways0 (146C.c).
//! The C body is a constant `return 1;` and never reads either argument, so the
//! inputs cover the argument shapes a caller can pass: arg0 is null or a
//! valid arena action, and arg1 is a valid byte buffer. Both runs must return
//! 1 and touch nothing, whatever the arguments are.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteAlways0));

pub const classes = [_][:0]const u8{ "null-action", "action" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = ctx.allocBytes(16, 1);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
