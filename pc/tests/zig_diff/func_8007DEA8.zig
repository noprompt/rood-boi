//! zig_diff spec: func_8007DEA8 -> func_8007DEA8.func_8007DEA8 (146C.c).
//! Inputs: a P_CODE object in the arena with random bytes, or the global
//! D_800F1A78 itself (the copy is then a self-assignment). The C has no
//! branches and calls nothing, so the copy of a random 4-byte struct into
//! the argument is what the harness compares.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DEA8));

pub const classes = [_][:0]const u8{ "arena", "aliased-global" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(8)) return .{v.g.D_800F1A78()};
    return .{ctx.alloc(v.P_CODE)};
}

pub fn classify(args: Args) usize {
    return if (args[0].? == v.g.D_800F1A78()) 1 else 0;
}
