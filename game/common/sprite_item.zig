//! A sprite as a draw item, for the Zig ports (pc/src/game/spriteItem.h: what vs_battle_setSprite and its kin made as packets).
const psx = @import("psx.zig");

const Item = *const fn (?*anyopaque, c_int, c_int, c_int, c_int, c_int) callconv(.c) c_int;
const Color = *const fn (c_int, c_int) callconv(.c) c_int;
const Command = *const fn (c_int) callconv(.c) ?*const anyopaque;

/// The draw mode of vs_battle_setSpriteDefaultTexPage's packet (the default texture page).
pub const page: c_int = @bitCast(@as(c_uint, 0xE100000C));

/// A sprite at `ot` (null: vs_scratch.unk8): `brightness` (bit 8: semi-transparent), place (x low, y high), size, draw mode as
/// an E1 word (0: the GPU's), texels and CLUT. Returns the item.
pub fn sprite(ot: ?*anyopaque, brightness: c_int, xy: c_int, wh: c_int, mode: c_int, uv_clut: c_int) c_int {
    return psx.weak(Item, "vs_battle_spriteItem").?(ot, brightness, xy, wh, mode, uv_clut);
}

/// The item's colour as a packet's colour word (0xBBGGRR, bit 25: semi-transparent).
pub fn color(item: c_int, word: c_int) void {
    _ = psx.weak(Color, "vs_battle_spriteColor").?(item, word);
}

/// The item's command word: what ui_text keys a glyph on.
pub fn command(item: c_int) ?*const anyopaque {
    return psx.weak(Command, "vs_battle_spriteCommand").?(item);
}
