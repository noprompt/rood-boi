//! zig_diff spec: func_8006C350 -> func_8006C350.func_8006C350 (146C.c).
//! Inputs: the unit takes no arguments and reads no object, so the only
//! state is the random globals (D_800F1968 and the arena). Both callees are
//! recording stubs that write D_800F1968 from `ctx.value`, so the C's final
//! store and the call order are observable: a store moved across
//! func_80095B70, a dropped store, or a wrong loop bound or argument all
//! change the state or the call trace.

const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C350));

pub const classes = [_][:0]const u8{"run"};

pub const stubs = struct {
    pub fn func_8009E5C4(ctx: *zd.Ctx, i: anytype) void {
        _ = i;
        v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_80095B70(ctx: *zd.Ctx, i: anytype) void {
        _ = i;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
