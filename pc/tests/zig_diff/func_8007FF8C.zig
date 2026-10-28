//! zig_diff spec: func_8007FF8C -> func_8007FF8C.func_8007FF8C (146C.c).
//! Inputs: a 0x130-byte buffer in the arena whose three slots at 0xCA, 0xFA and
//! 0x12A are each 9 or a non-9 edge (0, 8, 10, 0x89, 0xF9, 0xFF), so every
//! subset of slots is hit (none, one of each, several); arg1 on edges (0, +-1,
//! +-100, 32767, -32768) and random shorts, so the product, the truncating
//! division and the short narrowing are all exercised, negative values
//! included; arg0 is random (the C never reads it).
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007FF8C));

pub const classes = [_][:0]const u8{ "none", "slot0-only", "slot1-only", "slot2-only", "several" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const buf: [*]u8 = ctx.allocBytes(0x130, 16);
    const mask = ctx.range(u8, 0, 7);
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const off = i * 0x30 + 0xCA;
        if ((mask & (@as(u8, 1) << @intCast(i))) != 0) {
            buf[off] = 9;
        } else {
            buf[off] = ctx.edge(u8, &.{ 0, 8, 10, 0x89, 0xF9, 0xFF });
        }
    }
    return .{
        ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFF_FFFF, -0x8000_0000 }),
        ctx.pick(c_short, &.{ 0, 1, -1, 100, -100, 32767, -32768 }),
        buf,
    };
}

pub fn classify(args: Args) usize {
    const buf: [*]u8 = args[2];
    var n: usize = 0;
    var which: usize = 0;
    for (0..3) |i| {
        if (buf[i * 0x30 + 0xCA] == 9) {
            n += 1;
            which = i;
        }
    }
    if (n == 0) return 0;
    if (n > 1) return 4;
    return which + 1;
}
