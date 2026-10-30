//! zig_diff spec: func_800CB1C0 -> func_800CB1C0.func_800CB1C0 (5BF94.c).
//! Inputs: an arg0 that is negative or not, with the edges where arg0 + 0x40
//! wraps the u8 store (0, -64, 191, 192, 255, the top of the int range below
//! the overflow line). The callee func_800CACD0 is a recording stub that
//! sometimes rewrites D_800F4EA0 and D_800F4E6B, so the port must reread both
//! after the call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB1C0));

pub const classes = [_][:0]const u8{ "negative", "nonnegative" };

pub const stubs = struct {
    pub fn func_800CACD0(ctx: *zd.Ctx, menuState: anytype, arg1: anytype) c_int {
        _ = menuState;
        _ = arg1;
        if (ctx.value(u1) == 1) v.g.D_800F4EA0().* = ctx.value(i32);
        if (ctx.value(u1) == 1) v.g.D_800F4E6B().* = ctx.value(u8);
        return ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Keep arg0 + 0x40 inside int (the C would overflow past INT_MAX).
    var a: i32 = ctx.int(i32);
    if (a > 0x7FFF_FFBF) a -= 0x40;
    if (ctx.chance(4)) {
        a = ctx.edge(i32, &.{ 0, -64, -65, 191, 192, 255, 0x7FFF_FFBF, -2147483648, -1, 1 });
    }
    return .{a};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
