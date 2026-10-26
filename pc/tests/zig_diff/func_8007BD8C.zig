//! zig_diff spec: func_8007BD8C -> func_8007BD8C.func_8007BD8C (146C.c).
//! Inputs: arg0 drawn from zero, small positive, -1 (sign bit set, all ones),
//! INT_MAX and INT_MIN, so both sides of `arg0 != 0` run, and nonzero values
//! both with and without the sign bit are seen. The C only calls two void or
//! int externals and never reads anything back from them, so the stubs keep
//! their default behaviour (the callees' return value is discarded by the C).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
const psx = @import("common").psx;

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BD8C));

pub const classes = [_][:0]const u8{ "zero", "positive", "negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fffffff, -0x80000000 });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 == 0) return 0;
    if (arg0 < 0) return 2;
    return 1;
}
