//! zig_diff spec: func_80090B28 -> func_80090B28.func_80090B28 (146C.c).
//! Inputs: the trig angles D_800F1D98[4] and [5] (any i16, including the 0,
//! +-1, 4095/4096 and extreme edges) and the scale D_800F1D98[6], which is 0
//! a quarter of the time (so every product is 0 and the `< 0` tests see equal
//! sides), negative, or positive. The C reads [6] past the six declared
//! entries, into the gap the harness keeps as state, so prepare sets it like
//! the others. rsin and rcos are pure recording stubs that return a trig-range
//! value (a 13-bit signed value, or 0 one time in four), so both signs of every
//! intermediate product occur and the 32-bit arithmetic never overflows.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80090B28));

pub const classes = [_][:0]const u8{ "scale-zero", "scale-negative", "scale-positive" };

pub const stubs = struct {
    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        if (ctx.value(u2) == 0) return 0;
        return @as(c_int, ctx.value(i13));
    }
    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        if (ctx.value(u2) == 0) return 0;
        return @as(c_int, ctx.value(i13));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const t = v.g.D_800F1D98();
    t[4] = ctx.pick(i16, &.{ 0, 1, -1, 4095, 4096, -4096, 32767, -32768 });
    t[5] = ctx.pick(i16, &.{ 0, 1, -1, 4095, 4096, -4096, 32767, -32768 });
    // Index 6 is the scale the C reads past the six declared entries.
    t[6] = if (ctx.chance(4)) 0 else ctx.pick(i16, &.{ 1, -1, 4096, -4096, 32767, -32768 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const t = v.g.D_800F1D98();
    if (t[6] == 0) return 0;
    if (t[6] < 0) return 1;
    return 2;
}
