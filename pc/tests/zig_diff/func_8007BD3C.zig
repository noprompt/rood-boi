//! zig_diff spec: func_8007BD3C -> func_8007BD3C.func_8007BD3C (146C.c).
//! Inputs: arg0 is zero, positive or negative (any value in each sign range,
//! so the sign bit alone and the extremes occur). The unit's one global,
//! D_80050468, is random bytes, so both halves of the swap see distinct values.
//! The two callees are recording stubs that may rewrite D_80050468's bytes
//! (the state the next call and the return see), drawn with ctx.value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BD3C));

pub const classes = [_][:0]const u8{ "zero", "positive", "negative" };

pub const stubs = struct {
    pub fn func_800CB550(ctx: *zd.Ctx) void {
        const g = v.g.D_80050468();
        if (ctx.value(u1) == 1) g.unk1 = ctx.value(u8);
    }

    pub fn func_800CB560(ctx: *zd.Ctx) void {
        const g = v.g.D_80050468();
        if (ctx.value(u1) == 1) g.unk0 = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg: c_int = switch (ctx.range(u2, 0, 3)) {
        0 => 0,
        1 => ctx.range(c_int, 1, std.math.maxInt(c_int)),
        2 => ctx.range(c_int, std.math.minInt(c_int), -1),
        else => ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int), 256 }),
    };
    return .{arg};
}

pub fn classify(args: Args) usize {
    if (args[0] == 0) return 0;
    if (args[0] > 0) return 1;
    return 2;
}
