//! zig_diff spec: func_80069E80 -> func_80069E80.func_80069E80 (146C.c).
//! Inputs: the table index D_80060064 in 0..3, the eight unk8 rows of
//! D_80061078[index] with random bytes, about a third of them set to arg0+1
//! so that none, one or several match (the last match wins). arg0 comes from
//! byte-edge values (-2, -1, 0, 254, 255, 256) and extremes, so arg0+1 falls
//! outside 0..255 too. Out-of-byte cases also plant the truncated value in
//! some rows, so a port that compares through a u8 truncation gets caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069E80));

pub const classes = [_][:0]const u8{ "out-of-byte", "no-match", "one-match", "several-matches" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const idx = ctx.range(i32, 0, 3);
    v.g.D_80060064().* = idx;
    const row = &v.g.D_80061078()[@intCast(idx)];

    const arg = ctx.pick(c_int, &.{ -2, -1, 0, 1, 254, 255, 256, -2147483647, 2147483646 });
    const want: c_int = arg +% 1;
    const bits: u32 = @bitCast(want);
    const low: u8 = @truncate(bits);

    for (&row.unk8) |*e| {
        if (ctx.chance(3)) {
            e[0] = low;
        }
    }
    return .{arg};
}

pub fn classify(args: Args) usize {
    const want: c_int = args[0] +% 1;
    if (want < 0 or want > 255) return 0;
    const row = &v.g.D_80061078()[@intCast(v.g.D_80060064().*)];
    var n: usize = 0;
    for (row.unk8) |e| {
        if (e[0] == @as(u8, @intCast(want))) n += 1;
    }
    return switch (n) {
        0 => 1,
        1 => 2,
        else => 3,
    };
}
