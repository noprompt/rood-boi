//! zig_diff spec: vs_battle_keystreamBits -> keystream_bits.keystreamBits (5BF94.c).
//! Inputs: a shift count of 1..32 (the C shifts by 32 - value, so values
//! outside 1..32 are undefined in C and not compared), biased toward the
//! ends 1, 31 and 32, and a keystream state that has the sign bit set half
//! the time, so a signed shift or a read after the store shows. The C has
//! no branches, so the classes only name the shift edges.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").keystreamBits));

pub const classes = [_][:0]const u8{ "shift-by-31", "shift-by-0", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Half the states have the sign bit set, so the logical shift is visible.
    if (ctx.chance(2)) v.g._keystreamState().* |= 0x8000_0000;
    const value: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 1, 2, 16, 31, 32 })
    else
        ctx.range(c_int, 1, 32);
    return .{value};
}

pub fn classify(args: Args) usize {
    return switch (args[0]) {
        1 => 0,
        32 => 1,
        else => 2,
    };
}
