//! Marks a battle actor's slot as flagged (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007BF6C (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets bit 0 of the flags of battle actor `arg0`, if its slot is occupied.
pub fn func_8007BF6C(arg0: c_int) callconv(.c) void {
    if (psx.at(v.g.vs_battle_actors(), arg0).* != null) {
        c.func_800A087C(arg0, psx.conv(c_int, c.func_800A0BE0(arg0) | 1));
    }
}
