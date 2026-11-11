//! Arms the D_800F1B98 state of the battle transition's wipe (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DD50 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Sets state 1, or state 3 when `arg0` is zero. (The original also took a heap block of packets for the wipe on the first call; the wipe
/// is items, and nothing read the block.)
pub fn func_8007DD50(arg0: c_int) callconv(.c) void {
    v.g.D_800F1B98().* = if (arg0 != 0) 1 else 3;
}
