//! zig_diff spec: _getLastValue -> get_last_value.getLastValue (146C.c).
//! The C body reads no argument: it returns the global _lastValue (a u32)
//! narrowed to short. Inputs: the pointer arguments are null or arena
//! objects, arg3 is 7 sometimes (the value the C ignores), and the global
//! is random bits half the time, otherwise an edge value that puts the low
//! 16 bits at zero, at the sign bit, just below it, or at all-ones, with
//! high bits set above the 16 the return drops.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getLastValue));

pub const classes = [_][:0]const u8{ "low-zero", "low-sign-set", "low-sign-clear" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (!ctx.chance(2)) {
        v.g._lastValue().* = ctx.pick(u32, &.{
            0,        1,          0x7FFF,     0x8000,
            0xFFFF,   0x10000,    0x7FFF_0000, 0x8000_0000,
            0xFFFF_8000, 0xFFFF_FFFF,
        });
    }
    const a: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const h1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const h2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    return .{ a, h1, h2, ctx.pick(c_int, &.{ 0, 7, -1 }), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    _ = args;
    const low: u16 = @truncate(v.g._lastValue().*);
    if (low == 0) return 0;
    return if ((low & 0x8000) != 0) 1 else 2;
}
