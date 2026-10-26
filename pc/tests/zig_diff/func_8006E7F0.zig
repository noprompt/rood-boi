//! zig_diff spec: func_8006E7F0 -> func_8006E7F0.func_8006E7F0 (146C.c).
//! Inputs: the transition step (edges 0-5 and wraps, so the fade branch and
//! the `- 1 < 2U` wrap both run), the transition flag bits of D_800F1AB0, the
//! mode-7 stick (edges at the 64 and 128 deadzone thresholds, so the unsigned
//! `> ONE / 32u` test sees negative operands), the button masks (single bits
//! and combinations, so the four D-pad steps and the R2 / R-left branches all
//! run), the camera distance around the 1536 and 2304 clamps, and the yaw.
//! func_8006E158 may move the camera distance and yaw; func_80074B14 may move
//! the buttons global; func_800A0BE0 returns any unsigned value, so bit 19 is
//! set and clear. ratan2 returns a small signed value, so the angle sums
//! cannot overflow.
const std = @import("std");
const zd = @import("zdiff");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006E7F0));

pub const classes = [_][:0]const u8{
    "transition-flag-set",
    "transition-flag-clear",
    "stick-mode7",
    "r2-held",
    "pressed-r-left",
    "other",
};

pub const stubs = struct {
    pub fn func_8006E158(ctx: *zd.Ctx) void {
        const cam = v.g.vs_battle_cameraCurrentSpherical();
        if (ctx.value(u1) == 1) cam.values.distance = ctx.value(i32);
        if (ctx.value(u1) == 1) cam.values.yaw = @as(i32, ctx.value(i16));
    }

    pub fn func_80074B14(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        if (ctx.value(u1) == 1) v.g.vs_main_buttonsPreviousState().* = ctx.value(i32);
    }

    pub fn func_800A0BE0(ctx: *zd.Ctx, a: anytype) c_uint {
        _ = a;
        return ctx.value(c_uint);
    }

    pub fn ratan2(ctx: *zd.Ctx, y: anytype, x: anytype) c_int {
        _ = y;
        _ = x;
        return @as(c_int, ctx.value(i16));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const stats = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    psx.put(&actor.stats, stats);
    v.g.vs_battle_characterState().* = actor;
    stats.unk31 = ctx.pick(u8, &.{ 0, 1, 255, 128 });
    stats.unk33 = ctx.pick(u8, &.{ 0, 1, 255, 128 });

    v.g.vs_battle_screenTransitionStep().* = ctx.pick(u32, &.{ 0, 1, 2, 3, 4, 5, 0xFFFF_FFFF });
    const flag = v.g.D_800F1AB0();
    psx.setBits(flag, "unk6_15", ctx.range(u1, 0, 1));
    psx.setBits(flag, "unk4_13", ctx.range(u2, 0, 3));

    const pi = &v.g._portInfo()[0];
    pi.mode = if (ctx.chance(2)) 7 else ctx.pick(u8, &.{ 0, 1, 6, 8, 255 });
    const stick = [_]u8{ 0, 63, 64, 65, 127, 128, 129, 160, 191, 192, 193, 255 };
    pi.rStickX = ctx.pick(u8, &stick);
    pi.rStickY = ctx.pick(u8, &stick);

    v.g.vs_main_buttonsPreviousState().* = ctx.pick(i32, &.{
        0,
        1 << 14,
        1 << 12,
        1 << 15,
        1 << 13,
        1 << 1,
        (1 << 1) | (1 << 14),
        (1 << 1) | (1 << 13),
        (1 << 14) | (1 << 12),
        (1 << 15) | (1 << 13),
        -1,
    });
    v.g.vs_main_buttonsPressed().all = ctx.pick(u32, &.{ 0, 1 << 7, 0xFFFF_FFFF, 1 << 6 });

    const cam = v.g.vs_battle_cameraCurrentSpherical();
    cam.values.distance = ctx.pick(i32, &.{ 1536, 1535, 1537, 2303, 2304, 2305, 0, -1, 0x7FFF_FFFF });
    cam.values.yaw = ctx.pick(i32, &.{ 0, 2048, 4095, 4096, -1 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const step = v.g.vs_battle_screenTransitionStep().*;
    if ((step -% 1) < 2 or step == 4) {
        return if (psx.getBits(v.g.D_800F1AB0(), "unk6_15") != 0) 0 else 1;
    }
    const pi = v.g._portInfo()[0];
    const dy = @as(i32, pi.rStickY) - 128;
    if (pi.mode == 7 and @abs(dy) > 64) return 2;
    const held = v.g.vs_main_buttonsPreviousState().*;
    if ((held & (1 << 1)) != 0) return 3;
    if ((v.g.vs_main_buttonsPressed().all & (1 << 7)) != 0) return 4;
    return 5;
}
