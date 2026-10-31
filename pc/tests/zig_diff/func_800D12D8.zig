//! zig_diff spec: func_800D12D8 -> func_800D12D8.func_800D12D8 (5BF94.c).
//! Inputs: a table in the arena (a count, then a short offset table and
//! byte chains). The count is the argument in about a quarter of the runs,
//! so `arg0 < count` sees equal sides often. Offsets are small or any i16
//! (negative ones included), chain bytes cover 1, 0x80-0xFF and the rest,
//! and chains run 0-4 bytes. The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D12D8));

pub const classes = [_][:0]const u8{ "equal-count", "past-count", "negative", "empty-chain", "chain" };

/// The table sits 40 KB into an 80 KB block: every offset the C can form
/// (a short plus a byte, or arg0 + 2 within the generated range) stays inside it.
const buf_size = 80 * 1024;
const table_off = 40 * 1024;

var last_table: [*]u8 = undefined;

pub fn prepare(ctx: *zd.Ctx) Args {
    const buf = ctx.allocBytes(buf_size, 16);
    const table: [*]u8 = buf + table_off;
    last_table = table;

    const n: c_int = ctx.edge(c_int, &.{ 0, 1, 2, 3, -1, 5, 40, 1000 });
    psx.byteAt(c_int, table, 0).* = n;

    const arg0: c_int = if (ctx.chance(4))
        n
    else if (ctx.chance(3))
        ctx.range(c_int, -20000, 16000)
    else if (n > 0)
        ctx.range(c_int, 0, @min(n - 1, 16000))
    else
        ctx.range(c_int, -3, 3);

    // The offset-table slot for arg0: ((short*)table)[arg0 + 2].
    const off0: i16 = if (ctx.chance(2))
        ctx.range(i16, -64, 64)
    else
        ctx.range(i16, -32768, 32767);
    psx.byteAt(i16, table, 4 + 2 * @as(isize, arg0)).* = off0;

    // The first byte at off0 moves the start of the chain.
    const b: u8 = if (ctx.chance(4)) ctx.edge(u8, &.{ 0, 1, 127, 128, 255 }) else ctx.int(u8);
    psx.byteAt(u8, table, off0).* = b;
    const p: isize = @as(isize, off0) + @as(isize, b);

    // The chain: nonzero bytes at p, p+2, ..., then a zero.
    const k: usize = if (ctx.chance(4)) 0 else ctx.range(usize, 1, 4);
    var j: usize = 0;
    while (j < k) : (j += 1) {
        const val: u8 = if (ctx.chance(4)) 1 else ctx.range(u8, 1, 255);
        psx.byteAt(u8, table, p + 2 * @as(isize, @intCast(j))).* = val;
    }
    psx.byteAt(u8, table, p + 2 * @as(isize, @intCast(k))).* = 0;

    const obj = ctx.alloc(v.D_800F569C_t);
    psx.put(&obj.block11Data, table);
    v.g.D_800F569C().* = obj;

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const t = last_table;
    const arg0 = args[0];
    const n = psx.byteAt(c_int, t, 0).*;
    if (arg0 == n) return 0;
    if (arg0 >= n) return 1;
    if (arg0 < 0) return 2;
    const off0 = psx.byteAt(i16, t, 4 + 2 * @as(isize, arg0)).*;
    var off: isize = off0;
    off += @as(isize, psx.byteAt(u8, t, off).*);
    return if (psx.byteAt(u8, t, off).* == 0) 3 else 4;
}
