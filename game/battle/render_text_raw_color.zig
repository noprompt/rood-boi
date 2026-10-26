//! Lays out a line of text as raw GPU primitives in the packet list
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: vs_battle_renderTextRawColor (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Writes the glyph and underline primitives for `text` at (x, y) in `color`, linked in front of `nextPrim`, and moves the packet cursor past them.
pub fn renderTextRawColor(text: [*c]const u8, x: c_int, color: c_int, nextPrim: ?*anyopaque) callconv(.c) void {
    const scratch = v.g.vs_scratch();
    const widths = v.g.D_800EB7B4();
    const kern = v.g.D_800EB708();
    const glyph = v.g.D_800EB7D4();

    var prim: [*]align(1) u32 = @ptrCast(psx.get(scratch.unk0).?);
    const y: c_int = x >> 16;
    var cx: c_int = psx.conv(i16, x);
    var next: ?*anyopaque = nextPrim;
    if (next == null) next = psx.get(scratch.unk8);

    prim[0] = ((psx.addr(&prim[2]) << 8) >> 8) | 0x01000000;
    prim[1] = 0xE100000C;
    prim += 2;

    var tp: [*]const u8 = text;
    while (true) {
        var c: u8 = tp[0];
        tp += 1;
        if (c == 0) break;

        c -%= 0x20;
        if (c >= 0x3B) {
            if (c == 0x3B) cx -%= 1;
        } else if (psx.conv(c_uint, @as(c_int, c) -% 3) < 2) {
            var w: c_uint = 0;
            var scan: [*]const u8 = tp;
            while (true) {
                const raw = scan[0];
                scan += 1;
                if (raw == 0) break;
                var ch: u8 = raw;
                ch -%= 0x20;
                if (ch < 0x3C) {
                    const sh: u5 = @intCast((@as(c_int, ch) << 2) & 4);
                    w +%= psx.conv(c_uint, (@as(c_int, widths[@as(usize, ch >> 1)]) >> sh) & 0xF);
                    ch -%= 0x21;
                    if (ch < 26) {
                        var index: c_uint = psx.conv(c_uint, @as(c_int, scan[0]) - 0x41);
                        if (index < 26) {
                            index +%= @as(c_uint, ch) * 26;
                            const sh2: u5 = @intCast((index & 3) * 2);
                            w -%= psx.conv(c_uint, (@as(c_int, kern[@as(usize, index >> 2)]) >> sh2) & 3);
                        }
                    }
                }
            }
            const sh3: u5 = @intCast(@as(c_int, c) - 3);
            cx -%= psx.conv(c_int, w >> sh3);
        } else {
            const sh: u5 = @intCast((@as(c_int, c) << 2) & 4);
            const w: c_uint = psx.conv(c_uint, (@as(c_int, widths[@as(usize, c >> 1)]) >> sh) & 0xF);
            if (w != 0) {
                const index: c_uint = @as(c_uint, glyph[@as(usize, c)]);
                prim[0] = ((psx.addr(&prim[5]) << 8) >> 8) | 0x04000000;
                prim[1] = psx.conv(u32, color) | 0x64000000;
                prim[2] = (psx.conv(u32, cx) & 0xFFFF) | (psx.conv(u32, y) << 16);
                prim[3] = (index & 0xFE) | ((((index & 1) *% 10) +% 0x4C) << 8) | 0x37F60000;
                prim[4] = w | 0xA0000;
                if (c == 10) {
                    prim[2] = (psx.conv(u32, cx -% 1) & 0xFFFF) | (psx.conv(u32, y -% 1) << 16);
                    prim[3] = 0x37F64BE8;
                    prim[4] = w | 0xB0000;
                }
                prim += 5;
                cx +%= psx.conv(c_int, w);
                c -%= 0x21;
                if (c < 26) {
                    var index2: c_uint = psx.conv(c_uint, @as(c_int, tp[0]) - 0x41);
                    if (index2 < 26) {
                        index2 +%= @as(c_uint, c) * 26;
                        const sh2: u5 = @intCast((index2 & 3) * 2);
                        cx -%= (@as(c_int, kern[@as(usize, index2 >> 2)]) >> sh2) & 3;
                    }
                }
            }
        }
    }

    const next_word: *align(1) u32 = @ptrCast(next.?);
    prim[0] = next_word.* & 0xFFFFFF;
    next_word.* = (psx.rawOf(scratch.unk0) << 8) >> 8;
    psx.put(&scratch.unk0, @as(*anyopaque, @ptrCast(&prim[1])));
}
