//! zig_diff spec: _dismissAllTextBoxes -> dismiss_all_text_boxes.dismissAllTextBoxes (5BF94.c).
//! Inputs: no arguments and no globals. The C calls vs_battle_dismissTextBox for
//! i = 0..7 and returns 1 unless one call returned nonzero. Each iteration picks a
//! mode for the stub's results: every call returns 0; every call returns a nonzero
//! value (random, so both sign bits, with 0 replaced by 1); a mix of 0, INT_MIN, 1
//! and random values; or only negative values (-1 and INT_MIN). The mode is the class.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dismissAllTextBoxes));

pub const classes = [_][:0]const u8{ "all-zero", "all-nonzero", "mixed", "negative-only" };

var mode: u8 = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    mode = ctx.range(u8, 0, 3);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}

pub const stubs = struct {
    pub fn vs_battle_dismissTextBox(ctx: *zd.Ctx, i: anytype) c_int {
        _ = i;
        return switch (mode) {
            0 => 0,
            1 => blk: {
                const r = ctx.value(c_int);
                break :blk if (r == 0) 1 else r;
            },
            2 => switch (ctx.value(u8) % 4) {
                0 => 0,
                1 => std.math.minInt(c_int),
                2 => 1,
                else => ctx.value(c_int),
            },
            else => if (ctx.value(bool)) -1 else std.math.minInt(c_int),
        };
    }
};
