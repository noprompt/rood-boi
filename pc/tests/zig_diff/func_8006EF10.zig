//! zig_diff spec: func_8006EF10 -> func_8006EF10.func_8006EF10 (146C.c).
//! Inputs: the camera's delta.mode across the edges (INT_MIN, -1, 0 to 4,
//! INT_MAX) and random values, so every case label, the fall-through pairs
//! and the default (no store) path run. The global D_800F19CC always points
//! at a fresh arena object, so a store to it in any mode is a visible
//! difference in the arena bytes rather than a fault. The stored halfwords
//! and the arena bytes around them are compared as state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006EF10));

pub const classes = [_][:0]const u8{ "low-modes", "high-modes", "other-modes" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const cam = v.g.vs_battle_cameraCurrentSpherical();
    cam.delta.mode = ctx.pick(i32, &.{ -2147483648, -1, 0, 1, 2, 3, 4, 2147483647 });
    // Always valid: the C dereferences it in modes 0-3, and a mutation that
    // stores in other modes must show as a mismatch, not a fault.
    v.g.D_800F19CC().* = ctx.alloc(v.D_800F19CC_t);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const mode = v.g.vs_battle_cameraCurrentSpherical().delta.mode;
    return switch (mode) {
        0, 1 => 0,
        2, 3 => 1,
        else => 2,
    };
}
