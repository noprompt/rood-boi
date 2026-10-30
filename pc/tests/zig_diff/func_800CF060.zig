//! zig_diff spec: func_800CF060 -> func_800CF060.func_800CF060 (5BF94.c).
//! Inputs: no arguments. The C toggles D_800EC2E4, calls four callees and
//! ORs the two results, and calls func_800D2560 only when D_800F531C == 4.
//! prepare sets D_800F531C to 4 half the time (otherwise to values near it
//! and to extremes). The callees' stubs can rewrite D_800F531C after the
//! calls, one time in eight with the value 4, so the C's read after the
//! calls is covered. Their return values are random 32-bit values, so the
//! OR sees overlapping bits.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF060));

pub const classes = [_][:0]const u8{ "hook-taken", "hook-skipped" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F531C().* = if (ctx.chance(2)) 4 else ctx.pick(u32, &.{ 0, 3, 5, 0xFFFF_FFFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F531C().* == 4) 0 else 1;
}

pub const stubs = struct {
    pub fn func_800CE9B0(ctx: *zd.Ctx) c_int {
        if (ctx.value(u3) == 0) {
            v.g.D_800F531C().* = 4;
        }
        return ctx.value(c_int);
    }

    pub fn func_800CED60(ctx: *zd.Ctx) c_int {
        if (ctx.value(u3) == 0) {
            v.g.D_800F531C().* = 4;
        }
        return ctx.value(c_int);
    }

    pub fn func_800D7890(ctx: *zd.Ctx, on: anytype) void {
        _ = on;
        if (ctx.value(u3) == 0) {
            v.g.D_800F531C().* = 4;
        } else if (ctx.value(u2) == 0) {
            v.g.D_800F531C().* = ctx.value(u32);
        }
    }

    pub fn func_800D2560(ctx: *zd.Ctx) void {
        _ = ctx;
    }
};
