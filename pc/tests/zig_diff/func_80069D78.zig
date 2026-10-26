//! zig_diff spec: func_80069D78 -> func_80069D78.func_80069D78 (146C.c).
//! Inputs: the unit takes no arguments, so the inputs are the globals it
//! reads: vs_scratch.firstPersonViewFacing (random, with bit 15 and bit 31
//! set and clear) and _firstPersonViewEnabled (zero, one, -1, bit 15 and
//! 16 patterns, the extremes). The callee vs_battle_syncCameraAnglesFromPosition
//! is a recording stub that rewrites both globals with ctx.value, because the
//! C reads them back after the call, and it returns a value the C discards.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069D78));

pub const classes = [_][:0]const u8{ "facing-bit15-clear", "facing-bit15-set" };

pub const stubs = struct {
    pub fn vs_battle_syncCameraAnglesFromPosition(ctx: *zd.Ctx, p: anytype) c_int {
        _ = p;
        // The real callee rewrites the scratch facing and the first-person flag.
        if (ctx.value(u1) == 1) v.g.vs_scratch().firstPersonViewFacing = ctx.value(u32);
        if (ctx.value(u1) == 1) v.g._firstPersonViewEnabled().* = ctx.value(i32);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.vs_scratch().firstPersonViewFacing = ctx.pick(u32, &.{ 0, 0x8000, 0x7FFF, 0xFFFF_FFFF, 0x8000_0000, 0x0001_8000 });
    v.g._firstPersonViewEnabled().* = ctx.pick(i32, &.{ 0, 1, -1, 0x8000, 0x7FFF_FFFF, -0x8000_0000, 0x1_0000 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const facing = v.g.vs_scratch().firstPersonViewFacing;
    return if ((facing & 0x8000) != 0) 1 else 0;
}
