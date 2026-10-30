//! zig_diff spec: _renderDigit -> render_digit.renderDigit (5BF94.c).
//! Inputs: font 0-7 (the shift by font*4 is undefined outside that range, so
//! the font never has its sign bit set), xy any value that cannot overflow
//! when the tpage bit adds 0x20000, digit any i16 (so the short store wraps
//! and the product stays inside int), and a 128-byte primitive buffer. The
//! primitive call is a recording stub that overwrites the first five words of
//! nextPrim and returns it advanced by 0-3 words, so a store made before the
//! call, or to the argument instead of the returned primitive, is caught. The
//! short store at [8] overlaps prim[4]'s low half, so the store order matters.
//! Classes: font 2 (no short store), font with the tpage bit (font & 2), and
//! the rest.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").renderDigit));

pub const classes = [_][:0]const u8{ "font-2", "tpage-bit", "other-font" };

pub const stubs = struct {
    pub fn vs_battle_setSpriteDefaultTexPage(
        ctx: *zd.Ctx,
        brightnessTransparency: anytype,
        xy: anytype,
        wh: anytype,
        nextPrim: anytype,
    ) [*c]c_uint {
        _ = brightnessTransparency;
        _ = xy;
        _ = wh;
        // The real callee writes a tpage primitive into the buffer it is given.
        const p: [*c]c_uint = nextPrim;
        var i: usize = 0;
        while (i < 5) : (i += 1) p[i] = ctx.value(u32);
        // It returns the next free slot: the buffer advanced by 0-3 words.
        return p + @as(usize, ctx.value(u2));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const font = ctx.range(c_int, 0, 7);
    const xy: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 0, -1, 0x7fff, -0x8000, 0x12345, -0x12345 })
    else
        ctx.range(c_int, -(1 << 30), 1 << 30);
    const digit: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ -32768, -1, 0, 1, 9, 32767 })
    else
        ctx.range(c_int, -32768, 32767);
    const before: [*c]c_uint = @ptrCast(@alignCast(ctx.allocBytes(128, 16)));
    return .{ font, xy, digit, before };
}

pub fn classify(args: Args) usize {
    if (args[0] == 2) return 0;
    return if ((args[0] & 2) != 0) 1 else 2;
}
