//! zig_diff spec: func_8007C398 -> func_8007C398.func_8007C398 (146C.c).
//! The unit reads only vs_battle_screenTransitionStep and maps it through a
//! switch. The inputs set that global to the case values 0-7, the values just
//! past them, the 16-bit wrap edge (0x10000, 0x10001), and extremes (0x80000000,
//! 0xFFFFFFFF), with half the runs fully random. Classes: step 0, steps 1-2
//! (shared return), steps 3-7, and every other value (default).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C398));

pub const classes = [_][:0]const u8{ "step-0", "step-1-2", "step-3-7", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const step = v.g.vs_battle_screenTransitionStep();
    step.* = ctx.pick(u32, &.{
        0,      1,      2,       3,        4,          5,        6,        7,
        8,      9,      0x10000, 0x10001,  0x80000000, 0xFFFFFFFF, 0x80000001, 0x00000101,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const step = v.g.vs_battle_screenTransitionStep().*;
    return switch (step) {
        0 => 0,
        1, 2 => 1,
        3...7 => 2,
        else => 3,
    };
}
