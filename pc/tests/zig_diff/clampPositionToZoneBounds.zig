//! zig_diff spec: _clampPositionToZoneBounds -> clamp_position_to_zone_bounds.clampPositionToZoneBounds (146C.c).
//! Inputs: the zone bounds and the camera distance are kept small enough that
//! the C's int products and sums do not overflow (its arithmetic is only
//! defined there). A quarter of the runs make the zone flat (maxX == minX,
//! maxZ == minZ, distance 0), so the inverted test is equal. Each axis's
//! inPos is at the low or high limit, one past it, or anywhere, so the
//! ordered comparisons see equality and both sides. The vertical offset
//! inPos.vy - lookAt.vy is at +-96*4096 and one past it, so the window test
//! sees equality. lookAt.vy is sometimes 0, so `outPos->vy > 0` sees equality.
//! outPos is sometimes the same object as inPos (in-place clamping). Negative
//! and positive inPos values on both axes meet bounds of either sign, so
//! signed and unsigned comparisons differ. No callees: the function reads
//! only globals and its arguments.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").clampPositionToZoneBounds));

pub const classes = [_][:0]const u8{ "inverted", "clamped", "inside", "y-outside" };

/// The C's clamp window on one axis: [min*4096*128 + r*360, max*4096*128 - r*360].
fn span(minB: i16, maxB: i16, radius: i32) [2]i32 {
    return .{
        @as(i32, minB) * 4096 * 128 + radius * 360,
        @as(i32, maxB) * 4096 * 128 - radius * 360,
    };
}

/// A position on one axis: at the low or high limit, one past it, or anywhere.
fn axis(ctx: *zd.Ctx, low: i32, high: i32) i32 {
    return switch (ctx.range(u8, 0, 5)) {
        0 => low,
        1 => high,
        2 => low - 1,
        3 => high + 1,
        else => ctx.range(i32, -(1 << 30), 1 << 30),
    };
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const zone = v.g._zoneContext();
    const sph = v.g.vs_battle_cameraCurrentSpherical();
    const scratch = v.g.vs_scratch();

    const flat = ctx.chance(4);
    zone.bounds.minX = ctx.range(i16, -1500, 1500);
    zone.bounds.maxX = if (flat) zone.bounds.minX else ctx.range(i16, -1500, 1500);
    zone.bounds.minZ = ctx.range(i16, -1500, 1500);
    zone.bounds.maxZ = if (flat) zone.bounds.minZ else ctx.range(i16, -1500, 1500);
    sph.values.distance = if (flat) 0 else ctx.range(i32, -100000, 100000);

    const radius: i32 = @divTrunc(sph.values.distance * 4096, 2304);
    const x = span(zone.bounds.minX, zone.bounds.maxX, radius);
    const z = span(zone.bounds.minZ, zone.bounds.maxZ, radius);

    const inPos = ctx.alloc(v.VECTOR);
    const outPos = if (ctx.chance(5)) inPos else ctx.alloc(v.VECTOR);
    inPos.vx = axis(ctx, x[0], x[1]);
    inPos.vz = axis(ctx, z[0], z[1]);

    scratch.camera.lookAt.vy = if (ctx.chance(4)) 0 else ctx.range(i32, -(1 << 29), 1 << 29);
    const diff: i32 = switch (ctx.range(u8, 0, 6)) {
        0 => 96 * 4096,
        1 => -96 * 4096,
        2 => 96 * 4096 + 1,
        3 => -96 * 4096 - 1,
        4 => 96 * 4096 - 1,
        else => ctx.range(i32, -(1 << 29), 1 << 29),
    };
    inPos.vy = scratch.camera.lookAt.vy + diff;

    return .{ inPos, outPos };
}

pub fn classify(args: Args) usize {
    const inPos = args[0].?;
    const zone = v.g._zoneContext();
    const sph = v.g.vs_battle_cameraCurrentSpherical();
    const scratch = v.g.vs_scratch();
    const radius: i32 = @divTrunc(sph.values.distance * 4096, 2304);
    const x = span(zone.bounds.minX, zone.bounds.maxX, radius);
    const z = span(zone.bounds.minZ, zone.bounds.maxZ, radius);
    if (x[1] < x[0] or z[1] < z[0]) return 0;
    if (inPos.vx < x[0] or x[1] < inPos.vx or inPos.vz < z[0] or z[1] < inPos.vz) return 1;
    const dy = inPos.vy - scratch.camera.lookAt.vy;
    if (dy > 96 * 4096 or dy < -96 * 4096) return 3;
    return 2;
}
