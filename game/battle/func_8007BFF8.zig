//! Clears bit 0 of a battle actor's slot word when the slot is occupied (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007BFF8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears bit 0 of the word func_800A0BE0 returns for actor slot `arg0`, if that slot is occupied.
pub fn func_8007BFF8(arg0: c_int) callconv(.c) void {
    if (psx.at(v.g.vs_battle_actors(), arg0).* != null) {
        c.func_800A087C(arg0, psx.conv(c_int, c.func_800A0BE0(arg0)) & ~@as(c_int, 1));
    }
}
