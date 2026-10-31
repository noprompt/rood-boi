//! Text box lookup: the address of one entry in the battle text box table
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: vs_battle_getTextBox (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns the text box at index `id` of vs_battle_textBoxes, with no bounds check, as the C does.
pub fn getTextBox(id: c_int) callconv(.c) ?*v.vs_battle_textBox {
    return psx.at(v.g.textBoxes(), id);
}
