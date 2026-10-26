//! zig_diff spec: func_8007B10C -> func_8007B10C.func_8007B10C (146C.c).
//! Inputs: three int arguments and two short arguments, each drawn from edge
//! values (0, 1, -1, the int and short extremes) or any value of its type.
//! The C has no branches and no value comparisons. Its three calls to
//! vs_main_transformClutSlot are recording stubs (void, no state change), so
//! the compared calls and the state hashes at each call check the slot order,
//! the argument mapping and the implicit narrowing of arg2 to the callee's
//! short parameter.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B10C));

pub const classes = [_][:0]const u8{ "arg3-negative", "arg3-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const int_edges = [_]c_int{ 0, 1, -1, 2, 0x7FFF_FFFF, -0x8000_0000, 0xFFFF, 0x1_0000 };
    const short_edges = [_]c_short{ 0, 1, -1, 2, 32767, -32768, 255, -256 };
    return .{
        ctx.pick(c_int, &int_edges),
        ctx.pick(c_int, &int_edges),
        ctx.pick(c_int, &int_edges),
        ctx.pick(c_short, &short_edges),
        ctx.pick(c_short, &short_edges),
    };
}

pub fn classify(args: Args) usize {
    return if (args[3] < 0) 0 else 1;
}
