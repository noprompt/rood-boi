//! zig_diff spec: func_800753F8 -> func_800753F8.func_800753F8 (146C.c).
//! Inputs: an actor in the arena whose three signed words (unkC, unk10.s32,
//! unk14) come from edges at 0, +-0x7FFF, +-0x8000, the 4096 quotient steps,
//! the i32 extremes, in-range noise and full-range noise; and an SVECTOR in
//! the arena that starts with random bytes. Both pointers are always valid
//! because the C never tests them. Classes follow unkC, which picks the arm
//! of its first block: the three words are independent, so each one's arms
//! are covered by the same draws.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800753F8));

pub const classes = [_][:0]const u8{
    "unkC-at-or-below--8000",
    "unkC-neg-in-range",
    "unkC-zero",
    "unkC-pos-in-range",
    "unkC-at-or-above-8000",
};

fn word(ctx: *zd.Ctx) i32 {
    return switch (ctx.range(u8, 0, 3)) {
        0 => ctx.pick(i32, &.{
            0,      -1,    1,      -0x7FFF, 0x7FFF,   -0x8000, 0x8000,
            -0x7FFE, 0x7FFE, 4095,  -4095,   4096,     -4096,   -4097,
            4097,   0x8001, -0x8001, std.math.minInt(i32), std.math.maxInt(i32),
        }),
        1 => ctx.range(i32, -0x9000, 0x9000),
        2 => ctx.range(i32, -8 * 4096 - 2048, 8 * 4096 + 2048),
        else => ctx.int(i32),
    };
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const out = ctx.alloc(v.SVECTOR);
    actor.unkC = word(ctx);
    actor.unk10.s32 = word(ctx);
    actor.unk14 = word(ctx);
    return .{ actor, out };
}

pub fn classify(args: Args) usize {
    const c = args[0].?.unkC;
    if (c <= -0x8000) return 0;
    if (c < 0) return 1;
    if (c == 0) return 2;
    if (c <= 0x7FFF) return 3;
    return 4;
}
