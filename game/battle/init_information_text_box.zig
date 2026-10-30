//! Opens the information text box (text box 7) with a header (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const c = @import("c_5BF94");

/// orig: vs_battle_initInformationTextBox (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Opens text box 7 with the information header `header` in its high byte.
pub fn initInformationTextBox(header: c_uint) callconv(.c) void {
    // (header << 8) | 4 is unsigned; the callee's int parameter takes its bits.
    const flags: c_uint = (header << 8) | 4;
    c.vs_battle_initTextBox(7, psx.conv(c_int, flags), 0, 1, 0, 4, 0, 0);
}
