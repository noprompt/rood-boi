//! zig_diff spec: vs_battle_setProjectionDistance -> set_projection_distance.setProjectionDistance (146C.c).
//! Inputs: a projection distance from the edges (0, -1, 1, INT_MAX, INT_MIN,
//! 320) or any random c_int. The C has no branches; SetGeomScreen is a
//! recording stub, so the state hash at the call and the call's argument
//! both have to agree with the C: the store to vs_main_projectionDistance
//! must happen before the call, with the full 32-bit value.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setProjectionDistance));

pub const classes = [_][:0]const u8{ "negative", "non-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const d: c_int = ctx.pick(c_int, &.{ 0, -1, 1, 320, 0x7FFF_FFFF, -0x8000_0000, 0x7FFF, 0x8000, -0x8001 });
    return .{d};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
