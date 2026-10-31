//! zig_diff spec: func_800D11F4 -> func_800D11F4.func_800D11F4 (5BF94.c).
//! Inputs: a block-11 table in the arena, reached through D_800F569C. It has a
//! count of 0-8 and eight offsets. Each offset leads to a list of (weight,
//! value) byte pairs ended by a 0 weight and its value. Weights run 1-255, so
//! the unsigned bytes above 127 are read, and weight 1 is common. arg0 runs
//! from -2 past the count (a signed compare). arg1 is the exact prefix sum of
//! the chosen list (the remainder reaches exactly 0), the sum +-1, 0, small
//! values and 0x7FFFFFFF. The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D11F4));

pub const classes = [_][:0]const u8{ "arg0-outside", "break-in-list", "end-arg1-zero", "end-arg1-nonzero", "empty-list" };

/// The class prepare built, returned by classify.
var cls: usize = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F569C_t);
    const b = ctx.allocBytes(512, 16);
    v.g.D_800F569C().* = d;
    psx.put(&d.block11Data, b);

    const count: i32 = ctx.range(i32, 0, 8);
    psx.byteAt(i32, b, 0).* = count;

    // arg0 below count (the C reads the table), at count, or past it.
    const arg0: i32 = switch (ctx.range(u8, 0, 3)) {
        0 => count,
        1 => ctx.range(i32, -2, count),
        else => ctx.range(i32, -2, 9),
    };

    var ns: [8]usize = undefined;
    var ws: [8][4]i32 = undefined;
    for (0..8) |i| {
        const off: usize = 40 + 24 * i;
        const s: usize = ctx.range(usize, 1, 3);
        const start = off + s;
        const n = ctx.range(usize, 0, 4);
        ns[i] = n;
        for (0..n) |k| {
            const w: u8 = if (ctx.chance(3)) ctx.edge(u8, &.{ 1, 128, 255 }) else ctx.range(u8, 1, 255);
            ws[i][k] = w;
            b[start + 2 * k] = w;
            b[start + 2 * k + 1] = ctx.int(u8);
        }
        // The terminator: a 0 weight and the value returned for arg1 == 0.
        b[start + 2 * n] = 0;
        b[start + 2 * n + 1] = ctx.int(u8);
        // The header byte the C adds to the table's offset.
        b[off] = @intCast(s);
        psx.byteAt(i16, b, @intCast(4 + 2 * i)).* = @intCast(off);
    }

    const idx: usize = if (arg0 >= 0 and arg0 < count) @intCast(arg0) else 0;
    var sum: i32 = 0;
    const pre = ctx.range(usize, 0, ns[idx]);
    for (0..pre) |k| sum += ws[idx][k];

    const arg1: i32 = switch (ctx.range(u8, 0, 7)) {
        0 => sum,
        1 => sum + 1,
        2 => sum - 1,
        3 => 0,
        4 => ctx.edge(i32, &.{ -1, 1, 255, 256, -255, 0x7FFF_FFFF }),
        else => ctx.range(i32, -300, 300),
    };

    cls = if (arg0 < 0 or arg0 >= count) 0 else if (ns[idx] == 0) 4 else blk: {
        var a = arg1;
        var broke = false;
        for (0..ns[idx]) |k| {
            const vv = a - ws[idx][k];
            if (vv < 0) {
                broke = true;
                break;
            }
            a = vv;
        }
        break :blk if (broke) 1 else if (a == 0) 2 else 3;
    };

    return .{ @as(c_int, arg0), @as(c_int, arg1) };
}

pub fn classify(args: Args) usize {
    _ = args;
    return cls;
}
