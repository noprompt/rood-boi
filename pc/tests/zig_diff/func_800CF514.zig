//! zig_diff spec: func_800CF514 -> func_800CF514.func_800CF514 (5BF94.c).
//! Inputs: arg0 in -31..127, all inside the four-entry table D_800F5320
//! (indices 0..3). Nonnegative arg0 covers every bit position in every
//! entry; negative arg0 takes the `arg0 < 0` branch and stays on index 0.
//! The C's bit count is then negative (-31..-1), which the C masks as the
//! hardware does, so the C run stays fault-free. The table is random bytes,
//! so the cleared bit is set or clear at random. Edge values (0, the entry
//! boundaries 31/32/63/64/95/96/127, and -1, -16, -31) are drawn half the
//! time, so arg0 == 0 (the `arg0 < 0` sides equal) happens often.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF514));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

const edges = [_]c_int{ 0, 1, 31, 32, 63, 64, 95, 96, 127, -1, -16, -31 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &edges)
    else
        ctx.range(c_int, -31, 127);
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a < 0) return 0;
    if (a == 0) return 1;
    return 2;
}
