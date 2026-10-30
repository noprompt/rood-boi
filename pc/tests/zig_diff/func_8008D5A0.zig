//! zig_diff spec: func_8008D5A0 -> func_8008D5A0.func_8008D5A0 (146C.c).
//! Inputs: the room's section12Len (u32) at the edges of the divide-by-184
//! test: 0, 1, 183 (quotient 0, the outer `if` is false), and 184, 185, 367,
//! 368, 0x80000000, 0xFFFFFFFF (quotient nonzero). The argument covers 0,
//! 1, -1, INT_MAX, INT_MIN, 256 and 65536, so the `!= 0` test sees
//! negative and positive values. The callee is a void recording stub, so
//! its call arguments and the D_800F1D68 store are what the harness compares.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D5A0));

pub const classes = [_][:0]const u8{ "section12-under-184", "arg-zero", "arg-negative", "arg-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const hdr = &v.g.vs_battle_roomData().header;
    hdr.section12Len = if (ctx.chance(4))
        ctx.edge(u32, &.{ 0, 1, 183 })
    else
        ctx.pick(u32, &.{ 184, 185, 367, 368, 0x8000_0000, 0xFFFF_FFFF });
    const arg = ctx.pick(c_int, &.{ 0, 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 256, 65536 });
    return .{arg};
}

pub fn classify(args: Args) usize {
    const len = v.g.vs_battle_roomData().header.section12Len;
    if (len / 184 == 0) return 0;
    if (args[0] == 0) return 1;
    if (args[0] < 0) return 2;
    return 3;
}
