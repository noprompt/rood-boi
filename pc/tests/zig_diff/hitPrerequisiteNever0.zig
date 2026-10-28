//! zig_diff spec: _hitPrerequisiteNever0 -> hit_prerequisite_never0.hitPrerequisiteNever0 (146C.c).
//! The C body returns 0 and touches neither argument. The inputs cover a null
//! and a valid `vs_action_t` in arg0 (with its `id` sometimes 0xFF, so a port
//! that reads the object and branches on it is caught), and an arena buffer in
//! arg1 that a port writing through it would change. Every iteration is
//! crash-free: arg1 is always valid and arg0 is only dereferenced when non-null.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteNever0));

pub const classes = [_][:0]const u8{ "arg0-null", "arg0-id-ff", "arg0-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    action.id = ctx.pick(u8, &.{ 0, 0xFF, 1 });
    const buf: [*c]u8 = ctx.allocBytes(16, 1);
    const a: ?*v.vs_action_t = if (ctx.chance(3)) null else action;
    return .{ a, buf };
}

pub fn classify(args: Args) usize {
    const a = args[0] orelse return 0;
    return if (a.id == 0xFF) 1 else 2;
}
