//! zig_diff spec: func_800CF920 -> func_800CF920.func_800CF920 (5BF94.c).
//! The C body is one store: D_800F522C = 0. The function takes no arguments
//! and returns nothing. prepare sets the global to zero about half the time
//! and to a random byte otherwise, so both classes ("already-zero" and
//! "nonzero-before") occur. The store's effect is visible in the compared
//! state, so a port that drops it, stores another value, or touches other
//! bytes disagrees.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_800CF920));

pub const classes = [_][:0]const u8{ "already-zero", "nonzero-before" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const flag = v.g.D_800F522C();
    if (ctx.chance(2)) {
        flag.* = 0;
    } else {
        flag.* = ctx.pick(u8, &.{ 1, 0x7F, 0x80, 0xFF });
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F522C().* == 0) 0 else 1;
}
