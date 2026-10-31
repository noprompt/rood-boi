//! zig_diff spec: func_800D1FEC -> func_800D1FEC.func_800D1FEC (5BF94.c).
//! Inputs: an arg0 that is a random int or an edge (0, -1, INT_MIN, INT_MAX,
//! and nibble patterns), so every bit i of 0..3 is set or clear in turn, with
//! the sign bit both set and clear. The classes split on the low nibble: none
//! of the four bits set, all four set, or some of them. The loop only reads
//! arg0 and its own counter. D_800F54B8 is random bytes and the store to its
//! unk0 is compared through the state at the call and at the end. The callee
//! func_800D1DFC is a void recording stub: the C never reads anything back
//! from it, so it needs no model. Its hash of the state at the call still
//! catches a store moved across the call.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1FEC));

pub const classes = [_][:0]const u8{ "no-bits", "some-bits", "all-bits" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{
        0,
        -1,
        -2147483648,
        2147483647,
        0x0F,
        0x0A,
        0x05,
        -16,
        0x7FFFFFF0,
    });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const m = args[0] & 15;
    if (m == 0) return 0;
    if (m == 15) return 2;
    return 1;
}
