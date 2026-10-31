//! zig_diff spec: func_800D1E78 -> func_800D1E78.func_800D1E78 (5BF94.c).
//! Inputs: one D_800F54B8_t in the arena with unk1_6 random (the curve flag),
//! unk0 and unk3 drawn from edges (0, 1, 2, 127, 128, 255). The curve sampler
//! stub returns 0, -1 or any c_int, so the `var_s0 == 0` test sees zero,
//! negative and positive divisors. rand() returns a non-negative value as the
//! C library does, so `rand() % var_s0` covers large divisors and the u8 narrowing.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1E78));

pub const classes = [_][:0]const u8{ "curve-off-zero-field", "curve-off-nonzero-field", "curve-on" };

pub const stubs = struct {
    pub fn vs_battle_sampleCurve(ctx: *zd.Ctx, curveId: anytype, distance: anytype) c_int {
        _ = curveId;
        _ = distance;
        if (ctx.value(u8) < 40) return 0;
        if (ctx.value(u8) < 40) return -1;
        return ctx.value(c_int);
    }

    pub fn rand(ctx: *zd.Ctx) c_int {
        return @as(c_int, @intCast(ctx.value(u31)));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F54B8_t);
    psx.setBits(arg, "unk1_6", ctx.int(u1));
    arg.unk0 = ctx.pick(u8, &.{ 0, 1, 2, 127, 128, 255 });
    arg.unk3 = ctx.pick(u8, &.{ 0, 1, 2, 127, 128, 255 });
    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0].?;
    if (psx.getBits(arg, "unk1_6") == 1) return 2;
    return if (arg.unk3 == 0) 0 else 1;
}
