//! The battle menu's one heap block (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c): 40 menu items, the 0x60-byte
//! string buffer and the 0xC4 bytes of row types follow. The PS1's 0xA00, 0xA60 and 0xB24 are these.
const v = @import("views_5BF94");

pub const items_len: usize = 40 * @sizeOf(v.vs_battle_menuItem_t);
pub const strings_at: usize = items_len;
pub const row_types_at: usize = items_len + 0x60;
pub const total: usize = row_types_at + 0xC4;
