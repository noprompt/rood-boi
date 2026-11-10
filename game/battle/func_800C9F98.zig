//! Sprite primitive setup in the scratch packet (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");
const sprite_item = @import("common").sprite_item;

/// orig: func_800C9F98 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets up a sprite primitive at the default texture page and writes its two command words.
pub fn func_800C9F98(arg0: c_int, arg1: c_int) callconv(.c) void {
    // The packet pointer is a word-aligned guest address: assert the alignment the C type needs.
    _ = sprite_item.sprite(null, arg1, arg0, 0x60006, @bitCast(@as(c_uint, 0xE1000017)), 0x373D80C0);
}
