//! zig_diff spec: vs_battle_renderTextRawColor -> render_text_raw_color.renderTextRawColor (5BF94.c).
//! Inputs: a prim buffer and a nextPrim block in the arena, both wired into
//! vs_scratch.unk0 and vs_scratch.unk8 (nextPrim is null a quarter of the
//! time, so the C takes unk8). The text is 0-56 bytes of printable ASCII
//! with specials mixed in: '[' (the c == 0x3B case), '#' and '$' (the
//! width-sum path), '%' (c - 3 == 2), '*' (glyph 10), '\\', 'g', letters
//! (kerning pairs), control bytes and high bytes (unsigned reads). x and
//! color take edge values (sign changes, 16-bit wraps, INT_MIN/INT_MAX).
//! The C makes no external calls, so there are no stubs.
//! The kerning test `c < 26` is reached only with the u_char c after
//! `c -= 0x21`, which is either 0..25 or 0xDF..0xFF; no input can make it a
//! positive value above 25 (see the coverage waiver in the TOML).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").renderTextRawColor));

pub const classes = [_][:0]const u8{ "empty-text", "null-next", "width-escape", "glyph" };

const special = [_]u8{ '[', '#', '$', '%', '*', '\\', 'g', 'A', 'Z', 0x80, 0xFF, 0x01, 0x1F, 0x7F };

pub fn prepare(ctx: *zd.Ctx) Args {
    const scratch = v.g.vs_scratch();

    // Prim buffer (4096 bytes): the C writes at most 5 words per glyph.
    const prim_buf = ctx.alloc([1024]u32);
    const prim: *anyopaque = prim_buf;
    psx.put(&scratch.unk0, prim);

    // The block nextPrim names, and the one unk8 gives when nextPrim is null.
    const next_buf = ctx.alloc([4]u32);
    const next: *anyopaque = next_buf;
    psx.put(&scratch.unk8, next);

    // Text: NUL-terminated, never NUL inside.
    const tb = ctx.alloc([64]u8);
    const len: usize = if (ctx.chance(10)) 0 else ctx.range(usize, 1, 56);
    for (0..len) |i| {
        tb[i] = if (ctx.chance(10))
            special[ctx.range(usize, 0, special.len - 1)]
        else
            ctx.range(u8, 0x20, 0x7E);
    }
    tb[len] = 0;

    const x = ctx.pick(c_int, &.{
        0,                      -1,                      1,
        0x7FFF,                 -0x8000,                 0xFFFF,
        0x10000,                -0x10000,                0x7FFF_0000,
        std.math.minInt(c_int), std.math.maxInt(c_int),
    });
    const color = ctx.pick(c_int, &.{
        0, -1, 0x7F7F7F, 0x00FF0000, 0x1F, std.math.minInt(c_int),
    });

    var np: ?*anyopaque = next;
    if (ctx.chance(4)) np = null;

    return .{ @as([*c]const u8, &tb[0]), x, color, np };
}

pub fn classify(args: Args) usize {
    const text = args[0];
    if (text[0] == 0) return 0;
    if (args[3] == null) return 1;
    var i: usize = 0;
    while (text[i] != 0) : (i += 1) {
        if (text[i] == '#' or text[i] == '$') return 2;
    }
    return 3;
}
