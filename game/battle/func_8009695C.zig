//! Draws one row of a text-box entry as textured quads: two icons, a separator and the digits of its text (pc/src/game/BATTLE/BATTLE.PRG/2842C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_2842C");
const sprite_item = common.sprite_item;

fn xy(x: c_int, y: c_int) c_int {
    return @bitCast((@as(c_uint, @bitCast(x)) & 0xFFFF) | (@as(c_uint, @bitCast(y)) << 16));
}

fn uv(u: c_int, t: c_int) c_int {
    return @bitCast((@as(c_uint, @bitCast(u)) & 0xFF) | ((@as(c_uint, @bitCast(t)) & 0xFF) << 8));
}

/// One quad of the row: a draw item at slot 2 of the table at scratch.unk4 (the row's own slot), the page and colour every
/// piece of the row has (page 768, 0; its colour from the sign), a rectangle of the page's texels (`ux`, `uy`, `w`, `h`).
fn piece(x: c_int, y: c_int, w: c_int, h: c_int, ux: c_int, uy: c_int, clut: c_int, rgb: [4]u8) void {
    const scratch = common.scratch.get();
    const ot: ?*anyopaque = if (psx.get(scratch.unk4)) |q| @ptrFromInt(@intFromPtr(q) +% 8) else @ptrFromInt(8);
    const corners = [4]c_int{ xy(x, y), xy(x +% w, y), xy(x, y +% h), xy(x +% w, y +% h) };
    const texels = [4]c_int{ uv(ux, uy), uv(ux +% w, uy), uv(ux, uy +% h), uv(ux +% w, uy +% h) };
    _ = sprite_item.ft4(ot, false, false, 12, clut, @as(c_int, rgb[0]) | (@as(c_int, rgb[1]) << 8) | (@as(c_int, rgb[2]) << 16), &corners, &texels);
}

/// orig: func_8009695C (pc/src/game/BATTLE/BATTLE.PRG/2842C.c)
/// Adds the textured quads of one text-box row: the icons, a separator and the digits, from the right as the packets were.
pub fn func_8009695C(x_in: c_int, y_in: c_int, p: ?*v.D_800F1BAC_t) callconv(.c) void {
    var x = x_in;
    const pp = p.?;
    const y = y_in -% @as(c_int, pp.unk12);
    const negative: c_int = @as(c_int, pp.unkC) & 0x8000;
    const positive: c_int = @intFromBool(negative == 0);
    const colors = [2][4]u8{ .{ 128, 64, 0, 0 }, .{ 0, 64, 128, 0 } };
    const rgb = colors[@intCast(positive)];

    // First icon (setClut(848, 223)).
    {
        const r = v.g.D_80069144()[pp.unkE];
        piece(x, y, r.w, r.h, r.x, r.y, 14325, rgb);
        x +%= @as(c_int, r.w) +% 2;
    }

    // Second icon.
    {
        const r = v.g.D_8006917C()[pp.unkA];
        piece(x, y, r.w, r.h, r.x, r.y, 14325, rgb);
        x +%= @as(c_int, r.w) +% 2;
    }

    // Separator: eight by eight texels from the page's (120 or 128, 208), one pixel above the row.
    piece(x, y -% 1, 8, 8, positive *% 8 +% 120, 208, 14325, rgb);

    x +%= 2;
    x +%= @as(c_int, pp.displayTextLen) *% 5;

    const text: [*]i8 = @ptrCast(pp);
    var i: c_int = @as(c_int, pp.displayTextLen) -% 1;
    while (i >= 0) : ({
        i -%= 1;
        x -%= 5;
    }) {
        // The digit byte is read at p + i + 20 (the C reads past displayText's four bytes); setClut(832, 223).
        const glyph: c_int = (@as(c_int, text[@as(usize, @intCast(i)) + 20]) -% '0') *% 6;
        piece(x, y -% 1, 6, 10, glyph, 0, 14324, rgb);
    }
}
