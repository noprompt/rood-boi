//! zig_diff spec: func_8007C46C -> func_8007C46C.func_8007C46C (146C.c).
//! Inputs: the screen transition step at 1, at 2, or at another value (0, 3, 5,
//! max u32, or random), with random effect, speed and angle drawn from edge
//! values and any c_int. The C returns early when the step is 1 or 2 and
//! otherwise stores 5 and the three arguments. The function makes no calls.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C46C));

pub const classes = [_][:0]const u8{ "step-1", "step-2", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const step = v.g.vs_battle_screenTransitionStep();
    if (ctx.chance(2)) {
        step.* = ctx.edge(u32, &.{ 1, 2 });
    } else {
        step.* = ctx.pick(u32, &.{ 0, 1, 2, 3, 4, 5, 0x8000_0000, 0xFFFF_FFFF });
    }
    const effect = ctx.pick(c_int, &.{ 0, 1, -1, 2, 5, 0x7FFF_FFFF, -0x8000_0000 });
    const speed = ctx.pick(c_int, &.{ 0, 1, -1, 2, 5, 0x7FFF_FFFF, -0x8000_0000 });
    const angle = ctx.pick(c_int, &.{ 0, 1, -1, 2, 5, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ effect, speed, angle };
}

pub fn classify(args: Args) usize {
    _ = args;
    const step = v.g.vs_battle_screenTransitionStep().*;
    if (step == 1) return 0;
    if (step == 2) return 1;
    return 2;
}
