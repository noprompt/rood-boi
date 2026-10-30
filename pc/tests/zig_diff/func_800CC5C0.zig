//! zig_diff spec: func_800CC5C0 -> func_800CC5C0.func_800CC5C0 (5BF94.c).
//! Inputs: a tile list pointer (an arena object, or null, which the C passes
//! on unread) and an arg1 drawn from the edges that matter for the three
//! OR-ed constants and the +0x13F carry: 0, -1, 0x13F, -0x13F (so arg1 + 0x13F
//! wraps to 0), INT_MAX, INT_MIN, and a small value. The C has no branches and
//! no value tests; the only thing to compare is the addTile call's arguments.
//! vs_battle_addTile is a recording stub: the C reads nothing back from it, so
//! the stub needs no behaviour.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CC5C0));

pub const classes = [_][:0]const u8{ "zero", "sign-bit", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const before: [*c]c_uint = if (ctx.chance(8)) null else ctx.alloc(c_uint);
    const arg1 = ctx.pick(c_int, &.{ 0, -1, 0x13F, -0x13F, 0x7FFFFFFF, -0x80000000, 0xE3 });
    return .{ before, arg1 };
}

pub fn classify(args: Args) usize {
    const arg1 = args[1];
    if (arg1 == 0) return 0;
    if (arg1 < 0) return 1;
    return 2;
}
