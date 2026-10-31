//! zig_diff spec: func_800D2560 -> func_800D2560.func_800D2560 (5BF94.c).
//! Inputs: the timer D_800F55A0 is zero, negative or positive (edges included),
//! and D_800F54D0 is equal to it, one or two below it, or unrelated, so the
//! tick compare sees equality and the increment can reach the reset (and wrap
//! at 32767). The mode D_800F55E8 is 0-3 or another value, D_800F5518 is zero
//! or nonzero, so the call guard and the zeroing of D_800F54D8 both run. The
//! callees write the globals the C reads back: the tick, the timer, the flag
//! and the struct fields. Stubs draw only ctx.value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D2560));

pub const classes = [_][:0]const u8{ "timer-off", "timer-hit", "mode-0", "mode-1", "mode-2", "mode-3", "mode-other" };

pub const stubs = struct {
    pub fn func_800D21C0(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 64) v.g.D_800F54D0().* = ctx.value(i16);
    }
    pub fn func_800D236C(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 64) v.g.D_800F55A0().* = ctx.value(i16);
    }
    pub fn func_800D2518(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 64) v.g.D_800F5518().* = ctx.value(u8);
    }
    pub fn func_800D206C(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 128) v.g.D_800F54D8().unk20 = ctx.value(i32);
    }
    pub fn func_800D1E20(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u8) < 128) v.g.D_800F5518().* = ctx.value(u8);
    }
    pub fn func_800D1B80(ctx: *zd.Ctx, p: anytype) void {
        const s: *v.D_800F54D8_t = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) s.unk24 = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const timer = ctx.pick(i16, &.{ 0, 1, 2, -1, 32767, -32768 });
    v.g.D_800F55A0().* = timer;
    v.g.D_800F54D0().* = switch (ctx.range(u8, 0, 3)) {
        0 => timer,
        1 => timer -% 1,
        2 => timer -% 2,
        else => ctx.int(i16),
    };
    v.g.D_800F55E8().* = ctx.pick(u32, &.{ 0, 1, 2, 3, 4, 0x8000_0000, 0x8000_0001, 0xFFFF_FFFF });
    v.g.D_800F5518().* = if (ctx.chance(2)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const timer = v.g.D_800F55A0().*;
    if (timer == 0) return 0;
    if (v.g.D_800F54D0().* == timer) return 1;
    return switch (v.g.D_800F55E8().*) {
        0 => 2,
        1 => 3,
        2 => 4,
        3 => 5,
        else => 6,
    };
}
