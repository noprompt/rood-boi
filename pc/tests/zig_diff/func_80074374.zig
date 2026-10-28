//! zig_diff spec: func_80074374 -> func_80074374.func_80074374 (146C.c).
//! Inputs: none (the unit takes no arguments and reads no globals). The
//! scratchpad-free stubs carry the variation: func_800A1108 fills the six
//! shorts it is given with any i16 (so sp18[3] - 0x5A wraps on the store),
//! _stepTowardTarget sometimes rewrites the SVECTOR it is passed and returns
//! a value that depends on the SVECTOR's fields (so a dropped or misplaced
//! store shows in the return value), and func_8009E480 is zero, positive
//! or negative per run, which covers the `!= 0` test both ways and with
//! and without the sign bit.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074374));

/// How func_8009E480 answers this run: 0 = zero, 1 = positive nonzero,
/// 2 = negative. Set by prepare, read by the stub (same in both runs).
var status_mode: u8 = 0;

pub const classes = [_][:0]const u8{ "status-zero", "status-positive", "status-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    status_mode = ctx.range(u8, 0, 2);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return status_mode;
}

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, a: c_int, buf: ?*anyopaque) c_int {
        _ = a;
        const sp: [*]i16 = @ptrCast(@alignCast(buf.?));
        for (0..6) |i| sp[i] = ctx.value(i16);
        return ctx.value(c_int);
    }

    pub fn _stepTowardTarget(ctx: *zd.Ctx, p: anytype, a: c_int, b: c_int) c_int {
        _ = a;
        _ = b;
        const sv: *v.SVECTOR = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) {
            sv.vx = ctx.value(i16);
            sv.vy = ctx.value(i16);
            sv.vz = ctx.value(i16);
        }
        return ctx.value(c_int) +% @as(c_int, sv.vx) +% @as(c_int, sv.vy) *% 7 +% @as(c_int, sv.vz) *% 131;
    }

    pub fn func_8009E480(ctx: *zd.Ctx) c_int {
        const r = ctx.value(c_int);
        return switch (status_mode) {
            0 => 0,
            1 => (r & 0x7FFF_FFFF) | 1,
            else => r | @as(c_int, @bitCast(@as(u32, 0x8000_0000))),
        };
    }
};
