//! zig_diff spec: func_8007DE5C -> func_8007DE5C.func_8007DE5C (146C.c).
//! The C body is one store: `D_800F1A40 = arg0;`, with no branches and no
//! calls. The inputs pick arg0 from zero, one, the sign-bit boundary, the
//! 16-bit boundaries, and the int extremes, so a narrowed, masked, or
//! sign-folded store, or a dropped or constant store, differs on some run.
//! The global is random before each run and the store must overwrite all
//! 32 bits in both runs.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE5C));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const x = ctx.pick(i32, &.{
        0,
        1,
        -1,
        0x7FFF,
        0x8000,
        -0x8000,
        -0x8001,
        0xFFFF,
        0x10000,
        0x8000_0000 - 0x1_0000_0000,
        std.math.maxInt(i32),
        std.math.minInt(i32),
    });
    return .{x};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x == 0) return 0;
    if (x < 0) return 1;
    return 2;
}
