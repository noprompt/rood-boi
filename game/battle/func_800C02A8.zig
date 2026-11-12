//! Loads the scratchpad matrix at 0x1F800014 as the GTE rotation and translation (pc/src/game/BATTLE/BATTLE.PRG/573B8.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_573B8");
const c = @import("c_573B8");

/// orig: func_800C02A8 (pc/src/game/BATTLE/BATTLE.PRG/573B8.c)
/// Sets the GTE rotation and translation matrices from the scratchpad matrix at 0x1F800014.
pub fn func_800C02A8() callconv(.c) void {
    const matrix: *v.MATRIX = common.view.at(v.MATRIX, common.view.matrix_offset);
    c.SetRotMatrix(psx.cptr(c.MATRIX, matrix));
    c.SetTransMatrix(psx.cptr(c.MATRIX, matrix));
    common.gte.setFrame(matrix);
}
