//! zig_diff spec: func_8008F234 -> func_8008F234.func_8008F234 (146C.c).
//! Inputs: the owned pointer D_800F1DCC is null or a fresh arena block; the
//! scratch byte D_800F1DC8 and the i16 D_800F1DBE are random, with D_800F1DBE
//! biased to its sign edges (-1, -32768, 0, 32767) so the sign-extended
//! argument is checked. The callee func_8007E0A8 may replace D_800F1DCC
//! (null or a new block) and D_800F1DC9, so a port that caches the pointer
//! before the call differs. vs_main_freeHeapR is a recording stub.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008F234));

pub const classes = [_][:0]const u8{ "owned-null", "owned-freed" };

pub const stubs = struct {
    pub fn func_8007E0A8(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        if (ctx.value(u2) == 0) v.g.D_800F1DCC().* = null;
        if (ctx.value(u2) == 1) v.g.D_800F1DCC().* = ctx.alloc(v.vs_battle_backgroundLayout);
        if (ctx.value(u1) == 1) v.g.D_800F1DC9().* = ctx.value(u8);
        return ctx.value(c_int);
    }

    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        _ = ctx;
        _ = p;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(3)) {
        v.g.D_800F1DCC().* = null;
    } else {
        v.g.D_800F1DCC().* = ctx.alloc(v.vs_battle_backgroundLayout);
    }
    v.g.D_800F1DBE().* = ctx.pick(i16, &.{ -1, -32768, 0, 32767 });
    v.g.D_800F1DC8().* = ctx.int(u8);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1DCC().* == null) 0 else 1;
}
