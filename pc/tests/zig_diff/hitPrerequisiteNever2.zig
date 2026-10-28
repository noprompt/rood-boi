//! zig_diff spec: _hitPrerequisiteNever2 -> hit_prerequisite_never2.hitPrerequisiteNever2 (146C.c).
//! The C body ignores both arguments and returns 0: no branches, no callees, no globals.
//! The inputs vary whether each argument is null or points at live random bytes in the
//! arena, so a port that returns anything other than 0, or lets an argument's nullness
//! leak into the result, is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteNever2));

pub const classes = [_][:0]const u8{ "both-null", "arg1-only", "arg0-only", "both-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    var action: ?*v.vs_action_t = null;
    if (!ctx.chance(3)) action = ctx.alloc(v.vs_action_t);
    var name: [*c]u8 = null;
    if (!ctx.chance(3)) name = ctx.allocBytes(24, 1);
    return .{ action, name };
}

pub fn classify(args: Args) usize {
    return @as(usize, @intFromBool(args[0] != null)) * 2 + @intFromBool(args[1] != null);
}
