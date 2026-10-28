//! zig_diff spec: func_8007CE74 -> func_8007CE74.func_8007CE74 (146C.c).
//! Inputs: the argument at each value the C tests (-0x300 and -0x80), values
//! near them, the -0x180 default, and edge and random ints. The C has no calls
//! and reads no memory beyond its argument. It writes only
//! vs_battle_cameraCurrentSpherical.values.pitch, which the harness randomises
//! before every run, so a port that skips the store or the return is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CE74));

pub const classes = [_][:0]const u8{ "eq-minus-0x300", "eq-minus-0x80", "other" };

const edges = [_]c_int{ -0x300, -0x80, -0x180, -0x301, -0x81, -0x7F, -0x2FF, 0, -1, 0x7fff_ffff };

pub fn prepare(ctx: *zd.Ctx) Args {
    // The global the C writes is random already; touch it so the accessor is exercised.
    _ = v.g.vs_battle_cameraCurrentSpherical();
    const arg0 = ctx.pick(c_int, &edges);
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 == -0x300) return 0;
    if (arg0 == -0x80) return 1;
    return 2;
}
