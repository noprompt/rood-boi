//! zig_diff spec: func_8006C40C -> func_8006C40C.func_8006C40C (146C.c).
//! The C is straight-line code: no branches and no comparisons, so there is
//! nothing to steer. Each iteration starts from random bytes in the arena,
//! the scratchpad and the globals, and the single class is always taken. The
//! callees are stubs that sometimes overwrite D_800F1968 with a random i32,
//! so a port that stores before the calls, or leaves the store out, shows up
//! in the state hashed at each call and in the final state. The stubs for
//! func_8007B1B8 and func_80095B70 model that write; the others only return
//! values the C discards.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C40C));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}

pub const stubs = struct {
    pub fn func_8007B1B8(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype, e: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        _ = e;
        if (ctx.value(u2) == 0) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_80095B70(ctx: *zd.Ctx, a: anytype) void {
        _ = a;
        if (ctx.value(u2) == 0) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_8008B4C8(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return ctx.value(c_int);
    }
};
