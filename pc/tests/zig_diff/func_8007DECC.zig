//! zig_diff spec: func_8007DECC -> func_8007DECC.func_8007DECC (146C.c).
//! The C copies the 16-byte global D_800F1A68 over *arg0. It has no branches,
//! calls or comparisons, so the inputs vary only the destination: an arena
//! object (random bytes, different from the global) or the global itself
//! (the copy aliases its source). Every word of the copy must differ between
//! the two sides to be caught, which random fills ensure.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DECC));

pub const classes = [_][:0]const u8{ "arena-object", "aliases-global" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) return .{v.g.D_800F1A68()};
    return .{ctx.alloc(v.D_800F1A68_t)};
}

pub fn classify(args: Args) usize {
    return if (args[0].? == v.g.D_800F1A68()) 1 else 0;
}
