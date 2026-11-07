//! zig_diff spec: _printFixedWidthFontChar -> fixed_font_char.printFixedWidthFontChar (D2: pc/src/fixed_font.c).
//! Inputs: the six arguments, any ints. pc_fixed_font_char's stub records its
//! seven arguments (the scratchpad cursor address, then the six as unsigned)
//! and returns any int, which must come back.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").printFixedWidthFontChar));

pub const classes = [_][:0]const u8{ "call" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{ 0, 1, -1, 0x8f, 0x10000, -0x8000, 0x7fffffff, -0x80000000 };
    return .{ ctx.pick(c_int, &edges), ctx.pick(c_int, &edges), ctx.pick(c_int, &edges), ctx.pick(c_int, &edges), ctx.pick(c_int, &edges), ctx.pick(c_int, &edges) };
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}

pub const stubs = struct {
    pub fn pc_fixed_font_char(ctx: *zd.Ctx, cursor: anytype, character: anytype, x: anytype, y: anytype, width: anytype, height: anytype, scale: anytype) c_int {
        _ = .{ cursor, character, x, y, width, height, scale };
        return ctx.value(c_int);
    }
};
