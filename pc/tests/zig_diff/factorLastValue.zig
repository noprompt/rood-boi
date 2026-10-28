//! zig_diff spec: _factorLastValue -> factor_last_value.factorLastValue (146C.c).
//! Inputs: an action in the arena (a 512-byte block, the action 256 bytes in, so
//! hitParams indices -8..8 stay in memory the harness owns) with a random 5-bit
//! statFactor at every index; arg3 and arg4 drawn independently from -8..8, so a
//! port that reads the wrong one differs; the two hit entities null or valid (the
//! C never reads them); and _lastValue at its edges: the sign bit set or clear,
//! the 32-bit product wrapping (above 138547332, the largest value with
//! lastValue * 31 < 2^32), 0 and the extremes.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorLastValue));

pub const classes = [_][:0]const u8{ "sign-bit-set", "product-wraps", "small" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const block = ctx.allocBytes(512, 16) + 256;
    const action: *v.vs_action_t = @ptrCast(@alignCast(block));
    const off: isize = @offsetOf(v.vs_action_t, "hitParams");

    var k: isize = -8;
    while (k <= 8) : (k += 1) {
        const hp = psx.byteAt(v.vs_action_t_hitParams, action, off + 4 * k);
        psx.setBits(hp, "statFactor", ctx.int(u5));
    }

    const arg3 = ctx.range(c_int, -8, 8);
    const arg4 = ctx.range(c_int, -8, 8);

    v.g._lastValue().* = ctx.pick(u32, &.{
        0,          1,         9,          138547332,
        138547333,  0x7FFFFFFF, 0x80000000, 0xFFFFFFFF,
    });

    var h1: ?*v._hitEntity_t = null;
    var h2: ?*v._hitEntity_t = null;
    if (!ctx.chance(2)) h1 = ctx.alloc(v._hitEntity_t);
    if (!ctx.chance(2)) h2 = ctx.alloc(v._hitEntity_t);

    return .{ action, h1, h2, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    _ = args;
    const lv = v.g._lastValue().*;
    if ((lv & 0x8000_0000) != 0) return 0;
    if (lv > 138547332) return 1;
    return 2;
}
